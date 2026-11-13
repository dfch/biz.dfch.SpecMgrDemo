#!/usr/bin/env bash
# feat-7-verification-architecture-tools, Task 140.110 (REQ-006)
#
# Coverage of the Maven module with JaCoCo (the recipe coverage-backend). The recipe makes
# the report and prints the numbers. No threshold is set (REQ-006: the feature must not set
# a threshold; the walking skeleton sets the threshold from the measured baseline).
#
# Usage: coverage-backend.sh <backend dir>
#
# The report: one run of ./mvnw (the version of the plugin is JACOCO_VERSION of
# tools/versions.env) starts the goal
# org.jacoco:jacoco-maven-plugin:<JACOCO_VERSION>:prepare-agent, then the phase test, then
# the goal org.jacoco:jacoco-maven-plugin:<JACOCO_VERSION>:report, with -Dcodegen.skip=true
# (the generated code is committed, and the gate check-generated compares it with HEAD).
# The goals and the phase run in this order (the standard form of the JaCoCo recipe):
# prepare-agent sets the project property argLine before the phase test runs, and the test
# runner maven-surefire-plugin (that has no own argLine configuration) passes it to the
# forked JVM; report reads the execution data (target/jacoco.exec) after the tests. The
# run is green (exit code 0) and makes the HTML report and the XML report in
# target/site/jacoco (index.html and jacoco.xml, the parameter formats of the plugin in
# backend/pom.xml; the folder is in .gitignore through target/).
#
# The tests of the run are the unit tests, the normal run of surefire (the same set as the
# recipe test-unit-backend): the JUnit tests of the generated code, the property tests of
# jqwik, and the architecture tests (the classes of the recipe architecture-backend and the
# comparison ModelComparisonTest of the recipe architecture-model, the suffix Test is in the
# default run). The integration tests are no unit tests: the suffix IT keeps them out of the
# run, and the run is deterministic without the Docker daemon. The class set of the report
# is the default of the plugin: every class of target/classes (the generated code of the
# contract - the packages biz.dfch.specmgrdemo.api and biz.dfch.specmgrdemo.model; the
# module has no product code). The XML report is the deterministic source that the script
# asserts on: the counters of the report element are the totals over the class set (the
# covered and the missed lines and branches).
#
# The script needs JDK 21 (the Maven Wrapper of the module), uv (the Python of the numbers
# step, the step that prints the counters of the XML report) and the network for the first
# run (Maven Central, the plugin and its dependencies). It does not change the repository
# (the build is in target/, it is in .gitignore). It stops (exit code 1) if the run does
# not give the expected result.

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/_lib.sh"

require_cmd uv

[[ $# -eq 1 ]] || die "Usage: coverage-backend.sh <backend dir>"
backend_dir="$1"
[[ -f "${backend_dir}/pom.xml" ]] || die "${backend_dir}/pom.xml does not exist"
[[ -x "${backend_dir}/mvnw" ]] || die "${backend_dir}/mvnw does not exist or is not executable"

cd "${backend_dir}"

jacoco_version="$(version_of JACOCO_VERSION)"
report_dir="target/site/jacoco"

passed=0
failed=0

rm -rf "${report_dir}" target/jacoco.exec # no old report or data can pass for the new one

echo "== the report (JaCoCo)"
set +e
run_output="$(./mvnw --batch-mode --no-transfer-progress \
    "org.jacoco:jacoco-maven-plugin:${jacoco_version}:prepare-agent" test \
    "org.jacoco:jacoco-maven-plugin:${jacoco_version}:report" -Dcodegen.skip=true 2>&1)"
run_code=$?
set -e
if [[ ${run_code} -ne 0 ]]; then
    echo "FAIL the run of the coverage is not green (exit code ${run_code})"
    printf '%s\n' "${run_output}" | tail -n 40 | sed -e 's/^/     | /'
    failed=$((failed + 1))
else
    summary="$(printf '%s\n' "${run_output}" \
        | grep -E '^\[INFO\] Tests run: [0-9]+, Failures: [0-9]+, Errors: [0-9]+, Skipped: [0-9]+$' | tail -n 1)"
    if [[ -n "${summary}" && "${summary}" == *"Failures: 0"* && "${summary}" == *"Errors: 0"* ]]; then
        echo "ok   the unit tests ran without failure and without error: ${summary}"
        passed=$((passed + 1))
    else
        echo "FAIL the run has no green summary of the unit tests: ${summary}"
        failed=$((failed + 1))
    fi
    if [[ -s "${report_dir}/index.html" && -s "${report_dir}/jacoco.xml" ]]; then
        echo "ok   the report is made: ${report_dir}/index.html and ${report_dir}/jacoco.xml"
        passed=$((passed + 1))
    else
        echo "FAIL the report is not made: ${report_dir} has no index.html or no jacoco.xml"
        failed=$((failed + 1))
    fi
fi

echo
echo "== the numbers (the counters of the report element of the XML, over the class set of target/classes)"
totals="$(uv run --no-project --quiet python - "${report_dir}/jacoco.xml" <<'PYEOF'
import sys
import xml.etree.ElementTree as ET

path = sys.argv[1]
root = ET.parse(path).getroot()
# The counters of the report element are the totals over the class set of the report
# (the package and the class counters are nested and come first in the file).
counters = {}
for counter in root.findall("counter"):
    counters[counter.get("type")] = (
        int(counter.get("missed", "0")),
        int(counter.get("covered", "0")),
    )
for kind in ("LINE", "BRANCH"):
    missed, covered = counters.get(kind, (0, 0))
    total = missed + covered
    if total == 0:
        print(f"{kind}: 0/0 (no {kind.lower()} in the class set)")
    else:
        percent = 100.0 * covered / total
        print(f"{kind}: {covered}/{total} ({percent:.2f}%)")
PYEOF
)" || totals=""
if [[ -n "${totals}" && "${totals}" == *"LINE: "* && "${totals}" == *"BRANCH: "* ]]; then
    while IFS= read -r line; do
        echo "ok   ${line}"
    done <<<"${totals}"
    passed=$((passed + 1))
else
    echo "FAIL the XML report has no counters of the report element:"
    printf '%s\n' "${run_output}" | tail -n 10 | sed -e 's/^/     | /'
    failed=$((failed + 1))
fi

echo
echo "coverage-backend: ${passed} ok, ${failed} failed"
[[ ${failed} -eq 0 ]]
