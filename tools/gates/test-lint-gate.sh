#!/usr/bin/env bash
# feat-6-contracts-openapi-pipeline, Task 110.115 (REQ-006, REQ-008, ACC-007, ACC-015)
#
# Test of the lint gate (lint.sh) with the real Spectral and the rules in tools/lint/ruleset.yaml.
#
# Usage: test-lint-gate.sh
#
# Part 1, the real file: contracts/openapi.yaml must pass (exit code 0).
#
# Part 2, the fixtures in tools/lint/fixtures/: the file expected.txt has one line for each fixture, in the form
#
#   <file> | PASS | <cause>
#   <file> | STOP <rule>,<rule>,... | <cause>
#
# PASS: lint.sh returns exit code 0. STOP: lint.sh returns exit code 1, and the rules that Spectral reports for the
# file (the column `code` of the output) are exactly the rules of the list. So a bad fixture fails with the right
# rule and not with another one, and a rule that stops to work makes the test fail. The cases of ACC-007 are:
#   - a response 4xx or 5xx that does not use application/problem+json with the schema Problem: 01 to 10 and 43;
#   - a schema Problem with no `code`: 11 and 12; with no trace identifier: 13 and 14;
#   - an operation with no `x-specmgr-req`: 26, 27, 33 and 35 to 41 (each HTTP method);
#   - a value of `x-specmgr-req` that is not a UUID: 28 to 32 and 42.
# The other fixtures are for the other rules (the list ErrorCode, a text in a language, a `$ref`, the version of the
# interface, a file that is not OpenAPI). The script also checks that each fixture has a line in expected.txt, and
# the other way round.
#
# Part 3, the script: a missing file, a missing ruleset, a lock file that does not fit package.json (the frozen
# install must stop), a Spectral with another version than SPECTRAL_VERSION, and a ruleset that Spectral cannot read.
#
# The script needs Node and pnpm (lint.sh installs Spectral from the lock file) and the network for the first
# install. It does not change the repository. It stops (exit code 1) if one case does not give the expected result.

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/_lib.sh"

lint="${GATES_DIR}/lint.sh"
real_file="${REPO_ROOT}/contracts/openapi.yaml"
ruleset="${REPO_ROOT}/tools/lint/ruleset.yaml"
fixtures="${REPO_ROOT}/tools/lint/fixtures"
expected_file="${fixtures}/expected.txt"
[[ -f "${expected_file}" ]] || die "No file ${expected_file}"

work="$(mktemp -d)"
trap 'rm -rf "${work}"' EXIT

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
        echo "${output}" | sed -e 's/^/     | /'
        failed=$((failed + 1))
    fi
}

echo "== the real file"
expect 0 "PASS. No finding." "contracts/openapi.yaml passes" "${lint}" "${real_file}" "${ruleset}"

echo
echo "== the fixtures"
listed=()
while IFS= read -r line; do
    [[ -z "${line// /}" || "${line}" == \#* ]] && continue
    IFS='|' read -r file result reason <<<"${line}"
    file="$(echo "${file}" | xargs)"
    result="$(echo "${result}" | xargs)"
    listed+=("${file}")
    [[ -f "${fixtures}/${file}" ]] || { echo "FAIL ${file}: the fixture does not exist"; failed=$((failed + 1)); continue; }

    set +e
    output="$("${lint}" "${fixtures}/${file}" "${ruleset}" 2>&1)"
    code=$?
    set -e
    # The rules in the output of Spectral: the lines `<line>:<column> <level> <rule> <message>`.
    found="$(echo "${output}" | sed -n -E 's/^ *[0-9]+:[0-9]+ +(error|warning|info|hint) +([^ ]+) .*/\2/p' | LC_ALL=C sort -u | paste -sd, -)"

    ok=0
    case "${result}" in
        "PASS") [[ ${code} -eq 0 && -z "${found}" ]] && ok=1 ;;
        "STOP "*)
            want="$(echo "${result#STOP }" | tr ',' '\n' | LC_ALL=C sort -u | paste -sd, -)"
            [[ ${code} -eq 1 && "${found}" == "${want}" ]] && ok=1
            ;;
        *) die "expected.txt: unknown result '${result}' for ${file}" ;;
    esac
    if [[ ${ok} -eq 1 ]]; then
        echo "ok   ${file}: ${result}"
        passed=$((passed + 1))
    else
        echo "FAIL ${file}: expected ${result}, got exit code ${code} and the rules '${found}'"
        echo "${output}" | sed -e 's/^/     | /'
        failed=$((failed + 1))
    fi
done <"${expected_file}"

# Each fixture needs an expected result.
for path in "${fixtures}"/*.yaml; do
    name="$(basename "${path}")"
    found=0
    for item in "${listed[@]}"; do [[ "${item}" == "${name}" ]] && found=1; done
    if [[ ${found} -eq 0 ]]; then
        echo "FAIL ${name}: no line in expected.txt"
        failed=$((failed + 1))
    fi
done

echo
echo "== the script"
expect 1 "Usage: lint.sh" "no argument" "${lint}"
expect 1 "The OpenAPI file does not exist" "a file that does not exist" "${lint}" "${work}/no-such-file.yaml" "${ruleset}"
expect 1 "The ruleset does not exist" "a ruleset that does not exist" "${lint}" "${real_file}" "${work}/no-such-ruleset.yaml"
expect 1 "The folder of the Spectral project does not exist" "no folder for the Spectral project" \
    env LINT_TOOL_DIR="${work}/no-such-tool-dir" "${lint}" "${real_file}" "${ruleset}"
mkdir -p "${work}/tool-nolock"
cp "${REPO_ROOT}/tools/spectral/package.json" "${work}/tool-nolock/"
expect 1 "pnpm-lock.yaml does not exist. Spectral must run from a lock file" "a package.json and no lock file: Spectral does not start" \
    env LINT_TOOL_DIR="${work}/tool-nolock" "${lint}" "${real_file}" "${ruleset}"
# A lock file that does not fit package.json: the frozen install stops, and Spectral does not start.
mkdir -p "${work}/tool-outdated"
cp "${REPO_ROOT}/tools/spectral/pnpm-lock.yaml" "${work}/tool-outdated/"
sed -e 's#"@stoplight/spectral-cli": "[^"]*"#"@stoplight/spectral-cli": "6.0.0"#' "${REPO_ROOT}/tools/spectral/package.json" >"${work}/tool-outdated/package.json"
expect 1 "Spectral did not start" "a lock file that does not fit package.json: the frozen install stops" \
    env LINT_TOOL_DIR="${work}/tool-outdated" "${lint}" "${real_file}" "${ruleset}"
# Another version in versions.env than the installed one.
sed -e 's#^SPECTRAL_VERSION=.*#SPECTRAL_VERSION=6.0.0#' "${REPO_ROOT}/tools/versions.env" >"${work}/versions-other.env"
expect 1 "but SPECTRAL_VERSION in ${work}/versions-other.env is '6.0.0'. Spectral did not start." "the installed Spectral is not the version of versions.env" \
    env VERSIONS_FILE="${work}/versions-other.env" "${lint}" "${real_file}" "${ruleset}"
grep -v '^SPECTRAL_VERSION=' "${REPO_ROOT}/tools/versions.env" >"${work}/versions-none.env"
expect 1 "SPECTRAL_VERSION is not set" "versions.env has no SPECTRAL_VERSION" \
    env VERSIONS_FILE="${work}/versions-none.env" "${lint}" "${real_file}" "${ruleset}"
printf 'rules: [\n' >"${work}/broken-ruleset.yaml"
expect 2 "Spectral could not examine the file" "a ruleset that Spectral cannot read: exit code 2" "${lint}" "${real_file}" "${work}/broken-ruleset.yaml"

echo
echo "lint gate: ${passed} ok, ${failed} failed"
[[ ${failed} -eq 0 ]]
