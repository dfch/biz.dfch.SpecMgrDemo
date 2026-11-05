#!/usr/bin/env bash
# feat-6-contracts-openapi-pipeline, Task 130.100 and Task 130.120 (REQ-001, REQ-005, ACC-004, ACC-009, ACC-015)
#
# Test of the gate for generated code (check-generated.sh) with the real generators.
#
# Usage: test-check-generated-gate.sh
#
# The test makes ONE temporary git repository (copy_work_tree in _lib.sh: a copy of the files of this repository in one commit,
# tag `base`) and runs the gate in it, as CI runs it for a checkout. It never changes the real work tree. Each case makes a
# change, commits it (as a pull request has it) or leaves it in the work tree (as a developer machine has it), runs
# `check-generated.sh backend frontend`, and goes back to `base`.
#
# The four cases of ACC-004, marked "ACC-004 (1)" to "ACC-004 (4)" below. Each must stop the gate (exit code 1):
#   (1) a change by hand to a generated file (a Java file, a TypeScript file, and the README.md of the folder);
#   (2) a change of contracts/openapi.yaml with no new generation (a new error code, and a new version of the interface, which
#       changes only the marker .openapi-generator/*.sha256: it has the hash of the parsed OpenAPI file). A change of a comment
#       only gives the same files, so it does not stop the gate (a good case);
#   (3) a deleted generated file (a Java file, a TypeScript file, and a whole folder);
#   (4) an extra file in the folder of generated code (Java, TypeScript, in a sub-folder, and a file that .gitignore ignores
#       and that was added with `git add -f`).
# More cases: the state of the work tree before the generation (a change by hand that is not committed, a staged change, a file
# that is not tracked, a file that .gitignore ignores, a file with the flag assume-unchanged, a change of the mode of a file)
# stops the gate and the file stays as it is (the gate must not overwrite it), the marks "generated, do not change" (ACC-009: a
# missing README.md, a README.md without the title, a Java file without @Generated, a TypeScript file without the banner of
# Kubb), a generation that fails (a file that is not an OpenAPI file), a usage error, and the good cases (the clean copy, and a
# change outside of the generated folders).
#
# Needs git, JDK 21, Node, pnpm and the network (Maven Central, the npm registry), as generate.sh. It takes about two minutes
# (each case that reaches the generation takes about six seconds).

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/_lib.sh"

require_cmd git
require_cmd tar

work="$(mktemp -d)"
trap 'rm -rf "${work}"' EXIT
repo="${work}/repo"
copy_work_tree "${repo}"
gate="${repo}/tools/gates/check-generated.sh"
[[ -x "${gate}" ]] || die "The gate ${gate} is not in the copy of the repository (or it is not executable)."

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

# check <description> <command...>: ok if the command returns exit code 0
check() {
    local description="$1"
    shift
    if "$@" >/dev/null 2>&1; then
        echo "ok   ${description}"
        passed=$((passed + 1))
    else
        echo "FAIL ${description}"
        failed=$((failed + 1))
    fi
}

section() { echo; echo "== $*"; }

# git in the temporary repository
r() { git -C "${repo}" -c core.fileMode=true "$@"; }

# reset: go back to `base`. The generated folders are cleaned with -x too (an ignored file that a case made), the other ignored
# folders (frontend/node_modules, backend/target) stay, so the install is not made again for each case.
reset() {
    r reset --quiet --hard base
    r clean --quiet -fdx -- backend/src/generated frontend/src/generated
    r update-index --really-refresh >/dev/null 2>&1 || true
}

# commit_all: commit what the case changed (a pull request has the change in a commit). A case that commits a file that
# .gitignore ignores adds it with `git add -f` first.
commit_all() {
    r add -A -- .
    r commit --quiet --no-verify -m "case"
}

# gate_run: the gate in the temporary repository, with the working folder of the repository (as `just check-generated`).
gate_run() { (cd "${repo}" && "${gate}" backend frontend); }

java_file="backend/src/generated/java/biz/dfch/specmgrdemo/model/ErrorCode.java"
status_api="backend/src/generated/java/biz/dfch/specmgrdemo/api/StatusApi.java"
ts_file="frontend/src/generated/zod/errorCodeSchema.ts"
ts_types="frontend/src/generated/types/Problem.ts"
STOP_DIFF="RESULT: STOP. The generated code in the repository is not the generated code of contracts/openapi.yaml."
STOP_CLEAN="RESULT: STOP. The generated folders are not clean before the generation."
STOP_MARK='RESULT: STOP. A mark "generated, do not change" is missing.'

section "the good cases"
expect 0 "PASS. The generated code (15 files in backend/src/generated frontend/src/generated) is the same as the new generation" \
    "the copy of the repository (the generated code is the generated code) passes" gate_run
expect 0 "PASS" "the same copy again (the first run left no change, and node_modules and target do not matter)" gate_run
echo "a change outside of the generated folders" >>"${repo}/contracts/README.md"
echo "not tracked" >"${repo}/outside.txt"
expect 0 "PASS" "a change of the README of contracts/ and an untracked file outside of the generated folders do not stop the gate" gate_run
rm -f "${repo}/outside.txt"
reset

section "ACC-004 (1): a change by hand to a generated file (committed, as in a pull request)"
echo "// a change by hand" >>"${repo}/${java_file}"
commit_all
expect 1 "${STOP_DIFF}" "a change by hand to a Java file stops the gate" gate_run
reset
echo "// a change by hand" >>"${repo}/${ts_file}"
commit_all
expect 1 "M ${ts_file}" "a change by hand to a TypeScript file stops the gate and the message names the file" gate_run
reset
echo "A text that a person added." >>"${repo}/backend/src/generated/README.md"
commit_all
expect 1 "M backend/src/generated/README.md" "a change by hand to the README.md of a generated folder stops the gate" gate_run
reset

section "ACC-004 (2): a change of contracts/openapi.yaml with no new generation (committed)"
sed -i -e 's/^        - service_unavailable$/        - service_unavailable\n        - teapot/' "${repo}/contracts/openapi.yaml"
check "the test changed the OpenAPI file (a new error code teapot)" grep -q '^        - teapot$' "${repo}/contracts/openapi.yaml"
commit_all
expect 1 "M ${java_file}" "a new error code in the OpenAPI file with no new generation stops the gate (the Java enum is not the new one)" gate_run
reset
sed -i -e 's/^  version: 0.1.0$/  version: 0.1.1/' "${repo}/contracts/openapi.yaml"
commit_all
expect 1 "M backend/src/generated/.openapi-generator/openapi.yaml-spring-interfaces.sha256" \
    "a new version of the interface with no new generation stops the gate (only the marker with the hash of the OpenAPI file changes)" gate_run
reset
sed -i -e '1s/^/# a comment only\n/' "${repo}/contracts/openapi.yaml"
commit_all
expect 0 "PASS" "a change of a comment of the OpenAPI file does not stop the gate (the generators make the same files)" gate_run
reset

section "ACC-004 (3): a deleted generated file (committed)"
git -C "${repo}" rm --quiet "${status_api}"
commit_all
expect 1 "?? ${status_api}" "a deleted Java file stops the gate (the generators make it again, so git sees a file that HEAD has not)" gate_run
reset
git -C "${repo}" rm --quiet "${ts_types}"
commit_all
expect 1 "?? ${ts_types}" "a deleted TypeScript file stops the gate" gate_run
reset
git -C "${repo}" rm --quiet -r frontend/src/generated
commit_all
expect 1 "frontend/src/generated has no file in HEAD" "a deleted generated folder stops the gate" gate_run
reset

section "ACC-004 (4): an extra file in the folder of generated code (committed)"
# An extra file that has the mark (a person copied a generated file) is found by the comparison: the generators delete the folder
# first, so git sees a deleted file.
printf '@Generated(value = "by hand")\nclass Extra {}\n' >"${repo}/backend/src/generated/java/biz/dfch/specmgrdemo/model/Extra.java"
commit_all
expect 1 " D backend/src/generated/java/biz/dfch/specmgrdemo/model/Extra.java" "an extra Java file (with a mark) stops the gate (git sees a deleted file after the generation)" gate_run
reset
mkdir -p "${repo}/frontend/src/generated/extra/deep"
printf '/**\n* Generated by Kubb (https://kubb.dev/).\n* Do not edit manually.\n*/\nexport const extra = 1\n' >"${repo}/frontend/src/generated/extra/deep/extra.ts"
commit_all
expect 1 " D frontend/src/generated/extra/deep/extra.ts" "an extra TypeScript file (with a banner) in a sub-folder stops the gate" gate_run
reset
echo "class Extra {}" >"${repo}/backend/src/generated/java/biz/dfch/specmgrdemo/model/Extra.java"
commit_all
expect 1 "model/Extra.java has no @Generated annotation" "an extra Java file with no mark stops the gate (ACC-009: the mark of the file)" gate_run
reset
mkdir -p "${repo}/frontend/src/generated/extra"
echo "export const extra = 1" >"${repo}/frontend/src/generated/extra/extra.ts"
commit_all
expect 1 "extra/extra.ts has no banner of Kubb" "an extra TypeScript file with no banner stops the gate (ACC-009: the mark of the file)" gate_run
reset
echo "a note" >"${repo}/backend/src/generated/notes.txt"
commit_all
expect 1 " D backend/src/generated/notes.txt" "an extra file that is not code (notes.txt) stops the gate" gate_run
reset
echo "a log" >"${repo}/frontend/src/generated/extra.log"
check "the file extra.log is ignored by .gitignore (the test is a real case for an ignored file)" git -C "${repo}" check-ignore -q frontend/src/generated/extra.log
r add -f frontend/src/generated/extra.log
commit_all
check "the ignored file extra.log is in the commit (git add -f)" git -C "${repo}" ls-files --error-unmatch frontend/src/generated/extra.log
expect 1 " D frontend/src/generated/extra.log" "an extra file that .gitignore ignores and that was added with git add -f stops the gate" gate_run
reset

section "a change of the mode of a file (committed)"
chmod +x "${repo}/${java_file}"
commit_all
expect 1 "M ${java_file}" "a change of the mode of a generated file stops the gate" gate_run
reset

section "the work tree before the generation: the gate stops, and it does not overwrite the state"
echo "// a change by hand" >>"${repo}/${java_file}"
expect 1 "${STOP_CLEAN}" "a change by hand that is not committed stops the gate before the generation" gate_run
check "the change by hand is still in the file (the gate did not overwrite it)" grep -q '^// a change by hand$' "${repo}/${java_file}"
reset
echo "// a change by hand" >>"${repo}/${ts_file}"
r add "${ts_file}"
expect 1 "M  ${ts_file}" "a staged change by hand stops the gate before the generation" gate_run
check "the staged change is still in the file" grep -q '^// a change by hand$' "${repo}/${ts_file}"
reset
echo "extra" >"${repo}/backend/src/generated/Untracked.java"
expect 1 "?? backend/src/generated/Untracked.java" "a file that is not tracked stops the gate before the generation" gate_run
check "the untracked file is still there" test -f "${repo}/backend/src/generated/Untracked.java"
reset
echo "extra" >"${repo}/frontend/src/generated/Ignored.class"
check "the file Ignored.class is ignored by .gitignore" git -C "${repo}" check-ignore -q frontend/src/generated/Ignored.class
expect 1 "!! frontend/src/generated/Ignored.class" "a file that .gitignore ignores stops the gate before the generation (git status --ignored)" gate_run
check "the ignored file is still there" test -f "${repo}/frontend/src/generated/Ignored.class"
reset
echo "// a change by hand" >>"${repo}/${java_file}"
r update-index --assume-unchanged "${java_file}"
check "git status does not show the change of a file with the flag assume-unchanged (the test is a real case)" test -z "$(r status --porcelain -- "${java_file}")"
expect 1 "assume-unchanged or skip-worktree" "a change by hand in a file with the flag assume-unchanged stops the gate" gate_run
r update-index --no-assume-unchanged "${java_file}"
reset
echo "// a change by hand" >>"${repo}/${ts_file}"
r update-index --skip-worktree "${ts_file}"
expect 1 "assume-unchanged or skip-worktree" "a change by hand in a file with the flag skip-worktree stops the gate" gate_run
r update-index --no-skip-worktree "${ts_file}"
reset

section "ACC-009: the marks 'generated, do not change'"
git -C "${repo}" rm --quiet backend/src/generated/README.md
commit_all
expect 1 "${STOP_MARK}" "no README.md in the Java folder stops the gate" gate_run
reset
printf 'Some text with no title.\n' >"${repo}/frontend/src/generated/README.md"
commit_all
expect 1 "frontend/src/generated/README.md does not exist or has no title" "a README.md with no title of the mark stops the gate" gate_run
reset
sed -i -e '/^@Generated(/d' "${repo}/${java_file}"
commit_all
expect 1 "${java_file} has no @Generated annotation" "a Java file with no @Generated stops the gate" gate_run
reset
sed -i -e '/Generated by Kubb/d' "${repo}/${ts_file}"
commit_all
expect 1 "${ts_file} has no banner of Kubb" "a TypeScript file with no banner of Kubb stops the gate" gate_run
reset

section "a generation that fails, and the usage"
printf 'this is not an OpenAPI file\n' >"${repo}/contracts/openapi.yaml"
commit_all
expect 1 "generate.sh failed" "an OpenAPI file that the generator cannot read stops the gate" gate_run
reset
expect 1 "Usage: check-generated.sh" "no argument" "${gate}"
expect 1 "The Maven module does not exist" "a folder that does not exist" bash -c "cd '${repo}' && '${gate}' none frontend"
mkdir -p "${work}/no-git/backend" "${work}/no-git/frontend"
expect 1 "is not a git work tree" "a folder that is not a git work tree" bash -c "cd '${repo}' && GATE_WORK_ROOT='${work}/no-git' '${gate}' backend frontend"
expect 1 "is not in the repository" "a module that is not in the repository" bash -c "cd '${repo}' && '${gate}' backend '${work}/no-git/frontend'"

echo
echo "gate for generated code: ${passed} ok, ${failed} failed"
[[ ${failed} -eq 0 ]]
