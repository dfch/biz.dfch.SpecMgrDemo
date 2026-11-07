#!/usr/bin/env bash
# feat-6-contracts-openapi-pipeline, Task 110.115 (REQ-002, REQ-006, REQ-008, REQ-009, ACC-002, ACC-007)
#
# Gate: the linter Spectral examines the OpenAPI file with the rules of the project.
#
# Usage: lint.sh <openapi file> <ruleset>
#   <openapi file>  the file to examine, for example contracts/openapi.yaml
#   <ruleset>       the rules, for example tools/lint/ruleset.yaml (the rules and their causes are in that file
#                   and in tools/lint/README.md)
#
# What the script does:
#   1. It installs Spectral from the lock file in tools/spectral/ with `pnpm install --frozen-lockfile
#      --ignore-scripts` (finding G2, REQ-009). pnpm compares the integrity value of each package (Spectral and
#      all its dependencies) with the lock file, and stops if the lock file and package.json are not the same.
#      No package runs an install script (the package @scarf/scarf of the tree has one, and it must not run).
#      `just check-pins` ties package.json and the lock file to SPECTRAL_VERSION and SPECTRAL_INTEGRITY of
#      tools/versions.env. Spectral is a tool of the gates and does not go to users (rule A), so its tree is
#      not in the SBOM (sbom.sh does not scan tools/spectral/).
#   2. It stops if the installed Spectral has another version than SPECTRAL_VERSION.
#   3. It starts `spectral lint --ruleset <ruleset> --fail-severity warn <openapi file>`. A warning stops the
#      gate too, so a file with a finding of any level does not pass.
#
# Exit codes: 0 the file has no finding; 1 the file has a finding, or the install or the version of Spectral is
# not correct; 2 Spectral could not decide (a file or the ruleset does not exist or cannot be read).
# The script does not change the repository. The install goes to tools/spectral/node_modules (it is in
# .gitignore). Spectral does not send data and does not write a file. The tool needs Node and pnpm
# (the versions are NODE_VERSION and PNPM_VERSION of tools/versions.env) but no Java.
#
# Environment variables for the tests:
#   LINT_TOOL_DIR   another folder for the Spectral project (the default is tools/spectral of this repository)

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/_lib.sh"

[[ $# -eq 2 ]] || die "Usage: lint.sh <openapi file> <ruleset>"
openapi="$1"
ruleset="$2"
[[ -f "${openapi}" ]] || die "The OpenAPI file does not exist: ${openapi}"
[[ -f "${ruleset}" ]] || die "The ruleset does not exist: ${ruleset}"
# Absolute paths: the script starts Spectral in another folder.
openapi="$(cd "$(dirname "${openapi}")" && pwd)/$(basename "${openapi}")"
ruleset="$(cd "$(dirname "${ruleset}")" && pwd)/$(basename "${ruleset}")"

spectral_version="$(version_of SPECTRAL_VERSION)"
require_cmd node
require_cmd pnpm
tool_dir="${LINT_TOOL_DIR:-${REPO_ROOT}/tools/spectral}"
[[ -d "${tool_dir}" ]] || die "The folder of the Spectral project does not exist: ${tool_dir}"
tool_dir="$(cd "${tool_dir}" && pwd)"
for tool_file in package.json pnpm-lock.yaml; do
    [[ -f "${tool_dir}/${tool_file}" ]] || die "${tool_dir}/${tool_file} does not exist. Spectral must run from a lock file. Spectral did not start."
done

log "Install: pnpm install --frozen-lockfile --ignore-scripts in ${tool_dir}"
(cd "${tool_dir}" && pnpm install --frozen-lockfile --ignore-scripts >/dev/null) \
    || die "pnpm install --frozen-lockfile --ignore-scripts failed in ${tool_dir} (see above). Spectral did not start."
spectral_bin="${tool_dir}/node_modules/.bin/spectral"
[[ -x "${spectral_bin}" ]] || die "${spectral_bin} does not exist after the install. Spectral did not start."
# The lock file can have another version than the pin (just check-pins also finds this).
spectral_installed="$(node -p 'require(process.argv[1]).version' "${tool_dir}/node_modules/@stoplight/spectral-cli/package.json")" \
    || die "Cannot read the version of the installed Spectral in ${tool_dir}/node_modules/@stoplight/spectral-cli/package.json"
[[ "${spectral_installed}" == "${spectral_version}" ]] \
    || die "The installed @stoplight/spectral-cli has the version '${spectral_installed}', but SPECTRAL_VERSION in ${VERSIONS_FILE} is '${spectral_version}'. Spectral did not start."
log "The installed @stoplight/spectral-cli has the version ${spectral_installed} (SPECTRAL_VERSION)"

log "Lint: ${openapi} with the rules in ${ruleset}"
set +e
"${spectral_bin}" lint --ruleset "${ruleset}" --fail-severity warn --format stylish "${openapi}"
code=$?
set -e
case "${code}" in
    0) log "PASS. No finding." ;;
    1)
        echo "[$(basename "${0}")] STOP: the file has a finding (see above)." >&2
        exit 1
        ;;
    *)
        echo "[$(basename "${0}")] ERROR: Spectral could not examine the file (exit code ${code}, see above)." >&2
        exit 2
        ;;
esac
