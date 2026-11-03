#!/usr/bin/env python3
"""Gate: the workflows run only `just <recipe>` steps, and nothing else changes what a job does.

feat-5-foundation-monorepo-ci, Task 130.140 (REQ-009, ACC-003) and the finding E2 of the review.
There is no list of exceptions for a `run:` step.

Usage: check_workflows.py <justfile> <workflows-dir> <required-setup>

The script reads the YAML of each workflow (PyYAML). It stops for each of these:

  Steps
  * `run:` is not exactly `just <recipe>` (one line, no other word, no expression), or <recipe> is
    not a public recipe of the justfile (`just --summary`).
  * a step with a `shell:` key, a job with no `steps:` (for example a job with `uses:`), a step with
    no `run:` and no `uses:`.

  The rest of the workflow (the finding E2: before, a job with `if: false`, an `env:` with `PATH=...`
  or a changed trigger passed the gate)
  * the trigger is not ALLOWED_TRIGGERS (`pull_request` with the branches `dev` and `main`, in this
    order, and no other key such as `paths`, `types` or `branches-ignore`). To change the branches,
    change the list in ALLOWED_TRIGGERS: this is the one place.
  * `permissions:` of the workflow is missing or is not `contents: read`, or the `permissions:` of
    a job is not `contents: read`.
  * a key that is not in WORKFLOW_KEYS, JOB_KEYS, RUN_STEP_KEYS or USES_STEP_KEYS. So `env`,
    `defaults`, `concurrency` (workflow), and `if`, `continue-on-error`, `container`, `services`,
    `strategy`, `needs`, `env`, `outputs`, `defaults` (job), and `shell`, `env`, `working-directory`,
    `continue-on-error` (step) are not allowed. The only `if:` is in ALLOWED_IF.
  * the `name:` of a job is not its identifier, a job has not exactly one `run:` step, or the
    identifier of a job is not its recipe (the jobs are the required status checks of the ruleset).
  * a job or a workflow file that is not in <required-setup> (tools/gates/required-setup.txt), a job of
    the file that is missing, and a job whose `uses:` actions (by name) are not exactly the actions of
    its line in the file (a missing or an extra action).

Exit codes: 0 all correct; 1 at least one finding; 2 an error in a file.
The pins of the `uses:` steps are the work of check_pins.py.
"""

import re
import subprocess
import sys
from collections import Counter
from pathlib import Path
from typing import Any

from _workflow import GateError, iter_jobs, iter_steps, load_workflows

RUN_PATTERN = re.compile(r"just [a-z][a-z0-9_-]*")

# The trigger of each workflow. The value of `on:` must be exactly this: the gates run for pull
# requests to `dev` and to `main` (the branches with a ruleset), in this order, and for nothing else.
# To add or remove a branch, change the list of branches (one line). The `justfile` takes the branch
# to compare with from GITHUB_BASE_REF, so it needs no change.
ALLOWED_TRIGGERS: dict[str, Any] = {"pull_request": {"branches": ["dev", "main"]}}
# The permissions of the workflow, and of a job that has `permissions:`.
ALLOWED_PERMISSIONS: dict[str, str] = {"contents": "read"}
# The keys that each level may have. Each other key stops the gate.
WORKFLOW_KEYS = {"name", "on", "permissions", "jobs"}
JOB_KEYS = {"name", "runs-on", "timeout-minutes", "permissions", "steps"}
RUN_STEP_KEYS = {"name", "run"}
USES_STEP_KEYS = {"name", "uses", "with", "if"}
# The only `if:` that a step may have: (job identifier, action name) -> the text of the condition.
ALLOWED_IF: dict[tuple[str, str], str] = {("license-check", "actions/upload-artifact"): "${{ !cancelled() }}"}


def recipes_of(justfile: Path) -> set[str]:
    """Return the public recipes of the justfile."""
    try:
        result = subprocess.run(
            ["just", "--justfile", str(justfile), "--summary"],
            check=True,
            capture_output=True,
            text=True,
        )
    except (OSError, subprocess.CalledProcessError) as error:
        raise GateError(f"cannot read the recipes with `just --summary`: {error}") from error
    recipes = set(result.stdout.split())
    if not recipes:
        raise GateError(f"{justfile} has no public recipe")
    return recipes


def read_required(path: Path) -> dict[tuple[str, str], list[str]]:
    """Read tools/gates/required-setup.txt: lines `<workflow file> <job> <action>...`."""
    try:
        lines = path.read_text(encoding="utf-8").splitlines()
    except OSError as error:
        raise GateError(f"cannot read {path}: {error}") from error
    required: dict[tuple[str, str], list[str]] = {}
    for number, line in enumerate(lines, start=1):
        if not line.strip() or line.lstrip().startswith("#"):
            continue
        words = line.split()
        if len(words) < 2 or not all(re.fullmatch(r"[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+", action) for action in words[2:]):
            raise GateError(f"{path}, line {number}: the form is not `<workflow file> <job> <owner>/<name>...`")
        key = (words[0], words[1])
        if key in required:
            raise GateError(f"{path}, line {number}: the job {words[1]} of {words[0]} is twice in the file")
        required[key] = sorted(words[2:])
    if not required:
        raise GateError(f"{path} has no job")
    return required


def check_step(step: dict[Any, Any], recipes: set[str]) -> str | None:
    """Return None if the step is correct, or the reason why it is not."""
    if "shell" in step:
        return "the step has a `shell:` key"
    if "run" not in step:
        return None if "uses" in step else "the step has no `run:` and no `uses:`"
    if "uses" in step:
        return "the step has `run:` and `uses:`"
    command = step["run"]
    if not isinstance(command, str):
        return f"`run:` is not a text ({command!r})"
    command = command.rstrip("\n")  # a block scalar with one line ends with a new line
    if not RUN_PATTERN.fullmatch(command):
        return f"`run:` is not exactly `just <recipe>`: {command!r}"
    recipe = command.split(" ", 1)[1]
    if recipe not in recipes:
        return f"the recipe '{recipe}' is not in the justfile"
    return None


def key_problems(where: str, mapping: dict[Any, Any], allowed: set[str]) -> list[str]:
    """Return a problem for each key of the mapping that is not in the allowed set."""
    problems: list[str] = []
    for key in mapping:
        shown = "on" if key is True else str(key)  # PyYAML reads the key `on` as the boolean True
        if shown not in allowed:
            problems.append(
                f"{where} has the key `{shown}`, which is not allowed (allowed: {', '.join(sorted(allowed))})"
            )
    return problems


def has_run_shell(defaults: Any) -> bool:
    """Return True if a `defaults:` block has `run: shell:`."""
    return isinstance(defaults, dict) and isinstance(defaults.get("run"), dict) and "shell" in defaults["run"]


def workflow_problems(path: Path, workflow: dict[Any, Any]) -> list[str]:
    """Check the keys, the trigger and the permissions of a workflow (not its jobs)."""
    problems = key_problems(f"{path}: the workflow", workflow, WORKFLOW_KEYS)
    if has_run_shell(workflow.get("defaults")):
        problems.append(f"{path}: `defaults.run.shell` is not allowed")
    triggers = [workflow[key] for key in (True, "on") if key in workflow]
    if len(triggers) != 1:
        problems.append(f"{path}: the workflow must have exactly one `on:` key")
    elif triggers[0] != ALLOWED_TRIGGERS:
        problems.append(f"{path}: `on:` is {triggers[0]!r}, but it must be exactly {ALLOWED_TRIGGERS!r}")
    if workflow.get("permissions") != ALLOWED_PERMISSIONS:
        problems.append(
            f"{path}: `permissions:` of the workflow is {workflow.get('permissions')!r}, "
            f"but it must be exactly {ALLOWED_PERMISSIONS!r}"
        )
    return problems


def uses_name(step: dict[Any, Any]) -> str:
    """Return the name of the action of a `uses:` step (the text before the @)."""
    return str(step["uses"]).split("@", 1)[0]


def job_problems(
    path: Path, job_id: str, job: dict[Any, Any], recipes: set[str], required: dict[tuple[str, str], list[str]]
) -> tuple[int, list[str]]:
    """Check one job. Return the number of correct `run:` steps and the problems."""
    problems: list[str] = []
    where = f"{path}: job '{job_id}'"
    steps = iter_steps(path, job_id, job)
    problems += key_problems(where, job, JOB_KEYS)
    if has_run_shell(job.get("defaults")):
        problems.append(f"{where} has `defaults.run.shell`")
    if job.get("name") != job_id:
        problems.append(f"{where}: `name:` is {job.get('name')!r}, but it must be the identifier '{job_id}'")
    if "timeout-minutes" in job and (
        isinstance(job["timeout-minutes"], bool) or not isinstance(job["timeout-minutes"], int)
    ):
        problems.append(f"{where}: `timeout-minutes:` must be a number ({job['timeout-minutes']!r})")
    if "permissions" in job and job["permissions"] != ALLOWED_PERMISSIONS:
        problems.append(
            f"{where}: `permissions:` is {job['permissions']!r}, but it must be exactly {ALLOWED_PERMISSIONS!r}"
        )

    run_steps: list[str] = []
    actions: list[str] = []
    for index, step in enumerate(steps, start=1):
        place = f"{where}, step {index}"
        reason = check_step(step, recipes)
        if reason is not None:
            problems.append(f"{place}: {reason}")
            continue
        if "run" in step:
            problems += key_problems(place, step, RUN_STEP_KEYS)
            run_steps.append(step["run"].rstrip("\n"))
            print(f"ok   {path}: job '{job_id}', step {index}: {step['run'].rstrip()}")
            continue
        problems += key_problems(place, step, USES_STEP_KEYS)
        action = uses_name(step)
        actions.append(action)
        if "if" in step and ALLOWED_IF.get((job_id, action)) != step["if"]:
            problems.append(f"{place}: `if: {step['if']}` is not allowed. The only `if:` is {ALLOWED_IF!r}")
        if "with" in step and not isinstance(step["with"], dict):
            problems.append(f"{place}: `with:` is not a mapping")

    if len(run_steps) != 1:
        problems.append(f"{where} has {len(run_steps)} `run:` steps, but each job starts exactly one `just` recipe")
    elif run_steps[0] != f"just {job_id}":
        problems.append(
            f"{where}: the recipe of the job is `{run_steps[0]}`, but it must be `just {job_id}` (the name of the job)"
        )

    wanted = required.get((path.name, job_id))
    if wanted is None:
        problems.append(f"{where} is not in required-setup.txt (add a line for it, with the actions of the job)")
    else:
        have = Counter(actions)
        want = Counter(wanted)
        missing = sorted((want - have).elements())
        extra = sorted((have - want).elements())
        if missing:
            problems.append(f"{where} lacks the required action(s) {', '.join(missing)} (required-setup.txt)")
        if extra:
            problems.append(f"{where} has the action(s) {', '.join(extra)}, which are not in required-setup.txt")
    return len(run_steps), problems


def main(argv: list[str]) -> int:
    if len(argv) != 4:
        print("Usage: check_workflows.py <justfile> <workflows-dir> <required-setup>", file=sys.stderr)
        return 2
    try:
        recipes = recipes_of(Path(argv[1]))
        print(f"recipes in {argv[1]}: {' '.join(sorted(recipes))}")
        required = read_required(Path(argv[3]))
        problems: list[str] = []
        run_steps = 0
        seen: set[tuple[str, str]] = set()
        for path, workflow in load_workflows(Path(argv[2])):
            problems += workflow_problems(path, workflow)
            for job_id, job in iter_jobs(path, workflow):
                seen.add((path.name, job_id))
                count, found = job_problems(path, job_id, job, recipes, required)
                run_steps += count
                problems += found
        for file_name, job_id in sorted(set(required) - seen):
            problems.append(f"the job '{job_id}' of {file_name} is in required-setup.txt, but not in the workflows")
    except GateError as error:
        print(f"ERROR: {error}", file=sys.stderr)
        return 2
    for problem in problems:
        print(f"STOP {problem}")
    if problems:
        print(f"RESULT: STOP. {len(problems)} problem(s).")
        return 1
    print(
        f"RESULT: PASS. {run_steps} run step(s), each is `just <recipe>` with a recipe in the justfile. "
        f"Trigger, permissions, keys and setup actions are as in required-setup.txt."
    )
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
