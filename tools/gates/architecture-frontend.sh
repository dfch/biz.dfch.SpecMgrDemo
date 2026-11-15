#!/usr/bin/env bash
# feat-7-verification-architecture-tools, Task 130.110 (REQ-003, ACC-002, ACC-006)
#
# The architecture tests of the frontend with ArchUniTS (the recipe architecture-frontend; DEC
# 9edc1071-4fd0-48b6-a037-1a4cb2331f73: "ArchUniTS examines the layers and the imports in the
# frontend.").
#
# Usage: architecture-frontend.sh <frontend dir>
#
# Part 1, the cases that are successful: the script installs the module first (install_frontend
# in _lib.sh: the frozen install of the lock file and the versions of tools/versions.env, with
# the package archunit in the version ARCHUNIT_TS_VERSION), and runs the architecture rules of
# the frontend (node architecture/rules.mjs, the tsconfig.json of the module). The rules (the
# directions the code has): R1' the module structure, the slice form of ArchUniTS (the unit
# generated has no dependency on the unit test, the pattern src/(**)); R2' the layer rule (the
# layers of the generated code - the units types and zod - do not depend on the layer of the
# tests, the direction of the code is test -> generated); R3' the imports rule (the generated
# code does not import from the unit root, the files that lie directly in frontend/src). The run
# is green (exit code 0), and each rule has no violation. A rule whose pattern has no file is not
# green (the check gives the violation No files found matching pattern(s), the option
# allowEmptyTests is false by default).
#
# Part 2, the case that is not successful (ACC-002): the script architecture/rules.broken.mjs
# runs the rule that the code violates (the unit test must not depend on the generated unit zod -
# the opposite direction of R2'; the test files of frontend/src/test import the generated Zod
# schemas, and the module has no product code, so the tests exercise the generated code). The run
# of the script stops for the violations (exit code 1), and it names the violating imports (the
# source file and the target file of each dependency). The recipe asserts the report and gives
# exit code 0.
#
# The maturity of ArchUniTS (ACC-006, REQ-008) is examined in the plan (the Result of the Phase
# 130): the rules R2' and R3' (the layers and the imports) are possible with the pinned version,
# and the module structure R1' is possible only in the slice form (a dependency between two named
# units): the part of the structure that is a closed set (exactly these units, no more, no less)
# is not possible - a unit that the code adds is not detected by the rules (the examination
# shows it), and the model comparison of the recipe architecture-model checks it instead (the
# units are discovered from the files of the code). The mitigation of RSK
# 025202ba-e4a7-4f6b-a65b-92f945b6f321 (a DEC for one more tool) is not triggered.
#
# The script needs Node and pnpm (install_frontend) and the network for the first run (the npm
# registry). It does not change the repository. It stops (exit code 1) if one part does not give
# the expected result.

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/_lib.sh"

[[ $# -eq 1 ]] || die "Usage: architecture-frontend.sh <frontend dir>"
[[ -d "$1" ]] || die "The folder of the pnpm module does not exist: $1"
frontend_dir="$(cd "$1" && pwd)"
install_frontend "${frontend_dir}"
cd "${frontend_dir}"

passed=0
failed=0

echo "== the cases that are successful (ArchUniTS: R1' the slice form, R2' the layer rule, R3' the imports rule)"
set +e
run_output="$(node architecture/rules.mjs "$(pwd)" 2>&1)"
run_code=$?
set -e
if [[ ${run_code} -ne 0 ]]; then
    echo "FAIL the run of the architecture rules is not green (exit code ${run_code})"
    printf '%s\n' "${run_output}" | tail -n 40 | sed -e 's/^/     | /'
    failed=$((failed + 1))
else
    if [[ "${run_output}" == *"PASS the architecture rules of the frontend are green"* ]]; then
        echo "ok   the run of the architecture rules is green (no violation for R1', R2' and R3')"
        passed=$((passed + 1))
    else
        echo "FAIL the run of the architecture rules has no PASS line:"
        printf '%s\n' "${run_output}" | tail -n 5 | sed -e 's/^/     | /'
        failed=$((failed + 1))
    fi
fi

echo
echo "== the case that is not successful (ACC-002)"
set +e
run_output="$(node architecture/rules.broken.mjs "$(pwd)" 2>&1)"
run_code=$?
set -e
if [[ ${run_code} -eq 1 && "${run_output}" == *"the violated rule has"* \
    && "${run_output}" == *"src/test/property.test.ts -> src/generated/zod/statusSchema.ts"* \
    && "${run_output}" == *"src/test/status-schema.test.ts -> src/generated/zod/statusSchema.ts"* ]]; then
    echo "ok   the run stops for the violated rule, and ArchUniTS names the violating imports"
    passed=$((passed + 1))
    printf '%s\n' "${run_output}" | grep -E "violation|src/test" | sed -e 's/^/     | /'
else
    echo "FAIL the run of rules.broken.mjs gives exit code ${run_code}, and the output has not the violations of the rule:"
    printf '%s\n' "${run_output}" | tail -n 10 | sed -e 's/^/     | /'
    failed=$((failed + 1))
fi

echo
echo "architecture-frontend: ${passed} ok, ${failed} failed"
[[ ${failed} -eq 0 ]]
