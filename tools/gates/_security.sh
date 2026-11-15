#!/usr/bin/env bash
# feat-8-traceability-security-gates, Tasks 120.100 to 120.120 (REQ-004, REQ-005, ACC-005, ACC-006)
#
# Shared shell helpers for the security gates (vuln-scan.sh, secret-scan.sh, workflow-scan.sh). Do not run it.
# Source it instead:
#
#   source "$(dirname "${BASH_SOURCE[0]}")/_security.sh"
#
# It sources _lib.sh. It has two parts:
#
#   1. The function that separates a finding from a failure of the tool (security_classify, run_security_tool).
#   2. The install of the two binaries OSV-Scanner and gitleaks, with the sha256 check (install_osv_scanner,
#      install_gitleaks). zizmor is a Python package, and make_python_env (in _lib.sh) installs it from its lock file.
#
# The three security tools run as REPORTS with no threshold (REQ-005). A finding is part of the report, and the gate
# ends with exit code 0. A failure of the tool (no network, a file that cannot be read, a wrong configuration, a
# missing binary, a download with another checksum) ends the gate with a non-zero exit code. The gate must never pass
# because the tool did not run: a report with no finding and a tool that did not run look the same to a reader.

source "$(dirname "${BASH_SOURCE[0]}")/_lib.sh"

# security_classify <exit code of the tool> [<exit code that means a finding>...]
#
# Prints one word on stdout:
#   clean    the exit code is 0: the tool ran and has no finding
#   finding  the exit code is one of the finding codes: the tool ran and has at least one finding
#   failure  each other exit code (also a value that is not a number): the tool did not run to the end
#
# The finding codes are the exit codes that the tool documents for "findings", and no other. Each other non-zero exit
# code is a failure of the tool, also if the tool does not document it (a new release can add one: it then stops the
# gate and does not pass in silence). The codes of the three tools (checked for the pinned releases, 2026-11-15):
#   OSV-Scanner 2.7.1  0 no vulnerability, 1 vulnerabilities found. 127 general error, 128 no packages found, and the
#                      other codes are failures (https://google.github.io/osv-scanner/output/, "Return Codes").
#                      The run without network gives 127 and prints a report with no package.
#   gitleaks 8.30.1    0 no leak. With --exit-code 2 the code 2 is "leaks found". Other codes are failures: 1 is a
#                      fatal error (a wrong configuration, a path that does not exist), 126 is a wrong flag.
#                      A git error of the range (--log-opts) gives exit code 0 and an ERR line: see run_security_tool.
#   zizmor 1.32.0      0 no finding. 11, 12, 13 and 14 are findings (the highest level: informational, low, medium,
#                      high). 1 is an error of the audit, 2 is a wrong argument, 3 is "no inputs collected"
#                      (https://docs.zizmor.sh/usage/, "Exit codes").
security_classify() {
    local code="${1:-}" finding_code
    shift || true
    if [[ ! "${code}" =~ ^[0-9]+$ ]]; then
        echo failure
        return 0
    fi
    if [[ "${code}" -eq 0 ]]; then
        echo clean
        return 0
    fi
    for finding_code in "$@"; do
        if [[ "${code}" == "${finding_code}" ]]; then
            echo finding
            return 0
        fi
    done
    echo failure
}

# run_security_tool <label> <finding codes> <finding marker> <failure marker> -- <command> [<argument>...]
#
#   <label>          the name of the tool for the messages (for example "OSV-Scanner")
#   <finding codes>  the exit codes of the tool for "findings", separated by spaces (for example "11 12 13 14")
#   <finding marker> an extended regular expression, or "" for none. With a marker, an exit code for a finding is
#                    accepted only if the output of the tool has the text. A crash of the program can have the same
#                    exit code as a finding (a Go program that panics ends with exit code 2, and gitleaks uses 2 for
#                    "leaks found"), so the code alone is not enough for such a tool.
#   <failure marker> an extended regular expression, or "" for none. If the output has the text, the run is a
#                    failure, also with exit code 0 or with a finding code (gitleaks logs an ERR line and ends with
#                    exit code 0 if git cannot read the range of commits).
#
# It starts the command with the output (stdout and stderr) in one stream, writes the output, and sets
#   SECURITY_RESULT   clean, finding or failure
#   SECURITY_EXIT     the exit code of the tool
#   SECURITY_OUTPUT   the output of the tool
# It returns 0 for clean and finding (the report is the result), and 1 for failure. The caller decides what to do
# with a failure (the scripts run each part, and then end with exit code 1). It does not stop the script by itself.
# The text of the verdict goes to stdout for a finding and to stderr for a failure.
run_security_tool() {
    local label="$1" finding_codes="$2" finding_marker="$3" failure_marker="$4" out code errexit=0
    [[ $# -ge 6 && "$5" == "--" ]] || die "run_security_tool: usage: run_security_tool <label> <finding codes> <finding marker> <failure marker> -- <command>..."
    shift 5
    out="$(mktemp)"
    # The function sets the state of `set -e` back to what the caller had.
    [[ "$-" == *e* ]] && errexit=1
    set +e
    "$@" >"${out}" 2>&1
    code=$?
    [[ ${errexit} -eq 1 ]] && set -e
    SECURITY_EXIT="${code}"
    SECURITY_OUTPUT="$(cat "${out}")"
    rm -f "${out}"
    printf '%s\n' "${SECURITY_OUTPUT}"
    # shellcheck disable=SC2086 # the finding codes are a list of words
    SECURITY_RESULT="$(security_classify "${code}" ${finding_codes})"
    if [[ "${SECURITY_RESULT}" == "finding" && -n "${finding_marker}" ]] && ! grep -Eq -- "${finding_marker}" <<<"${SECURITY_OUTPUT}"; then
        echo "[$(basename "${0}")] ${label} ended with exit code ${code}, which is a code for findings, but the output has no sign of a finding (the text '${finding_marker}'). The run is treated as a failure of the tool." >&2
        SECURITY_RESULT="failure"
    fi
    if [[ "${SECURITY_RESULT}" != "failure" && -n "${failure_marker}" ]] && grep -Eq -- "${failure_marker}" <<<"${SECURITY_OUTPUT}"; then
        echo "[$(basename "${0}")] The output of ${label} has an error line (the text '${failure_marker}'), so the run is treated as a failure of the tool, also if the exit code is ${code}." >&2
        SECURITY_RESULT="failure"
    fi
    case "${SECURITY_RESULT}" in
        clean)
            log "${label}: no finding (exit code ${code})."
            ;;
        finding)
            log "${label}: FINDINGS (exit code ${code}). The output above is the report. The gate does not stop for a finding (no threshold)."
            ;;
        failure)
            echo "[$(basename "${0}")] FAILURE OF THE TOOL: ${label} ended with exit code ${code}. The finding codes of the tool are: ${finding_codes}. This is not a finding, so the gate stops." >&2
            return 1
            ;;
    esac
    return 0
}

# _fetch_verified <label> <sha key> <url> <expected sha256> <destination file>
#
# Downloads <url> with curl to <destination file>, compares the sha256 of the file with <expected sha256> (the value of
# tools/versions.env, never a value from the server), and deletes the file and returns 1 (with a message on stderr) if
# the download fails or the value is not the same. The caller removes its work folder and stops. The caller opens or
# starts the file only after this function returns 0.
_fetch_verified() {
    local label="$1" sha_key="$2" url="$3" want="$4" dest="$5" actual
    require_cmd curl
    log "Download ${url}"
    if ! curl -fsSL --retry 3 -o "${dest}" "${url}"; then
        rm -f "${dest}"
        echo "[$(basename "${0}")] ERROR: Download failed: ${url}" >&2
        return 1
    fi
    actual="$(sha256sum "${dest}" | cut -d' ' -f1)"
    if [[ "${actual}" != "${want}" ]]; then
        rm -f "${dest}"
        echo "[$(basename "${0}")] ERROR: sha256 of the ${label} download is ${actual}, but ${sha_key} in ${VERSIONS_FILE} is ${want}. The download is deleted. ${label} did not start." >&2
        return 1
    fi
    log "sha256 is correct for the ${label} download"
}

# _check_platform <label> <sha key> -- the pins of the security binaries are for Linux x86_64 only
_check_platform() {
    [[ "$(uname -s)" == "Linux" && "$(uname -m)" == "x86_64" ]] \
        || die "$1 is pinned for Linux x86_64 only ($2 is the checksum of the linux x86_64 file). This machine is $(uname -s) $(uname -m)."
}

# install_osv_scanner
#
# Installs OSV-Scanner (feat-8-traceability-security-gates, Task 120.110, ACC-006) and sets OSV_SCANNER_BIN to its
# path. The release file osv-scanner_linux_amd64 is the binary (no archive), so the install is the same as
# install_oasdiff without the unpack:
#
#   1. The script stops if the machine is not Linux x86_64.
#   2. If <home>/osv-scanner-<version>/osv-scanner exists, its first line of `--version` is
#      `osv-scanner version: <OSV_SCANNER_VERSION>`, and the file `.sha256` of the folder has OSV_SCANNER_SHA256,
#      the script does not download again. A change of the version or of the sha256 in tools/versions.env makes a
#      new download.
#   3. If not, it downloads the file with curl, compares its sha256 with OSV_SCANNER_SHA256 BEFORE it makes the file
#      executable, and stops (the download is deleted) if the value is not the same.
#   4. It stops if `osv-scanner --version` has another version.
#
# Variables for the tests: OSV_SCANNER_HOME (the folder for the install; the default is build/tools of this
# repository, and /build/ is in .gitignore) and OSV_SCANNER_URL (another URL for the file, for example a file:// URL;
# the sha256 is compared with the pin in each case, so another URL gives no other trust). The first run needs the
# network (GitHub).
install_osv_scanner() {
    local version sha home target url work first_line
    version="$(version_of OSV_SCANNER_VERSION)"
    sha="$(version_of OSV_SCANNER_SHA256)"
    [[ "${version}" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || die "OSV_SCANNER_VERSION is not an exact version: '${version}'"
    [[ "${sha}" =~ ^[0-9a-f]{64}$ ]] || die "OSV_SCANNER_SHA256 is not a sha256 value (64 lower case hexadecimal characters): '${sha}'"
    _check_platform "OSV-Scanner" "OSV_SCANNER_SHA256"
    require_cmd sha256sum
    home="${OSV_SCANNER_HOME:-${REPO_ROOT}/build/tools}"
    target="${home}/osv-scanner-${version}"
    OSV_SCANNER_BIN="${target}/osv-scanner"

    if [[ -x "${OSV_SCANNER_BIN}" && -f "${target}/.sha256" && "$(cat "${target}/.sha256")" == "${sha}" ]] \
        && [[ "$("${OSV_SCANNER_BIN}" --version 2>/dev/null | head -n 1)" == "osv-scanner version: ${version}" ]]; then
        log "OSV-Scanner ${version} is already installed in ${target}"
        return 0
    fi

    url="${OSV_SCANNER_URL:-https://github.com/google/osv-scanner/releases/download/v${version}/osv-scanner_linux_amd64}"
    mkdir -p "${home}"
    work="$(mktemp -d "${home}/.osv-scanner.XXXXXX")"
    _fetch_verified "OSV-Scanner" "OSV_SCANNER_SHA256" "${url}" "${sha}" "${work}/osv-scanner" || { rm -rf "${work}"; exit 1; }
    chmod 0755 "${work}/osv-scanner"
    printf '%s\n' "${sha}" >"${work}/.sha256"
    rm -rf "${target}"
    mkdir -p "${target}"
    mv "${work}/osv-scanner" "${work}/.sha256" "${target}/"
    rm -rf "${work}"
    first_line="$("${OSV_SCANNER_BIN}" --version 2>/dev/null | head -n 1)" || die "${OSV_SCANNER_BIN} does not start."
    [[ "${first_line}" == "osv-scanner version: ${version}" ]] \
        || { rm -rf "${target}"; die "${OSV_SCANNER_BIN} says '${first_line}', but OSV_SCANNER_VERSION in ${VERSIONS_FILE} is '${version}'."; }
    log "OSV-Scanner ${version} is in ${target}"
}

# install_gitleaks
#
# Installs gitleaks (feat-8-traceability-security-gates, Task 120.120, ACC-006) and sets GITLEAKS_BIN to its path. The
# release file is gitleaks_<version>_linux_x64.tar.gz, and the install is the same as install_oasdiff:
#
#   1. The script stops if the machine is not Linux x86_64.
#   2. If <home>/gitleaks-<version>/gitleaks exists, `gitleaks version` is GITLEAKS_VERSION, and the file `.sha256`
#      of the folder has GITLEAKS_SHA256, the script does not download again.
#   3. If not, it downloads the archive with curl, compares its sha256 with GITLEAKS_SHA256 BEFORE it unpacks the
#      file, and stops (the download is deleted) if the value is not the same. It unpacks only `gitleaks` and `LICENSE`.
#   4. It stops if `gitleaks version` has another version.
#
# Variables for the tests: GITLEAKS_HOME and GITLEAKS_URL (as OSV_SCANNER_HOME and OSV_SCANNER_URL).
install_gitleaks() {
    local version sha home target url work installed
    version="$(version_of GITLEAKS_VERSION)"
    sha="$(version_of GITLEAKS_SHA256)"
    [[ "${version}" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || die "GITLEAKS_VERSION is not an exact version: '${version}'"
    [[ "${sha}" =~ ^[0-9a-f]{64}$ ]] || die "GITLEAKS_SHA256 is not a sha256 value (64 lower case hexadecimal characters): '${sha}'"
    _check_platform "gitleaks" "GITLEAKS_SHA256"
    require_cmd tar
    require_cmd sha256sum
    home="${GITLEAKS_HOME:-${REPO_ROOT}/build/tools}"
    target="${home}/gitleaks-${version}"
    GITLEAKS_BIN="${target}/gitleaks"

    if [[ -x "${GITLEAKS_BIN}" && -f "${target}/.sha256" && "$(cat "${target}/.sha256")" == "${sha}" ]] \
        && [[ "$("${GITLEAKS_BIN}" version 2>/dev/null)" == "${version}" ]]; then
        log "gitleaks ${version} is already installed in ${target}"
        return 0
    fi

    url="${GITLEAKS_URL:-https://github.com/gitleaks/gitleaks/releases/download/v${version}/gitleaks_${version}_linux_x64.tar.gz}"
    mkdir -p "${home}"
    work="$(mktemp -d "${home}/.gitleaks.XXXXXX")"
    _fetch_verified "gitleaks" "GITLEAKS_SHA256" "${url}" "${sha}" "${work}/archive.tar.gz" || { rm -rf "${work}"; exit 1; }
    mkdir -p "${work}/unpacked"
    tar -xzf "${work}/archive.tar.gz" -C "${work}/unpacked" gitleaks LICENSE \
        || { rm -rf "${work}"; die "The gitleaks download has not the files gitleaks and LICENSE."; }
    printf '%s\n' "${sha}" >"${work}/unpacked/.sha256"
    rm -rf "${target}"
    mv "${work}/unpacked" "${target}"
    rm -rf "${work}"
    installed="$("${GITLEAKS_BIN}" version 2>/dev/null)" || die "${GITLEAKS_BIN} does not start."
    [[ "${installed}" == "${version}" ]] \
        || { rm -rf "${target}"; die "${GITLEAKS_BIN} says '${installed}', but GITLEAKS_VERSION in ${VERSIONS_FILE} is '${version}'."; }
    log "gitleaks ${version} is in ${target}"
}
