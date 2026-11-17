#!/usr/bin/env python3
"""feat-9-walking-skeleton, Tasks 500.110 and 500.120 (REQ-006, ACC-007)

The level gate of the three security recipes (vuln-scan.sh, secret-scan.sh, workflow-scan.sh). It reads the findings of
the tool in a machine-readable form, and the baseline file of the tool, and it decides. The mechanism is the section
"A threshold, and the baseline file" of tools/security/README.md.

Usage: security_threshold.py <tool> <baseline file> <report file>...

  <tool>           osv (OSV-Scanner, `--format json`), gitleaks (`--report-format json`, one report file for each
                   scan) or zizmor (`--format json-v1`)
  <baseline file>  tools/security/<tool>-baseline.txt: one line for each finding of the state of the feature, the
                   identifier only. Empty lines and lines that start with `#` are comments. The form of a line:
                     osv       <OSV identifier> <package>@<version>      GHSA-4mjr-xmp4-gh2g qs@6.15.1
                     gitleaks  the fingerprint of gitleaks               <file>:<rule>:<line>, or <commit>:<file>:<rule>:<line>
                     zizmor    <audit> <file> <route>                    artipacked .github/workflows/ci.yml jobs/lint/steps/0
                   The file has counts and identifiers only (no advisory text, no report text): this is the condition
                   of the deviation for the OSV data (DEC 93a6d588-e002-4daf-9a47-45e2d77786e9).
  <report file>    the report of the tool (JSON). gitleaks has two (the files and the history), the others have one.

The decision:
  - A finding that is Critical or High stops the gate in each case, also if the baseline has a line for it (the baseline
    must have no line of these levels: a line that has such a finding is an error of the feature, and the gate says so).
  - A finding that is not in the baseline is a new finding, and it stops the gate (each level).
  - A line of the baseline that has no finding any more is a warning (the baseline can be made smaller). It does not stop.
  - A finding of the baseline that is not Critical or High passes.

The level of a finding (the mapping of each tool):
  - OSV-Scanner: the CVSS base score of the group of the finding (`max_severity`, the same value that the table of
    OSV-Scanner shows): 9.0 or more is Critical, 7.0 to 8.9 is High, 4.0 to 6.9 is Medium, below 4.0 is Low. If the
    record has no score, the label of the database (`database_specific.severity`: CRITICAL, HIGH, MODERATE, LOW) is
    used. If both are there, the higher level is used. A finding with neither is Unknown (it is no stop by its level;
    if it is new, it stops as a new finding).
  - zizmor: the severity of the audit (Informational, Low, Medium, High). zizmor has no level Critical. High stops in
    each case. A finding that zizmor suppresses (its own `ignored` mark) is no finding.
  - gitleaks: no level (gitleaks gives no severity). The level is Unrated, and the only rule is the baseline: a secret
    that is not in the baseline stops. The one place that hides a false positive is the allowlist of gitleaks.toml.
    (The decision is in the plan of feat-9, Decisions Made. The constant GITLEAKS_LEVEL is the one place to change it:
    with the value Critical, each secret would stop in each case, and the baseline of gitleaks could have no line.)

Exit codes:
  0  the gate passes (no new finding, no finding that is Critical or High; stale lines are warnings)
  1  the gate stops (a new finding, or a finding that is Critical or High)
  2  an input that cannot be used: a baseline file or a report file that is missing or cannot be read, a line of the
     baseline with a wrong form or a line twice, or a report with another form. The caller treats it as a failure of
     the tool (it stops, as the failure of the tool).

The script uses the standard library only (the environment of the gate has no package for it). It prints the findings
with the level, the identifier, the package or the file, and the state (baseline or NEW), and it prints no text of the
records of the tool.
"""

from __future__ import annotations

import json
import re
import sys
from dataclasses import dataclass
from pathlib import Path

CRITICAL = "Critical"
HIGH = "High"
MEDIUM = "Medium"
LOW = "Low"
INFORMATIONAL = "Informational"
UNKNOWN = "Unknown"
UNRATED = "Unrated"

# The levels, the highest first. The levels that stop in each case are BLOCKING.
RANK = {
    CRITICAL: 5,
    HIGH: 4,
    MEDIUM: 3,
    LOW: 2,
    INFORMATIONAL: 1,
    UNKNOWN: 0,
    UNRATED: 0,
}
BLOCKING = (CRITICAL, HIGH)
SUMMARY_LEVELS = (CRITICAL, HIGH, MEDIUM, LOW, INFORMATIONAL, UNKNOWN, UNRATED)

# gitleaks gives no severity. The level is Unrated, and the baseline decides (see the text at the top of this file).
GITLEAKS_LEVEL = UNRATED

EXIT_PASS = 0
EXIT_STOP = 1
EXIT_INPUT = 2


class InputError(Exception):
    """An input that cannot be used (exit code 2)."""


@dataclass(frozen=True)
class Finding:
    key: str
    level: str
    detail: str


def level_of_score(score: float) -> str:
    if score >= 9.0:
        return CRITICAL
    if score >= 7.0:
        return HIGH
    if score >= 4.0:
        return MEDIUM
    if score > 0.0:
        return LOW
    return UNKNOWN


def level_of_label(label: object) -> str:
    mapping = {
        "CRITICAL": CRITICAL,
        "HIGH": HIGH,
        "MODERATE": MEDIUM,
        "MEDIUM": MEDIUM,
        "LOW": LOW,
    }
    return mapping.get(str(label).strip().upper(), UNKNOWN)


def higher(first: str, second: str) -> str:
    return first if RANK[first] >= RANK[second] else second


def read_json(path: Path) -> object:
    try:
        text = path.read_text(encoding="utf-8")
    except OSError as error:
        raise InputError(
            f"the report file cannot be read: {path} ({error.strerror})"
        ) from error
    try:
        return json.loads(text)
    except ValueError as error:
        raise InputError(f"the report file is not JSON: {path} ({error})") from error


def findings_osv(data: object, path: Path) -> list[Finding]:
    if not isinstance(data, dict) or not isinstance(data.get("results"), list):
        raise InputError(f"{path}: the report of OSV-Scanner has no list `results`")
    findings: dict[str, Finding] = {}
    for result in data["results"]:
        for package in result.get("packages", []) if isinstance(result, dict) else []:
            info = package.get("package", {})
            name, version = info.get("name"), info.get("version")
            if (
                not isinstance(name, str)
                or not isinstance(version, str)
                or not name
                or not version
            ):
                raise InputError(
                    f"{path}: a package of the report of OSV-Scanner has no name or no version"
                )
            labels = {}
            for vulnerability in package.get("vulnerabilities", []):
                label = (vulnerability.get("database_specific") or {}).get("severity")
                if label is not None and "id" in vulnerability:
                    labels[vulnerability["id"]] = label
            for group in package.get("groups", []):
                ids = group.get("ids") or []
                if not ids or not all(isinstance(item, str) and item for item in ids):
                    raise InputError(
                        f"{path}: a group of {name}@{version} has no identifier"
                    )
                identifier = sorted(ids)[0]
                level, detail = UNKNOWN, "no score"
                try:
                    score = float(group.get("max_severity"))
                except (TypeError, ValueError):
                    score = None
                if score is not None:
                    level, detail = level_of_score(score), f"CVSS {score:.1f}"
                for item in ids:
                    if item in labels:
                        level = higher(level, level_of_label(labels[item]))
                key = f"{identifier} {name}@{version}"
                previous = findings.get(key)
                if previous is None or RANK[level] > RANK[previous.level]:
                    findings[key] = Finding(key, level, detail)
    return list(findings.values())


def findings_gitleaks(data: object, path: Path) -> list[Finding]:
    if not isinstance(data, list):
        raise InputError(f"{path}: the report of gitleaks is not a list")
    findings: dict[str, Finding] = {}
    for item in data:
        if not isinstance(item, dict):
            raise InputError(
                f"{path}: an entry of the report of gitleaks is not an object"
            )
        fingerprint = item.get("Fingerprint")
        if not isinstance(fingerprint, str) or not fingerprint:
            raise InputError(
                f"{path}: an entry of the report of gitleaks has no fingerprint"
            )
        findings.setdefault(
            fingerprint,
            Finding(fingerprint, GITLEAKS_LEVEL, f"rule {item.get('RuleID', '?')}"),
        )
    return list(findings.values())


def route_text(route: object) -> str:
    """`jobs/lint/steps/0` for the route of a location of zizmor (the keys and the indexes of the YAML path)."""
    parts: list[str] = []
    steps = route.get("route") if isinstance(route, dict) else None
    for step in steps or []:
        if isinstance(step, dict) and "Key" in step:
            parts.append(str(step["Key"]))
        elif isinstance(step, dict) and "Index" in step:
            parts.append(str(step["Index"]))
    return "/".join(parts) or "-"


def findings_zizmor(data: object, path: Path) -> list[Finding]:
    if not isinstance(data, list):
        raise InputError(f"{path}: the report of zizmor is not a list")
    levels = {
        "HIGH": HIGH,
        "MEDIUM": MEDIUM,
        "LOW": LOW,
        "INFORMATIONAL": INFORMATIONAL,
    }
    findings: dict[str, Finding] = {}
    for item in data:
        if (
            not isinstance(item, dict)
            or not isinstance(item.get("ident"), str)
            or not item["ident"]
        ):
            raise InputError(
                f"{path}: an entry of the report of zizmor has no audit (`ident`)"
            )
        if item.get("ignored") is True:
            continue
        locations = item.get("locations") or []
        primary = next(
            (
                loc
                for loc in locations
                if (loc.get("symbolic") or {}).get("kind") == "Primary"
            ),
            None,
        )
        symbolic = (primary or (locations[0] if locations else {})).get(
            "symbolic"
        ) or {}
        local = (symbolic.get("key") or {}).get("Local") or {}
        file_name = local.get("verbatim_path") or local.get("given_path")
        if not isinstance(file_name, str) or not file_name:
            raise InputError(
                f"{path}: the finding `{item['ident']}` of zizmor has no file"
            )
        determinations = item.get("determinations") or {}
        level = levels.get(
            str(determinations.get("severity", "")).strip().upper(), UNKNOWN
        )
        key = f"{item['ident']} {file_name} {route_text(symbolic.get('route'))}"
        previous = findings.get(key)
        if previous is None or RANK[level] > RANK[previous.level]:
            findings[key] = Finding(
                key, level, f"confidence {determinations.get('confidence', '?')}"
            )
    return list(findings.values())


READERS = {
    "osv": findings_osv,
    "gitleaks": findings_gitleaks,
    "zizmor": findings_zizmor,
}
LABELS = {"osv": "OSV-Scanner", "gitleaks": "gitleaks", "zizmor": "zizmor"}
# The form of a baseline line (None: any text that is not empty). OSV: the identifier, a space, name@version.
LINE_FORMS = {
    "osv": re.compile(r"^[A-Za-z0-9._-]+ \S+@[^\s@]+$"),
    "gitleaks": None,
    "zizmor": re.compile(r"^[a-z0-9-]+ \S+ \S+$"),
}
LINE_HELP = {
    "osv": "<OSV identifier> <package>@<version>",
    "gitleaks": "the fingerprint of gitleaks",
    "zizmor": "<audit> <file> <route>",
}


def read_baseline(tool: str, path: Path) -> list[tuple[int, str]]:
    try:
        text = path.read_text(encoding="utf-8")
    except OSError as error:
        raise InputError(
            f"the baseline file cannot be read: {path} ({error.strerror})"
        ) from error
    lines: list[tuple[int, str]] = []
    seen: dict[str, int] = {}
    form = LINE_FORMS[tool]
    for number, raw in enumerate(text.splitlines(), start=1):
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        if form is not None and not form.match(line):
            raise InputError(
                f"{path}:{number}: the line is not of the form `{LINE_HELP[tool]}`: {line}"
            )
        if line in seen:
            raise InputError(
                f"{path}:{number}: the line is twice in the baseline (first at line {seen[line]}): {line}"
            )
        seen[line] = number
        lines.append((number, line))
    return lines


def summary(findings: list[Finding]) -> str:
    counts = {
        level: sum(1 for item in findings if item.level == level)
        for level in SUMMARY_LEVELS
    }
    parts = [
        f"{counts[level]} {level}"
        for level in SUMMARY_LEVELS
        if level != UNRATED or counts[level]
    ]
    return f"{len(findings)} finding(s) ({', '.join(parts)})"


def decide(tool: str, baseline_path: Path, report_paths: list[Path]) -> int:
    label = LABELS[tool]
    baseline = read_baseline(tool, baseline_path)
    baseline_keys = {line for _, line in baseline}
    merged: dict[str, Finding] = {}
    for report_path in report_paths:
        for finding in READERS[tool](read_json(report_path), report_path):
            previous = merged.get(finding.key)
            if previous is None or RANK[finding.level] > RANK[previous.level]:
                merged[finding.key] = finding
    findings = sorted(merged.values(), key=lambda item: (-RANK[item.level], item.key))

    print(
        f"SUMMARY: {label}: {summary(findings)}; baseline {baseline_path.name}: {len(baseline)} line(s)"
    )
    for finding in findings:
        state = "baseline" if finding.key in baseline_keys else "NEW"
        print(f"  {finding.level:<13} {state:<8} {finding.key} ({finding.detail})")

    new = [item for item in findings if item.key not in baseline_keys]
    blocking = [item for item in findings if item.level in BLOCKING]
    bad_lines = [item for item in blocking if item.key in baseline_keys]
    stale = [line for _, line in baseline if line not in merged]

    for line in stale:
        print(
            f"WARNING: the baseline line has no finding any more, so the baseline can be made smaller: {line}",
            file=sys.stderr,
        )
    for item in bad_lines:
        print(
            f"ERROR OF THE FEATURE: the baseline has a line for a finding that is {item.level} (the baseline must have "
            f"no line of the levels {' or '.join(BLOCKING)}): {item.key}",
            file=sys.stderr,
        )
    for item in blocking:
        print(
            f"STOP: a finding that is {item.level} stops in each case: {item.key} ({item.detail})",
            file=sys.stderr,
        )
    for item in new:
        if item.level not in BLOCKING:
            print(
                f"STOP: a new finding that is not in the baseline ({item.level}): {item.key} ({item.detail})",
                file=sys.stderr,
            )

    if new or blocking:
        print(
            f"RESULT: STOP. {len(new)} new finding(s), {len(blocking)} finding(s) that are Critical or High, "
            f"{len(stale)} old baseline line(s)."
        )
        return EXIT_STOP
    print(
        f"RESULT: PASS. {len(findings)} finding(s), all in the baseline, none Critical or High; {len(stale)} old baseline line(s)."
    )
    return EXIT_PASS


def main(argv: list[str]) -> int:
    if len(argv) < 4 or argv[1] not in READERS:
        print(
            "Usage: security_threshold.py <osv|gitleaks|zizmor> <baseline file> <report file>...",
            file=sys.stderr,
        )
        return EXIT_INPUT
    try:
        return decide(argv[1], Path(argv[2]), [Path(item) for item in argv[3:]])
    except InputError as error:
        print(f"ERROR: {error}", file=sys.stderr)
        return EXIT_INPUT


if __name__ == "__main__":
    sys.exit(main(sys.argv))
