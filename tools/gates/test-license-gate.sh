#!/usr/bin/env bash
# feat-5-foundation-monorepo-ci, Task 130.135 (ACC-009)
#
# Test of the license gate with the fixtures in tools/license/fixtures/.
#
# Usage: test-license-gate.sh
#
# The file tools/license/fixtures/expected.txt has the expected result of each
# fixture. For each fixture, the script copies the file alone to a temporary
# folder, starts license-check.sh with the real list of permitted licenses and the real table
# of names, and compares the exit code and the text of the result:
#
#   PASS           exit code 0, and `RESULT: PASS`
#   NOT PERMITTED  exit code 1, and a line `NOT PERMITTED:` in the output, and no `NOT KNOWN:` line
#   NOT KNOWN      exit code 1, and a line `NOT KNOWN:` in the output
#   ERROR          exit code 2
#
# The script also checks that each fixture has a line in expected.txt, and the other way round.
# It stops (exit code 1) if one fixture has a result that is not expected.

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/_lib.sh"

require_cmd uv
fixtures="${REPO_ROOT}/tools/license/fixtures"
expected_file="${fixtures}/expected.txt"
permitted="${REPO_ROOT}/tools/license/permitted-licenses.txt"
[[ -f "${expected_file}" ]] || die "No file ${expected_file}"

work="$(mktemp -d)"
trap 'rm -rf "${work}"' EXIT

passed=0
failed=0
listed=()
while IFS= read -r line; do
    [[ -z "${line// /}" || "${line}" == \#* ]] && continue
    IFS='|' read -r file result reason <<<"${line}"
    file="$(echo "${file}" | xargs)"
    result="$(echo "${result}" | xargs)"
    reason="$(echo "${reason}" | sed -e 's/^ *//')"
    listed+=("${file}")
    [[ -f "${fixtures}/${file}" ]] || { echo "FAIL ${file}: the fixture does not exist"; failed=$((failed + 1)); continue; }

    rm -rf "${work:?}/sbom" && mkdir -p "${work}/sbom"
    cp "${fixtures}/${file}" "${work}/sbom/${file}"
    set +e
    output="$("${GATES_DIR}/license-check.sh" "${work}/sbom" "${permitted}" 2>&1)"
    code=$?
    set -e

    ok=0
    case "${result}" in
        "PASS") [[ ${code} -eq 0 && "${output}" == *"RESULT: PASS"* ]] && ok=1 ;;
        "NOT PERMITTED") [[ ${code} -eq 1 && "${output}" == *$'\n  NOT PERMITTED: '* && "${output}" != *$'\n  NOT KNOWN: '* ]] && ok=1 ;;
        "NOT KNOWN") [[ ${code} -eq 1 && "${output}" == *$'\n  NOT KNOWN: '* ]] && ok=1 ;;
        "ERROR") [[ ${code} -eq 2 ]] && ok=1 ;;
        *) die "expected.txt: unknown result '${result}' for ${file}" ;;
    esac
    if [[ ${ok} -eq 1 ]]; then
        echo "ok   ${file}: ${result}"
        passed=$((passed + 1))
    else
        echo "FAIL ${file}: expected ${result}, got exit code ${code}"
        echo "${output}" | sed -e 's/^/     | /'
        failed=$((failed + 1))
    fi
done <"${expected_file}"

# Each fixture needs an expected result.
for path in "${fixtures}"/*.json; do
    name="$(basename "${path}")"
    found=0
    for item in "${listed[@]}"; do [[ "${item}" == "${name}" ]] && found=1; done
    if [[ ${found} -eq 0 ]]; then
        echo "FAIL ${name}: no line in expected.txt"
        failed=$((failed + 1))
    fi
done

echo "license gate fixtures: ${passed} ok, ${failed} failed"
[[ ${failed} -eq 0 ]]
