#!/usr/bin/env bash
# feat-8-traceability-security-gates, Tasks 120.100 to 120.130 (REQ-004, REQ-005, ACC-005, ACC-006)
#
# Test of the three security recipes (vuln-scan.sh, secret-scan.sh, workflow-scan.sh) and of the function that
# separates a finding from a failure of the tool (security_classify and run_security_tool in _security.sh).
#
# Usage: test-security-gates.sh
#
# ACC-005: each security recipe ends with exit code 0 for a finding and with an exit code that is not 0 for a failure of
# the tool. This test shows the two cases for each tool:
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
[[ -d "${fixtures}" ]] || die "No folder ${fixtures}"
[[ -f "${real_config}" ]] || die "No file ${real_config}"

work="$(mktemp -d)"
trap 'rm -rf "${work}"' EXIT
osv_version="$(version_of OSV_SCANNER_VERSION)"
osv_sha="$(version_of OSV_SCANNER_SHA256)"
gitleaks_version="$(version_of GITLEAKS_VERSION)"
gitleaks_sha="$(version_of GITLEAKS_SHA256)"

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

# A stub of OSV-Scanner. The install knows a folder with the binary, the file `.sha256` with the pin and the right
# version as "already installed", so the stub is started and nothing is downloaded. The stub writes its arguments to
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
exit "\${STUB_EXIT:-0}"
STUB
}

mk_osv_stub_home() {
    local home="$1"
    mkdir -p "${home}/osv-scanner-${osv_version}"
    stub_script "osv-scanner version: ${osv_version}" "--version" yes >"${home}/osv-scanner-${osv_version}/osv-scanner"
    chmod +x "${home}/osv-scanner-${osv_version}/osv-scanner"
    printf '%s\n' "${osv_sha}" >"${home}/osv-scanner-${osv_version}/.sha256"
}

osv_home="${work}/osv-stub-home"
mk_osv_stub_home "${osv_home}"
sbom="${work}/sbom"
mkdir -p "${sbom}"
echo '{"bomFormat":"CycloneDX","specVersion":"1.5","version":1,"components":[{"type":"library","name":"qs","version":"6.15.1","purl":"pkg:npm/qs@6.15.1","bom-ref":"pkg:npm/qs@6.15.1"}]}' >"${sbom}/backend.cdx.json"
echo '{"bomFormat":"CycloneDX","specVersion":"1.5","version":1,"components":[]}' >"${sbom}/frontend.cdx.json"
echo "not an sbom file" >"${sbom}/notes.txt"
echo '{}' >"${sbom}/other.json"
args_file="${work}/osv-args.txt"

run_vuln() { env OSV_SCANNER_HOME="${osv_home}" STUB_ARGS_FILE="${args_file}" "$@" "${GATES_DIR}/vuln-scan.sh" "${sbom}"; }

expect 0 "OSV-Scanner: no finding (exit code 0)" "vuln-scan: the stub has no finding, exit code 0" \
    run_vuln STUB_EXIT=0 STUB_OUTPUT="No issues found"
expect 0 "REPORT: Total 2 packages affected by 5 known vulnerabilities" "vuln-scan: the stub has findings (exit code 1), the recipe ends with exit code 0 and prints the summary (ACC-005)" \
    run_vuln STUB_EXIT=1 STUB_OUTPUT="Total 2 packages affected by 5 known vulnerabilities (0 Critical, 0 High, 5 Medium, 0 Low, 0 Unknown) from 1 ecosystem."
expect 0 "FINDINGS (exit code 1)" "vuln-scan: a finding says that the gate does not stop (no threshold)" \
    run_vuln STUB_EXIT=1 STUB_OUTPUT="Total 1 package affected by 1 known vulnerability (0 Critical, 0 High, 1 Medium, 0 Low, 0 Unknown) from 1 ecosystem."
expect 0 "Data: OSV.dev (https://osv.dev)" "vuln-scan: the attribution of the OSV data is in the output (the condition of the deviation)" \
    run_vuln STUB_EXIT=1 STUB_OUTPUT="Total 1 package affected by 1 known vulnerability"
expect_fail "FAILURE OF THE TOOL: OSV-Scanner ended with exit code 127" "vuln-scan: exit code 127 (general error, for example no network) of the tool stops the recipe (ACC-005)" \
    run_vuln STUB_EXIT=127 STUB_OUTPUT="Error during extraction: max retries exceeded"
expect_fail "FAILURE OF THE TOOL: OSV-Scanner ended with exit code 128" "vuln-scan: exit code 128 (no packages found) stops the recipe" \
    run_vuln STUB_EXIT=128 STUB_OUTPUT="No package sources found"
expect_fail "FAILURE OF THE TOOL: OSV-Scanner ended with exit code 2" "vuln-scan: another code stops the recipe" \
    run_vuln STUB_EXIT=2
expect_not 1 "REPORT:" "vuln-scan: a failure prints no REPORT line (the table of a failed run, with 0 packages, is not a report)" \
    run_vuln STUB_EXIT=127 STUB_OUTPUT="Total 0 packages affected by 0 known vulnerabilities (0 Critical, 0 High, 0 Medium, 0 Low, 0 Unknown) from 0 ecosystems."

# The arguments of the scan: -L for each *.cdx.json file, no other file, no --licenses
env OSV_SCANNER_HOME="${osv_home}" STUB_ARGS_FILE="${args_file}" STUB_EXIT=0 "${GATES_DIR}/vuln-scan.sh" "${sbom}" >/dev/null 2>&1 || true
if [[ "$(grep -c '^-L$' "${args_file}")" == "2" ]] && grep -qx "${sbom}/backend.cdx.json" "${args_file}" \
    && grep -qx "${sbom}/frontend.cdx.json" "${args_file}" && ! grep -q 'notes.txt\|other.json' "${args_file}" \
    && ! grep -q -- '--licenses' "${args_file}" && [[ "$(sed -n 1,2p "${args_file}" | tr '\n' ' ')" == "scan source " ]]; then
    echo "ok   vuln-scan: the tool is started with 'scan source', one -L for each *.cdx.json file, no other file and no --licenses"
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
    env OSV_SCANNER_HOME="${osv_home}" "${GATES_DIR}/vuln-scan.sh" "${empty_sbom}"
expect_fail "The folder of the SBOM files does not exist" "vuln-scan: a folder that does not exist stops the recipe" \
    env OSV_SCANNER_HOME="${osv_home}" "${GATES_DIR}/vuln-scan.sh" "${work}/no-such-folder"
expect_fail "Usage: vuln-scan.sh" "vuln-scan: no argument stops the recipe" env OSV_SCANNER_HOME="${osv_home}" "${GATES_DIR}/vuln-scan.sh"

# The install with the sha256 check. A small file is the "download" (a file:// URL, no network). The versions file of
# the case has the sha256 of that file, so the pin is checked in each case.
make_versions() { # make_versions <name> <key> <value> : a copy of versions.env with one value changed
    local file="${work}/versions-$1.env"
    sed -e "s/^$2=.*/$2=$3/" "${VERSIONS_FILE}" >"${file}"
    echo "${file}"
}
stub_file="${work}/osv-download"
stub_script "osv-scanner version: ${osv_version}" "--version" yes >"${stub_file}"
stub_sha="$(sha256sum "${stub_file}" | cut -d' ' -f1)"
versions_osv="$(make_versions osvgood OSV_SCANNER_SHA256 "${stub_sha}")"
install_home="${work}/osv-install-home"
started_file="${work}/osv-started.txt"
install_osv() { # install_osv <home> <url> <versions file>
    env OSV_SCANNER_HOME="$1" OSV_SCANNER_URL="$2" VERSIONS_FILE="$3" STUB_STARTED_FILE="${started_file}" \
        bash -c 'source "$1/_security.sh"; install_osv_scanner; echo "BIN=${OSV_SCANNER_BIN}"' _ "${GATES_DIR}"
}
expect 0 "sha256 is correct for the OSV-Scanner download" "install_osv_scanner: a file with the pinned sha256 is installed" \
    install_osv "${install_home}" "file://${stub_file}" "${versions_osv}"
if [[ -x "${install_home}/osv-scanner-${osv_version}/osv-scanner" && "$(cat "${install_home}/osv-scanner-${osv_version}/.sha256")" == "${stub_sha}" ]]; then
    echo "ok   install_osv_scanner: the binary is executable and the folder has the file .sha256 with the pin"
    passed=$((passed + 1))
else
    echo "FAIL install_osv_scanner: the binary or the file .sha256 is not in ${install_home}"
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
# A cache with another sha256 in the file `.sha256` is not trusted: a new download (here: it fails, there is no file)
mkdir -p "${work}/osv-stale-home"
cp -a "${osv_home}/osv-scanner-${osv_version}" "${work}/osv-stale-home/"
echo "0000000000000000000000000000000000000000000000000000000000000000" >"${work}/osv-stale-home/osv-scanner-${osv_version}/.sha256"
expect_fail "Download failed" "install_osv_scanner: a cache whose .sha256 is not the pin is not used" \
    install_osv "${work}/osv-stale-home" "file:///no/such/file" "${VERSIONS_FILE}"

# The REAL OSV-Scanner (the download of the release, the sha256 of the pin) without the network: a proxy that
# refuses the connection. This is the real failure of the tool (no network). The files of the SBOM have one package.
# The real binary is installed FIRST, here, with the network and the sha256 check (install_osv_scanner, no proxy
# variable is set in this shell). The proxy is set only for the start of the scan (the `env` of the case below), and
# not for the install: on a clean machine (a CI runner) build/tools/ has no binary, and a proxy that refuses the
# connection would also stop the download of the binary, which is not the case that this test shows.
real_osv_home="${REPO_ROOT}/build/tools"
OSV_SCANNER_HOME="${real_osv_home}" install_osv_scanner
check "the real OSV-Scanner has the pinned version ${osv_version}" test "$("${OSV_SCANNER_BIN}" --version | head -n 1)" == "osv-scanner version: ${osv_version}"
cat >"${work}/sbom-real.cdx.json" <<'JSON'
{"bomFormat":"CycloneDX","specVersion":"1.5","version":1,"components":[{"type":"library","name":"qs","version":"6.15.1","purl":"pkg:npm/qs@6.15.1","bom-ref":"pkg:npm/qs@6.15.1"}]}
JSON
mkdir -p "${work}/sbom-real"
cp "${work}/sbom-real.cdx.json" "${work}/sbom-real/frontend.cdx.json"
expect_fail "FAILURE OF THE TOOL: OSV-Scanner ended with exit code 127" "vuln-scan: the REAL OSV-Scanner without the network (a proxy that refuses the connection) ends with exit code 127, and the recipe stops (ACC-005)" \
    env OSV_SCANNER_HOME="${real_osv_home}" HTTPS_PROXY="http://127.0.0.1:9" HTTP_PROXY="http://127.0.0.1:9" https_proxy="http://127.0.0.1:9" http_proxy="http://127.0.0.1:9" \
    "${GATES_DIR}/vuln-scan.sh" "${work}/sbom-real"
mkdir -p "${work}/sbom-nopackage"
echo '{"bomFormat":"CycloneDX","specVersion":"1.5","version":1,"components":[]}' >"${work}/sbom-nopackage/frontend.cdx.json"
expect_fail "FAILURE OF THE TOOL: OSV-Scanner ended with exit code 128" "vuln-scan: the REAL OSV-Scanner with an SBOM that has no package ends with exit code 128, and the recipe stops (a scan of nothing must not pass)" \
    env OSV_SCANNER_HOME="${real_osv_home}" "${GATES_DIR}/vuln-scan.sh" "${work}/sbom-nopackage"
mkdir -p "${work}/sbom-broken"
echo '{this is not json' >"${work}/sbom-broken/frontend.cdx.json"
expect_fail "FAILURE OF THE TOOL: OSV-Scanner ended with exit code 127" "vuln-scan: the REAL OSV-Scanner with an SBOM file that cannot be read ends with exit code 127, and the recipe stops (ACC-005)" \
    env OSV_SCANNER_HOME="${real_osv_home}" "${GATES_DIR}/vuln-scan.sh" "${work}/sbom-broken"

# ======================================================================================================================
section "Part 3: secret-scan.sh (gitleaks)"

# A stub of gitleaks: `gitleaks version` gives the version, and each other start gives STUB_OUTPUT and STUB_EXIT.
mk_gitleaks_stub_home() {
    local home="$1"
    mkdir -p "${home}/gitleaks-${gitleaks_version}"
    stub_script "${gitleaks_version}" "version" >"${home}/gitleaks-${gitleaks_version}/gitleaks"
    chmod +x "${home}/gitleaks-${gitleaks_version}/gitleaks"
    printf '%s\n' "${gitleaks_sha}" >"${home}/gitleaks-${gitleaks_version}/.sha256"
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
run_secret() { # run_secret <repo> [env VAR=value...] : the recipe form, base origin/dev and the config of the repository
    local repo="$1"
    shift
    env GATE_WORK_ROOT="${repo}" "$@" "${GATES_DIR}/secret-scan.sh" origin/dev tools/security/gitleaks.toml
}

# --- the stub
gl_home="${work}/gitleaks-stub-home"
mk_gitleaks_stub_home "${gl_home}"
stub_repo="${work}/repo-stub"
mk_repo "${stub_repo}"
echo "some work" >"${stub_repo}/work.txt"
commit_all "${stub_repo}" "work"
gl_args="${work}/gitleaks-args.txt"

expect 0 "REPORT: files: 0 finding(s); history origin/dev..HEAD: 0 finding(s)" "secret-scan: the stub has no finding (exit code 0)" \
    run_secret "${stub_repo}" GITLEAKS_HOME="${gl_home}" STUB_EXIT=0 STUB_OUTPUT="INF no leaks found"
expect 0 "REPORT: files: 3 finding(s); history origin/dev..HEAD: 3 finding(s)" "secret-scan: the stub has findings (exit code 2), the recipe ends with exit code 0 and prints the counts (ACC-005)" \
    run_secret "${stub_repo}" GITLEAKS_HOME="${gl_home}" STUB_EXIT=2 STUB_OUTPUT="WRN leaks found: 3"
expect 0 "FINDINGS (exit code 2)" "secret-scan: a finding says that the gate does not stop (no threshold)" \
    run_secret "${stub_repo}" GITLEAKS_HOME="${gl_home}" STUB_EXIT=2 STUB_OUTPUT="WRN leaks found: 1"
expect_fail "FAILURE OF THE TOOL: gitleaks (files) ended with exit code 1" "secret-scan: exit code 1 of the tool (a fatal error) stops the recipe (ACC-005)" \
    run_secret "${stub_repo}" GITLEAKS_HOME="${gl_home}" STUB_EXIT=1 STUB_OUTPUT="FTL unable to load gitleaks config"
expect_fail "FAILURE OF THE TOOL: gitleaks (files) ended with exit code 126" "secret-scan: exit code 126 of the tool (a wrong flag) stops the recipe" \
    run_secret "${stub_repo}" GITLEAKS_HOME="${gl_home}" STUB_EXIT=126
expect_fail "no sign of a finding" "secret-scan: exit code 2 with no text 'leaks found' (a crash) stops the recipe" \
    run_secret "${stub_repo}" GITLEAKS_HOME="${gl_home}" STUB_EXIT=2 STUB_OUTPUT="panic: runtime error: index out of range"
expect_fail "has an error line" "secret-scan: an ERR line with exit code 0 (git cannot read the range) stops the recipe" \
    run_secret "${stub_repo}" GITLEAKS_HOME="${gl_home}" STUB_EXIT=0 STUB_OUTPUT="11:49AM ERR [git] fatal: ambiguous argument"
expect_not 1 "REPORT:" "secret-scan: a failure prints no REPORT line" \
    run_secret "${stub_repo}" GITLEAKS_HOME="${gl_home}" STUB_EXIT=1
# The arguments: the options that the plan and the script need (the last start is the scan of the history)
run_secret "${stub_repo}" GITLEAKS_HOME="${gl_home}" STUB_EXIT=0 STUB_ARGS_FILE="${gl_args}" >/dev/null 2>&1 || true
gl_all_ok=1
for option in git "$(git -C "${stub_repo}" rev-parse --absolute-git-dir)" --exit-code 2 --redact --ignore-gitleaks-allow --gitleaks-ignore-path --log-opts=origin/dev..HEAD --no-color; do
    grep -qxF -- "${option}" "${gl_args}" || gl_all_ok=0
done
if [[ ${gl_all_ok} -eq 1 ]] && grep -qx -- "--config" "${gl_args}" && grep -q 'tools/security/gitleaks.toml$' "${gl_args}"; then
    echo "ok   secret-scan: the tool is started with --config, --exit-code 2, --redact, --ignore-gitleaks-allow, --gitleaks-ignore-path and the log options base..HEAD"
    passed=$((passed + 1))
else
    echo "FAIL secret-scan: the arguments of the tool are not the expected ones"
    sed -e 's/^/     | /' "${gl_args}"
    failed=$((failed + 1))
fi
expect_fail "The base 'origin/nothing' does not exist" "secret-scan: a base that does not exist stops the recipe" \
    env GATE_WORK_ROOT="${stub_repo}" GITLEAKS_HOME="${gl_home}" "${GATES_DIR}/secret-scan.sh" origin/nothing tools/security/gitleaks.toml
expect_fail "The gitleaks config does not exist" "secret-scan: a config that does not exist stops the recipe" \
    env GATE_WORK_ROOT="${stub_repo}" GITLEAKS_HOME="${gl_home}" "${GATES_DIR}/secret-scan.sh" origin/dev tools/security/none.toml
expect_fail "Usage: secret-scan.sh" "secret-scan: no argument stops the recipe" env GATE_WORK_ROOT="${stub_repo}" GITLEAKS_HOME="${gl_home}" "${GATES_DIR}/secret-scan.sh"

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
    env GATE_WORK_ROOT="${shallow}" GITLEAKS_HOME="${gl_home}" "${GATES_DIR}/secret-scan.sh" origin/dev tools/security/gitleaks.toml
full="${work}/repo-full"
git clone --quiet "file://${shallow_src}" "${full}" 2>/dev/null
expect 0 "Base: origin/dev, merge base:" "secret-scan: a clone with the full history finds the merge base (stub)" \
    env GATE_WORK_ROOT="${full}" GITLEAKS_HOME="${gl_home}" STUB_EXIT=0 "${GATES_DIR}/secret-scan.sh" origin/dev tools/security/gitleaks.toml

# --- the install of gitleaks with the sha256 check (a file:// URL, no network)
gl_pkg="${work}/gl-pkg"
mkdir -p "${gl_pkg}"
stub_script "${gitleaks_version}" "version" >"${gl_pkg}/gitleaks"
chmod +x "${gl_pkg}/gitleaks"
echo "stub license" >"${gl_pkg}/LICENSE"
gl_archive="${work}/gitleaks-stub.tar.gz"
tar -C "${gl_pkg}" -czf "${gl_archive}" gitleaks LICENSE
gl_archive_sha="$(sha256sum "${gl_archive}" | cut -d' ' -f1)"
versions_gl="$(make_versions glgood GITLEAKS_SHA256 "${gl_archive_sha}")"
gl_started="${work}/gl-started.txt"
install_gl() { # install_gl <home> <url> <versions file>
    env GITLEAKS_HOME="$1" GITLEAKS_URL="$2" VERSIONS_FILE="$3" STUB_STARTED_FILE="${gl_started}" \
        bash -c 'source "$1/_security.sh"; install_gitleaks; echo "BIN=${GITLEAKS_BIN}"' _ "${GATES_DIR}"
}
expect 0 "sha256 is correct for the gitleaks download" "install_gitleaks: an archive with the pinned sha256 is installed" \
    install_gl "${work}/gl-install-home" "file://${gl_archive}" "${versions_gl}"
if [[ -x "${work}/gl-install-home/gitleaks-${gitleaks_version}/gitleaks" && -f "${work}/gl-install-home/gitleaks-${gitleaks_version}/LICENSE" \
    && "$(cat "${work}/gl-install-home/gitleaks-${gitleaks_version}/.sha256")" == "${gl_archive_sha}" ]]; then
    echo "ok   install_gitleaks: the folder has gitleaks, LICENSE and the file .sha256 with the pin"
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

# --- the REAL gitleaks in temporary repositories. The real binary is the install of the gate (build/tools/). It is
# installed here, with the network and the sha256 check, before the cases start the script (no case depends on a binary
# that an earlier run left in build/tools/, and no case sets a proxy or blocks the network).
install_gitleaks
real_gl="${GITLEAKS_BIN}"
check "the real gitleaks has the pinned version ${gitleaks_version}" test "$("${real_gl}" version)" == "${gitleaks_version}"

r="${work}/repo-clean"
mk_repo "${r}"
echo "some work" >"${r}/work.txt"
commit_all "${r}" "work"
expect 0 "REPORT: files: 0 finding(s); history origin/dev..HEAD: 0 finding(s)" "secret-scan (real gitleaks): a repository with no secret has no finding" run_secret "${r}"

r="${work}/repo-secret-file"
mk_repo "${r}"
fake_secret_line >"${r}/config.txt"
commit_all "${r}" "add a config"
expect 0 "REPORT: files: 1 finding(s); history origin/dev..HEAD: 1 finding(s)" "secret-scan (real gitleaks): a secret in a committed file is a finding in the files and in the history, the recipe ends with exit code 0 (ACC-005)" run_secret "${r}"
expect 0 "FINDINGS (exit code 2)" "secret-scan (real gitleaks): the finding has the exit code 2 of the tool" run_secret "${r}"
expect_not 0 "sk_live_51H8" "secret-scan (real gitleaks): the secret is redacted in the report" run_secret "${r}"
expect 0 "RuleID:      stripe-access-token" "secret-scan (real gitleaks): the report names the rule" run_secret "${r}"
expect 0 "File:        config.txt" "secret-scan (real gitleaks): the report names the file (a path relative to the repository)" run_secret "${r}"

r="${work}/repo-secret-history"
mk_repo "${r}"
fake_secret_line >"${r}/config.txt"
commit_all "${r}" "add a config"
git -C "${r}" rm --quiet config.txt
commit_all "${r}" "remove the config"
expect 0 "REPORT: files: 0 finding(s); history origin/dev..HEAD: 1 finding(s)" "secret-scan (real gitleaks): a secret that is only in the history of the pull request (deleted in a later commit) is a finding of the history" run_secret "${r}"

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
expect 0 "REPORT: files: 1 finding(s); history origin/dev..HEAD: 0 finding(s)" "secret-scan (real gitleaks): a secret in the base is a finding of the files, and not of the history of the pull request (the range is base..HEAD)" run_secret "${r}"

r="${work}/repo-secret-untracked"
mk_repo "${r}"
fake_secret_line >"${r}/not-committed.txt"
expect 0 "REPORT: files: 1 finding(s); history origin/dev..HEAD: 0 finding(s)" "secret-scan (real gitleaks): a secret in a file that is not committed is a finding of the files" run_secret "${r}"

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
expect 0 "files: 0 finding(s); history origin/dev..HEAD: 1 finding(s)" "secret-scan (real gitleaks): a file that git has and the work tree has deleted does not stop the copy (the history has the secret)" run_secret "${r}"

r="${work}/repo-secret-allow-comment"
mk_repo "${r}"
printf 'stripe = "sk_live_%s" # gitleaks:allow\n' "51H8jT2LkqW9xYzAbCdEfGhIjKlMn" >"${r}/config.txt"
commit_all "${r}" "add a config"
expect 0 "REPORT: files: 1 finding(s); history origin/dev..HEAD: 1 finding(s)" "secret-scan (real gitleaks): a comment gitleaks:allow does not hide a finding" run_secret "${r}"

r="${work}/repo-secret-ignorefile"
mk_repo "${r}"
fake_secret_line >"${r}/config.txt"
commit_all "${r}" "add a config"
fingerprint="$(git -C "${r}" rev-parse HEAD):config.txt:stripe-access-token:1"
printf '%s\nconfig.txt:stripe-access-token:1\n' "${fingerprint}" >"${r}/.gitleaksignore"
expect 0 "REPORT: files: 1 finding(s); history origin/dev..HEAD: 1 finding(s)" "secret-scan (real gitleaks): a .gitleaksignore file does not hide a finding" run_secret "${r}"

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

# ======================================================================================================================
section "Part 4: workflow-scan.sh (zizmor)"

wf="${work}/wf"
mkdir -p "${wf}/dir-clean/.github/workflows" "${wf}/dir-problem/.github/workflows" "${wf}/dir-both/.github/workflows" "${wf}/empty"
cp "${fixtures}/workflow-clean.yml" "${wf}/dir-clean/.github/workflows/clean.yml"
cp "${fixtures}/workflow-known-problem.yml" "${wf}/dir-problem/.github/workflows/problem.yml"
cp "${fixtures}/workflow-clean.yml" "${wf}/dir-both/.github/workflows/clean.yml"
cp "${fixtures}/workflow-unreadable.yml" "${wf}/dir-both/.github/workflows/unreadable.yml"
cp "${fixtures}/workflow-clean.yml" "${fixtures}/workflow-known-problem.yml" "${fixtures}/workflow-unreadable.yml" "${wf}/"
echo "nothing" >"${wf}/empty/readme.txt"
run_wf() { env GATE_WORK_ROOT="${wf}" "${GATES_DIR}/workflow-scan.sh" "$@"; }

expect 0 "zizmor: no finding (exit code 0)" "workflow-scan: a clean workflow file has no finding (exit code 0)" run_wf workflow-clean.yml
expect 0 "zizmor: no finding (exit code 0)" "workflow-scan: a folder .github/workflows with a clean workflow has no finding (exit code 0)" run_wf dir-clean/.github/workflows
expect 0 "FINDINGS (exit code 14)" "workflow-scan: a workflow with a known problem is a finding (zizmor exit code 14), the recipe ends with exit code 0 (ACC-005)" run_wf workflow-known-problem.yml
expect 0 "FINDINGS (exit code 14)" "workflow-scan: a folder .github/workflows with a known problem is a finding, the recipe ends with exit code 0" run_wf dir-problem/.github/workflows
expect 0 "error[template-injection]" "workflow-scan: the report names the known problem (template-injection)" run_wf workflow-known-problem.yml
expect 0 "error[dangerous-triggers]" "workflow-scan: the report names the known problem (dangerous-triggers)" run_wf workflow-known-problem.yml
expect 0 "REPORT: 7 findings" "workflow-scan: the summary line of zizmor is in the report" run_wf workflow-known-problem.yml
expect_fail "FAILURE OF THE TOOL: zizmor ended with exit code 1" "workflow-scan: a workflow file that zizmor cannot read stops the recipe (ACC-005)" run_wf workflow-unreadable.yml
expect_fail "FAILURE OF THE TOOL: zizmor ended with exit code 1" "workflow-scan: a folder with a good and a bad file stops the recipe (--strict-collection)" run_wf dir-both/.github/workflows
expect_fail "FAILURE OF THE TOOL: zizmor ended with exit code 3" "workflow-scan: a folder with no workflow (no inputs) stops the recipe" run_wf empty
expect_fail "The path does not exist" "workflow-scan: a path that does not exist stops the recipe" run_wf nothing-here
expect_fail "Usage: workflow-scan.sh" "workflow-scan: no argument stops the recipe" run_wf
expect 0 "FINDINGS (exit code 14)" "workflow-scan: more than one path (a clean file and a file with a problem) gives the findings of both" run_wf workflow-clean.yml workflow-known-problem.yml

# the mode of zizmor is explicit: a token in the environment does not start the online audits
expect 0 "zizmor: no finding (exit code 0)" "workflow-scan: a token in the environment (GITHUB_TOKEN) does not change the offline mode" \
    env GITHUB_TOKEN="not-a-real-token" GH_TOKEN="not-a-real-token" GATE_WORK_ROOT="${wf}" "${GATES_DIR}/workflow-scan.sh" workflow-clean.yml

# ======================================================================================================================
section "Part 5: the form of the scripts and of the recipes"

check "vuln-scan.sh does not use the option --licenses (the condition of the OSV deviation)" bash -c "! grep -v '^[[:space:]]*#' '${GATES_DIR}/vuln-scan.sh' | grep -q -- '--licenses'"
check "vuln-scan.sh reads the SBOM files with -L and uses --no-resolve" bash -c "grep -v '^[[:space:]]*#' '${GATES_DIR}/vuln-scan.sh' | grep -q -- 'scan source --no-resolve' && grep -v '^[[:space:]]*#' '${GATES_DIR}/vuln-scan.sh' | grep -q -- '-L '"
check "workflow-scan.sh starts zizmor with --offline" bash -c "grep -v '^[[:space:]]*#' '${GATES_DIR}/workflow-scan.sh' | grep -q -- '--offline'"
check "workflow-scan.sh starts zizmor with --strict-collection" bash -c "grep -v '^[[:space:]]*#' '${GATES_DIR}/workflow-scan.sh' | grep -q -- '--strict-collection'"
check "secret-scan.sh has --exit-code 2, --redact and --ignore-gitleaks-allow" bash -c "grep -v '^[[:space:]]*#' '${GATES_DIR}/secret-scan.sh' | grep -q -- '--exit-code 2' && grep -v '^[[:space:]]*#' '${GATES_DIR}/secret-scan.sh' | grep -q -- '--redact' && grep -v '^[[:space:]]*#' '${GATES_DIR}/secret-scan.sh' | grep -q -- '--ignore-gitleaks-allow'"
for script in vuln-scan.sh secret-scan.sh workflow-scan.sh test-security-gates.sh _security.sh; do
    check "${script} is executable" test -x "${GATES_DIR}/${script}"
done
justfile="${REPO_ROOT}/justfile"
just_recipe() { # just_recipe <recipe> <text in the body> : the justfile has the recipe with the text in its lines
    just --justfile "${justfile}" --show "$1" 2>/dev/null | grep -q -- "$2"
}
check "the justfile has the recipe vuln-scan with the prerequisite sbom" bash -c "just --justfile '${justfile}' --show vuln-scan | grep -q '^vuln-scan: sbom\$'"
check "the recipe vuln-scan starts vuln-scan.sh with the SBOM folder" just_recipe vuln-scan "_gate vuln-scan.sh"
check "the recipe secret-scan starts secret-scan.sh with the base and the config" just_recipe secret-scan "secret-scan.sh 120.120 \"{{ base }}\" tools/security/gitleaks.toml"
check "the recipe workflow-scan starts workflow-scan.sh with .github/workflows" just_recipe workflow-scan "workflow-scan.sh 120.130 .github/workflows"
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

echo
echo "RESULT: ${passed} ok, ${failed} failed"
[[ ${failed} -eq 0 ]] || exit 1
