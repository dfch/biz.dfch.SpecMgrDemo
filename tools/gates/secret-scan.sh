#!/usr/bin/env bash
# feat-8-traceability-security-gates, Task 120.120 (REQ-004, REQ-005, ACC-005, ACC-006)
#
# Gate 9, part 2 (DEC 361678a6-f941-473b-a058-1ba2bacf7d3d): secrets in the files and in the history of the pull
# request, with gitleaks. It is a REPORT with no threshold: a finding does not stop the gate.
#
# Usage: secret-scan.sh <base> <config>
#   <base>    the branch that the pull request goes to, for example origin/dev (the variable `base` of the
#             `justfile`; see "The base of the comparison" in tools/gates/README.md)
#   <config>  the gitleaks configuration with the allowlist, for example tools/security/gitleaks.toml. The path is
#             relative to the repository (GATE_WORK_ROOT in the tests). CODEOWNERS covers the folder tools/.
#
# What the script does (two scans, and the script runs both before it decides):
#   1. The FILES. It copies the files that git knows or that .gitignore does not ignore (`git ls-files --cached
#      --others --exclude-standard`, so a file that is not committed yet is in the copy, and node_modules, target and
#      build are not) to a temporary folder, and starts `gitleaks dir .` in the copy (so the paths in the report, and
#      in the `paths` of the allowlist, are relative to the repository). The copy has the deleted files out, and it has
#      no `.gitleaksignore` file of the root (see below).
#   2. The HISTORY of the pull request: `gitleaks git --log-opts <base>..HEAD`, the commits that are in HEAD and not
#      in <base>. The commits of the base are not scanned again (the commits of an earlier pull request are the
#      business of that pull request). The history needs `fetch-depth: 0` in `actions/checkout`, as commit-check.sh:
#      a shallow clone that has no merge base of <base> and HEAD stops the script (exit code 1), because a scan of
#      the commits that happen to be in a shallow clone would pass for a range that it did not see.
#      The source of this scan is the git folder of the repository (`git rev-parse --absolute-git-dir`), and not the
#      work tree: gitleaks reads the file `.gitleaksignore` of the source folder of a scan, and the option
#      --gitleaks-ignore-path does not stop it (checked for the pinned release: with the work tree as the source a
#      `.gitleaksignore` file hides a finding of the history).
#   Each run uses the config (the default rules of gitleaks, `useDefault = true`, and the allowlist with one entry and
#   a reason for each false positive). The options are:
#     --redact                         the report shows no secret (the log of CI is public for a public repository)
#     --ignore-gitleaks-allow          a comment `gitleaks:allow` in a file does not hide a finding
#     --gitleaks-ignore-path <empty>   a file `.gitleaksignore` does not hide a finding
#   So the allowlist in the config (covered by CODEOWNERS) is the one place that hides a finding.
#
# The script separates a finding from a failure of the tool (run_security_tool in _security.sh). The exit code of
# gitleaks for "leaks found" is set with --exit-code 2 (the default is 1, which is also the code of a fatal error, so the
# default cannot separate the two):
#        exit code 0    no leak
#        exit code 2    leaks found (a finding; the output must have the text "leaks found")
#        each other     a failure of the tool (1 is a fatal error: a wrong config, a path that does not exist;
#                       126 is a wrong flag)
#   One case has the exit code 0 and is a failure: git cannot read the range, and gitleaks logs an ERR line. The
#   script treats an output with an ERR or FTL line as a failure.
#
# Exit codes: 0 the report is done (with or without a finding); 1 a failure of the tool, a base that does not exist,
# a shallow clone with no merge base, a config that does not exist, or a download with another checksum. The script does
# not change the repository. gitleaks goes to build/tools/ (it is in .gitignore).

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/_security.sh"

[[ $# -eq 2 ]] || die "Usage: secret-scan.sh <base> <config>"
base="$1"
config="$2"

require_cmd git
require_cmd tar
cd "${WORK_ROOT}"
[[ -f "${config}" ]] || die "The gitleaks config does not exist: ${config}"
git rev-parse --verify --quiet "${base}^{commit}" >/dev/null \
    || die "The base '${base}' does not exist. In CI, actions/checkout needs fetch-depth: 0."
if ! merge_base="$(git merge-base "${base}" HEAD)"; then
    if [[ "$(git rev-parse --is-shallow-repository)" == "true" ]]; then
        die "This is a shallow clone, and it has no merge base of '${base}' and HEAD, so the commits of the pull request are not known. In CI, actions/checkout needs fetch-depth: 0."
    fi
    die "No merge base of '${base}' and HEAD."
fi
log "Base: ${base}, merge base: ${merge_base}"

install_gitleaks

work="$(mktemp -d)"
trap 'rm -rf "${work}"' EXIT
mkdir -p "${work}/files" "${work}/no-ignore-file"
config_abs="$(cd "$(dirname "${config}")" && pwd)/$(basename "${config}")"

# The files: a copy of what git knows, without the deleted files. A tar error stops the script (set -e).
# The file .gitleaksignore of the root is not copied: gitleaks reads the file of the source folder of a scan (and
# ignores the option --gitleaks-ignore-path there), and the file must not hide a finding.
git ls-files -z --cached --others --exclude-standard --deduplicate | while IFS= read -r -d '' path; do
    [[ "${path}" != ".gitleaksignore" && ( -e "${path}" || -L "${path}" ) ]] && printf '%s\0' "${path}"
done | tar --null -T - -cf - | tar -C "${work}/files" -xf -

git_dir="$(git rev-parse --absolute-git-dir)"
common=(--config "${config_abs}" --exit-code 2 --redact --no-banner --no-color --ignore-gitleaks-allow
    --gitleaks-ignore-path "${work}/no-ignore-file" --verbose)
status=0

log "gitleaks $(version_of GITLEAKS_VERSION): the files (a copy of the files of git), no threshold"
scan_files() { (cd "${work}/files" && "${GITLEAKS_BIN}" dir . "${common[@]}"); }
run_security_tool "gitleaks (files)" "2" "leaks found" '(^|[[:space:]])(ERR|FTL)[[:space:]]' -- scan_files || status=1
files_result="${SECURITY_RESULT}"
files_count="$(grep -Eo 'leaks found: [0-9]+' <<<"${SECURITY_OUTPUT}" | head -n 1 | grep -Eo '[0-9]+' || true)"

log "gitleaks $(version_of GITLEAKS_VERSION): the history ${base}..HEAD, no threshold"
run_security_tool "gitleaks (history)" "2" "leaks found" '(^|[[:space:]])(ERR|FTL)[[:space:]]' -- \
    "${GITLEAKS_BIN}" git "${git_dir}" "${common[@]}" --log-opts="${base}..HEAD" || status=1
history_result="${SECURITY_RESULT}"
history_count="$(grep -Eo 'leaks found: [0-9]+' <<<"${SECURITY_OUTPUT}" | head -n 1 | grep -Eo '[0-9]+' || true)"

if [[ "${files_result}" == "failure" || "${history_result}" == "failure" ]]; then
    exit 1
fi
log "REPORT: files: ${files_count:-0} finding(s); history ${base}..HEAD: ${history_count:-0} finding(s). The secrets are redacted in the report."
exit "${status}"
