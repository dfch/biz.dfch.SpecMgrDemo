#!/usr/bin/env bash
# feat-22-python-tools-lockfile, Task 110.100 (REQ-005)
#
# Makes the lock files of the Python tools of the gates. Run it from any folder:
#
#   tools/python/make-locks.sh              keep the versions that the lock files have now
#   tools/python/make-locks.sh --upgrade    take the newest versions of the dependencies
#
# For each tool, the script writes a temporary input file with the version of tools/versions.env
# (SPECMGR_VERSION, PYYAML_VERSION, LICENSE_EXPRESSION_VERSION), and starts
#
#   uv pip compile --generate-hashes --universal --only-binary :all: --python-version <PYTHON_VERSION>
#
# The result has an exact version and the sha256 of each file for each package, with the
# dependencies. --universal makes a lock file that is valid for each platform (the entries
# have markers). --only-binary :all: stops the script if a package has no wheel, so no install
# builds a source archive.
#
# Without --upgrade, the script gives the lock file that exists to uv as the output file. uv then
# keeps each version that is in it, so a new run does not change a version of a dependency. A
# change of the version of a tool in tools/versions.env changes that tool and the dependencies
# that it needs. The script does not change tools/versions.env.
#
# The folder for the lock files is the folder of this script. The variable LOCK_DIR sets another
# folder (a copy of the repository, for a test). Needs uv and network access.

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../gates/_lib.sh"

upgrade=0
case "${1:-}" in
    "") ;;
    --upgrade) upgrade=1 ;;
    *) die "Usage: make-locks.sh [--upgrade]" ;;
esac
[[ $# -le 1 ]] || die "Usage: make-locks.sh [--upgrade]"

require_cmd uv
lock_dir="${LOCK_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"
python_version="$(version_of PYTHON_VERSION)"
[[ "${python_version}" =~ ^3\.[0-9]+$ ]] || die "PYTHON_VERSION is not a minor version like 3.13: '${python_version}'"

work="$(mktemp -d)"
trap 'rm -rf "${work}"' EXIT

# make_lock <lock file name> <requirement> <the key of the version in versions.env>
make_lock() {
    local file="$1" requirement="$2" key="$3" version out
    version="$(version_of "${key}")"
    [[ "${version}" =~ ^[0-9A-Za-z.+_-]+$ ]] || die "${key} is not a version: '${version}'"
    echo "${requirement/@VERSION@/${version}}" >"${work}/input.txt"
    out="${work}/${file}"
    if [[ ${upgrade} -eq 0 && -f "${lock_dir}/${file}" ]]; then
        cp "${lock_dir}/${file}" "${out}"
    else
        rm -f "${out}"
    fi
    log "${file}: ${requirement/@VERSION@/${version}}"
    uv pip compile "${work}/input.txt" --generate-hashes --universal --only-binary :all: \
        --python-version "${python_version}" --no-header --quiet --output-file "${out}" \
        || die "uv could not make ${file} (see the message of uv above)"
    {
        echo "# The lock file of ${requirement/==@VERSION@/} (feat-22-python-tools-lockfile, GitHub issue #22)."
        echo "# Do not edit it. tools/python/make-locks.sh writes it from tools/versions.env, and"
        echo "# just check-pins compares it with tools/versions.env. The procedure to change a version is in"
        echo "# tools/python/README.md. Python ${python_version}, all platforms (--universal), wheels only."
        # uv writes the path of the temporary input file in the `# via` lines. A fixed text keeps the file the same for each run.
        sed -e "s#-r ${work}/input.txt#-r tools/versions.env#" "${out}"
    } >"${lock_dir}/${file}"
}

mkdir -p "${lock_dir}"
make_lock specmgr.lock "biz-dfch-specmgr[mcp]==@VERSION@" SPECMGR_VERSION
make_lock pyyaml.lock "PyYAML==@VERSION@" PYYAML_VERSION
make_lock license-expression.lock "license-expression==@VERSION@" LICENSE_EXPRESSION_VERSION
log "done: ${lock_dir}"
