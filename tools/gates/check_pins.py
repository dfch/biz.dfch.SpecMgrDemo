#!/usr/bin/env python3
"""Gate: the pins in the workflows (ACC-013).

feat-5-foundation-monorepo-ci, Task 130.142 (REQ-003, REQ-015).

Usage: check_pins.py <versions.env> <workflows-dir> <allowed-actions> <project-root>

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

The Maven pin (the finding G1 of the review; REQ-003 wants the same Maven version in CI as in
tools/versions.env, and the repository has no Maven setup action). The Maven Wrapper pins Maven in the
repository, so the script looks in <project-root> (not in .git, node_modules, build, target, and from the
root only .specmgr and the fixtures of the gates; EXCLUDED_* below, the same list as manifest_files in
_lib.sh) and stops for each of these:

  * a `.mvn/wrapper/maven-wrapper.properties` whose `distributionUrl` has no file
    `apache-maven-<MAVEN_VERSION>-bin.zip` (or `.tar.gz`), with MAVEN_VERSION of tools/versions.env;
  * a wrapper with no `distributionSha256Sum` (64 hexadecimal characters). The script cannot compare the
    value with versions.env (the file has the sha512 of the tar.gz), so it checks that the value is there;
  * a project with a `pom.xml` and no wrapper (fail closed: sbom.sh does not use the Maven of the runner).

A project with no `pom.xml` and no wrapper passes, and the script says "no Maven project". Until
feat-6-contracts-openapi-pipeline adds the wrapper, a `pom.xml` stops this gate on purpose.

The comment is not in the YAML data, so the script reads the lines of the file for the comment,
and the YAML data for the inputs. Exit codes: 0 pass; 1 a pin is not correct; 2 an error in a file.
"""

import os
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

# The folders that the search for pom.xml and for the wrapper does not enter (see the header). The names
# are at each level; the paths are relative to the project root. manifest_files in _lib.sh has the same list.
# manifest_files also does not list tools/sbom/package.json and tools/sbom/pnpm-lock.yaml (the lock file of
# cdxgen, feat-16-cdxgen-lockfile). This script needs no entry for them: it searches for pom.xml and for the
# Maven Wrapper only.
EXCLUDED_NAMES = {".git", "node_modules", "build", "target"}
EXCLUDED_PATHS = {".specmgr", "tools/license/fixtures", "tools/gates/fixtures"}
WRAPPER_FILE = Path(".mvn") / "wrapper" / "maven-wrapper.properties"


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


def find_files(root: Path, name: str) -> list[Path]:
    """Return the paths (relative to the root) of the files with this name, without the excluded folders."""
    found: list[Path] = []
    for folder, dirs, files in os.walk(root):
        relative = Path(folder).relative_to(root)
        dirs[:] = sorted(d for d in dirs if d not in EXCLUDED_NAMES and (relative / d).as_posix() not in EXCLUDED_PATHS)
        if name in files:
            found.append(relative / name)
    return sorted(found)


def read_properties(path: Path) -> dict[str, str]:
    """Read a Java properties file (lines `key=value`; `#` and `!` start a comment; `\\:` is a colon)."""
    properties: dict[str, str] = {}
    try:
        lines = path.read_text(encoding="utf-8").splitlines()
    except OSError as error:
        raise GateError(f"cannot read {path}: {error}") from error
    for line in lines:
        stripped = line.strip()
        if not stripped or stripped[0] in "#!" or "=" not in stripped:
            continue
        key, value = stripped.split("=", 1)
        properties[key.strip()] = value.strip().replace("\\:", ":")
    return properties


def check_maven(root: Path, versions: dict[str, str]) -> tuple[str, list[str]]:
    """Check the Maven pin (finding G1). Return a message for the log and the problems."""
    if "MAVEN_VERSION" not in versions:
        return "", ["MAVEN_VERSION is not in tools/versions.env"]
    version = versions["MAVEN_VERSION"]
    poms = find_files(root, "pom.xml")
    wrappers = [path for path in find_files(root, "maven-wrapper.properties") if path.parts[-3:] == WRAPPER_FILE.parts]
    if not poms and not wrappers:
        return "no Maven project (no pom.xml and no Maven Wrapper)", []
    problems: list[str] = []
    if poms and not wrappers:
        problems.append(
            f"Maven: {', '.join(str(p) for p in poms)} exists, but no {WRAPPER_FILE} (the Maven Wrapper). "
            f"Add the wrapper for Maven {version}: CI has no Maven setup action and must not use the Maven of the runner"
        )
    url_pattern = re.compile(r"/apache-maven-" + re.escape(version) + r"-bin\.(zip|tar\.gz)")
    for wrapper in wrappers:
        properties = read_properties(root / wrapper)
        url = properties.get("distributionUrl")
        if url is None:
            problems.append(f"Maven: {wrapper} has no `distributionUrl`")
        elif not url_pattern.search(url):
            problems.append(
                f"Maven: {wrapper}: `distributionUrl` is {url}, but MAVEN_VERSION in tools/versions.env is {version} "
                f"(the URL must have apache-maven-{version}-bin.zip)"
            )
        checksum = properties.get("distributionSha256Sum")
        if checksum is None:
            problems.append(f"Maven: {wrapper} has no `distributionSha256Sum` (the sha256 of the Maven download)")
        elif not re.fullmatch(r"[0-9a-fA-F]{64}", checksum):
            problems.append(f"Maven: {wrapper}: `distributionSha256Sum` is not a sha256 value ({checksum!r})")
    note = f"Maven Wrapper: {len(wrappers)} file(s), Maven {version}" if not problems else ""
    return note, problems


def main(argv: list[str]) -> int:
    if len(argv) != 5:
        print("Usage: check_pins.py <versions.env> <workflows-dir> <allowed-actions> <project-root>", file=sys.stderr)
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
        note, maven_problems = check_maven(Path(argv[4]), versions)
        print(f"Maven pin: {note or str(len(maven_problems)) + ' problem(s)'}")
        problems += maven_problems
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
