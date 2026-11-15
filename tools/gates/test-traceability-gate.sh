#!/usr/bin/env bash
# feat-8-traceability-security-gates, Task 110.150 (ACC-002, ACC-003, ACC-004, REQ-001 to REQ-003)
#
# Test of the traceability check (Gate 2) with the fixtures in tools/gates/fixtures/traceability/ and
# tools/gates/fixtures/traceability-reader/.
#
# Usage: test-traceability-gate.sh
#
# The folder fixtures/traceability/base is a small repository that passes the check (the case that is successful):
# an approved REQ with a VCR, the REQ in the OpenAPI file and in the model, the VCR in the name of a test (the backend and
# the frontend), a draft REQ with no VCR, and references that have a target. Each other folder in fixtures/traceability/
# is an overlay. The script copies the base to a temporary folder, copies the files of the overlay over it, and starts
# traceability.py (in the hash-locked environment of specmgr) on the copy. It asserts the exit code and the rule and the
# file in the output:
#
#   ACC-002  the errors: a reference that has no target (a REQ, a FEAT, an identifier of another type), an
#            `x-specmgr-req` that is not the identifier of a REQ (no document, a document of another type), an
#            identifier in the model that has no document, a `vcr:<uuid>` in a test of the backend, of the frontend
#            and of the end-to-end tests that has no document, an approved REQ that has no VCR. And the case that is
#            successful (also with REQ documents that have a status that is not approved).
#   ACC-003  the two warnings (an approved REQ with no element in the model, an approved REQ whose VCR is not in the
#            name of a test): the exit code is 0, and the warnings are a part of the output apart from the errors.
#   ACC-004  the function find_references of the reader of references: the check stops (exit code 2) if the function is
#            not there, has another parameter, gives another form, or raises an error. The real function of the pinned
#            specmgr is the case that is successful. The test also shows that the script has no second copy of the
#            syntax of the references.
#   and the real repository passes (traceability.sh, the entry of the recipe).
#
# The script needs uv and the network for the first run (the install of specmgr from the lock file). It does not change the
# repository.

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/_lib.sh"

require_cmd uv
make_python_env specmgr
work="${GATE_ENV_DIR}/work"
mkdir -p "${work}"
fixtures="${GATES_DIR}/fixtures/traceability"
reader_fixtures="${GATES_DIR}/fixtures/traceability-reader"
[[ -d "${fixtures}/base" ]] || die "No folder ${fixtures}/base"

passed=0
failed=0
case_output=""
case_code=0

# make_case <name> <overlay>... : the copy of the base with the overlays (in this order) in ${work}/<name>
make_case() {
    local name="$1" overlay
    shift
    rm -rf "${work:?}/${name}"
    mkdir -p "${work}/${name}"
    cp -a "${fixtures}/base/." "${work}/${name}/"
    for overlay in "$@"; do
        [[ -d "${fixtures}/${overlay}" ]] || die "No overlay ${fixtures}/${overlay}"
        cp -a "${fixtures}/${overlay}/." "${work}/${name}/"
    done
}

# run_check <folder> [options] : start the check, and keep the output and the exit code
run_check() {
    set +e
    case_output="$("${GATE_PYTHON}" "${GATES_DIR}/traceability.py" "$@" 2>&1)"
    case_code=$?
    set -e
}

# verdict <description> <ok: 0 or 1> : write the line of the result
verdict() {
    if [[ "$2" -eq 1 ]]; then
        echo "ok   $1"
        passed=$((passed + 1))
    else
        echo "FAIL $1"
        echo "${case_output}" | sed -e 's/^/     | /'
        failed=$((failed + 1))
    fi
}

# expect_case <description> <exit code> <text>... : the exit code of the last run, and each text is in the output
expect_case() {
    local description="$1" want_code="$2" text ok=1
    shift 2
    [[ ${case_code} -eq ${want_code} ]] || ok=0
    for text in "$@"; do
        [[ "${case_output}" == *"${text}"* ]] || ok=0
    done
    if [[ ${ok} -eq 0 ]]; then
        echo "FAIL ${description}: expected exit code ${want_code} and the text(s) $*, got exit code ${case_code}"
        echo "${case_output}" | sed -e 's/^/     | /'
        failed=$((failed + 1))
    else
        echo "ok   ${description}"
        passed=$((passed + 1))
    fi
}

# absent <description> <text>... : none of the texts is in the output of the last run
absent() {
    local description="$1" text ok=1
    shift
    for text in "$@"; do
        [[ "${case_output}" != *"${text}"* ]] || ok=0
    done
    verdict "${description}" "${ok}"
}

# case_check <name> <exit code> <text>... : run the check on the case with the name (made with make_case before)
case_check() {
    local name="$1" want_code="$2"
    shift 2
    run_check "${work}/${name}"
    expect_case "${name}" "${want_code}" "$@"
}

bad="99999999-9999-4999-8999-999999999999"

echo "== ACC-002: the case that is successful"
make_case ok
case_check ok 0 "RESULT: PASS (0 warning(s))" "WARNINGS (0)" "ERRORS (0)" "2 REQ (1 approved) and 1 VCR documents" \
    "1 identifiers in the OpenAPI file, 2 in the model, 1 in the tests" "(the form is the expected form)"
make_case ok-other-statuses ok-other-statuses
case_check ok-other-statuses 0 "RESULT: PASS (0 warning(s))" "6 REQ (1 approved)"

echo
echo "== ACC-002: a reference that has no target"
make_case err-dangling-reference err-dangling-reference
case_check err-dangling-reference 1 "ERROR docs/notes.md:1: [reference-has-no-target] the reference REQ ${bad} has no target" \
    "RESULT: FAIL (1 error(s), 0 warning(s))"
make_case err-dangling-feat-reference err-dangling-feat-reference
case_check err-dangling-feat-reference 1 "ERROR .specmgr/notes.md:1: [reference-has-no-target] the reference FEAT feat-77-no-such-feature has no target"
make_case err-reference-wrong-type err-reference-wrong-type
case_check err-reference-wrong-type 1 "ERROR docs/notes.md:1: [reference-has-no-target] the reference DEC 11111111-1111-4111-8111-111111111111 has no target"

echo
echo "== ACC-002: an x-specmgr-req that is not the identifier of a REQ"
make_case err-openapi-unknown-req err-openapi-unknown-req
case_check err-openapi-unknown-req 1 "ERROR contracts/openapi.yaml: [openapi-req-not-found] the operation GET /status, x-specmgr-req: ${bad} is not the id of a REQ document (no document has this id)"
make_case err-openapi-not-a-req err-openapi-not-a-req
case_check err-openapi-not-a-req 1 "[openapi-req-not-found]" "it is the id of a DEC document"

echo
echo "== ACC-002: an identifier in the model that has no document"
make_case err-model-unknown-id err-model-unknown-id
case_check err-model-unknown-id 1 "ERROR model/workspace.json: [model-id-has-no-document] the element Fixture/backend/model, specmgr-req: ${bad} is not the id of a REQ document (no document has this id)"
make_case err-model-not-a-req err-model-not-a-req
case_check err-model-not-a-req 1 "[model-id-has-no-document]" "the element Fixture/backend/api, specmgr-req: 33333333-3333-4333-8333-333333333333" "it is the id of a VCR document"

echo
echo "== ACC-002: a vcr:<uuid> in a test that has no document"
make_case err-test-backend-unknown-vcr err-test-backend-unknown-vcr
case_check err-test-backend-unknown-vcr 1 "ERROR backend/src/test/java/example/UnknownVcrTest.java:9: [test-vcr-has-no-document] vcr:${bad} is not the id of a VCR document"
absent "err-test-backend-unknown-vcr: the commented line of ExampleTest.java is not read" "ExampleTest.java"
make_case err-test-frontend-unknown-vcr err-test-frontend-unknown-vcr
case_check err-test-frontend-unknown-vcr 1 "ERROR frontend/src/test/unknown-vcr.test.ts:3: [test-vcr-has-no-document] vcr:${bad}"
absent "err-test-frontend-unknown-vcr: the commented line of example.test.ts is not read" "example.test.ts"
make_case err-test-e2e-unknown-vcr err-test-e2e-unknown-vcr
case_check err-test-e2e-unknown-vcr 1 "ERROR frontend/e2e/unknown-vcr.spec.ts:3: [test-vcr-has-no-document] vcr:${bad}"

echo
echo "== ACC-002: an approved REQ that has no VCR (the warnings are a part apart from the errors)"
make_case err-approved-req-no-vcr err-approved-req-no-vcr
case_check err-approved-req-no-vcr 1 "[approved-req-has-no-vcr] the REQ 55555555-5555-4555-8555-555555555555 has the status implemented, but no VCR has it in the section Verifies" \
    "ERRORS (1)" "WARNINGS (1)" "RESULT: FAIL (1 error(s), 1 warning(s))"
verdict "err-approved-req-no-vcr: the part of the warnings is before the part of the errors, and each has its own lines" \
    "$([[ "${case_output}" =~ WARNINGS\ \(1\).*WARNING\ docs/req/req-55555555.*ERRORS\ \(1\).*ERROR\ docs/req/req-55555555 ]] && echo 1 || echo 0)"
# the same case with the status accepted
make_case err-approved-req-no-vcr-accepted err-approved-req-no-vcr
sed -i -e 's/^status: implemented$/status: accepted/' "${work}/err-approved-req-no-vcr-accepted/docs/req/req-55555555-5555-4555-8555-555555555555-an-implemented-requirement-without-a-vcr.md"
case_check err-approved-req-no-vcr-accepted 1 "[approved-req-has-no-vcr]" "has the status accepted"

echo
echo "== ACC-003: the two warnings do not stop the check"
make_case warn-no-model-element warn-no-model-element
case_check warn-no-model-element 0 "WARNING docs/req/req-66666666-6666-4666-8666-666666666666-an-accepted-requirement-without-an-element.md: [approved-req-has-no-model-element]" \
    "WARNINGS (1)" "ERRORS (0)" "RESULT: PASS (1 warning(s))"
absent "warn-no-model-element: no warning for the test (the VCR is in the name of a test)" "[approved-req-vcr-not-in-test]"
make_case warn-no-test-name warn-no-test-name
case_check warn-no-test-name 0 "WARNING docs/req/req-88888888-8888-4888-8888-888888888888-an-accepted-requirement-without-a-test-name.md: [approved-req-vcr-not-in-test]" \
    "the VCR aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa of the REQ 88888888-8888-4888-8888-888888888888 is not in the name of a test" \
    "WARNINGS (1)" "ERRORS (0)" "RESULT: PASS (1 warning(s))"
absent "warn-no-test-name: no warning for the model (the REQ is in the model)" "[approved-req-has-no-model-element]"
make_case warn-both warn-no-model-element warn-no-test-name
case_check warn-both 0 "[approved-req-has-no-model-element]" "[approved-req-vcr-not-in-test]" "WARNINGS (2)" "ERRORS (0)" "RESULT: PASS (2 warning(s))"

echo
echo "== The input that cannot be read (exit code 2)"
make_case err-input-workspace-not-json err-input-workspace-not-json
case_check err-input-workspace-not-json 2 "ERROR: cannot read model/workspace.json"
make_case err-input-no-openapi
rm "${work}/err-input-no-openapi/contracts/openapi.yaml"
case_check err-input-no-openapi 2 "ERROR: the file contracts/openapi.yaml does not exist"
make_case err-input-no-workspace
rm "${work}/err-input-no-workspace/model/workspace.json"
case_check err-input-no-workspace 2 "ERROR: the file model/workspace.json does not exist"
make_case err-input-no-e2e
rm -r "${work}/err-input-no-e2e/frontend/e2e"
case_check err-input-no-e2e 2 "ERROR: the folder frontend/e2e does not exist"
make_case err-input-no-feat
rm -r "${work}/err-input-no-feat/.specmgr"
case_check err-input-no-feat 2 "ERROR: the folder .specmgr/feat does not exist"
make_case err-input-bad-frontmatter
printf -- '---\nid: [unclosed\n---\n# x\n' >"${work}/err-input-bad-frontmatter/docs/req/req-12121212-1212-4121-8121-121212121212-bad.md"
case_check err-input-bad-frontmatter 2 "ERROR: cannot read the frontmatter of docs/req/req-12121212-1212-4121-8121-121212121212-bad.md"
run_check "${work}/no-such-folder"
expect_case "a folder that does not exist" 2 "is not a folder"

echo
echo "== ACC-004: the function find_references of the reader of references"
make_case reader
mkdir -p "${work}/reader-modules"
for stub in missing-function changed-parameters changed-result changed-case raises; do
    cp "${reader_fixtures}/${stub}.py.fixture" "${work}/reader-modules/reader_${stub//-/_}.py"
done
reader_check() {
    local stub="$1" text="$2"
    set +e
    case_output="$(PYTHONPATH="${work}/reader-modules" "${GATE_PYTHON}" "${GATES_DIR}/traceability.py" "${work}/reader" \
        --reader-module "reader_${stub//-/_}" 2>&1)"
    case_code=$?
    set -e
    expect_case "the reader ${stub}: the check stops" 2 "ERROR: the reader of references:" "${text}"
    absent "the reader ${stub}: the check gives no result of the traceability" "RESULT:"
}
reader_check missing-function "has no function find_references"
reader_check changed-parameters "has the parameters ['text', 'kinds'], but the form that the check expects is (text)"
reader_check changed-result "gives ['REQ 1ca335d7-969a-443e-9392-165fdeea99a0'] for the probe text"
reader_check changed-case "gives [('REQ', '1ca335d7-969a-443e-9392-165fdeea99a0')] for the probe text"
reader_check raises "raised RuntimeError('the reader is broken')"
run_check "${work}/reader" --reader-module no_such_reader_module
expect_case "a reader module that does not exist: the check stops" 2 "ERROR: the reader of references: cannot import the module no_such_reader_module"
# The pinned specmgr: the function exists, and it has the form that the check expects.
real_form="$("${GATE_PYTHON}" - <<'PYEOF'
import inspect
from biz.dfch.specmgr.general.tools._references import find_references

print([p.name for p in inspect.signature(find_references).parameters.values()])
print(find_references("REQ 1ca335d7-969a-443e-9392-165fdeea99a0: x"))
PYEOF
)" || real_form="the function find_references of the pinned specmgr cannot be imported"
case_output="${real_form}"
verdict "the pinned specmgr $(version_of SPECMGR_VERSION): find_references(text) gives the pairs (type, id)" \
    "$([[ "${real_form}" == "['text']"$'\n'"[('req', '1ca335d7-969a-443e-9392-165fdeea99a0')]" ]] && echo 1 || echo 0)"
# The one regular expression of an identifier (UUID_PATTERN) is the identifier of a document and not the syntax of a reference.
case_output="$(grep -n -E '(GOL|PRB|QA|UC|REQ|RSK|DEC|ADR|VCR|SYSRS|TXT)[|](GOL|PRB|QA|UC|REQ|RSK|DEC|ADR|VCR|SYSRS|TXT)' "${GATES_DIR}/traceability.py" || true)"
verdict "traceability.py has no second copy of the syntax of the references (no list of the reference tags in capital letters)" \
    "$([[ -z "${case_output}" ]] && echo 1 || echo 0)"

echo
echo "== The real repository (the entry of the recipe: traceability.sh)"
set +e
case_output="$("${GATES_DIR}/traceability.sh" "${REPO_ROOT}" 2>&1)"
case_code=$?
set -e
expect_case "the real repository passes (the REQ has the status draft, no VCR is needed)" 0 "RESULT: PASS" "ERRORS (0)" "(the form is the expected form)"
set +e
case_output="$("${GATES_DIR}/traceability.sh" "${work}/err-dangling-reference" 2>&1)"
case_code=$?
set -e
expect_case "traceability.sh gives the exit code 1 of the check for a fixture with an error" 1 "[reference-has-no-target]"
set +e
case_output="$("${GATES_DIR}/traceability.sh" "${work}/no-such-folder" 2>&1)"
case_code=$?
set -e
expect_case "traceability.sh stops for a folder that does not exist" 1 "The folder does not exist"

echo
echo "traceability gate: ${passed} ok, ${failed} failed"
[[ ${failed} -eq 0 ]]
