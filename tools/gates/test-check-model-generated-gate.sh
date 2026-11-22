#!/usr/bin/env bash
# feat-50-structurizr-model-rules, Task 110.120 (REQ-003, ACC-004; DEC b6e8808f-86b4-41a4-92f2-33d38869beed)
#
# Test of the gate for the generated model (check-model-generated.sh) with the real container.
#
# Usage: test-check-model-generated-gate.sh
#
# The test makes ONE temporary model folder (a copy of the files of model/ of this repository), and runs
# the gate on it (the gate takes the model folder as the argument, so it never changes the real
# repository). Each case makes a change, runs `check-model-generated.sh <model dir>`, and goes back.
#
# The cases:
#   - the good case: the copy of the model (the JSON is the JSON that the DSL makes now) passes, twice
#     (the second run shows that the gate changes nothing of the model folder);
#   - the changed-JSON case: a change by hand of workspace.json stops the gate, and the message names
#     the difference (ACC-004: the gate stops for a JSON that differs from the DSL);
#   - the stale-JSON case: a change of workspace.dsl with no new generation stops the gate (the
#     committed file is not the file that the DSL makes now);
#   - the inspection-count case: a change of workspace.dsl that gains one deployment node (the probe
#     node host2) with a new generation of the committed file for the changed DSL stops the gate in
#     the count check (the count of the inspection of the fresh generation is 31, and the recorded
#     value is 29, the message names the count);
#   - the broken-DSL case: a DSL that does not parse stops the gate (the container validate names the
#     line);
#   - the pin case: a value of STRUCTURIZR_IMAGE_DIGEST that is not a sha256 digest stops the gate
#     (the step names the digest, and not the tag);
#   - the usage: no argument, and a folder that does not exist.
#
# Needs docker (and the network for the first pull, if the image is not local), as the gate. It takes
# about one minute (each case starts the container three times: validate, and two runs of the export;
# the inspection-count case starts it one more time for the regeneration of the committed file).

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/_lib.sh"

require_cmd docker

work="$(mktemp -d)"
trap 'rm -rf "${work}"' EXIT
model="${work}/model"
mkdir -p "${model}"
cp "${REPO_ROOT}/model/workspace.dsl" "${model}/"
cp "${REPO_ROOT}/model/workspace.json" "${model}/"
gate="${GATES_DIR}/check-model-generated.sh"
[[ -x "${gate}" ]] || die "The gate ${gate} is not in the repository (or it is not executable)."

passed=0
failed=0

# expect <exit code> <text in the output> <description> <command...>
expect() {
    local want_code="$1" want_text="$2" description="$3"
    shift 3
    local output code
    set +e
    output="$("$@" 2>&1)"
    code=$?
    set -e
    if [[ ${code} -eq ${want_code} && "${output}" == *"${want_text}"* ]]; then
        echo "ok   ${description}"
        passed=$((passed + 1))
    else
        echo "FAIL ${description}: expected exit code ${want_code} and '${want_text}', got exit code ${code}"
        echo "${output}" | tail -n 30 | sed -e 's/^/     | /'
        failed=$((failed + 1))
    fi
}

section() { echo; echo "== $*"; }

# gate_run: the gate in the temporary model folder (as `just check-model-generated`).
gate_run() { (cd "${REPO_ROOT}" && "${gate}" "${model}"); }

section "the good case"
expect 0 "PASS. model/workspace.json is the JSON that the pinned container makes from" \
    "the copy of the model (the JSON is up to date with the DSL) passes" gate_run
expect 0 "PASS" "the same copy again (the gate changes nothing of the model folder)" gate_run

section "the changed-JSON case (a change by hand of workspace.json)"
sed -i -E 's/("structurizr.inspection.error" : ")[0-9]+/\120/' "${model}/workspace.json"
check_changed=0
grep -q '"structurizr.inspection.error" : "20"' "${model}/workspace.json" && check_changed=1
[[ ${check_changed} -eq 1 ]] || die "the test did not change the JSON (the line structurizr.inspection.error was not found)"
expect 1 'structurizr.inspection.error" : "20' \
    "a change by hand of workspace.json stops the gate, and the message names the difference" gate_run

section "the stale-JSON case (a change of workspace.dsl with no new generation)"
sed -i 's/The status API of the project: the backend/The status API of the project (stale): the backend/' "${model}/workspace.dsl"
grep -q "(stale)" "${model}/workspace.dsl" || die "the test did not change the DSL"
expect 1 "RESULT: STOP. The JSON of the model is not up to date with the DSL." \
    "a change of workspace.dsl with no new generation stops the gate (the stale JSON)" gate_run

section "the inspection-count case (the committed file carries another count of the inspection than the recorded value)"
# The copy of the DSL gains one deployment node (the probe node host2): with the pinned container,
# the count of the inspection of a fresh generation is 31 (the recorded value of the committed model
# is 29, the record in model/README.md and in the Updates entry of DEC b6e8808f). The committed file
# of the copy is regenerated with the container for the changed DSL (the gate then compares the
# committed file with the new generation byte for byte, and the count check stops for the value 31
# that is not the recorded value 29).
sed -i 's#^\(            host = deploymentNode "host".*\)$#\1\n            host2 = deploymentNode "host2" "A probe node" "Linux"#' "${model}/workspace.dsl"
grep -q 'host2 = deploymentNode' "${model}/workspace.dsl" || die "the test did not change the DSL (the probe node host2 was not added)"
export_dir="${work}/inspection-count"
mkdir -p "${export_dir}"
image="$(version_of STRUCTURIZR_IMAGE)"
digest="$(version_of STRUCTURIZR_IMAGE_DIGEST)"
docker run --rm -v "${model}:/src:ro" -v "${export_dir}:/out" -w /src "${image%%:*}@${digest}" export -w workspace.dsl -f json -o /out \
    || die "the export of the container failed in the test (the probe node case)"
cp "${export_dir}/workspace.json" "${model}/workspace.json"
expect 1 'structurizr.inspection.error with the value 31, and the recorded value is 29' \
    "the committed file with another count of the inspection stops the gate (the message names the count)" gate_run

section "the broken-DSL case (a DSL that does not parse)"
# Replace the final closing brace of the workspace with a token that the parser does not know (the
# error names the line of the token).
sed -i '$ d' "${model}/workspace.dsl"
printf 'bogus_token\n}\n' >>"${model}/workspace.dsl"
output=""
code=0
set +e
output="$(gate_run 2>&1)"
code=$?
set -e
if [[ ${code} -eq 1 && "${output}" == *"at line"* && "${output}" == *"RESULT: STOP. The DSL of the model does not parse."* ]]; then
    echo "ok   a DSL that does not parse stops the gate (the container validate names the line)"
    passed=$((passed + 1))
else
    echo "FAIL a DSL that does not parse: expected exit code 1, a named line, and the stop message; got exit code ${code}"
    echo "${output}" | tail -n 30 | sed -e 's/^/     | /'
    failed=$((failed + 1))
fi

section "the pin case (a digest that does not name an image)"
printf 'STRUCTURIZR_IMAGE=structurizr/structurizr:2026.10.26-noble\nSTRUCTURIZR_IMAGE_DIGEST=not-a-digest\n' >"${work}/versions.env"
expect 1 "STRUCTURIZR_IMAGE_DIGEST is not a sha256 digest" \
    "a value of STRUCTURIZR_IMAGE_DIGEST that is not a sha256 digest stops the gate" \
    bash -c "cd '${REPO_ROOT}' && VERSIONS_FILE='${work}/versions.env' '${gate}' '${model}'"

section "the usage"
expect 1 "Usage: check-model-generated.sh" "no argument" "${gate}"
expect 1 "The model folder does not exist" "a folder that does not exist" bash -c "cd '${REPO_ROOT}' && '${gate}' none"

echo
echo "gate for the generated model: ${passed} ok, ${failed} failed"
[[ ${failed} -eq 0 ]]
