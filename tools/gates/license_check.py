#!/usr/bin/env python3
"""Gate: compare the licenses in CycloneDX SBOM files with the list of permitted licenses.

feat-5-foundation-monorepo-ci, Task 130.130 (REQ-006, DEC 84c37f7d-08cb-457d-8ab3-1db37dba9bc9).

Usage: license_check.py <sbom-dir> <permitted-list> <names-table>

The script is started by license-check.sh in a temporary virtual environment that has
`license-expression` (installed with checksums). It does not parse license expressions. The library `license-expression` does this. The
script only evaluates the parsed tree against the list:

  * OR   is permitted if any alternative is permitted.
  * AND  is permitted if all parts are permitted.
  * `X WITH Y` is ONE symbol. It must be in the list as a complete expression.
  * Parentheses are handled by the library.

The script fails closed. A license is "not known" (and the gate stops) if the library cannot
parse the expression, if the expression has a license or an exception that is not on the
SPDX list, if a component has no license, or if a license name is not in the table of names.
A license that is known but not in the list is "not permitted" (and the gate stops).

Exit codes: 0 all licenses permitted; 1 at least one license not permitted or not known;
2 an error in a file (SBOM, list or table), so the gate cannot decide.
"""

import json
import re
import sys
from pathlib import Path
from typing import Any

from license_expression import LicenseSymbol, LicenseWithExceptionSymbol, get_spdx_licensing

PERMITTED = "PERMITTED"
NOT_PERMITTED = "NOT PERMITTED"
NOT_KNOWN = "NOT KNOWN"

# The library maps these prefixes to SPDX licenses with its own aliases (for example
# LicenseRef-Apache to Apache-2.0). They are not SPDX license identifiers, so they are not known.
_REF_PATTERN = re.compile(r"(DocumentRef|LicenseRef)-", re.IGNORECASE)


class GateError(Exception):
    """A file is wrong, so the gate cannot decide (exit code 2)."""


class Unknown(Exception):
    """A license is not known (the gate stops)."""


class Policy:
    """The list of permitted licenses, the table of names and the evaluation."""

    def __init__(self, permitted_file: Path, names_file: Path) -> None:
        self.licensing = get_spdx_licensing()
        self.permitted = self._load_permitted(permitted_file)
        self.names = self._load_names(names_file)

    def _normalize(self, text: str) -> Any:
        """Parse text to a tree. Raise Unknown if the library cannot do it, or finds a wrong symbol."""
        if not isinstance(text, str) or not text.strip():
            raise Unknown("empty license expression")
        if _REF_PATTERN.search(text):
            raise Unknown("LicenseRef and DocumentRef are not SPDX license identifiers")
        try:
            info = self.licensing.validate(text)
            if info.errors or info.invalid_symbols or info.normalized_expression is None:
                raise Unknown("; ".join(info.errors) or "the expression is not valid")
            tree = self.licensing.parse(text)
        except Unknown:
            raise
        except Exception as error:  # the library can raise other errors (fail closed)
            raise Unknown(f"the library cannot parse the expression ({type(error).__name__}: {error})") from error
        if tree is None:
            raise Unknown("the library found no license in the expression")
        return tree

    def _load_lines(self, path: Path) -> list[str]:
        try:
            lines = path.read_text(encoding="utf-8").splitlines()
        except OSError as error:
            raise GateError(f"cannot read {path}: {error}") from error
        return [line.strip() for line in lines if line.strip() and not line.lstrip().startswith("#")]

    def _load_permitted(self, path: Path) -> set[str]:
        permitted: set[str] = set()
        for entry in self._load_lines(path):
            try:
                tree = self._normalize(entry)
            except Unknown as error:
                raise GateError(f"{path}: the entry '{entry}' is not valid: {error}") from error
            if not isinstance(tree, (LicenseSymbol, LicenseWithExceptionSymbol)):
                raise GateError(f"{path}: the entry '{entry}' must be one license or one `license WITH exception`")
            permitted.add(str(tree))
        if not permitted:
            raise GateError(f"{path}: the list of permitted licenses is empty")
        return permitted

    def _load_names(self, path: Path) -> dict[str, str]:
        names: dict[str, str] = {}
        for entry in self._load_lines(path):
            name, separator, expression = entry.partition(" => ")
            if not separator:
                raise GateError(f"{path}: the line '{entry}' must have the form `name => SPDX expression`")
            try:
                self._normalize(expression.strip())
            except Unknown as error:
                raise GateError(f"{path}: the entry '{entry}' is not valid: {error}") from error
            names[" ".join(name.split())] = expression.strip()
        return names

    def _evaluate(self, node: Any) -> bool:
        if isinstance(node, LicenseWithExceptionSymbol):
            return str(node) in self.permitted
        if isinstance(node, LicenseSymbol):
            return node.key in self.permitted
        if isinstance(node, self.licensing.AND):
            return all(self._evaluate(argument) for argument in node.args)
        if isinstance(node, self.licensing.OR):
            return any(self._evaluate(argument) for argument in node.args)
        raise Unknown(f"unexpected element in the expression: {type(node).__name__}")

    def classify_expression(self, text: str) -> tuple[str, str]:
        """Return (status, detail) for one SPDX expression."""
        try:
            tree = self._normalize(text)
            permitted = self._evaluate(tree)
        except Unknown as error:
            return NOT_KNOWN, str(error)
        if permitted:
            return PERMITTED, str(tree)
        return NOT_PERMITTED, str(tree)

    def classify_name(self, name: str) -> tuple[str, str]:
        """Return (status, detail) for a license name that is not an SPDX identifier."""
        expression = self.names.get(" ".join(str(name).split()))
        if expression is None:
            return NOT_KNOWN, f"the license name '{name}' is not in the table of names"
        status, detail = self.classify_expression(expression)
        return status, f"name '{name}' is {detail}"

    def classify_choice(self, choice: Any) -> tuple[str, str]:
        """Return (status, detail) for one entry of `licenses` of a component."""
        if not isinstance(choice, dict):
            return NOT_KNOWN, "an entry of licenses is not an object"
        if "expression" in choice:
            return self.classify_expression(choice["expression"])
        license_object = choice.get("license")
        if isinstance(license_object, dict):
            if "id" in license_object:
                return self.classify_expression(license_object["id"])
            if "name" in license_object:
                return self.classify_name(license_object["name"])
        return NOT_KNOWN, "the entry has no license id, name or expression"

    def classify_component(self, component: dict[str, Any]) -> tuple[str, str]:
        """All entries in `licenses` of one component must be permitted (the strict reading)."""
        choices = component.get("licenses")
        if not isinstance(choices, list) or not choices:
            return NOT_KNOWN, "the component has no license in the SBOM"
        results = [self.classify_choice(choice) for choice in choices]
        details = " AND ".join(detail for _, detail in results)
        statuses = {status for status, _ in results}
        if NOT_KNOWN in statuses:
            return NOT_KNOWN, details
        if NOT_PERMITTED in statuses:
            return NOT_PERMITTED, details
        return PERMITTED, details


def iter_components(components: Any, where: str) -> list[dict[str, Any]]:
    """Return all components, with the nested ones."""
    if not isinstance(components, list):
        raise GateError(f"{where}: `components` is not a list")
    found: list[dict[str, Any]] = []
    for component in components:
        if not isinstance(component, dict):
            raise GateError(f"{where}: an entry of `components` is not an object")
        found.append(component)
        if "components" in component:
            found.extend(iter_components(component["components"], where))
    return found


def label(component: dict[str, Any]) -> str:
    group = component.get("group")
    name = component.get("name", "<no name>")
    version = component.get("version", "<no version>")
    return f"{group + ':' if group else ''}{name}@{version}"


def check_sbom(path: Path, policy: Policy) -> tuple[int, dict[str, list[str]]]:
    """Check one SBOM file. Return the number of components and the findings."""
    try:
        sbom = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, ValueError) as error:
        raise GateError(f"{path}: cannot read the SBOM as JSON: {error}") from error
    if not isinstance(sbom, dict) or sbom.get("bomFormat") != "CycloneDX" or not sbom.get("specVersion"):
        raise GateError(f"{path}: this is not a CycloneDX SBOM (`bomFormat` and `specVersion` are necessary)")
    if "components" not in sbom:
        raise GateError(f"{path}: the SBOM has no `components` list (an empty SBOM has `components: []`)")
    components = iter_components(sbom["components"], str(path))
    findings: dict[str, list[str]] = {NOT_PERMITTED: [], NOT_KNOWN: []}
    for component in components:
        status, detail = policy.classify_component(component)
        print(f"  {'OK  ' if status == PERMITTED else 'STOP'} {label(component)}: {status} ({detail})")
        if status != PERMITTED:
            findings[status].append(f"{label(component)} [{detail}]")
    return len(components), findings


def main(argv: list[str]) -> int:
    if len(argv) != 4:
        print("Usage: license_check.py <sbom-dir> <permitted-list> <names-table>", file=sys.stderr)
        return 2
    sbom_dir, permitted_file, names_file = Path(argv[1]), Path(argv[2]), Path(argv[3])
    try:
        policy = Policy(permitted_file, names_file)
        files = sorted(sbom_dir.glob("*.json")) if sbom_dir.is_dir() else []
        if not files:
            raise GateError(f"no SBOM file (*.json) in {sbom_dir}")
        print(f"permitted licenses: {len(policy.permitted)}, names in the table: {len(policy.names)}")
        not_permitted: list[str] = []
        not_known: list[str] = []
        total = 0
        for path in files:
            print(f"{path}:")
            count, findings = check_sbom(path, policy)
            print(f"  {count} component(s)")
            total += count
            not_permitted += findings[NOT_PERMITTED]
            not_known += findings[NOT_KNOWN]
    except GateError as error:
        print(f"ERROR: {error}", file=sys.stderr)
        return 2
    if not_permitted or not_known:
        print(f"RESULT: STOP. {NOT_PERMITTED}: {len(not_permitted)}. {NOT_KNOWN}: {len(not_known)}.")
        for item in not_permitted:
            print(f"  {NOT_PERMITTED}: {item}")
        for item in not_known:
            print(f"  {NOT_KNOWN}: {item}")
        return 1
    print(f"RESULT: PASS. {total} component(s), all licenses permitted.")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
