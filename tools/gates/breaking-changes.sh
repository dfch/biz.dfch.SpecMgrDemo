#!/usr/bin/env bash
# feat-6-contracts-openapi-pipeline, Tasks 115.100 to 115.120 (REQ-003, REQ-009, REQ-012, ACC-002, ACC-003, ACC-014)
#
# Gate: breaking changes of the OpenAPI file (DEC 93594b2b-be54-4f60-9f53-ec2ce6c84be4).
#
# Usage: breaking-changes.sh <base> <openapi file> <ignore file>
#   <base>          the branch that the pull request goes to, for example origin/dev (the variable `base` of the
#                   `justfile`; see "The base of the comparison" in tools/gates/README.md)
#   <openapi file>  the path of the file in the repository, for example contracts/openapi.yaml
#   <ignore file>   the ignore file, for example tools/breaking/breaking-changes-ignore.txt
#   The two paths are relative to the repository (GATE_WORK_ROOT in the tests).
#
# The severity levels of oasdiff (tools/breaking/oasdiff-severity-levels.txt, the variable SEVERITY_LEVELS_FILE in the
# tests): the level err for the removal of a response property (required or optional), the removal of a response, and
# the removal of an enum value of a response property (the criterion ACC-003). All other levels are the defaults of
# oasdiff. The file is relative to the repository.
#
# What the script does:
#   1. It finds the merge base of <base> and HEAD (`git merge-base`): a pull request to `dev` is compared with the
#      merge base of the pull request and `dev`, and a release pull request to `main` with `main` (rule 1 of the DEC).
#   2. It reads the OpenAPI file at the merge base (`git show <merge base>:<file>`) into a temporary file. If the base
#      has no such file, there is nothing to compare, and the gate passes (the pull request that adds the file for
#      the first time). If the base has the file and the pull request deletes it, the gate stops.
#   3. It installs oasdiff with a checksum (install_oasdiff in _lib.sh: download, sha256 of OASDIFF_SHA256,
#      build/tools/).
#   4. It starts breaking_changes.py (in a virtual environment with PyYAML from the lock file, as check-pins.sh does),
#      which starts oasdiff with the ignore file and the severity levels file and checks the version number. How the
#      gate decides is in the header of breaking_changes.py.
#
# CI needs `fetch-depth: 0` in `actions/checkout` (the merge base needs the history, as commit-check.sh), `git`, `uv`
# and `just`, the network for the download of oasdiff, and no Node and no Java.
#
# Exit codes: 0 the gate passes; 1 it stops (a breaking change that is not ignored, an entry used with a version that
# does not go up, an ignore file that is not correct, a base that does not exist, an OpenAPI file that is deleted, a
# download with another checksum); 2 the gate cannot decide (oasdiff cannot read a file, or its results disagree).
# The script does not change the repository. oasdiff goes to build/tools/ (it is in .gitignore).

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/_lib.sh"

[[ $# -eq 3 ]] || die "Usage: breaking-changes.sh <base> <openapi file> <ignore file>"
base="$1"
openapi="$2"
ignore="$3"

require_cmd git
cd "${WORK_ROOT}"
# The severity levels of oasdiff (see the header): the level err for the removals of ACC-003. The file is needed only
# if the gate compares, as the ignore file, so the check for it is with the check for the ignore file.
severity_levels="${SEVERITY_LEVELS_FILE:-tools/breaking/oasdiff-severity-levels.txt}"
git rev-parse --verify --quiet "${base}^{commit}" >/dev/null \
    || die "The base '${base}' does not exist. In CI, actions/checkout needs fetch-depth: 0."
merge_base="$(git merge-base "${base}" HEAD)" \
    || die "No merge base of '${base}' and HEAD. In CI, actions/checkout needs fetch-depth: 0 (a shallow clone has no merge base)."
log "Base: ${base}, merge base: ${merge_base}"

if ! git cat-file -e "${merge_base}:${openapi}" 2>/dev/null; then
    log "PASS. The base has no ${openapi}, so there is nothing to compare (the pull request adds the file)."
    exit 0
fi
[[ -f "${openapi}" ]] \
    || { echo "[$(basename "${0}")] STOP: the base has ${openapi}, but the file does not exist now. A deleted OpenAPI file is a breaking change of the whole interface." >&2; exit 1; }
[[ -f "${ignore}" ]] || die "The ignore file does not exist: ${ignore}"
[[ -f "${severity_levels}" ]] || die "The severity levels file does not exist: ${severity_levels}"

work="$(mktemp -d)"
trap 'rm -rf "${work}"' EXIT
base_file="${work}/base-openapi.yaml"
git show "${merge_base}:${openapi}" >"${base_file}" || die "Cannot read ${openapi} at ${merge_base}"

install_oasdiff
make_python_env pyyaml
trap 'rm -rf "${GATE_ENV_DIR}" "${work}"' EXIT

log "Compare ${openapi} with the file at the merge base, with the ignore file ${ignore} and the severity levels ${severity_levels}"
set +e
"${GATE_PYTHON}" "${GATES_DIR}/breaking_changes.py" check "${OASDIFF_BIN}" "${base_file}" "${openapi}" "${ignore}" "${severity_levels}"
code=$?
set -e
case "${code}" in
    0) ;;
    1) echo "[$(basename "${0}")] STOP: see above." >&2 ;;
    *) echo "[$(basename "${0}")] ERROR: the gate could not decide (exit code ${code}, see above)." >&2 ;;
esac
exit "${code}"
