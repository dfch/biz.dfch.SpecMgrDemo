#!/usr/bin/env bash
# feat-7-verification-architecture-tools, Task 120.100 (REQ-002, ACC-002)
#
# Mutation tests of the Maven module with PIT (the recipe mutation-backend).
#
# Usage: mutation-backend.sh <backend dir>
#
# Part 1, the report: one run of ./mvnw (the version of the plugin is PIT_VERSION of
# tools/versions.env) starts the phase test-compile and then the goal
# org.pitest:pitest-maven:<PIT_VERSION>:mutationCoverage with -Dcodegen.skip=true (the generated
# code is committed, and the gate check-generated compares it with HEAD; the phase is
# necessary, the generator execution of generate-sources adds src/generated/java as a compile
# source root, and the goal skips a project with no compile source root). PIT mutates the
# compiled classes of the module (target/classes, the generated model code; the module has
# no product code) and runs the target tests (the unit tests of the generated code, see the
# configuration in backend/pom.xml) on each mutant. The run is green (exit code 0) and makes
# the HTML report and the XML report in target/pit-reports (the folder is in .gitignore
# through target/). The XML report is the deterministic source that part 2 asserts on.
#
# Part 2, the finding (ACC-002): the report has at least one mutant with the status
# SURVIVED. The mutant is deterministic for the pinned code and the pinned tests: the
# target tests never assert the return value of toString() of the generated enum ErrorCode,
# so the mutant of that method (replaced return value with "", the mutator
# EmptyObjectReturnValsMutator, line 47 of ErrorCode.java) survives in each run. The script
# reads the status attribute of each mutation of target/pit-reports/mutations.xml, counts
# the mutants with the status SURVIVED, and stops if there is no such mutant.
#
# The script needs JDK 21 (the Maven Wrapper of the module) and the network for the first run
# (Maven Central, the plugin and its dependencies). It does not change the repository (the
# build is in target/, it is in .gitignore). It stops (exit code 1) if one part does not give
# the expected result.

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/_lib.sh"

[[ $# -eq 1 ]] || die "Usage: mutation-backend.sh <backend dir>"
backend_dir="$1"
[[ -f "${backend_dir}/pom.xml" ]] || die "${backend_dir}/pom.xml does not exist"
[[ -x "${backend_dir}/mvnw" ]] || die "${backend_dir}/mvnw does not exist or is not executable"

cd "${backend_dir}"

pitest_version="$(version_of PIT_VERSION)"
report_dir="target/pit-reports"

passed=0
failed=0

rm -rf "${report_dir}" # no old report can pass for the new one

echo "== the report (PIT)"
set +e
run_output="$(./mvnw --batch-mode --no-transfer-progress test-compile \
    "org.pitest:pitest-maven:${pitest_version}:mutationCoverage" -Dcodegen.skip=true 2>&1)"
run_code=$?
set -e
if [[ ${run_code} -ne 0 ]]; then
    echo "FAIL the run of PIT is not green (exit code ${run_code})"
    printf '%s\n' "${run_output}" | tail -n 40 | sed -e 's/^/     | /'
    failed=$((failed + 1))
else
    if [[ -s "${report_dir}/index.html" && -s "${report_dir}/mutations.xml" ]]; then
        echo "ok   the report is made: ${report_dir}/index.html and ${report_dir}/mutations.xml"
        passed=$((passed + 1))
    else
        echo "FAIL the report is not made: ${report_dir} has no index.html or no mutations.xml"
        failed=$((failed + 1))
    fi
    if [[ "${run_output}" == *"Mutating from"* && "${run_output}" != *"Skipping project because"* ]]; then
        echo "ok   PIT mutated the compiled classes of the module (the run was not skipped)"
        passed=$((passed + 1))
    else
        echo "FAIL the run of PIT has no 'Mutating from' or it skipped the project:"
        printf '%s\n' "${run_output}" | grep -E "Mutating|Skipping" | head -n 3 | sed -e 's/^/     | /'
        failed=$((failed + 1))
    fi
    summary="$(printf '%s\n' "${run_output}" | grep -E '^>> Generated [0-9]+ mutations' | tail -n 1)"
    if [[ -n "${summary}" ]]; then
        echo "ok   the summary of the run: ${summary}"
        passed=$((passed + 1))
    else
        echo "FAIL the run has no summary line '>> Generated N mutations': ${summary}"
        failed=$((failed + 1))
    fi
fi

echo
echo "== the finding (a surviving mutant, ACC-002)"
survived=0
if [[ -s "${report_dir}/mutations.xml" ]]; then
    survived="$(grep -c "status='SURVIVED'" "${report_dir}/mutations.xml" || true)"
fi
if [[ ${survived} -ge 1 ]]; then
    echo "ok   the report has ${survived} mutant(s) with the status SURVIVED"
    passed=$((passed + 1))
    # One mutation is one line of the XML file: the line of the first surviving mutant, with its class, method,
    # line number, mutator and description.
    grep -o "<mutation[^>]*status='SURVIVED'.*" "${report_dir}/mutations.xml" | head -n 1 \
        | grep -oE "<mutatedClass>[^<]*</mutatedClass>|<mutatedMethod>[^<]*</mutatedMethod>|<lineNumber>[0-9]+</lineNumber>|<mutator>[^<]*</mutator>|<description>[^<]*</description>" \
        | sed -e 's/^/     | /'
else
    echo "FAIL the report has no mutant with the status SURVIVED (the deterministic one is the"
    echo "     mutant of toString() of the generated enum ErrorCode, the mutator EmptyObjectReturnValsMutator)"
    failed=$((failed + 1))
fi

echo
echo "mutation-backend: ${passed} ok, ${failed} failed"
[[ ${failed} -eq 0 ]]
