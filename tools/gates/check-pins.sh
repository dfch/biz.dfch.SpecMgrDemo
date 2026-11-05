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
#   - the lock file of cdxgen (finding G2, feat-16-cdxgen-lockfile): tools/sbom/package.json and
#     tools/sbom/pnpm-lock.yaml must have the CDXGEN_VERSION and the CDXGEN_INTEGRITY of the versions file
#     (the first argument), one dependency only, and an integrity value for each package. A missing folder
#     or file stops the check. The folder is SBOM_TOOL_DIR (a variable for the tests; the default is
#     tools/sbom of this repository, as in sbom.sh, and not of GATE_WORK_ROOT: the tool belongs to the gates).
#
#   - the lock files of the Python tools (finding G2, feat-22-python-tools-lockfile): tools/python/ must have
#     the lock files specmgr.lock, pyyaml.lock and license-expression.lock, each with exact pins and sha256
#     hashes only, and the version of the tool in each file must be the version of the versions file (the
#     first argument). The folder is PYTHON_LOCK_DIR (a variable for the tests, as in make_python_env in
#     _lib.sh; the default is tools/python of this repository).
#
#   - the lock file of Spectral (feat-6-contracts-openapi-pipeline, Task 110.110, REQ-009): tools/spectral/package.json
#     and tools/spectral/pnpm-lock.yaml have the same check as the lock file of cdxgen, with SPECTRAL_VERSION and
#     SPECTRAL_INTEGRITY of the versions file. The folder is LINT_TOOL_DIR (a variable for the tests; the default
#     is tools/spectral of this repository).
#
#   - the download of oasdiff (feat-6-contracts-openapi-pipeline, Task 115.100, REQ-009, ACC-011): OASDIFF_VERSION and
#     OASDIFF_SHA256 of the versions file must be in the right form, and tools/breaking/oasdiff-checksums.txt (the file
#     `checksums.txt` of the release of oasdiff) must have the line for oasdiff_<OASDIFF_VERSION>_linux_amd64.tar.gz with
#     the value of OASDIFF_SHA256. The folder is BREAKING_TOOL_DIR (a variable for the tests; the default is
#     tools/breaking of this repository).
#
# check_pins.py does the work. It reads the YAML with PyYAML. The version is PYYAML_VERSION in the versions
# file (the first argument), and the script installs it with `uv pip install --require-hashes` from the
# lock file tools/python/pyyaml.lock (make_python_env in _lib.sh). Exit codes: 0 pass, 1 a pin is not correct, 2 an error in a file.

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/_lib.sh"

[[ $# -eq 2 || $# -eq 3 ]] || die "Usage: check-pins.sh <versions.env> <workflows-dir> [<allowed-actions>]"
allowed="${3:-${REPO_ROOT}/tools/license/allowed-actions.txt}"
VERSIONS_FILE="$1"
make_python_env pyyaml
"${GATE_PYTHON}" "${GATES_DIR}/check_pins.py" "$1" "$2" "${allowed}" "${WORK_ROOT}" "${SBOM_TOOL_DIR:-${REPO_ROOT}/tools/sbom}" \
    "${PYTHON_LOCK_DIR:-${REPO_ROOT}/tools/python}" "${LINT_TOOL_DIR:-${REPO_ROOT}/tools/spectral}" \
    "${BREAKING_TOOL_DIR:-${REPO_ROOT}/tools/breaking}"
