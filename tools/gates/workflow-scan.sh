#!/usr/bin/env bash
# feat-8-traceability-security-gates, Task 120.130 (REQ-004, REQ-005, ACC-005, ACC-006), and
# feat-9-walking-skeleton, Task 500.120 (REQ-006, ACC-007: the level gate)
#
# Gate 9, part 3 (DEC 361678a6-f941-473b-a058-1ba2bacf7d3d): the workflow files, with zizmor. Since feat-9 it is a
# BLOCKING gate: a finding with the severity High stops in each case (zizmor has no level Critical), a finding that is not
# in the baseline file stops, and a line of the baseline that has no finding any more is a warning (the level gate:
# security_level_gate in _security.sh and security_threshold.py).
#
# Usage: workflow-scan.sh <baseline file> <workflow dir or file>...
#   <baseline file>         tools/security/zizmor-baseline.txt: one line for each finding of the state of the feature:
#                           the audit, the file and the place in the file (`artipacked .github/workflows/ci.yml
#                           jobs/lint/steps/0`; the place is the path of the YAML keys and indexes, so a change of the
#                           line numbers of the file does not change the line). The file must exist, also if it has no
#                           line. The path is relative to the repository (GATE_WORK_ROOT in the tests).
#   <workflow dir or file>  a folder with workflow files (for example .github/workflows) or a workflow file. The paths
#                           are relative to the repository (GATE_WORK_ROOT in the tests).
#
# What the script does:
#   1. It stops if the baseline file or a path does not exist.
#   2. It installs zizmor in a temporary virtual environment from the lock file tools/python/zizmor.lock
#      (make_python_env in _lib.sh: `uv pip install --require-hashes --only-binary :all:`, as the other Python tools).
#      The Python of this environment runs the level gate (standard library only).
#   3. It starts `zizmor --offline --no-progress --color never --strict-collection <path>...` for the report (the text
#      with the source lines, in the log), and a second time with `--format json-v1` for the level gate. Both runs see
#      the same files and give the same exit code (a difference is a failure of the tool).
#        --offline            no network: the workflow has no token, and the online audits need one. zizmor does not
#                             start the online audits and does not fetch a remote repository.
#        --strict-collection  a workflow file that zizmor cannot read is an error, and not a warning (without the
#                             option zizmor writes a warning and goes on with the other files).
#      The persona is the default (regular: the findings with few false positives).
#   4. It separates a finding from a failure of the tool (run_security_tool in _security.sh):
#        exit code 0                  no finding
#        exit code 11, 12, 13, 14     findings (the highest level is informational, low, medium or high). The level gate
#                                     decides.
#        each other exit code         a failure of the tool (1 an error of the audit, for example a file that cannot be
#                                     read; 2 a wrong argument; 3 no inputs collected). The gate stops.
#   5. It starts the level gate with the baseline file (security_level_gate).
#
# Exit codes: 0 the gate passes (no new finding, no finding with the severity High); 1 a new finding, a finding that is
# High, a failure of the tool, a path that does not exist or an install that does not work. The script does not change
# the repository.

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/_security.sh"

[[ $# -ge 2 ]] || die "Usage: workflow-scan.sh <baseline file> <workflow dir or file>..."
cd "${WORK_ROOT}"
baseline="$1"
shift
[[ -f "${baseline}" ]] || die "The baseline file does not exist: ${baseline}. The file must exist (it can have no line). The gate does not pass without it."
for path in "$@"; do
    [[ -e "${path}" ]] || die "The path does not exist: ${path}"
done

require_cmd uv
make_python_env zizmor
log "zizmor $(version_of ZIZMOR_VERSION) (all packages are checked with the lock file): $* (offline, level gate with the baseline ${baseline})"
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
    first_exit="${SECURITY_EXIT}"
    # The second run gives the data for the level gate: the JSON goes to a file (stdout), the messages of zizmor to the output.
    report="${GATE_ENV_DIR}/zizmor-report.json"
    zizmor_json() { "${zizmor_bin}" --offline --no-progress --color never --strict-collection --format json-v1 "$@" >"${report}"; }
    run_security_tool "zizmor (JSON for the level gate)" "11 12 13 14" "" "" -- zizmor_json "$@" >/dev/null || status=1
    if [[ "${SECURITY_RESULT}" == "failure" ]]; then
        :
    elif [[ "${SECURITY_EXIT}" != "${first_exit}" ]]; then
        echo "[$(basename "${0}")] FAILURE OF THE TOOL: the second run of zizmor ended with exit code ${SECURITY_EXIT}, the first with ${first_exit}. The runs must give the same result, so the gate stops." >&2
        status=1
    else
        security_level_gate "zizmor" zizmor "${baseline}" "${report}" || status=1
    fi
fi
exit "${status}"
