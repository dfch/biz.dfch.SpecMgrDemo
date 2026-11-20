#!/usr/bin/env bash
# feat-8-traceability-security-gates, Tasks 120.100 to 120.130 (REQ-004, REQ-005, ACC-005, ACC-006)
#
# Test of the three security recipes (vuln-scan.sh, secret-scan.sh, workflow-scan.sh), of the function that
# separates a finding from a failure of the tool (security_classify and run_security_tool in _security.sh) and of the
# level gate with the baseline files (security_level_gate in _security.sh, security_threshold.py).
#
# Usage: test-security-gates.sh
#
# feat-8 ACC-005: each security recipe ends with an exit code that is not 0 for a failure of the tool, and a finding
# does not look like a failure. Since feat-9-walking-skeleton (Task 500.120, ACC-007) the recipes are blocking gates with
# a level gate: exit code 0 for no finding and for a finding of the baseline (an old line of the baseline is a warning),
# and exit code 1 for a new finding, for a finding that is Critical or High (also if the baseline has a line for it:
# that is an error of the feature), and for the failure of the tool. This test shows each case for each tool:
#
#   Part 1  the function: the table of exit codes of the three tools (OSV-Scanner, gitleaks, zizmor), a value that is no
#           number, a signal, the finding marker and the failure marker of run_security_tool.
#   Part 2  vuln-scan.sh with a STUB of OSV-Scanner (a script in the folder that the install knows as already installed,
#           so no download and no network): no finding, a finding (exit code 1 of the tool), each failure (127, 128,
#           another code), no SBOM file. The install of OSV-Scanner with the sha256 check (a file:// URL with a small
#           file, no network): a good file, a wrong checksum (the tool never starts), a wrong version, a download that
#           does not work, the cache. Then the REAL OSV-Scanner without the network (a proxy that refuses the
#           connection): the real failure of the tool (exit code 127), and an SBOM with no package (exit code 128).
#   Part 3  secret-scan.sh with a STUB of gitleaks (a finding with exit code 2, each failure, an ERR line with exit
#           code 0), the install of gitleaks with the sha256 check, and the REAL gitleaks in temporary git repositories
#           (a clean repository, a secret in a file, in the history only, in the base only, in a file that is not
#           committed, in a file that git ignores, a comment `gitleaks:allow`, a `.gitleaksignore` file, an allowlist
#           entry, a wrong config, a base that does not exist, a shallow clone). The fake secrets are made while the
#           test runs (the repository has no value that looks like a secret).
#   Part 4  workflow-scan.sh with the REAL zizmor and the fixtures in fixtures/security/: a clean workflow, a workflow
#           with a known problem (a finding: exit code 0), a file that cannot be read, a folder with no workflow, a path
#           that does not exist.
#   Part 5  the form of the scripts and of the recipes (the options that the plan and the deviation DEC need, the
#           recipes in the justfile, the allowlist of gitleaks, CODEOWNERS).
#   Part 6  the level gate itself (security_threshold.py with the report files of the three tools, made while the test
#           runs): the levels (CVSS score, label, zizmor severity, gitleaks has none), the new finding, the finding that
#           is Critical or High (also with a line in the baseline), the old line, the finding of the baseline that
#           passes, and each input that cannot be used (a missing or wrong baseline, a wrong report). The real files
#           tools/security/*-baseline.txt are examined too (the form, no line twice, no level that is not allowed).
#           In parts 2, 3 and 4 the recipes show the same cases with a stub of the tool (OSV-Scanner, gitleaks) and with
#           the real tools (gitleaks, zizmor).
#
# The install of the cache is verified again (no marker file): a cache with a changed binary (OSV-Scanner), or with a
# changed or missing archive (gitleaks), is not started and is replaced by a new download, or the install stops. A real
# tool that cannot be installed (no network) is a counted FAIL with the message of the install, and the cases that need
# the tool are not run (real_install), so the script ends with the summary line and exit code 1.
#
# The script needs git, uv, curl and the network for the first run (the install of gitleaks and of OSV-Scanner from
# GitHub, and the install of zizmor from the lock file). It does not change the repository. The real tools go to
# build/tools/ (it is in .gitignore).

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/_security.sh"

require_cmd git
require_cmd uv
require_cmd curl
require_cmd tar
require_cmd sha256sum

fixtures="${GATES_DIR}/fixtures/security"
real_config="${REPO_ROOT}/tools/security/gitleaks.toml"
real_gl_baseline="${REPO_ROOT}/tools/security/gitleaks-baseline.txt"
[[ -d "${fixtures}" ]] || die "No folder ${fixtures}"
[[ -f "${real_config}" ]] || die "No file ${real_config}"
[[ -f "${real_gl_baseline}" ]] || die "No file ${real_gl_baseline}"

work="$(mktemp -d)"
trap 'rm -rf "${work}"' EXIT
osv_version="$(version_of OSV_SCANNER_VERSION)"
gitleaks_version="$(version_of GITLEAKS_VERSION)"

passed=0
failed=0

# expect <exit code> <text in the output> <description> <command...>
expect() {
    local want_code="$1" want_text="$2" description="$3"
    shift 3
    local output code
    set +e
    output="$("$@" 2>&1)"
    code=$?
    set -e
    if [[ ${code} -eq ${want_code} && "${output}" == *"${want_text}"* ]]; then
        echo "ok   ${description}"
        passed=$((passed + 1))
    else
        echo "FAIL ${description}: expected exit code ${want_code} and '${want_text}', got exit code ${code}"
        echo "${output}" | sed -e 's/^/     | /'
        failed=$((failed + 1))
    fi
}

# expect_fail <text in the output> <description> <command...> : exit code 1 and the text in the output
expect_fail() {
    local want_text="$1" description="$2"
    shift 2
    expect 1 "${want_text}" "${description}" "$@"
}

# expect_not <exit code> <text that must NOT be in the output> <description> <command...>
expect_not() {
    local want_code="$1" bad_text="$2" description="$3"
    shift 3
    local output code
    set +e
    output="$("$@" 2>&1)"
    code=$?
    set -e
    if [[ ${code} -eq ${want_code} && "${output}" != *"${bad_text}"* ]]; then
        echo "ok   ${description}"
        passed=$((passed + 1))
    else
        echo "FAIL ${description}: expected exit code ${want_code} and no '${bad_text}', got exit code ${code}"
        echo "${output}" | sed -e 's/^/     | /'
        failed=$((failed + 1))
    fi
}

# check <description> <command...> : the command must succeed (for the tests that are not a run of a script)
check() {
    local description="$1"
    shift
    if "$@" >/dev/null 2>&1; then
        echo "ok   ${description}"
        passed=$((passed + 1))
    else
        echo "FAIL ${description}"
        failed=$((failed + 1))
    fi
}

section() { echo; echo "== $*"; }

# real_install <label> <install function> <variable of the path of the binary> <variable of the folder> <folder>
#
# Installs a REAL tool (the download of the release with the sha256 check, or the cache of build/tools/) in a subshell,
# so a download that does not work (no network, a wrong checksum) is a counted FAIL of this test with the message of the
# install, and not an exit of the whole script with no summary (G2 of the review). It sets REAL_BIN to the path of the
# binary and returns 0 on success. On failure it returns 1: the caller skips the cases that need the real tool (they
# would all fail for the same cause), and the end of the script ends with exit code 1 and the summary line.
real_install() {
    local label="$1" install_function="$2" bin_variable="$3" home_variable="$4" home="$5" output code
    REAL_BIN=""
    set +e
    output="$(env "${home_variable}=${home}" bash -c 'source "$1/_security.sh"; "$2"; echo "BIN=${!3}"' test-security-gates.sh "${GATES_DIR}" "${install_function}" "${bin_variable}" 2>&1)"
    code=$?
    set -e
    if [[ ${code} -eq 0 ]]; then
        REAL_BIN="$(grep '^BIN=' <<<"${output}" | tail -n 1 | cut -d= -f2-)"
        echo "ok   the real ${label} is installed (the download with the sha256 check, or the verified cache)"
        passed=$((passed + 1))
        return 0
    fi
    echo "FAIL the real ${label} cannot be installed (exit code ${code}). The cases that need the real ${label} are not run. The reason is in the output of the install:"
    printf '%s\n' "${output}" | tail -n 8 | sed -e 's/^/     | /'
    failed=$((failed + 1))
    return 1
}

# ======================================================================================================================
section "Part 1: security_classify and run_security_tool (ACC-005, the function that separates a finding from a failure)"

# classify_case <expected word> <description> <exit code> [<finding code>...]
classify_case() {
    local want="$1" description="$2" got
    shift 2
    got="$(security_classify "$@")"
    if [[ "${got}" == "${want}" ]]; then
        echo "ok   ${description}"
        passed=$((passed + 1))
    else
        echo "FAIL ${description}: expected '${want}', got '${got}'"
        failed=$((failed + 1))
    fi
}

# OSV-Scanner: 0 clean, 1 findings, everything else is a failure (127 general error, 128 no packages found)
classify_case clean "OSV-Scanner: exit code 0 is clean" 0 1
classify_case finding "OSV-Scanner: exit code 1 is a finding" 1 1
classify_case failure "OSV-Scanner: exit code 127 (general error, for example no network) is a failure" 127 1
classify_case failure "OSV-Scanner: exit code 128 (no packages found) is a failure" 128 1
classify_case failure "OSV-Scanner: exit code 129 (a code for errors that are not a result) is a failure" 129 1
classify_case failure "OSV-Scanner: exit code 2 (a code that is not documented for findings) is a failure" 2 1
# gitleaks with --exit-code 2: 0 clean, 2 leaks, 1 fatal error, 126 wrong flag
classify_case clean "gitleaks: exit code 0 is clean" 0 2
classify_case finding "gitleaks: exit code 2 (--exit-code 2) is a finding" 2 2
classify_case failure "gitleaks: exit code 1 (a fatal error: a wrong config or a path that does not exist) is a failure" 1 2
classify_case failure "gitleaks: exit code 126 (a wrong flag) is a failure" 126 2
# zizmor: 0 clean, 11 to 14 findings, 1 error, 2 wrong argument, 3 no inputs
classify_case clean "zizmor: exit code 0 is clean" 0 11 12 13 14
for code in 11 12 13 14; do
    classify_case finding "zizmor: exit code ${code} is a finding" "${code}" 11 12 13 14
done
classify_case failure "zizmor: exit code 1 (an error of the audit) is a failure" 1 11 12 13 14
classify_case failure "zizmor: exit code 2 (a wrong argument) is a failure" 2 11 12 13 14
classify_case failure "zizmor: exit code 3 (no inputs collected) is a failure" 3 11 12 13 14
classify_case failure "zizmor: exit code 10 (not used since v1.14.0) is a failure" 10 11 12 13 14
classify_case failure "zizmor: exit code 15 (reserved) is a failure" 15 11 12 13 14
# the general cases
classify_case failure "a tool that is killed by a signal (137) is a failure" 137 1
classify_case failure "a tool that is not found (127) is a failure" 127 2
classify_case failure "an exit code that is no number is a failure" "x" 1
classify_case failure "an empty exit code is a failure" "" 1
classify_case failure "a negative exit code is a failure" "-1" 1
classify_case clean "exit code 0 is clean also with no finding code" 0
classify_case failure "each non-zero exit code is a failure if the tool has no finding code" 1

# run_case <description> <expected result> <expected return> <expected text in the output> <finding codes> <finding marker> <failure marker> <shell command>
# The function runs in a subshell, and the subshell prints the result, the exit code of the tool and the return value.
run_case() {
    local description="$1" want_result="$2" want_return="$3" want_text="$4" codes="$5" fmarker="$6" emarker="$7" command="$8" output
    output="$(
        # shellcheck disable=SC1091
        source "${GATES_DIR}/_security.sh"
        set +e
        run_security_tool "Tool" "${codes}" "${fmarker}" "${emarker}" -- bash -c "${command}" 2>&1
        echo "return=$?"
        echo "result=${SECURITY_RESULT} exit=${SECURITY_EXIT}"
    )"
    if [[ "${output}" == *"return=${want_return}"* && "${output}" == *"result=${want_result} "* && "${output}" == *"${want_text}"* ]]; then
        echo "ok   ${description}"
        passed=$((passed + 1))
    else
        echo "FAIL ${description}: expected result ${want_result}, return ${want_return} and '${want_text}'"
        echo "${output}" | sed -e 's/^/     | /'
        failed=$((failed + 1))
    fi
}

run_case "run_security_tool: exit code 0 gives clean, and the function returns 0" clean 0 "no finding" "1" "" "" 'echo hello; exit 0'
run_case "run_security_tool: a finding code gives finding, and the function returns 0 (the report is the result)" finding 0 "FINDINGS (exit code 1)" "1" "" "" 'echo report line; exit 1'
run_case "run_security_tool: the output of the tool is written" finding 0 "report line" "1" "" "" 'echo report line; exit 1'
run_case "run_security_tool: another code gives failure, and the function returns 1" failure 1 "FAILURE OF THE TOOL: Tool ended with exit code 127" "1" "" "" 'echo oops; exit 127'
run_case "run_security_tool: a tool that does not start gives failure" failure 1 "FAILURE OF THE TOOL" "1" "" "" '/nonexistent/tool-that-is-not-there'
run_case "run_security_tool: a finding code with no finding marker in the output is a failure (a crash has the same code)" failure 1 "no sign of a finding" "2" "leaks found" "" 'echo "panic: runtime error"; exit 2'
run_case "run_security_tool: a finding code with the finding marker is a finding" finding 0 "FINDINGS (exit code 2)" "2" "leaks found" "" 'echo "WRN leaks found: 3"; exit 2'
run_case "run_security_tool: an error line with exit code 0 is a failure (the ERR line of gitleaks)" failure 1 "has an error line" "2" "leaks found" ' ERR ' 'echo "11:49AM ERR [git] fatal: bad range"; echo "0 commits scanned"; exit 0'
run_case "run_security_tool: an error line with a finding code is a failure" failure 1 "has an error line" "2" "leaks found" ' ERR ' 'echo "11:49AM ERR something"; echo "leaks found: 1"; exit 2'
run_case "run_security_tool: no error line and exit code 0 is clean" clean 0 "no finding" "2" "leaks found" ' ERR ' 'echo "11:49AM INF no leaks found"; exit 0'
run_case "run_security_tool: a list of finding codes (zizmor 13)" finding 0 "FINDINGS (exit code 13)" "11 12 13 14" "" "" 'exit 13'
run_case "run_security_tool: a code that is not in the list of finding codes (zizmor 3)" failure 1 "FAILURE OF THE TOOL" "11 12 13 14" "" "" 'exit 3'

# ======================================================================================================================
section "Part 2: vuln-scan.sh (OSV-Scanner)"

# A stub of OSV-Scanner. The install knows a folder with a binary that has the pin (see versions_osv below) and the
# right version as "already installed", so the stub is started and nothing is downloaded. The stub writes its arguments to
# the file STUB_ARGS_FILE, and its output and exit code are STUB_OUTPUT and STUB_EXIT.
stub_script() {
    local version_line="$1" version_command="$2" extra_line="${3:-no}" extra=""
    # OSV-Scanner prints more than one line for --version (only the first line is the version), gitleaks prints one line
    [[ "${extra_line}" == "yes" ]] && extra='echo "stub version information that is not the first line"'
    cat <<STUB
#!/usr/bin/env bash
if [[ "\${1:-}" == "${version_command}" ]]; then
    echo "${version_line}"
    ${extra}
    exit 0
fi
[[ -n "\${STUB_STARTED_FILE:-}" ]] && echo "started" >>"\${STUB_STARTED_FILE}"
[[ -n "\${STUB_ARGS_FILE:-}" ]] && printf '%s\n' "\$@" >"\${STUB_ARGS_FILE}"
[[ -n "\${STUB_OUTPUT:-}" ]] && printf '%s\n' "\${STUB_OUTPUT}"
# The report of the tool (JSON): the file STUB_REPORT_<FIRST ARGUMENT> (STUB_REPORT_SCAN for OSV-Scanner, STUB_REPORT_DIR
# and STUB_REPORT_GIT for the two scans of gitleaks) or STUB_REPORT_FILE is copied to the path of the option --output-file
# (OSV-Scanner) or --report-path (gitleaks). With no such variable the tool writes no report.
prev=""
for arg in "\$@"; do
    if [[ "\${prev}" == "--output-file" || "\${prev}" == "--report-path" ]]; then
        report_variable="STUB_REPORT_\${1^^}"
        report_source="\${!report_variable:-\${STUB_REPORT_FILE:-}}"
        [[ -n "\${report_source}" ]] && cp "\${report_source}" "\${arg}"
    fi
    prev="\${arg}"
done
exit "\${STUB_EXIT:-0}"
STUB
}

mk_osv_stub_home() {
    local home="$1"
    mkdir -p "${home}/osv-scanner-${osv_version}"
    stub_script "osv-scanner version: ${osv_version}" "--version" yes >"${home}/osv-scanner-${osv_version}/osv-scanner"
    chmod +x "${home}/osv-scanner-${osv_version}/osv-scanner"
}

# make_versions <name> <key> <value> : a copy of versions.env with one value changed
make_versions() {
    local file="${work}/versions-$1.env"
    sed -e "s/^$2=.*/$2=$3/" "${VERSIONS_FILE}" >"${file}"
    echo "${file}"
}
# The stub is also the "download" of the install cases. A cache is used only if the sha256 of its binary is the pin
# (install_osv_scanner computes it again, with no marker file), so the stub cases use a copy of versions.env that has
# the sha256 of the stub as the pin. The real tools use the real pin.
stub_file="${work}/osv-download"
stub_script "osv-scanner version: ${osv_version}" "--version" yes >"${stub_file}"
stub_sha="$(sha256sum "${stub_file}" | cut -d' ' -f1)"
versions_osv="$(make_versions osvgood OSV_SCANNER_SHA256 "${stub_sha}")"
osv_home="${work}/osv-stub-home"
mk_osv_stub_home "${osv_home}"
sbom="${work}/sbom"
mkdir -p "${sbom}"
echo '{"bomFormat":"CycloneDX","specVersion":"1.5","version":1,"components":[{"type":"library","name":"qs","version":"6.15.1","purl":"pkg:npm/qs@6.15.1","bom-ref":"pkg:npm/qs@6.15.1"}]}' >"${sbom}/backend.cdx.json"
echo '{"bomFormat":"CycloneDX","specVersion":"1.5","version":1,"components":[]}' >"${sbom}/frontend.cdx.json"
echo "not an sbom file" >"${sbom}/notes.txt"
echo '{}' >"${sbom}/other.json"
args_file="${work}/osv-args.txt"

# The baseline files and the report files of the cases are made while the test runs (the repository has no copy of a
# record: the reports have an identifier, a package and a score only).
bl_dir="${work}/baselines"
mkdir -p "${bl_dir}"
# mk_baseline <name> [<line>...] : a baseline file with a comment and the lines (the file is printed)
mk_baseline() {
    local file="${bl_dir}/$1.txt"
    shift
    printf '# the baseline of a case of test-security-gates.sh\n' >"${file}"
    [[ $# -eq 0 ]] || printf '%s\n' "$@" >>"${file}"
    echo "${file}"
}
# osv_pkg <id> <name> <version> <score> [<label>] : one package of a report of OSV-Scanner (JSON) with one finding
osv_pkg() {
    local label_json=""
    [[ -n "${5:-}" ]] && label_json=",\"database_specific\":{\"severity\":\"$5\"}"
    printf '{"package":{"name":"%s","version":"%s","ecosystem":"npm"},"groups":[{"ids":["%s"],"aliases":["%s"],"max_severity":"%s"}],"vulnerabilities":[{"id":"%s"%s}]}' \
        "$2" "$3" "$1" "$1" "$4" "$1" "${label_json}"
}
# osv_report <file> [<package JSON>...] : the report of OSV-Scanner (the file is printed)
osv_report() {
    local file="$1" joined
    shift
    joined="$(IFS=,; echo "$*")"
    printf '{"results":[{"source":{"path":"build/sbom/frontend.cdx.json","type":"sbom"},"packages":[%s]}]}\n' "${joined}" >"${file}"
    echo "${file}"
}
osv_empty="$(osv_report "${work}/osv-report-empty.json")"
osv_medium="$(osv_report "${work}/osv-report-medium.json" "$(osv_pkg GHSA-4mjr-xmp4-gh2g qs 6.15.1 6.3)")"
osv_two="$(osv_report "${work}/osv-report-two.json" "$(osv_pkg GHSA-4mjr-xmp4-gh2g qs 6.15.1 6.3)" "$(osv_pkg GHSA-g3hv-75wg-m249 minimatch 10.2.6 6.9)")"
osv_critical="$(osv_report "${work}/osv-report-critical.json" "$(osv_pkg GHSA-aaaa-bbbb-cccc spring-web 9.9.9 9.8)")"
osv_high="$(osv_report "${work}/osv-report-high.json" "$(osv_pkg GHSA-dddd-eeee-ffff left-pad 1.0.0 7.5)")"
osv_label_only="$(osv_report "${work}/osv-report-label.json" "$(osv_pkg GHSA-gggg-hhhh-iiii left-pad 1.0.0 "" CRITICAL)")"
osv_unknown="$(osv_report "${work}/osv-report-unknown.json" "$(osv_pkg GHSA-jjjj-kkkk-llll left-pad 1.0.0 "")")"
bl_empty="$(mk_baseline osv-empty)"
bl_qs="$(mk_baseline osv-qs "GHSA-4mjr-xmp4-gh2g qs@6.15.1")"
bl_qs_minimatch="$(mk_baseline osv-qs-minimatch "GHSA-4mjr-xmp4-gh2g qs@6.15.1" "GHSA-g3hv-75wg-m249 minimatch@10.2.6")"

# run_vuln <baseline file> <report file or "-"> [<env VAR=value>...] : the recipe form with the stub of OSV-Scanner. The
# report is the file that the stub writes for the option --output-file ("-": the stub writes no report).
run_vuln() {
    local baseline="$1" report="$2"
    shift 2
    local report_env=()
    [[ "${report}" == "-" ]] || report_env=(STUB_REPORT_FILE="${report}")
    env OSV_SCANNER_HOME="${osv_home}" VERSIONS_FILE="${versions_osv}" STUB_ARGS_FILE="${args_file}" "${report_env[@]}" "$@" \
        "${GATES_DIR}/vuln-scan.sh" "${sbom}" "${baseline}"
}

# ACC-007, the cases of the level gate (the stub of OSV-Scanner gives the exit code and the report of each case)
expect 0 "THRESHOLD PASS" "vuln-scan: the stub has no finding (exit code 0, the empty baseline): the gate passes" \
    run_vuln "${bl_empty}" "${osv_empty}" STUB_EXIT=0 STUB_OUTPUT="No issues found"
expect 0 "THRESHOLD PASS" "vuln-scan: a finding that is in the baseline (Medium, exit code 1 of the tool): the gate passes with exit code 0 (ACC-007)" \
    run_vuln "${bl_qs}" "${osv_medium}" STUB_EXIT=1
expect 0 "Medium        baseline GHSA-4mjr-xmp4-gh2g qs@6.15.1 (CVSS 6.3)" "vuln-scan: the report shows the level, the identifier, the package and the state of the finding" \
    run_vuln "${bl_qs}" "${osv_medium}" STUB_EXIT=1
expect 0 "SUMMARY: OSV-Scanner: 2 finding(s) (0 Critical, 0 High, 2 Medium, 0 Low, 0 Informational, 0 Unknown); baseline osv-qs-minimatch.txt: 2 line(s)" "vuln-scan: the summary has the counts of the levels and of the lines of the baseline" \
    run_vuln "${bl_qs_minimatch}" "${osv_two}" STUB_EXIT=1
expect 1 "THRESHOLD STOP" "vuln-scan: a new finding (it is not in the baseline) stops the gate with exit code 1 (ACC-007)" \
    run_vuln "${bl_empty}" "${osv_medium}" STUB_EXIT=1
expect 1 "STOP: a new finding that is not in the baseline (Medium): GHSA-4mjr-xmp4-gh2g qs@6.15.1" "vuln-scan: the message names the new finding (the identifier and the package)" \
    run_vuln "${bl_empty}" "${osv_medium}" STUB_EXIT=1
expect 1 "STOP: a new finding that is not in the baseline (Medium): GHSA-g3hv-75wg-m249 minimatch@10.2.6" "vuln-scan: one new finding of two stops (the finding of the baseline does not hide it)" \
    run_vuln "${bl_qs}" "${osv_two}" STUB_EXIT=1
expect 1 "STOP: a finding that is Critical stops in each case: GHSA-aaaa-bbbb-cccc spring-web@9.9.9 (CVSS 9.8)" "vuln-scan: a new finding that is Critical (CVSS 9.8) stops the gate (ACC-007)" \
    run_vuln "${bl_empty}" "${osv_critical}" STUB_EXIT=1
expect 1 "STOP: a finding that is High stops in each case: GHSA-dddd-eeee-ffff left-pad@1.0.0 (CVSS 7.5)" "vuln-scan: a new finding that is High (CVSS 7.5) stops the gate (ACC-007)" \
    run_vuln "${bl_empty}" "${osv_high}" STUB_EXIT=1
expect 1 "ERROR OF THE FEATURE: the baseline has a line for a finding that is Critical" "vuln-scan: a Critical finding that has a line in the baseline stops the gate, and the message says that the baseline is wrong (ACC-007)" \
    run_vuln "$(mk_baseline osv-critical-line "GHSA-aaaa-bbbb-cccc spring-web@9.9.9")" "${osv_critical}" STUB_EXIT=1
expect 1 "ERROR OF THE FEATURE: the baseline has a line for a finding that is High" "vuln-scan: a High finding that has a line in the baseline stops the gate, and the message says that the baseline is wrong (ACC-007)" \
    run_vuln "$(mk_baseline osv-high-line "GHSA-dddd-eeee-ffff left-pad@1.0.0")" "${osv_high}" STUB_EXIT=1
expect 1 "GHSA-gggg-hhhh-iiii left-pad@1.0.0 (no score)" "vuln-scan: a record with no score and the label CRITICAL is Critical (the label of the database is used) and stops the gate" \
    run_vuln "$(mk_baseline osv-label-line "GHSA-gggg-hhhh-iiii left-pad@1.0.0")" "${osv_label_only}" STUB_EXIT=1
expect 0 "THRESHOLD PASS" "vuln-scan: a finding with no score and no label (Unknown) that is in the baseline passes (it is no stop by its level)" \
    run_vuln "$(mk_baseline osv-unknown-line "GHSA-jjjj-kkkk-llll left-pad@1.0.0")" "${osv_unknown}" STUB_EXIT=1
expect 1 "STOP: a new finding that is not in the baseline (Unknown)" "vuln-scan: a new finding with no score and no label (Unknown) stops the gate as a new finding" \
    run_vuln "${bl_empty}" "${osv_unknown}" STUB_EXIT=1
expect 0 "WARNING: the baseline line has no finding any more, so the baseline can be made smaller: GHSA-g3hv-75wg-m249 minimatch@10.2.6" "vuln-scan: a line of the baseline that has no finding any more is a warning, and the gate passes with exit code 0 (ACC-007, the old line)" \
    run_vuln "${bl_qs_minimatch}" "${osv_medium}" STUB_EXIT=1
expect 0 "1 old baseline line(s)" "vuln-scan: the result counts the old lines" \
    run_vuln "${bl_qs_minimatch}" "${osv_medium}" STUB_EXIT=1
expect 0 "WARNING: the baseline line has no finding any more" "vuln-scan: the old line is a warning also if the tool has no finding at all (exit code 0)" \
    run_vuln "${bl_qs}" "${osv_empty}" STUB_EXIT=0
expect 1 "THRESHOLD STOP" "vuln-scan: an old line and a new finding: the new finding stops the gate (the old line is only a warning)" \
    run_vuln "${bl_qs}" "${osv_high}" STUB_EXIT=1
expect_fail "FAILURE OF THE TOOL: OSV-Scanner ended with exit code 127" "vuln-scan: exit code 127 (general error, for example no network) of the tool stops the recipe, with a baseline that matches (ACC-005, ACC-007)" \
    run_vuln "${bl_qs}" "${osv_medium}" STUB_EXIT=127 STUB_OUTPUT="Error during extraction: max retries exceeded"
expect_fail "FAILURE OF THE TOOL: OSV-Scanner ended with exit code 128" "vuln-scan: exit code 128 (no packages found) stops the recipe" \
    run_vuln "${bl_empty}" "${osv_empty}" STUB_EXIT=128 STUB_OUTPUT="No package sources found"
expect_fail "FAILURE OF THE TOOL: OSV-Scanner ended with exit code 2" "vuln-scan: another code stops the recipe" \
    run_vuln "${bl_empty}" "${osv_empty}" STUB_EXIT=2
expect_not 1 "THRESHOLD" "vuln-scan: a failure of the tool does not start the level gate (no verdict of the gate, also if the stub wrote a report with no finding)" \
    run_vuln "${bl_empty}" "${osv_empty}" STUB_EXIT=127 STUB_OUTPUT="Total 0 packages affected by 0 known vulnerabilities (0 Critical, 0 High, 0 Medium, 0 Low, 0 Unknown) from 0 ecosystems."
expect_fail "FAILURE OF THE LEVEL GATE" "vuln-scan: a tool with exit code 1 that wrote no report stops the recipe (the gate has no input, so it does not pass)" \
    run_vuln "${bl_qs}" - STUB_EXIT=1
expect_fail "FAILURE OF THE LEVEL GATE" "vuln-scan: a tool with exit code 0 that wrote no report stops the recipe" \
    run_vuln "${bl_empty}" - STUB_EXIT=0
echo "this is not json" >"${work}/osv-report-broken.json"
expect_fail "the report file is not JSON" "vuln-scan: a report that is not JSON stops the recipe" \
    run_vuln "${bl_empty}" "${work}/osv-report-broken.json" STUB_EXIT=1
echo '{"no":"results"}' >"${work}/osv-report-form.json"
expect_fail "the report of OSV-Scanner has no list \`results\`" "vuln-scan: a report with another form stops the recipe" \
    run_vuln "${bl_empty}" "${work}/osv-report-form.json" STUB_EXIT=1
expect_fail "The baseline file does not exist" "vuln-scan: a baseline file that does not exist stops the recipe (the gate must read it)" \
    run_vuln "${bl_dir}/no-such-baseline.txt" "${osv_empty}" STUB_EXIT=0
expect_fail "the line is not of the form" "vuln-scan: a line of the baseline with a wrong form stops the recipe" \
    run_vuln "$(mk_baseline osv-badline "this is not an identifier")" "${osv_empty}" STUB_EXIT=0
expect_fail "the line is twice in the baseline" "vuln-scan: a line twice in the baseline stops the recipe" \
    run_vuln "$(mk_baseline osv-twice "GHSA-4mjr-xmp4-gh2g qs@6.15.1" "GHSA-4mjr-xmp4-gh2g qs@6.15.1")" "${osv_medium}" STUB_EXIT=1
expect 0 "Data: OSV.dev (https://osv.dev)" "vuln-scan: the attribution of the OSV data is in the output (the condition of the deviation)" \
    run_vuln "${bl_qs}" "${osv_medium}" STUB_EXIT=1
expect_not 1 "Data: OSV.dev" "vuln-scan: a failure of the tool prints no attribution of data (no report, no data)" \
    run_vuln "${bl_empty}" "${osv_empty}" STUB_EXIT=127

# The arguments of the scan: -L for each *.cdx.json file, no other file, no --licenses, the JSON report in a file
env OSV_SCANNER_HOME="${osv_home}" VERSIONS_FILE="${versions_osv}" STUB_ARGS_FILE="${args_file}" STUB_REPORT_FILE="${osv_empty}" STUB_EXIT=0 "${GATES_DIR}/vuln-scan.sh" "${sbom}" "${bl_empty}" >/dev/null 2>&1 || true
if [[ "$(grep -c '^-L$' "${args_file}")" == "2" ]] && grep -qx "${sbom}/backend.cdx.json" "${args_file}" \
    && grep -qx "${sbom}/frontend.cdx.json" "${args_file}" && ! grep -q 'notes.txt\|other.json' "${args_file}" \
    && ! grep -q -- '--licenses' "${args_file}" && [[ "$(sed -n 1,2p "${args_file}" | tr '\n' ' ')" == "scan source " ]] \
    && grep -qx -- '--format' "${args_file}" && grep -qx 'json' "${args_file}" && grep -qx -- '--output-file' "${args_file}"; then
    echo "ok   vuln-scan: the tool is started with 'scan source', --format json, --output-file, one -L for each *.cdx.json file, no other file and no --licenses"
    passed=$((passed + 1))
else
    echo "FAIL vuln-scan: the arguments of the tool are not the expected ones"
    sed -e 's/^/     | /' "${args_file}"
    failed=$((failed + 1))
fi

empty_sbom="${work}/sbom-empty"
mkdir -p "${empty_sbom}"
echo "x" >"${empty_sbom}/readme.txt"
expect_fail "has no *.cdx.json file" "vuln-scan: a folder with no *.cdx.json file stops the recipe (a scan of nothing must not pass)" \
    env OSV_SCANNER_HOME="${osv_home}" VERSIONS_FILE="${versions_osv}" "${GATES_DIR}/vuln-scan.sh" "${empty_sbom}" "${bl_empty}"
expect_fail "The folder of the SBOM files does not exist" "vuln-scan: a folder that does not exist stops the recipe" \
    env OSV_SCANNER_HOME="${osv_home}" VERSIONS_FILE="${versions_osv}" "${GATES_DIR}/vuln-scan.sh" "${work}/no-such-folder" "${bl_empty}"
expect_fail "Usage: vuln-scan.sh" "vuln-scan: no argument stops the recipe" env OSV_SCANNER_HOME="${osv_home}" VERSIONS_FILE="${versions_osv}" "${GATES_DIR}/vuln-scan.sh"
expect_fail "Usage: vuln-scan.sh" "vuln-scan: no baseline file argument stops the recipe (the form of feat-8 is not accepted)" \
    env OSV_SCANNER_HOME="${osv_home}" VERSIONS_FILE="${versions_osv}" "${GATES_DIR}/vuln-scan.sh" "${sbom}"

# The install with the sha256 check. A small file is the "download" (a file:// URL, no network). The versions file of
# the case has the sha256 of that file, so the pin is checked in each case.
install_home="${work}/osv-install-home"
started_file="${work}/osv-started.txt"
install_osv() { # install_osv <home> <url> <versions file>
    env OSV_SCANNER_HOME="$1" OSV_SCANNER_URL="$2" VERSIONS_FILE="$3" STUB_STARTED_FILE="${started_file}" \
        bash -c 'source "$1/_security.sh"; install_osv_scanner; echo "BIN=${OSV_SCANNER_BIN}"' _ "${GATES_DIR}"
}
expect 0 "sha256 is correct for the OSV-Scanner download" "install_osv_scanner: a file with the pinned sha256 is installed" \
    install_osv "${install_home}" "file://${stub_file}" "${versions_osv}"
if [[ -x "${install_home}/osv-scanner-${osv_version}/osv-scanner" && "$(sha256sum "${install_home}/osv-scanner-${osv_version}/osv-scanner" | cut -d' ' -f1)" == "${stub_sha}" \
    && ! -e "${install_home}/osv-scanner-${osv_version}/.sha256" ]]; then
    echo "ok   install_osv_scanner: the binary is executable and has the pinned sha256 (the install writes no marker file that a later run could trust)"
    passed=$((passed + 1))
else
    echo "FAIL install_osv_scanner: the binary is not in ${install_home}, or it has not the pin, or a marker file exists"
    failed=$((failed + 1))
fi
expect 0 "is already installed" "install_osv_scanner: a second call does not download again (the cache)" \
    install_osv "${install_home}" "file:///no/such/file" "${versions_osv}"
bad_home="${work}/osv-bad-home"
rm -f "${started_file}"
expect_fail "sha256 of the OSV-Scanner download is ${stub_sha}, but OSV_SCANNER_SHA256" "install_osv_scanner: a file with another sha256 stops the install" \
    install_osv "${bad_home}" "file://${stub_file}" "${VERSIONS_FILE}"
if [[ ! -e "${bad_home}/osv-scanner-${osv_version}" && ! -e "${started_file}" && -z "$(find "${bad_home}" -type f 2>/dev/null)" ]]; then
    echo "ok   install_osv_scanner: with a wrong sha256 the download is deleted, no binary is installed and the file never started"
    passed=$((passed + 1))
else
    echo "FAIL install_osv_scanner: a file stays after a wrong sha256, or the file started"
    find "${bad_home}" 2>/dev/null | sed -e 's/^/     | /'
    failed=$((failed + 1))
fi
other_version_file="${work}/osv-download-other-version"
stub_script "osv-scanner version: 0.0.1" "--version" yes >"${other_version_file}"
versions_other="$(make_versions osvother OSV_SCANNER_SHA256 "$(sha256sum "${other_version_file}" | cut -d' ' -f1)")"
expect_fail "but OSV_SCANNER_VERSION in" "install_osv_scanner: a binary with another version stops the install" \
    install_osv "${work}/osv-other-home" "file://${other_version_file}" "${versions_other}"
expect_fail "Download failed" "install_osv_scanner: a download that does not work stops the install" \
    install_osv "${work}/osv-nodl-home" "file:///no/such/file" "${versions_osv}"
expect_fail "OSV_SCANNER_SHA256 is not a sha256 value" "install_osv_scanner: a pin that is not a sha256 value stops the install" \
    install_osv "${work}/osv-badpin-home" "file://${stub_file}" "$(make_versions osvbadpin OSV_SCANNER_SHA256 xyz)"
expect_fail "OSV_SCANNER_VERSION is not an exact version" "install_osv_scanner: a version that is not exact stops the install" \
    install_osv "${work}/osv-badver-home" "file://${stub_file}" "$(make_versions osvbadver OSV_SCANNER_VERSION 2.7)"
# A cache is verified again (I1 of the review): the sha256 of the cached binary is computed at each start, and a marker
# file is not trusted. A cache whose binary has not the pin is not started. The same as install_oasdiff for a cache that
# does not match, the install downloads again and replaces it (the first case), and it stops if the download does not
# work (the second case).
mkdir -p "${work}/osv-stale-home"
cp -a "${osv_home}/osv-scanner-${osv_version}" "${work}/osv-stale-home/"
expect_fail "Download failed" "install_osv_scanner: a cache whose binary has not the pin is not used (the pin of the case is the real pin, the cache has the stub)" \
    install_osv "${work}/osv-stale-home" "file:///no/such/file" "${VERSIONS_FILE}"
tamper_ran="${work}/osv-tamper-ran.txt"
tamper_osv() { # tamper_osv <home> : a good install, then the binary is replaced by a file that records its start. The file .sha256 is the old marker (the pin).
    local home="$1" dir
    dir="${home}/osv-scanner-${osv_version}"
    rm -rf "${home}" "${tamper_ran}"
    install_osv "${home}" "file://${stub_file}" "${versions_osv}" >/dev/null 2>&1
    printf '#!/usr/bin/env bash\ntouch %q\necho "osv-scanner version: %s"\n' "${tamper_ran}" "${osv_version}" >"${dir}/osv-scanner"
    printf '%s\n' "${stub_sha}" >"${dir}/.sha256"
    chmod +x "${dir}/osv-scanner"
}
tamper_osv "${work}/osv-tamper-home"
expect 0 "has not the pinned sha256" "install_osv_scanner: a changed cached binary (the marker file still has the pin) is replaced by a new download" \
    install_osv "${work}/osv-tamper-home" "file://${stub_file}" "${versions_osv}"
if [[ ! -e "${tamper_ran}" && "$(sha256sum "${work}/osv-tamper-home/osv-scanner-${osv_version}/osv-scanner" | cut -d' ' -f1)" == "${stub_sha}" ]]; then
    echo "ok   install_osv_scanner: the changed binary never started, and the binary in the cache has the pin after the install"
    passed=$((passed + 1))
else
    echo "FAIL install_osv_scanner: the changed binary started, or the cache has not the pin after the install"
    failed=$((failed + 1))
fi
tamper_osv "${work}/osv-tamper-home2"
expect_fail "Download failed" "install_osv_scanner: a changed cached binary and a download that does not work stop the install" \
    install_osv "${work}/osv-tamper-home2" "file:///no/such/file" "${versions_osv}"
if [[ ! -e "${tamper_ran}" ]]; then
    echo "ok   install_osv_scanner: the changed binary never started when the install stopped"
    passed=$((passed + 1))
else
    echo "FAIL install_osv_scanner: the changed binary started"
    failed=$((failed + 1))
fi
tamper_osv "${work}/osv-tamper-home3"
expect_fail "sha256 of the OSV-Scanner download is" "install_osv_scanner: a changed cached binary and a download with another sha256 stop the install" \
    install_osv "${work}/osv-tamper-home3" "file://${stub_file}" "$(make_versions osvother2 OSV_SCANNER_SHA256 "$(printf '%064d' 1)")"
if [[ ! -e "${tamper_ran}" ]]; then
    echo "ok   install_osv_scanner: the changed binary never started (a download with another sha256)"
    passed=$((passed + 1))
else
    echo "FAIL install_osv_scanner: the changed binary started"
    failed=$((failed + 1))
fi

# The REAL OSV-Scanner (the download of the release, the sha256 of the pin) without the network: a proxy that
# refuses the connection. This is the real failure of the tool (no network). The files of the SBOM have one package.
# The real binary is installed FIRST, here, with the network and the sha256 check (install_osv_scanner, no proxy
# variable is set in this shell). The proxy is set only for the start of the scan (the `env` of the case below), and
# not for the install: on a clean machine (a CI runner) build/tools/ has no binary, and a proxy that refuses the
# connection would also stop the download of the binary, which is not the case that this test shows.
real_osv_home="${OSV_SCANNER_HOME:-${REPO_ROOT}/build/tools}"
# The cases up to the matching `fi` need the real OSV-Scanner (not indented, so the here-documents stay as they are).
if real_install "OSV-Scanner" install_osv_scanner OSV_SCANNER_BIN OSV_SCANNER_HOME "${real_osv_home}"; then
real_osv_bin="${REAL_BIN}"
check "the real OSV-Scanner has the pinned version ${osv_version}" test "$("${real_osv_bin}" --version | head -n 1)" == "osv-scanner version: ${osv_version}"
cat >"${work}/sbom-real.cdx.json" <<'JSON'
{"bomFormat":"CycloneDX","specVersion":"1.5","version":1,"components":[{"type":"library","name":"qs","version":"6.15.1","purl":"pkg:npm/qs@6.15.1","bom-ref":"pkg:npm/qs@6.15.1"}]}
JSON
mkdir -p "${work}/sbom-real"
cp "${work}/sbom-real.cdx.json" "${work}/sbom-real/frontend.cdx.json"
expect_fail "FAILURE OF THE TOOL: OSV-Scanner ended with exit code 127" "vuln-scan: the REAL OSV-Scanner without the network (a proxy that refuses the connection) ends with exit code 127, and the recipe stops (ACC-005)" \
    env OSV_SCANNER_HOME="${real_osv_home}" HTTPS_PROXY="http://127.0.0.1:9" HTTP_PROXY="http://127.0.0.1:9" https_proxy="http://127.0.0.1:9" http_proxy="http://127.0.0.1:9" \
    "${GATES_DIR}/vuln-scan.sh" "${work}/sbom-real" "${bl_empty}"
mkdir -p "${work}/sbom-nopackage"
echo '{"bomFormat":"CycloneDX","specVersion":"1.5","version":1,"components":[]}' >"${work}/sbom-nopackage/frontend.cdx.json"
expect_fail "FAILURE OF THE TOOL: OSV-Scanner ended with exit code 128" "vuln-scan: the REAL OSV-Scanner with an SBOM that has no package ends with exit code 128, and the recipe stops (a scan of nothing must not pass)" \
    env OSV_SCANNER_HOME="${real_osv_home}" "${GATES_DIR}/vuln-scan.sh" "${work}/sbom-nopackage" "${bl_empty}"
mkdir -p "${work}/sbom-broken"
echo '{this is not json' >"${work}/sbom-broken/frontend.cdx.json"
expect_fail "FAILURE OF THE TOOL: OSV-Scanner ended with exit code 127" "vuln-scan: the REAL OSV-Scanner with an SBOM file that cannot be read ends with exit code 127, and the recipe stops (ACC-005)" \
    env OSV_SCANNER_HOME="${real_osv_home}" "${GATES_DIR}/vuln-scan.sh" "${work}/sbom-broken" "${bl_empty}"
fi

# ======================================================================================================================
section "Part 3: secret-scan.sh (gitleaks)"

# A stub of gitleaks: `gitleaks version` gives the version, and each other start gives STUB_OUTPUT and STUB_EXIT.
# The stub is in an archive (also the "download" of the install cases). The pin of the stub cases is the sha256 of
# that archive (versions_gl, a copy of versions.env), and a cache of the stub has the archive and the binary of the
# archive, because install_gitleaks verifies the cache against the pin again (no marker file).
gl_pkg="${work}/gl-pkg"
mkdir -p "${gl_pkg}"
stub_script "${gitleaks_version}" "version" >"${gl_pkg}/gitleaks"
chmod +x "${gl_pkg}/gitleaks"
echo "stub license" >"${gl_pkg}/LICENSE"
gl_archive="${work}/gitleaks-stub.tar.gz"
tar -C "${gl_pkg}" -czf "${gl_archive}" gitleaks LICENSE
gl_archive_sha="$(sha256sum "${gl_archive}" | cut -d' ' -f1)"
versions_gl="$(make_versions glgood GITLEAKS_SHA256 "${gl_archive_sha}")"
mk_gitleaks_stub_home() {
    local home="$1"
    mkdir -p "${home}/gitleaks-${gitleaks_version}"
    cp "${gl_pkg}/gitleaks" "${gl_pkg}/LICENSE" "${home}/gitleaks-${gitleaks_version}/"
    cp "${gl_archive}" "${home}/gitleaks-${gitleaks_version}/archive.tar.gz"
}

# The fake secret is made while the test runs (the repository has no value that looks like a secret). The value has the
# form of a Stripe key, which the default rules of gitleaks find. It is not a key of an account.
fake_secret_line() { printf 'stripe = "sk_live_%s"\n' "51H8jT2LkqW9xYzAbCdEfGhIjKlMn"; }

# mk_repo <dir> : a git repository with the commit `base` on the branch dev (the reference refs/remotes/origin/dev), the
# config tools/security/gitleaks.toml of this repository, and the branch `feature` that has the work tree
mk_repo() {
    local dir="$1"
    rm -rf "${dir}"
    mkdir -p "${dir}/tools/security"
    cp "${real_config}" "${dir}/tools/security/gitleaks.toml"
    cp "${real_gl_baseline}" "${dir}/tools/security/gitleaks-baseline.txt"
    (
        cd "${dir}"
        git init --quiet --initial-branch=dev
        git config user.name "Gate Test"
        git config user.email "gate-test@example.invalid"
        git config commit.gpgsign false
        echo "hello" >readme.txt
        git add -A
        git commit --quiet --no-verify -m "base"
        git update-ref refs/remotes/origin/dev HEAD
        git checkout --quiet -b feature
    )
}
commit_all() { (cd "$1" && git add -A && git commit --quiet --no-verify -m "$2"); }
run_secret() { # run_secret <repo> [env VAR=value...] : the recipe form, base origin/dev, the config and the baseline file of the repository
    local repo="$1"
    shift
    env GATE_WORK_ROOT="${repo}" "$@" "${GATES_DIR}/secret-scan.sh" origin/dev tools/security/gitleaks.toml tools/security/gitleaks-baseline.txt
}
# set_gl_baseline <repo> [<line>...] : the baseline file of the repository (a comment and the lines)
set_gl_baseline() {
    local repo="$1"
    shift
    printf '# the baseline of a case of test-security-gates.sh\n' >"${repo}/tools/security/gitleaks-baseline.txt"
    [[ $# -eq 0 ]] || printf '%s\n' "$@" >>"${repo}/tools/security/gitleaks-baseline.txt"
}
# gl_report <file> [<fingerprint>...] : the report of gitleaks (JSON) with one entry for each fingerprint (no secret in it)
gl_report() {
    local file="$1" entries="" fingerprint
    shift
    for fingerprint in "$@"; do
        entries+="${entries:+,}{\"RuleID\":\"stripe-access-token\",\"Fingerprint\":\"${fingerprint}\"}"
    done
    printf '[%s]\n' "${entries}" >"${file}"
}

# --- the stub
gl_home="${work}/gitleaks-stub-home"
mk_gitleaks_stub_home "${gl_home}"
stub_repo="${work}/repo-stub"
mk_repo "${stub_repo}"
echo "some work" >"${stub_repo}/work.txt"
commit_all "${stub_repo}" "work"
gl_args="${work}/gitleaks-args.txt"

# ACC-007, the cases of the level gate (the stub of gitleaks gives the exit code and the report of each scan)
gl_fp_files="config.txt:stripe-access-token:1"
gl_fp_history="1111111111111111111111111111111111111111:config.txt:stripe-access-token:1"
gl_report "${work}/gl-report-files.json" "${gl_fp_files}"
gl_report "${work}/gl-report-history.json" "${gl_fp_history}"
gl_report "${work}/gl-report-none.json"
gl_stub_findings=(STUB_REPORT_DIR="${work}/gl-report-files.json" STUB_REPORT_GIT="${work}/gl-report-history.json")
expect 0 "REPORT: files: 0 finding(s); history origin/dev..HEAD: 0 finding(s)" "secret-scan: the stub has no finding (exit code 0, the report has no entry)" \
    run_secret "${stub_repo}" GITLEAKS_HOME="${gl_home}" VERSIONS_FILE="${versions_gl}" STUB_EXIT=0 STUB_OUTPUT="INF no leaks found" STUB_REPORT_FILE="${work}/gl-report-none.json"
expect 0 "THRESHOLD PASS" "secret-scan: the stub has no finding and writes no report (a clean run: the report is empty): the gate passes" \
    run_secret "${stub_repo}" GITLEAKS_HOME="${gl_home}" VERSIONS_FILE="${versions_gl}" STUB_EXIT=0 STUB_OUTPUT="INF no leaks found"
expect 1 "REPORT: files: 3 finding(s); history origin/dev..HEAD: 3 finding(s)" "secret-scan: the stub has findings (exit code 2) that are not in the baseline: the recipe prints the counts and stops with exit code 1 (ACC-007)" \
    run_secret "${stub_repo}" GITLEAKS_HOME="${gl_home}" VERSIONS_FILE="${versions_gl}" STUB_EXIT=2 STUB_OUTPUT="WRN leaks found: 3" "${gl_stub_findings[@]}"
expect 1 "FINDINGS (exit code 2)" "secret-scan: a finding says that the level gate decides next (the gate does not pass by itself)" \
    run_secret "${stub_repo}" GITLEAKS_HOME="${gl_home}" VERSIONS_FILE="${versions_gl}" STUB_EXIT=2 STUB_OUTPUT="WRN leaks found: 1" "${gl_stub_findings[@]}"
expect 1 "THRESHOLD STOP" "secret-scan: a new finding (a secret that is not in the baseline) stops the gate with exit code 1 (ACC-007)" \
    run_secret "${stub_repo}" GITLEAKS_HOME="${gl_home}" VERSIONS_FILE="${versions_gl}" STUB_EXIT=2 STUB_OUTPUT="WRN leaks found: 1" "${gl_stub_findings[@]}"
expect 1 "STOP: a new finding that is not in the baseline (Unrated): ${gl_fp_files} (rule stripe-access-token)" "secret-scan: the message names the fingerprint of the new finding (and no secret)" \
    run_secret "${stub_repo}" GITLEAKS_HOME="${gl_home}" VERSIONS_FILE="${versions_gl}" STUB_EXIT=2 STUB_OUTPUT="WRN leaks found: 1" "${gl_stub_findings[@]}"
set_gl_baseline "${stub_repo}" "${gl_fp_files}" "${gl_fp_history}"
expect 0 "THRESHOLD PASS" "secret-scan: the findings are in the baseline (the fingerprints of the files and of the history): the gate passes with exit code 0 (ACC-007)" \
    run_secret "${stub_repo}" GITLEAKS_HOME="${gl_home}" VERSIONS_FILE="${versions_gl}" STUB_EXIT=2 STUB_OUTPUT="WRN leaks found: 1" "${gl_stub_findings[@]}"
expect 0 "Unrated       baseline ${gl_fp_files} (rule stripe-access-token)" "secret-scan: gitleaks has no severity, so the level of a finding is Unrated, and the report shows the state baseline" \
    run_secret "${stub_repo}" GITLEAKS_HOME="${gl_home}" VERSIONS_FILE="${versions_gl}" STUB_EXIT=2 STUB_OUTPUT="WRN leaks found: 1" "${gl_stub_findings[@]}"
set_gl_baseline "${stub_repo}" "${gl_fp_files}"
expect 1 "STOP: a new finding that is not in the baseline (Unrated): ${gl_fp_history}" "secret-scan: a baseline with the fingerprint of the files only: the finding of the history is new and stops the gate" \
    run_secret "${stub_repo}" GITLEAKS_HOME="${gl_home}" VERSIONS_FILE="${versions_gl}" STUB_EXIT=2 STUB_OUTPUT="WRN leaks found: 1" "${gl_stub_findings[@]}"
set_gl_baseline "${stub_repo}" "${gl_fp_files}" "${gl_fp_history}" "config.txt:stripe-access-token:99"
expect 0 "WARNING: the baseline line has no finding any more, so the baseline can be made smaller: config.txt:stripe-access-token:99" "secret-scan: a line of the baseline that has no finding any more is a warning, and the gate passes with exit code 0 (ACC-007, the old line)" \
    run_secret "${stub_repo}" GITLEAKS_HOME="${gl_home}" VERSIONS_FILE="${versions_gl}" STUB_EXIT=2 STUB_OUTPUT="WRN leaks found: 1" "${gl_stub_findings[@]}"
set_gl_baseline "${stub_repo}" "${gl_fp_files}"
expect 0 "WARNING: the baseline line has no finding any more" "secret-scan: the old line is a warning also if the tool has no finding at all (exit code 0)" \
    run_secret "${stub_repo}" GITLEAKS_HOME="${gl_home}" VERSIONS_FILE="${versions_gl}" STUB_EXIT=0 STUB_OUTPUT="INF no leaks found"
set_gl_baseline "${stub_repo}"
expect_fail "FAILURE OF THE LEVEL GATE" "secret-scan: a tool with exit code 2 (findings) that wrote no report stops the recipe (the gate has no input, so it does not pass)" \
    run_secret "${stub_repo}" GITLEAKS_HOME="${gl_home}" VERSIONS_FILE="${versions_gl}" STUB_EXIT=2 STUB_OUTPUT="WRN leaks found: 1"
echo '{"not":"a list"}' >"${work}/gl-report-form.json"
expect_fail "the report of gitleaks is not a list" "secret-scan: a report with another form stops the recipe" \
    run_secret "${stub_repo}" GITLEAKS_HOME="${gl_home}" VERSIONS_FILE="${versions_gl}" STUB_EXIT=2 STUB_OUTPUT="WRN leaks found: 1" STUB_REPORT_FILE="${work}/gl-report-form.json"
rm "${stub_repo}/tools/security/gitleaks-baseline.txt"
expect_fail "The baseline file does not exist" "secret-scan: a baseline file that does not exist stops the recipe (the gate must read it)" \
    run_secret "${stub_repo}" GITLEAKS_HOME="${gl_home}" VERSIONS_FILE="${versions_gl}" STUB_EXIT=0
set_gl_baseline "${stub_repo}"
expect_fail "FAILURE OF THE TOOL: gitleaks (files) ended with exit code 1" "secret-scan: exit code 1 of the tool (a fatal error) stops the recipe (ACC-005)" \
    run_secret "${stub_repo}" GITLEAKS_HOME="${gl_home}" VERSIONS_FILE="${versions_gl}" STUB_EXIT=1 STUB_OUTPUT="FTL unable to load gitleaks config"
expect_fail "FAILURE OF THE TOOL: gitleaks (files) ended with exit code 126" "secret-scan: exit code 126 of the tool (a wrong flag) stops the recipe" \
    run_secret "${stub_repo}" GITLEAKS_HOME="${gl_home}" VERSIONS_FILE="${versions_gl}" STUB_EXIT=126
expect_fail "no sign of a finding" "secret-scan: exit code 2 with no text 'leaks found' (a crash) stops the recipe" \
    run_secret "${stub_repo}" GITLEAKS_HOME="${gl_home}" VERSIONS_FILE="${versions_gl}" STUB_EXIT=2 STUB_OUTPUT="panic: runtime error: index out of range"
expect_fail "has an error line" "secret-scan: an ERR line with exit code 0 (git cannot read the range) stops the recipe" \
    run_secret "${stub_repo}" GITLEAKS_HOME="${gl_home}" VERSIONS_FILE="${versions_gl}" STUB_EXIT=0 STUB_OUTPUT="11:49AM ERR [git] fatal: ambiguous argument"
expect_not 1 "REPORT:" "secret-scan: a failure prints no REPORT line" \
    run_secret "${stub_repo}" GITLEAKS_HOME="${gl_home}" VERSIONS_FILE="${versions_gl}" STUB_EXIT=1
expect_not 1 "THRESHOLD" "secret-scan: a failure of the tool does not start the level gate (no verdict of the gate, also with a baseline that matches)" \
    run_secret "${stub_repo}" GITLEAKS_HOME="${gl_home}" VERSIONS_FILE="${versions_gl}" STUB_EXIT=1 "${gl_stub_findings[@]}"
# The arguments: the options that the plan and the script need (the last start is the scan of the history)
run_secret "${stub_repo}" GITLEAKS_HOME="${gl_home}" VERSIONS_FILE="${versions_gl}" STUB_EXIT=0 STUB_ARGS_FILE="${gl_args}" >/dev/null 2>&1 || true
gl_all_ok=1
for option in git "$(git -C "${stub_repo}" rev-parse --absolute-git-dir)" --exit-code 2 --redact --ignore-gitleaks-allow --gitleaks-ignore-path --log-opts=origin/dev..HEAD --no-color --report-format json --report-path; do
    grep -qxF -- "${option}" "${gl_args}" || gl_all_ok=0
done
if [[ ${gl_all_ok} -eq 1 ]] && grep -qx -- "--config" "${gl_args}" && grep -q 'tools/security/gitleaks.toml$' "${gl_args}"; then
    echo "ok   secret-scan: the tool is started with --config, --exit-code 2, --redact, --ignore-gitleaks-allow, --gitleaks-ignore-path, the JSON report (--report-format json, --report-path) and the log options base..HEAD"
    passed=$((passed + 1))
else
    echo "FAIL secret-scan: the arguments of the tool are not the expected ones"
    sed -e 's/^/     | /' "${gl_args}"
    failed=$((failed + 1))
fi
expect_fail "The base 'origin/nothing' does not exist" "secret-scan: a base that does not exist stops the recipe" \
    env GATE_WORK_ROOT="${stub_repo}" GITLEAKS_HOME="${gl_home}" VERSIONS_FILE="${versions_gl}" "${GATES_DIR}/secret-scan.sh" origin/nothing tools/security/gitleaks.toml tools/security/gitleaks-baseline.txt
expect_fail "The gitleaks config does not exist" "secret-scan: a config that does not exist stops the recipe" \
    env GATE_WORK_ROOT="${stub_repo}" GITLEAKS_HOME="${gl_home}" VERSIONS_FILE="${versions_gl}" "${GATES_DIR}/secret-scan.sh" origin/dev tools/security/none.toml tools/security/gitleaks-baseline.txt
expect_fail "Usage: secret-scan.sh" "secret-scan: no argument stops the recipe" env GATE_WORK_ROOT="${stub_repo}" GITLEAKS_HOME="${gl_home}" VERSIONS_FILE="${versions_gl}" "${GATES_DIR}/secret-scan.sh"

# --- a shallow clone (the history of the pull request is not known)
shallow_src="${work}/repo-shallow-src"
mk_repo "${shallow_src}"
echo "one" >"${shallow_src}/one.txt"
commit_all "${shallow_src}" "one"
echo "two" >"${shallow_src}/two.txt"
commit_all "${shallow_src}" "two"
shallow="${work}/repo-shallow"
git clone --quiet --depth 1 --branch feature "file://${shallow_src}" "${shallow}" 2>/dev/null
(cd "${shallow}" && git fetch --quiet --depth 1 origin dev:refs/remotes/origin/dev 2>/dev/null)
expect_fail "This is a shallow clone, and it has no merge base" "secret-scan: a shallow clone with no merge base of the base and HEAD stops the recipe (fetch-depth: 0)" \
    env GATE_WORK_ROOT="${shallow}" GITLEAKS_HOME="${gl_home}" VERSIONS_FILE="${versions_gl}" "${GATES_DIR}/secret-scan.sh" origin/dev tools/security/gitleaks.toml tools/security/gitleaks-baseline.txt
full="${work}/repo-full"
git clone --quiet "file://${shallow_src}" "${full}" 2>/dev/null
expect 0 "Base: origin/dev, merge base:" "secret-scan: a clone with the full history finds the merge base (stub)" \
    env GATE_WORK_ROOT="${full}" GITLEAKS_HOME="${gl_home}" VERSIONS_FILE="${versions_gl}" STUB_EXIT=0 "${GATES_DIR}/secret-scan.sh" origin/dev tools/security/gitleaks.toml tools/security/gitleaks-baseline.txt

# --- the install of gitleaks with the sha256 check (a file:// URL, no network)
gl_started="${work}/gl-started.txt"
install_gl() { # install_gl <home> <url> <versions file>
    env GITLEAKS_HOME="$1" GITLEAKS_URL="$2" VERSIONS_FILE="$3" STUB_STARTED_FILE="${gl_started}" \
        bash -c 'source "$1/_security.sh"; install_gitleaks; echo "BIN=${GITLEAKS_BIN}"' _ "${GATES_DIR}"
}
expect 0 "sha256 is correct for the gitleaks download" "install_gitleaks: an archive with the pinned sha256 is installed" \
    install_gl "${work}/gl-install-home" "file://${gl_archive}" "${versions_gl}"
if [[ -x "${work}/gl-install-home/gitleaks-${gitleaks_version}/gitleaks" && -f "${work}/gl-install-home/gitleaks-${gitleaks_version}/LICENSE" \
    && "$(sha256sum "${work}/gl-install-home/gitleaks-${gitleaks_version}/archive.tar.gz" | cut -d' ' -f1)" == "${gl_archive_sha}" \
    && ! -e "${work}/gl-install-home/gitleaks-${gitleaks_version}/.sha256" ]]; then
    echo "ok   install_gitleaks: the folder has gitleaks, LICENSE and the archive with the pinned sha256 (no marker file that a later run could trust)"
    passed=$((passed + 1))
else
    echo "FAIL install_gitleaks: the folder ${work}/gl-install-home does not have the expected files"
    failed=$((failed + 1))
fi
expect 0 "is already installed" "install_gitleaks: a second call does not download again (the cache)" \
    install_gl "${work}/gl-install-home" "file:///no/such/file" "${versions_gl}"
rm -f "${gl_started}"
expect_fail "sha256 of the gitleaks download is ${gl_archive_sha}, but GITLEAKS_SHA256" "install_gitleaks: an archive with another sha256 stops the install" \
    install_gl "${work}/gl-bad-home" "file://${gl_archive}" "${VERSIONS_FILE}"
if [[ -z "$(find "${work}/gl-bad-home" -type f 2>/dev/null)" && ! -e "${gl_started}" ]]; then
    echo "ok   install_gitleaks: with a wrong sha256 the download is deleted, nothing is unpacked and the file never started"
    passed=$((passed + 1))
else
    echo "FAIL install_gitleaks: a file stays after a wrong sha256"
    failed=$((failed + 1))
fi
expect_fail "Download failed" "install_gitleaks: a download that does not work stops the install" \
    install_gl "${work}/gl-nodl-home" "file:///no/such/file" "${versions_gl}"
echo "not an archive" >"${work}/gl-notar"
expect_fail "has not the files gitleaks and LICENSE" "install_gitleaks: a file that is not the archive (with the right sha256) stops the install" \
    install_gl "${work}/gl-notar-home" "file://${work}/gl-notar" "$(make_versions glnotar GITLEAKS_SHA256 "$(sha256sum "${work}/gl-notar" | cut -d' ' -f1)")"

# A cache is verified again against the pin (I1 of the review): the archive has the pin, and the binary is the file of
# the archive. A marker file is not trusted. Each cache that does not match is not started, and it is replaced by a new
# download, as install_oasdiff does (the cases 1 to 3), and a download that does not work stops the install (the case 4).
gl_tamper_ran="${work}/gl-tamper-ran.txt"
tamper_gl() { # tamper_gl <home> <what: binary | archive | no-archive>
    local home="$1" what="$2" dir
    dir="${home}/gitleaks-${gitleaks_version}"
    rm -rf "${home}" "${gl_tamper_ran}"
    install_gl "${home}" "file://${gl_archive}" "${versions_gl}" >/dev/null 2>&1
    case "${what}" in
        binary)
            printf '#!/usr/bin/env bash\ntouch %q\necho "%s"\n' "${gl_tamper_ran}" "${gitleaks_version}" >"${dir}/gitleaks"
            chmod +x "${dir}/gitleaks"
            ;;
        archive) printf 'x' >>"${dir}/archive.tar.gz" ;;
        no-archive) rm -f "${dir}/archive.tar.gz" ;;
    esac
    printf '%s\n' "${gl_archive_sha}" >"${dir}/.sha256"
}
for what in binary archive no-archive; do
    tamper_gl "${work}/gl-tamper-${what}" "${what}"
    expect 0 "does not match the pinned sha256" "install_gitleaks: a cache with a changed ${what/no-archive/missing archive} is replaced by a new download (the marker file still has the pin)" \
        install_gl "${work}/gl-tamper-${what}" "file://${gl_archive}" "${versions_gl}"
    if [[ ! -e "${gl_tamper_ran}" ]] && _gitleaks_cache_matches_pin "${work}/gl-tamper-${what}/gitleaks-${gitleaks_version}" "${gl_archive_sha}"; then
        echo "ok   install_gitleaks: the changed ${what/no-archive/missing archive} never started, and the cache matches the pin after the install"
        passed=$((passed + 1))
    else
        echo "FAIL install_gitleaks: the changed ${what} started, or the cache does not match the pin after the install"
        failed=$((failed + 1))
    fi
done
tamper_gl "${work}/gl-tamper-stop" binary
expect_fail "Download failed" "install_gitleaks: a changed cached binary and a download that does not work stop the install" \
    install_gl "${work}/gl-tamper-stop" "file:///no/such/file" "${versions_gl}"
if [[ ! -e "${gl_tamper_ran}" ]]; then
    echo "ok   install_gitleaks: the changed binary never started when the install stopped"
    passed=$((passed + 1))
else
    echo "FAIL install_gitleaks: the changed binary started"
    failed=$((failed + 1))
fi
check "_gitleaks_cache_matches_pin: a good cache matches, and the same cache with another pin does not" \
    bash -c 'source "$1/_security.sh"; _gitleaks_cache_matches_pin "$2" "$3" && ! _gitleaks_cache_matches_pin "$2" "$(printf "%064d" 1)"' _ "${GATES_DIR}" "${gl_home}/gitleaks-${gitleaks_version}" "${gl_archive_sha}"

# --- the REAL gitleaks in temporary repositories. The real binary is the install of the gate (build/tools/). It is
# installed here, with the network and the sha256 check, before the cases start the script (no case depends on a binary
# that an earlier run left in build/tools/, and no case sets a proxy or blocks the network).
# The cases up to the matching `fi` need the real gitleaks (not indented, so the here-documents stay as they are).
if real_install "gitleaks" install_gitleaks GITLEAKS_BIN GITLEAKS_HOME "${GITLEAKS_HOME:-${REPO_ROOT}/build/tools}"; then
real_gl="${REAL_BIN}"
check "the real gitleaks has the pinned version ${gitleaks_version}" test "$("${real_gl}" version)" == "${gitleaks_version}"

r="${work}/repo-clean"
mk_repo "${r}"
echo "some work" >"${r}/work.txt"
commit_all "${r}" "work"
expect 0 "REPORT: files: 0 finding(s); history origin/dev..HEAD: 0 finding(s)" "secret-scan (real gitleaks): a repository with no secret has no finding" run_secret "${r}"
expect 0 "THRESHOLD PASS" "secret-scan (real gitleaks): a repository with no secret passes the level gate (the baseline of this repository, which has no line)" run_secret "${r}"

r="${work}/repo-secret-file"
mk_repo "${r}"
fake_secret_line >"${r}/config.txt"
commit_all "${r}" "add a config"
expect 1 "REPORT: files: 1 finding(s); history origin/dev..HEAD: 1 finding(s)" "secret-scan (real gitleaks): a secret in a committed file is a finding in the files and in the history, and it is not in the baseline, so the recipe stops with exit code 1 (ACC-007)" run_secret "${r}"
expect 1 "FINDINGS (exit code 2)" "secret-scan (real gitleaks): the finding has the exit code 2 of the tool" run_secret "${r}"
expect_not 1 "sk_live_51H8" "secret-scan (real gitleaks): the secret is redacted in the report" run_secret "${r}"
expect 1 "RuleID:      stripe-access-token" "secret-scan (real gitleaks): the report names the rule" run_secret "${r}"
expect 1 "File:        config.txt" "secret-scan (real gitleaks): the report names the file (a path relative to the repository)" run_secret "${r}"
expect 1 "THRESHOLD STOP" "secret-scan (real gitleaks): the new finding stops the level gate" run_secret "${r}"
secret_head="$(git -C "${r}" rev-parse HEAD)"
set_gl_baseline "${r}" "config.txt:stripe-access-token:1" "${secret_head}:config.txt:stripe-access-token:1"
expect 0 "THRESHOLD PASS" "secret-scan (real gitleaks): the baseline has the two fingerprints of the secret (the files and the history): the recipe passes with exit code 0 (ACC-007, the finding of the baseline)" run_secret "${r}"
expect 0 "Unrated       baseline config.txt:stripe-access-token:1 (rule stripe-access-token)" "secret-scan (real gitleaks): the report of the level gate shows the finding with the state baseline" run_secret "${r}"
set_gl_baseline "${r}" "config.txt:stripe-access-token:1"
expect 1 "STOP: a new finding that is not in the baseline (Unrated): ${secret_head}:config.txt:stripe-access-token:1" "secret-scan (real gitleaks): a baseline with the fingerprint of the files only: the finding of the history is new and stops the recipe" run_secret "${r}"
set_gl_baseline "${r}" "config.txt:stripe-access-token:1" "${secret_head}:config.txt:stripe-access-token:1" "old.txt:stripe-access-token:7"
expect 0 "WARNING: the baseline line has no finding any more, so the baseline can be made smaller: old.txt:stripe-access-token:7" "secret-scan (real gitleaks): a line of the baseline that has no finding any more is a warning, and the recipe passes (ACC-007, the old line)" run_secret "${r}"

r="${work}/repo-secret-history"
mk_repo "${r}"
fake_secret_line >"${r}/config.txt"
commit_all "${r}" "add a config"
git -C "${r}" rm --quiet config.txt
commit_all "${r}" "remove the config"
expect 1 "REPORT: files: 0 finding(s); history origin/dev..HEAD: 1 finding(s)" "secret-scan (real gitleaks): a secret that is only in the history of the pull request (deleted in a later commit) is a finding of the history" run_secret "${r}"

r="${work}/repo-secret-base"
mk_repo "${r}"
git -C "${r}" checkout --quiet dev
fake_secret_line >"${r}/config.txt"
commit_all "${r}" "a secret in the base"
git -C "${r}" update-ref refs/remotes/origin/dev HEAD
git -C "${r}" checkout --quiet feature
git -C "${r}" reset --quiet --hard origin/dev
echo "pr work" >"${r}/work.txt"
commit_all "${r}" "work"
expect 1 "REPORT: files: 1 finding(s); history origin/dev..HEAD: 0 finding(s)" "secret-scan (real gitleaks): a secret in the base is a finding of the files, and not of the history of the pull request (the range is base..HEAD)" run_secret "${r}"

r="${work}/repo-secret-untracked"
mk_repo "${r}"
fake_secret_line >"${r}/not-committed.txt"
expect 1 "REPORT: files: 1 finding(s); history origin/dev..HEAD: 0 finding(s)" "secret-scan (real gitleaks): a secret in a file that is not committed is a finding of the files" run_secret "${r}"

r="${work}/repo-secret-ignored"
mk_repo "${r}"
echo "ignored.txt" >"${r}/.gitignore"
commit_all "${r}" "ignore"
fake_secret_line >"${r}/ignored.txt"
expect 0 "REPORT: files: 0 finding(s); history origin/dev..HEAD: 0 finding(s)" "secret-scan (real gitleaks): a file that .gitignore ignores is not scanned (it is not in git)" run_secret "${r}"

r="${work}/repo-secret-deleted"
mk_repo "${r}"
fake_secret_line >"${r}/gone.txt"
commit_all "${r}" "add"
rm "${r}/gone.txt"
expect 1 "files: 0 finding(s); history origin/dev..HEAD: 1 finding(s)" "secret-scan (real gitleaks): a file that git has and the work tree has deleted does not stop the copy (the history has the secret)" run_secret "${r}"

r="${work}/repo-secret-allow-comment"
mk_repo "${r}"
printf 'stripe = "sk_live_%s" # gitleaks:allow\n' "51H8jT2LkqW9xYzAbCdEfGhIjKlMn" >"${r}/config.txt"
commit_all "${r}" "add a config"
expect 1 "REPORT: files: 1 finding(s); history origin/dev..HEAD: 1 finding(s)" "secret-scan (real gitleaks): a comment gitleaks:allow does not hide a finding" run_secret "${r}"

r="${work}/repo-secret-ignorefile"
mk_repo "${r}"
fake_secret_line >"${r}/config.txt"
commit_all "${r}" "add a config"
fingerprint="$(git -C "${r}" rev-parse HEAD):config.txt:stripe-access-token:1"
printf '%s\nconfig.txt:stripe-access-token:1\n' "${fingerprint}" >"${r}/.gitleaksignore"
expect 1 "REPORT: files: 1 finding(s); history origin/dev..HEAD: 1 finding(s)" "secret-scan (real gitleaks): a .gitleaksignore file does not hide a finding" run_secret "${r}"

r="${work}/repo-secret-allowlist"
mk_repo "${r}"
fake_secret_line >"${r}/fixture.txt"
commit_all "${r}" "add a fixture"
cat >>"${r}/tools/security/gitleaks.toml" <<'TOML'

[[allowlists]]
description = "The file fixture.txt is a fixture of this test: a text that looks like a Stripe key and is no credential."
paths = ['''^fixture\.txt$''']
TOML
expect 0 "REPORT: files: 0 finding(s); history origin/dev..HEAD: 0 finding(s)" "secret-scan (real gitleaks): an allowlist entry of the config hides the finding (the files and the history)" run_secret "${r}"

r="${work}/repo-config-broken"
mk_repo "${r}"
echo "[extend" >>"${r}/tools/security/gitleaks.toml"
expect_fail "FAILURE OF THE TOOL: gitleaks (files) ended with exit code 1" "secret-scan (real gitleaks): a config that gitleaks cannot read stops the recipe (ACC-005)" run_secret "${r}"
expect_fail "FAILURE OF THE TOOL: gitleaks (history) ended with exit code 1" "secret-scan (real gitleaks): a config that gitleaks cannot read stops the scan of the history too" run_secret "${r}"

r="${work}/repo-config-rule"
mk_repo "${r}"
cat >>"${r}/tools/security/gitleaks.toml" <<'TOML'

[[rules]]
id = "broken-rule"
regex = '''(unclosed'''
TOML
expect_fail "FAILURE OF THE TOOL" "secret-scan (real gitleaks): a config with a rule that has a wrong regular expression stops the recipe" run_secret "${r}"
fi

# ======================================================================================================================
section "Part 4: workflow-scan.sh (zizmor)"

wf="${work}/wf"
mkdir -p "${wf}/dir-clean/.github/workflows" "${wf}/dir-problem/.github/workflows" "${wf}/dir-both/.github/workflows" "${wf}/empty"
cp "${fixtures}/workflow-clean.yml" "${wf}/dir-clean/.github/workflows/clean.yml"
cp "${fixtures}/workflow-known-problem.yml" "${wf}/dir-problem/.github/workflows/problem.yml"
cp "${fixtures}/workflow-clean.yml" "${wf}/dir-both/.github/workflows/clean.yml"
cp "${fixtures}/workflow-unreadable.yml" "${wf}/dir-both/.github/workflows/unreadable.yml"
cp "${fixtures}/workflow-clean.yml" "${fixtures}/workflow-known-problem.yml" "${fixtures}/workflow-medium-problem.yml" "${fixtures}/workflow-unreadable.yml" "${wf}/"
echo "nothing" >"${wf}/empty/readme.txt"
# The baseline files of the cases (the paths are relative to ${wf}, the GATE_WORK_ROOT of the cases). The default of run_wf
# is a baseline with no line; a case sets wf_baseline for the other files.
printf '# an empty baseline\n' >"${wf}/bl-empty.txt"
printf '# the finding of the severity Medium of workflow-medium-problem.yml\nartipacked workflow-medium-problem.yml jobs/medium/steps/0\n' >"${wf}/bl-medium.txt"
printf '# the finding and an old line\nartipacked workflow-medium-problem.yml jobs/medium/steps/0\ntemplate-injection workflow-medium-problem.yml jobs/medium/steps/1/run\n' >"${wf}/bl-medium-old.txt"
printf '# a line for each finding of workflow-known-problem.yml, also the three that are High (an error of the feature)\nartipacked workflow-known-problem.yml jobs/known-problem/steps/0\ndangerous-triggers workflow-known-problem.yml on\ntemplate-injection workflow-known-problem.yml jobs/known-problem/steps/1/run\nunpinned-uses workflow-known-problem.yml jobs/known-problem/steps/0/uses\n' >"${wf}/bl-known-problem.txt"
printf '# a line with a wrong form\nthis is not an audit line\n' >"${wf}/bl-bad-form.txt"
wf_baseline="bl-empty.txt"
run_wf() { env GATE_WORK_ROOT="${wf}" "${GATES_DIR}/workflow-scan.sh" "${wf_baseline}" "$@"; }

expect 0 "zizmor: no finding (exit code 0)" "workflow-scan: a clean workflow file has no finding (exit code 0)" run_wf workflow-clean.yml
expect 0 "THRESHOLD PASS" "workflow-scan: a clean workflow file passes the level gate (the empty baseline)" run_wf workflow-clean.yml
expect 0 "zizmor: no finding (exit code 0)" "workflow-scan: a folder .github/workflows with a clean workflow has no finding (exit code 0)" run_wf dir-clean/.github/workflows
# a finding of the severity Medium (the case that the baseline can have)
expect 1 "FINDINGS (exit code 13)" "workflow-scan: a workflow with a finding of the severity Medium has the exit code 13 of zizmor" run_wf workflow-medium-problem.yml
expect 1 "THRESHOLD STOP" "workflow-scan: the finding of the severity Medium is not in the baseline: a new finding stops the gate with exit code 1 (ACC-007)" run_wf workflow-medium-problem.yml
expect 1 "STOP: a new finding that is not in the baseline (Medium): artipacked workflow-medium-problem.yml jobs/medium/steps/0 (confidence Low)" "workflow-scan: the message names the new finding (the audit, the file and the place)" run_wf workflow-medium-problem.yml
wf_baseline="bl-medium.txt"
expect 0 "THRESHOLD PASS" "workflow-scan: the finding of the severity Medium is in the baseline: the gate passes with exit code 0 (ACC-007, the finding of the baseline)" run_wf workflow-medium-problem.yml
expect 0 "Medium        baseline artipacked workflow-medium-problem.yml jobs/medium/steps/0 (confidence Low)" "workflow-scan: the report shows the level, the audit, the place and the state of the finding" run_wf workflow-medium-problem.yml
expect 0 "THRESHOLD PASS" "workflow-scan: the old line of the baseline for a clean file is only a warning: the gate passes (see the next case)" run_wf workflow-clean.yml
expect 0 "WARNING: the baseline line has no finding any more, so the baseline can be made smaller: artipacked workflow-medium-problem.yml jobs/medium/steps/0" "workflow-scan: a line of the baseline that has no finding any more is a warning, and the gate passes with exit code 0 (ACC-007, the old line)" run_wf workflow-clean.yml
wf_baseline="bl-medium-old.txt"
expect 0 "WARNING: the baseline line has no finding any more, so the baseline can be made smaller: template-injection workflow-medium-problem.yml jobs/medium/steps/1/run" "workflow-scan: a baseline with the line of the finding and an old line: the finding passes, and the old line is a warning" run_wf workflow-medium-problem.yml
wf_baseline="bl-empty.txt"
# the findings of the severity High
expect 1 "FINDINGS (exit code 14)" "workflow-scan: a workflow with a known problem is a finding (zizmor exit code 14)" run_wf workflow-known-problem.yml
expect 1 "FINDINGS (exit code 14)" "workflow-scan: a folder .github/workflows with a known problem is a finding" run_wf dir-problem/.github/workflows
expect 1 "error[template-injection]" "workflow-scan: the report names the known problem (template-injection)" run_wf workflow-known-problem.yml
expect 1 "error[dangerous-triggers]" "workflow-scan: the report names the known problem (dangerous-triggers)" run_wf workflow-known-problem.yml
expect 1 "REPORT: 7 findings" "workflow-scan: the summary line of zizmor is in the report" run_wf workflow-known-problem.yml
expect 1 "STOP: a finding that is High stops in each case: dangerous-triggers workflow-known-problem.yml on (confidence Medium)" "workflow-scan: a finding with the severity High stops the gate (ACC-007)" run_wf workflow-known-problem.yml
expect 1 "SUMMARY: zizmor: 4 finding(s) (0 Critical, 3 High, 1 Medium, 0 Low, 0 Informational, 0 Unknown)" "workflow-scan: the summary has the counts of the levels (the findings that zizmor suppresses are no findings)" run_wf workflow-known-problem.yml
wf_baseline="bl-known-problem.txt"
expect 1 "ERROR OF THE FEATURE: the baseline has a line for a finding that is High" "workflow-scan: a baseline with a line for a finding that is High is an error of the feature, and the gate stops although the finding is in the baseline (ACC-007)" run_wf workflow-known-problem.yml
expect 1 "THRESHOLD STOP" "workflow-scan: the findings that are High stop the gate also if all of them are in the baseline" run_wf workflow-known-problem.yml
wf_baseline="bl-empty.txt"
# a failure of the tool, and the inputs that cannot be used
expect_fail "FAILURE OF THE TOOL: zizmor ended with exit code 1" "workflow-scan: a workflow file that zizmor cannot read stops the recipe (ACC-005)" run_wf workflow-unreadable.yml
expect_fail "FAILURE OF THE TOOL: zizmor ended with exit code 1" "workflow-scan: a folder with a good and a bad file stops the recipe (--strict-collection)" run_wf dir-both/.github/workflows
expect_fail "FAILURE OF THE TOOL: zizmor ended with exit code 3" "workflow-scan: a folder with no workflow (no inputs) stops the recipe" run_wf empty
wf_baseline="bl-medium.txt"
expect_not 1 "THRESHOLD" "workflow-scan: a failure of the tool does not start the level gate (no verdict of the gate, also with a baseline that has a line)" run_wf workflow-unreadable.yml
wf_baseline="bl-empty.txt"
expect_fail "The path does not exist" "workflow-scan: a path that does not exist stops the recipe" run_wf nothing-here
expect_fail "Usage: workflow-scan.sh" "workflow-scan: no argument stops the recipe" run_wf
expect_fail "Usage: workflow-scan.sh" "workflow-scan: no baseline file (only a path) stops the recipe (the form of feat-8 is not accepted)" \
    env GATE_WORK_ROOT="${wf}" "${GATES_DIR}/workflow-scan.sh" workflow-clean.yml
wf_baseline="bl-does-not-exist.txt"
expect_fail "The baseline file does not exist" "workflow-scan: a baseline file that does not exist stops the recipe (the gate must read it)" run_wf workflow-clean.yml
wf_baseline="bl-bad-form.txt"
expect_fail "the line is not of the form" "workflow-scan: a line of the baseline with a wrong form stops the recipe" run_wf workflow-clean.yml
wf_baseline="bl-empty.txt"
expect 1 "FINDINGS (exit code 14)" "workflow-scan: more than one path (a clean file and a file with a problem) gives the findings of both" run_wf workflow-clean.yml workflow-known-problem.yml

# the mode of zizmor is explicit: a token in the environment does not start the online audits
expect 0 "zizmor: no finding (exit code 0)" "workflow-scan: a token in the environment (GITHUB_TOKEN) does not change the offline mode" \
    env GITHUB_TOKEN="not-a-real-token" GH_TOKEN="not-a-real-token" GATE_WORK_ROOT="${wf}" "${GATES_DIR}/workflow-scan.sh" bl-empty.txt workflow-clean.yml

# ======================================================================================================================
section "Part 5: the form of the scripts and of the recipes"

check "vuln-scan.sh does not use the option --licenses (the condition of the OSV deviation)" bash -c "! grep -v '^[[:space:]]*#' '${GATES_DIR}/vuln-scan.sh' | grep -q -- '--licenses'"
check "vuln-scan.sh reads the SBOM files with -L and uses --no-resolve" bash -c "grep -v '^[[:space:]]*#' '${GATES_DIR}/vuln-scan.sh' | grep -q -- 'scan source --no-resolve' && grep -v '^[[:space:]]*#' '${GATES_DIR}/vuln-scan.sh' | grep -q -- '-L '"
check "workflow-scan.sh starts zizmor with --offline" bash -c "grep -v '^[[:space:]]*#' '${GATES_DIR}/workflow-scan.sh' | grep -q -- '--offline'"
check "workflow-scan.sh starts zizmor with --strict-collection" bash -c "grep -v '^[[:space:]]*#' '${GATES_DIR}/workflow-scan.sh' | grep -q -- '--strict-collection'"
check "secret-scan.sh has --exit-code 2, --redact and --ignore-gitleaks-allow" bash -c "grep -v '^[[:space:]]*#' '${GATES_DIR}/secret-scan.sh' | grep -q -- '--exit-code 2' && grep -v '^[[:space:]]*#' '${GATES_DIR}/secret-scan.sh' | grep -q -- '--redact' && grep -v '^[[:space:]]*#' '${GATES_DIR}/secret-scan.sh' | grep -q -- '--ignore-gitleaks-allow'"
for script in vuln-scan.sh secret-scan.sh workflow-scan.sh test-security-gates.sh _security.sh security_threshold.py; do
    check "${script} is executable" test -x "${GATES_DIR}/${script}"
done
for script in vuln-scan.sh secret-scan.sh workflow-scan.sh; do
    check "${script} calls the level gate (security_level_gate), and its code has no text of a report with no threshold" \
        bash -c 'code="$(grep -v "^[[:space:]]*#" "$1")"; grep -q security_level_gate <<<"${code}" && ! grep -q "no threshold" <<<"${code}"' _ "${GATES_DIR}/${script}"
done
check "the job secret-scan of ci.yml has the action astral-sh/setup-uv (the level gate runs in a Python environment that uv makes)" bash -c "grep -E '^ci.yml secret-scan ' '${GATES_DIR}/required-setup.txt' | grep -q 'astral-sh/setup-uv'"
justfile="${REPO_ROOT}/justfile"
just_recipe() { # just_recipe <recipe> <text in the body> : the justfile has the recipe with the text in its lines
    just --justfile "${justfile}" --show "$1" 2>/dev/null | grep -q -- "$2"
}
check "the justfile has the recipe vuln-scan with the prerequisite sbom" bash -c "just --justfile '${justfile}' --show vuln-scan | grep -q '^vuln-scan: sbom\$'"
check "the recipe vuln-scan starts vuln-scan.sh with the SBOM folder" just_recipe vuln-scan "_gate vuln-scan.sh"
check "the recipe vuln-scan gives the baseline file osv-baseline.txt to vuln-scan.sh (the level gate, feat-9 Task 500.120)" just_recipe vuln-scan "vuln-scan.sh 500.120 \"{{ sbom_dir }}\" tools/security/osv-baseline.txt"
check "the recipe secret-scan starts secret-scan.sh with the base, the config and the baseline file" just_recipe secret-scan "secret-scan.sh 500.120 \"{{ base }}\" tools/security/gitleaks.toml tools/security/gitleaks-baseline.txt"
check "the recipe workflow-scan starts workflow-scan.sh with the baseline file and .github/workflows" just_recipe workflow-scan "workflow-scan.sh 500.120 tools/security/zizmor-baseline.txt .github/workflows"
check "the recipe test-security-gates starts this test" just_recipe test-security-gates "test-security-gates.sh"
check "test-gates has the prerequisite test-security-gates" bash -c "just --justfile '${justfile}' --show test-gates | grep -q '^test-gates:.* test-security-gates'"
check "the allowlist of gitleaks has useDefault = true" grep -q '^useDefault = true' "${real_config}"
check "CODEOWNERS covers the allowlist of gitleaks" grep -Eq '^/tools/security/gitleaks.toml[[:space:]]+@dfch' "${REPO_ROOT}/.github/CODEOWNERS"
check "CODEOWNERS covers the folder tools/" grep -Eq '^/tools/[[:space:]]+@dfch' "${REPO_ROOT}/.github/CODEOWNERS"
allowlist_entries="$(grep -c '^\[\[allowlists\]\]' "${real_config}" || true)"
allowlist_descriptions="$(grep -c '^description = ' "${real_config}" || true)"
if [[ "${allowlist_entries}" == "${allowlist_descriptions}" ]]; then
    echo "ok   the allowlist of gitleaks has a description (the reason) for each entry (${allowlist_entries} entries)"
    passed=$((passed + 1))
else
    echo "FAIL the allowlist of gitleaks has ${allowlist_entries} entries and ${allowlist_descriptions} descriptions: each entry needs a reason"
    failed=$((failed + 1))
fi

# ======================================================================================================================
section "Part 6: the level gate (security_threshold.py) and the baseline files of the repository (feat-9 Task 500.110 and 500.120, ACC-007)"

# The script uses the standard library only. The environment has the Python of PYTHON_VERSION and no package. The trap of
# make_python_bare_env is replaced, so the temporary folder of the test is removed too.
make_python_bare_env
trap 'rm -rf "${work}" "${GATE_ENV_DIR}"' EXIT
threshold() { "${GATE_PYTHON}" "${GATES_DIR}/security_threshold.py" "$@"; }

# OSV-Scanner: the level of the CVSS score (the same limits as the table of OSV-Scanner), the label, the higher of the two
for score_case in "9.0|Critical" "9.8|Critical" "8.9|High" "7.0|High" "6.9|Medium" "4.0|Medium" "3.9|Low" "0.1|Low"; do
    score="${score_case%%|*}"
    level="${score_case##*|}"
    expect 1 "(CVSS ${score})" "level gate (OSV): the score ${score} is the level ${level} (a new finding stops in each case)" \
        threshold osv "${bl_empty}" "$(osv_report "${work}/osv-score.json" "$(osv_pkg GHSA-aaaa-bbbb-cccc pkg 1.0.0 "${score}")")"
    expect 1 "  ${level} " "level gate (OSV): the score ${score} is shown with the level ${level}" \
        threshold osv "${bl_empty}" "${work}/osv-score.json"
done
expect 0 "RESULT: PASS. 1 finding(s)" "level gate (OSV): the score 6.9 (Medium) in the baseline passes" \
    threshold osv "$(mk_baseline lg-osv-6-9 "GHSA-aaaa-bbbb-cccc pkg@1.0.0")" "$(osv_report "${work}/osv-6-9.json" "$(osv_pkg GHSA-aaaa-bbbb-cccc pkg 1.0.0 6.9)")"
expect 0 "RESULT: PASS. 1 finding(s)" "level gate (OSV): the score 3.9 (Low) in the baseline passes" \
    threshold osv "$(mk_baseline lg-osv-3-9 "GHSA-aaaa-bbbb-cccc pkg@1.0.0")" "$(osv_report "${work}/osv-3-9.json" "$(osv_pkg GHSA-aaaa-bbbb-cccc pkg 1.0.0 3.9)")"
expect 1 "RESULT: STOP. 0 new finding(s), 1 finding(s) that are Critical or High" "level gate (OSV): the score 7.0 (High) in the baseline stops (the baseline has no line of this level)" \
    threshold osv "$(mk_baseline lg-osv-7-0 "GHSA-aaaa-bbbb-cccc pkg@1.0.0")" "$(osv_report "${work}/osv-7-0.json" "$(osv_pkg GHSA-aaaa-bbbb-cccc pkg 1.0.0 7.0)")"
expect 1 "GHSA-aaaa-bbbb-cccc pkg@1.0.0 (CVSS 5.0)" "level gate (OSV): a record with the score 5.0 and the label HIGH is High (the higher level of the two)" \
    threshold osv "${bl_empty}" "$(osv_report "${work}/osv-5-high.json" "$(osv_pkg GHSA-aaaa-bbbb-cccc pkg 1.0.0 5.0 HIGH)")"
expect 1 "STOP: a finding that is High stops in each case: GHSA-aaaa-bbbb-cccc pkg@1.0.0" "level gate (OSV): the label HIGH with the score 5.0 stops in each case" \
    threshold osv "${bl_empty}" "${work}/osv-5-high.json"
expect 0 "Medium        baseline GHSA-aaaa-bbbb-cccc pkg@1.0.0" "level gate (OSV): a record with no score and the label MODERATE is Medium (the label is the level if there is no score)" \
    threshold osv "$(mk_baseline lg-osv-moderate "GHSA-aaaa-bbbb-cccc pkg@1.0.0")" "$(osv_report "${work}/osv-moderate.json" "$(osv_pkg GHSA-aaaa-bbbb-cccc pkg 1.0.0 "" MODERATE)")"
expect 1 "Critical" "level gate (OSV): a record with the score 9.0 and the label MODERATE is Critical (the score is the higher level)" \
    threshold osv "${bl_empty}" "$(osv_report "${work}/osv-9-moderate.json" "$(osv_pkg GHSA-aaaa-bbbb-cccc pkg 1.0.0 9.0 MODERATE)")"
# a group with two identifiers: the first identifier in the sorted order is the key (so the order of the report does not matter)
printf '{"results":[{"packages":[{"package":{"name":"pkg","version":"1.0.0","ecosystem":"npm"},"groups":[{"ids":["OSV-2026-9","GHSA-aaaa-bbbb-cccc"],"max_severity":"5.0"}],"vulnerabilities":[]}]}]}\n' >"${work}/osv-two-ids.json"
expect 0 "RESULT: PASS. 1 finding(s)" "level gate (OSV): a group with two identifiers has the key of the first identifier in the sorted order (GHSA-aaaa-bbbb-cccc)" \
    threshold osv "$(mk_baseline lg-osv-two-ids "GHSA-aaaa-bbbb-cccc pkg@1.0.0")" "${work}/osv-two-ids.json"
expect 0 "RESULT: PASS. 1 finding(s)" "level gate (OSV): the same finding in two packages of two SBOM files is one finding" \
    threshold osv "${bl_qs}" "$(osv_report "${work}/osv-dup.json" "$(osv_pkg GHSA-4mjr-xmp4-gh2g qs 6.15.1 6.3)" "$(osv_pkg GHSA-4mjr-xmp4-gh2g qs 6.15.1 6.3)")"
expect 0 "RESULT: PASS. 1 finding(s)" "level gate (OSV): a scoped npm package (@types/node@26.6.6) and a Maven package (org.springframework:spring-web@7.0.10) are lines of the baseline" \
    threshold osv "$(mk_baseline lg-osv-scoped "GHSA-aaaa-bbbb-cccc @types/node@26.6.6")" "$(osv_report "${work}/osv-scoped.json" "$(osv_pkg GHSA-aaaa-bbbb-cccc @types/node 26.6.6 5.0)")"
expect 0 "RESULT: PASS. 1 finding(s)" "level gate (OSV): the package of a Maven artifact has the form group:artifact" \
    threshold osv "$(mk_baseline lg-osv-maven "GHSA-aaaa-bbbb-cccc org.springframework:spring-web@7.0.10")" "$(osv_report "${work}/osv-maven.json" "$(osv_pkg GHSA-aaaa-bbbb-cccc org.springframework:spring-web 7.0.10 5.0)")"
expect 0 "RESULT: PASS. 0 finding(s), all in the baseline, none Critical or High; 0 old baseline line(s)." "level gate (OSV): no finding and a baseline with comments and empty lines only passes" \
    threshold osv "$(mk_baseline lg-osv-comments)" "${osv_empty}"
printf '# a comment\n\n   \n  GHSA-4mjr-xmp4-gh2g qs@6.15.1   \n# another comment\n' >"${bl_dir}/lg-osv-blank.txt"
expect 0 "RESULT: PASS. 1 finding(s)" "level gate (OSV): comments, empty lines and the spaces around a line are no problem" \
    threshold osv "${bl_dir}/lg-osv-blank.txt" "${osv_medium}"
# an input that cannot be used: exit code 2
expect 2 "the baseline file cannot be read" "level gate: a baseline file that does not exist is exit code 2 (an input that cannot be used)" \
    threshold osv "${bl_dir}/none.txt" "${osv_empty}"
expect 2 "the report file cannot be read" "level gate: a report file that does not exist is exit code 2" \
    threshold osv "${bl_empty}" "${work}/none.json"
expect 2 "the line is not of the form" "level gate (OSV): a line of the baseline that is only an identifier is exit code 2" \
    threshold osv "$(mk_baseline lg-osv-onlyid "GHSA-4mjr-xmp4-gh2g")" "${osv_empty}"
expect 2 "the line is not of the form" "level gate (OSV): a line of the baseline with a URL of the advisory in place of the package is exit code 2 (no record text in the baseline)" \
    threshold osv "$(mk_baseline lg-osv-text "GHSA-4mjr-xmp4-gh2g qs 6.15.1 prototype pollution")" "${osv_empty}"
expect 2 "the line is twice in the baseline" "level gate: a line twice in the baseline is exit code 2" \
    threshold osv "$(mk_baseline lg-osv-twice "GHSA-4mjr-xmp4-gh2g qs@6.15.1" "GHSA-4mjr-xmp4-gh2g qs@6.15.1")" "${osv_empty}"
expect 2 "Usage: security_threshold.py" "level gate: an unknown tool is exit code 2" threshold nope "${bl_empty}" "${osv_empty}"
expect 2 "Usage: security_threshold.py" "level gate: no report file is exit code 2" threshold osv "${bl_empty}"
expect 2 "the report of OSV-Scanner has no list" "level gate (OSV): a report with another form is exit code 2" \
    threshold osv "${bl_empty}" "${work}/osv-report-form.json"
printf '{"results":[{"packages":[{"package":{"name":"pkg"},"groups":[]}]}]}\n' >"${work}/osv-nover.json"
expect 2 "has no name or no version" "level gate (OSV): a package with no version is exit code 2" threshold osv "${bl_empty}" "${work}/osv-nover.json"
printf '{"results":[{"packages":[{"package":{"name":"pkg","version":"1"},"groups":[{"ids":[]}]}]}]}\n' >"${work}/osv-noid.json"
expect 2 "has no identifier" "level gate (OSV): a group with no identifier is exit code 2" threshold osv "${bl_empty}" "${work}/osv-noid.json"

# The review finding N1: a vulnerability of a package that no group names must not pass as "0 findings" (the report
# `groups` is the list of the findings of the gate). The cross-check stops with exit code 2 (an unusable input).
printf '{"results":[{"packages":[{"package":{"name":"pkg","version":"1.0.0","ecosystem":"npm"},"groups":[],"vulnerabilities":[{"id":"GHSA-aaaa-bbbb-cccc","database_specific":{"severity":"CRITICAL"}}]}]}]}\n' >"${work}/osv-nogroup.json"
expect 2 "has 1 vulnerabilit(ies) that no group names (GHSA-aaaa-bbbb-cccc)" "level gate (OSV): a package with a Critical vulnerability and \"groups\": [] is exit code 2, and not \"0 finding(s)\" (N1)" \
    threshold osv "${bl_empty}" "${work}/osv-nogroup.json"
expect_not 2 "RESULT: PASS" "level gate (OSV): the report with a vulnerability that no group names has no pass verdict (N1)" \
    threshold osv "${bl_empty}" "${work}/osv-nogroup.json"
printf '{"results":[{"packages":[{"package":{"name":"pkg","version":"1.0.0","ecosystem":"npm"},"groups":[{"ids":["GHSA-aaaa-bbbb-cccc"],"max_severity":"5.0"}],"vulnerabilities":[{"id":"GHSA-aaaa-bbbb-cccc"},{"id":"GHSA-zzzz-yyyy-xxxx"}]}]}]}\n' >"${work}/osv-onegroup.json"
expect 2 "that no group names (GHSA-zzzz-yyyy-xxxx)" "level gate (OSV): one vulnerability that is in no group, next to one that is in a group, is exit code 2 (N1)" \
    threshold osv "$(mk_baseline lg-osv-onegroup "GHSA-aaaa-bbbb-cccc pkg@1.0.0")" "${work}/osv-onegroup.json"
printf '{"results":[{"packages":[{"package":{"name":"pkg","version":"1.0.0","ecosystem":"npm"},"groups":[{"ids":["GHSA-aaaa-bbbb-cccc"],"aliases":["CVE-2026-1"],"max_severity":"5.0"}],"vulnerabilities":[{"id":"CVE-2026-1"}]}]}]}\n' >"${work}/osv-alias-covered.json"
expect 0 "RESULT: PASS. 1 finding(s)" "level gate (OSV): a vulnerability that a group names as an alias is covered (no exit code 2)" \
    threshold osv "$(mk_baseline lg-osv-alias-covered "GHSA-aaaa-bbbb-cccc pkg@1.0.0")" "${work}/osv-alias-covered.json"
printf '{"results":[{"packages":[{"package":{"name":"pkg","version":"1.0.0","ecosystem":"npm"},"groups":[{"ids":["GHSA-aaaa-bbbb-cccc"],"max_severity":"5.0"}]}]}]}\n' >"${work}/osv-novulns.json"
expect 0 "RESULT: PASS. 1 finding(s)" "level gate (OSV): a package with groups and with no key \`vulnerabilities\` is no problem" \
    threshold osv "$(mk_baseline lg-osv-novulns "GHSA-aaaa-bbbb-cccc pkg@1.0.0")" "${work}/osv-novulns.json"
printf '{"results":[{"packages":[{"package":{"name":"pkg","version":"1.0.0","ecosystem":"npm"},"groups":[{"ids":["GHSA-aaaa-bbbb-cccc"]}],"vulnerabilities":[{"summary":"no id"}]}]}]}\n' >"${work}/osv-vuln-noid.json"
expect 2 "a vulnerability of pkg@1.0.0 has no identifier" "level gate (OSV): a vulnerability with no identifier is exit code 2" threshold osv "${bl_empty}" "${work}/osv-vuln-noid.json"

# The review finding N3: the baseline line matches a finding if it has ANY identifier of the group (the key of the report is
# the first identifier in the sorted order, so the group [GHSA-aaaa-bbbb-cccc, CVE-2026-1] has the key CVE-2026-1).
printf '{"results":[{"packages":[{"package":{"name":"pkg","version":"1.0.0","ecosystem":"npm"},"groups":[{"ids":["GHSA-aaaa-bbbb-cccc","CVE-2026-1"],"max_severity":"5.0"}],"vulnerabilities":[{"id":"GHSA-aaaa-bbbb-cccc"}]}]}]}\n' >"${work}/osv-multi.json"
expect 0 "baseline CVE-2026-1 pkg@1.0.0" "level gate (OSV): the report shows the key of the first identifier in the sorted order (CVE-2026-1) (N3)" \
    threshold osv "$(mk_baseline lg-osv-multi-first "CVE-2026-1 pkg@1.0.0")" "${work}/osv-multi.json"
expect_not 0 "WARNING" "level gate (OSV): a baseline line with the first identifier of the group matches (no old line) (N3)" \
    threshold osv "$(mk_baseline lg-osv-multi-first2 "CVE-2026-1 pkg@1.0.0")" "${work}/osv-multi.json"
expect 0 "baseline CVE-2026-1 pkg@1.0.0" "level gate (OSV): a baseline line with the other identifier (the GHSA that is not the first in the sorted order) matches the finding (N3)" \
    threshold osv "$(mk_baseline lg-osv-multi-other "GHSA-aaaa-bbbb-cccc pkg@1.0.0")" "${work}/osv-multi.json"
expect_not 0 "WARNING" "level gate (OSV): the line with the other identifier is no old line, and there is no NEW finding (N3)" \
    threshold osv "${bl_dir}/lg-osv-multi-other.txt" "${work}/osv-multi.json"
expect 0 "RESULT: PASS. 1 finding(s), all in the baseline, none Critical or High; 0 old baseline line(s)." "level gate (OSV): the two lines of the two identifiers of one group are one finding, and none is old (N3)" \
    threshold osv "$(mk_baseline lg-osv-multi-both "CVE-2026-1 pkg@1.0.0" "GHSA-aaaa-bbbb-cccc pkg@1.0.0")" "${work}/osv-multi.json"
expect 1 "STOP: a new finding that is not in the baseline (Medium): CVE-2026-1 pkg@1.0.0" "level gate (OSV): a line with an identifier that is not in the group is no match: the finding is new (N3)" \
    threshold osv "$(mk_baseline lg-osv-multi-nomatch "GHSA-zzzz-yyyy-xxxx pkg@1.0.0")" "${work}/osv-multi.json"
expect 1 "WARNING: the baseline line has no finding any more, so the baseline can be made smaller: GHSA-zzzz-yyyy-xxxx pkg@1.0.0" "level gate (OSV): a line that no group matches is an old line (N3)" \
    threshold osv "${bl_dir}/lg-osv-multi-nomatch.txt" "${work}/osv-multi.json"
expect 1 "STOP: a new finding that is not in the baseline (Medium): CVE-2026-1 pkg@1.0.0" "level gate (OSV): a line with an identifier of the group but another version of the package is no match (N3)" \
    threshold osv "$(mk_baseline lg-osv-multi-version "GHSA-aaaa-bbbb-cccc pkg@2.0.0")" "${work}/osv-multi.json"
printf '{"results":[{"packages":[{"package":{"name":"pkg","version":"1.0.0","ecosystem":"npm"},"groups":[{"ids":["GHSA-aaaa-bbbb-cccc","CVE-2026-1"],"max_severity":"9.1"}],"vulnerabilities":[{"id":"GHSA-aaaa-bbbb-cccc"}]}]}]}\n' >"${work}/osv-multi-critical.json"
expect 1 "ERROR OF THE FEATURE: the baseline has a line for a finding that is Critical" "level gate (OSV): a Critical finding with a line of the other identifier in the baseline stops, and the baseline is an error of the feature (N3)" \
    threshold osv "$(mk_baseline lg-osv-multi-critical "GHSA-aaaa-bbbb-cccc pkg@1.0.0")" "${work}/osv-multi-critical.json"

# The review finding N2: a Python crash must be exit code 2 (an input that cannot be used), never exit code 1 with a
# traceback (the shell would call it "a new finding"). Bytes that are not UTF-8, and the JSON nodes of another type.
printf '\xff\xfe\n' >"${work}/bytes-ff-fe.bin"
echo '[]' >"${work}/gl-report-early.json"
expect 2 "the baseline file is not text in UTF-8" "level gate: a baseline file with the bytes 0xFF 0xFE is exit code 2 (N2)" \
    threshold osv "${work}/bytes-ff-fe.bin" "${osv_empty}"
expect_not 2 "Traceback" "level gate: a baseline file that is not UTF-8 gives no traceback (N2)" threshold osv "${work}/bytes-ff-fe.bin" "${osv_empty}"
expect 2 "the baseline file is not text in UTF-8" "level gate (gitleaks): a baseline file with the bytes 0xFF 0xFE is exit code 2 (N2)" \
    threshold gitleaks "${work}/bytes-ff-fe.bin" "${work}/gl-report-early.json"
expect 2 "the report file is not text in UTF-8" "level gate: a report file with the bytes 0xFF 0xFE is exit code 2 (N2)" \
    threshold osv "${bl_empty}" "${work}/bytes-ff-fe.bin"
expect_not 2 "Traceback" "level gate: a report file that is not UTF-8 gives no traceback (N2)" threshold osv "${bl_empty}" "${work}/bytes-ff-fe.bin"
printf '{"results":[{"packages":["x"]}]}\n' >"${work}/osv-node-string.json"
expect 2 "the report of OSV-Scanner has a form that the gate cannot read" "level gate (OSV): a package that is a string in place of an object is exit code 2 (N2)" \
    threshold osv "${bl_empty}" "${work}/osv-node-string.json"
expect_not 2 "Traceback" "level gate (OSV): a package that is a string gives no traceback (N2)" threshold osv "${bl_empty}" "${work}/osv-node-string.json"
printf '{"results":[{"packages":[{"package":{"name":"pkg","version":"1"},"groups":["x"]}]}]}\n' >"${work}/osv-group-string.json"
expect 2 "has a form that the gate cannot read" "level gate (OSV): a group that is a string is exit code 2 (N2)" threshold osv "${bl_empty}" "${work}/osv-group-string.json"
printf '{"results":[{"packages":[{"package":{"name":"pkg","version":"1"},"groups":[{"ids":["a"]}],"vulnerabilities":"x"}]}]}\n' >"${work}/osv-vulns-string.json"
expect 2 "has a form that the gate cannot read" "level gate (OSV): \`vulnerabilities\` that is a string is exit code 2 (N2)" threshold osv "${bl_empty}" "${work}/osv-vulns-string.json"
printf '[{"ident":"artipacked","locations":["x"]}]\n' >"${work}/zz-loc-string.json"
expect 2 "has a form that the gate cannot read" "level gate (zizmor): a location that is a string is exit code 2 (N2)" threshold zizmor "${bl_empty}" "${work}/zz-loc-string.json"
printf '[{"ident":"artipacked","determinations":"x","locations":[{"symbolic":{"key":{"Local":{"verbatim_path":"f.yml"}},"kind":"Primary"}}]}]\n' >"${work}/zz-det-string.json"
expect 2 "has a form that the gate cannot read" "level gate (zizmor): \`determinations\` that is a string is exit code 2 (N2)" threshold zizmor "${bl_empty}" "${work}/zz-det-string.json"
"${GATE_PYTHON}" -c 'print("[" * 100000)' >"${work}/json-deep.json"
expect 2 "the report file is not JSON" "level gate: a JSON that is nested too deep is exit code 2, and not a crash (N2)" threshold osv "${bl_empty}" "${work}/json-deep.json"
# A bug of the script itself ends with exit code 3 (never 1): the reader of OSV is replaced by a function that fails.
internal_error() { "${GATE_PYTHON}" -c "
import sys
sys.path.insert(0, '${GATES_DIR}')
import security_threshold as t
t.READERS['osv'] = lambda *a: 1 / 0
sys.exit(t.main(['x', 'osv', '${bl_empty}', '${osv_empty}']))
"; }
expect 3 "INTERNAL ERROR of the level gate: ZeroDivisionError" "level gate: a bug of the script (an exception that is not an input error) is exit code 3, with no traceback (N2)" internal_error
expect_not 3 "Traceback" "level gate: the exit code 3 has no traceback (N2)" internal_error
# The shell function: exit code 1 is the finding, exit code 2 an unusable input, any other code is a failure of the script.
fake_py() { # fake_py <name> <exit code> : a script that ends with the exit code (it is the GATE_PYTHON of the function)
    printf '#!/usr/bin/env bash\nexit %s\n' "$2" >"${work}/$1" && chmod +x "${work}/$1" && echo "${work}/$1"
}
level_gate_with() { ( GATE_PYTHON="$1"; security_level_gate "tool" osv "${bl_empty}" "${osv_empty}" ); }
for code_case in "0|THRESHOLD PASS|0" "1|THRESHOLD STOP|1" "2|the baseline ${bl_empty} or the report of tool cannot be used (exit code 2)|1" \
    "3|unexpected exit code 3|1" "7|unexpected exit code 7|1" "137|unexpected exit code 137|1"; do
    IFS='|' read -r fake_code fake_text fake_result <<<"${code_case}"
    expect "${fake_result}" "${fake_text}" "level gate (shell): the exit code ${fake_code} of the script is read as '${fake_text}' (N2)" \
        level_gate_with "$(fake_py "fake-py-${fake_code}" "${fake_code}")"
done
expect_not 1 "THRESHOLD STOP" "level gate (shell): an unexpected exit code of the script is not a finding (the text of the finding is not in the message) (N2)" \
    level_gate_with "$(fake_py fake-py-7 7)"

# zizmor: the severity, ignored findings, the place of the finding
zz_item() { # zz_item <audit> <severity> <file> <route JSON array> [<ignored: true|false>]
    printf '{"ident":"%s","desc":"x","url":"u","determinations":{"confidence":"High","severity":"%s","persona":"Regular"},"locations":[{"symbolic":{"key":{"Local":{"verbatim_path":"%s"}},"annotation":"a","route":{"route":%s},"feature_kind":"Normal","kind":"Primary"},"concrete":{}}],"ignored":%s}' \
        "$1" "$2" "$3" "$4" "${5:-false}"
}
zz_report() { local file="$1" joined; shift; joined="$(IFS=,; echo "$*")"; printf '[%s]\n' "${joined}" >"${file}"; echo "${file}"; }
zz_route_job='[{"Key":"jobs"},{"Key":"lint"},{"Key":"steps"},{"Index":0}]'
expect 1 "STOP: a finding that is High stops in each case: template-injection .github/workflows/ci.yml jobs/lint/steps/0" "level gate (zizmor): the severity High stops (zizmor has no level Critical)" \
    threshold zizmor "${bl_empty}" "$(zz_report "${work}/zz-high.json" "$(zz_item template-injection High .github/workflows/ci.yml "${zz_route_job}")")"
expect 1 "ERROR OF THE FEATURE: the baseline has a line for a finding that is High" "level gate (zizmor): a High finding with a line in the baseline stops, and the message says that the baseline is wrong" \
    threshold zizmor "$(mk_baseline lg-zz-high "template-injection .github/workflows/ci.yml jobs/lint/steps/0")" "${work}/zz-high.json"
for severity in Medium Low Informational; do
    expect 0 "RESULT: PASS. 1 finding(s)" "level gate (zizmor): the severity ${severity} in the baseline passes" \
        threshold zizmor "$(mk_baseline "lg-zz-${severity}" "artipacked .github/workflows/ci.yml jobs/lint/steps/0")" \
        "$(zz_report "${work}/zz-${severity}.json" "$(zz_item artipacked "${severity}" .github/workflows/ci.yml "${zz_route_job}")")"
    expect 1 "STOP: a new finding that is not in the baseline (${severity}): artipacked" "level gate (zizmor): the severity ${severity} that is not in the baseline stops (a new finding)" \
        threshold zizmor "${bl_empty}" "${work}/zz-${severity}.json"
done
expect 0 "RESULT: PASS. 0 finding(s)" "level gate (zizmor): a finding that zizmor suppresses (ignored: true) is no finding, also with the severity High" \
    threshold zizmor "${bl_empty}" "$(zz_report "${work}/zz-ignored.json" "$(zz_item template-injection High .github/workflows/ci.yml "${zz_route_job}" true)")"
expect 1 "SUMMARY: zizmor: 2 finding(s)" "level gate (zizmor): the same audit in two jobs is two findings (the place is part of the line)" \
    threshold zizmor "$(mk_baseline lg-zz-two "artipacked .github/workflows/ci.yml jobs/lint/steps/0")" \
    "$(zz_report "${work}/zz-two.json" "$(zz_item artipacked Medium .github/workflows/ci.yml "${zz_route_job}")" "$(zz_item artipacked Medium .github/workflows/ci.yml '[{"Key":"jobs"},{"Key":"compile"},{"Key":"steps"},{"Index":0}]')")"
expect 1 "STOP: a new finding that is not in the baseline (Medium): artipacked .github/workflows/ci.yml jobs/compile/steps/0" "level gate (zizmor): the finding in the second job is the new one" \
    threshold zizmor "${bl_dir}/lg-zz-two.txt" "${work}/zz-two.json"
expect 0 "RESULT: PASS. 1 finding(s)" "level gate (zizmor): the place of a finding is the path of the keys and the indexes, so the line numbers of the file do not matter (a trigger has the place 'on')" \
    threshold zizmor "$(mk_baseline lg-zz-on "dangerous-triggers-low .github/workflows/ci.yml on")" \
    "$(zz_report "${work}/zz-on.json" "$(zz_item dangerous-triggers-low Low .github/workflows/ci.yml '[{"Key":"on"}]')")"
expect 0 "RESULT: PASS. 1 finding(s)" "level gate (zizmor): a finding with no place has the place '-'" \
    threshold zizmor "$(mk_baseline lg-zz-noroute "obfuscation .github/workflows/ci.yml -")" \
    "$(zz_report "${work}/zz-noroute.json" "$(zz_item obfuscation Low .github/workflows/ci.yml '[]')")"
echo '{"not":"a list"}' >"${work}/zz-form.json"
expect 2 "the report of zizmor is not a list" "level gate (zizmor): a report with another form is exit code 2" threshold zizmor "${bl_empty}" "${work}/zz-form.json"
printf '[{"ident":"artipacked","determinations":{"severity":"Medium"},"locations":[],"ignored":false}]\n' >"${work}/zz-nofile.json"
expect 2 "has no file" "level gate (zizmor): a finding with no location is exit code 2" threshold zizmor "${bl_empty}" "${work}/zz-nofile.json"
expect 2 "the line is not of the form" "level gate (zizmor): a line of the baseline with only an audit is exit code 2" \
    threshold zizmor "$(mk_baseline lg-zz-badform "artipacked")" "${bl_empty}" 
expect 1 "(Unknown)" "level gate (zizmor): a severity that the gate does not know is Unknown (it is no stop by its level, and a new finding stops)" \
    threshold zizmor "${bl_empty}" "$(zz_report "${work}/zz-unknown.json" "$(zz_item artipacked Surprising .github/workflows/ci.yml "${zz_route_job}")")"

# gitleaks: no level, the fingerprints of two reports (the files and the history)
gl_report "${work}/lg-gl-files.json" "config.txt:stripe-access-token:1"
gl_report "${work}/lg-gl-history.json" "abc123:config.txt:stripe-access-token:1"
expect 0 "SUMMARY: gitleaks: 2 finding(s) (0 Critical, 0 High, 0 Medium, 0 Low, 0 Informational, 0 Unknown, 2 Unrated); baseline lg-gl-both.txt: 2 line(s)" "level gate (gitleaks): the findings of the two reports are in the baseline: the gate passes, and the level is Unrated (gitleaks has no severity)" \
    threshold gitleaks "$(mk_baseline lg-gl-both "config.txt:stripe-access-token:1" "abc123:config.txt:stripe-access-token:1")" "${work}/lg-gl-files.json" "${work}/lg-gl-history.json"
expect 1 "STOP: a new finding that is not in the baseline (Unrated): abc123:config.txt:stripe-access-token:1" "level gate (gitleaks): a finding of the history that is not in the baseline stops the gate" \
    threshold gitleaks "$(mk_baseline lg-gl-files-only "config.txt:stripe-access-token:1")" "${work}/lg-gl-files.json" "${work}/lg-gl-history.json"
expect 1 "RESULT: STOP. 2 new finding(s), 0 finding(s) that are Critical or High" "level gate (gitleaks): with an empty baseline each finding of a secret is new and stops (the result counts them)" \
    threshold gitleaks "${bl_empty}" "${work}/lg-gl-files.json" "${work}/lg-gl-history.json"
expect 0 "SUMMARY: gitleaks: 1 finding(s)" "level gate (gitleaks): the same fingerprint in the two reports is one finding" \
    threshold gitleaks "$(mk_baseline lg-gl-same "config.txt:stripe-access-token:1")" "${work}/lg-gl-files.json" "${work}/lg-gl-files.json"
gl_report "${work}/lg-gl-none.json"
expect 0 "WARNING: the baseline line has no finding any more, so the baseline can be made smaller: config.txt:stripe-access-token:1" "level gate (gitleaks): a line of the baseline for a secret that is gone is a warning (the old line), and the gate passes" \
    threshold gitleaks "$(mk_baseline lg-gl-old "config.txt:stripe-access-token:1")" "${work}/lg-gl-none.json" "${work}/lg-gl-none.json"
expect 0 "<a file name with spaces.txt>:rule:3" "level gate (gitleaks): a fingerprint can have spaces (the line is the whole fingerprint)" \
    threshold gitleaks "$(mk_baseline lg-gl-space "<a file name with spaces.txt>:rule:3")" "$(printf '[{"RuleID":"rule","Fingerprint":"<a file name with spaces.txt>:rule:3"}]\n' >"${work}/lg-gl-space.json"; echo "${work}/lg-gl-space.json")"
echo '[{"RuleID":"rule"}]' >"${work}/lg-gl-nofp.json"
expect 2 "has no fingerprint" "level gate (gitleaks): an entry with no fingerprint is exit code 2" threshold gitleaks "${bl_empty}" "${work}/lg-gl-nofp.json"
echo '{"x":1}' >"${work}/lg-gl-form.json"
expect 2 "the report of gitleaks is not a list" "level gate (gitleaks): a report with another form is exit code 2" threshold gitleaks "${bl_empty}" "${work}/lg-gl-form.json"
check "the level of a finding of gitleaks is a constant of one place (GITLEAKS_LEVEL), and its value is Unrated" \
    grep -q '^GITLEAKS_LEVEL = UNRATED$' "${GATES_DIR}/security_threshold.py"

# The baseline files of the repository (Task 500.110): they exist, they have the form that the gate reads, no line twice, no
# text of a record. The gate reads each of them with a report that has no finding (all lines are old lines: warnings only).
real_security_dir="${REPO_ROOT}/tools/security"
for tool_case in "osv|osv-baseline.txt|${osv_empty}" "gitleaks|gitleaks-baseline.txt|${work}/lg-gl-none.json" "zizmor|zizmor-baseline.txt|$(zz_report "${work}/zz-none.json")"; do
    IFS='|' read -r tool_name baseline_name report_file <<<"${tool_case}"
    check "the baseline file tools/security/${baseline_name} exists, and the gate reads each line (the form, no line twice)" \
        test -f "${real_security_dir}/${baseline_name}" -a -s "${real_security_dir}/${baseline_name}"
    expect 0 "RESULT: PASS." "the gate reads tools/security/${baseline_name} (exit code 0 for a report with no finding: the lines are old lines, warnings only)" \
        threshold "${tool_name}" "${real_security_dir}/${baseline_name}" "${report_file}"
done
# data_lines <file> : the lines of a baseline file that are no comment and no empty line
data_lines() { grep -v '^[[:space:]]*\(#\|$\)' "$1" || true; }
osv_data="$(data_lines "${real_security_dir}/osv-baseline.txt")"
zz_data="$(data_lines "${real_security_dir}/zizmor-baseline.txt")"
# The test asserts the form and the parseability of the baseline files only (the review finding S5): the content (the
# number of the lines, the packages) is the decision of the owner and of the repository, so deleting an old line or adding
# a line that the owner accepts must not stop this test. The level gate itself (above) has the rule for the levels.
check "no baseline file has a text of a record: each line of osv-baseline.txt is '<identifier> <package>@<version>' and each line of zizmor-baseline.txt has three words" \
    test -z "$(grep -v '^[A-Za-z0-9._-]* [^ ]*@[^ @]*$' <<<"${osv_data}")" -a -z "$(grep -v '^[a-z0-9-]* [^ ]* [^ ]*$' <<<"${zz_data}")"
check "CODEOWNERS covers the baseline files (the folder /tools/)" grep -Eq '^/tools/[[:space:]]+@dfch' "${REPO_ROOT}/.github/CODEOWNERS"

echo
echo "RESULT: ${passed} ok, ${failed} failed"
[[ ${failed} -eq 0 ]] || exit 1
