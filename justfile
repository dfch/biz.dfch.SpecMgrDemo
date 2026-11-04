# The one entry point for local work and for CI (REQ-002, REQ-009).
# CI jobs start one recipe from this file, and nothing else (ACC-003).
#
# feat-5-foundation-monorepo-ci, Task 120.110.
# The number after the script name is the number of the task that wrote the gate: 130.xxx are the tasks of
# feat-5-foundation-monorepo-ci, and 110.115 is the task of feat-6-contracts-openapi-pipeline (the lint gate).
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

# Test: all gates with good and bad input (the license gate and the lint gate with their fixtures too).
test-gates: test-license-gate test-lint-gate
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
