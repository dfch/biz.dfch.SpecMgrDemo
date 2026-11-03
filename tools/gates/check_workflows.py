#!/usr/bin/env python3
"""Gate: each `run:` step in a workflow is `just <recipe>`, and the recipe is in the justfile.

feat-5-foundation-monorepo-ci, Task 130.140 (REQ-009, ACC-003). There is no list of exceptions.

Usage: check_workflows.py <justfile> <workflows-dir>

The script reads the YAML of each workflow (PyYAML) and looks at each step of each job:

  * `run:` must be exactly `just <recipe>` (one line, no other word, no expression).
  * <recipe> must be a public recipe of the justfile (`just --summary`).
  * a step with a `shell:` key stops the gate (a shell can change what `just` means).
  * a job with no `steps:` (for example a job with `uses:`) stops the gate.
  * a step with no `run:` and no `uses:` stops the gate.

Exit codes: 0 all steps correct; 1 at least one step not correct; 2 an error in a file.
The pins of the `uses:` steps are the work of check_pins.py.
"""

import re
import subprocess
import sys
from pathlib import Path
from typing import Any

from _workflow import GateError, iter_jobs, iter_steps, load_workflows

RUN_PATTERN = re.compile(r"just [a-z][a-z0-9_-]*")


def recipes_of(justfile: Path) -> set[str]:
    """Return the public recipes of the justfile."""
    try:
        result = subprocess.run(  # noqa: S603
            ["just", "--justfile", str(justfile), "--summary"],  # noqa: S607
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


def main(argv: list[str]) -> int:
    if len(argv) != 3:
        print("Usage: check_workflows.py <justfile> <workflows-dir>", file=sys.stderr)
        return 2
    try:
        recipes = recipes_of(Path(argv[1]))
        print(f"recipes in {argv[1]}: {' '.join(sorted(recipes))}")
        failures = 0
        run_steps = 0
        for path, workflow in load_workflows(Path(argv[2])):
            defaults = workflow.get("defaults")
            if isinstance(defaults, dict) and isinstance(defaults.get("run"), dict) and "shell" in defaults["run"]:
                print(f"STOP {path}: `defaults.run.shell` is not allowed")
                failures += 1
            for job_id, job in iter_jobs(path, workflow):
                job_defaults = job.get("defaults")
                if (
                    isinstance(job_defaults, dict)
                    and isinstance(job_defaults.get("run"), dict)
                    and "shell" in job_defaults["run"]
                ):
                    print(f"STOP {path}: job '{job_id}' has `defaults.run.shell`")
                    failures += 1
                for index, step in enumerate(iter_steps(path, job_id, job), start=1):
                    reason = check_step(step, recipes)
                    if reason is not None:
                        print(f"STOP {path}: job '{job_id}', step {index}: {reason}")
                        failures += 1
                    elif "run" in step:
                        run_steps += 1
                        print(f"ok   {path}: job '{job_id}', step {index}: {step['run'].rstrip()}")
    except GateError as error:
        print(f"ERROR: {error}", file=sys.stderr)
        return 2
    if failures:
        print(f"RESULT: STOP. {failures} step(s) not correct.")
        return 1
    print(f"RESULT: PASS. {run_steps} run step(s), each is `just <recipe>` with a recipe in the justfile.")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
