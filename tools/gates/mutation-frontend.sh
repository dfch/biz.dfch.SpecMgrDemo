#!/usr/bin/env bash
# feat-7-verification-architecture-tools, Task 120.110 (REQ-002, ACC-002)
#
# Mutation tests of the pnpm module with Stryker (the recipe mutation-frontend).
#
# Usage: mutation-frontend.sh <frontend dir>
#
# Part 1, the report: the script installs the module first (install_frontend in _lib.sh:
# the frozen install of the lock file and the versions of tools/versions.env), and runs
# `pnpm exec stryker run` (the config stryker.config.json). The plugin @stryker-mutator/vitest-runner
# (the version STRYKER_VITEST_RUNNER_VERSION, the peer vitest >=2.0.0 operates with the pinned
# Vitest 5.1.0) runs Vitest as the test runner with the config vitest.config.ts (the normal
# run: the tests of the generated Zod schemas and the weak test of the example). Stryker
# mutates the scope of the config (src/mutation-example.ts, the example file for the mutation
# tests, and the generated Zod schemas in src/generated/zod) and runs the tests on each mutant.
# The run is green (exit code 0; the config has no breaking threshold, thresholds.break is
# null: the tool operates as a report and not as a gate, the DEC about verification). The run
# makes the HTML report and the JSON report in mutation-report/ (the folder is in .gitignore).
# The JSON report is the deterministic source that part 2 asserts on.
#
# Part 2, the finding (ACC-002): the report has at least one mutant with the status Survived.
# The example file is tested weakly on purpose (src/test/mutation-example.test.ts: one input
# for countLetters, one state for stateLabel), so the mutants of the example survive in each
# run. The run is deterministic for the pinned code and the pinned tests: the four runs of
# 2026-11-10 have the same 57 mutants with the same statuses (28 killed, 21 survived, 8 with
# no coverage). The script counts the occurrences of "status":"Survived" of the JSON report,
# and stops if there is no such mutant.
#
# The script needs Node and pnpm (install_frontend) and the network for the first run (the npm
# registry). It does not change the repository (the report is in mutation-report/, it is in
# .gitignore, and the temp folder of Stryker is deleted by the run). It stops (exit code 1) if
# one part does not give the expected result.

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/_lib.sh"

[[ $# -eq 1 ]] || die "Usage: mutation-frontend.sh <frontend dir>"
[[ -d "$1" ]] || die "The folder of the pnpm module does not exist: $1"
frontend_dir="$(cd "$1" && pwd)"
install_frontend "${frontend_dir}"
cd "${frontend_dir}"

report_dir="mutation-report"

passed=0
failed=0

rm -rf "${report_dir}" .stryker-tmp # no old report can pass for the new one

echo "== the report (Stryker)"
set +e
run_output="$(pnpm exec stryker run 2>&1)"
run_code=$?
set -e
if [[ ${run_code} -ne 0 ]]; then
    echo "FAIL the run of Stryker is not green (exit code ${run_code})"
    printf '%s\n' "${run_output}" | tail -n 40 | sed -e 's/^/     | /'
    failed=$((failed + 1))
else
    if [[ -s "${report_dir}/mutation.html" && -s "${report_dir}/mutation.json" ]]; then
        echo "ok   the report is made: ${report_dir}/mutation.html and ${report_dir}/mutation.json"
        passed=$((passed + 1))
    else
        echo "FAIL the report is not made: ${report_dir} has no mutation.html or no mutation.json"
        failed=$((failed + 1))
    fi
    if [[ "${run_output}" == *"Instrumented"* && "${run_output}" == *"Done in"* ]]; then
        echo "ok   Stryker instrumented the source files and the run is done"
        passed=$((passed + 1))
    else
        echo "FAIL the run of Stryker has no 'Instrumented' or no 'Done in':"
        printf '%s\n' "${run_output}" | grep -E "Instrumented|Done in" | head -n 3 | sed -e 's/^/     | /'
        failed=$((failed + 1))
    fi
    summary="$(printf '%s\n' "${run_output}" | grep -E '^All files' | tail -n 1)"
    if [[ -n "${summary}" ]]; then
        echo "ok   the summary of the run: ${summary}"
        passed=$((passed + 1))
    else
        echo "FAIL the run has no summary line 'All files' of the mutation score"
        failed=$((failed + 1))
    fi
fi

echo
echo "== the finding (a surviving mutant, ACC-002)"
survived=0
if [[ -s "${report_dir}/mutation.json" ]]; then
    survived="$(grep -o '"status":"Survived"' "${report_dir}/mutation.json" | wc -l)"
fi
if [[ ${survived} -ge 1 ]]; then
    echo "ok   the report has ${survived} mutant(s) with the status Survived"
    passed=$((passed + 1))
    # The first block of a surviving mutant of the output of the run (the clear-text reporter:
    # the mutator, the file and the line, and the change).
    printf '%s\n' "${run_output}" | awk '/^\[Survived\]/{found = 1} found {print; count++} count == 4 {exit}' \
        | sed -e 's/^/     | /'
else
    echo "FAIL the report has no mutant with the status Survived (the deterministic ones are the"
    echo "     mutants of the example src/mutation-example.ts, the test of it is weak on purpose)"
    failed=$((failed + 1))
fi

echo
echo "mutation-frontend: ${passed} ok, ${failed} failed"
[[ ${failed} -eq 0 ]]
