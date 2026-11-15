#!/usr/bin/env bash
# feat-8-traceability-security-gates, Task 120.130 (REQ-004, REQ-005, ACC-005, ACC-006)
#
# Gate 9, part 3 (DEC 361678a6-f941-473b-a058-1ba2bacf7d3d): the workflow files, with zizmor. It is a REPORT with no
# threshold: a finding does not stop the gate.
#
# Usage: workflow-scan.sh <workflow dir or file>...
#   <workflow dir or file>  a folder with workflow files (for example .github/workflows) or a workflow file. The paths
#                           are relative to the repository (GATE_WORK_ROOT in the tests).
#
# What the script does:
#   1. It stops if a path does not exist.
#   2. It installs zizmor in a temporary virtual environment from the lock file tools/python/zizmor.lock
#      (make_python_env in _lib.sh: `uv pip install --require-hashes --only-binary :all:`, as the other Python tools).
#   3. It starts `zizmor --offline --no-progress --color never --strict-collection <path>...`.
#        --offline            no network: the workflow has no token, and the online audits need one. zizmor does not
#                             start the online audits and does not fetch a remote repository.
#        --strict-collection  a workflow file that zizmor cannot read is an error, and not a warning (without the
#                             option zizmor writes a warning and goes on with the other files).
#      The persona is the default (regular: the findings with few false positives).
#   4. It separates a finding from a failure of the tool (run_security_tool in _security.sh):
#        exit code 0                  no finding
#        exit code 11, 12, 13, 14     findings (the highest level is informational, low, medium or high). The report
#                                     is the result, and the gate does not stop.
#        each other exit code         a failure of the tool (1 an error of the audit, for example a file that cannot be
#                                     read; 2 a wrong argument; 3 no inputs collected). The gate stops.
#
# Exit codes: 0 the report is done (with or without a finding); 1 a failure of the tool, a path that does not exist or
# an install that does not work. The script does not change the repository.

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/_security.sh"

[[ $# -ge 1 ]] || die "Usage: workflow-scan.sh <workflow dir or file>..."
cd "${WORK_ROOT}"
for path in "$@"; do
    [[ -e "${path}" ]] || die "The path does not exist: ${path}"
done

require_cmd uv
make_python_env zizmor
log "zizmor $(version_of ZIZMOR_VERSION) (all packages are checked with the lock file): $* (offline, no threshold)"
# The tool is the installed package of the environment: a zizmor on the PATH is never used.
zizmor_bin="${GATE_ENV_DIR}/venv/bin/zizmor"
[[ -x "${zizmor_bin}" ]] || die "The environment has no zizmor: ${zizmor_bin}"
installed="$("${zizmor_bin}" --version 2>/dev/null)" || die "${zizmor_bin} does not start."
[[ "${installed}" == "zizmor $(version_of ZIZMOR_VERSION)" ]] \
    || die "${zizmor_bin} says '${installed}', but ZIZMOR_VERSION in ${VERSIONS_FILE} is '$(version_of ZIZMOR_VERSION)'."

status=0
# NO_COLOR and ZIZMOR_* variables of the environment must not change the mode (--offline is explicit)
run_security_tool "zizmor" "11 12 13 14" "" "" -- \
    "${zizmor_bin}" --offline --no-progress --color never --strict-collection "$@" || status=1

if [[ "${SECURITY_RESULT}" != "failure" ]]; then
    summary="$(grep -E '^[0-9]+ findings? |^No findings to report' <<<"${SECURITY_OUTPUT}" | head -n 1 || true)"
    log "REPORT: ${summary:-the summary line of zizmor is not in the output}"
fi
exit "${status}"
