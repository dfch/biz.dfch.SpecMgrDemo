#!/usr/bin/env python3
"""Compare the exported DSL model with model/workspace.json of the repository (feat-0-demoprep, ACC-001).

Usage: 100-110-01-compare-model.py <exported workspace.json> <model/workspace.json>

The two models must have the same components (by name and container) and the same relations
between components and containers. The DSL model may have more (the person, the views, the
properties). Exit code 0: same. Exit code 1: different.
"""
import json
import sys


def collect(path):
    model = json.load(open(path))["model"]
    names, rels, by_id = set(), set(), {}
    for system in model.get("softwareSystems", []):
        by_id[system["id"]] = system["name"]
        for container in system.get("containers", []):
            by_id[container["id"]] = container["name"]
            names.add(("container", container["name"], system["name"]))
            for component in container.get("components", []):
                by_id[component["id"]] = component["name"]
                names.add(("component", component["name"], container["name"]))

    def walk(element):
        for r in element.get("relationships", []):
            rels.add((element["name"], by_id.get(r["destinationId"], r["destinationId"])))

    for system in model.get("softwareSystems", []):
        walk(system)
        for container in system.get("containers", []):
            walk(container)
            for component in container.get("components", []):
                walk(component)
    return names, rels


new_names, new_rels = collect(sys.argv[1])
old_names, old_rels = collect(sys.argv[2])
ok = True
for label, a, b in (("element", old_names, new_names), ("relation", old_rels, new_rels)):
    for item in sorted(a - b):
        print(f"MISSING in the DSL model: {label} {item}")
        ok = False
# components of the DSL model must not exist only there (no drift in this direction either)
for item in sorted(x for x in new_names - old_names if x[0] == "component"):
    print(f"EXTRA in the DSL model: component {item}")
    ok = False
print(f"components: {sum(1 for x in new_names if x[0] == 'component')} (DSL) / {sum(1 for x in old_names if x[0] == 'component')} (JSON)")
print(f"relations : {len(new_rels)} (DSL) / {len(old_rels)} (JSON)")
print("PASS the DSL model has the elements and the relations of model/workspace.json" if ok else "FAIL the models differ")
sys.exit(0 if ok else 1)
