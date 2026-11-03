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
#   - the Maven pin (finding G1): a Maven Wrapper (`.mvn/wrapper/maven-wrapper.properties`) must have a
#     distributionUrl with the MAVEN_VERSION of tools/versions.env and a distributionSha256Sum, and a
#     project with a pom.xml must have a wrapper. No pom.xml and no wrapper: "no Maven project".
#     The folder for the search is GATE_WORK_ROOT (the default is the repository root).
#
# check_pins.py does the work. It reads the YAML with PyYAML. The version and the sha256 value
# (the source archive) are PYYAML_VERSION and PYYAML_SHA256 in the versions file (the first
# argument), and the script installs it with `uv pip install --require-hashes` (make_python_env in
# _lib.sh). Exit codes: 0 pass, 1 a pin is not correct, 2 an error in a file.

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/_lib.sh"

[[ $# -eq 2 || $# -eq 3 ]] || die "Usage: check-pins.sh <versions.env> <workflows-dir> [<allowed-actions>]"
allowed="${3:-${REPO_ROOT}/tools/license/allowed-actions.txt}"
VERSIONS_FILE="$1"
make_python_env require "PyYAML:PYYAML_VERSION:PYYAML_SHA256"
"${GATE_PYTHON}" "${GATES_DIR}/check_pins.py" "$1" "$2" "${allowed}" "${WORK_ROOT}"
