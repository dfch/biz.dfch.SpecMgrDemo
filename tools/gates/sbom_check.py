#!/usr/bin/env python3
"""Check that an SBOM has components if the manifests declare dependencies (finding E1, part b).

feat-5-foundation-monorepo-ci, Task 130.130 (REQ-006). sbom.sh starts this script after it made
an SBOM file. The script uses only the standard library.

Usage: sbom_check.py <node|maven> <sbom.json> <manifest>...

  node   each manifest is a package.json. It declares dependencies if `dependencies`,
         `devDependencies`, `optionalDependencies` or `peerDependencies` is a mapping with an entry.
  maven  each manifest is a pom.xml. It declares dependencies if a `<dependency>` is a direct child of
         `<dependencies>` of the project or of a profile. A `<dependency>` in `<dependencyManagement>`
         or in a plugin is not a dependency of the project, and does not count.

The SBOM must have at least one component (the `components` list and the components in it, at each
level) if one manifest declares dependencies. Otherwise the tool that made the SBOM did not see the
dependencies, and a license gate that passes on an empty SBOM would be wrong. The gate fails closed.

One case is different (feat-6-contracts-openapi-pipeline, Task 105.110, the first run with a real pom.xml): for
`maven`, cyclonedx-maven-plugin 2.9.3 writes an SBOM with NO `components` key if the project has no dependency
(the key is optional in CycloneDX), and license_check.py stops for an SBOM with no `components` list. If the
SBOM has no `components` key and the manifests declare no dependency, the script writes `"components": []` to
the SBOM file and says so, so the license gate can read it. If the manifests declare a dependency, the same SBOM
stops the script (exit code 1), as an empty list does. The script does this for `maven` only: no other tool is known
to omit the key.

Exit codes: 0 the SBOM is plausible; 1 dependencies are declared and the SBOM has no component;
2 a file cannot be read.
"""

import json
import sys
import xml.etree.ElementTree as ET
from pathlib import Path
from typing import Any

NODE_KEYS = ("dependencies", "devDependencies", "optionalDependencies", "peerDependencies")


class CheckError(Exception):
    """A file is wrong, so the check cannot decide."""


def node_dependencies(path: Path) -> int:
    """Return the number of dependencies that a package.json declares."""
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, ValueError) as error:
        raise CheckError(f"cannot read {path}: {error}") from error
    if not isinstance(data, dict):
        raise CheckError(f"{path} is not a JSON object")
    count = 0
    for key in NODE_KEYS:
        value = data.get(key)
        if isinstance(value, dict):
            count += len(value)
        elif value is not None:
            raise CheckError(f"{path}: `{key}` is not an object")
    return count


def local_name(tag: str) -> str:
    """Return the name of an XML tag without the namespace."""
    return tag.rsplit("}", 1)[-1]


def maven_dependencies(path: Path) -> int:
    """Return the number of `<dependency>` elements of the project (and of its profiles) in a pom.xml."""
    try:
        root = ET.parse(path).getroot()
    except (OSError, ET.ParseError) as error:
        raise CheckError(f"cannot read {path}: {error}") from error
    if local_name(root.tag) != "project":
        raise CheckError(f"{path}: the root element is not <project>")
    count = 0
    containers = [root] + [
        profile for profiles in root if local_name(profiles.tag) == "profiles" for profile in profiles
    ]
    for container in containers:
        for child in container:
            if local_name(child.tag) == "dependencies":
                count += sum(1 for dependency in child if local_name(dependency.tag) == "dependency")
    return count


def components_in(node: Any) -> int:
    """Return the number of components in a CycloneDX object (the `components` list and the nested ones)."""
    count = 0
    components = node.get("components") if isinstance(node, dict) else None
    if isinstance(components, list):
        for component in components:
            count += 1 + components_in(component)
    return count


def add_empty_components(sbom: Path, data: dict[str, Any]) -> None:
    """Write the SBOM file again with `"components": []` (all other keys stay)."""
    data["components"] = []
    try:
        sbom.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    except OSError as error:
        raise CheckError(f"cannot write the SBOM {sbom}: {error}") from error


def main(argv: list[str]) -> int:
    if len(argv) < 4 or argv[1] not in ("node", "maven"):
        print("Usage: sbom_check.py <node|maven> <sbom.json> <manifest>...", file=sys.stderr)
        return 2
    kind, sbom = argv[1], Path(argv[2])
    try:
        try:
            data = json.loads(sbom.read_text(encoding="utf-8"))
        except (OSError, ValueError) as error:
            raise CheckError(f"cannot read the SBOM {sbom}: {error}") from error
        components = components_in(data)
        counter = node_dependencies if kind == "node" else maven_dependencies
        declared = {name: counter(Path(name)) for name in argv[3:]}
        total = sum(declared.values())
        if kind == "maven" and total == 0 and isinstance(data, dict) and "components" not in data:
            add_empty_components(sbom, data)
            print(f"{sbom}: no `components` key and no declared dependency: wrote `components: []`")
    except CheckError as error:
        print(f"ERROR: {error}", file=sys.stderr)
        return 2
    for name, count in declared.items():
        print(f"{name}: {count} declared dependenc{'y' if count == 1 else 'ies'}")
    print(f"{sbom}: {components} component(s)")
    if total > 0 and components == 0:
        print(
            f"STOP: the manifests declare {total} dependenc{'y' if total == 1 else 'ies'}, but the SBOM {sbom} has no "
            "component. The SBOM tool did not see the dependencies, so the license gate would pass on nothing."
        )
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
