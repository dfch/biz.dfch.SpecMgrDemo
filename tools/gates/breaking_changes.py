#!/usr/bin/env python3
"""Gate: breaking changes of the OpenAPI file, the ignore file and the version number (REQ-003, REQ-012).

feat-6-contracts-openapi-pipeline, Task 115.120 (ACC-003, ACC-014). The policy is DEC
93594b2b-be54-4f60-9f53-ec2ce6c84be4. breaking-changes.sh finds the base file (the file at the merge base), installs
oasdiff and starts this script.

Usage:
  breaking_changes.py check <oasdiff> <base file> <revision file> <ignore file>
  breaking_changes.py semver <version> <version>      print -1, 0 or 1 (Semantic Versioning 2.0.0 precedence)
  breaking_changes.py rule <base version> <new version>   exit code 0 if rule 5 of the DEC is met (for the tests)

What `check` does:

  1. It reads the ignore file (the format is below). A line that is not correct stops the gate (exit code 1).
  2. It starts oasdiff (`oasdiff breaking <base> <revision> --fail-on ERR`) with no ignore file, and takes the
     changes of the level `error` (the default levels of oasdiff are kept: a new value of an enum in a property of a
     response is an error, and the removal of a value is only `info`).
  3. For each entry it starts oasdiff again with that one entry as the ignore file. The changes that go away are the
     changes that the entry ignores. So the script knows which entry is used and which change is ignored, and it uses
     the matching of oasdiff itself and not its own copy of the rule.
  4. A change of the level `error` that no entry ignores stops the gate (exit code 1). The message has the line that
     the owner can add to the ignore file. A last start of oasdiff with all entries must agree with this result
     (exit code 1 if and only if a change is not ignored), or the script stops with exit code 2.
  5. If at least one entry is used (a breaking change was found and ignored), `info.version` of the revision must
     be higher than `info.version` of the base in the way of rule 5 of the DEC (see version_goes_up), or the gate
     stops (exit code 1).
  6. If no change of the level `error` is there, the gate passes, with entries or without. An entry that matches no
     change is not a failure. The gate writes a WARNING for it (rule 6 of the DEC says that the owner removes it).

The ignore file. Blank lines and lines that start with `#` are not read. Each other line is one entry with four
items, as rule 4 of the DEC wants, separated by ` | ` (a space, a vertical bar and a space):

  <METHOD> <path> <the change as oasdiff names it> | <cause> | #<number of the issue or pull request> | <release>

for example

  GET /status removed the required property `checkedAt` from the response with the `200` status | The field moves to the new member `time` | #123 | 0.2.0

The first item is the line for the option `--err-ignore` of oasdiff (`oasdiff breaking -f singleline` prints the
text of a change, and the gate prints the whole line for each change that it stops). `<release>` is the release after
which the entry ends: a version in the form of Semantic Versioning 2.0.0. The gate gives only the first item to
oasdiff, so a comment line or the text of the other items cannot ignore a change by chance (oasdiff reads a line that
starts with `#` as a normal entry, and it ignores a text after the message).

oasdiff reads a configuration file `.oasdiff.*` or `oasdiff.*` in its current folder, and the variable
OASDIFF_CONFIG. A file like this could set `err-ignore` and switch off the check. So the script starts oasdiff in a
new empty folder and without the variables OASDIFF_*.

Exit codes: 0 pass; 1 the gate stops (a breaking change that is not ignored, an entry that is used with a version that
is not higher, an entry that is not correct, a version that is not correct); 2 the gate cannot decide (oasdiff does not
start or cannot read a file, or its results disagree).
"""

import json
import os
import re
import subprocess
import sys
import tempfile
from pathlib import Path
from typing import NamedTuple

ERROR_LEVEL = 3  # the level `error` in the JSON of oasdiff (1 info, 2 warn, 3 err)
OASDIFF_TIMEOUT_SECONDS = 120

# Semantic Versioning 2.0.0, the regular expression of semver.org.
SEMVER = re.compile(
    r"(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)"
    r"(?:-((?:0|[1-9][0-9]*|[0-9]*[a-zA-Z-][0-9a-zA-Z-]*)(?:\.(?:0|[1-9][0-9]*|[0-9]*[a-zA-Z-][0-9a-zA-Z-]*))*))?"
    r"(?:\+([0-9a-zA-Z-]+(?:\.[0-9a-zA-Z-]+)*))?"
)
CHANGE = re.compile(r"[A-Za-z]+ /\S* \S.*")
ISSUE = re.compile(r"#[0-9]+")
ENTRY_SEPARATOR = " | "


class GateError(Exception):
    """The gate cannot decide (exit code 2)."""


class SemVer(NamedTuple):
    """A version of Semantic Versioning 2.0.0. The build metadata is not kept: it has no precedence."""

    major: int
    minor: int
    patch: int
    pre: tuple[str, ...]


class Entry(NamedTuple):
    """One entry of the ignore file (the four items of rule 4 of the DEC)."""

    line: int
    change: str
    cause: str
    issue: str
    release: str


class Change(NamedTuple):
    """A change of the level `error` that oasdiff found."""

    id: str
    operation: str
    path: str
    text: str


def parse_semver(text: str) -> SemVer | None:
    """Parse a version of Semantic Versioning 2.0.0. Return None if the text is not one."""
    match = SEMVER.fullmatch(text)
    if not match:
        return None
    pre = tuple(match.group(4).split(".")) if match.group(4) else ()
    return SemVer(int(match.group(1)), int(match.group(2)), int(match.group(3)), pre)


def _compare_identifiers(left: str, right: str) -> int:
    """Compare two identifiers of a pre-release (SemVer 2.0.0, point 11.4)."""
    left_numeric, right_numeric = left.isdigit(), right.isdigit()
    if left_numeric and right_numeric:
        return (int(left) > int(right)) - (int(left) < int(right))
    if left_numeric:
        return -1  # a numeric identifier is lower than an identifier with letters
    if right_numeric:
        return 1
    return (left > right) - (left < right)  # ASCII order


def compare_semver(left: SemVer, right: SemVer) -> int:
    """Return -1, 0 or 1: the precedence of two versions (SemVer 2.0.0, point 11). The build metadata is not used."""
    for first, second in (
        (left.major, right.major),
        (left.minor, right.minor),
        (left.patch, right.patch),
    ):
        if first != second:
            return -1 if first < second else 1
    if not left.pre and not right.pre:
        return 0
    if not left.pre:
        return 1  # a version with no pre-release is higher than one with a pre-release
    if not right.pre:
        return -1
    for first_id, second_id in zip(left.pre, right.pre):
        result = _compare_identifiers(first_id, second_id)
        if result:
            return result
    return (len(left.pre) > len(right.pre)) - (len(left.pre) < len(right.pre))


def version_goes_up(base: SemVer, new: SemVer) -> tuple[bool, str]:
    """Rule 5 of the DEC. Return (met, the reason in a text).

    The version must be higher by the precedence of SemVer 2.0.0. In addition, as the DEC says: if the first number of
    the base is 0, the second number must go up (the first number and the second number together must be higher: so
    0.1.0 to 0.2.0 and 0.1.0 to 1.0.0 are correct, and 0.1.0 to 0.1.1 is not). If the first number of the base is not 0,
    the first number must go up. A pre-release (1.0.0-rc.1) is only a version with a lower precedence than the release,
    and it follows the same rule.
    """
    if compare_semver(new, base) <= 0:
        return False, "the new version is not higher than the version of the base"
    if base.major == 0:
        if (new.major, new.minor) > (base.major, base.minor):
            return (
                True,
                "the first number of the base is 0 and the second number goes up",
            )
        return (
            False,
            "the first number of the base is 0, so the second number must go up (or the first number)",
        )
    if new.major > base.major:
        return True, "the first number goes up"
    return (
        False,
        "the first number of the base is not 0, so the first number must go up",
    )


def parse_ignore_file(path: Path) -> tuple[list[Entry], list[str]]:
    """Read the ignore file (see the header). Return the entries and the problems."""
    try:
        lines = path.read_text(encoding="utf-8").splitlines()
    except (OSError, UnicodeDecodeError) as error:
        raise GateError(f"cannot read the ignore file {path}: {error}") from error
    entries: list[Entry] = []
    problems: list[str] = []
    seen: dict[str, int] = {}
    for number, line in enumerate(lines, start=1):
        text = line.strip()
        if not text or text.startswith("#"):
            continue
        where = f"{path}, line {number}"
        parts = [part.strip() for part in text.rsplit(ENTRY_SEPARATOR, 3)]
        if len(parts) != 4 or not all(parts):
            problems.append(
                f"{where}: an entry has four items with `{ENTRY_SEPARATOR}` between them: "
                "`<METHOD> <path> <the change> | <cause> | #<issue or pull request> | <release>`"
            )
            continue
        change, cause, issue, release = parts
        if not CHANGE.fullmatch(change):
            problems.append(
                f"{where}: the first item `{change}` is not `<METHOD> <path> <the change as oasdiff names it>`"
            )
            continue
        if not ISSUE.fullmatch(issue):
            problems.append(
                f"{where}: the third item `{issue}` is not the number of an issue or a pull request (`#123`)"
            )
            continue
        if parse_semver(release) is None:
            problems.append(
                f"{where}: the fourth item `{release}` is not a release version (Semantic Versioning 2.0.0)"
            )
            continue
        key = change.lower()
        if key in seen:
            problems.append(f"{where}: the change is already in line {seen[key]}")
            continue
        seen[key] = number
        entries.append(Entry(number, change, cause, issue, release))
    return entries, problems


def oasdiff_env() -> dict[str, str]:
    """The environment for oasdiff: the same as ours, without the variables OASDIFF_* (OASDIFF_CONFIG)."""
    return {name: value for name, value in os.environ.items() if not name.upper().startswith("OASDIFF_")}


def run_oasdiff(oasdiff: str, base: Path, revision: Path, ignore_lines: list[str] | None) -> tuple[int, list[Change]]:
    """Start `oasdiff breaking` and return the exit code and the changes of the level error.

    ignore_lines is None (no ignore file) or the lines for --err-ignore. The exit code is 0 or 1 (the option
    --fail-on ERR). Another exit code of oasdiff (it cannot read a file: 102) is a GateError.
    """
    with tempfile.TemporaryDirectory() as folder:
        command = [
            oasdiff,
            "breaking",
            str(base.resolve()),
            str(revision.resolve()),
            "--format",
            "json",
            "--fail-on",
            "ERR",
            "--lang",
            "en",
        ]
        if ignore_lines is not None:
            ignore_file = Path(folder) / "ignore.txt"
            ignore_file.write_text("".join(f"{line}\n" for line in ignore_lines), encoding="utf-8")
            command += ["--err-ignore", str(ignore_file)]
        try:
            result = subprocess.run(
                command,
                cwd=folder,
                env=oasdiff_env(),
                capture_output=True,
                text=True,
                timeout=OASDIFF_TIMEOUT_SECONDS,
                check=False,
            )
        except (OSError, subprocess.SubprocessError) as error:
            raise GateError(f"oasdiff did not run: {error}") from error
    if result.returncode not in (0, 1):
        raise GateError(f"oasdiff returned exit code {result.returncode}: {(result.stderr or result.stdout).strip()}")
    try:
        data = json.loads(result.stdout)
    except ValueError as error:
        raise GateError(f"the output of oasdiff is not JSON: {error}: {result.stdout[:200]!r}") from error
    if not isinstance(data, list):
        raise GateError("the output of oasdiff is not a JSON list")
    changes: list[Change] = []
    for item in data:
        if not isinstance(item, dict) or not all(key in item for key in ("id", "text", "level", "path")):
            raise GateError(f"an item of the output of oasdiff has not the members id, text, level and path: {item!r}")
        if item["level"] == ERROR_LEVEL:
            changes.append(
                Change(
                    str(item["id"]),
                    str(item.get("operation", "")),
                    str(item["path"]),
                    str(item["text"]),
                )
            )
    return result.returncode, changes


def read_version(path: Path, label: str) -> tuple[SemVer | None, str]:
    """Read `info.version` of an OpenAPI file. Return the version (None if it is not correct) and a message."""
    import yaml  # PyYAML comes from the lock file (make_python_env), and `semver` and `rule` do not need it

    try:
        document = yaml.safe_load(path.read_text(encoding="utf-8"))
    except (OSError, UnicodeDecodeError, yaml.YAMLError) as error:
        raise GateError(f"cannot read {label} ({path}): {error}") from error
    info = document.get("info") if isinstance(document, dict) else None
    version = info.get("version") if isinstance(info, dict) else None
    if not isinstance(version, str):
        return (
            None,
            f"{label} has no `info.version` that is a text (it is {version!r}). Write it in quotes if YAML reads it as a number",
        )
    parsed = parse_semver(version)
    if parsed is None:
        return (
            None,
            f"`info.version` of {label} is {version!r}, which is not a version of Semantic Versioning 2.0.0",
        )
    return parsed, version


def suggested_line(change: Change) -> str:
    """The first item of an entry for a change: the line for --err-ignore."""
    return f"{change.operation} {change.path} {change.text}"


def check(oasdiff: str, base: Path, revision: Path, ignore_file: Path) -> int:
    """The gate. See the header. Return the exit code."""
    entries, problems = parse_ignore_file(ignore_file)
    if problems:
        for problem in problems:
            print(f"STOP {problem}")
        print(f"STOP: the ignore file {ignore_file} has {len(problems)} line(s) that are not correct.")
        return 1

    _, found = run_oasdiff(oasdiff, base, revision, None)
    print(f"oasdiff: {len(found)} breaking change(s) (level error) between the base and the revision")
    for change in found:
        print(f"  {suggested_line(change)} [{change.id}]")

    used: set[Change] = set()
    used_entries: list[Entry] = []
    stale: list[Entry] = []
    if found:
        for entry in entries:
            _, remaining = run_oasdiff(oasdiff, base, revision, [entry.change])
            ignored = set(found) - set(remaining)
            if ignored:
                used |= ignored
                used_entries.append(entry)
            else:
                stale.append(entry)
    else:
        stale = list(entries)

    unignored = [change for change in found if change not in used]
    all_code, all_remaining = run_oasdiff(oasdiff, base, revision, [entry.change for entry in entries])
    if (all_code == 1) != bool(unignored) or len(all_remaining) != len(unignored):
        raise GateError(
            "oasdiff with all entries does not agree with the check of each entry "
            f"(exit code {all_code}, {len(all_remaining)} change(s) left, the script expected {len(unignored)})"
        )

    for entry in stale:
        print(
            f"WARNING {ignore_file}, line {entry.line}: the entry matches no breaking change: `{entry.change}`. "
            "The owner removes an entry that matches no change (rule 6 of DEC 93594b2b-be54-4f60-9f53-ec2ce6c84be4)."
        )

    if unignored:
        for change in unignored:
            print(f"STOP breaking change that no entry ignores: {suggested_line(change)} [{change.id}]")
        print(
            "To accept a change, the owner adds one line to the ignore file, and the version of the interface goes up "
            f"(DEC 93594b2b-be54-4f60-9f53-ec2ce6c84be4). The line has four items, for example:\n"
            f"  {suggested_line(unignored[0])} | <cause> | #<issue or pull request> | <release>"
        )
        print(f"RESULT: STOP. {len(unignored)} breaking change(s) have no entry in {ignore_file}.")
        return 1

    if not used_entries:
        print("RESULT: PASS. No breaking change.")
        return 0

    base_version, base_text = read_version(base, "the base file")
    new_version, new_text = read_version(revision, "the revision file")
    if base_version is None or new_version is None:
        for text in (
            base_text if base_version is None else "",
            new_text if new_version is None else "",
        ):
            if text:
                print(f"STOP {text}")
        print("RESULT: STOP. The breaking changes have entries, but the version of the interface cannot be compared.")
        return 1
    met, reason = version_goes_up(base_version, new_version)
    for entry in used_entries:
        print(
            f"entry in line {entry.line} is used: `{entry.change}` ({entry.issue}, ends after the release {entry.release})"
        )
    if not met:
        print(
            f"STOP `info.version` is {new_text} and the version of the base is {base_text}: {reason}. "
            "An accepted breaking change needs a higher version of the interface in the same pull request "
            "(rule 5 of DEC 93594b2b-be54-4f60-9f53-ec2ce6c84be4)."
        )
        print(f"RESULT: STOP. {len(used)} breaking change(s) are ignored, but the version does not go up.")
        return 1
    print(f"`info.version` goes from {base_text} to {new_text}: {reason}.")
    print(
        f"RESULT: PASS. {len(used)} breaking change(s) are ignored by {len(used_entries)} entry(ies), and the version goes up."
    )
    return 0


USAGE = (
    "Usage: breaking_changes.py check <oasdiff> <base file> <revision file> <ignore file>\n"
    "       breaking_changes.py semver <version> <version>\n"
    "       breaking_changes.py rule <base version> <new version>"
)


def main(argv: list[str]) -> int:
    try:
        if len(argv) == 6 and argv[1] == "check":
            return check(argv[2], Path(argv[3]), Path(argv[4]), Path(argv[5]))
        if len(argv) == 4 and argv[1] in ("semver", "rule"):
            left, right = parse_semver(argv[2]), parse_semver(argv[3])
            if left is None or right is None:
                wrong = argv[2] if left is None else argv[3]
                print(f"ERROR: {wrong!r} is not a version of Semantic Versioning 2.0.0", file=sys.stderr)
                return 2
            if argv[1] == "semver":
                print(compare_semver(left, right))
                return 0
            met, reason = version_goes_up(left, right)
            print(reason)
            return 0 if met else 1
    except GateError as error:
        print(f"ERROR: {error}", file=sys.stderr)
        return 2
    print(USAGE, file=sys.stderr)
    return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv))
