---
classification: null
created: '2026-11-17T04:20:52.459+01:00'
id: feat-48-pre-commit-hooks
status: review
type: feat
updated: '2026-11-18T18:57:09.942+01:00'
version: 1.0.0
---

# Feature: Add Pre-Commit Hooks for the Fast Local Gates

## Plan

### Overview

This feature adds local git hooks that run the fast, local, no-network gates before a commit and before a push. Today all enforcement is CI-side, as `just` gate recipes, so an author or a coding agent learns about a failing gate only after the round trip of a pull request (RSK edee1891-1428-41ac-9877-d8deb20d07e9, issue #31). The hooks are opt-in and idempotent: the `just install-hooks` recipe points `core.hooksPath` to a `tools/hooks/` folder of shell scripts that call the existing `just` recipes only, which keeps the one-entry-point rule of feat-5-foundation-monorepo-ci (REQ-002, REQ-009). The pre-commit hook runs `commit-check`, `validate`, `lint`, `check-pins`, `check-workflows` and `check-sudo`; a commit message that does not follow Conventional Commits with the feature scope, and a document that fails the specmgr validation, are stopped locally. The pre-push hook re-runs the fast gates against the base. The hooks are bypassed with `git commit --no-verify`, and a documented environment marker exists for the bulk commits of the coding agent, within the limits of DEC cc4449cd-78fb-452a-904f-7efda89cf004. No hook framework is used and no dependency is added. GitHub issue #48 is for this feature.

### Requirements

- REQ-001: A `just` recipe `install-hooks` must set `core.hooksPath` to the folder `tools/hooks/` of the repository. The recipe is opt-in and idempotent: a second run changes nothing. CI must not install the hooks.

- REQ-002: The hooks must be native git hooks as shell scripts in `tools/hooks/`. Each hook must call the existing `just` recipes only (the one entry point, feat-5 REQ-002 and REQ-009). No hook framework (the pre-commit framework, husky, lefthook), no new dependency and no new license may be added.

- REQ-003: The pre-commit hook must run the fast gates `commit-check`, `validate`, `lint`, `check-pins`, `check-workflows` and `check-sudo`. A commit message that does not follow Conventional Commits with the feature scope, and a changed document that fails the specmgr validation, must be stopped locally.

- REQ-004: No slow or network gate may run in the pre-commit hook: not the security scans, not `sbom`, not `license-check`, not the builds and not the tests.

- REQ-005: The hooks must have a clear opt-out: `git commit --no-verify` bypasses them, and a documented environment marker bypasses them for the bulk commits of the coding agent, within the limits of DEC cc4449cd-78fb-452a-904f-7efda89cf004 (an agent must not disable a gate for a normal commit).

- REQ-006: A pre-push hook must re-run the fast gates against the base, so that a commit made with `--no-verify` is stopped before it reaches `dev`.

- REQ-007: The hook scripts must use no `sudo`. The existing `check-sudo` gate covers them because it scans `tools/`.

- REQ-008: The README, the engineering handbook (TXT eff55a59-137b-40b0-8f7b-44c349aa923a) and `tools/README.md` must describe the install of the hooks and the opt-out.

### Acceptance Criteria

- [ ] ACC-001: `just install-hooks` sets `core.hooksPath` to `tools/hooks/`, and a second run changes nothing. (REQ-001)

- [ ] ACC-002: The hooks are shell scripts in `tools/hooks/` that call `just` recipes only. No hook framework, no new dependency and no new license exist in the repository. The behavior of CI is not changed: the hooks are local only, and the workflow files stay untouched. (REQ-002)

- [ ] ACC-003: A commit message that does not follow Conventional Commits with the feature scope is stopped locally by the commit check, and a changed document that fails the validation is stopped locally by `validate`. (REQ-003)

- [ ] ACC-004: The pre-commit hook runs no slow or network gate (no security scan, no `sbom`, no `license-check`, no build, no test). (REQ-004)

- [ ] ACC-005: `git commit --no-verify` bypasses the hooks, and a bulk commit with the documented environment marker bypasses them. (REQ-005)

- [ ] ACC-006: A commit made with `--no-verify` is stopped by the pre-push hook when it is pushed, because the pre-push hook re-runs the fast gates against the base. (REQ-006)

- [ ] ACC-007: No hook script uses `sudo`, and `just check-sudo` passes for the new scripts in `tools/hooks/`. (REQ-007)

- [ ] ACC-008: The README, the engineering handbook and `tools/README.md` describe the install (`just install-hooks`) and the opt-out (`--no-verify` and the environment marker). (REQ-008)

### Scope

#### Included

- The `just` recipe `install-hooks` (opt-in, idempotent) that points `core.hooksPath` to `tools/hooks/`.

- The native git hooks in `tools/hooks/`: the pre-commit hook (the six fast gates), the commit message check (Conventional Commits with the feature scope) and the pre-push hook (the fast gates against the base).

- The opt-out: `git commit --no-verify` and the documented environment marker for the bulk commits of the coding agent.

- The documentation: the README, the engineering handbook (TXT eff55a59-137b-40b0-8f7b-44c349aa923a) and `tools/README.md` describe the install and the opt-out.

#### Explicitly Out Of Scope

- No new hook framework (the pre-commit framework, husky, lefthook): a new tool would need a pin and a license check per DEC 84c37f7d-08cb-457d-8ab3-1db37dba9bc9.

- No slow or network gate in the pre-commit hook (the security scans, `sbom`, `license-check`, the builds, the tests).

- No change to the CI workflow and no change to the branch protection: the hooks are local only.

### Design Notes

No hook framework (DEC 84c37f7d, the one entry point): the sibling repository biz.dfch.SpecMgr runs local pre-commit checks with the pre-commit framework (`.pre-commit-config.yaml`, with local hooks for ruff, vulture, the documentation and schema regeneration and pytest). This repository does not adopt it: a new tool would need a pin in `tools/versions.env` and a license check (DEC 84c37f7d-08cb-457d-8ab3-1db37dba9bc9), and a hook framework would bypass the rule that the `justfile` is the one entry point for local work (feat-5 REQ-002, REQ-009). The hooks are native git hooks.

Thin shells: each hook in `tools/hooks/` is a shell script with `set -euo pipefail` that calls only the existing `just` recipes (`commit-check`, `validate`, `lint`, `check-pins`, `check-workflows`, `check-sudo`). The hooks add no gate logic of their own, except the opt-out check. A code owner reviews the scripts (CODEOWNERS covers `/tools/`). `just check-sudo` (REQ-007) scans the `.sh`, `.bash`, `.just`, `justfile`, `.yml` and `.yaml` files of `tools/`, and the extensionless hook files are not in its scan list: the absence of `sudo`, `doas` and `pkexec` in the hooks is a fact of their content (they contain none of these words at all, verified), and `just check-sudo` passes without change, so no change of the gate or of CODEOWNERS is necessary.

Base and commit range: in the `justfile`, `base` is `origin/GITHUB_BASE_REF`, or `origin/dev` if `GITHUB_BASE_REF` is not set (the developer machine). The hooks use the same base. `commit-check` covers the commits of the branch that are already in `HEAD`, like in CI.

Commit message of the commit in progress: a git pre-commit hook runs before the commit object exists, so the message of the new commit is not yet in `git log`. The message is checked by a commit-msg hook in the same folder, with the same rule as the `commit-check` gate (Conventional Commits with the feature scope, DEC a56f231b-d063-4bef-bbc8-3deb4daff76e: `type(feat-N): subject`). Both hooks are installed by the same `just install-hooks` recipe: `core.hooksPath` points to the whole folder, and git finds `pre-commit` and `commit-msg` in it. The `commit-msg` hook passes the subject line to the thin `just` recipe `commit-message-check`, which runs `commit-check.sh --message`, so the rule stays in the gate script.

Opt-out (DEC cc4449cd): `git commit --no-verify` is the documented bypass for a person. For the bulk commits of the coding agent (for example the import of a large amount of history), the documented environment marker `SKIP_HOOKS_FOR_BULK` (fixed in this entry; the handbook documents it in Task 130.100) makes the hooks skip. Within the limits of DEC cc4449cd-78fb-452a-904f-7efda89cf004, an agent must not use the marker for a normal commit: a gate that an agent can disable gives no protection. The pre-push hook (REQ-006) is the backstop for commits that were made with the bypass: they are re-checked against the base before they reach `dev`.

CI is untouched: the workflow files are not changed, the branch protection is not changed, and no hook runs in CI. The hooks are a local convenience, and CI remains the enforcement.

### Related Decisions

- DEC 870244cf-9bea-46bf-8ff2-fe030325743d: Use a Monorepo with Maven, pnpm, just and GitHub Actions

- DEC a56f231b-d063-4bef-bbc8-3deb4daff76e: Use Conventional Commits, Feature Branches and a Definition of Done

- DEC 361678a6-f941-473b-a058-1ba2bacf7d3d: Use a Test Pyramid and Blocking Gates for Verification

- DEC cc4449cd-78fb-452a-904f-7efda89cf004: Set Limits for Coding Agents

- DEC 84c37f7d-08cb-457d-8ab3-1db37dba9bc9: Use Only Open Source Libraries That Are Compatible With AGPL-3.0-only

- RSK edee1891-1428-41ac-9877-d8deb20d07e9: Blocking Gates Make Work Slow for Coding Agents and Authors

- TXT eff55a59-137b-40b0-8f7b-44c349aa923a: Engineering Handbook

- GitHub issue #48: Gates: add optional pre-commit hooks to run the fast local gates

- GitHub issue #31: Process: reduce the cost of pull requests for document-only changes

### Task List

#### Phase 100: Install Recipe and Hooks Folder

- [x] Task 100.100: Write the `just` recipe `install-hooks`: set `core.hooksPath` to `tools/hooks/`, idempotent (a second run changes nothing), opt-in. Note the uninstall path (`git config --unset core.hooksPath`) in the recipe comment.

- [x] Task 100.110: Create the `tools/hooks/` folder with a README that names each hook and the `just` recipes it calls.

#### Phase 110: The Pre-Commit Hook

- [x] Task 110.100: Write the pre-commit hook: run `commit-check`, `validate`, `lint`, `check-pins`, `check-workflows` and `check-sudo` as `just` recipes. Stop the commit on the first failing gate.

- [x] Task 110.110: Write the commit message check for the commit in progress (Conventional Commits with the feature scope, DEC a56f231b-d063-4bef-bbc8-3deb4daff76e) as a commit-msg hook in `tools/hooks/`, with the same rule as the `commit-check` gate.

#### Phase 120: Pre-Push Hook and Opt-Out

- [x] Task 120.100: Write the pre-push hook: re-run the six fast gates as `just` recipes against the base of the pushed branch.

- [x] Task 120.110: Implement the documented environment marker for the bulk commits of the coding agent (the hooks skip when it is set), within the limits of DEC cc4449cd-78fb-452a-904f-7efda89cf004.

#### Phase 130: Documentation and Tests

- [x] Task 130.100: Update the README, the engineering handbook (TXT eff55a59-137b-40b0-8f7b-44c349aa923a) and `tools/README.md`: the install (`just install-hooks`) and the opt-out (`--no-verify` and the environment marker).

- [x] Task 130.110: Test the hooks in a temporary git repository: a commit message that fails is stopped, a document that fails the validation is stopped, `--no-verify` bypasses, a second run of `install-hooks` changes nothing, the environment marker skips the hooks, and a commit made with `--no-verify` is stopped by the pre-push hook.

- [ ] Task 130.120: The owner examines the hooks, the tests and the documentation.

## Progress

### Current Status

**As of 2026-11-18**: Phase 130 is complete for the agent: the three documents (the root README, the engineering handbook TXT eff55a59-137b-40b0-8f7b-44c349aa923a, and `tools/README.md`) describe the install (`just install-hooks`) and the opt-out (`git commit --no-verify`, `git push --no-verify`, and the environment marker `SKIP_HOOKS_FOR_BULK` — the marker name is fixed in the handbook, per the Design Notes), and the permanent test `just test-hooks` (`tools/gates/test-hooks.sh`, the seven cases of the plan in a temporary git repository with the real gates) passes. Remaining: Task 130.120, the examination of the hooks, the tests and the documentation by the owner. The work happens on the branch `feat-48-pre-commit-hooks`, and the commit messages use the scope `feat(feat-48)`. The feature has the status `review`: the implementation of all phases is complete, the remaining task is 130.120 (the examination by the owner), and the orchestrator opens the pull request to `dev` (the one PR that covers the plan and the implementation, per the owner).

### Blockers

- None for the start of Phase 100.

### Updates

<!-- Newest entry first -- prepend new entries directly below this comment. -->

#### 2026-11-18 17:26:25.000Z - Phase 130 complete

The agent did Tasks 130.100 and 130.110. Task 130.120 (the examination of the hooks, the tests and the documentation by the owner) is open and stays unticked: the owner examines after this work.

1. The root README (Task 130.100): a new section `## Git Hooks` (the file was two lines before). It says that the hooks give the fast local signal that CI gives only after the round trip of a pull request, that they are local and opt-in and CI remains the enforcement; that the three hooks are shell scripts in `tools/hooks/` that call the `just` recipes only — `pre-commit` runs the six fast gates (`commit-check`, `validate`, `lint`, `check-pins`, `check-workflows`, `check-sudo`) before a commit and stops on the first failing gate, `commit-msg` checks the subject of the commit in progress with the Conventional Commits feature-scope rule, and `pre-push` re-runs the six gates against the base as the backstop for a commit made with the bypass; the install (`just install-hooks`, opt-in, idempotent) and the uninstall (`git config --unset core.hooksPath`); the opt-out (`git commit --no-verify` / `git push --no-verify` for a person, and the environment marker `SKIP_HOOKS_FOR_BULK`, set and non-empty, for the bulk commits of a coding agent, with the limit of DEC cc4449cd-78fb-452a-904f-7efda89cf004: an agent must not use the marker for a normal commit); and a pointer to `tools/hooks/README.md` for the details.
2. The engineering handbook (Task 130.100, TXT eff55a59-137b-40b0-8f7b-44c349aa923a): two new bullets in `## Tools and Data` — the first names the hooks, the folder `tools/hooks/`, the install (`just install-hooks`, opt-in, idempotent, uninstall `git config --unset core.hooksPath`) and what each hook runs (`pre-commit` the six fast gates, `commit-msg` the Conventional Commits feature-scope rule of DEC a56f231b-d063-4bef-bbc8-3deb4daff76e, `pre-push` the six gates against the base as the backstop); the second gives the opt-out (`git commit --no-verify` / `git push --no-verify` for a person, and the environment marker `SKIP_HOOKS_FOR_BULK`, set and non-empty, for the bulk commits of the coding agent, within the limits of DEC cc4449cd-78fb-452a-904f-7efda89cf004 — an agent must not use the marker for a normal commit) and points to `tools/hooks/README.md`. The marker name is thereby fixed in the handbook, as the Design Notes promised. A new `## Updates` entry (2026-11-18 16:35:38.000Z, "Git hooks of the fast local gates") describes the change. The frontmatter, the H1, the index lists and `## Open Items` are unchanged.
3. `tools/README.md` (Task 130.100): one new row in the table, after the `gates/` row: `hooks/` — the git hooks of feat-48-pre-commit-hooks (`pre-commit`, `commit-msg`, `pre-push`), thin shells that call the `just` recipes only; the install `just install-hooks` (opt-in, idempotent; uninstall `git config --unset core.hooksPath`); the opt-out `git commit --no-verify`, `git push --no-verify` and the environment marker `SKIP_HOOKS_FOR_BULK` (set and non-empty) for the bulk commits of the coding agent (DEC cc4449cd-78fb-452a-904f-7efda89cf004, an agent must not use it for a normal commit); the details in `tools/hooks/README.md`.
4. The permanent test (Task 130.110): `tools/gates/test-hooks.sh` (new, executable, mode 100755 in git) in the house style of the other `tools/gates/test-*.sh` (the header attributes feat-48-pre-commit-hooks and Task 130.110, `set -euo pipefail`, `source _lib.sh`, `log`/`die`, a `mktemp -d` work area with a `trap` cleanup, and the `ok`/`FAIL` counters with the summary line). It builds the temporary repository with the existing `copy_work_tree` helper (one commit on the branch `work`, tag `base`, file modes kept, the copy verified), then, in the temporary repository only: a bare `origin` (`git init --bare`), `git remote add origin`, `git push -u origin work` (before the install, so without hooks), and `just install-hooks` (`core.hooksPath` = `tools/hooks`). Every `git commit`, `git push` and `just` call runs with `GITHUB_BASE_REF=work` in the environment (the base of the justfile is `origin/work`). The seven cases of the plan, with the decisive output line of each:
    (1) the positive case: `git commit --allow-empty -m "feat(feat-48): test commit"` → the pre-commit hook runs the six gates green and the commit-msg hook prints `[commit-check.sh] OK: feat(feat-48): test commit`; the commit is made. Then `git push origin work` → the pre-push hook runs the six gates green (`[commit-check.sh] OK   <sha> feat(feat-48): test commit`, `[commit-check.sh] 1 commit message(s) correct. PASS` and the five other PASS lines), and the bare origin receives the commit (`origin/work` = `HEAD`).
    (2) a commit message that fails is stopped: `git commit --allow-empty -m "bad message"` → the six gates of pre-commit run green, and the commit-msg hook rejects the message: `[commit-check.sh] NOT CORRECT: bad message`; the exit code is 1 and no commit is made (`HEAD` unchanged).
    (3) a document that fails the validation is stopped: the test inserts `corruption: [unclosed,` into the YAML frontmatter of the engineering handbook (after the `version:` line), and first verifies with a direct `just validate` that the gate fails on it (exit 1, `✗ docs/txt/txt-eff55a59-... (txt): while parsing a flow node ...`, `summary: linted=1 failed=1 skipped=0 excluded=0`), so the fixture is real. Then `git commit -am "feat(feat-48): broken doc"` → the first gate (commit-check) passes (`[commit-check.sh] No commit in origin/work..HEAD. Nothing to check. PASS`), and the stop happens at the second gate (validate) on the same `while parsing a flow node` line; the exit code is 1 and no commit is made. This is the demonstration of the stop-on-first-failing-gate of the pre-commit hook.
    (4) `--no-verify` bypasses: with the document still corrupted, `git commit --no-verify -am "bypassed"` → the exit code is 0 and the commit IS made, with no hook output at all (no gate line, no SKIP notice).
    (5) a second run of `install-hooks` changes nothing: the two snapshots of `git config --list` (before and after the second `just install-hooks` in the temporary repository) are byte-identical, and `git config core.hooksPath` still answers `tools/hooks`.
    (6) the environment marker skips the hooks: `SKIP_HOOKS_FOR_BULK=1 git commit --allow-empty -m "bulk import"` → the commit is made even with a message that fails (exit 0); the SKIP notice appears for `pre-commit` and for `commit-msg` (`[pre-commit] SKIP: SKIP_HOOKS_FOR_BULK is set (non-empty); this hook skips all gates and exits 0.` and the same for `[commit-msg]`, with the limit line of DEC cc4449cd), and no gate output appears.
    (7) a commit made with `--no-verify` is stopped by the pre-push hook: `git push origin work` (no marker) → the pre-push hook stops at the first gate (commit-check) on the two non-conforming commits of the range `origin/work..HEAD` (`[commit-check.sh] FAIL <sha> bypassed`, `[commit-check.sh] FAIL <sha> bulk import`, `[commit-check.sh] 2 of 2 commit message(s) not correct.`); the second gate (validate) does not run, and the bare origin did not receive the commits (`git ls-remote origin work` is unchanged).
    One design note: the order of the cases and the state transitions needed no `git reset --hard` and no force-push at all (the plan foresaw force-push resets of `origin/work` back to the base): `origin/work` advances exactly once (case 1), and cases 4 and 6 build their history on top of it, so case 7 stops at the first gate before anything else matters. That saves the full gate runs of the resets; the test does three full runs of the six gates (case 1 commit, case 1 push, case 2) plus the partial runs of cases 3 and 7.
    The run of `just test-hooks` at the repository root: 15 `ok` lines, 0 `FAIL` lines, `git hooks: 15 ok, 0 failed`, `[test-hooks.sh] PASS: the seven cases of the git hooks of tools/hooks/ (feat-48-pre-commit-hooks, Task 130.110)`, total real time 13.6 s (the gates run fast on this machine with the warm caches: the specmgr venv from the uv lock and Spectral from the pnpm lock are already installed, and a run of the six gates costs about 3 s — verified gate by gate in a fresh temporary repository).
5. The recipe (Task 130.110): `test-hooks` is in the `justfile` directly after `test-security-gates` (the neighbourhood of the gate self-tests), with the house comment (attribute feat-48-pre-commit-hooks, Task 130.110). It is NOT part of the `test-gates` aggregation, and no workflow file was touched: the hook test is local only, like the hooks (CI remains the enforcement).
6. The quality gates at the repository root of this worktree: `just check-sudo` PASS (119 files — the new script is in the scan list and has no command to get more rights), `just check-workflows` PASS (27 run steps), `just check-pins` PASS (102 `uses:` steps), `just commit-check` PASS (4 commit message(s) correct), `just validate` PASS (`summary: linted=2 failed=0 skipped=0 excluded=0`; the engineering handbook and the plan README of this feature are the changed documents), `just lint` PASS (no finding), and `just test-hooks` PASS (item 4). `just validate` is run again after the text of this entry is added (item 7).
7. Two notes. (a) The `core.hooksPath` of this worktree stayed unset for the whole phase: `just install-hooks` ran only in the temporary repositories, and `git config --get core.hooksPath` exits with code 1 (the key is absent) before and after. (b) Task 130.120 is open for the owner: the hooks (`tools/hooks/`), the permanent test (`tools/gates/test-hooks.sh` and the `test-hooks` recipe) and the three documents of item 1 to 3 are to be examined.

#### 2026-11-18 14:11:55.000Z - Phase 120 complete

The agent did Tasks 120.100 and 120.110.

1. The pre-push hook (Task 120.100): `tools/hooks/pre-push` (executable, mode 100755 in git) is a thin shell in the style of the other two hooks (`#!/usr/bin/env bash`, `set -euo pipefail`, the header attributes Task 120.100, REQ-006 and DEC cc4449cd-78fb-452a-904f-7efda89cf004). The opt-out marker check comes first (item 2), then the `just`-on-PATH check with the same clear error as the other hooks, and then it re-runs the six fast gates in the REQ-003 order: `just commit-check`, `just validate`, `just lint`, `just check-pins`, `just check-workflows`, `just check-sudo`. With `set -e`, the first failing gate stops the push. The hook reads no stdin (the refs that git gives a pre-push hook are not used) and has no base logic of its own (the base stays the `base` of the `justfile`: `origin/GITHUB_BASE_REF`, or `origin/dev` if not set).
2. The opt-out marker (Task 120.110): the environment marker `SKIP_HOOKS_FOR_BULK` is now checked in all three hooks as the first action, before the `just`-on-PATH check, so the skip works even if `just` is not installed. The check is inlined in each hook (no shared helper file; each hook stays copyable on its own). When the variable is present and non-empty (`[[ -n "${SKIP_HOOKS_FOR_BULK:-}" ]]`, safe under `set -u`), the hook prints a two-line notice to stderr and exits 0 without running any gate. The wording is identical in the three hooks except for the hook name: line 1 names the hook, the marker, and the skip of all gates; line 2 carries the limit of DEC cc4449cd (the marker is documented for the bulk commits of the coding agent, not for a normal commit; the pre-push hook re-checks the base). `git commit --no-verify` and `git push --no-verify` remain the per-person bypass. The name is fixed in the Design Notes (item 4); the handbook documents it in Task 130.100.
3. The folder README: `tools/hooks/README.md` no longer says that `pre-push` arrives in Phase 120 (all three hooks exist now; the `pre-push` row also states that it stops the push on the first failing gate), and the old one-line bypass note is replaced by an "Opt-out" section: the per-person bypass (`git commit --no-verify`, `git push --no-verify`), the environment marker `SKIP_HOOKS_FOR_BULK` (set and non-empty: all three hooks skip every gate and exit 0 with a notice), and the limit of DEC cc4449cd-78fb-452a-904f-7efda89cf004 (an agent must not use the marker for a normal commit; the `pre-push` hook is the backstop).
4. The Design Notes of this plan: the "Opt-out (DEC cc4449cd)" paragraph now carries the fixed marker name — the parenthetical "(the name is chosen in Task 120.110 and fixed in the handbook)" is replaced by "the documented environment marker `SKIP_HOOKS_FOR_BULK` (fixed in this entry; the handbook documents it in Task 130.100)"; the rest of the paragraph is unchanged. Tasks 120.100 and 120.110 are ticked.
5. The tests in a throwaway repository (the real gates; the `core.hooksPath` of this worktree stayed unset for the whole test, item 7). The files of the worktree were copied to a temporary directory under /tmp/opencode (excluding `.git`, `build`, `node_modules` and `target`), a git repository was started in it (branch `work`, a local `user.name` and `user.email`, `commit.gpgsign` false), one commit `feat(feat-48): base`, a bare `origin` remote, a push, and `just install-hooks` in the temporary repository only (`core.hooksPath` = `tools/hooks`). Every `git commit`/`git push`/`just` call ran with `GITHUB_BASE_REF=work` in the environment (base = `origin/work`).
    (1) T1, the marker skips the commit hooks: `corruption: [unclosed,` was added to the YAML frontmatter of `docs/txt/txt-eff55a59-137b-40b0-8f7b-44c349aa923a-engineering-handbook.md` (after the `version:` line), and `just validate` was verified to fail on it first (exit 1, `✗ docs/txt/txt-eff55a59-... (txt): while parsing a flow node ... in "the frontmatter block", line 10, column 1`, `summary: linted=1 failed=1 skipped=0 excluded=0`), so the fixture is real. Then `SKIP_HOOKS_FOR_BULK=1 git commit -am "bulk import of history"` → the commit was created (`[work f599efe] bulk import of history`, `1 file changed, 1 insertion(+)`) even with the broken document and the non-conforming message; the skip notice was printed for `pre-commit` and for `commit-msg` (two lines each, the hook name the only difference), and no gate output appeared.
    (2) T2, the backstop stops the bypassed commit: `git push origin work` → the pre-push hook ran gate 1, `commit-check`: `[commit-check.sh] FAIL f599efe bulk import of history`, `[commit-check.sh] 1 of 1 commit message(s) not correct.`, `error: recipe 'commit-check' failed on line 49 with exit code 1`, `error: failed to push some refs to '/tmp/opencode/.../origin.git'` (push exit 1). `origin/work` stayed at the base commit. Gate 1 stopped first, although `validate` would have failed on the corrupted document too — the stop-on-first-failing-gate behavior.
    (3) T3, the marker skips the pre-push hook: `SKIP_HOOKS_FOR_BULK=1 git push origin work` → the push succeeded despite the broken state (`f9a7517..f599efe work -> work`, exit 0); the skip notice was printed for `pre-push`, and no gate output appeared.
    (4) T4, a clean push passes: `git reset --hard f9a7517` (the base commit; the document comes back clean from it), then — one addition to the prescribed setup, needed because T3 had advanced `origin/work` — `git push --force origin work` brought `origin/work` back to the base as well, and its pre-push run was green over all six gates (`[commit-check.sh] No commit in origin/work..HEAD. Nothing to check. PASS`, `[validate-docs.sh] ... Nothing to validate. PASS`, `[lint.sh] PASS. No finding.`, check-pins `RESULT: PASS. 102 ...`, check-workflows `RESULT: PASS. 27 run step(s) ...`, `[check-sudo.sh] 118 file(s) checked, ... PASS`, `+ f599efe...f9a7517 work -> work (forced update)`). Then `git commit --allow-empty -m "feat(feat-48): clean commit"` → the pre-commit hook ran the six gates green and the commit-msg hook printed `[commit-check.sh] OK: feat(feat-48): clean commit`; the commit was created (`[work 5252659] feat(feat-48): clean commit`). Then `git push origin work` → the pre-push hook was green over all six gates (`[commit-check.sh] OK   5252659 feat(feat-48): clean commit`, `[commit-check.sh] 1 commit message(s) correct. PASS`, the five other PASS lines), and the push succeeded (`f9a7517..5252659 work -> work`, exit 0).
6. The quality gates at the repository root of this worktree: `just check-sudo` PASS (118 files), `just check-workflows` PASS (27 run steps), `just check-pins` PASS (102 `uses:` steps), `just commit-check` PASS (3 commit message(s) correct), `just validate` PASS (`summary: linted=1 failed=0 skipped=0 excluded=0`; the plan README of this feature is the only changed document), `just lint` PASS (no finding). `just validate` was run again after the text of this entry was added, and it still passes.
7. Two notes. (a) The `core.hooksPath` of this worktree stayed unset for the whole test: `git config --get core.hooksPath` exits with code 1 (the key is absent) before and after the test. (b) Observation for Phase 130 and the owner: the file selection of `check-sudo.sh` matches only `*.sh`, `*.bash`, `*.just`, `justfile`, `*.yml` and `*.yaml` inside the scanned folders, so the extensionless hook files in `tools/hooks/` are not among the scanned files (the count stayed 118 since Phase 110; a manual scan of the three hook files finds no `sudo`/`doas`/`pkexec` command word — the only occurrences of the word "sudo" are the recipe name `check-sudo`, which the gate does not flag because `-` is not a command boundary). REQ-007 is met by the content of the hook files, but the claim that `check-sudo` covers them file-by-file is not exact while the extension list of the gate does not include the hooks. The "Thin shells" Design Notes paragraph was corrected accordingly, so this observation is not left open.

#### 2026-11-18 08:12:28.000Z - Phase 110 complete

The agent did Tasks 110.100 and 110.110. The date of this entry is 2026-11-18: the machine clock (UTC) reads 2026-11-18 at the time of writing, one day later than the date of the Phase 100 entry.

1. The recipe (Task 110.110): the thin `just` recipe `commit-message-check subject` is in the `justfile` directly next to `commit-check`. It runs the existing gate script `tools/gates/commit-check.sh` in its `--message "<subject>"` mode, so the Conventional Commits rule (DEC a56f231b-d063-4bef-bbc8-3deb4daff76e) stays in one place, in the gate script, and the commit-msg hook in `tools/hooks/` calls the recipe. One deviation from the prescribed shape, forced by `just` semantics: the private recipe `_gate` expands its variadic argument unquoted (`exec "${path}" {{ args }}`), and a conforming subject always contains spaces and brackets, so the prescribed one-liner `commit-message-check subject: @{{ just_executable() }} _gate commit-check.sh 130.120 --message "{{ subject }}"` word-splits the subject and dies with a bash syntax error on the parenthesis (verified: `syntax error near unexpected token '('`). The recipe therefore checks that `tools/gates/commit-check.sh` is executable (the same NOT IMPLEMENTED guard as `_gate`) and then calls it directly with the quoted subject: `exec "tools/gates/commit-check.sh" --message "{{ subject }}"`. The mechanism of the owner's decision (a thin recipe, the rule in the gate script) is unchanged; see Decisions Made.
2. The pre-commit hook (Task 110.100): `tools/hooks/pre-commit` (executable, mode 100755 in git) is a thin shell (`#!/usr/bin/env bash`, `set -euo pipefail`). It stops with a clear error if `just` is not on PATH, and then runs the six fast gates in the REQ-003 order: `just commit-check`, `just validate`, `just lint`, `just check-pins`, `just check-workflows`, `just check-sudo`. With `set -e`, the first failing gate stops the commit. No gate logic, no environment-marker check (that arrives with Task 120.110), and no `sudo` (REQ-007).
3. The commit-msg hook (Task 110.110): `tools/hooks/commit-msg` (executable, mode 100755 in git) is a thin shell in the same style. It stops with a clear error if `just` is not on PATH, extracts the subject line from the message file that git gives as `$1` (the first line of the file that is not a comment, i.e. has no `#` as its first non-blank character, and not blank; that is plumbing, not gate logic), and exits 0 if the file has no subject line (git itself rejects an empty message; the hook adds no rule here). Otherwise it calls `just commit-message-check "<subject>"` and lets the exit code of the gate decide.
4. The folder README: `tools/hooks/README.md` no longer says that the `pre-commit` and `commit-msg` scripts arrive in Phase 110 (they exist now; only `pre-push` arrives in Phase 120), and the `commit-msg` row names the `just` recipe it calls: `commit-message-check`, which applies the same rule as the `commit-check` gate.
5. The tests in a throwaway repository (the hook was tested against the real gates; the `core.hooksPath` of this worktree stayed unset for the whole test, see item 7). The files of the worktree (tracked and untracked, excluding `.git`, `build`, `node_modules` and `target`) were copied to a temporary directory under /tmp/opencode, a git repository was started in it (branch `work`, a local `user.name` and `user.email`, `commit.gpgsign` false), one commit `feat(feat-48): base`, a bare `origin` remote, a push, and then `just install-hooks` in the temporary repository only (`core.hooksPath` = `tools/hooks`). Every `git commit` and every direct `just` call ran with `GITHUB_BASE_REF=work` in the environment (base = `origin/work`). The temporary repository was deleted afterwards.
   (1) S1, an invalid message is stopped: `git commit --allow-empty -m "bad message"` → the pre-commit hook ran the six gates green (`[commit-check.sh] No commit in origin/work..HEAD. Nothing to check. PASS`, `[validate-docs.sh] No document under docs/ or .specmgr/ changed. Nothing to validate. PASS`, `[lint.sh] PASS. No finding.`, check-pins `RESULT: PASS. 102 ...`, check-workflows `RESULT: PASS. 27 run step(s) ...`, `[check-sudo.sh] 118 file(s) checked, no command to get more rights. PASS`), and then the commit-msg hook rejected the message: `[commit-check.sh] NOT CORRECT: bad message`, `error: recipe 'commit-message-check' failed ... with exit code 1`. The commit exit code was 1, and `git log` was unchanged (no commit created).
   (2) S2, a valid message passes: `git commit --allow-empty -m "feat(feat-48): hooks test commit"` → the six gates ran green, the commit-msg hook printed `[commit-check.sh] OK: feat(feat-48): hooks test commit`, the commit exit code was 0, and the commit was created (the log shows `8f31c3b feat(feat-48): hooks test commit` over the base).
   (3) S3, a document that fails the validation is stopped: a line with an unclosed flow sequence (`corruption: [unclosed,`) was added to the YAML frontmatter of `docs/txt/txt-eff55a59-137b-40b0-8f7b-44c349aa923a-engineering-handbook.md`, and `just validate` (with `GITHUB_BASE_REF=work`) was verified to fail on that corruption before the commit (exit code 1, `✗ docs/txt/txt-eff55a59-... (txt): while parsing a flow node ... in "the frontmatter block", line 10, column 1`, `summary: linted=1 failed=1 skipped=0 excluded=0`), so the fixture is real. Then `git commit -am "feat(feat-48): broken doc"` → the pre-commit hook ran `commit-check` green (`[commit-check.sh] 1 commit message(s) correct. PASS`, the commit of S2 in the range) and stopped at the second gate, `validate`, on the same `✗ ... while parsing a flow node` line (`error: recipe 'validate' failed ... with exit code 1`). The other four gates did not run, the commit exit code was 1, and `git log` was unchanged. This is the demonstration of stop-on-first-failing-gate.
   (4) S4, the bypass: with the document still corrupted, `git commit --no-verify -am "totally invalid message"` → the commit was created (`[work 53ff505] totally invalid message`, `1 file changed, 1 insertion(+)`), even with the invalid message and the failing document, and the hooks produced no output at all (both skipped).
6. The quality gates at the repository root of this worktree: `just check-sudo` PASS (118 files), `just check-workflows` PASS (27 run steps), `just check-pins` PASS, `just commit-check` PASS (2 commit message(s) correct), `just validate` PASS (the plan README of this feature is the only changed document; `summary: linted=1 failed=0 skipped=0 excluded=0`), `just lint` PASS (no finding). `just validate` was run again after the text of this entry was added, and it still passes.
7. Note (an accident during the tests, corrected at once): `just install-hooks` was once started with the working directory of this worktree instead of the temporary repository, so `core.hooksPath` was set on this worktree for a short time. It was unset immediately (`git config --unset core.hooksPath`), and verified: `git config --get core.hooksPath` exits with code 1 (the key is absent), the local git config has no `core.hooksPath` entry, and all the gate results of item 6 were produced with the key absent. The entry of Phase 100 ("the recipe was never run on this worktree") is therefore amended for Phase 110 by this note.

#### 2026-11-17 16:45:26.000Z - Phase 100 complete

The agent did Tasks 100.100 and 100.110.

1. The recipe (Task 100.100): `just install-hooks` is in the `justfile` next to `verify-tools` (the local-machine recipes, not a gate). It runs `git config core.hooksPath tools/hooks` (the relative path resolves from the worktree top level, as git expects). The install is opt-in: no workflow file was touched and CI never calls the recipe. It is idempotent: `git config` with an unchanged value writes nothing, and the recipe adds no other state. The comment notes the uninstall path: `git config --unset core.hooksPath`.
2. The folder (Task 100.110): `tools/hooks/` exists with a `README.md` that names each hook and the `just` recipes it calls: `pre-commit` (Phase 110: the six fast gates `commit-check`, `validate`, `lint`, `check-pins`, `check-workflows`, `check-sudo`), `commit-msg` (Phase 110: the message of the commit in progress, with the same rule as the `commit-check` gate, DEC a56f231b-d063-4bef-bbc8-3deb4daff76e: `type(feat-N): subject`), and `pre-push` (Phase 120: the six fast gates against the base). The README states that the hook scripts arrive in Phase 110 and Phase 120, and that the hooks are bypassed with `git commit --no-verify` (details in Phase 130). The folder is covered by `just check-sudo`, which scans `tools`.
3. The test in a throwaway repository (the recipe was never run on this worktree, so the `core.hooksPath` of the developer repository is unchanged): the tracked and untracked files of the worktree were copied to a temporary directory (excluding `.git` and the build folders), a git repository was started in it (`git init`, a local `user.name` and `user.email`, `commit.gpgsign` false), and one commit was made. (1) `just install-hooks` ran, and `git config core.hooksPath` printed `tools/hooks`. (2) `git config --list` was written to a file before and after a second `just install-hooks`, and the two files were byte-identical (13 lines each: idempotent). (3) `git config --unset core.hooksPath` removed the key (`git config --get core.hooksPath` answered exit code 1, the answer for an absent key). The temporary repository and the snapshot files were deleted.
4. The quality gates at the repository root: `just check-sudo` (PASS), `just check-workflows` (PASS), `just check-pins` (PASS), `just commit-check` (PASS), `just validate` (PASS), `just lint` (PASS).
5. The agent changed no workflow, no pin, no DEC and no file other than the `justfile` and this plan. The changes are not committed.

#### 2026-11-16 22:17:20.000Z - Created

The plan is drafted from GitHub issue #48 (Gates: add optional pre-commit hooks to run the fast local gates, opened 2026-11-16) and from the state of the repository on 2026-11-16: the six fast gates exist in the `justfile`, and the repository has no git hooks. The issue says that this work is a separate, later feature, and that it is not part of the walking skeleton (feat-9-walking-skeleton is not planned yet). The feature id carries the issue number: `feat-48-pre-commit-hooks`.

### Decisions Made

<!-- Newest entry first -- prepend new entries directly below this comment. -->

#### 2026-11-18 14:11:55.000Z - The opt-out environment marker is named SKIP_HOOKS_FOR_BULK

The owner fixed the name (2026-11-17) of the environment marker for the bulk commits of the coding agent, within the limits of DEC cc4449cd-78fb-452a-904f-7efda89cf004: `SKIP_HOOKS_FOR_BULK`. When the variable is present and non-empty, all three hooks (`pre-commit`, `commit-msg`, `pre-push`) skip: they print a notice (the marker, the skip of all gates, and the limit of the DEC) and exit 0 without running any gate. The marker is documented for the bulk commits of the coding agent (for example the import of a large amount of history); an agent must not use it for a normal commit, because a gate that an agent can disable gives no protection, and the `pre-push` hook is the backstop that re-checks the commits against the base. `git commit --no-verify` and `git push --no-verify` remain the per-person bypass. The name is fixed in the Design Notes of this plan and will be documented in the handbook in Task 130.100. Source: the owner's decision during the feat-48 implementation.

#### 2026-11-18 06:31:05.000Z - The commit-msg hook uses the thin recipe commit-message-check

The owner decided (2026-11-17) that the commit-msg hook checks the subject line of the commit in progress through a new thin `just` recipe `commit-message-check`, which runs the existing gate script `commit-check.sh` in its `--message` mode (the mode is from feat-5-foundation-monorepo-ci, Task 130.120). The Conventional Commits rule (DEC a56f231b-d063-4bef-bbc8-3deb4daff76e: `type(feat-N): subject`) therefore stays in one place, in the gate script, the hook stays a thin shell (Design Notes: no gate logic in the hooks), and the one entry point rule of the `justfile` (feat-5 REQ-002, REQ-009) holds. The alternatives were rejected: the hook calling the private `_gate` recipe directly (a private recipe is not an entry point for a hook), and a copy of the regex in the hook (a second source for the rule). Source: the owner's decision during the feat-48 implementation.

#### 2026-11-16 22:17:20.000Z - Native git hooks, no hook framework

The hooks are native git hooks (shell scripts in `tools/hooks/` that call the `just` recipes), not the pre-commit framework. The sibling repository biz.dfch.SpecMgr uses the pre-commit framework for its local checks, but a new tool in this repository would need a pin and a license check (DEC 84c37f7d-08cb-457d-8ab3-1db37dba9bc9), and it would bypass the one-entry-point rule of the `justfile` (feat-5 REQ-002, REQ-009). Source: the Scope (out) of GitHub issue #48.

### Related PRs / Commits

- [Issue #48](https://github.com/dfch/biz.dfch.SpecMgrDemo/issues/48): the tracking issue for this feature.
