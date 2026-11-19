#!/usr/bin/env bash
# feat-48-pre-commit-hooks, Task 130.110 (REQ-001, REQ-003, REQ-005, REQ-006, ACC-001, ACC-003, ACC-005, ACC-006)
#
# Test of the git hooks of tools/hooks/ (pre-commit, commit-msg, pre-push) with the real gates.
#
# Usage: test-hooks.sh
#
# The test makes ONE temporary git repository (copy_work_tree in _lib.sh: a copy of the files of this repository in
# one commit on the branch `work`, tag `base`), makes a bare `origin` remote, pushes the branch, and installs the
# hooks in the temporary repository only (`just install-hooks`, never in the real work tree). Every git commit, git
# push and just call runs with GITHUB_BASE_REF=work in the environment, so the base of the justfile is origin/work.
# It never changes the real work tree.
#
# The nine cases (the seven of the plan, and the two added by the post-implementation review of 2026-11-18):
#   1. a conforming commit (feat(feat-48): test commit) passes the six gates of pre-commit and the commit-msg check,
#      and the following push passes the six gates of pre-push and reaches the bare origin;
#   2. a commit message that fails is stopped: the commit-msg check gives NOT CORRECT, and no commit is made;
#   3. a merge in progress is exempt from the commit-msg check (the gate skips merge commits too): a conforming empty
#      commit on a side branch passes the hooks, the merge is created with the default (non-conforming) subject, and
#      the commit-check gate passes with the merge in the range (the gate skips merge commits, git log --no-merges);
#   4. a document that fails the validation is stopped: the corruption is verified with a direct run of the validate
#      gate first (the fixture is real), and the commit stops at the second gate (validate), after the first gate
#      (commit-check) passed; no commit is made;
#   5. --no-verify bypasses: the commit with the corrupted document and a message that fails is made, with no hook
#      output at all;
#   6. a second run of install-hooks changes nothing: the two snapshots of git config --list are byte-identical, and
#      core.hooksPath is still tools/hooks;
#   7. the environment marker SKIP_HOOKS_FOR_BULK (set and non-empty) skips the commit hooks: the commit with a
#      message that fails is made, the SKIP notice appears for pre-commit and for commit-msg, and no gate output
#      appears;
#   8. a commit made with --no-verify is stopped by the pre-push hook: the push stops at the first gate
#      (commit-check), and the bare origin does not receive the commits;
#   9. the environment marker SKIP_HOOKS_FOR_BULK skips the pre-push hook: with the non-conforming commits of case 8
#      in the range, the push succeeds, the SKIP notice of pre-push appears, no gate output appears, and the bare
#      origin advances to the local tip.
#
# Needs git, just, uv, Node, pnpm, tar, sed, grep and cmp, as the six gates. With the warm tool caches (the specmgr
# uv lock and the Spectral pnpm lock already installed), the test takes on the order of tens of seconds. On a machine
# without the caches it takes a few minutes, because a run of the six gates installs the tools from the lock files.

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/_lib.sh"

require_cmd git
require_cmd just
require_cmd tar
require_cmd sed
require_cmd grep
require_cmd cmp

work="$(mktemp -d)"
trap 'rm -rf "${work}"' EXIT
repo="${work}/repo"
copy_work_tree "${repo}"
for hook in pre-commit commit-msg pre-push; do
    [[ -f "${repo}/tools/hooks/${hook}" ]] || die "The hook tools/hooks/${hook} is not in the copy of the repository."
done

origin="${work}/origin.git"
git init --bare --quiet "${origin}"

# git in the temporary repository. GITHUB_BASE_REF=work makes the base of the justfile origin/work (the base that the
# hooks run against, as in the tests of the hooks of Phase 110 and Phase 120).
r() { GITHUB_BASE_REF=work git -C "${repo}" -c core.fileMode=true "$@"; }
# a just recipe in the temporary repository, with the same base.
j() { (cd "${repo}" && GITHUB_BASE_REF=work just "$@"); }

r remote add origin "${origin}"
# The push before the install runs with no hooks (the temporary repository has no core.hooksPath yet).
r push --quiet -u origin work
j install-hooks
[[ "$(r config core.hooksPath)" == "tools/hooks" ]] \
    || die "just install-hooks did not set core.hooksPath to tools/hooks in the temporary repository."

passed=0
failed=0

section() { echo; echo "== $*"; }

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
        echo "${output}" | tail -n 30 | sed -e 's/^/     | /'
        failed=$((failed + 1))
    fi
}

# check <description> <command...>: ok if the command returns exit code 0
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

section "case 1: a conforming commit passes the commit hooks, and the push passes the pre-push hook"
before="$(r rev-parse HEAD)"
case1_commit() { r commit --allow-empty -m "feat(feat-48): test commit"; }
expect 0 "OK: feat(feat-48): test commit" \
    "the conforming commit passes pre-commit (the six fast gates) and commit-msg (the Conventional Commits feature-scope rule)" case1_commit
check "the conforming commit is made" test "$(r rev-parse HEAD)" != "${before}"
case1_push() { r push --quiet origin work; }
expect 0 "1 commit message(s) correct. PASS" \
    "the push passes the pre-push hook (the six fast gates against the base)" case1_push
check "the bare origin received the commit" test "$(r rev-parse HEAD)" = "$(r rev-parse origin/work)"

section "case 2: a commit message that fails is stopped (no commit is made)"
before="$(r rev-parse HEAD)"
case2_commit() { r commit --allow-empty -m "bad message"; }
expect 1 "NOT CORRECT: bad message" \
    "the failing message stops the commit after the six gates of pre-commit passed" case2_commit
check "no commit is made for the failing message" test "$(r rev-parse HEAD)" = "${before}"

section "case 3: a merge in progress is exempt from the commit-msg check (the gate skips merge commits too)"
r branch side
r checkout --quiet side
case3_side() { r commit --allow-empty -m "feat(feat-48): side commit"; }
expect 0 "OK: feat(feat-48): side commit" \
    "the conforming empty commit on the side branch passes the commit hooks" case3_side
r checkout --quiet work
# One capture, two proofs: the merge commit is created, and its subject is the default merge subject of git
# (not conforming: proof that the commit-msg hook exempted it via MERGE_HEAD instead of the rule passing it;
# git runs no pre-commit hook when it completes a merge commit, so the commit-msg hook is the only hook that
# sees the merge message, and the subject prefix covers the git-version spellings of the default message).
set +e
output="$(r merge --no-ff side 2>&1)"
code=$?
set -e
if [[ ${code} -eq 0 && "$(r log --format=%s -1)" == "Merge branch 'side'"* ]]; then
    echo "ok   the merge is created with the default (non-conforming) subject: the commit-msg hook exempted it (MERGE_HEAD)"
    passed=$((passed + 1))
else
    echo "FAIL the merge exemption: want exit code 0 and the default merge subject (got '$(r log --format=%s -1)'); got exit code ${code}"
    echo "${output}" | tail -n 30 | sed -e 's/^/     | /'
    failed=$((failed + 1))
fi
case3_gate() { j commit-check; }
expect 0 "1 commit message(s) correct. PASS" \
    "the commit-check gate passes with the merge in the range (the gate skips merge commits via --no-merges)" case3_gate

section "case 4: a document that fails the validation is stopped at the second gate (validate)"
doc="docs/txt/txt-eff55a59-137b-40b0-8f7b-44c349aa923a-engineering-handbook.md"
sed -i -e 's/^version: 1\.0\.0$/version: 1.0.0\ncorruption: [unclosed,/' "${repo}/${doc}"
check "the test corrupted the document (an unclosed flow sequence in the frontmatter)" \
    grep -q '^corruption: \[unclosed,$' "${repo}/${doc}"
case4_validate() { j validate; }
expect 1 "while parsing a flow node" \
    "the validate gate fails on the corruption before any commit (the fixture is real)" case4_validate
before="$(r rev-parse HEAD)"
# One capture, two proofs: the first gate (commit-check) passed on the conforming side commit of case 3 in the range,
# and the stop is at the second gate (validate).
set +e
output="$(r commit -am "feat(feat-48): broken doc" 2>&1)"
code=$?
set -e
if [[ ${code} -eq 1 && "${output}" == *"1 commit message(s) correct. PASS"* \
    && "${output}" == *"while parsing a flow node"* ]]; then
    echo "ok   the commit stops at the validate gate (the second gate; the first gate, commit-check, passed)"
    passed=$((passed + 1))
else
    echo "FAIL the commit stops at the validate gate: want exit code 1, the pass of commit-check and the flow node error; got exit code ${code}"
    echo "${output}" | tail -n 30 | sed -e 's/^/     | /'
    failed=$((failed + 1))
fi
check "no commit is made for the corrupted document" test "$(r rev-parse HEAD)" = "${before}"

section "case 5: --no-verify bypasses the hooks (the document is still corrupted)"
before="$(r rev-parse HEAD)"
# One capture, three proofs: the commit is made, with a message that fails and a document that fails, and no hook
# output at all (no gate line and no SKIP notice).
set +e
output="$(r commit --no-verify -am "bypassed" 2>&1)"
code=$?
set -e
if [[ ${code} -eq 0 && "$(r rev-parse HEAD)" != "${before}" \
    && "${output}" != *"commit-check.sh"* && "${output}" != *"validate-docs.sh"* && "${output}" != *"SKIP"* ]]; then
    echo "ok   the bypassed commit is made, with no hook output at all"
    passed=$((passed + 1))
else
    echo "FAIL the bypassed commit: want exit code 0, a new commit and no hook output"
    echo "${output}" | tail -n 30 | sed -e 's/^/     | /'
    failed=$((failed + 1))
fi

section "case 6: a second run of install-hooks changes nothing"
r config --list >"${work}/config-before"
j install-hooks
r config --list >"${work}/config-after"
check "the two snapshots of git config --list are byte-identical" cmp -s "${work}/config-before" "${work}/config-after"
check "core.hooksPath is still tools/hooks" test "$(r config core.hooksPath)" = "tools/hooks"

section "case 7: the environment marker SKIP_HOOKS_FOR_BULK (set and non-empty) skips the commit hooks (pre-commit and commit-msg)"
before="$(r rev-parse HEAD)"
# One capture, three proofs: the commit with a message that fails is made, the SKIP notice appears for pre-commit and
# for commit-msg, and no gate output appears (the marker skips before the gates run).
set +e
output="$(cd "${repo}" && GITHUB_BASE_REF=work SKIP_HOOKS_FOR_BULK=1 git commit --allow-empty -m "bulk import" 2>&1)"
code=$?
set -e
if [[ ${code} -eq 0 && "$(r rev-parse HEAD)" != "${before}" \
    && "${output}" == *"[pre-commit] SKIP: SKIP_HOOKS_FOR_BULK"* && "${output}" == *"[commit-msg] SKIP: SKIP_HOOKS_FOR_BULK"* \
    && "${output}" != *"commit-check.sh"* && "${output}" != *"validate-docs.sh"* ]]; then
    echo "ok   the marker skips pre-commit and commit-msg (the SKIP notice of each, no gate output), and the commit is made"
    passed=$((passed + 1))
else
    echo "FAIL the marker skips the hooks: want exit code 0, a new commit, the two SKIP notices and no gate output; got exit code ${code}"
    echo "${output}" | tail -n 30 | sed -e 's/^/     | /'
    failed=$((failed + 1))
fi

section "case 8: a commit made with --no-verify is stopped by the pre-push hook (the bare origin stays)"
remote_before="$(r ls-remote origin work)"
# One capture, three proofs: the push stops at the first gate (commit-check, on the bypassed message), the second gate
# (validate) does not run, and the bare origin did not receive the commits.
set +e
output="$(r push origin work 2>&1)"
code=$?
set -e
remote_after="$(r ls-remote origin work)"
if [[ ${code} -eq 1 && "${output}" == *"commit message(s) not correct"* && "${output}" != *"validate-docs.sh"* \
    && "${remote_before}" == "${remote_after}" ]]; then
    echo "ok   the push stops at the commit-check gate (the first gate), and the bare origin did not receive the commits"
    passed=$((passed + 1))
else
    echo "FAIL the pre-push stop: want exit code 1, the not-correct line, no output of the second gate, and the bare origin unchanged; got exit code ${code}"
    echo "${output}" | tail -n 30 | sed -e 's/^/     | /'
    failed=$((failed + 1))
fi

section "case 9: the environment marker SKIP_HOOKS_FOR_BULK skips the pre-push hook (the bare origin advances)"
local_tip="$(r rev-parse HEAD)"
# One capture, three proofs: the push with the marker succeeds although the range has the non-conforming commits of
# case 8, the SKIP notice of pre-push appears, no gate output appears (the marker skips before the gates run), and
# the bare origin advances to the local tip.
set +e
output="$(cd "${repo}" && GITHUB_BASE_REF=work SKIP_HOOKS_FOR_BULK=1 git push origin work 2>&1)"
code=$?
set -e
if [[ ${code} -eq 0 && "${output}" == *"[pre-push] SKIP: SKIP_HOOKS_FOR_BULK"* \
    && "${output}" != *"commit-check.sh"* && "${output}" != *"validate-docs.sh"* \
    && "$(r ls-remote origin work | cut -f1)" == "${local_tip}" ]]; then
    echo "ok   the marker skips pre-push (the SKIP notice, no gate output), and the bare origin advances to the local tip"
    passed=$((passed + 1))
else
    echo "FAIL the marker skips the pre-push hook: want exit code 0, the SKIP notice, no gate output and the bare origin at the local tip; got exit code ${code}"
    echo "${output}" | tail -n 30 | sed -e 's/^/     | /'
    failed=$((failed + 1))
fi

echo
echo "git hooks: ${passed} ok, ${failed} failed"
if [[ ${failed} -eq 0 ]]; then
    log "PASS: the nine cases of the git hooks of tools/hooks/ (feat-48-pre-commit-hooks, Task 130.110)"
else
    log "FAIL: ${failed} case(s) of the git hooks of tools/hooks/ did not pass (feat-48-pre-commit-hooks, Task 130.110)"
    exit 1
fi
