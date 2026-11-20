#!/usr/bin/env bash
# feat-7-verification-architecture-tools, Task 130.120 (REQ-004, ACC-002, ACC-003)
#
# The test that compares the Structurizr workspace with the packages and the dependencies of the
# code (the recipe architecture-model; refactored onto the rule set the model gives in
# feat-50-structurizr-model-rules, Task 130.130, REQ-005; the canonical form is the section "The
# rules the model gives" of model/README.md; DEC e85e9685-0787-4dff-9ee5-9d46670e9ee4, that
# replaces the name rule of DEC 9edc1071-4fd0-48b6-a037-1a4cb2331f73). This is the analyzer of the
# closed set (group 3 of the canonical section) and of the exceptions (group 4): the limit of the
# parity (the tools of the runner cannot examine a closed set, DEC e85e9685) stays in this recipe.
#
# Usage: architecture-model.sh <backend dir> <frontend dir>
#
# The workspace is the file model/workspace.json of the repository (the JSON form that the
# exporter of the pinned container structurizr/structurizr makes from model/workspace.dsl, see
# model/README.md). The comparison is mapping-based (and not name-based): the components are read
# by their entries of the property code.package (backend) or of the property code.path (frontend),
# and the mapping does not depend on the name of the component (DEC e85e9685).
#
# Part 1, the case that is successful (ACC-002: the committed workspace matches the code):
#   - the backend side: the JUnit class ModelComparisonTest (the recipe runs it with
#     ./mvnw test -Dcodegen.skip=true -Dtest=ModelComparisonTest). The reader is the library
#     structurizr-java (the artifact structurizr-client, the class JsonReader), the source of the
#     packages and the dependencies of the code is ArchUnit (the compiled classes of the base
#     package of the container's code.root, the test classes are excluded by the import option
#     DoNotIncludeTests), and the reading and the derivation are the shared class ModelRules (the
#     same rule set as the runner ModelRuleRunnerTest). The assertions: every code location (the
#     package of every class) is owned by exactly one component (ACC-003a), every code dependency
#     between mapped components is in the model (ACC-003b), the other direction (no component in
#     the model without a class, no relation in the model without the code), and every code
#     dependency to a package that no component owns is allowed if and only if it matches an entry
#     of the source component's code.allowedExternal (the platform java.* and javax.* is given).
#     The run is green (exit code 0).
#   - the frontend side: the script frontend/architecture/compare.mjs (the strict reading of the
#     workspace and the derivation through the shared module frontend/architecture/workspace.mjs,
#     the discovery of the files from the code - the rule of thumb stays the discovery, and it is
#     the source of truth for what code exists - and the imports read with the compiler of the
#     pinned package typescript, including the dynamic forms import() and require(), the fix of
#     Task 130.130). The same assertions for the files and the imports of the container frontend.
#     The run is green (exit code 0, the PASS line).
#
# Part 2, the two conditions of ACC-003, each demonstrated in a temporary copy of the repository
# (copy_work_tree in _lib.sh; the script changes the workspace of the copy only, and the
# repository is never changed):
#   (a) a module or a package has no component in the model:
#       - the backend: the script removes the component model of the container backend (and the
#         dependency that names it, because the reader of structurizr-java does not accept a
#         dependency without its element - it stops with a NullPointerException, see the plan).
#         The comparison is not successful, and the message names the package without a
#         component.
#       - the frontend: the script removes the component zod of the container frontend (and the
#         dependency that names it). The comparison is not successful, and the message names the
#         unit without a component.
#   (b) a dependency is not in the model:
#       - the backend: the script removes the dependency api -> model. The comparison is not
#         successful, and the message names the dependency that is not in the model.
#       - the frontend: the script removes the dependency test -> zod. The comparison is not
#         successful, and the message names the dependency that is not in the model.
#   The recipe asserts the exit code and the message of each failure, and the run of part 1 is
#   green.
#
# Part 3, the key `properties` of an element (feat-8-traceability-security-gates: the property `specmgr-req` of the
# traceability check). The frontend side (compare.mjs, a strict reader) accepts the key `properties` of a software
# system, a container and a component if the value is a map of texts, and it stops (exit code 2) for each other value.
# The cases change a copy of the workspace file only (a file in the temporary folder), and start compare.mjs on the
# module with it. The case of the component with the map of texts keeps the mapping of the component (the merge
# of the key into the existing properties, and not the replacement): the comparison is mapping-based (Task
# 130.130), and a replacement would destroy the entries of code.path of the component (the files of the
# component would have no mapped element, and the comparison would stop - the correct behavior of the
# closed set, and not the case of the reader that this part examines). The case of the empty map is on the
# software system (the properties of the system carry no mapping).
#
# Part 4, the entry code.ignore of the container (the frontend side, the exception of the closed
# world that the check does not examine, group 4 of the canonical section): in a temporary copy of
# the repository, one scratch file lies directly in the folder src/generated (the rule of thumb
# has no unit for it). The first sub-case runs the comparison of the copy with the workspace of
# the copy and asserts that the run stops for the file (exit code 2, the rule-of-thumb message
# "no unit for it") - the existing behavior without an entry. The second sub-case sets the
# property code.ignore of the container frontend of the workspace of the copy to the one entry
# that names the file (the mutation type "ignore" of mutate_workspace) and asserts that the run
# is green (exit code 0, the PASS line names the ignored count) - the file is examined not at
# all. In both sub-cases the scratch file exists in the temporary copy only, and the repository
# is never changed.
#
# The script needs JDK 21 (the Maven Wrapper of the module), Node and pnpm (install_frontend for
# the run of part 1 and for the copies of the frontend) and the network for the first run (Maven
# Central, the npm registry). It does not change the repository (the copies are in a temporary
# folder, and the builds are in the target/ of the copies). It stops (exit code 1) if one part
# does not give the expected result.

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/_lib.sh"

require_cmd uv

[[ $# -eq 2 ]] || die "Usage: architecture-model.sh <backend dir> <frontend dir>"
backend_dir="$1"
frontend_dir="$2"
[[ -f "${backend_dir}/pom.xml" ]] || die "${backend_dir}/pom.xml does not exist"
[[ -x "${backend_dir}/mvnw" ]] || die "${backend_dir}/mvnw does not exist or is not executable"
[[ -d "${frontend_dir}" ]] || die "The folder of the pnpm module does not exist: ${frontend_dir}"
frontend_dir="$(cd "${frontend_dir}" && pwd)"

work="$(mktemp -d)"
trap 'rm -rf "${work}"' EXIT

passed=0
failed=0

# surefire_summary <output> -- the final summary line of surefire (the line with no class name)
surefire_summary() {
    printf '%s\n' "$1" | grep -E '^\[INFO\] Tests run: [0-9]+, Failures: [0-9]+, Errors: [0-9]+, Skipped: [0-9]+$' | tail -n 1
}

# backend_comparison <backend dir> <workspace file>: run the comparison test of the backend side
# (the classes are compiled by the run; the generation is skipped, the generated code is
# committed). Capture the output and the exit code (run_output, run_code). The property
# build.info.commit (the value of the build, Task 200.120) is the one of the directory.
backend_comparison() {
    local dir="$1" file="$2"
    backend_maven_args "${dir}"
    set +e
    run_output="$(cd "${dir}" && ./mvnw --batch-mode --no-transfer-progress test -Dcodegen.skip=true \
        -Dtest=ModelComparisonTest "-Dmodel.workspace.path=${file}" "${MAVEN_BUILD_ARGS[@]}" 2>&1)"
    run_code=$?
    set -e
}

# frontend_comparison <frontend dir> <workspace file>: run the comparison of the frontend side
# (the module is installed first, the script reads the imports with the compiler of typescript).
frontend_comparison() {
    local dir="$1" file="$2"
    install_frontend "${dir}"
    set +e
    run_output="$(node "${dir}/architecture/compare.mjs" "${dir}" "${file}" 2>&1)"
    run_code=$?
    set -e
}

# mutate_workspace <workspace file> <mutation JSON>: change the workspace of a copy of the
# repository (the file of the copy only). The mutation is a small JSON object (the values are
# the names of the elements of the workspace; the helper resolves them to the ids, and a name
# that the workspace has not stops the helper): {"type": "component", "container": <the
# container>, "name": <the component>} removes the component and the dependency that names it,
# {"type": "relationship", "container": <the container>, "sourceId": <the source component>,
# "destinationId": <the destination component>} removes the dependency between the two
# components (the relationships of the workspace are by id; the values of sourceId and
# destinationId are the names, as in the recipe), and {"type": "ignore", "container": <the
# container>, "entries": <the text of the entries>} sets the property code.ignore of the
# container (the list form of the DEC: the entries that the character comma separates; the
# entries name the code locations that no element maps and that the check does not examine).
# The mutations are the two conditions of ACC-003, for the two sides (the component model of
# the container backend, the component zod of the container frontend, the dependency api ->
# model, and the dependency test -> zod), and the demonstration of the entry code.ignore of
# Part 4.
mutate_workspace() {
    local file="$1" mutation="$2"
    uv run --no-project --quiet python - "${file}" "${mutation}" <<'PYEOF'
import json
import sys

path, mutation_text = sys.argv[1], sys.argv[2]
try:
    mutation = json.loads(mutation_text)
except ValueError as error:
    sys.exit(f"the mutation is not a JSON object: {error}")
if not isinstance(mutation, dict):
    sys.exit(f"the mutation is not a JSON object: {mutation_text}")
workspace = json.load(open(path, encoding="utf-8"))
systems = workspace["model"]["softwareSystems"]
kind = mutation.get("type")
container_name = mutation.get("container")
if kind not in ("component", "relationship", "ignore") or not isinstance(container_name, str):
    sys.exit(f"unknown mutation {mutation_text}")
container = next(
    (c for s in systems for c in s.get("containers", []) if c.get("name") == container_name), None
)
if container is None:
    sys.exit(f"the workspace has no container {container_name}")
components = container.get("components", [])
if kind == "ignore":
    entries = mutation.get("entries")
    if not isinstance(entries, str):
        sys.exit(f"unknown mutation {mutation_text}")
    properties = container.get("properties") or {}
    properties["code.ignore"] = entries
    container["properties"] = properties
elif kind == "component":
    component_name = mutation.get("name")
    if not isinstance(component_name, str):
        sys.exit(f"unknown mutation {mutation_text}")
    target = next((c for c in components if c.get("name") == component_name), None)
    if target is None:
        sys.exit(f"the container {container_name} of the workspace has no component {component_name}")
    target_id = target["id"]
    container["components"] = [c for c in components if c.get("name") != component_name]
    def drop(relations):
        return [
            r
            for r in (relations or [])
            if r.get("sourceId") != target_id and r.get("destinationId") != target_id
        ]
    container["relationships"] = drop(container.get("relationships"))
    for component in container["components"]:
        component["relationships"] = drop(component.get("relationships"))
else:
    source_name = mutation.get("sourceId")
    destination_name = mutation.get("destinationId")
    if not isinstance(source_name, str) or not isinstance(destination_name, str):
        sys.exit(f"unknown mutation {mutation_text}")
    ids = {c.get("name"): c.get("id") for c in components}
    if source_name not in ids or destination_name not in ids:
        sys.exit(
            f"the container {container_name} of the workspace has no component {source_name} or {destination_name}"
        )
    def drop(relations):
        return [
            r
            for r in (relations or [])
            if not (r.get("sourceId") == ids[source_name] and r.get("destinationId") == ids[destination_name])
        ]
    container["relationships"] = drop(container.get("relationships"))
    for component in container["components"]:
        component["relationships"] = drop(component.get("relationships"))
with open(path, "w", encoding="utf-8") as handle:
    json.dump(workspace, handle, indent=2)
print(f"mutated {path}: {mutation_text}")
PYEOF
}

echo "== the case that is successful (the workspace matches the code)"
backend_dir="$(cd "${backend_dir}" && pwd)"
echo "-- the backend side (structurizr-java and ArchUnit)"
backend_comparison "${backend_dir}" "${backend_dir}/../model/workspace.json"
if [[ ${run_code} -ne 0 ]]; then
    echo "FAIL the comparison of the backend side is not green (exit code ${run_code})"
    printf '%s\n' "${run_output}" | tail -n 40 | sed -e 's/^/     | /'
    failed=$((failed + 1))
else
    summary="$(surefire_summary "${run_output}")"
    if [[ -n "${summary}" && "${summary}" == *"Failures: 0"* && "${summary}" == *"Errors: 0"* ]]; then
        echo "ok   the comparison of the backend side is green (the packages and the dependencies of the module are in the model)"
        passed=$((passed + 1))
    else
        echo "FAIL the summary of the comparison of the backend side has a failure or an error: ${summary}"
        failed=$((failed + 1))
    fi
fi
echo "-- the frontend side (the script compare.mjs)"
frontend_comparison "${frontend_dir}" "${frontend_dir}/../model/workspace.json"
if [[ ${run_code} -ne 0 ]]; then
    echo "FAIL the comparison of the frontend side is not green (exit code ${run_code})"
    printf '%s\n' "${run_output}" | tail -n 20 | sed -e 's/^/     | /'
    failed=$((failed + 1))
else
    if [[ "${run_output}" == *"PASS the workspace"* ]]; then
        echo "ok   the comparison of the frontend side is green (the units and the dependencies of the frontend are in the model)"
        passed=$((passed + 1))
    else
        echo "FAIL the comparison of the frontend side has no PASS line:"
        printf '%s\n' "${run_output}" | tail -n 5 | sed -e 's/^/     | /'
        failed=$((failed + 1))
    fi
fi

echo
echo "== ACC-003 (a): a module or a package has no component in the model (a temporary copy of the repository)"
echo "-- the backend side (the component model of the container backend is removed from the copy of the workspace)"
copy_work_tree "${work}/a-backend"
mutate_workspace "${work}/a-backend/model/workspace.json" \
    '{"type": "component", "container": "backend", "name": "model"}'
backend_comparison "${work}/a-backend/backend" "${work}/a-backend/model/workspace.json"
if [[ ${run_code} -ne 0 && "${run_output}" == *"the package biz.dfch.specmgrdemo.model has no component in the model"* ]]; then
    echo "ok   the comparison is not successful, and the message names the package without a component"
    passed=$((passed + 1))
    printf '%s\n' "${run_output}" | grep -E "AssertionFailedError|FAIL" | head -n 2 | sed -e 's/^/     | /'
else
    echo "FAIL the comparison of the copy gives exit code ${run_code}, and the output has not the message of the package without a component:"
    printf '%s\n' "${run_output}" | grep -E "Tests run|AssertionFailedError|has no component" | head -n 5 | sed -e 's/^/     | /'
    failed=$((failed + 1))
fi
echo "-- the frontend side (the component zod of the container frontend is removed from the copy of the workspace)"
copy_work_tree "${work}/a-frontend"
mutate_workspace "${work}/a-frontend/model/workspace.json" \
    '{"type": "component", "container": "frontend", "name": "zod"}'
frontend_comparison "${work}/a-frontend/frontend" "${work}/a-frontend/model/workspace.json"
if [[ ${run_code} -ne 0 && "${run_output}" == *"the unit zod of the frontend has no component in the model"* ]]; then
    echo "ok   the comparison is not successful, and the message names the unit without a component"
    passed=$((passed + 1))
    printf '%s\n' "${run_output}" | grep -E "FAIL" | head -n 2 | sed -e 's/^/     | /'
else
    echo "FAIL the comparison of the copy gives exit code ${run_code}, and the output has not the message of the unit without a component:"
    printf '%s\n' "${run_output}" | grep -E "FAIL|has no component" | head -n 5 | sed -e 's/^/     | /'
    failed=$((failed + 1))
fi

echo
echo "== ACC-003 (b): a dependency is not in the model (a temporary copy of the repository)"
echo "-- the backend side (the dependency api -> model is removed from the copy of the workspace)"
copy_work_tree "${work}/b-backend"
mutate_workspace "${work}/b-backend/model/workspace.json" \
    '{"type": "relationship", "container": "backend", "sourceId": "api", "destinationId": "model"}'
backend_comparison "${work}/b-backend/backend" "${work}/b-backend/model/workspace.json"
if [[ ${run_code} -ne 0 && "${run_output}" == *"the dependency biz.dfch.specmgrdemo.api -> biz.dfch.specmgrdemo.model is not in the model"* ]]; then
    echo "ok   the comparison is not successful, and the message names the dependency that is not in the model"
    passed=$((passed + 1))
    printf '%s\n' "${run_output}" | grep -E "AssertionFailedError|FAIL" | head -n 2 | sed -e 's/^/     | /'
else
    echo "FAIL the comparison of the copy gives exit code ${run_code}, and the output has not the message of the dependency that is not in the model:"
    printf '%s\n' "${run_output}" | grep -E "Tests run|AssertionFailedError|is not in the model" | head -n 5 | sed -e 's/^/     | /'
    failed=$((failed + 1))
fi
echo "-- the frontend side (the dependency test -> zod is removed from the copy of the workspace)"
copy_work_tree "${work}/b-frontend"
mutate_workspace "${work}/b-frontend/model/workspace.json" \
    '{"type": "relationship", "container": "frontend", "sourceId": "test", "destinationId": "zod"}'
frontend_comparison "${work}/b-frontend/frontend" "${work}/b-frontend/model/workspace.json"
if [[ ${run_code} -ne 0 && "${run_output}" == *"the dependency test -> zod of the frontend is not in the model"* ]]; then
    echo "ok   the comparison is not successful, and the message names the dependency that is not in the model"
    passed=$((passed + 1))
    printf '%s\n' "${run_output}" | grep -E "FAIL" | head -n 2 | sed -e 's/^/     | /'
else
    echo "FAIL the comparison of the copy gives exit code ${run_code}, and the output has not the message of the dependency that is not in the model:"
    printf '%s\n' "${run_output}" | grep -E "FAIL|is not in the model" | head -n 5 | sed -e 's/^/     | /'
    failed=$((failed + 1))
fi

echo
echo "== The key properties of an element (the frontend side: a map of texts is accepted, each other value stops the comparison)"
# set_properties <workspace file> <level: system | container | component> <JSON value> <merge 0|1> :
# set the key `properties` of one element of the copy of the workspace (the software system, the
# container frontend, the component zod of it). The merge (1) keeps the existing properties and adds
# the keys of the value (the case of the component: the mapping code.* of the component is
# load-bearing for the mapping-based comparison, Task 130.130). The replace (0) is the whole value.
set_properties() {
    local file="$1" level="$2" value="$3" merge="$4"
    uv run --no-project --quiet python - "${file}" "${level}" "${value}" "${merge}" <<'PYEOF'
import json
import sys

path, level, value_text, merge = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4] == "1"
value = json.loads(value_text)
workspace = json.load(open(path, encoding="utf-8"))
system = workspace["model"]["softwareSystems"][0]
container = next(c for c in system["containers"] if c["name"] == "frontend")
element = {
    "system": system,
    "container": container,
    "component": next(c for c in container["components"] if c["name"] == "zod"),
}[level]
element["properties"] = {**(element.get("properties") or {}), **value} if merge else value
with open(path, "w", encoding="utf-8") as handle:
    json.dump(workspace, handle, indent=2)
PYEOF
}
# properties_case <ok | stop> <level> <JSON value> <description> [merge 0|1] : compare.mjs with the
# copy that has the value
properties_case() {
    local want="$1" level="$2" value="$3" description="$4" merge="${5:-0}" file
    file="${work}/properties-${level}-${RANDOM}.json"
    cp "${frontend_dir}/../model/workspace.json" "${file}"
    set_properties "${file}" "${level}" "${value}" "${merge}"
    set +e
    run_output="$(node "${frontend_dir}/architecture/compare.mjs" "${frontend_dir}" "${file}" 2>&1)"
    run_code=$?
    set -e
    if [[ "${want}" == "ok" && ${run_code} -eq 0 && "${run_output}" == *"PASS the workspace"* ]]; then
        echo "ok   ${description}: the comparison is green"
        passed=$((passed + 1))
    elif [[ "${want}" == "stop" && ${run_code} -eq 2 && "${run_output}" == *"has the key properties, and its value is not a map of texts"* ]]; then
        echo "ok   ${description}: the comparison stops (exit code 2) with the message that the value is not a map of texts"
        passed=$((passed + 1))
    else
        echo "FAIL ${description}: expected ${want}, got exit code ${run_code}"
        printf '%s\n' "${run_output}" | tail -n 5 | sed -e 's/^/     | /'
        failed=$((failed + 1))
    fi
}
properties_case ok system '{"specmgr-req": "11111111-1111-4111-8111-111111111111", "other": "a text"}' "the software system has a map of texts"
properties_case ok container '{"specmgr-req": "11111111-1111-4111-8111-111111111111, 22222222-2222-4222-8222-222222222222"}' "the container has a map of texts (a list with a comma)"
properties_case ok component '{"specmgr-req": "11111111-1111-4111-8111-111111111111"}' "the component has a map of texts (the merge keeps the mapping of the component)" 1
properties_case ok system '{}' "the software system has an empty map"
properties_case stop system '"a text"' "the software system has a text as the value of properties"
properties_case stop container '["specmgr-req"]' "the container has a list as the value of properties"
properties_case stop component 'null' "the component has null as the value of properties"
properties_case stop component '{"specmgr-req": 5}' "the component has a number as the value of a property"
properties_case stop component '{"specmgr-req": ["11111111-1111-4111-8111-111111111111"]}' "the component has a list as the value of a property"
properties_case stop component '{"specmgr-req": {"a": "b"}}' "the component has a map as the value of a property"

echo
echo "== The entry code.ignore of the container (the frontend side: a file directly in src/generated that no component owns is examined not at all)"
# The two sub-cases of the demonstration, each in a temporary copy of the repository (the
# repository is never changed). The scratch file lies directly in the folder src/generated of
# the copy (the rule of thumb has no unit for it): without an entry of code.ignore on the
# container frontend of the workspace of the copy, the comparison stops for the file (exit code
# 2, the rule-of-thumb message); with the entry that names the file, the comparison is green
# (exit code 0, the PASS line names the ignored count).
copy_work_tree "${work}/ignore-none"
cat >"${work}/ignore-none/frontend/src/generated/ignored-probe.ts" <<'EOF'
// Scratch file of the recipe architecture-model (feat-50-structurizr-model-rules, the fix pass
// of the post-implementation review): the file lies directly in the folder src/generated (the
// rule of thumb has no unit for it). Without an entry of code.ignore on the container frontend
// of the workspace, the comparison stops for the file. The file exists in the temporary copy
// only; the repository is never changed.
export const ignoredProbe = 'probe'
EOF
frontend_comparison "${work}/ignore-none/frontend" "${work}/ignore-none/model/workspace.json"
if [[ ${run_code} -eq 2 && "${run_output}" == *"no unit for it"* ]]; then
    echo "ok   the file that lies directly in src/generated and that no entry of code.ignore names stops the run (the rule of thumb)"
    passed=$((passed + 1))
    printf '%s\n' "${run_output}" | head -n 2 | sed -e 's/^/     | /'
else
    echo "FAIL the comparison of the copy gives exit code ${run_code}, and the output has not the rule-of-thumb message of the file directly in src/generated:"
    printf '%s\n' "${run_output}" | tail -n 5 | sed -e 's/^/     | /'
    failed=$((failed + 1))
fi
copy_work_tree "${work}/ignore-entry"
cat >"${work}/ignore-entry/frontend/src/generated/ignored-probe.ts" <<'EOF'
// Scratch file of the recipe architecture-model (feat-50-structurizr-model-rules, the fix pass
// of the post-implementation review): the file lies directly in the folder src/generated (the
// rule of thumb has no unit for it). With an entry of code.ignore on the container frontend of
// the workspace that names the file, the comparison examines it not at all. The file exists in
// the temporary copy only; the repository is never changed.
export const ignoredProbe = 'probe'
EOF
mutate_workspace "${work}/ignore-entry/model/workspace.json" \
    '{"type": "ignore", "container": "frontend", "entries": "src/generated/ignored-probe.ts"}'
frontend_comparison "${work}/ignore-entry/frontend" "${work}/ignore-entry/model/workspace.json"
if [[ ${run_code} -eq 0 && "${run_output}" == *"PASS the workspace"* && "${run_output}" == *"1 file(s) in code.ignore"* ]]; then
    echo "ok   the same file that an entry of code.ignore names is examined not at all (the comparison is green, the PASS line names the ignored count)"
    passed=$((passed + 1))
    printf '%s\n' "${run_output}" | grep -F "PASS the workspace" | head -n 1 | sed -e 's/^/     | /'
else
    echo "FAIL the comparison of the copy gives exit code ${run_code}, and the output has not the PASS line with the ignored count:"
    printf '%s\n' "${run_output}" | tail -n 5 | sed -e 's/^/     | /'
    failed=$((failed + 1))
fi

echo
echo "architecture-model: ${passed} ok, ${failed} failed"
[[ ${failed} -eq 0 ]]
