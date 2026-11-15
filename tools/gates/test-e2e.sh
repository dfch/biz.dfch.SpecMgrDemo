#!/usr/bin/env bash
# feat-7-verification-architecture-tools, Task 110.120 (REQ-001, REQ-007, ACC-002)
#
# Test of the end-to-end tests with Playwright and the accessibility check of axe-core (the recipe
# test-e2e).
#
# Usage: test-e2e.sh <frontend dir>
#
# Part 0, the browser: the script installs the chromium browser for the pinned version of
# @playwright/test (`pnpm exec playwright install chromium`). The browser is in the user cache of
# the home (no right is necessary). If the browser of the version is already in the cache,
# playwright does not download it again (the install is idempotent).
#
# Part 1, the case that is successful: the run of the end-to-end tests (`pnpm exec playwright
# test --reporter=line`, the config playwright.config.ts, headless, no display). The reporter line
# is forced on both runs: the default reporter of Playwright in CI (no TTY) prints no title for a
# passed test, and the titles are what the recipe asserts on (the first real run of the job on
# GitHub, PR 46, 2026-11-13, was red for this assertion only; the reporter line is stable in TTY
# and in CI). The tests open the HTML fixtures of the folder e2e/fixtures/ (the config starts the
# static server of e2e/serve.mjs on the loopback address, waits for the port, and stops it after
# the run; no server of the script is necessary). The accessibility check uses the package axe-core
# directly: the test reads the source of axe.min.js from node_modules (and not a wrapper package,
# the license table names axe-core), injects it into the page, and runs axe. The good page gives
# zero violations, and the bad page (an image without alt, and a text with low contrast) gives the
# violations that axe reports (the rules image-alt and color-contrast). The run is green (exit code
# 0), and the summary of playwright has a passed test and no failed one.
#
# Part 2, the case that is not successful (ACC-002): the spec of the folder e2e/negative/ expects
# no violations on the page with violations. The config of part 1 does not start the folder, so
# the committed run is green. The script runs the spec with the config playwright.config.negative.ts
# and the reporter line (the same reason as part 1) and stops for it: axe-core reports the
# violations of the page, the test of Playwright fails (exit code not 0), and the output names the
# violations.
#
# The script needs Node and pnpm (install_frontend in _lib.sh installs the module from the lock file
# with `pnpm install --frozen-lockfile --ignore-scripts`, and stops if an installed package has
# another version than the key of tools/versions.env) and the network for the first run (the npm
# registry, and the download of the browser). The headless chromium needs the shared libraries of
# the machine (they are on the machine of the author and on the runner of GitHub). It does not
# change the repository (the output of the failed run, frontend/test-results/, is in .gitignore, and
# the script removes it). It stops (exit code 1) if one part does not give the expected result.

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/_lib.sh"

[[ $# -eq 1 ]] || die "Usage: test-e2e.sh <frontend dir>"
[[ -d "$1" ]] || die "The folder of the pnpm module does not exist: $1"
frontend_dir="$(cd "$1" && pwd)"
install_frontend "${frontend_dir}"
cd "${frontend_dir}"

passed=0
failed=0

# playwright_summary <output> -- the line of the summary of playwright (N passed / N failed)
playwright_summary() {
    printf '%s\n' "$1" | grep -E '^[[:space:]]+[0-9]+ (passed|failed)' | tail -n 2
}

cleanup() {
    rm -rf "${frontend_dir}/test-results"
}
trap cleanup EXIT

echo "== the browser (chromium for the pinned version of @playwright/test)"
set +e
run_output="$(pnpm exec playwright install chromium 2>&1)"
run_code=$?
set -e
if [[ ${run_code} -ne 0 ]]; then
    echo "FAIL the install of the chromium browser did not run (exit code ${run_code})"
    printf '%s\n' "${run_output}" | tail -n 20 | sed -e 's/^/     | /'
    failed=$((failed + 1))
else
    echo "ok   the chromium browser is in the user cache of the home (the install is idempotent)"
    passed=$((passed + 1))
fi

echo
echo "== the case that is successful (Playwright and axe-core)"
set +e
run_output="$(pnpm exec playwright test --reporter=line 2>&1)"
run_code=$?
set -e
if [[ ${run_code} -ne 0 ]]; then
    echo "FAIL the run of the end-to-end tests is not green (exit code ${run_code})"
    printf '%s\n' "${run_output}" | tail -n 40 | sed -e 's/^/     | /'
    failed=$((failed + 1))
else
    summary="$(playwright_summary "${run_output}")"
    if [[ "${summary}" == *"passed"* && "${summary}" != *"failed"* ]]; then
        echo "ok   the run of the end-to-end tests is green: ${summary//$'\n'/ | }"
        passed=$((passed + 1))
    else
        echo "FAIL the summary of the run has a failed test: ${summary}"
        failed=$((failed + 1))
    fi
    if [[ "${run_output}" == *"the good page has no violations"* && "${run_output}" == *"the bad page reports the violations"* ]]; then
        echo "ok   the run has the check of the good page (zero violations) and of the bad page (the violations of axe-core)"
        passed=$((passed + 1))
    else
        echo "FAIL the run has not the two tests of the accessibility check"
        failed=$((failed + 1))
    fi
fi

echo
echo "== the case that is not successful (ACC-002)"
set +e
run_output="$(pnpm exec playwright test --config playwright.config.negative.ts --reporter=line 2>&1)"
run_code=$?
set -e
if [[ ${run_code} -ne 0 && "${run_output}" == *"the bad page has no violations"* && "${run_output}" == *"image-alt"* && "${run_output}" == *"color-contrast"* ]]; then
    echo "ok   the run stops for the page with violations, and the output names them (image-alt, color-contrast)"
    passed=$((passed + 1))
else
    echo "FAIL the run of the spec of the bad page gives exit code ${run_code}, and the output has not the violations:"
    printf '%s\n' "${run_output}" | grep -E "failed|image-alt|color-contrast" | head -n 5 | sed -e 's/^/     | /'
    failed=$((failed + 1))
fi

echo
echo "test-e2e: ${passed} ok, ${failed} failed"
[[ ${failed} -eq 0 ]]
