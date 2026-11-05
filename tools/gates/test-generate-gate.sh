#!/usr/bin/env bash
# feat-6-contracts-openapi-pipeline, Task 120.120 and Task 120.130 (REQ-004, REQ-006, REQ-011, REQ-015, ACC-005, ACC-008,
# ACC-012, ACC-013, ACC-018)
#
# Test of the generators with the real tools: openapi-generator-maven-plugin, Kubb, Maven, JDK 21, Node and pnpm.
#
# Usage: test-generate-gate.sh
#
# Part 1, ACC-013 (two runs of `just generate` make no change). The script defines "no change" as the same files in the two
# generated folders (backend/src/generated and frontend/src/generated), with the same content and the same mode. It does not
# need a clean tree: it compares the runs with each other, and not with git (the comparison with git is the gate of the
# task 130.100). Run 1 and run 2 are one after the other in the folder of the repository. Run 3 starts in another working
# folder, with another time zone and another locale (the result must not depend on them). Then:
#   - the files of the three runs must be the same (the list of files, the sha256 and the mode of each file);
#   - no file has a time stamp, or the path of the repository, of the home folder or of the temporary folder (REQ-011);
#   - each folder has the README.md with the mark, each Java file has @Generated, and each TypeScript file has the banner of
#     Kubb (REQ-001, ACC-009);
#   - if the folders had no change in git at the start (git status), they have none at the end, so the committed code is
#     the code that the generators make now (this part is for a clean checkout, as in CI);
#   - the generator stops a hand change: a changed file, an extra file in each folder and a deleted file are all gone after
#     one run (the files are the same as after run 1).
#
# Part 2, ACC-008 (the list of error codes). The Maven module and the pnpm module are compiled (compile.sh, ACC-005). The list
# `components.schemas.ErrorCode.enum` of contracts/openapi.yaml must be the same as the values (getValue(), and not the
# names of the constants) of the Java enum ErrorCode, as `errorCodeSchema.options` of the Zod schema, and as the list of
# `Problem.code`. tools/generate/error_codes.py compares them. The script also checks that the comparison finds a difference:
# an OpenAPI file with a value added, removed, changed or in another order, and a list of Java or Zod with a value that is
# not the same, each must give exit code 1.
#
# Part 3, ACC-012 (the pin of the generator plugin). With another OPENAPI_GENERATOR_MAVEN_PLUGIN_SHA256 in versions.env,
# `generate.sh`, `compile.sh` and `api-docs.sh` stop (exit code 1) before the plugin generates, and `generate.sh` leaves
# the generated folders as they are.
#
# Part 4, ACC-018 (the API documentation). Two runs of api-docs.sh one after the other (the second one in another working
# folder, with another time zone) make the same files (`diff -r`), the HTML has no time stamp and no path of the machine, and
# the output folder of the recipe (build/api-docs) is not in git. The gate for generated code does not check it.
#
# The script needs JDK 21 (JAVA_HOME or the PATH), Node, pnpm, uv and the network for the first run (Maven Central, the npm
# registry; the Maven Wrapper downloads Maven). It changes the two generated folders (it makes them again, so the files are
# the same as before if the OpenAPI file did not change) and build/api-docs. It stops (exit code 1) if one case fails.

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/_lib.sh"

generate="${GATES_DIR}/generate.sh"
compile="${GATES_DIR}/compile.sh"
api_docs="${GATES_DIR}/api-docs.sh"
backend="${REPO_ROOT}/backend"
frontend="${REPO_ROOT}/frontend"
contract="${REPO_ROOT}/contracts/openapi.yaml"
java_dir="${backend}/src/generated"
ts_dir="${frontend}/src/generated"
helpers="${REPO_ROOT}/tools/generate"

require_cmd git
require_cmd uv
require_cmd node
require_cmd sha256sum

make_python_env pyyaml
work="$(mktemp -d)"
trap 'rm -rf "${work}" "${GATE_ENV_DIR}"' EXIT

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
        echo "${output}" | tail -n 20 | sed -e 's/^/     | /'
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

# snapshot <file>: the list of the files of the two generated folders with the mode and the sha256 of each file
snapshot() {
    (
        cd "${REPO_ROOT}"
        find backend/src/generated frontend/src/generated -type f -print0 | LC_ALL=C sort -z \
            | xargs -0 stat -c '%a %n' | while read -r mode path; do
            printf '%s %s  %s\n' "${mode}" "$(sha256sum "${path}" | cut -d' ' -f1)" "${path}"
        done
    ) >"$1"
}

# same <description> <file a> <file b>: ok if the two snapshots are the same
same() {
    if diff -u "$2" "$3" >"${work}/diff.txt"; then
        echo "ok   $1"
        passed=$((passed + 1))
    else
        echo "FAIL $1"
        sed -e 's/^/     | /' "${work}/diff.txt" | head -n 30
        failed=$((failed + 1))
    fi
}

dirty_before="$(git -C "${REPO_ROOT}" status --porcelain -- backend/src/generated frontend/src/generated)"

echo "== ACC-013: two runs of generate.sh one after the other"
"${generate}" "${backend}" "${frontend}" >"${work}/run1.log" 2>&1 || { cat "${work}/run1.log"; die "run 1 of generate.sh failed"; }
snapshot "${work}/snap1"
"${generate}" "${backend}" "${frontend}" >"${work}/run2.log" 2>&1 || { cat "${work}/run2.log"; die "run 2 of generate.sh failed"; }
snapshot "${work}/snap2"
same "run 2 makes no change ($(wc -l <"${work}/snap1") files: the list, the mode and the sha256 are the same as after run 1)" "${work}/snap1" "${work}/snap2"
mkdir -p "${work}/elsewhere"
(
    cd "${work}/elsewhere"
    TZ=Pacific/Kiritimati LC_ALL=C LANG=C "${generate}" "${backend}" "${frontend}"
) >"${work}/run3.log" 2>&1 || { cat "${work}/run3.log"; die "run 3 of generate.sh failed"; }
snapshot "${work}/snap3"
same "run 3 (another working folder, TZ=Pacific/Kiritimati, LC_ALL=C) makes no change" "${work}/snap1" "${work}/snap3"

[[ "$(wc -l <"${work}/snap1")" -ge 8 ]] || die "The two folders have less than 8 files. The generators did not make the expected files."
echo "ok   the folders have these files:"
sed -e 's/^[0-7]* [0-9a-f]*  /       /' "${work}/snap1"
passed=$((passed + 1))

# No machine value (REQ-011).
machine_values=0
for value in "${REPO_ROOT}" "${HOME}" "/tmp/"; do
    if grep -rIlF -e "${value}" "${java_dir}" "${ts_dir}" >"${work}/found.txt" 2>/dev/null; then
        echo "FAIL a generated file has the path '${value}':"
        sed -e 's/^/     | /' "${work}/found.txt"
        machine_values=$((machine_values + 1))
    fi
done
if grep -rIlE '[0-9]{4}-[0-9]{2}-[0-9]{2}[T ][0-9]{2}:[0-9]{2}' "${java_dir}" "${ts_dir}" >"${work}/found.txt" 2>/dev/null; then
    echo "FAIL a generated file has a time stamp:"
    sed -e 's/^/     | /' "${work}/found.txt"
    machine_values=$((machine_values + 1))
fi
if [[ ${machine_values} -eq 0 ]]; then
    echo "ok   no generated file has a time stamp or the path of the repository, of the home folder or of /tmp"
    passed=$((passed + 1))
else
    failed=$((failed + 1))
fi

# The marks (REQ-001, ACC-009).
file_exists() {
    if [[ -f "$1" ]]; then
        echo "ok   $2"
        passed=$((passed + 1))
    else
        echo "FAIL $2: no file $1"
        failed=$((failed + 1))
    fi
}
file_exists "${java_dir}/README.md" "backend/src/generated has the README.md with the mark"
file_exists "${ts_dir}/README.md" "frontend/src/generated has the README.md with the mark"
check "backend/src/generated/README.md says 'generated, do not change'" grep -q 'Generated code, do not change' "${java_dir}/README.md"
check "frontend/src/generated/README.md says 'generated, do not change'" grep -q 'Generated code, do not change' "${ts_dir}/README.md"
unmarked=0
while IFS= read -r file; do grep -q '^@Generated(' "${file}" || { echo "FAIL ${file} has no @Generated"; unmarked=$((unmarked + 1)); }; done \
    < <(find "${java_dir}" -type f -name '*.java')
while IFS= read -r file; do grep -q '^\* Generated by Kubb (https://kubb.dev/)\.$' "${file}" || { echo "FAIL ${file} has no banner of Kubb"; unmarked=$((unmarked + 1)); }; done \
    < <(find "${ts_dir}" -type f -name '*.ts')
if [[ ${unmarked} -eq 0 ]]; then
    echo "ok   each Java file has @Generated and each TypeScript file has the banner of Kubb"
    passed=$((passed + 1))
else
    failed=$((failed + 1))
fi

# The folders had no change in git at the start: they have none now.
if [[ -z "${dirty_before}" ]]; then
    after="$(git -C "${REPO_ROOT}" status --porcelain -- backend/src/generated frontend/src/generated)"
    if [[ -z "${after}" ]]; then
        echo "ok   the generated folders had no change in git at the start, and they have none after the runs (the committed code is the generated code)"
        passed=$((passed + 1))
    else
        echo "FAIL the generated folders were clean in git, and the runs changed them (the committed code is not the generated code):"
        echo "${after}" | sed -e 's/^/     | /'
        failed=$((failed + 1))
    fi
else
    echo "ok   (the generated folders had a change in git at the start, so the comparison with git is not made)"
fi

# A hand change is gone after one run.
echo '// a change by hand' >>"${java_dir}/java/biz/dfch/specmgrdemo/model/ErrorCode.java"
echo '// a change by hand' >>"${ts_dir}/zod/errorCodeSchema.ts"
echo 'extra' >"${java_dir}/extra.txt"
echo 'extra' >"${ts_dir}/extra.ts"
rm "${java_dir}/java/biz/dfch/specmgrdemo/api/StatusApi.java" "${ts_dir}/types/Problem.ts" "${java_dir}/README.md"
snapshot "${work}/snap-hand"
if diff -q "${work}/snap1" "${work}/snap-hand" >/dev/null; then
    echo "FAIL the test changed no file by hand"
    failed=$((failed + 1))
else
    echo "ok   the comparison of the snapshots finds a change by hand (a changed, an extra and a deleted file)"
    passed=$((passed + 1))
fi
"${generate}" "${backend}" "${frontend}" >"${work}/run4.log" 2>&1 || { cat "${work}/run4.log"; die "run 4 of generate.sh failed"; }
snapshot "${work}/snap4"
same "one run makes the files of run 1 again (no changed, no extra and no deleted file stays)" "${work}/snap1" "${work}/snap4"

echo
echo "== ACC-005 and ACC-008: compile, and the list of error codes"
"${compile}" "${backend}" "${frontend}" >"${work}/compile.log" 2>&1 && compile_code=0 || compile_code=$?
if [[ ${compile_code} -eq 0 ]]; then
    echo "ok   compile.sh: the Maven module and the pnpm module compile with the generated code"
    passed=$((passed + 1))
else
    echo "FAIL compile.sh returned exit code ${compile_code}"
    tail -n 30 "${work}/compile.log" | sed -e 's/^/     | /'
    failed=$((failed + 1))
fi
snapshot "${work}/snap5"
same "the compile (it generates the Java code in the Maven build) makes no change in the generated files" "${work}/snap1" "${work}/snap5"

java_bin="java"
[[ -n "${JAVA_HOME:-}" ]] && java_bin="${JAVA_HOME}/bin/java"
"${java_bin}" -cp "${backend}/target/classes" "${helpers}/ErrorCodes.java" >"${work}/java.json" \
    || die "The Java program ${helpers}/ErrorCodes.java failed (is ${backend}/target/classes there?)"
node "${helpers}/error-codes.mjs" "${ts_dir}/zod" >"${work}/zod.json" || die "The Node program ${helpers}/error-codes.mjs failed"
compare() { "${GATE_PYTHON}" "${helpers}/error_codes.py" "$@"; }
expect 0 "RESULT: PASS. The list of error codes is the same" "the list of error codes is the same in the OpenAPI file, in the Java enum (getValue()) and in the Zod schemas" \
    compare "${contract}" "${work}/java.json" "${work}/zod.json"

# The comparison finds a difference.
make_spec() { # <name> <python expression on the list `codes`>
    "${GATE_PYTHON}" - "${contract}" "${work}/spec-$1.yaml" "$2" <<'PY'
import sys
import yaml

spec = yaml.safe_load(open(sys.argv[1], encoding="utf-8"))
codes = spec["components"]["schemas"]["ErrorCode"]["enum"]
spec["components"]["schemas"]["ErrorCode"]["enum"] = eval(sys.argv[3], {"codes": codes})
yaml.safe_dump(spec, open(sys.argv[2], "w", encoding="utf-8"), sort_keys=False)
PY
}
make_spec added 'codes + ["a_new_code"]'
make_spec removed 'codes[:-1]'
make_spec changed '["not_found_2"] + codes[1:]'
make_spec reordered 'codes[1:] + codes[:1]'
make_spec twice 'codes + codes[:1]'
for name in added removed changed reordered twice; do
    expect 1 "RESULT: STOP" "the comparison stops for a value ${name} in the OpenAPI file (the generated code is not the same)" \
        compare "${work}/spec-${name}.yaml" "${work}/java.json" "${work}/zod.json"
done
"${GATE_PYTHON}" - "${work}/java.json" "${work}/zod.json" "${work}" <<'PY'
import json
import sys

java, zod, out = json.load(open(sys.argv[1])), json.load(open(sys.argv[2])), sys.argv[3]
json.dump(java + ["extra_java"], open(f"{out}/java-extra.json", "w"))
json.dump(java[:-1], open(f"{out}/java-short.json", "w"))
json.dump({**zod, "errorCodeSchema": zod["errorCodeSchema"] + ["extra_zod"]}, open(f"{out}/zod-extra.json", "w"))
json.dump({**zod, "problemCode": zod["problemCode"][::-1]}, open(f"{out}/zod-reversed.json", "w"))
PY
expect 1 "Java enum ErrorCode (getValue())" "the comparison stops for a Java enum with an extra value" compare "${contract}" "${work}/java-extra.json" "${work}/zod.json"
expect 1 "Java enum ErrorCode (getValue())" "the comparison stops for a Java enum with a value less" compare "${contract}" "${work}/java-short.json" "${work}/zod.json"
expect 1 "Zod export errorCodeSchema" "the comparison stops for a Zod schema with an extra value" compare "${contract}" "${work}/java.json" "${work}/zod-extra.json"
expect 1 "Zod Problem.code" "the comparison stops for a Problem.code in another order" compare "${contract}" "${work}/java.json" "${work}/zod-reversed.json"
printf '{}' >"${work}/not-a-list.json"
expect 2 "ERROR" "the comparison stops (exit code 2) for a file that has not the form" compare "${contract}" "${work}/not-a-list.json" "${work}/zod.json"

echo
echo "== ACC-012: another sha256 of the plugin jar stops the generators"
sed -e 's#^OPENAPI_GENERATOR_MAVEN_PLUGIN_SHA256=.*#OPENAPI_GENERATOR_MAVEN_PLUGIN_SHA256=0000000000000000000000000000000000000000000000000000000000000000#' \
    "${VERSIONS_FILE}" >"${work}/versions-badjar.env"
snapshot "${work}/snap6"
expect 1 "OPENAPI_GENERATOR_MAVEN_PLUGIN_SHA256 in ${work}/versions-badjar.env is 0000" "generate.sh with another sha256 of the plugin jar" \
    env VERSIONS_FILE="${work}/versions-badjar.env" "${generate}" "${backend}" "${frontend}"
snapshot "${work}/snap7"
same "generate.sh with another sha256 of the plugin jar leaves the generated folders as they are" "${work}/snap6" "${work}/snap7"
expect 1 "OPENAPI_GENERATOR_MAVEN_PLUGIN_SHA256 in ${work}/versions-badjar.env is 0000" "compile.sh with another sha256 of the plugin jar" \
    env VERSIONS_FILE="${work}/versions-badjar.env" "${compile}" "${backend}" "${frontend}"
expect 1 "OPENAPI_GENERATOR_MAVEN_PLUGIN_SHA256 in ${work}/versions-badjar.env is 0000" "api-docs.sh with another sha256 of the plugin jar" \
    env VERSIONS_FILE="${work}/versions-badjar.env" "${api_docs}" "${backend}" "${work}/docs-badjar"
[[ ! -e "${work}/docs-badjar" ]] && { echo "ok   api-docs.sh with another sha256 made no output"; passed=$((passed + 1)); } \
    || { echo "FAIL api-docs.sh with another sha256 made an output"; failed=$((failed + 1)); }
grep -v '^OPENAPI_GENERATOR_MAVEN_PLUGIN_SHA256=' "${VERSIONS_FILE}" >"${work}/versions-nojar.env"
expect 1 "OPENAPI_GENERATOR_MAVEN_PLUGIN_SHA256 is not set" "generate.sh with no sha256 in versions.env" \
    env VERSIONS_FILE="${work}/versions-nojar.env" "${generate}" "${backend}" "${frontend}"

echo
echo "== the scripts: bad input"
expect 1 "Usage: generate.sh" "generate.sh with no argument" "${generate}"
expect 1 "The Maven module does not exist" "generate.sh with a folder that does not exist" "${generate}" "${work}/none" "${frontend}"
expect 1 "Usage: compile.sh" "compile.sh with no argument" "${compile}"
expect 1 "Usage: api-docs.sh" "api-docs.sh with no argument" "${api_docs}"
# A pnpm module with a lock file that does not fit package.json: the frozen install stops.
mkdir -p "${work}/frontend-outdated"
cp "${frontend}/pnpm-lock.yaml" "${frontend}/pnpm-workspace.yaml" "${work}/frontend-outdated/"
sed -e 's#"zod": "[^"]*"#"zod": "4.0.0"#' "${frontend}/package.json" >"${work}/frontend-outdated/package.json"
expect 1 "Nothing was generated" "a lock file that does not fit package.json: the frozen install stops" \
    bash -c 'source "$1"; install_frontend "$2"' _ "${GATES_DIR}/_lib.sh" "${work}/frontend-outdated"
sed -e 's#^ZOD_VERSION=.*#ZOD_VERSION=4.0.0#' "${VERSIONS_FILE}" >"${work}/versions-zod.env"
expect 1 "The installed zod has the version '4.6.7', but ZOD_VERSION in ${work}/versions-zod.env is '4.0.0'" "the installed Zod is not the version of versions.env" \
    env VERSIONS_FILE="${work}/versions-zod.env" bash -c 'source "$1"; install_frontend "$2"' _ "${GATES_DIR}/_lib.sh" "${frontend}"

echo
echo "== ACC-018: the API documentation"
"${api_docs}" "${backend}" "${work}/docs-1" >"${work}/docs1.log" 2>&1 || { cat "${work}/docs1.log"; die "run 1 of api-docs.sh failed"; }
(
    cd "${work}/elsewhere"
    TZ=Pacific/Kiritimati LC_ALL=C LANG=C "${api_docs}" "${backend}" "${work}/docs-2"
) >"${work}/docs2.log" 2>&1 || { cat "${work}/docs2.log"; die "run 2 of api-docs.sh failed"; }
file_exists "${work}/docs-1/index.html" "api-docs.sh made index.html"
if diff -r "${work}/docs-1" "${work}/docs-2" >"${work}/diff.txt"; then
    echo "ok   two runs of api-docs.sh make the same files (diff -r; the second run in another working folder with another time zone)"
    passed=$((passed + 1))
else
    echo "FAIL two runs of api-docs.sh make different files"
    head -n 20 "${work}/diff.txt" | sed -e 's/^/     | /'
    failed=$((failed + 1))
fi
check "the HTML has the title of the OpenAPI file" grep -q 'SpecMgr Demo API' "${work}/docs-1/index.html"
check "the HTML has the operation GET /status" grep -q '/status' "${work}/docs-1/index.html"
machine_values=0
for value in "${REPO_ROOT}" "${HOME}" "${work}"; do
    grep -rIlF -e "${value}" "${work}/docs-1" >/dev/null 2>&1 && { echo "FAIL the documentation has the path '${value}'"; machine_values=$((machine_values + 1)); }
done
# The HTML has the scripts of third parties (jQuery and others). One of them has a header with a fixed date of 2015, so the
# check looks for a time stamp of this year or of last year (the time of the run).
this_year="$(date -u +%Y)"
grep -rIlE "(${this_year}|$((this_year - 1)))-[0-9]{2}-[0-9]{2}[T ][0-9]{2}:[0-9]{2}" "${work}/docs-1" >/dev/null 2>&1 \
    && { echo "FAIL the documentation has a time stamp of this year or of last year"; machine_values=$((machine_values + 1)); }
if [[ ${machine_values} -eq 0 ]]; then
    echo "ok   the documentation has no time stamp and no path of the machine"
    passed=$((passed + 1))
else
    failed=$((failed + 1))
fi
if git -C "${REPO_ROOT}" check-ignore -q build/api-docs/index.html; then
    echo "ok   build/api-docs (the output folder of the recipe) is not in git"
    passed=$((passed + 1))
else
    echo "FAIL build/api-docs is not ignored by git"
    failed=$((failed + 1))
fi
# The recipe `generate` does not make the documentation, and the generated folders do not have it.
if [[ -z "$(find "${java_dir}" "${ts_dir}" -name 'index.html')" ]]; then
    echo "ok   the generated folders have no HTML (the documentation is not part of the generated code)"
    passed=$((passed + 1))
else
    echo "FAIL a generated folder has an HTML file"
    failed=$((failed + 1))
fi

echo
echo "generators: ${passed} ok, ${failed} failed"
[[ ${failed} -eq 0 ]]
