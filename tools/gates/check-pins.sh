#!/usr/bin/env bash
# feat-5-foundation-monorepo-ci, Task 130.142 (REQ-003, REQ-015, ACC-013)
#
# Gate: the pins in the workflows.
#   - each `uses:` has a full commit SHA (40 hexadecimal characters) and a comment on the same line
#     with the name of the action and the release tag, and is an action of the license table;
#   - the versions of the tools in the workflow (the inputs of the setup actions) are the same as
#     in tools/versions.env.
#
# Usage: check-pins.sh <versions.env> <workflows-dir> [<allowed-actions>]
#   <allowed-actions> is tools/license/allowed-actions.txt (the default): the actions of the license
#   table with the tag and the SHA.
#
# check_pins.py does the work. It reads the YAML with PyYAML. The version is PYYAML_VERSION in
# tools/versions.env, and `uv run` installs it. Exit codes: 0 pass, 1 a pin is not correct,
# 2 an error in a file.

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/_lib.sh"

[[ $# -eq 2 || $# -eq 3 ]] || die "Usage: check-pins.sh <versions.env> <workflows-dir> [<allowed-actions>]"
allowed="${3:-${REPO_ROOT}/tools/license/allowed-actions.txt}"
require_cmd uv
pyyaml="$(VERSIONS_FILE="$1" version_of PYYAML_VERSION)"
exec uv run --no-project --quiet --with "pyyaml==${pyyaml}" \
    python "${GATES_DIR}/check_pins.py" "$1" "$2" "${allowed}"
