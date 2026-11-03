#!/usr/bin/env bash
# feat-5-foundation-monorepo-ci, Task 130.120 (REQ-011, DEC a56f231b-d063-4bef-bbc8-3deb4daff76e)
#
# Gate: the commit messages follow Conventional Commits, and the scope is the
# number of the feature.
#
# Usage: commit-check.sh <base>
#        commit-check.sh --message "<subject>"   (check one subject line)
#
# The subject line of each commit in <base>..HEAD must have this form:
#
#   type(feat-N): subject
#   type(feat-N)!: subject        (a breaking change)
#
#   type    feat, fix, docs, chore, refactor, test, ci, build, perf, style or revert
#   feat-N  the identifier of the feature, with digits only (for example feat-5)
#   subject at least one character after the colon and one space
#
# The DEC gives the scope (the feature identifier) and says that the history
# shows the feature of each change. It does not list the types, so the script
# uses the types of the Conventional Commits specification that the history
# uses. The gate does not check the name of the branch.
#
# Merge commits are skipped (git log --no-merges). The reason is that CI checks
# out the merge of the pull request into the base, and that merge commit is
# not a message of the author. Messages that git makes (for example `Revert "..."`
# and `fixup! ...`) are not correct: write `revert(feat-N): ...` and squash the
# fixup commits before the pull request.

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/_lib.sh"

readonly PATTERN='^(feat|fix|docs|chore|refactor|test|ci|build|perf|style|revert)\(feat-[0-9]+\)!?: [^ ].*$'

# check_subject <subject> -- succeed if the subject has the correct form.
check_subject() {
    [[ "$1" =~ ${PATTERN} ]]
}

if [[ "${1:-}" == "--message" ]]; then
    [[ $# -eq 2 ]] || die "Usage: commit-check.sh --message \"<subject>\""
    if check_subject "$2"; then
        log "OK: $2"
        exit 0
    fi
    log "NOT CORRECT: $2"
    exit 1
fi

[[ $# -eq 1 ]] || die "Usage: commit-check.sh <base>"
base="$1"

require_cmd git
cd "${WORK_ROOT}"
git rev-parse --verify --quiet "${base}^{commit}" >/dev/null \
    || die "The base '${base}' does not exist. In CI, actions/checkout needs fetch-depth: 0."

failed=0
total=0
while IFS=$'\t' read -r sha subject; do
    total=$((total + 1))
    if check_subject "${subject}"; then
        log "OK   ${sha:0:7} ${subject}"
    else
        log "FAIL ${sha:0:7} ${subject}"
        failed=$((failed + 1))
    fi
done < <(git log --no-merges --format='%H%x09%s' "${base}..HEAD")

if [[ ${total} -eq 0 ]]; then
    log "No commit in ${base}..HEAD. Nothing to check. PASS"
    exit 0
fi
if [[ ${failed} -gt 0 ]]; then
    echo "[commit-check.sh] ${failed} of ${total} commit message(s) not correct." >&2
    echo "[commit-check.sh] Expected: type(feat-N): subject. Types: feat, fix, docs, chore, refactor, test, ci, build, perf, style, revert." >&2
    exit 1
fi
log "${total} commit message(s) correct. PASS"
