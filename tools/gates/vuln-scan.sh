#!/usr/bin/env bash
# feat-8-traceability-security-gates, Task 120.110 (REQ-004, REQ-005, REQ-007, ACC-005, ACC-006), and
# feat-9-walking-skeleton, Task 500.120 (REQ-006, ACC-007: the level gate)
#
# Gate 9, part 1 (DEC 361678a6-f941-473b-a058-1ba2bacf7d3d): the known vulnerabilities in the dependencies, with
# OSV-Scanner. Since feat-9 it is a BLOCKING gate: a finding that is Critical or High stops, a finding that is not in
# the baseline file stops, and a line of the baseline that has no finding any more is a warning (the level gate:
# security_level_gate in _security.sh and security_threshold.py).
#
# Usage: vuln-scan.sh <sbom dir> <baseline file>
#   <sbom dir>       the folder with the SBOM files of `just sbom`, for example build/sbom. The recipe `vuln-scan` has
#                    `sbom` as a prerequisite, so the files are new. The script reads the files <sbom dir>/*.cdx.json
#                    (CycloneDX, JSON), and the other files of the folder are not read.
#   <baseline file>  tools/security/osv-baseline.txt: one line for each finding of the state of the feature, the OSV
#                    identifier and the package (`GHSA-4mjr-xmp4-gh2g qs@6.15.1`). The file has counts and identifiers
#                    only (the condition of the deviation of the OSV data). The file must exist, also if it has no line.
#
# What the script does:
#   1. It stops if the folder has no *.cdx.json file, or the baseline file does not exist. A missing input must not make
#      the gate pass.
#   2. It installs OSV-Scanner with a checksum (install_osv_scanner in _security.sh: download, sha256 of
#      OSV_SCANNER_SHA256 of tools/versions.env, build/tools/), and a Python without a package for the level gate
#      (make_python_bare_env in _lib.sh).
#   3. It starts `osv-scanner scan source --no-resolve --format json --output-file <report> -L <file> ...` (one start,
#      one `-L` for each file). The scanner asks api.osv.dev (the network is needed) and writes the report (JSON) to a
#      temporary file (it is not in the repository). The script does NOT use the option --licenses: the deviation of
#      the OSV data in DEC 93a6d588-e002-4daf-9a47-45e2d77786e9 allows the use as a report of vulnerabilities only.
#   4. It separates a finding from a failure of the tool (run_security_tool in _security.sh):
#        exit code 0 of the tool    no vulnerability
#        exit code 1 of the tool    vulnerabilities found (a finding: the level gate decides)
#        each other exit code       a failure of the tool (127 general error, for example no network or a file that
#                                   cannot be read; 128 no packages found). The gate stops.
#   5. For a finding (and for no finding) it starts the level gate with the baseline file (security_level_gate). The
#      script prints the findings with the level (the CVSS score of the record), the identifier, the package and the state
#      (baseline or NEW). It prints no advisory text.
#
# The conditions of the deviation for the OSV data (DEC 93a6d588-e002-4daf-9a47-45e2d77786e9, the section of OSV data):
# a report only (now: a gate that uses the identifiers and the level, and no copy of a record); the repository keeps
# counts and finding identifiers only (the baseline file); no copy of the records; the attribution is kept (the text that
# the script prints after the report, and tools/security/README.md).
#
# Exit codes: 0 the gate passes (no new finding, no finding that is Critical or High); 1 a new finding, a finding that
# is Critical or High, a failure of the tool, a missing input or a download with another checksum. The script does not
# change the repository. OSV-Scanner goes to build/tools/ (it is in .gitignore).

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/_security.sh"

[[ $# -eq 2 ]] || die "Usage: vuln-scan.sh <sbom dir> <baseline file>"
sbom_dir="$1"
baseline="$2"
[[ -d "${sbom_dir}" ]] || die "The folder of the SBOM files does not exist: ${sbom_dir}. Run 'just sbom' first (the recipe vuln-scan does it)."
[[ -f "${baseline}" ]] || die "The baseline file does not exist: ${baseline}. The file must exist (it can have no line). The gate does not pass without it."

shopt -s nullglob
sbom_files=("${sbom_dir}"/*.cdx.json)
shopt -u nullglob
[[ ${#sbom_files[@]} -gt 0 ]] || die "The folder ${sbom_dir} has no *.cdx.json file. There is nothing to scan, and a scan of nothing must not pass."

install_osv_scanner
make_python_bare_env
report="${GATE_ENV_DIR}/osv-report.json"

args=(scan source --no-resolve --format json --output-file "${report}")
for file in "${sbom_files[@]}"; do
    args+=(-L "${file}")
done
log "OSV-Scanner $(version_of OSV_SCANNER_VERSION): ${#sbom_files[@]} SBOM file(s) in ${sbom_dir} (online query of api.osv.dev, level gate with the baseline ${baseline})"
status=0
run_security_tool "OSV-Scanner" "1" "" "" -- "${OSV_SCANNER_BIN}" "${args[@]}" || status=1

if [[ "${SECURITY_RESULT}" != "failure" ]]; then
    security_level_gate "OSV-Scanner" osv "${baseline}" "${report}" || status=1
    log "Data: OSV.dev (https://osv.dev). The records come from several sources with their own licenses (for example the GitHub Advisory Database, CC-BY 4.0). The report is not stored: the repository keeps counts and finding identifiers only (DEC 93a6d588-e002-4daf-9a47-45e2d77786e9)."
fi
exit "${status}"
