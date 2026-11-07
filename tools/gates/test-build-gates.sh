#!/usr/bin/env bash
# feat-6-contracts-openapi-pipeline, Task 130.105 and Task 130.120 (REQ-004, REQ-015, ACC-005, ACC-015, ACC-018)
#
# Test of the gates `compile` (compile.sh) and `api-docs` (api-docs.sh) with bad input and the real tools.
#
# Usage: test-build-gates.sh
#
# The test makes ONE temporary git repository (copy_work_tree in _lib.sh: a copy of the files of this repository in one commit,
# tag `base`), makes a change that must stop the gate in it, runs the gate, and goes back to `base`. It never changes the real
# work tree. The positive cases of the two gates are in test-generate-gate.sh and in the recipes themselves.
#
# Cases for `compile` (each must give exit code 1 with the message of the failed tool):
#   - the control: the copy compiles (exit code 0);
#   - a Java file with a compile error in the source root of the module (backend/src/main/java);
#   - a TypeScript file with a type error in frontend/src (`tsc --noEmit --strict`);
#   - a generated TypeScript file with a type error (compile.sh compiles the committed code of frontend/src/generated).
# And one case that shows a limit (finding G8 of phase 120): a generated Java file with a syntax error does NOT stop `compile`,
# because the Maven build makes the Java code again (the execution `spring-interfaces` is bound to generate-sources). The gate
# for generated code (check-generated.sh) is the gate that stops this change, and the test shows that it does.
#
# Cases for `api-docs`: an OpenAPI file that the generator cannot read stops the gate (exit code 1) and no HTML is made, and the
# control that the copy makes index.html. (The cases of a changed sha256 of the plugin jar and of the output that two runs make
# the same are in test-generate-gate.sh and in selftest.sh.)
#
# Needs git, JDK 21, Node, pnpm and the network, as generate.sh. It takes about a minute.

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/_lib.sh"

require_cmd git
require_cmd tar

work="$(mktemp -d)"
trap 'rm -rf "${work}"' EXIT
repo="${work}/repo"
copy_work_tree "${repo}"
compile="${repo}/tools/gates/compile.sh"
api_docs="${repo}/tools/gates/api-docs.sh"
check_generated="${repo}/tools/gates/check-generated.sh"
for script in "${compile}" "${api_docs}" "${check_generated}"; do
    [[ -x "${script}" ]] || die "${script} is not in the copy of the repository (or it is not executable)."
done

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

r() { git -C "${repo}" -c core.fileMode=true "$@"; }
reset() {
    r reset --quiet --hard base
    r clean --quiet -fdq -- backend/src frontend/src contracts
}
commit_all() {
    r add -A -- .
    r commit --quiet --no-verify -m "case"
}
compile_run() { (cd "${repo}" && "${compile}" backend frontend); }
docs_run() { (cd "${repo}" && "${api_docs}" backend "${work}/docs"); }

section "compile (ACC-005)"
expect 0 "PASS. The Maven module and the pnpm module compile with the generated code." "the control: the copy compiles" compile_run

mkdir -p "${repo}/backend/src/main/java/biz/dfch/specmgrdemo"
printf 'package biz.dfch.specmgrdemo;\n\npublic class Broken {\n    int x = "text";\n}\n' >"${repo}/backend/src/main/java/biz/dfch/specmgrdemo/Broken.java"
commit_all
expect 1 "./mvnw compile failed in" "a Java file with a compile error stops compile" compile_run
reset

printf 'export const broken: number = "text";\n' >"${repo}/frontend/src/broken.ts"
commit_all
expect 1 "tsc failed in" "a TypeScript file with a type error stops compile" compile_run
reset

printf '\nexport const broken: number = "text";\n' >>"${repo}/frontend/src/generated/zod/errorCodeSchema.ts"
commit_all
expect 1 "tsc failed in" "a generated TypeScript file with a type error stops compile (it compiles the committed code)" compile_run
reset

printf '\nthis is not Java;\n' >>"${repo}/backend/src/generated/java/biz/dfch/specmgrdemo/model/ErrorCode.java"
commit_all
expect 0 "PASS. The Maven module and the pnpm module compile" "a generated Java file with a syntax error does not stop compile (the build makes the Java code again, finding G8)" compile_run
r reset --quiet --hard HEAD
r clean --quiet -fdq -- backend/src frontend/src
printf '\nthis is not Java;\n' >>"${repo}/backend/src/generated/java/biz/dfch/specmgrdemo/model/ErrorCode.java"
r commit --quiet --no-verify -am "case again"
expect 1 "M backend/src/generated/java/biz/dfch/specmgrdemo/model/ErrorCode.java" "the gate for generated code stops the same change" \
    bash -c "cd '${repo}' && '${check_generated}' backend frontend"
reset

section "api-docs (ACC-018)"
expect 0 "PASS." "the control: the copy makes the API documentation" docs_run
[[ -s "${work}/docs/index.html" ]] && { echo "ok   the control made index.html"; passed=$((passed + 1)); } \
    || { echo "FAIL the control made no index.html"; failed=$((failed + 1)); }
printf 'this is not an OpenAPI file\n' >"${repo}/contracts/openapi.yaml"
commit_all
expect 1 "Maven did not make the API documentation" "an OpenAPI file that the generator cannot read stops api-docs" docs_run
[[ ! -e "${work}/docs/index.html" ]] && { echo "ok   no index.html is left after the failed run"; passed=$((passed + 1)); } \
    || { echo "FAIL the failed run left an index.html"; failed=$((failed + 1)); }
reset

echo
echo "compile and api-docs: ${passed} ok, ${failed} failed"
[[ ${failed} -eq 0 ]]
