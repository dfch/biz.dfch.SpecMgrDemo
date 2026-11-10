#!/usr/bin/env python3
"""Remove the components of one package from a CycloneDX SBOM (feat-7-verification-architecture-tools, Phase 110).

sbom.sh starts this script for the frontend SBOM, after cdxgen made it. The package is axe-core (the
accessibility check of the end-to-end test): the license MPL-2.0 is not in
tools/license/permitted-licenses.txt, and the owner approved the use of the tool with the deviation DEC
93a6d588-e002-4daf-9a47-45e2d77786e9 (accepted 2026-11-09). The tool is a development tool: it does not go
to users (rule A of DEC 84c37f7d-08cb-457d-8ab3-1db37dba9bc9), so its license is checked in the plan of
the feature (the license table), and the package is kept out of the SBOM. cdxgen 12.9.0 has no package
filter for a pnpm lock file (its `--exclude` is a file path pattern, verified in the plan), so the
removal is a documented step of the gate, not a flag of the tool.

Usage: sbom_exclude.py <sbom.json> <name> <version>

The script removes each component (in the `components` list and in the nested components, at each level)
whose `name` is <name> and whose `version` is <version>. For each removed component, the entry of the
`dependencies` section with the bom-ref of the component is removed too, and each reference to the bom-ref
in a `dependsOn` list. A component with another version of the package is NOT removed: the exclusion is
the pinned package only, and a different version stops the license gate as a finding (fail closed). The
script rewrites the file only if it removed a component (all other keys stay). It uses only the standard
library.

Exit codes: 0 the SBOM has no component of the package (the file is unchanged, or the removal is written);
2 a file cannot be read or written.
"""

import json
import sys
from pathlib import Path
from typing import Any


class ExcludeError(Exception):
    """A file is wrong, so the script cannot work."""


def remove_components(components: list[Any], name: str, version: str, removed_refs: set[str]) -> int:
    """Remove the components with the name and the version (in place). Collect their bom-refs."""
    removed = 0
    kept: list[Any] = []
    for component in components:
        if isinstance(component, dict) and component.get("name") == name and component.get("version") == version:
            removed += 1
            ref = component.get("bom-ref")
            if isinstance(ref, str) and ref:
                removed_refs.add(ref)
            continue
        if isinstance(component, dict) and "components" in component:
            removed += remove_components(component["components"], name, version, removed_refs)
        kept.append(component)
    components[:] = kept
    return removed


def remove_dependencies(dependencies: list[Any], removed_refs: set[str]) -> None:
    """Remove the entries of a removed component and the references to it in the other entries."""
    kept: list[Any] = []
    for entry in dependencies:
        if not isinstance(entry, dict):
            kept.append(entry)
            continue
        if entry.get("ref") in removed_refs:
            continue
        depends_on = entry.get("dependsOn")
        if isinstance(depends_on, list):
            depends_on[:] = [ref for ref in depends_on if ref not in removed_refs]
        kept.append(entry)
    dependencies[:] = kept


def main(argv: list[str]) -> int:
    if len(argv) != 4:
        print("Usage: sbom_exclude.py <sbom.json> <name> <version>", file=sys.stderr)
        return 2
    sbom = Path(argv[1])
    name, version = argv[2], argv[3]
    try:
        data = json.loads(sbom.read_text(encoding="utf-8"))
        if not isinstance(data, dict) or not isinstance(data.get("components"), list):
            raise ExcludeError(f"{sbom}: this is not a CycloneDX SBOM with a `components` list")
        removed_refs: set[str] = set()
        removed = remove_components(data["components"], name, version, removed_refs)
        if removed > 0:
            dependencies = data.get("dependencies")
            if isinstance(dependencies, list):
                remove_dependencies(dependencies, removed_refs)
            sbom.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
            print(f"{sbom}: removed {removed} component(s) {name}@{version} (and the references to them)")
        else:
            print(f"{sbom}: no component {name}@{version} (nothing to remove)")
    except (OSError, ValueError) as error:
        print(f"ERROR: cannot read the SBOM {sbom}: {error}", file=sys.stderr)
        return 2
    except ExcludeError as error:
        print(f"ERROR: {error}", file=sys.stderr)
        return 2
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
