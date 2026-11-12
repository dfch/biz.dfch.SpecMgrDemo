#!/usr/bin/env bash
# feat-7-verification-architecture-tools, Task 130.120 (REQ-004, ACC-002, ACC-003)
#
# The test that compares the Structurizr workspace with the modules, the packages and the
# dependencies (the recipe architecture-model; DEC 9edc1071-4fd0-48b6-a037-1a4cb2331f73: "A test
# reads the workspace and compares the components with the modules and the packages").
#
# Usage: architecture-model.sh <backend dir> <frontend dir>
#
# The workspace is the file model/workspace.json of the repository (the JSON form that the
# writer of the library structurizr-java makes, see model/README.md). The name of a component is
# the identifier of its package (backend) or of its unit (frontend).
#
# Part 1, the case that is successful (ACC-002: the committed workspace matches the code):
#   - the backend side: the JUnit class ModelComparisonTest (the recipe runs it with
#     ./mvnw test -Dcodegen.skip=true -Dtest=ModelComparisonTest). The reader is the library
#     structurizr-java (the artifact structurizr-client, the class JsonReader), the source of the
#     packages and the dependencies of the code is ArchUnit (the compiled classes of the module,
#     the packages biz.dfch.specmgrdemo.*, the test classes are excluded by the import option
#     DoNotIncludeTests). The assertions: every package has a component in the model (ACC-003a),
#     every package dependency is in the model (ACC-003b), and the other direction (no component
#     in the model without a package, no dependency in the model without the code - recorded in
#     the plan). The run is green (exit code 0).
#   - the frontend side: the script frontend/architecture/compare.mjs (a strict reading of the
#     workspace, the discovery of the units from the files of the code, and the imports read with
#     the compiler of the pinned package typescript). The same assertions for the units and the
#     dependencies of the container frontend. The run is green (exit code 0, the PASS line).
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
# committed). Capture the output and the exit code (run_output, run_code).
backend_comparison() {
    local dir="$1" file="$2"
    set +e
    run_output="$(cd "${dir}" && ./mvnw --batch-mode --no-transfer-progress test -Dcodegen.skip=true \
        -Dtest=ModelComparisonTest "-Dmodel.workspace.path=${file}" 2>&1)"
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

# mutate_workspace <workspace file> <mutation>: change the workspace of a copy of the repository
# (the file of the copy only). The mutations are the two conditions of ACC-003, for the two
# sides: component-backend-model (remove the component model of the container backend, and the
# dependency that names it), component-frontend-zod (the same for the component zod of the
# container frontend), relationship-backend-api-model (remove the dependency api -> model),
# relationship-frontend-test-zod (remove the dependency test -> zod).
mutate_workspace() {
    local file="$1" mutation="$2"
    uv run --no-project --quiet python - "${file}" "${mutation}" <<'PYEOF'
import json
import sys

path, mutation = sys.argv[1], sys.argv[2]
workspace = json.load(open(path, encoding="utf-8"))
systems = workspace["model"]["softwareSystems"]
if mutation.startswith("component-"):
    container_name, component_name = mutation[len("component-"):].split("-", 1)
elif mutation.startswith("relationship-"):
    container_name, source_name, destination_name = mutation[len("relationship-"):].split("-")
else:
    sys.exit(f"unknown mutation {mutation}")
container = next(
    (c for s in systems for c in s.get("containers", []) if c.get("name") == container_name), None
)
if container is None:
    sys.exit(f"the workspace has no container {container_name}")
components = container.get("components", [])
if mutation.startswith("component-"):
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
print(f"mutated {path}: {mutation}")
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
mutate_workspace "${work}/a-backend/model/workspace.json" component-backend-model
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
mutate_workspace "${work}/a-frontend/model/workspace.json" component-frontend-zod
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
mutate_workspace "${work}/b-backend/model/workspace.json" relationship-backend-api-model
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
mutate_workspace "${work}/b-frontend/model/workspace.json" relationship-frontend-test-zod
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
echo "architecture-model: ${passed} ok, ${failed} failed"
[[ ${failed} -eq 0 ]]
