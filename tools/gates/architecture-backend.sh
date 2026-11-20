#!/usr/bin/env bash
# feat-50-structurizr-model-rules, Task 140.100 (REQ-007, ACC-006)
#
# The rules the model gives (the container backend, derived from model/workspace.json at test time,
# with ArchUnit; the recipe architecture-backend; the canonical form is the section "The rules the
# model gives" of model/README.md, DEC e85e9685-0787-4dff-9ee5-9d46670e9ee4). The rules come from
# the model (one source of truth, GOL 9ffb930c-44e8-4d0e-b4fd-f94c7162a894), and the same rules
# run from the model in both languages (the frontend side is the recipe architecture-frontend,
# the script frontend/architecture/runner.mjs).
#
# Usage: architecture-backend.sh <backend dir>
#
# Part 1, the case that is successful (ACC-002 and ACC-005: the derived rules hold): the JUnit
# class ModelRuleRunnerTest (the suffix Test, so the normal run of surefire starts it too, the
# recipe test-unit-backend) reads the workspace (the file model/workspace.json of the repository;
# the property model.workspace.path gives another file, the same interface as ModelComparisonTest),
# derives the rule set of the container backend (the shared class ModelRules, the same derivation
# as the comparison), and builds the ArchUnit rules at test time: one dynamic test per derived
# rule. The derived rules (the groups 1 and 2 of the canonical section): the forbidden
# dependencies (every ordered pair of distinct mapped components that has no relation in the
# model; today: the three pairs api -> app, model -> api and model -> app, the direction of the
# code is api -> model, app -> api and app -> model) and the cycle rule (the slices of the mapped components,
# one slice per component, the most specific entry of code.package, are free of cycles). The
# classes: the base package of the container's code.root, the test classes excluded by the import
# option DoNotIncludeTests (the same option as the comparison). A violation that ArchUnit reports
# names the dependency (the report of the run). The run is green (exit code 0), the summary of
# surefire has no failure and no error, and the report of the run names the derived rule count.
#
# Part 2, the case that is not successful of the forbidden dependencies (ACC-006, the Broken*
# pattern): the class BrokenModelRule (no suffix Test, so the default run of part 1 does not start
# it, and the committed run is green) derives the same way: it reads the workspace, takes the
# relations of the model between the mapped components of the container backend (today: api ->
# model, app -> api and app -> model), and builds for each of them the ArchUnit rule that FORBIDS
# it. The code has the direction of the modelled relation (the generated interfaces reference the
# classes of the model, and the controllers of app implement the generated interfaces of api), so
# the rule is violated deterministically, and ArchUnit names the violating dependency in the
# report (the method getStatus() of the interface StatusApi, with the return type of the model
# class Status). The script runs the class with -Dtest=BrokenModelRule and stops for it: the run
# is red (exit code not 0), the report names the violation, and the script gives exit code 0.
#
# Part 3, the case that is not successful of the cycle rule (ACC-006, the Broken* pattern): the
# committed code has no cycle of the mapped components (the cycle rule of part 1 is green), so a
# separate artifact cannot show it; the script demonstrates the cycle in a temporary copy of the
# repository (copy_work_tree in _lib.sh, the same pattern as the recipe architecture-model; the
# repository is never changed). The copy has one scratch class in the normal source root
# (src/main/java - and not in src/generated, the folder that the generator execution of a build
# without the skip flag would wipe) in the package biz.dfch.specmgrdemo.model (the component
# model) that references the interface biz.dfch.specmgrdemo.api.StatusApi (the component api):
# with the direction api -> model of the committed code (the generated interface references the
# classes of the model), it makes the dependency cycle api <-> model of the mapped components.
# The script runs the runner class in the copy (-Dtest=ModelRuleRunnerTest, the generation is
# skipped) and stops for it: the run is red (exit code not 0), and the report of the cycle rule
# names the slices of the cycle (the lines after "Cycle detected": the names of the slices api
# and model, and not the order of them).
#
# The script needs JDK 21 (the Maven Wrapper of the module), git and tar (the temporary copy of
# part 3) and the network for the first run (Maven Central). It does not change the repository
# (the build is in target/, it is in .gitignore, and the copy of part 3 is in a temporary
# folder). It stops (exit code 1) if one part does not give the expected result.

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/_lib.sh"

[[ $# -eq 1 ]] || die "Usage: architecture-backend.sh <backend dir>"
backend_dir="$1"
[[ -f "${backend_dir}/pom.xml" ]] || die "${backend_dir}/pom.xml does not exist"
[[ -x "${backend_dir}/mvnw" ]] || die "${backend_dir}/mvnw does not exist or is not executable"

backend_maven_args "${backend_dir}" # the property build.info.commit (the value of the build, Task 200.120; the
# directory is resolved before the cd, so the call is here)
cd "${backend_dir}"

work="$(mktemp -d)"
trap 'rm -rf "${work}"' EXIT

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

echo "== part 1: the run of the derived rules (the case that is successful)"
mvn_run test -Dcodegen.skip=true -Dtest=ModelRuleRunnerTest "${MAVEN_BUILD_ARGS[@]}"
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
        printf '%s\n' "${run_output}" | grep -F "the model gives" | head -n 1 | sed -e 's/^\[INFO\] *//' | sed -e 's/^/     | /' || true
    else
        echo "FAIL the run has not the report of the derived rule count:"
        printf '%s\n' "${run_output}" | grep -E "Tests run|the model gives" | head -n 5 | sed -e 's/^/     | /' || true
        failed=$((failed + 1))
    fi
fi

echo
echo "== part 2: the case that is not successful of the forbidden dependencies (the class BrokenModelRule, ACC-006)"
mvn_run test -Dcodegen.skip=true -Dtest=BrokenModelRule "${MAVEN_BUILD_ARGS[@]}"
if [[ ${run_code} -ne 0 && "${run_output}" == *"BrokenModelRule"* && "${run_output}" == *"Architecture Violation"* \
    && "${run_output}" == *"biz.dfch.specmgrdemo.api.StatusApi.getStatus()"* && "${run_output}" == *"biz.dfch.specmgrdemo.model.Status"* ]]; then
    echo "ok   the run stops for the violated rule, and ArchUnit names the violating dependency"
    passed=$((passed + 1))
    # The report of the run (the line of the violated rule and the dependency that ArchUnit names).
    printf '%s\n' "${run_output}" | grep -E "Architecture Violation|Method <|depending on" | head -n 3 | sed -e 's/^/     | /' || true
else
    echo "FAIL the run of BrokenModelRule gives exit code ${run_code}, and the output has not the violated rule:"
    printf '%s\n' "${run_output}" | grep -E "Tests run|Architecture Violation|depending" | head -n 5 | sed -e 's/^/     | /' || true
    failed=$((failed + 1))
fi

echo
echo "== part 3: the case that is not successful of the cycle rule (ACC-006, a temporary copy of the repository)"
copy_work_tree "${work}/cycle"
scratch_dir="${work}/cycle/backend/src/main/java/biz/dfch/specmgrdemo/model"
mkdir -p "${scratch_dir}"
cat >"${scratch_dir}/ZCycle.java" <<'EOF'
package biz.dfch.specmgrdemo.model;

import biz.dfch.specmgrdemo.api.StatusApi;

/**
 * Scratch class of the case that is not successful of the recipe architecture-backend
 * (feat-50-structurizr-model-rules, Task 140.100, ACC-006): the class lies in the package
 * biz.dfch.specmgrdemo.model (the component model) and references the interface
 * biz.dfch.specmgrdemo.api.StatusApi (the component api), the direction model -> api of the
 * code. With the direction api -> model of the committed code (the generated interface
 * StatusApi references the class Status of the package model), it makes the dependency cycle
 * api <-> model of the mapped components of the container backend. The class exists in the
 * temporary copy only; the repository is never changed.
 */
public final class ZCycle {

  private ZCycle() {
  }

  public StatusApi statusApi() {
    return null;
  }
}
EOF
backend_maven_args "${work}/cycle/backend" # the commit of the copy (the value of the build, Task 200.120)
set +e
run_output="$(cd "${work}/cycle/backend" && ./mvnw --batch-mode --no-transfer-progress test -Dcodegen.skip=true \
    -Dtest=ModelRuleRunnerTest "${MAVEN_BUILD_ARGS[@]}" 2>&1)"
run_code=$?
set -e
# The cycle block of the report (the lines from "Cycle detected" to the first line of the
# dependencies of a slice): the names of the slices of the cycle, without the order.
cycle_block="$(printf '%s\n' "${run_output}" | sed -n '/Cycle detected/,/Dependencies of Slice/p')"
if [[ ${run_code} -ne 0 && "${run_output}" == *"free of cycles"* && -n "${cycle_block}" \
    && "${cycle_block}" == *"Slice api"* && "${cycle_block}" == *"Slice model"* ]]; then
    echo "ok   the run of the copy stops for the cycle, and the report names the slices api and model"
    passed=$((passed + 1))
    printf '%s\n' "${cycle_block}" | head -n 4 | sed -e 's/^\[ERROR\] *//' | sed -e 's/^/     | /' || true
else
    echo "FAIL the run of the copy gives exit code ${run_code}, and the output has not the cycle of the slices api and model:"
    printf '%s\n' "${run_output}" | grep -E "Tests run|Cycle detected|free of cycles" | head -n 5 | sed -e 's/^/     | /' || true
    failed=$((failed + 1))
fi

echo
echo "architecture-backend: ${passed} ok, ${failed} failed"
[[ ${failed} -eq 0 ]]
