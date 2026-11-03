# The one entry point for local work and for CI (REQ-002, REQ-009).
# CI jobs start one recipe from this file, and nothing else (ACC-003).
#
# feat-5-foundation-monorepo-ci, Task 120.110.
# The gate scripts are in tools/gates/. Phase 130 writes them. Until a
# script exists, its recipe stops with an error and a message. A recipe
# never passes because a script is missing.

set shell := ["bash", "-euo", "pipefail", "-c"]

# The folder for the SBOM files (ACC-010). The folder is not in git.
sbom_dir := "build/sbom"

# The branch that a pull request goes to. The gates compare with it.
base := "origin/dev"

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
    @{{ just_executable() }} _gate check-pins.sh 130.142 tools/versions.env .github/workflows

# Gate: no script of the project uses sudo.
check-sudo:
    @{{ just_executable() }} _gate check-sudo.sh 130.145 tools .specmgr/feat

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
        echo "NOT IMPLEMENTED: ${path} does not exist. Task {{ task }} of feat-5-foundation-monorepo-ci writes it." >&2
        exit 1
    fi
    exec "${path}" {{ args }}
