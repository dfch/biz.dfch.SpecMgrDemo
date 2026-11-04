#!/usr/bin/env bash
# feat-5-foundation-monorepo-ci, Task 130.110 (REQ-005)
#
# Gate: specmgr validation of the documents that changed.
#
# Usage: validate-docs.sh <base>
#   <base> is the branch that the pull request goes to, for example origin/dev.
#
# The script finds the Markdown files under docs/ and .specmgr/ that changed
# between the merge base of <base> and HEAD and the working tree. It skips
# deleted files. It starts `specmgr lint` (the full parse of each document
# with the model of its type, the same check that the MCP tools do) for them.
# CI has no MCP server, so the script uses the command line of specmgr. The
# version is SPECMGR_VERSION in tools/versions.env. The script installs it with
# `uv pip install --require-hashes` from the lock file tools/python/specmgr.lock (make_python_env in
# _lib.sh), and the package needs the extra `mcp` (the command line imports the server). The lock file
# has the sha256 of each file of specmgr and of its dependencies (feat-22-python-tools-lockfile).
# A wrong sha256 value, a package with no value or a package that is not in the file stops the gate.
#
# Files that are not documents of a type (for example a README.md in docs/)
# are skipped by specmgr and counted in its summary. The gate stops (exit
# code 1) if one document does not parse, if specmgr does not start, or if the
# base does not exist. If no document changed, the gate passes.

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/_lib.sh"

[[ $# -eq 1 ]] || die "Usage: validate-docs.sh <base>"
base="$1"

require_cmd git
require_cmd uv

cd "${WORK_ROOT}"
git rev-parse --verify --quiet "${base}^{commit}" >/dev/null \
    || die "The base '${base}' does not exist. In CI, actions/checkout needs fetch-depth: 0."
merge_base="$(git merge-base "${base}" HEAD)" \
    || die "No merge base of '${base}' and HEAD. In CI, actions/checkout needs fetch-depth: 0."
log "Base ${base}, merge base ${merge_base}"

# Added, copied, modified, renamed and type-changed files. Deleted files are not in the list.
files=()
while IFS= read -r -d '' file; do
    case "${file}" in
        docs/*.md | .specmgr/*.md) files+=("${file}") ;;
    esac
done < <(git diff --name-only -z --diff-filter=ACMRT "${merge_base}" -- docs .specmgr)

if [[ ${#files[@]} -eq 0 ]]; then
    log "No document under docs/ or .specmgr/ changed. Nothing to validate. PASS"
    exit 0
fi

log "${#files[@]} changed Markdown file(s) under docs/ and .specmgr/:"
printf '  %s\n' "${files[@]}"

specmgr_version="$(version_of SPECMGR_VERSION)"
make_python_env specmgr
log "specmgr ${specmgr_version} (all packages are checked with the lock file): lint"
"${GATE_ENV_DIR}/venv/bin/specmgr" lint --skip-unrecognized "${files[@]}"
log "PASS"
