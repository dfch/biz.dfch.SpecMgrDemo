#!/usr/bin/env bash
# feat-7-verification-architecture-tools, Task 140.110 (REQ-006)
#
# Coverage of the pnpm module with the provider v8 of Vitest (the recipe coverage-frontend).
# The recipe makes the report and prints the numbers. No threshold is set (REQ-006: the
# feature must not set a threshold; the walking skeleton sets the threshold from the
# measured baseline).
#
# Usage: coverage-frontend.sh <frontend dir>
#
# The report: the script installs the module first (install_frontend in _lib.sh), and runs
# the normal unit tests with coverage (`pnpm exec vitest run --config
# vitest.config.coverage.ts --coverage --reporter=verbose`, the provider
# @vitest/coverage-v8 in the pinned version, the same line as vitest). The test set is the
# normal one (the include and the exclude of vitest.config.ts: the files with the part
# `broken` are the cases that are not successful and are not in the run), and the coverage
# is over the SOURCE files of the module (the include set of the config): the generated
# code (the folders src/generated/types and src/generated/zod, the two artifacts of the
# generator) and the example file src/mutation-example.ts (the file that lies directly in
# src/). The test files (src/test/) are no source files of the module, so they are
# excluded. The run is green (exit code 0) and makes the text report (the console summary:
# the table with the row `All files`, and the block `Coverage summary`) and the HTML report
# in coverage/ (the folder is in .gitignore).
#
# The block `Coverage summary` is the deterministic source that the script asserts on: the
# line `Lines : X% ( a/b )` is the line coverage over the files of the include set (a is
# the covered lines, b is the total). The run does not fail for a coverage percentage: the
# config has no thresholds (the keys thresholds, the defaults of vitest have no value).
#
# The script needs Node and pnpm (install_frontend in _lib.sh installs the module from the
# lock file with `pnpm install --frozen-lockfile --ignore-scripts`, and stops if an
# installed package has another version than the key of tools/versions.env) and the network
# for the first run (the npm registry). It does not change the repository (the report is in
# coverage/, it is in .gitignore). It stops (exit code 1) if the run does not give the
# expected result.

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/_lib.sh"

[[ $# -eq 1 ]] || die "Usage: coverage-frontend.sh <frontend dir>"
[[ -d "$1" ]] || die "The folder of the pnpm module does not exist: $1"
frontend_dir="$(cd "$1" && pwd)"
install_frontend "${frontend_dir}"
cd "${frontend_dir}"

passed=0
failed=0

rm -rf coverage # no old report can pass for the new one

echo "== the report (Vitest, the provider v8)"
set +e
run_output="$(pnpm exec vitest run --config vitest.config.coverage.ts --coverage --reporter=verbose 2>&1)"
run_code=$?
set -e
if [[ ${run_code} -ne 0 ]]; then
    echo "FAIL the run of the coverage is not green (exit code ${run_code})"
    printf '%s\n' "${run_output}" | tail -n 40 | sed -e 's/^/     | /'
    failed=$((failed + 1))
else
    summary="$(printf '%s\n' "${run_output}" | grep -E 'Test Files|Tests  ' | tail -n 2)"
    if [[ "${summary}" == *"passed"* && "${summary}" != *"failed"* ]]; then
        echo "ok   the unit tests ran without failure: ${summary//$'\n'/ | }"
        passed=$((passed + 1))
    else
        echo "FAIL the summary of the run has a failed test file or test: ${summary}"
        failed=$((failed + 1))
    fi
    if [[ "${run_output}" == *"status-schema.test.ts"* && "${run_output}" == *"property.test.ts"* && "${run_output}" == *"mutation-example.test.ts"* ]]; then
        echo "ok   the run has the normal test files of the module (the files with the part broken are not in the run)"
        passed=$((passed + 1))
    else
        echo "FAIL the run has not the test files of the module"
        failed=$((failed + 1))
    fi
    if [[ -s "coverage/index.html" ]]; then
        echo "ok   the report is made: coverage/index.html (the HTML report)"
        passed=$((passed + 1))
    else
        echo "FAIL the report is not made: coverage/ has no index.html"
        failed=$((failed + 1))
    fi
fi

echo
echo "== the numbers (the block Coverage summary, over the files of the include set of vitest.config.coverage.ts)"
lines="$(printf '%s\n' "${run_output}" | grep -E '^Lines +: ' | tail -n 1)"
branches="$(printf '%s\n' "${run_output}" | grep -E '^Branches +: ' | tail -n 1)"
statements="$(printf '%s\n' "${run_output}" | grep -E '^Statements +: ' | tail -n 1)"
lines_form='\([[:space:]]*[0-9]+/[0-9]+[[:space:]]*\)'
if [[ -n "${lines}" && "${lines}" =~ ${lines_form} ]]; then
    echo "ok   the coverage summary:"
    printf '%s\n' "${statements}" "${branches}" "${lines}" | sed -e 's/^/     | /'
    passed=$((passed + 1))
else
    echo "FAIL the run has no coverage summary with the line coverage (the block Coverage summary):"
    printf '%s\n' "${run_output}" | tail -n 10 | sed -e 's/^/     | /'
    failed=$((failed + 1))
fi

echo
echo "coverage-frontend: ${passed} ok, ${failed} failed"
[[ ${failed} -eq 0 ]]
