#!/usr/bin/env bash
# feat-5-foundation-monorepo-ci, Task 130.140 (REQ-009, ACC-003)
#
# Gate: each `run:` step in each workflow is exactly `just <recipe>`, and the recipe is in
# the justfile. There is no list of exceptions.
#
# Usage: check-workflows.sh <justfile> <workflows-dir>
#
# check_workflows.py does the work. It reads the YAML with PyYAML. The version is
# PYYAML_VERSION in tools/versions.env, and `uv run` installs it. The script needs `just` in
# the PATH (it starts `just --summary`). Exit codes: 0 pass, 1 a step is not correct, 2 an
# error in a file.

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/_lib.sh"

[[ $# -eq 2 ]] || die "Usage: check-workflows.sh <justfile> <workflows-dir>"
require_cmd uv
require_cmd just
pyyaml="$(version_of PYYAML_VERSION)"
exec uv run --no-project --quiet --with "pyyaml==${pyyaml}" \
    python "${GATES_DIR}/check_workflows.py" "$1" "$2"
