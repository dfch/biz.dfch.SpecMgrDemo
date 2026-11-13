#!/usr/bin/env bash
# feat-7-verification-architecture-tools, Task 130.100 (REQ-003, ACC-002)
#
# The architecture tests of the Maven module with Spring Modulith and ArchUnit (the recipe
# architecture-backend; DEC 9edc1071-4fd0-48b6-a037-1a4cb2331f73: "In the backend, each top-level
# package is a Spring Modulith module and is one component of the model. Spring Modulith examines
# the module boundaries. ArchUnit examines the layers in a module.").
#
# Usage: architecture-backend.sh <backend dir>
#
# Part 1, the cases that are successful: the run of the architecture tests
# (`./mvnw test -Dcodegen.skip=true -Dtest=ModuleStructureTest,LayerRuleTest`, the generation is
# skipped, the generated code is committed, and the gate check-generated compares it with HEAD).
# R1 (Spring Modulith, the class ModuleStructureTest): the top-level packages of the module are
# the modules of the base package biz.dfch.specmgrdemo - exactly api and model, no more, no less,
# and the module structure has no violation. R2 (ArchUnit, the class LayerRuleTest, the layer
# rule of the DEC): the layer model does not depend on the layer api (the direction of the code
# is api -> model). The run is green (exit code 0), and the summary of surefire has no failure
# and no error.
#
# Part 2, the case that is not successful of ArchUnit (ACC-002): the class BrokenLayerRule has
# no suffix Test, so the default run of part 1 does not start it (the committed run is green).
# The rule of the class is the layer rule that the code violates (the api must not depend on the
# model - the opposite direction of R2; the generated interface StatusApi references the classes
# of the model). The script runs the class with -Dtest=BrokenLayerRule and stops for it: the run
# is red (exit code not 0), and ArchUnit names the violating dependency in the report of the run
# (the method getStatus() of the interface StatusApi, with the type argument of the model class
# Status).
#
# Part 3, the case that is not successful of Spring Modulith (ACC-002): the module structure test
# of R1 asserts that the top-level packages of the module are exactly the modules api and model,
# no more, no less, so the committed code cannot violate it without a change of the code. The
# script demonstrates the violation in a temporary copy of the repository (copy_work_tree in
# _lib.sh, the same pattern as the recipe architecture-model; the repository is never changed):
# the copy has a new top-level package (biz.dfch.specmgrdemo.extra, one scratch class in the
# normal source root src/main/java - and not in src/generated, the folder that the generator
# execution of a build without the skip flag would wipe). The script runs the module structure
# test in the copy (-Dtest=ModuleStructureTest, the generation is skipped) and stops for it: the
# run is red (exit code not 0), and the report names the package extra (the AssertionFailedError
# of the test, the expected modules api and model, and the modules of the copy - the list of the
# actual modules has no fixed order, so the script asserts the line of the error, the message of
# the test and the name extra, and not the order of the list).
#
# The script needs JDK 21 (the Maven Wrapper of the module), git and tar (the temporary copy) and
# the network for the first run (Maven Central, the new test tools). It does not change the
# repository (the build is in target/, it is in .gitignore, and the copy of part 3 is in a
# temporary folder). It stops (exit code 1) if one part does not give the expected result.

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/_lib.sh"

[[ $# -eq 1 ]] || die "Usage: architecture-backend.sh <backend dir>"
backend_dir="$1"
[[ -f "${backend_dir}/pom.xml" ]] || die "${backend_dir}/pom.xml does not exist"
[[ -x "${backend_dir}/mvnw" ]] || die "${backend_dir}/mvnw does not exist or is not executable"

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

echo "== the cases that are successful (Spring Modulith R1, ArchUnit R2)"
mvn_run test -Dcodegen.skip=true -Dtest='ModuleStructureTest,LayerRuleTest'
if [[ ${run_code} -ne 0 ]]; then
    echo "FAIL the run of the architecture tests is not green (exit code ${run_code})"
    printf '%s\n' "${run_output}" | tail -n 40 | sed -e 's/^/     | /'
    failed=$((failed + 1))
else
    summary="$(surefire_summary "${run_output}")"
    if [[ -n "${summary}" && "${summary}" == *"Failures: 0"* && "${summary}" == *"Errors: 0"* ]]; then
        total="$(sed -E 's/.*Tests run: ([0-9]+),.*/\1/' <<<"${summary}")"
        echo "ok   the run of the architecture tests is green: ${total} test(s), no failure and no error"
        passed=$((passed + 1))
    else
        echo "FAIL the summary of the run has a failure or an error: ${summary}"
        failed=$((failed + 1))
    fi
    if [[ "${run_output}" == *"ModuleStructureTest"* && "${run_output}" == *"LayerRuleTest"* ]]; then
        echo "ok   the run has the module structure of Spring Modulith (R1) and the layer rule of ArchUnit (R2)"
        passed=$((passed + 1))
    else
        echo "FAIL the run has not the architecture tests of Spring Modulith and of ArchUnit"
        failed=$((failed + 1))
    fi
fi

echo
echo "== the case that is not successful (ACC-002)"
mvn_run test -Dcodegen.skip=true -Dtest=BrokenLayerRule
if [[ ${run_code} -ne 0 && "${run_output}" == *"BrokenLayerRule"* && "${run_output}" == *"Architecture Violation"* \
    && "${run_output}" == *"biz.dfch.specmgrdemo.api.StatusApi.getStatus()"* && "${run_output}" == *"biz.dfch.specmgrdemo.model.Status"* ]]; then
    echo "ok   the run stops for the violated layer rule, and ArchUnit names the violating dependency"
    passed=$((passed + 1))
    # The report of the run (the line of the violated rule and the dependency that ArchUnit names).
    printf '%s\n' "${run_output}" | grep -E "Architecture Violation|Method <|depending on" | head -n 3 | sed -e 's/^/     | /'
else
    echo "FAIL the run of BrokenLayerRule gives exit code ${run_code}, and the output has not the violated rule:"
    printf '%s\n' "${run_output}" | grep -E "Tests run|Architecture Violation|depending" | head -n 5 | sed -e 's/^/     | /'
    failed=$((failed + 1))
fi

echo
echo "== the case that is not successful of Spring Modulith (ACC-002, a temporary copy of the repository)"
copy_work_tree "${work}/copy"
extra_dir="${work}/copy/backend/src/main/java/biz/dfch/specmgrdemo/extra"
mkdir -p "${extra_dir}"
cat >"${extra_dir}/Extra.java" <<'EOF'
package biz.dfch.specmgrdemo.extra;

/**
 * Scratch class of the not-successful case of the recipe architecture-backend (feat-7-verification-architecture-tools,
 * Phase 130, ACC-002): a top-level package that is no module of the committed code, so the module structure test
 * of Spring Modulith (R1) reports the violated structure.
 */
public final class Extra {

  private Extra() {
  }
}
EOF
set +e
run_output="$(cd "${work}/copy/backend" && ./mvnw --batch-mode --no-transfer-progress test -Dcodegen.skip=true \
    -Dtest=ModuleStructureTest 2>&1)"
run_code=$?
set -e
# The line of the report: the AssertionFailedError of the test, with the message of the test and
# the name of the package that the copy adds (extra). The list of the actual modules has no fixed
# order, so the script does not assert on it.
violation_line="$(printf '%s\n' "${run_output}" | grep -F "AssertionFailedError" \
    | grep -F "the top-level packages of the module are the modules of biz.dfch.specmgrdemo" \
    | grep -F "extra" | head -n 1)"
if [[ ${run_code} -ne 0 && -n "${violation_line}" ]]; then
    echo "ok   the run of the copy stops for the violated module structure, and the report names the package extra"
    passed=$((passed + 1))
    printf '%s\n' "${violation_line}" | sed -e 's/^\[ERROR\] *//' | sed -e 's/^/     | /'
else
    echo "FAIL the run of the copy gives exit code ${run_code}, and the output has not the violated module structure:"
    printf '%s\n' "${run_output}" | grep -E "Tests run|AssertionFailedError|the top-level packages" | head -n 5 | sed -e 's/^/     | /'
    failed=$((failed + 1))
fi

echo
echo "architecture-backend: ${passed} ok, ${failed} failed"
[[ ${failed} -eq 0 ]]
