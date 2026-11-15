#!/usr/bin/env bash
# feat-7-verification-architecture-tools, Task 110.130 (REQ-002, ACC-002)
#
# Test of the property tests of the pnpm module with fast-check (the recipe test-random-frontend).
#
# Usage: test-random-frontend.sh <frontend dir>
#
# Part 1, the case that is successful: the run of the property tests (`pnpm exec vitest run --reporter=verbose
# src/test/property.test.ts`). The properties run on the generated Zod schemas (the example module
# has no product code): each status the generator gives parses in the schema of the status, a state
# that is not up or degraded is rejected, and a small function of the test (it keeps only the lower
# case letters) is idempotent. The run is green (exit code 0), and the summary of vitest has a
# passed test file and no failed one.
#
# Part 2, the case that is not successful (ACC-002): the file broken-property.broken.test.ts has the
# part `broken` in the name, so the normal config does not start it (the committed run is green).
# The script runs the file with the config vitest.config.negative.ts and stops for it: fast-check
# finds a counterexample of the property (the sum of two numbers is never 3), the run fails (exit
# code not 0), and the output names the counterexample.
#
# The script needs Node and pnpm (install_frontend in _lib.sh installs the module from the lock file
# with `pnpm install --frozen-lockfile --ignore-scripts`, and stops if an installed package has
# another version than the key of tools/versions.env) and the network for the first run (the npm
# registry). It does not change the repository. It stops (exit code 1) if one part does not give the
# expected result.

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/_lib.sh"

[[ $# -eq 1 ]] || die "Usage: test-random-frontend.sh <frontend dir>"
[[ -d "$1" ]] || die "The folder of the pnpm module does not exist: $1"
frontend_dir="$(cd "$1" && pwd)"
install_frontend "${frontend_dir}"
cd "${frontend_dir}"

passed=0
failed=0

echo "== the case that is successful (fast-check)"
# The verbose reporter gives the name of each test in the output (a green run without the reporter
# has only the summary, and the script cannot name the file it ran).
set +e
run_output="$(pnpm exec vitest run --reporter=verbose src/test/property.test.ts 2>&1)"
run_code=$?
set -e
if [[ ${run_code} -ne 0 ]]; then
    echo "FAIL the run of the property tests is not green (exit code ${run_code})"
    printf '%s\n' "${run_output}" | tail -n 40 | sed -e 's/^/     | /'
    failed=$((failed + 1))
else
    summary="$(printf '%s\n' "${run_output}" | grep -E 'Test Files|Tests  ' | tail -n 2)"
    if [[ "${summary}" == *"passed"* && "${summary}" != *"failed"* ]]; then
        echo "ok   the run of the property tests is green: ${summary//$'\n'/ | }"
        passed=$((passed + 1))
    else
        echo "FAIL the summary of the run has a failed test: ${summary}"
        failed=$((failed + 1))
    fi
    if [[ "${run_output}" == *"property.test.ts"* ]]; then
        echo "ok   the run has the properties of the generated schemas"
        passed=$((passed + 1))
    else
        echo "FAIL the run has not the file of the properties"
        failed=$((failed + 1))
    fi
fi

echo
echo "== the case that is not successful (ACC-002)"
set +e
run_output="$(pnpm exec vitest run --config vitest.config.negative.ts src/test/broken-property.broken.test.ts 2>&1)"
run_code=$?
set -e
if [[ ${run_code} -ne 0 && "${run_output}" == *"broken-property"* && "${run_output}" == *"Property failed"* && "${run_output}" == *"Counterexample"* ]]; then
    echo "ok   fast-check finds the counterexample of the wrong property, and the run stops for it"
    passed=$((passed + 1))
else
    echo "FAIL the run of the file of the broken property gives exit code ${run_code}, and the output has not the counterexample:"
    printf '%s\n' "${run_output}" | grep -E "FAIL|Property failed|Counterexample|Test Files" | head -n 5 | sed -e 's/^/     | /'
    failed=$((failed + 1))
fi

echo
echo "test-random-frontend: ${passed} ok, ${failed} failed"
[[ ${failed} -eq 0 ]]
