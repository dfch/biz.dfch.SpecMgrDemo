# The one entry point for local work and for CI (REQ-002, REQ-009).
# CI jobs start one recipe from this file, and nothing else (ACC-003).
#
# feat-5-foundation-monorepo-ci, Task 120.110.
# The number after the script name is the number of the task that wrote the gate: 130.xxx are the tasks of
# feat-5-foundation-monorepo-ci, 110.115 is the task of feat-6-contracts-openapi-pipeline (the lint gate), and
# 115.110 is the task of feat-6-contracts-openapi-pipeline (the gate for breaking changes), 120.120 and 120.130 are the
# tasks of feat-6-contracts-openapi-pipeline (the generators and the API documentation), and 130.100 and 130.105 are tasks of
# feat-6-contracts-openapi-pipeline too (the gate for generated code, and the tests of the build gates). 110.100 to 110.130
# are the tasks of feat-7-verification-architecture-tools (the test tools, the recipes test-unit-backend,
# test-integration-backend, test-unit-frontend, test-e2e, test-random-backend and test-random-frontend),
# 120.100 and 120.110 are the tasks of feat-7-verification-architecture-tools (the mutation tests, the recipes
# mutation-backend and mutation-frontend), 130.100 to 130.120 are the tasks of
# feat-7-verification-architecture-tools (the architecture tools, the recipes architecture-backend,
# architecture-frontend and architecture-model), and 140.110 is the task of
# feat-7-verification-architecture-tools (the coverage, the recipes coverage-backend and
# coverage-frontend), and 110.130 and 110.150 are the tasks of feat-8-traceability-security-gates (Gate 2, the
# traceability check: the recipes traceability and test-traceability-gate), and 120.110 to 120.130 are the tasks of
# feat-8-traceability-security-gates (Gate 9, the security recipes vuln-scan, secret-scan and workflow-scan, and
# their test test-security-gates). The gate numbers of
# the scripts of feat-5-foundation-monorepo-ci and of feat-6-contracts-openapi-pipeline can be the same (130.xxx): the script
# name tells them apart.
# The gate scripts are in tools/gates/ (Phase 130). If a script does not
# exist, its recipe stops with an error and a message. A recipe never passes
# because a script is missing.

set shell := ["bash", "-euo", "pipefail", "-c"]

# The folder for the SBOM files (ACC-010). The folder is not in git.
sbom_dir := "build/sbom"

# The branch that the gates compare with: the branch that a pull request goes to. In GitHub Actions,
# GITHUB_BASE_REF (a default variable of the runner, set for a pull request only) is that branch,
# so a pull request to `main` is compared with origin/main and a pull request to `dev` with origin/dev.
# GITHUB_BASE_REF is empty for other events, and it is not set on a developer machine: then the base
# is origin/dev. A developer can set it for a test (for example GITHUB_BASE_REF=main just commit-check).
base := if env("GITHUB_BASE_REF", "") == "" { "origin/dev" } else { "origin/" + env("GITHUB_BASE_REF") }

# Show the recipes.
default:
    @{{ just_executable() }} --list

# Gate: specmgr validation of the documents that changed since the base.
validate:
    @{{ just_executable() }} _gate validate-docs.sh 130.110 "{{ base }}"

# Gate: Conventional Commits with the feature number as scope, for each commit since the base.
commit-check:
    @{{ just_executable() }} _gate commit-check.sh 130.120 "{{ base }}"

# Check the subject line of the commit in progress with the same rule as the `commit-check` gate (Conventional Commits with the feature number as scope). The commit-msg hook in tools/hooks calls this recipe; the rule is in the gate script, not in the hook (feat-48-pre-commit-hooks, Task 110.110). The subject may contain any character (spaces, brackets, double quotes, command substitution), so the parameter is exported ($subject) and the line passes the double-quoted variable "$subject" to the shell, which expands it without reinterpreting its value; it is not part of the unquoted variadic of the private recipe _gate.
commit-message-check $subject:
    @[[ -x "tools/gates/commit-check.sh" ]] || { echo "NOT IMPLEMENTED: tools/gates/commit-check.sh does not exist. The task 130.120 of feat-5-foundation-monorepo-ci writes it." >&2; exit 1; }
    @exec "tools/gates/commit-check.sh" --message "$subject"

# Make the SBOM files (CycloneDX) for the backend and the frontend.
sbom:
    @{{ just_executable() }} _gate sbom.sh 130.130 "{{ sbom_dir }}"

# Gate: compare the licenses in the SBOM files with the list of permitted licenses.
license-check: sbom
    @{{ just_executable() }} _gate license-check.sh 130.130 "{{ sbom_dir }}" tools/license/permitted-licenses.txt

# Gate: each `run:` step in a workflow is `just <recipe>` with a recipe in this file.
check-workflows:
    @{{ just_executable() }} _gate check-workflows.sh 130.140 justfile .github/workflows

# Gate: each `uses:` step has a full commit SHA and a comment, and the versions are those of tools/versions.env.
check-pins:
    @{{ just_executable() }} _gate check-pins.sh 130.142 tools/versions.env .github/workflows tools/license/allowed-actions.txt

# Gate: no script of the project uses sudo.
check-sudo:
    @{{ just_executable() }} _gate check-sudo.sh 130.145 justfile tools .specmgr/feat .github

# Test: the license gate with the fixtures in tools/license/fixtures/ (ACC-009).
test-license-gate:
    @{{ just_executable() }} _gate test-license-gate.sh 130.135

# Gate: the linter Spectral examines contracts/openapi.yaml with the rules in tools/lint/ruleset.yaml (REQ-002, REQ-006, REQ-008).
lint:
    @{{ just_executable() }} _gate lint.sh 110.115 contracts/openapi.yaml tools/lint/ruleset.yaml

# Test: the lint gate with the real Spectral and the bad OpenAPI files in tools/lint/fixtures/ (ACC-007).
test-lint-gate:
    @{{ just_executable() }} _gate test-lint-gate.sh 110.115

# Gate: oasdiff compares contracts/openapi.yaml with the file at the merge base of the base (a pull request to `dev`: dev, a release pull request to `main`: main). A breaking change needs an entry in the ignore file and a higher version (REQ-003, REQ-012, DEC 93594b2b-be54-4f60-9f53-ec2ce6c84be4).
breaking-changes:
    @{{ just_executable() }} _gate breaking-changes.sh 115.110 "{{ base }}" contracts/openapi.yaml tools/breaking/breaking-changes-ignore.txt

# Test: the gate for breaking changes with the real oasdiff and temporary git repositories: the four cases of ACC-003 and more.
test-breaking-changes-gate:
    @{{ just_executable() }} _gate test-breaking-changes-gate.sh 115.130

# Make all generated code again from contracts/openapi.yaml: the Spring server interfaces in backend/src/generated and the Zod schemas in frontend/src/generated. Two runs one after the other make no change (REQ-004, REQ-011).
generate:
    @{{ just_executable() }} _gate generate.sh 120.120 backend frontend

# Compile the Maven module and the pnpm module with the generated code (./mvnw compile, and tsc --noEmit --strict). The generation is part of the Maven build (ACC-005).
compile:
    @{{ just_executable() }} _gate compile.sh 120.120 backend frontend

# Make the API documentation (HTML) from contracts/openapi.yaml with the generator html2 of the pinned plugin. The output is in build/api-docs and is not in git (REQ-015).
api-docs:
    @{{ just_executable() }} _gate api-docs.sh 120.130 backend build/api-docs

# Gate: the generated code in the repository (backend/src/generated, frontend/src/generated) is the code that `just generate` makes now. It finds a file that is changed, deleted, extra, not tracked or ignored, and a missing mark "generated, do not change". It compares with HEAD (REQ-001, REQ-005).
check-generated:
    @{{ just_executable() }} _gate check-generated.sh 130.100 backend frontend

# Test: the gate for generated code with the real generators and a temporary git repository: the four cases of ACC-004 (a change by hand, a change of the OpenAPI file with no new generation, a deleted file, an extra file) and more.
test-check-generated-gate:
    @{{ just_executable() }} _gate test-check-generated-gate.sh 130.100

# Test: the gates `compile` and `api-docs` with bad input (a compile error, a type error, an OpenAPI file that the generator cannot read) in a temporary git repository.
test-build-gates:
    @{{ just_executable() }} _gate test-build-gates.sh 130.105

# Test: the generators. Two runs of `just generate` make no change, the lists of error codes in the YAML file, in the Java enum and in the Zod schema are the same, and two runs of `just api-docs` make the same HTML (ACC-008, ACC-013, ACC-018).
test-generate-gate:
    @{{ just_executable() }} _gate test-generate-gate.sh 120.120

# Test: all gates with good and bad input (the license gate, the lint gate, the gate for breaking changes, the generators, the gate for generated code, the build gates, the traceability check and the security recipes with their own tests too).
test-gates: test-license-gate test-lint-gate test-breaking-changes-gate test-generate-gate test-check-generated-gate test-build-gates test-traceability-gate test-security-gates
    @{{ just_executable() }} _gate selftest.sh 130.145

# Test: the unit tests of the Maven module with JUnit, and a test that is not successful (feat-7-verification-architecture-tools, Task 110.100).
test-unit-backend:
    @{{ just_executable() }} _gate test-unit-backend.sh 110.100 backend

# Test: the integration tests of the Maven module with Testcontainers (one container), and a test that is not successful (feat-7-verification-architecture-tools, Task 110.100).
test-integration-backend:
    @{{ just_executable() }} _gate test-integration-backend.sh 110.100 backend

# Test: the unit tests of the pnpm module with Vitest, and a test that is not successful (feat-7-verification-architecture-tools, Task 110.110).
test-unit-frontend:
    @{{ just_executable() }} _gate test-unit-frontend.sh 110.110 frontend

# Test: the end-to-end tests with Playwright and the accessibility check of axe-core, and a test that is not successful (feat-7-verification-architecture-tools, Task 110.120).
test-e2e:
    @{{ just_executable() }} _gate test-e2e.sh 110.120 frontend

# Test: the property tests of the Maven module with jqwik: one that is successful, and one that is not successful (feat-7-verification-architecture-tools, Task 110.130).
test-random-backend:
    @{{ just_executable() }} _gate test-random-backend.sh 110.130 backend

# Test: the property tests of the pnpm module with fast-check: one that is successful, and one that is not successful (feat-7-verification-architecture-tools, Task 110.130).
test-random-frontend:
    @{{ just_executable() }} _gate test-random-frontend.sh 110.130 frontend

# Test: the mutation tests of the Maven module with PIT: the run makes the report (HTML and XML in target/pit-reports), and the report has a surviving mutant (feat-7-verification-architecture-tools, Task 120.100).
mutation-backend:
    @{{ just_executable() }} _gate mutation-backend.sh 120.100 backend

# Test: the mutation tests of the pnpm module with Stryker: the run makes the report (HTML and JSON in mutation-report/), and the report has a surviving mutant (feat-7-verification-architecture-tools, Task 120.110).
mutation-frontend:
    @{{ just_executable() }} _gate mutation-frontend.sh 120.110 frontend

# Test: the architecture tests of the Maven module with Spring Modulith (R1, the module structure) and ArchUnit (R2, the layer rule): the run is green, and the violated rule is run separately and named in the report (feat-7-verification-architecture-tools, Task 130.100).
architecture-backend:
    @{{ just_executable() }} _gate architecture-backend.sh 130.100 backend

# Test: the architecture tests of the pnpm module with ArchUniTS (the layers and the imports of the frontend): the run of the rules is green, and the violated rule is run separately and named in the report (feat-7-verification-architecture-tools, Task 130.110).
architecture-frontend:
    @{{ just_executable() }} _gate architecture-frontend.sh 130.110 frontend

# Test: the test that compares the Structurizr workspace with the modules, the packages and the dependencies: the committed workspace matches the code (the run is green), and the two conditions of ACC-003 are demonstrated in a temporary copy of the repository (a package without a component, a dependency not in the model). The frontend side also has the cases for the key `properties` of an element (a map of texts is accepted, each other value stops the comparison) (feat-7-verification-architecture-tools, Task 130.120; feat-8-traceability-security-gates).
architecture-model:
    @{{ just_executable() }} _gate architecture-model.sh 130.120 backend frontend

# Report: the coverage of the Maven module with JaCoCo (the line and the branch coverage, the report in target/site/jacoco, the numbers on the console; no threshold, the walking skeleton sets it from the measured baseline) (feat-7-verification-architecture-tools, Task 140.110).
coverage-backend:
    @{{ just_executable() }} _gate coverage-backend.sh 140.110 backend

# Report: the coverage of the pnpm module with the provider v8 of Vitest (the line coverage, the report in coverage/, the numbers on the console; no threshold, the walking skeleton sets it from the measured baseline) (feat-7-verification-architecture-tools, Task 140.110).
coverage-frontend:
    @{{ just_executable() }} _gate coverage-frontend.sh 140.110 frontend

# Gate: the traceability check (DEC f21920d2-4da5-4cf7-bd94-2e9bcba77342). It stops (error) for a reference in docs/ and .specmgr/ that has no target, for an `x-specmgr-req` in contracts/openapi.yaml that is not the id of a REQ, for an id in `specmgr-req` of model/workspace.json or `vcr:<uuid>` in a test that has no document, for an approved REQ with no VCR, and for a test file of backend/ or frontend/ outside the folders that the check reads (TEST_ROOTS). It gives a warning (no stop) for an approved REQ with no element in the model, or whose VCR is not in the name of a test (feat-8-traceability-security-gates, Task 110.130).
traceability:
    @{{ just_executable() }} _gate traceability.sh 110.130 .

# Test: the traceability check with the fixtures in tools/gates/fixtures/traceability/: each error (ACC-002), the two warnings (ACC-003), the case that is successful, and a reader of references with another form (ACC-004) (feat-8-traceability-security-gates, Task 110.150).
test-traceability-gate:
    @{{ just_executable() }} _gate test-traceability-gate.sh 110.150

# Report: the known vulnerabilities in the dependencies (Gate 9, DEC 361678a6-f941-473b-a058-1ba2bacf7d3d). OSV-Scanner reads the SBOM files of `just sbom` (build/sbom/*.cdx.json) and asks api.osv.dev (the network is needed). A finding is part of the report and does not stop the recipe (exit code 0, no threshold, REQ-005). A failure of the tool (no network, a file that cannot be read, a missing binary, a wrong checksum) stops it (exit code 1). The data of OSV has a deviation in DEC 93a6d588-e002-4daf-9a47-45e2d77786e9 (feat-8-traceability-security-gates, Task 120.110).
vuln-scan: sbom
    @{{ just_executable() }} _gate vuln-scan.sh 120.110 "{{ sbom_dir }}"

# Report: secrets in the files and in the history of the pull request (the commits in <base>..HEAD), with gitleaks (Gate 9, DEC 361678a6-f941-473b-a058-1ba2bacf7d3d). The allowlist is tools/security/gitleaks.toml (CODEOWNERS covers it). A finding is part of the report and does not stop the recipe (exit code 0, no threshold, REQ-005). A failure of the tool (a wrong config, a base that does not exist, a shallow clone with no merge base, a wrong checksum) stops it (exit code 1) (feat-8-traceability-security-gates, Task 120.120).
secret-scan:
    @{{ just_executable() }} _gate secret-scan.sh 120.120 "{{ base }}" tools/security/gitleaks.toml

# Report: the workflow files with zizmor, offline (Gate 9, DEC 361678a6-f941-473b-a058-1ba2bacf7d3d). A finding is part of the report and does not stop the recipe (exit code 0, no threshold, REQ-005). A failure of the tool (a file that cannot be read, no input) stops it (exit code 1) (feat-8-traceability-security-gates, Task 120.130).
workflow-scan:
    @{{ just_executable() }} _gate workflow-scan.sh 120.130 .github/workflows

# Test: the three security recipes and the function that separates a finding from a failure of the tool (ACC-005): each tool with a finding (exit code 0) and with a failure (exit code that is not 0), with stubs of the tool and of the network, and with the real gitleaks, zizmor and OSV-Scanner (feat-8-traceability-security-gates, Tasks 120.100 to 120.130).
test-security-gates:
    @{{ just_executable() }} _gate test-security-gates.sh 120.100

# Test: the git hooks of tools/hooks/ with the real gates in a temporary git repository (the nine cases: the seven of the plan plus the two of the post-implementation review) (feat-48-pre-commit-hooks, Task 130.110).
test-hooks:
    @{{ just_executable() }} _gate test-hooks.sh 130.110

# Check the install on this machine: each tool has the pinned version.
verify-tools:
    .specmgr/feat/feat-5-foundation-monorepo-ci/bin/110.110-06-verify-tools.sh

# Install the git hooks on this machine: set core.hooksPath to tools/hooks, so that git runs the hooks of the folder before a commit and before a push. The install is opt-in (CI does not call the recipe) and idempotent (a second run changes nothing). Uninstall: git config --unset core.hooksPath (feat-48-pre-commit-hooks, Task 100.100).
install-hooks:
    git config core.hooksPath tools/hooks

# Start a gate script from tools/gates/. Stop if the script does not exist.
[private]
_gate script task *args:
    #!/usr/bin/env bash
    set -euo pipefail
    path="tools/gates/{{ script }}"
    if [[ ! -x "${path}" ]]; then
        echo "NOT IMPLEMENTED: ${path} does not exist. The task {{ task }} of the plan of the feature that added this recipe writes it." >&2
        exit 1
    fi
    exec "${path}" {{ args }}
