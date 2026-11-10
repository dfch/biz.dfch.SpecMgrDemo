#!/usr/bin/env bash
# feat-7-verification-architecture-tools, Task 110.130 (REQ-002, ACC-002)
#
# Test of the property tests of the Maven module with jqwik (the recipe test-random-backend).
#
# Usage: test-random-backend.sh <backend dir>
#
# Part 1, the case that is successful: the run of the property tests
# (`./mvnw test -Dtest=*PropertyTest`, the generation is skipped with -Dcodegen.skip=true). The
# properties run on the generated code (the example module has no product code): the value of each
# code of the enum ErrorCode round trips through fromValue, and the list has no duplicate value;
# and on a small function of the test (it counts the characters that are no letter): the count is
# between zero and the length of the text. The run is green (exit code 0), and the summary of
# surefire has no failure and no error.
#
# Part 2, the case that is not successful (ACC-002): the class BrokenProperty has no suffix Test,
# so the default run of surefire does not start it (the committed run is green). The script runs
# the class with -Dtest=BrokenProperty and stops for it: jqwik finds a counterexample of the
# property (the sum of two numbers is never 3), the run fails (exit code not 0), and the output
# names the failed property.
#
# The script needs JDK 21 (the Maven Wrapper of the module) and the network for the first run
# (Maven Central). It does not change the repository (the build is in target/, it is in .gitignore).
# It stops (exit code 1) if one part does not give the expected result.

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/_lib.sh"

[[ $# -eq 1 ]] || die "Usage: test-random-backend.sh <backend dir>"
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

echo "== the case that is successful (jqwik)"
mvn_run test -Dcodegen.skip=true -Dtest='*PropertyTest'
if [[ ${run_code} -ne 0 ]]; then
    echo "FAIL the run of the property tests is not green (exit code ${run_code})"
    printf '%s\n' "${run_output}" | tail -n 40 | sed -e 's/^/     | /'
    failed=$((failed + 1))
else
    summary="$(surefire_summary "${run_output}")"
    if [[ -n "${summary}" && "${summary}" == *"Failures: 0"* && "${summary}" == *"Errors: 0"* ]]; then
        total="$(sed -E 's/.*Tests run: ([0-9]+),.*/\1/' <<<"${summary}")"
        echo "ok   the run of the property tests is green: ${total} test(s), no failure and no error"
        passed=$((passed + 1))
    else
        echo "FAIL the summary of the run has a failure or an error: ${summary}"
        failed=$((failed + 1))
    fi
    if [[ "${run_output}" == *"ErrorCodePropertyTest"* && "${run_output}" == *"jqwik"* && "${run_output}" == *"tries ="* ]]; then
        echo "ok   the run has the properties of jqwik (the report of each property has the tries)"
        passed=$((passed + 1))
    else
        echo "FAIL the run has not the properties of jqwik"
        failed=$((failed + 1))
    fi
fi

echo
echo "== the case that is not successful (ACC-002)"
mvn_run test -Dcodegen.skip=true -Dtest=BrokenProperty
if [[ ${run_code} -ne 0 && "${run_output}" == *"BrokenProperty"* && "${run_output}" == *"the sum of any two numbers is 3"* && "${run_output}" == *"expected: <3> but was:"* ]]; then
    echo "ok   jqwik finds the counterexample of the wrong property, and the run stops for it"
    passed=$((passed + 1))
else
    echo "FAIL the run of BrokenProperty gives exit code ${run_code}, and the output has not the counterexample:"
    printf '%s\n' "${run_output}" | grep -E "Tests run|expected|FAILURE" | head -n 5 | sed -e 's/^/     | /'
    failed=$((failed + 1))
fi

echo
echo "test-random-backend: ${passed} ok, ${failed} failed"
[[ ${failed} -eq 0 ]]
