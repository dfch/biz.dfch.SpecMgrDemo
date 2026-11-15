#!/usr/bin/env bash
# feat-7-verification-architecture-tools, Task 110.110 (REQ-001, ACC-002)
#
# Test of the unit tests of the pnpm module with Vitest (the recipe test-unit-frontend).
#
# Usage: test-unit-frontend.sh <frontend dir>
#
# Part 1, the case that is successful: the run of the unit tests (`pnpm exec vitest run --reporter=verbose`,
# the config vitest.config.ts, the node environment). The tests exercise the generated Zod schemas (the example
# module has no product code): the schema of the status (a valid status, a state that is not in the
# list), the five error codes of the contract, and the schema of the problem (RFC 9457). The run is
# green (exit code 0), and the summary of vitest has a passed test file and no failed one.
#
# Part 2, the case that is not successful (ACC-002): the file broken-assertion.broken.test.ts has the
# part `broken` in the name, so the config of part 1 does not start it (the committed run is green).
# The script runs the files with the part `broken` with the config vitest.config.negative.ts and
# stops for them: the run fails (exit code not 0), and the output names the failed assertion of
# Vitest.
#
# The script needs Node and pnpm (install_frontend in _lib.sh installs the module from the lock file
# with `pnpm install --frozen-lockfile --ignore-scripts`, and stops if an installed package has
# another version than the key of tools/versions.env) and the network for the first run (the npm
# registry). It does not change the repository. It stops (exit code 1) if one part does not give the
# expected result.

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/_lib.sh"

[[ $# -eq 1 ]] || die "Usage: test-unit-frontend.sh <frontend dir>"
[[ -d "$1" ]] || die "The folder of the pnpm module does not exist: $1"
frontend_dir="$(cd "$1" && pwd)"
install_frontend "${frontend_dir}"
cd "${frontend_dir}"

passed=0
failed=0

# vitest_summary <output> -- the lines of the summary of vitest (Test Files, Tests)
vitest_summary() {
    printf '%s\n' "$1" | grep -E 'Test Files|Tests  ' | tail -n 2
}

echo "== the case that is successful (Vitest)"
# The verbose reporter gives the name of each test file and test in the output (a green run without
# the reporter has only the summary, and the script cannot name the files it ran).
set +e
run_output="$(pnpm exec vitest run --reporter=verbose 2>&1)"
run_code=$?
set -e
if [[ ${run_code} -ne 0 ]]; then
    echo "FAIL the run of the unit tests is not green (exit code ${run_code})"
    printf '%s\n' "${run_output}" | tail -n 40 | sed -e 's/^/     | /'
    failed=$((failed + 1))
else
    summary="$(vitest_summary "${run_output}")"
    if [[ "${summary}" == *"passed"* && "${summary}" != *"failed"* ]]; then
        echo "ok   the run of the unit tests is green: ${summary//$'\n'/ | }"
        passed=$((passed + 1))
    else
        echo "FAIL the summary of the run has a failed test file or test: ${summary}"
        failed=$((failed + 1))
    fi
    if [[ "${run_output}" == *"status-schema.test.ts"* && "${run_output}" == *"property.test.ts"* ]]; then
        echo "ok   the run has the tests of the generated Zod schemas and the property tests"
        passed=$((passed + 1))
    else
        echo "FAIL the run has not the test files of the module"
        failed=$((failed + 1))
    fi
fi

echo
echo "== the case that is not successful (ACC-002)"
set +e
run_output="$(pnpm exec vitest run --config vitest.config.negative.ts 2>&1)"
run_code=$?
set -e
if [[ ${run_code} -ne 0 && "${run_output}" == *"broken-assertion"* && "${run_output}" == *"expected 2 to be 3"* ]]; then
    echo "ok   the run stops for the wrong assertion of Vitest, and the output names it"
    passed=$((passed + 1))
else
    echo "FAIL the run of the files with the part broken gives exit code ${run_code}, and the output has not the failed assertion:"
    printf '%s\n' "${run_output}" | grep -E "FAIL|AssertionError|Test Files" | head -n 5 | sed -e 's/^/     | /'
    failed=$((failed + 1))
fi

echo
echo "test-unit-frontend: ${passed} ok, ${failed} failed"
[[ ${failed} -eq 0 ]]
