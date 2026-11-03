#!/usr/bin/env bash
# feat-5-foundation-monorepo-ci, Task 130.140 (REQ-009, ACC-003)
#
# Gate: each `run:` step in each workflow is exactly `just <recipe>`, and the recipe is in
# the justfile. There is no list of exceptions.
#
# Usage: check-workflows.sh <justfile> <workflows-dir> [<required-setup>]
#   <required-setup> is tools/gates/required-setup.txt (the default): the jobs of the workflows and the
#   actions that each job must have. The gate also checks the rest of the workflow (the trigger, the
#   permissions, the keys of a job and of a step, `if:`). See check_workflows.py.
#
# check_workflows.py does the work. It reads the YAML with PyYAML. The version and the sha256 value
# (the source archive) are PYYAML_VERSION and PYYAML_SHA256 in tools/versions.env, and the script
# installs it with `uv pip install --require-hashes` (make_python_env in _lib.sh). The script needs
# `just` in the PATH (it starts `just --summary`). Exit codes: 0 pass, 1 a step is not correct, 2 an
# error in a file.

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/_lib.sh"

[[ $# -eq 2 || $# -eq 3 ]] || die "Usage: check-workflows.sh <justfile> <workflows-dir> [<required-setup>]"
required="${3:-${GATES_DIR}/required-setup.txt}"
require_cmd just
make_python_env require "PyYAML:PYYAML_VERSION:PYYAML_SHA256"
"${GATE_PYTHON}" "${GATES_DIR}/check_workflows.py" "$1" "$2" "${required}"
