#!/usr/bin/env python3
"""Gate: the pins in the workflows (ACC-013).

feat-5-foundation-monorepo-ci, Task 130.142 (REQ-003, REQ-015).

Usage: check_pins.py <versions.env> <workflows-dir> <allowed-actions>

The script stops for each of these:

  * a `uses:` that is not `<owner>/<name>[/<path>]@<40 hexadecimal characters>` (a tag, a branch,
    a short SHA, a local action `./...`, and `docker://...` are not allowed);
  * a `uses:` with no comment on the same line, or a comment that is not `# <owner>/<name> <tag>`
    (the name is the name of the action, the tag is a release tag such as v7.0.1);
  * an action that is not in <allowed-actions> (the actions of the license table), or whose tag
    or SHA is not the one in this file;
  * a setup action whose version input is missing, is not a text, or is not the same as the
    value in tools/versions.env (see TOOL_INPUTS below);
  * `actions/setup-java` with a distribution that is not `temurin`;
  * a version input of an action that has no entry in TOOL_INPUTS (the gate cannot check it);
  * a `uses:` in the YAML that the text check did not find, or the other way round (this stops
    a form of the YAML that the text check does not read, for example a `uses:` in two lines).

The comment is not in the YAML data, so the script reads the lines of the file for the comment,
and the YAML data for the inputs. Exit codes: 0 pass; 1 a pin is not correct; 2 an error in a file.
"""

import re
import sys
from collections import Counter
from pathlib import Path
from typing import Any

from _workflow import GateError, iter_jobs, iter_steps, load_workflows

# The setup actions: the input with the version of the tool, and the key in tools/versions.env.
TOOL_INPUTS: dict[str, dict[str, str]] = {
    "actions/setup-java": {"java-version": "JDK_VERSION"},
    "actions/setup-node": {"node-version": "NODE_VERSION"},
    "pnpm/action-setup": {"version": "PNPM_VERSION"},
    "astral-sh/setup-uv": {"version": "UV_VERSION"},
    "extractions/setup-just": {"just-version": "JUST_VERSION"},
}
# Other inputs that must have a fixed value.
FIXED_INPUTS: dict[str, dict[str, str]] = {"actions/setup-java": {"distribution": "temurin"}}

USES_LINE = re.compile(r"^\s*(?:-\s+)?uses:\s*(\S+)[ \t]*(?:#(.*))?$")
USES_VALUE = re.compile(
    r"(?P<name>[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+)(?P<path>(?:/[A-Za-z0-9_./-]+)?)@(?P<sha>[0-9a-f]{40})"
)
COMMENT = re.compile(r"\s*(?P<name>[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+) (?P<tag>v[0-9]+(?:\.[0-9]+){0,2})\s*")
VERSION_KEY = re.compile(r"(^|[-_])version([-_]|$)", re.IGNORECASE)


def read_versions(path: Path) -> dict[str, str]:
    """Read tools/versions.env (lines `KEY=value`)."""
    versions: dict[str, str] = {}
    try:
        lines = path.read_text(encoding="utf-8").splitlines()
    except OSError as error:
        raise GateError(f"cannot read {path}: {error}") from error
    for number, line in enumerate(lines, start=1):
        if not line.strip() or line.lstrip().startswith("#"):
            continue
        match = re.fullmatch(r"([A-Z][A-Z0-9_]*)=(\S*)", line)
        if not match:
            raise GateError(f"{path}, line {number}: the form is not KEY=value")
        versions[match.group(1)] = match.group(2)
    return versions


def read_allowed(path: Path) -> dict[str, tuple[str, str]]:
    """Read the allowed actions: lines `<owner>/<name> <tag> <sha>`."""
    allowed: dict[str, tuple[str, str]] = {}
    try:
        lines = path.read_text(encoding="utf-8").splitlines()
    except OSError as error:
        raise GateError(f"cannot read {path}: {error}") from error
    for number, line in enumerate(lines, start=1):
        if not line.strip() or line.lstrip().startswith("#"):
            continue
        match = re.fullmatch(r"(\S+/\S+) (v[0-9]+(?:\.[0-9]+){0,2}) ([0-9a-f]{40})", line.strip())
        if not match:
            raise GateError(f"{path}, line {number}: the form is not `<owner>/<name> <tag> <sha>`")
        allowed[match.group(1)] = (match.group(2), match.group(3))
    if not allowed:
        raise GateError(f"{path} has no action")
    return allowed


def check_use(location: str, text: str, comment: str | None, allowed: dict[str, tuple[str, str]]) -> list[str]:
    """Check one `uses:` value and its comment. Return the problems."""
    value = USES_VALUE.fullmatch(text)
    if not value:
        return [f"{location}: `uses: {text}` is not `<owner>/<name>@<40 hexadecimal characters>`"]
    name, sha = value.group("name"), value.group("sha")
    if value.group("path"):
        return [f"{location}: `uses: {text}` has a path in the action. The table has the action {name} only"]
    if comment is None:
        return [f"{location}: `uses: {text}` has no comment `# {name} <tag>` on the same line"]
    match = COMMENT.fullmatch(comment)
    if not match or match.group("name") != name:
        return [f"{location}: the comment `#{comment}` must be `# {name} <tag>` (a release tag such as v7.0.1)"]
    tag = match.group("tag")
    if name not in allowed:
        return [f"{location}: the action {name} is not in the table of allowed actions (the license table)"]
    if allowed[name] != (tag, sha):
        return [
            f"{location}: {name} is {tag} {sha}, but the table has {allowed[name][0]} {allowed[name][1]}",
        ]
    return []


def check_inputs(location: str, name: str, with_block: Any, versions: dict[str, str]) -> list[str]:
    """Check the inputs of an action step against tools/versions.env."""
    problems: list[str] = []
    inputs = with_block if isinstance(with_block, dict) else {}
    tool_inputs = TOOL_INPUTS.get(name, {})
    for input_name, key in tool_inputs.items():
        if key not in versions:
            problems.append(f"{location}: {key} is not in tools/versions.env")
            continue
        value = inputs.get(input_name)
        if value is None:
            problems.append(f"{location}: {name} has no input `{input_name}` (it must be {versions[key]})")
        elif not isinstance(value, str):
            problems.append(f"{location}: the input `{input_name}` must be a text in quotes ({value!r})")
        elif value != versions[key]:
            problems.append(
                f"{location}: `{input_name}` is {value}, but {key} in tools/versions.env is {versions[key]}"
            )
    for input_name, expected in FIXED_INPUTS.get(name, {}).items():
        if inputs.get(input_name) != expected:
            problems.append(f"{location}: `{input_name}` of {name} must be {expected}")
    for input_name in inputs:
        if VERSION_KEY.search(str(input_name)) and input_name not in tool_inputs:
            problems.append(f"{location}: the input `{input_name}` of {name} has a version that the gate cannot check")
    return problems


def check_file(
    path: Path, workflow: dict[Any, Any], versions: dict[str, str], allowed: dict[str, tuple[str, str]]
) -> tuple[int, list[str]]:
    """Check one workflow file. Return the number of `uses:` steps and the problems."""
    problems: list[str] = []

    # The text check: each `uses:` line, with its comment.
    from_text: list[tuple[str, str | None, int]] = []
    for number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), start=1):
        match = USES_LINE.match(line)
        if match:
            from_text.append((match.group(1), match.group(2), number))

    # The YAML check: each `uses:` of a step (a job with `uses:` has no steps, and stops iter_steps).
    from_yaml: list[tuple[str, str, Any]] = []
    for job_id, job in iter_jobs(path, workflow):
        for index, step in enumerate(iter_steps(path, job_id, job), start=1):
            if "uses" in step:
                from_yaml.append((f"job '{job_id}', step {index}", str(step["uses"]), step.get("with")))

    if Counter(text for text, _, _ in from_text) != Counter(uses for _, uses, _ in from_yaml):
        problems.append(
            f"{path}: the `uses:` entries in the text and in the YAML are not the same. "
            "Write each `uses: <owner>/<name>@<sha> # <owner>/<name> <tag>` on one line"
        )
        return len(from_yaml), problems

    for text, comment, number in from_text:
        problems += check_use(f"{path}:{number}", text, comment, allowed)
    for where, uses, with_block in from_yaml:
        value = USES_VALUE.fullmatch(uses)
        if value:
            problems += check_inputs(f"{path}, {where}", value.group("name"), with_block, versions)
    return len(from_yaml), problems


def main(argv: list[str]) -> int:
    if len(argv) != 4:
        print("Usage: check_pins.py <versions.env> <workflows-dir> <allowed-actions>", file=sys.stderr)
        return 2
    try:
        versions = read_versions(Path(argv[1]))
        allowed = read_allowed(Path(argv[3]))
        problems: list[str] = []
        total = 0
        for path, workflow in load_workflows(Path(argv[2])):
            count, found = check_file(path, workflow, versions, allowed)
            print(f"{path}: {count} `uses:` step(s), {len(found)} problem(s)")
            total += count
            problems += found
    except GateError as error:
        print(f"ERROR: {error}", file=sys.stderr)
        return 2
    if problems:
        for problem in problems:
            print(f"STOP {problem}")
        print(f"RESULT: STOP. {len(problems)} problem(s).")
        return 1
    print(f"RESULT: PASS. {total} `uses:` step(s) with a full SHA, a comment and the versions of tools/versions.env.")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
