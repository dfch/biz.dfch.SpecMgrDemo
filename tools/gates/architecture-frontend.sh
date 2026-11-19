#!/usr/bin/env bash
# feat-50-structurizr-model-rules, Task 140.110 (REQ-007, ACC-006)
#
# The rules the model gives (the container frontend, derived from model/workspace.json at run time,
# with ArchUniTS; the recipe architecture-frontend; the canonical form is the section "The rules
# the model gives" of model/README.md, DEC e85e9685-0787-4dff-9ee5-9d46670e9ee4). The rules come
# from the model (one source of truth, GOL 9ffb930c-44e8-4d0e-b4fd-f94c7162a894), and the same
# rules run from the model in both languages (the backend side is the recipe architecture-backend,
# the class ModelRuleRunnerTest).
#
# Usage: architecture-frontend.sh <frontend dir>
#
# Part 1, the case that is successful (ACC-002 and ACC-005: the derived rules hold): the script
# installs the module first (install_frontend in _lib.sh: the frozen install of the lock file and
# the versions of tools/versions.env, with the package archunit in the version ARCHUNIT_TS_VERSION),
# and runs the script frontend/architecture/runner.mjs (the tsconfig.json of the module). The
# script reads the workspace strictly (the shared module frontend/architecture/workspace.mjs, the
# same reading and the same derivation as the comparison compare.mjs, so the two cannot drift
# apart), derives the rule set of the container frontend, and builds the checks of ArchUniTS
# programmatically: one check per derived rule. The derived rules (the groups 1 and 2 of the
# canonical section): the forbidden dependencies (every ordered pair of distinct mapped components
# that has no relation in the model; today: the 10 pairs of the four units types, zod, test and
# root, except the two modelled relations test -> zod and test -> root) and the cycle rule (no
# dependency cycle among the mapped components, the construct haveNoCycles of ArchUniTS). The
# pattern of a component is a pattern of the type RegExp of the entries of code.path (the form of
# the spike of Phase 100: a folder entry with the folder suffix matches the files of the folder at
# each depth, and a file entry matches the file; the text glob of the form (a|b) is not supported).
# A violation names the imports (the source file and the target file of each dependency, as the
# rules.mjs of feat-7). A rule whose pattern has no file is not green (the option allowEmptyTests
# of the check is false by default, and the check gives the violation No files found matching
# pattern(s)): a unit that disappears stops the run. The run is green (exit code 0) on the
# committed code, and the report of the run names the derived rule count.
#
# Part 2, the case that is not successful of the forbidden dependencies (ACC-006, the broken form
# of the house pattern): the script frontend/architecture/runner.broken.mjs (a separate script
# that the committed run of part 1 does not start) derives the same way: it reads the workspace
# through the shared module workspace.mjs, takes the relations of the model between the mapped
# components of the container frontend (today: the two relations test -> zod and test -> root),
# and builds for each of them the check of ArchUniTS that FORBIDS it (the component test must not
# depend on the component zod, and the component test must not depend on the component root). The
# code has the direction of each modelled relation (the test files import the generated Zod
# schemas and the file of the unit root), so each check is violated deterministically, and
# ArchUniTS names the violating imports in the report (the source file and the target file of
# each dependency: the four imports of the relation test -> zod, and the one import of the
# relation test -> root). The run of the script gives exit code 1 (the violations are printed),
# and the script also gives exit code 1 if a modelled relation has no violation in the code (the
# case that is not successful that passes silently would hide a change of the code, the form of
# the old script rules.broken.mjs of feat-7). The recipe asserts the exit code and the named
# imports, and gives exit code 0.
#
# Part 3, the case that is not successful of the cycle rule (ACC-006, the broken form of the
# house pattern): the committed code has no cycle of the mapped units (the cycle rule of part 1
# is green), so a separate script cannot show it; the recipe demonstrates the cycle in a
# temporary copy of the repository (copy_work_tree in _lib.sh, the same pattern as the recipe
# architecture-model; the repository is never changed). The copy has two scratch files in the
# mapped units (the folders of the entries of code.path, included by the tsconfig of the module):
# the file src/generated/types/zCycle.ts (the unit types) imports from the file
# src/test/zCycle.ts (the unit test), and the file src/test/zCycle.ts imports from the file
# src/generated/types/zCycle.ts (the direction types -> test and the direction test -> types of
# the code): it makes the dependency cycle types <-> test of the mapped components. The recipe
# runs the runner in the copy (node architecture/runner.mjs, the frozen install of the copy) and
# stops for it: the run is red (exit code 1), and the report of the cycle rule names the edges
# of the cycle (the two scratch files, and not the order of them).
#
# The limit of the parity (the canonical section, and the language skew of DEC e85e9685): ArchUniTS
# does not examine a closed set of units (a new unit that the code adds is invisible to the rules;
# the comparison compare.mjs examines it), and the graph of ArchUniTS has no edge to the external
# packages (the folder node_modules is excluded): the check of code.allowedExternal is in the
# comparison, and not in the runner.
#
# The script needs Node and pnpm (install_frontend, the temporary copy of part 3), git and tar
# (the temporary copy of part 3) and the network for the first run (the npm registry). It does
# not change the repository (the copy of part 3 is in a temporary folder). It stops (exit code
# 1) if one part does not give the expected result.

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/_lib.sh"

[[ $# -eq 1 ]] || die "Usage: architecture-frontend.sh <frontend dir>"
[[ -d "$1" ]] || die "The folder of the pnpm module does not exist: $1"
frontend_dir="$(cd "$1" && pwd)"
install_frontend "${frontend_dir}"
cd "${frontend_dir}"

work="$(mktemp -d)"
trap 'rm -rf "${work}"' EXIT

passed=0
failed=0

echo "== part 1: the run of the derived rules (the case that is successful)"
set +e
run_output="$(node architecture/runner.mjs "$(pwd)" 2>&1)"
run_code=$?
set -e
if [[ ${run_code} -ne 0 ]]; then
    echo "FAIL the run of the derived rules is not green (exit code ${run_code})"
    printf '%s\n' "${run_output}" | tail -n 40 | sed -e 's/^/     | /'
    failed=$((failed + 1))
else
    # The report of the run names the derived rule count (the 10 forbidden pairs of the model
    # today, and the cycle rule).
    if [[ "${run_output}" == *"the model gives 10 forbidden pair(s) and 1 cycle rule for the container frontend (11 rule(s))"* ]]; then
        echo "ok   the report names the derived rule count (10 forbidden pair(s) and the cycle rule)"
        passed=$((passed + 1))
        printf '%s\n' "${run_output}" | grep -F "the model gives" | head -n 1 | sed -e 's/^/     | /'
    else
        echo "FAIL the run has not the report of the derived rule count (the 10 forbidden pair(s) of the model today):"
        printf '%s\n' "${run_output}" | grep -E "the model gives|FAIL" | head -n 5 | sed -e 's/^/     | /'
        failed=$((failed + 1))
    fi
    if [[ "${run_output}" == *"PASS the rules the model gives (the container frontend) are green"* ]]; then
        echo "ok   the run of the derived rules is green (no violation for the 10 forbidden pair(s) and the cycle rule)"
        passed=$((passed + 1))
    else
        echo "FAIL the run of the derived rules has no PASS line:"
        printf '%s\n' "${run_output}" | tail -n 5 | sed -e 's/^/     | /'
        failed=$((failed + 1))
    fi
fi

echo
echo "== part 2: the case that is not successful of the forbidden dependencies (the script runner.broken.mjs, ACC-006)"
set +e
run_output="$(node architecture/runner.broken.mjs "$(pwd)" 2>&1)"
run_code=$?
set -e
if [[ ${run_code} -eq 1 && "${run_output}" == *"the violated rule has 4 violation(s): the component test depends on the component zod"* \
    && "${run_output}" == *"src/test/property.test.ts -> src/generated/zod/statusSchema.ts"* \
    && "${run_output}" == *"src/test/status-schema.test.ts -> src/generated/zod/errorCodeSchema.ts"* \
    && "${run_output}" == *"src/test/status-schema.test.ts -> src/generated/zod/problemSchema.ts"* \
    && "${run_output}" == *"src/test/status-schema.test.ts -> src/generated/zod/statusSchema.ts"* \
    && "${run_output}" == *"the violated rule has 1 violation(s): the component test depends on the component root"* \
    && "${run_output}" == *"src/test/mutation-example.test.ts -> src/mutation-example.ts"* ]]; then
    echo "ok   the run stops for the violated rules, and ArchUniTS names the violating imports"
    passed=$((passed + 1))
    printf '%s\n' "${run_output}" | grep -E "violation|src/test" | sed -e 's/^/     | /'
else
    echo "FAIL the run of runner.broken.mjs gives exit code ${run_code}, and the output has not the violations of the rules:"
    printf '%s\n' "${run_output}" | tail -n 10 | sed -e 's/^/     | /'
    failed=$((failed + 1))
fi

echo
echo "== part 3: the case that is not successful of the cycle rule (ACC-006, a temporary copy of the repository)"
copy_work_tree "${work}/cycle"
cat >"${work}/cycle/frontend/src/generated/types/zCycle.ts" <<'EOF'
// Scratch file of the case that is not successful of the recipe architecture-frontend
// (feat-50-structurizr-model-rules, Task 140.110, ACC-006): the file lies in the unit types
// (the folder src/generated/types) and imports from the unit test, the direction types -> test
// of the code. With the file src/test/zCycle.ts (the direction test -> types), it makes the
// dependency cycle types <-> test of the mapped components of the container frontend. The file
// exists in the temporary copy only; the repository is never changed.
import { fromTest } from '../../test/zCycle'

export const fromTypes = fromTest
EOF
cat >"${work}/cycle/frontend/src/test/zCycle.ts" <<'EOF'
// Scratch file of the case that is not successful of the recipe architecture-frontend
// (feat-50-structurizr-model-rules, Task 140.110, ACC-006): the file lies in the unit test
// (the folder src/test) and imports from the unit types, the direction test -> types of the
// code. With the file src/generated/types/zCycle.ts (the direction types -> test), it makes the
// dependency cycle types <-> test of the mapped components of the container frontend. The file
// exists in the temporary copy only; the repository is never changed.
import { fromTypes } from '../generated/types/zCycle'

export const fromTest = fromTypes
EOF
install_frontend "${work}/cycle/frontend"
set +e
run_output="$(cd "${work}/cycle/frontend" && node architecture/runner.mjs "$(pwd)" 2>&1)"
run_code=$?
set -e
# The cycle block of the report (the lines from the FAIL line of the cycle rule - the last rule
# of the runner - to the end of the output): the edges of the cycle, without the order.
cycle_block="$(printf '%s\n' "${run_output}" | sed -n '/FAIL the mapped components of the container frontend have no dependency cycle/,$p')"
if [[ ${run_code} -eq 1 && -n "${cycle_block}" \
    && "${cycle_block}" == *"src/generated/types/zCycle.ts"* && "${cycle_block}" == *"src/test/zCycle.ts"* ]]; then
    echo "ok   the run of the copy stops for the cycle, and the report names the two scratch files of the cycle"
    passed=$((passed + 1))
    printf '%s\n' "${cycle_block}" | sed -e 's/^/     | /'
else
    echo "FAIL the run of the copy gives exit code ${run_code}, and the output has not the cycle of the two scratch files:"
    printf '%s\n' "${run_output}" | grep -E "FAIL|have no dependency cycle" | head -n 5 | sed -e 's/^/     | /'
    failed=$((failed + 1))
fi

echo
echo "architecture-frontend: ${passed} ok, ${failed} failed"
[[ ${failed} -eq 0 ]]
