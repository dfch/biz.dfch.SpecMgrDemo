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

# make_python_env <lock-name>
#
# Makes a temporary virtual environment for a Python tool of a gate, and installs the tool in it from
# the lock file tools/python/<lock-name>.lock (feat-22-python-tools-lockfile, finding G2). The lock file
# has the exact version and the sha256 of each file of each package, with the dependencies. The
# function starts
#
#   uv venv --python <PYTHON_VERSION>
#   uv pip install --require-hashes --only-binary :all: -r <lock file>
#
#   --require-hashes   uv stops for a file with another hash, and for a package that has no hash or is
#                      not in the lock file (a dependency too).
#   --only-binary      uv does not build a source archive, so no build tool is part of the install.
#
# PYTHON_VERSION (the minor version, 3.13) is in tools/versions.env. uv uses a Python of this version
# that is on the machine, or downloads one. The folder of the lock files is tools/python of this
# repository. The variable PYTHON_LOCK_DIR sets another folder (only the self-tests use it).
# `just check-pins` ties the version of the tool in the lock file to tools/versions.env.
#
# Sets GATE_ENV_DIR (the temporary folder; the variable GATE_PYTHON is the Python of the
# environment) and removes the folder when the script ends. A lock file that is missing, or a
# PYTHON_VERSION that is not a minor version, stops the script.
make_python_env() {
    local lock_name="$1" lock_file python_version
    [[ $# -eq 1 && "${lock_name}" =~ ^[a-z0-9-]+$ ]] || die "make_python_env: usage: make_python_env <lock-name>"
    lock_file="${PYTHON_LOCK_DIR:-${REPO_ROOT}/tools/python}/${lock_name}.lock"
    [[ -f "${lock_file}" ]] || die "Lock file not found: ${lock_file}"
    python_version="$(version_of PYTHON_VERSION)"
    [[ "${python_version}" =~ ^3\.[0-9]+$ ]] || die "PYTHON_VERSION is not a minor version like 3.13: '${python_version}'"
    require_cmd uv
    GATE_ENV_DIR="$(mktemp -d)"
    trap 'rm -rf "${GATE_ENV_DIR}"' EXIT
    uv venv --quiet --python "${python_version}" "${GATE_ENV_DIR}/venv" || die "uv could not make a virtual environment with Python ${python_version}"
    GATE_PYTHON="${GATE_ENV_DIR}/venv/bin/python"
    uv pip install --quiet --python "${GATE_PYTHON}" --require-hashes --only-binary :all: -r "${lock_file}" \
        || die "uv did not install ${lock_name} from ${lock_file} (see the message of uv above)"
}

# manifest_files <root> -- print the manifests of the project (one path for each line, relative to
# <root>, with ./ at the start) that are not in an excluded folder. The manifests are pom.xml,
# package.json, pnpm-lock.yaml and pnpm-workspace.yaml. The excluded folders are .git, node_modules,
# build and target (at each level), and, from the root only, .specmgr (the folders of the features keep
# prototypes and documents that are not part of the layout) and the fixtures of the gates
# (tools/license/fixtures and tools/gates/fixtures). check_pins.py has the same list (EXCLUDED_*).
#
# Four files are not listed, by path and not by folder: tools/sbom/package.json and tools/sbom/pnpm-lock.yaml
# (the lock file of the SBOM tool cdxgen, feat-16-cdxgen-lockfile), and tools/spectral/package.json and
# tools/spectral/pnpm-lock.yaml (the lock file of the linter Spectral, feat-6-contracts-openapi-pipeline). They
# are not part of the project that the SBOM describes (rule A: these tools do not go to users). Each other
# manifest in tools/sbom/ and in tools/spectral/ (pnpm-workspace.yaml, a package.json in a sub-folder) and in the
# other folders of tools/ is listed.
# check_pins.py needs no change for them: it searches for pom.xml and for the Maven Wrapper only.
manifest_files() {
    (
        cd "$1" || exit 1
        find . \
            -type d \( -name .git -o -name node_modules -o -name build -o -name target \) -prune -o \
            -type d \( -path ./.specmgr -o -path ./tools/license/fixtures -o -path ./tools/gates/fixtures \) -prune -o \
            -type f \( -path ./tools/sbom/package.json -o -path ./tools/sbom/pnpm-lock.yaml \
            -o -path ./tools/spectral/package.json -o -path ./tools/spectral/pnpm-lock.yaml \) -prune -o \
            -type f \( -name pom.xml -o -name package.json -o -name pnpm-lock.yaml -o -name pnpm-workspace.yaml \) \
            -print | LC_ALL=C sort
    )
}

# install_oasdiff
#
# Installs the tool for breaking changes oasdiff (feat-6-contracts-openapi-pipeline, Task 115.100, REQ-009) and
# sets OASDIFF_BIN to its path. oasdiff is a Go binary with no package manager, so the install is a download with
# a checksum, as the install scripts of just and Node:
#
#   1. The script stops if the machine is not Linux x86_64. The pin has the checksum of the file
#      oasdiff_<OASDIFF_VERSION>_linux_amd64.tar.gz only (the gates run on a runner of GitHub and on the machine
#      of the author, and both are Linux x86_64).
#   2. If the folder <home>/oasdiff-<version> has the binary, the version of the binary is OASDIFF_VERSION, and the
#      file `.sha256` of the folder has the value OASDIFF_SHA256, the script does not download again. A change of
#      OASDIFF_VERSION or of OASDIFF_SHA256 in tools/versions.env therefore makes a new download.
#   3. If not, it downloads the file with curl, compares the sha256 of the file with OASDIFF_SHA256 of
#      tools/versions.env (never with a value from the server) BEFORE it unpacks the file, and stops (the download
#      is deleted) if the value is not the same. It unpacks only the two files `oasdiff` and `LICENSE`.
#   4. It stops if `oasdiff --version` does not say `oasdiff version <OASDIFF_VERSION>`.
#
# Variables for the tests: OASDIFF_HOME (the folder for the install; the default is build/tools of this repository,
# and /build/ is in .gitignore) and OASDIFF_URL (another URL for the file, for example a file:// URL; the sha256 is
# compared with the pin in each case, so another URL gives no other trust). The install needs the network for the
# first run (curl, GitHub). The tool does not send data and does not write a file when it examines a file. The
# tool reads a configuration file `.oasdiff.*` or `oasdiff.*` in the current folder, so breaking_changes.py starts it
# in a new empty folder.
install_oasdiff() {
    local version sha home target url work actual installed
    version="$(version_of OASDIFF_VERSION)"
    sha="$(version_of OASDIFF_SHA256)"
    [[ "${version}" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || die "OASDIFF_VERSION is not an exact version: '${version}'"
    [[ "${sha}" =~ ^[0-9a-f]{64}$ ]] || die "OASDIFF_SHA256 is not a sha256 value (64 lower case hexadecimal characters): '${sha}'"
    [[ "$(uname -s)" == "Linux" && "$(uname -m)" == "x86_64" ]] \
        || die "oasdiff is pinned for Linux x86_64 only (OASDIFF_SHA256 is the checksum of the linux_amd64 file). This machine is $(uname -s) $(uname -m)."
    require_cmd tar
    require_cmd sha256sum
    home="${OASDIFF_HOME:-${REPO_ROOT}/build/tools}"
    target="${home}/oasdiff-${version}"
    OASDIFF_BIN="${target}/oasdiff"

    if [[ -x "${OASDIFF_BIN}" && -f "${target}/.sha256" && "$(cat "${target}/.sha256")" == "${sha}" ]] \
        && [[ "$("${OASDIFF_BIN}" --version 2>/dev/null)" == "oasdiff version ${version}" ]]; then
        log "oasdiff ${version} is already installed in ${target}"
        return 0
    fi

    require_cmd curl
    url="${OASDIFF_URL:-https://github.com/oasdiff/oasdiff/releases/download/v${version}/oasdiff_${version}_linux_amd64.tar.gz}"
    mkdir -p "${home}"
    work="$(mktemp -d "${home}/.oasdiff.XXXXXX")"
    log "Download ${url}"
    curl -fsSL --retry 3 -o "${work}/archive.tar.gz" "${url}" || { rm -rf "${work}"; die "Download failed: ${url}"; }
    actual="$(sha256sum "${work}/archive.tar.gz" | cut -d' ' -f1)"
    if [[ "${actual}" != "${sha}" ]]; then
        rm -rf "${work}"
        die "sha256 of the oasdiff download is ${actual}, but OASDIFF_SHA256 in ${VERSIONS_FILE} is ${sha}. The download is deleted. oasdiff did not start."
    fi
    log "sha256 is correct for the oasdiff download"
    mkdir -p "${work}/unpacked"
    tar -xzf "${work}/archive.tar.gz" -C "${work}/unpacked" oasdiff LICENSE \
        || { rm -rf "${work}"; die "The oasdiff download has not the files oasdiff and LICENSE."; }
    printf '%s\n' "${sha}" >"${work}/unpacked/.sha256"
    rm -rf "${target}"
    mv "${work}/unpacked" "${target}"
    rm -rf "${work}"
    installed="$("${OASDIFF_BIN}" --version 2>/dev/null)" || die "${OASDIFF_BIN} does not start."
    [[ "${installed}" == "oasdiff version ${version}" ]] \
        || die "${OASDIFF_BIN} says '${installed}', but OASDIFF_VERSION in ${VERSIONS_FILE} is '${version}'."
    log "oasdiff ${version} is in ${target}"
}

# verify_generator_plugin <module dir>
#
# Compares the sha256 of the jar of the generator plugin (openapi-generator-maven-plugin, feat-6-contracts-openapi-pipeline,
# Task 120.105, REQ-009, ACC-012) with OPENAPI_GENERATOR_MAVEN_PLUGIN_SHA256 of tools/versions.env, as sbom.sh does for
# cyclonedx-maven-plugin (rule G2):
#
#   1. The function starts the goal `generate` of the plugin (the version is OPENAPI_GENERATOR_MAVEN_PLUGIN_VERSION; the
#      execution `spring-interfaces` of backend/pom.xml gives the input) with -Dcodegen.skip=true through the Maven Wrapper of <module dir> (never the Maven of the PATH). Maven loads the plugin,
#      and downloads the jar to the local repository if it is not there, but nothing is generated.
#   2. It compares the sha256 of the jar in the local repository with the pin, and stops (exit code 1) if the value is not
#      the same. The caller starts the real plugin only after this function returns.
#
# The local repository is ~/.m2/repository. GENERATOR_MAVEN_REPO_LOCAL sets another one (for the tests); the function gives
# it to Maven with -Dmaven.repo.local, so Maven and the function use the same folder. The dependencies of the plugin are NOT
# checked (GitHub issue #23). The first run needs the network (Maven Central).
verify_generator_plugin() {
    local module_dir="$1" version sha repo_local jar actual
    version="$(version_of OPENAPI_GENERATOR_MAVEN_PLUGIN_VERSION)"
    sha="$(version_of OPENAPI_GENERATOR_MAVEN_PLUGIN_SHA256)"
    [[ "${version}" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || die "OPENAPI_GENERATOR_MAVEN_PLUGIN_VERSION is not an exact version: '${version}'"
    [[ "${sha}" =~ ^[0-9a-f]{64}$ ]] || die "OPENAPI_GENERATOR_MAVEN_PLUGIN_SHA256 is not a sha256 value: '${sha}'"
    [[ -f "${module_dir}/mvnw" ]] || die "${module_dir}/mvnw does not exist. The gates must not use the Maven of the PATH."
    [[ -x "${module_dir}/mvnw" ]] || die "${module_dir}/mvnw is not executable (chmod +x, and git update-index --chmod=+x)."
    require_cmd sha256sum
    repo_local="${GENERATOR_MAVEN_REPO_LOCAL:-${HOME}/.m2/repository}"
    jar="${repo_local}/org/openapitools/openapi-generator-maven-plugin/${version}/openapi-generator-maven-plugin-${version}.jar"
    log "Generator plugin: openapi-generator-maven-plugin ${version} (load the plugin, no generation)"
    (
        cd "${module_dir}" && ./mvnw --batch-mode --no-transfer-progress --file pom.xml "-Dmaven.repo.local=${repo_local}" \
            "org.openapitools:openapi-generator-maven-plugin:${version}:generate@spring-interfaces" -Dcodegen.skip=true
    ) || die "Maven could not load the plugin openapi-generator-maven-plugin ${version} (see above)."
    [[ -f "${jar}" ]] || die "The plugin jar is not at ${jar} after Maven loaded it."
    actual="$(sha256sum "${jar}" | cut -d' ' -f1)"
    [[ "${actual}" == "${sha}" ]] \
        || die "sha256 of ${jar} is ${actual}, but OPENAPI_GENERATOR_MAVEN_PLUGIN_SHA256 in ${VERSIONS_FILE} is ${sha}. The plugin did not generate."
    log "sha256 of the plugin jar is the value of OPENAPI_GENERATOR_MAVEN_PLUGIN_SHA256"
}

# install_frontend <frontend dir>
#
# Installs the pnpm module frontend/ from its lock file (feat-6-contracts-openapi-pipeline, Task 120.110, REQ-009, ACC-011):
#
#   pnpm install --frozen-lockfile --ignore-scripts
#
# pnpm stops if package.json and the lock file are not the same, and it compares the integrity value of each tarball (Kubb,
# Zod, TypeScript and all their dependencies) with the lock file. No package runs an install script. Then the function stops
# if an installed package has another version than the key of tools/versions.env (`just check-pins` ties package.json and the
# lock file to these keys, and this is the check of the install itself). Needs Node, pnpm and the network (the first run).
install_frontend() {
    local frontend_dir="$1" file
    [[ -d "${frontend_dir}" ]] || die "The folder of the pnpm module does not exist: ${frontend_dir}"
    for file in package.json pnpm-lock.yaml pnpm-workspace.yaml; do
        [[ -f "${frontend_dir}/${file}" ]] || die "${frontend_dir}/${file} does not exist. The module must run from a lock file."
    done
    require_cmd node
    require_cmd pnpm
    log "Install: pnpm install --frozen-lockfile --ignore-scripts in ${frontend_dir}"
    (cd "${frontend_dir}" && pnpm install --frozen-lockfile --ignore-scripts >/dev/null) \
        || die "pnpm install --frozen-lockfile --ignore-scripts failed in ${frontend_dir} (see above). Nothing was generated."
    local entry package key want installed
    for entry in kubb:KUBB_VERSION @kubb/core:KUBB_VERSION @kubb/plugin-zod:KUBB_PLUGIN_ZOD_VERSION \
        @kubb/plugin-ts:KUBB_PLUGIN_TS_VERSION zod:ZOD_VERSION typescript:TYPESCRIPT_VERSION; do
        package="${entry%%:*}" key="${entry##*:}"
        want="$(version_of "${key}")"
        installed="$(node -p 'require(process.argv[1]).version' "${frontend_dir}/node_modules/${package}/package.json")" \
            || die "Cannot read the version of the installed ${package} in ${frontend_dir}/node_modules/${package}/package.json"
        [[ "${installed}" == "${want}" ]] \
            || die "The installed ${package} has the version '${installed}', but ${key} in ${VERSIONS_FILE} is '${want}'."
    done
    log "The installed Kubb, Zod and TypeScript have the versions of tools/versions.env"
}
