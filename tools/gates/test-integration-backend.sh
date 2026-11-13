#!/usr/bin/env bash
# feat-7-verification-architecture-tools, Task 110.100 (REQ-001, ACC-002)
#
# Test of the integration tests of the Maven module with Testcontainers (the recipe
# test-integration-backend).
#
# Usage: test-integration-backend.sh <backend dir>
#
# Part 1, the case that is successful: the run of the integration tests
# (`./mvnw test -Dtest=*IT`, the generation is skipped with -Dcodegen.skip=true). The class PostgresIT
# has the suffix IT, so the default run of the unit tests does not start it (the run of the recipe
# test-unit-backend is green without Docker). The test starts ONE lightweight container
# (postgres:16-alpine, the PostgreSQL license, and not an image of the SSPL/RSAL class), connects to
# it with the JDBC driver, and runs a trivial query (a table, an insert, a select). The run is green
# (exit code 0), and the summary of surefire has no failure and no error.
#
# Part 2, the case that is not successful (ACC-002): the class BrokenPostgres has no suffix IT, so
# the run of part 1 does not start it (the committed run is green). The script runs the class with
# -Dtest=BrokenPostgres and stops for it: the container starts and the connection works, and the
# assertion against the real query result is wrong on purpose (the run fails, exit code not 0), and
# the output names the failed assertion.
#
# The script needs JDK 21 (the Maven Wrapper of the module), Docker (the daemon of the machine; the
# container is a user container, and the script uses no elevated right) and the network for the first
# run (Maven Central, and the image of the container). It does not change the repository. It stops
# (exit code 1) if one part does not give the expected result.

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/_lib.sh"

[[ $# -eq 1 ]] || die "Usage: test-integration-backend.sh <backend dir>"
backend_dir="$1"
[[ -f "${backend_dir}/pom.xml" ]] || die "${backend_dir}/pom.xml does not exist"
[[ -x "${backend_dir}/mvnw" ]] || die "${backend_dir}/mvnw does not exist or is not executable"
require_cmd docker
docker info >/dev/null 2>&1 || die "The Docker daemon does not answer (docker info). The integration tests need Docker."

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

echo "== the case that is successful (Testcontainers, one container)"
mvn_run test -Dcodegen.skip=true -Dtest='*IT'
if [[ ${run_code} -ne 0 ]]; then
    echo "FAIL the run of the integration tests is not green (exit code ${run_code})"
    printf '%s\n' "${run_output}" | tail -n 40 | sed -e 's/^/     | /'
    failed=$((failed + 1))
else
    summary="$(surefire_summary "${run_output}")"
    if [[ -n "${summary}" && "${summary}" == *"Failures: 0"* && "${summary}" == *"Errors: 0"* ]]; then
        total="$(sed -E 's/.*Tests run: ([0-9]+),.*/\1/' <<<"${summary}")"
        echo "ok   the run of the integration tests is green: ${total} test(s) against the container"
        passed=$((passed + 1))
    else
        echo "FAIL the summary of the run has a failure or an error: ${summary}"
        failed=$((failed + 1))
    fi
    if [[ "${run_output}" == *"PostgresIT"* ]]; then
        echo "ok   the run has the test that starts the container and runs the query"
        passed=$((passed + 1))
    else
        echo "FAIL the run has not the test PostgresIT"
        failed=$((failed + 1))
    fi
fi

echo
echo "== the case that is not successful (ACC-002)"
mvn_run test -Dcodegen.skip=true -Dtest=BrokenPostgres
if [[ ${run_code} -ne 0 && "${run_output}" == *"BrokenPostgres"* && "${run_output}" == *"expected: <2> but was: <1>"* ]]; then
    echo "ok   the run stops for the wrong assertion against the real container, and the output names it"
    passed=$((passed + 1))
else
    echo "FAIL the run of BrokenPostgres gives exit code ${run_code}, and the output has not the failed assertion:"
    printf '%s\n' "${run_output}" | grep -E "Tests run|expected|FAILURE" | head -n 5 | sed -e 's/^/     | /'
    failed=$((failed + 1))
fi

echo
echo "test-integration-backend: ${passed} ok, ${failed} failed"
[[ ${failed} -eq 0 ]]
