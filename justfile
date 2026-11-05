# The one entry point for local work and for CI (REQ-002, REQ-009).
# CI jobs start one recipe from this file, and nothing else (ACC-003).
#
# feat-5-foundation-monorepo-ci, Task 120.110.
# The number after the script name is the number of the task that wrote the gate: 130.xxx are the tasks of
# feat-5-foundation-monorepo-ci, 110.115 is the task of feat-6-contracts-openapi-pipeline (the lint gate), and
# 115.110 is the task of feat-6-contracts-openapi-pipeline (the gate for breaking changes), 120.120 and 120.130 are the
# tasks of feat-6-contracts-openapi-pipeline (the generators and the API documentation), and 130.100 and 130.105 are tasks of
# feat-6-contracts-openapi-pipeline too (the gate for generated code, and the tests of the build gates). The gate numbers of
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

# Test: all gates with good and bad input (the license gate, the lint gate, the gate for breaking changes, the generators, the gate for generated code and the build gates with their own tests too).
test-gates: test-license-gate test-lint-gate test-breaking-changes-gate test-generate-gate test-check-generated-gate test-build-gates
    @{{ just_executable() }} _gate selftest.sh 130.145

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
