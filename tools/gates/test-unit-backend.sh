#!/usr/bin/env bash
# feat-7-verification-architecture-tools, Task 110.100 (REQ-001, ACC-002)
#
# Test of the unit tests of the Maven module with JUnit (the recipe test-unit-backend).
#
# Usage: test-unit-backend.sh <backend dir>
#
# Part 1, the case that is successful: the run of the unit tests (`./mvnw test`, the generation is
# skipped with -Dcodegen.skip=true, the generated code is committed, and the gate check-generated
# compares it with HEAD). The tests exercise the generated code (the example module has no product
# code): the enum ErrorCode (the values of the contract, the round trip through fromValue) and the
# interface StatusApi (the path of the contract). The run is green (exit code 0), and the summary of
# surefire has no failure and no error. The run has the two engines of the JUnit Platform (the JUnit
# tests and the property tests of jqwik).
#
# Part 2, the case that is not successful (ACC-002): the class BrokenAssertion has no suffix Test,
# so the default run of part 1 does not start it (the committed run is green). The script runs the
# class with -Dtest=BrokenAssertion and stops for it: the run fails (exit code not 0), and the
# output names the failed assertion of JUnit.
#
# The script needs JDK 21 (the Maven Wrapper of the module) and the network for the first run
# (Maven Central). It does not change the repository (the build is in target/, it is in .gitignore).
# It stops (exit code 1) if one part does not give the expected result.

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/_lib.sh"

[[ $# -eq 1 ]] || die "Usage: test-unit-backend.sh <backend dir>"
backend_dir="$1"
[[ -f "${backend_dir}/pom.xml" ]] || die "${backend_dir}/pom.xml does not exist"
[[ -x "${backend_dir}/mvnw" ]] || die "${backend_dir}/mvnw does not exist or is not executable"

cd "${backend_dir}"

passed=0
failed=0

# surefire_summary <output> -- the final summary line of surefire (the line with no class name)
surefire_summary() {
    printf '%s\n' "$1" | grep -E '^\[INFO\] Tests run: [0-9]+, Failures: [0-9]+, Errors: [0-9]+, Skipped: [0-9]+$' | tail -n 1
}

# mvn_run <args...>: run ./mvnw, and capture the output and the exit code (run_output, run_code)
mvn_run() {
    set +e
    run_output="$(./mvnw --batch-mode --no-transfer-progress "$@" 2>&1)"
    run_code=$?
    set -e
}

echo "== the case that is successful (JUnit)"
mvn_run test -Dcodegen.skip=true
if [[ ${run_code} -ne 0 ]]; then
    echo "FAIL the run of the unit tests is not green (exit code ${run_code})"
    printf '%s\n' "${run_output}" | tail -n 40 | sed -e 's/^/     | /'
    failed=$((failed + 1))
else
    summary="$(surefire_summary "${run_output}")"
    if [[ -n "${summary}" && "${summary}" == *"Failures: 0"* && "${summary}" == *"Errors: 0"* ]]; then
        total="$(sed -E 's/.*Tests run: ([0-9]+),.*/\1/' <<<"${summary}")"
        echo "ok   the run of the unit tests is green: ${total} test(s), no failure and no error"
        passed=$((passed + 1))
    else
        echo "FAIL the summary of the run has a failure or an error: ${summary}"
        failed=$((failed + 1))
    fi
    if [[ "${run_output}" == *"ErrorCodeTest"* && "${run_output}" == *"ErrorCodePropertyTest"* && "${run_output}" == *"jqwik"* ]]; then
        echo "ok   the run has the JUnit tests of the generated code and the property tests of jqwik"
        passed=$((passed + 1))
    else
        echo "FAIL the run has not the tests of JUnit and of jqwik"
        failed=$((failed + 1))
    fi
fi

echo
echo "== the case that is not successful (ACC-002)"
mvn_run test -Dcodegen.skip=true -Dtest=BrokenAssertion
if [[ ${run_code} -ne 0 && "${run_output}" == *"BrokenAssertion"* && "${run_output}" == *"expected: <3> but was: <2>"* ]]; then
    echo "ok   the run stops for the wrong assertion of JUnit, and the output names it"
    passed=$((passed + 1))
else
    echo "FAIL the run of BrokenAssertion gives exit code ${run_code}, and the output has not the failed assertion:"
    printf '%s\n' "${run_output}" | grep -E "Tests run|expected|FAILURE" | head -n 5 | sed -e 's/^/     | /'
    failed=$((failed + 1))
fi

echo
echo "test-unit-backend: ${passed} ok, ${failed} failed"
[[ ${failed} -eq 0 ]]
