#!/usr/bin/env bash
# feat-50-structurizr-model-rules, Task 130.120 (REQ-004, ACC-005)
#
# The rules the model gives (the container frontend, derived from model/workspace.json at run time,
# with ArchUniTS; the recipe architecture-frontend; the canonical form is the section "The rules the
# model gives" of model/README.md, DEC e85e9685-0787-4dff-9ee5-9d46670e9ee4). This recipe replaces
# the run of the hard-coded rules R1', R2' and R3' of feat-7-verification-architecture-tools (the
# scripts rules.mjs and rules.broken.mjs, removed in Task 130.140 of feat-50): the rules now come
# from the model (one source of truth, GOL 9ffb930c-44e8-4d0e-b4fd-f94c7162a894), and the same
# rules run from the model in both languages (the backend side is the recipe architecture-backend,
# the class ModelRuleRunnerTest).
#
# Usage: architecture-frontend.sh <frontend dir>
#
# The run (the script frontend/architecture/runner.mjs, the tsconfig.json of the module): the script
# reads the workspace strictly (the shared module frontend/architecture/workspace.mjs, the same
# reading and the same derivation as the comparison compare.mjs, so the two cannot drift apart),
# derives the rule set of the container frontend, and builds the checks of ArchUniTS programmatically:
# one check per derived rule. The derived rules (the groups 1 and 2 of the canonical section): the
# forbidden dependencies (every ordered pair of distinct mapped components that has no relation in
# the model; today: the 10 pairs of the four units types, zod, test and root, except the two
# modelled relations test -> zod and test -> root) and the cycle rule (no dependency cycle among
# the mapped components, the construct haveNoCycles of ArchUniTS). The pattern of a component is a
# pattern of the type RegExp of the entries of code.path (the form of the spike of Phase 100: a
# folder entry with the folder suffix matches the files of the folder at each depth, and a file
# entry matches the file; the text glob of the form (a|b) is not supported). A violation names the
# imports (the source file and the target file of each dependency, as the rules.mjs of feat-7). A
# rule whose pattern has no file is not green (the option allowEmptyTests of the check is false by
# default, and the check gives the violation No files found matching pattern(s)): a unit that
# disappears stops the run. The run is green (exit code 0) on the committed code (ACC-002 and
# ACC-005: the derived rules hold).
#
# The limit of the parity (the canonical section, and the language skew of DEC e85e9685): ArchUniTS
# does not examine a closed set of units (a new unit that the code adds is invisible to the rules;
# the comparison compare.mjs examines it), and the graph of ArchUniTS has no edge to the external
# packages (the folder node_modules is excluded): the check of code.allowedExternal is in the
# comparison, and not in the runner.
#
# The case that is not successful of each rule category (ACC-006, the Broken* pattern) comes back
# in Phase 140 of feat-50-structurizr-model-rules: the recipe runs the broken case separately,
# stops for it, and names the violation (the form of the part 2 of this recipe before the change
# of feat-50).
#
# The script needs Node and pnpm (install_frontend) and the network for the first run (the npm
# registry). It does not change the repository. It stops (exit code 1) if the run does not give
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

echo "== the rules the model gives (the container frontend, derived at run time, ArchUniTS)"
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
echo "architecture-frontend: ${passed} ok, ${failed} failed"
[[ ${failed} -eq 0 ]]
