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

# make_python_env <require|verify> <name:VERSION_KEY:SHA256_KEY>...
#
# Makes a temporary virtual environment for a Python tool of a gate, and installs the packages in
# it with the checksums of tools/versions.env (feat-5, finding G2). It writes one requirement line
# for each package from the file, `name==<version> --hash=sha256:<value>`, so that versions.env stays
# the one source. Then it starts `uv pip install` with --require-hashes (mode `require`) or with
# --verify-hashes (mode `verify`):
#
#   require  Each package that uv installs must have a hash in the file. Use it for a tool with no
#            other dependency than the packages in the list (license-expression with boolean.py,
#            PyYAML). uv stops for a hash that is wrong, and for a package that has no hash.
#   verify   uv checks the hash of each package that has one in the file, and does not check the
#            other packages. Use it for a tool with dependencies that the file does not list
#            (specmgr). The dependencies of the tool are NOT verified.
#
# uv chooses the file of a release that has the hash. So a hash of a wheel gives the wheel, and the
# hash of a source archive (PyYAML) gives the source archive, which uv builds. The build tools of
# that build are not verified.
#
# Sets GATE_ENV_DIR (the temporary folder; the variable GATE_PYTHON is the Python of the
# environment) and removes the folder when the script ends. A key of tools/versions.env that is
# missing, or a value that has not the form of a version or of a sha256, stops the script.
make_python_env() {
    local mode="$1" spec name version_key sha_key version sha
    shift
    [[ "${mode}" == "require" || "${mode}" == "verify" ]] || die "make_python_env: mode must be require or verify"
    require_cmd uv
    GATE_ENV_DIR="$(mktemp -d)"
    trap 'rm -rf "${GATE_ENV_DIR}"' EXIT
    : >"${GATE_ENV_DIR}/requirements.txt"
    for spec in "$@"; do
        IFS=: read -r name version_key sha_key <<<"${spec}"
        version="$(version_of "${version_key}")"
        sha="$(version_of "${sha_key}")"
        [[ "${version}" =~ ^[0-9A-Za-z.+_-]+$ ]] || die "${version_key} is not a version: '${version}'"
        [[ "${sha}" =~ ^[0-9a-f]{64}$ ]] || die "${sha_key} is not a sha256 value (64 hexadecimal characters): '${sha}'"
        printf '%s==%s --hash=sha256:%s\n' "${name}" "${version}" "${sha}" >>"${GATE_ENV_DIR}/requirements.txt"
    done
    uv venv --quiet "${GATE_ENV_DIR}/venv" || die "uv could not make a virtual environment"
    GATE_PYTHON="${GATE_ENV_DIR}/venv/bin/python"
    uv pip install --quiet --python "${GATE_PYTHON}" "--${mode}-hashes" -r "${GATE_ENV_DIR}/requirements.txt" \
        || die "uv did not install the tools with the checksums of ${VERSIONS_FILE} (see the message of uv above)"
}

# manifest_files <root> -- print the manifests of the project (one path for each line, relative to
# <root>, with ./ at the start) that are not in an excluded folder. The manifests are pom.xml,
# package.json, pnpm-lock.yaml and pnpm-workspace.yaml. The excluded folders are .git, node_modules,
# build and target (at each level), and, from the root only, .specmgr (the folders of the features keep
# prototypes and documents that are not part of the layout) and the fixtures of the gates
# (tools/license/fixtures and tools/gates/fixtures). check_pins.py has the same list (EXCLUDED_*).
#
# Two files are not listed, by path and not by folder (feat-16-cdxgen-lockfile): tools/sbom/package.json
# and tools/sbom/pnpm-lock.yaml. They are the lock file of the SBOM tool cdxgen. They are not part of the
# project that the SBOM describes (rule A: cdxgen does not go to users). Each other manifest in tools/sbom/
# (pnpm-workspace.yaml, a package.json in a sub-folder) and in the other folders of tools/ is listed.
# check_pins.py needs no change for them: it searches for pom.xml and for the Maven Wrapper only.
manifest_files() {
    (
        cd "$1" || exit 1
        find . \
            -type d \( -name .git -o -name node_modules -o -name build -o -name target \) -prune -o \
            -type d \( -path ./.specmgr -o -path ./tools/license/fixtures -o -path ./tools/gates/fixtures \) -prune -o \
            -type f \( -path ./tools/sbom/package.json -o -path ./tools/sbom/pnpm-lock.yaml \) -prune -o \
            -type f \( -name pom.xml -o -name package.json -o -name pnpm-lock.yaml -o -name pnpm-workspace.yaml \) \
            -print | LC_ALL=C sort
    )
}
