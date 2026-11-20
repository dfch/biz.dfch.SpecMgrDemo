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
# architecture-frontend and architecture-model), 130.110 to 130.130 are the tasks of
# feat-50-structurizr-model-rules (the rule set and the runner: the same three recipes, rewritten to run
# the rules derived from the model), 140.100 and 140.110 are the tasks of
# feat-50-structurizr-model-rules (the tests of the tests: the same two recipes architecture-backend and
# architecture-frontend, rewritten to the three-part form with the cases that are not successful of each
# rule category, the Broken* pattern), and 140.110 is the task of
# feat-7-verification-architecture-tools (the coverage, the recipes coverage-backend and
# coverage-frontend), and 110.130 and 110.150 are the tasks of feat-8-traceability-security-gates (Gate 2, the
# traceability check: the recipes traceability and test-traceability-gate, rewritten by 150.100 of
# feat-50-structurizr-model-rules for the property specmgr-refs of the model, and the old property specmgr-req
# that keeps working for one release, 150.110), and 120.110 to 120.130 are the tasks of
# feat-8-traceability-security-gates (Gate 9, the security recipes vuln-scan, secret-scan and workflow-scan, and
# their test test-security-gates), and 110.110 and 110.120 are the tasks of feat-50-structurizr-model-rules (the
# model in DSL: the recipe generate-model, and the gate for the generated model with its test, the recipes
# check-model-generated and test-check-model-generated-gate). The gate numbers of
# the scripts of the features can be the same (130.xxx, 110.xxx): the script
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

# Compile the Maven module and the pnpm module with the generated code (./mvnw compile, tsc --noEmit --strict, and the build of the browser bundle with vite build into a temporary folder). The generation is part of the Maven build (ACC-005).
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
test-gates: test-license-gate test-lint-gate test-breaking-changes-gate test-generate-gate test-check-generated-gate test-build-gates test-traceability-gate test-security-gates test-check-model-generated-gate
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

# Test: the rules the model gives (the container backend, derived from model/workspace.json at test time, with ArchUnit; one dynamic test per derived rule: the forbidden dependencies and the cycle rule, the rule set in model/README.md): part 1 the run is green on the committed code; part 2 the case that is not successful of the forbidden dependencies (the class BrokenModelRule: the modelled relation api -> model forbidden, the violation named); part 3 the case that is not successful of the cycle rule (a temporary copy of the repository: the scratch class makes the cycle api <-> model, the slices named) (feat-50-structurizr-model-rules, Task 140.100; the runner of Task 130.110).
architecture-backend:
    @{{ just_executable() }} _gate architecture-backend.sh 140.100 backend

# Test: the rules the model gives (the container frontend, derived from model/workspace.json at run time, with ArchUniTS; one check per derived rule: the forbidden dependencies, 10 today, and the cycle rule, the rule set in model/README.md): part 1 the run is green on the committed code; part 2 the case that is not successful of the forbidden dependencies (the script runner.broken.mjs: the modelled relations test -> zod and test -> root forbidden, the imports named); part 3 the case that is not successful of the cycle rule (a temporary copy of the repository: the two scratch files make the cycle types <-> test, the edges named) (feat-50-structurizr-model-rules, Task 140.110; the runner of Task 130.120).
architecture-frontend:
    @{{ just_executable() }} _gate architecture-frontend.sh 140.110 frontend

# Test: the test that compares the Structurizr workspace with the packages and the dependencies of the code (the mapping code.* of the elements, not the name; the rule set in model/README.md): the committed workspace matches the code (the run is green), and the two conditions of ACC-003 are demonstrated in a temporary copy of the repository (a package or a unit without a component, a dependency not in the model). The frontend side also has the cases for the key `properties` of an element (a map of texts is accepted, each other value stops the comparison), and the cases for the entry code.ignore of the container (a file directly in src/generated without a unit: without an entry the rule of thumb stops, with an entry that names it the comparison is green and the PASS line names the ignored count) (feat-50-structurizr-model-rules, Task 130.130; feat-7-verification-architecture-tools, Task 130.120; feat-8-traceability-security-gates).
architecture-model:
    @{{ just_executable() }} _gate architecture-model.sh 130.130 backend frontend

# Make model/workspace.json again from model/workspace.dsl with the pinned container structurizr/structurizr (the step names the digest STRUCTURIZR_IMAGE_DIGEST of tools/versions.env, and not the tag). Two runs make no change (feat-50-structurizr-model-rules, Task 110.110; DEC b6e8808f-86b4-41a4-92f2-33d38869beed).
generate-model:
    @{{ just_executable() }} _gate generate-model.sh 110.110 model

# Gate: the JSON of the model is the JSON that the pinned container makes from the DSL now (like check-generated): it validates the DSL (a DSL that does not parse stops the gate, the error names the line), it makes the JSON again twice in a temporary folder (two runs make no change), it stops if the result differs from model/workspace.json (the committed file), and it stops if the committed file carries another value for the top-level property structurizr.inspection.error than the recorded value 14 (the count of the inspection, the stable consequence of the limit of the pinned exporter for the deployment content; the record is in model/README.md and in the Updates entry of the DEC) (feat-50-structurizr-model-rules, Task 110.120; DEC b6e8808f-86b4-41a4-92f2-33d38869beed).
check-model-generated:
    @{{ just_executable() }} _gate check-model-generated.sh 110.120 model

# Test: the gate for the generated model with the fixtures: the good case (pass), the changed-JSON case (stop, the message names the difference), the stale-JSON case (stop), the broken-DSL case (stop, the line named), the pin case, and the usage (feat-50-structurizr-model-rules, Task 110.120).
test-check-model-generated-gate:
    @{{ just_executable() }} _gate test-check-model-generated-gate.sh 110.120

# Report: the coverage of the Maven module with JaCoCo (the line and the branch coverage, the report in target/site/jacoco, the numbers on the console; no threshold, the walking skeleton sets it from the measured baseline) (feat-7-verification-architecture-tools, Task 140.110).
coverage-backend:
    @{{ just_executable() }} _gate coverage-backend.sh 140.110 backend

# Report: the coverage of the pnpm module with the provider v8 of Vitest (the line coverage, the report in coverage/, the numbers on the console; no threshold, the walking skeleton sets it from the measured baseline) (feat-7-verification-architecture-tools, Task 140.110).
coverage-frontend:
    @{{ just_executable() }} _gate coverage-frontend.sh 140.110 frontend

# Gate: the traceability check (DEC f21920d2-4da5-4cf7-bd94-2e9bcba77342). It stops (error) for a reference in docs/ and .specmgr/ that has no target, for an `x-specmgr-req` in contracts/openapi.yaml that is not the id of a REQ, for an id in `specmgr-req` of model/workspace.json (the old form), for an entry of `specmgr-refs` of model/workspace.json (the new form TYPE UUID; TYPE UUID, DEC e85e9685-0787-4dff-9ee5-9d46670e9ee4: the form, the type, the document of the type) or `vcr:<uuid>` in a test that has no document, for an approved REQ with no VCR, and for a test file of backend/ or frontend/ outside the folders that the check reads (TEST_ROOTS). It gives a warning (no stop) for an approved REQ with no element in the model (in `specmgr-req`, or in an entry of the type REQ of `specmgr-refs`: the check reads the two forms independently and counts the REQ identifiers of the element in the two forms), or whose VCR is not in the name of a test. The old form `specmgr-req` keeps working for one release (the compatibility) (feat-8-traceability-security-gates, Task 110.130; feat-50-structurizr-model-rules, Task 150.100 and 150.110).
traceability:
    @{{ just_executable() }} _gate traceability.sh 150.100 .

# Test: the traceability check with the fixtures in tools/gates/fixtures/traceability/: each error (ACC-002), the two warnings (ACC-003), the case that is successful, a reader of references with another form (ACC-004), and the property `specmgr-refs` of the model (the form TYPE UUID; TYPE UUID: the case that is successful with the several types, the entry that has no document of its type, the broken form, the type that is no document type, and the element that has the two forms; the fixtures of the old form `specmgr-req` stay unchanged and green with the same assertions, the compatibility, feat-50 Task 150.100 and 150.110) (feat-8-traceability-security-gates, Task 110.150).
test-traceability-gate:
    @{{ just_executable() }} _gate test-traceability-gate.sh 150.100

# Gate: the known vulnerabilities in the dependencies (Gate 9, DEC 361678a6-f941-473b-a058-1ba2bacf7d3d). OSV-Scanner reads the SBOM files of `just sbom` (build/sbom/*.cdx.json) and asks api.osv.dev (the network is needed). The level gate compares the findings with the baseline tools/security/osv-baseline.txt (the OSV identifier and the package, no report text, DEC 93a6d588-e002-4daf-9a47-45e2d77786e9): a finding that is Critical or High stops in each case (exit code 1), a finding that is not in the baseline stops (exit code 1), and a line of the baseline that has no finding any more is a warning (exit code 0). A failure of the tool (no network, a file that cannot be read, a missing binary, a wrong checksum) stops it (exit code 1) (feat-8-traceability-security-gates, Task 120.110; feat-9-walking-skeleton, Task 500.120).
vuln-scan: sbom
    @{{ just_executable() }} _gate vuln-scan.sh 500.120 "{{ sbom_dir }}" tools/security/osv-baseline.txt

# Gate: secrets in the files and in the history of the pull request (the commits in <base>..HEAD), with gitleaks (Gate 9, DEC 361678a6-f941-473b-a058-1ba2bacf7d3d). The allowlist is tools/security/gitleaks.toml (CODEOWNERS covers it). gitleaks gives no severity, so the level gate uses the baseline tools/security/gitleaks-baseline.txt (the fingerprints) as the only rule: a finding that is not in the baseline stops (exit code 1), a line of the baseline that has no finding any more is a warning (exit code 0). A failure of the tool (a wrong config, a base that does not exist, a shallow clone with no merge base, a wrong checksum) stops it (exit code 1) (feat-8-traceability-security-gates, Task 120.120; feat-9-walking-skeleton, Task 500.120).
secret-scan:
    @{{ just_executable() }} _gate secret-scan.sh 500.120 "{{ base }}" tools/security/gitleaks.toml tools/security/gitleaks-baseline.txt

# Gate: the workflow files with zizmor, offline (Gate 9, DEC 361678a6-f941-473b-a058-1ba2bacf7d3d). The level gate compares the findings with the baseline tools/security/zizmor-baseline.txt (the audit, the file and the place in the file): a finding with the severity High stops in each case (exit code 1), a finding that is not in the baseline stops (exit code 1), and a line of the baseline that has no finding any more is a warning (exit code 0). A failure of the tool (a file that cannot be read, no input) stops it (exit code 1) (feat-8-traceability-security-gates, Task 120.130; feat-9-walking-skeleton, Task 500.120).
workflow-scan:
    @{{ just_executable() }} _gate workflow-scan.sh 500.120 tools/security/zizmor-baseline.txt .github/workflows

# Test: the three security recipes, the function that separates a finding from a failure of the tool (feat-8 ACC-005) and the level gate with the baseline files (feat-9 ACC-007): each tool with no finding, with a finding of the baseline (exit code 0), with a new finding, with a finding that is Critical or High and with a failure of the tool (exit code 1), and the old line of a baseline (a warning), with stubs of the tool and of the network, and with the real gitleaks, zizmor and OSV-Scanner (feat-8-traceability-security-gates, Tasks 120.100 to 120.130; feat-9-walking-skeleton, Task 500.120).
test-security-gates:
    @{{ just_executable() }} _gate test-security-gates.sh 120.100

# Check the install on this machine: each tool has the pinned version.
verify-tools:
    .specmgr/feat/feat-5-foundation-monorepo-ci/bin/110.110-06-verify-tools.sh

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
