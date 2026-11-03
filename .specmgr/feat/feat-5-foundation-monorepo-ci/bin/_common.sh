#!/usr/bin/env bash
# feat-5-foundation-monorepo-ci, Task 110.100
#
# Shared shell helpers for the install scripts in this folder. Not meant to
# be executed directly. Source it instead:
#
#   source "$(dirname "${BASH_SOURCE[0]}")/_common.sh"
#
# The scripts put the tools in the home directory of the user. They need no
# special rights, and they stop if the user is root.

# The repository root is four levels above this folder:
# <root>/.specmgr/feat/<feature>/bin
_COMMON_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${_COMMON_DIR}/../../../.." && pwd)"
VERSIONS_FILE="${REPO_ROOT}/tools/versions.env"

# Where the tools go. A user can set TOOLS_HOME before the scripts run.
TOOLS_HOME="${TOOLS_HOME:-${HOME}/.local/opt/biz.dfch.SpecMgrDemo}"
ENV_FILE="${ENV_FILE:-${HOME}/.config/biz.dfch.SpecMgrDemo/env.sh}"

# Temporary folders that the EXIT trap removes, also after an error.
_CLEANUP_DIRS=()
_cleanup() {
    local dir
    for dir in "${_CLEANUP_DIRS[@]:-}"; do
        if [[ -n "${dir}" ]]; then
            rm -rf "${dir}"
        fi
    done
    return 0
}
trap _cleanup EXIT

log() { echo "[$(basename "${0}")] $*"; }
die() { echo "[$(basename "${0}")] ERROR: $*" >&2; exit 1; }

# refuse_root -- stop if the script runs as root. The tools must belong to
# the user, and the scripts do not change the system.
refuse_root() {
    if [[ "${EUID}" -eq 0 ]]; then
        die "Run this script as a normal user, not as root."
    fi
}

# require_cmd <name> -- stop with a clear error if <name> is not on PATH.
require_cmd() {
    command -v "$1" >/dev/null 2>&1 || die "Required command '$1' not found."
}

# load_versions -- read tools/versions.env (the one source of the versions).
load_versions() {
    [[ -f "${VERSIONS_FILE}" ]] || die "Version file not found: ${VERSIONS_FILE}"
    # shellcheck disable=SC1090
    source "${VERSIONS_FILE}"
}

# require_var <name>... -- stop if a variable from the version file is empty.
require_var() {
    local name
    for name in "$@"; do
        [[ -n "${!name:-}" ]] || die "Variable ${name} is not set in ${VERSIONS_FILE}"
    done
}

# check_sum <algorithm: 256|512> <expected> <file> -- stop if the checksum
# of the file is not the expected value. The expected value is the pin in
# tools/versions.env, never a value from the download server.
check_sum() {
    local algo="$1" expected="$2" file="$3" actual
    actual="$("sha${algo}sum" "${file}" | cut -d' ' -f1)"
    if [[ "${actual}" != "${expected}" ]]; then
        die "sha${algo} of $(basename "${file}") is ${actual}, expected ${expected}. The download is deleted."
    fi
    log "sha${algo} is correct for $(basename "${file}")"
}

# install_archive <name> <version> <url> <algorithm> <expected> <strip> <check-cmd...>
#
# Download an archive, check the checksum, unpack it to
# ${TOOLS_HOME}/<name>-<version>, and make sure that <check-cmd> works.
# If the directory exists and <check-cmd> works, do nothing (can be run again).
# <strip> is the number of leading path parts to remove (0 or 1).
install_archive() {
    local name="$1" version="$2" url="$3" algo="$4" expected="$5" strip="$6"
    shift 6
    local target="${TOOLS_HOME}/${name}-${version}"

    if [[ -d "${target}" ]] && ( cd "${target}" && "$@" >/dev/null 2>&1 ); then
        log "${name} ${version} is already installed in ${target}"
        return 0
    fi

    mkdir -p "${TOOLS_HOME}"
    local work archive
    work="$(mktemp -d "${TOOLS_HOME}/.${name}.XXXXXX")"
    _CLEANUP_DIRS+=("${work}")
    archive="${work}/archive"

    log "Download ${url}"
    curl -fsSL --retry 3 -o "${archive}" "${url}" || die "Download failed: ${url}"
    check_sum "${algo}" "${expected}" "${archive}"

    mkdir -p "${work}/unpacked"
    tar -xf "${archive}" -C "${work}/unpacked" --strip-components="${strip}"

    rm -rf "${target}"
    mv "${work}/unpacked" "${target}"
    log "${name} ${version} is in ${target}"

    ( cd "${target}" && "$@" ) >/dev/null 2>&1 || die "The check '$*' failed for ${name} ${version}"
}
