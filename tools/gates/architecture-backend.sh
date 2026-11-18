#!/usr/bin/env bash
# feat-50-structurizr-model-rules, Task 130.110 (REQ-004, ACC-005)
#
# The rules the model gives (the container backend, derived from model/workspace.json at test time,
# with ArchUnit; the recipe architecture-backend; the canonical form is the section "The rules the
# model gives" of model/README.md, DEC e85e9685-0787-4dff-9ee5-9d46670e9ee4). This recipe replaces
# the run of the hard-coded rules R1 and R2 of feat-7-verification-architecture-tools (the classes
# ModuleStructureTest, LayerRuleTest and BrokenLayerRule, removed in Task 130.140 of feat-50): the
# rules now come from the model (one source of truth, GOL 9ffb930c-44e8-4d0e-b4fd-f94c7162a894),
# and the same rules run from the model in both languages (the frontend side is the recipe
# architecture-frontend, the script frontend/architecture/runner.mjs).
#
# Usage: architecture-backend.sh <backend dir>
#
# The run (the JUnit class ModelRuleRunnerTest, the suffix Test so the normal run of surefire
# starts it too, the recipe test-unit-backend): the class reads the workspace (the file
# model/workspace.json of the repository; the property model.workspace.path gives another file, the
# same interface as ModelComparisonTest), derives the rule set of the container backend (the shared
# class ModelRules, the same derivation as the comparison), and builds the ArchUnit rules at test
# time: one dynamic test per derived rule. The derived rules (the groups 1 and 2 of the canonical
# section): the forbidden dependencies (every ordered pair of distinct mapped components that has
# no relation in the model; today: exactly one pair, the component model must not depend on the
# component api, the direction of the code is api -> model) and the cycle rule (the slices of the
# mapped components, one slice per component, the most specific entry of code.package, are free of
# cycles). The classes: the base package of the container's code.root, the test classes excluded by
# the import option DoNotIncludeTests (the same option as the comparison). A violation that
# ArchUnit reports names the dependency (the report of the run). The run is green on the committed
# code (ACC-002 and ACC-005: the derived rules hold), and the summary of surefire has no failure
# and no error.
#
# The case that is not successful of each rule category (ACC-006, the Broken* pattern) comes back
# in Phase 140 of feat-50-structurizr-model-rules: the recipe runs the broken case separately,
# stops for it, and names the violation (the form of the part 2 and 3 of this recipe before the
# change of feat-50).
#
# The script needs JDK 21 (the Maven Wrapper of the module) and the network for the first run
# (Maven Central). It does not change the repository (the build is in target/, it is in
# .gitignore). It stops (exit code 1) if the run does not give the expected result.

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/_lib.sh"

[[ $# -eq 1 ]] || die "Usage: architecture-backend.sh <backend dir>"
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

echo "== the rules the model gives (the container backend, derived at test time, ArchUnit)"
mvn_run test -Dcodegen.skip=true -Dtest=ModelRuleRunnerTest
if [[ ${run_code} -ne 0 ]]; then
    echo "FAIL the run of the derived rules is not green (exit code ${run_code})"
    printf '%s\n' "${run_output}" | tail -n 40 | sed -e 's/^/     | /'
    failed=$((failed + 1))
else
    summary="$(surefire_summary "${run_output}")"
    if [[ -n "${summary}" && "${summary}" == *"Failures: 0"* && "${summary}" == *"Errors: 0"* ]]; then
        total="$(sed -E 's/.*Tests run: ([0-9]+),.*/\1/' <<<"${summary}")"
        echo "ok   the run of the derived rules is green: ${total} test(s), no failure and no error"
        passed=$((passed + 1))
    else
        echo "FAIL the summary of the run has a failure or an error: ${summary}"
        failed=$((failed + 1))
    fi
    # The report of the run names the derived rule count (the line the test factory prints): the
    # forbidden pairs and the cycle rule of the container backend.
    if [[ "${run_output}" == *"the model gives"* && "${run_output}" == *"forbidden pair(s)"* && "${run_output}" == *"cycle rule for the container backend"* ]]; then
        echo "ok   the report names the derived rule count (the forbidden pairs and the cycle rule)"
        passed=$((passed + 1))
        printf '%s\n' "${run_output}" | grep -F "the model gives" | head -n 1 | sed -e 's/^\[INFO\] *//' | sed -e 's/^/     | /'
    else
        echo "FAIL the run has not the report of the derived rule count:"
        printf '%s\n' "${run_output}" | grep -E "Tests run|the model gives" | head -n 5 | sed -e 's/^/     | /'
        failed=$((failed + 1))
    fi
fi

echo
echo "architecture-backend: ${passed} ok, ${failed} failed"
[[ ${failed} -eq 0 ]]
