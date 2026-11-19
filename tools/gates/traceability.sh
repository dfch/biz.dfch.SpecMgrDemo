#!/usr/bin/env bash
# feat-50-structurizr-model-rules, Task 150.100 and 150.110 (the gate was written by
# feat-8-traceability-security-gates, Task 110.130, REQ-001 to REQ-004, ACC-002 to ACC-004)
#
# Gate 2 (DEC f21920d2-4da5-4cf7-bd94-2e9bcba77342, DEC 361678a6-f941-473b-a058-1ba2bacf7d3d): the traceability check.
#
# Usage: traceability.sh <repository root> [traceability.py options]
#   <repository root> is `.` for the recipe. The self-test gives the folder of a fixture. The options are for the
#   self-test only (`--reader-module <module>`).
#
# traceability.py does the work (see the text at the top of that file for the checks, the rules and the definitions):
#   ERROR    a reference in the documents of docs/ and .specmgr/ that has no target; an `x-specmgr-req` of
#            contracts/openapi.yaml that is not the identifier of a REQ; an identifier in `specmgr-req` of
#            model/workspace.json (the old form: it keeps working for one release, the compatibility), an entry of
#            `specmgr-refs` of model/workspace.json (the new form TYPE UUID; TYPE UUID) that has no document of its
#            type, or `vcr:<uuid>` in a test, that has no document; an approved REQ with no VCR.
#   WARNING  an approved REQ with no element in the model (in `specmgr-req`, or in an entry of the type REQ of
#            `specmgr-refs`); the VCR of an approved REQ that is not in the name of a test.
#            A warning does not stop the gate (the owner decides this when the first approved REQ exists).
# The references are read with the function find_references of the pinned specmgr. The script runs in the hash-locked
# environment of specmgr (`uv pip install --require-hashes` from tools/python/specmgr.lock, make_python_env in _lib.sh),
# and it stops if the function has not the form that it expects.
#
# Exit codes: 0 no error (warnings are possible), 1 at least one error, 2 an input that cannot be read, or a reader of
# references with another form.

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/_lib.sh"

[[ $# -ge 1 ]] || die "Usage: traceability.sh <repository root> [traceability.py options]"
root="$1"
shift
[[ -d "${root}" ]] || die "The folder does not exist: ${root}"

require_cmd uv
make_python_env specmgr
log "specmgr $(version_of SPECMGR_VERSION) (all packages are checked with the lock file): traceability of ${root}"
set +e
"${GATE_PYTHON}" "${GATES_DIR}/traceability.py" "${root}" "$@"
code=$?
set -e
exit "${code}"
