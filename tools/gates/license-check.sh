#!/usr/bin/env bash
# feat-5-foundation-monorepo-ci, Task 130.130 (REQ-006)
#
# Gate: the licenses of all components in the SBOM files must be permitted.
#
# Usage: license-check.sh <sbom-dir> <permitted-list>
#   <sbom-dir>        the folder with the CycloneDX JSON files (the recipe `sbom` writes them)
#   <permitted-list>  tools/license/permitted-licenses.txt
#
# The table of names for licenses that are not SPDX identifiers is
# tools/license/license-names.txt (a file of the same folder as the list). The script
# license_check.py does the work. It uses the library `license-expression`. The versions and the
# sha256 values of the two wheels are LICENSE_EXPRESSION_VERSION / LICENSE_EXPRESSION_SHA256 and
# BOOLEAN_PY_VERSION / BOOLEAN_PY_SHA256 (its dependency) in tools/versions.env. The script installs
# them with `uv pip install --require-hashes` (make_python_env in _lib.sh): a wrong sha256 value, or
# a package with no value, stops the gate. The environment variable VERSIONS_FILE sets another
# versions file (for the tests).
# Exit codes: 0 pass, 1 a license is not permitted or not known, 2 an error in a file.

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/_lib.sh"

[[ $# -eq 2 ]] || die "Usage: license-check.sh <sbom-dir> <permitted-list>"
sbom_dir="$1"
permitted_list="$2"
names_table="${LICENSE_NAMES_TABLE:-$(dirname "${permitted_list}")/license-names.txt}"

make_python_env require \
    "license-expression:LICENSE_EXPRESSION_VERSION:LICENSE_EXPRESSION_SHA256" \
    "boolean.py:BOOLEAN_PY_VERSION:BOOLEAN_PY_SHA256"
log "license-expression $(version_of LICENSE_EXPRESSION_VERSION), boolean.py $(version_of BOOLEAN_PY_VERSION) (sha256 checked)"
"${GATE_PYTHON}" "${GATES_DIR}/license_check.py" "${sbom_dir}" "${permitted_list}" "${names_table}"
