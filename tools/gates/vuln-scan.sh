#!/usr/bin/env bash
# feat-8-traceability-security-gates, Task 120.110 (REQ-004, REQ-005, REQ-007, ACC-005, ACC-006)
#
# Gate 9, part 1 (DEC 361678a6-f941-473b-a058-1ba2bacf7d3d): the known vulnerabilities in the dependencies, with
# OSV-Scanner. It is a REPORT with no threshold: a finding does not stop the gate.
#
# Usage: vuln-scan.sh <sbom dir>
#   <sbom dir>  the folder with the SBOM files of `just sbom`, for example build/sbom. The recipe `vuln-scan` has
#               `sbom` as a prerequisite, so the files are new. The script reads the files <sbom dir>/*.cdx.json
#               (CycloneDX, JSON), and the other files of the folder are not read.
#
# What the script does:
#   1. It stops if the folder has no *.cdx.json file. A missing input must not make the gate pass.
#   2. It installs OSV-Scanner with a checksum (install_osv_scanner in _security.sh: download, sha256 of
#      OSV_SCANNER_SHA256 of tools/versions.env, build/tools/).
#   3. It starts `osv-scanner scan source --no-resolve -L <file> ...` (one start, one `-L` for each file). The
#      scanner asks api.osv.dev (the network is needed) and prints a table of the vulnerabilities. The script does NOT
#      use the option --licenses: the deviation of the OSV data in DEC 93a6d588-e002-4daf-9a47-45e2d77786e9 allows the
#      use as a report of vulnerabilities only.
#   4. It separates a finding from a failure of the tool (run_security_tool in _security.sh):
#        exit code 0 of the tool    no vulnerability
#        exit code 1 of the tool    vulnerabilities found (a finding, the report is the result)
#        each other exit code       a failure of the tool (127 general error, for example no network or a file that
#                                   cannot be read; 128 no packages found). The gate stops.
#
# The conditions of the deviation for the OSV data (DEC 93a6d588-e002-4daf-9a47-45e2d77786e9, the section of OSV data):
# a report only; the repository keeps counts and finding identifiers only (the plan); no copy of the records; the
# attribution is kept (the text that the script prints after the report, and tools/security/README.md).
#
# Exit codes: 0 the report is done (with or without a finding); 1 a failure of the tool, a missing input or a
# download with another checksum. The script does not change the repository. OSV-Scanner goes to build/tools/ (it is
# in .gitignore).

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/_security.sh"

[[ $# -eq 1 ]] || die "Usage: vuln-scan.sh <sbom dir>"
sbom_dir="$1"
[[ -d "${sbom_dir}" ]] || die "The folder of the SBOM files does not exist: ${sbom_dir}. Run 'just sbom' first (the recipe vuln-scan does it)."

shopt -s nullglob
sbom_files=("${sbom_dir}"/*.cdx.json)
shopt -u nullglob
[[ ${#sbom_files[@]} -gt 0 ]] || die "The folder ${sbom_dir} has no *.cdx.json file. There is nothing to scan, and a scan of nothing must not pass."

install_osv_scanner

args=(scan source --no-resolve)
for file in "${sbom_files[@]}"; do
    args+=(-L "${file}")
done
log "OSV-Scanner $(version_of OSV_SCANNER_VERSION): ${#sbom_files[@]} SBOM file(s) in ${sbom_dir} (online query of api.osv.dev, no threshold)"
status=0
run_security_tool "OSV-Scanner" "1" "" "" -- "${OSV_SCANNER_BIN}" "${args[@]}" || status=1

if [[ "${SECURITY_RESULT}" != "failure" ]]; then
    summary="$(grep -E '^Total [0-9]+ packages? affected by [0-9]+ known vulnerabilit' <<<"${SECURITY_OUTPUT}" | head -n 1 || true)"
    if [[ -n "${summary}" ]]; then
        log "REPORT: ${summary}"
    else
        log "REPORT: no vulnerability found in ${#sbom_files[@]} SBOM file(s)"
    fi
    log "Data: OSV.dev (https://osv.dev). The records come from several sources with their own licenses (for example the GitHub Advisory Database, CC-BY 4.0). The report is not stored: the repository keeps counts and finding identifiers only (DEC 93a6d588-e002-4daf-9a47-45e2d77786e9)."
fi
exit "${status}"
