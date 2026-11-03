#!/usr/bin/env bash
# feat-5-foundation-monorepo-ci, Tasks 130.110 to 130.145
#
# Shared shell helpers for the gate scripts in this folder. Do not run it.
# Source it instead:
#
#   source "$(dirname "${BASH_SOURCE[0]}")/_lib.sh"
#
# The gates do not change the system and need no special rights.

GATES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${GATES_DIR}/../.." && pwd)"
VERSIONS_FILE="${VERSIONS_FILE:-${REPO_ROOT}/tools/versions.env}"
# The folder with the git repository that the gates validate. It is the repository root, and only
# the self-tests (selftest.sh) set another folder (GATE_WORK_ROOT).
WORK_ROOT="${GATE_WORK_ROOT:-${REPO_ROOT}}"

log() { echo "[$(basename "${0}")] $*"; }
die() { echo "[$(basename "${0}")] ERROR: $*" >&2; exit 1; }

# require_cmd <name> -- stop with a clear error if <name> is not on PATH.
require_cmd() {
    command -v "$1" >/dev/null 2>&1 || die "Required command '$1' not found."
}

# version_of <KEY> -- print the value of KEY from tools/versions.env.
# The file has lines `KEY=value` with no quotes. Stop if the key is missing or empty.
version_of() {
    local key="$1" value
    [[ -f "${VERSIONS_FILE}" ]] || die "Version file not found: ${VERSIONS_FILE}"
    value="$(grep -E "^${key}=" "${VERSIONS_FILE}" | head -n 1 | cut -d= -f2-)" || true
    [[ -n "${value}" ]] || die "${key} is not set in ${VERSIONS_FILE}"
    echo "${value}"
}
