---
classification: null
created: '2026-11-17T04:20:52.459+01:00'
id: feat-48-pre-commit-hooks
status: planning
type: feat
updated: '2026-11-17T04:20:52.459+01:00'
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

Thin shells: each hook in `tools/hooks/` is a shell script with `set -euo pipefail` that calls only the existing `just` recipes (`commit-check`, `validate`, `lint`, `check-pins`, `check-workflows`, `check-sudo`). The hooks add no gate logic of their own, except the opt-out check. The scripts are in `tools/` and are therefore covered by `just check-sudo` (REQ-007), and a code owner reviews them (CODEOWNERS covers `/tools/`). No change of these two gates is necessary.

Base and commit range: in the `justfile`, `base` is `origin/GITHUB_BASE_REF`, or `origin/dev` if `GITHUB_BASE_REF` is not set (the developer machine). The hooks use the same base. `commit-check` covers the commits of the branch that are already in `HEAD`, like in CI.

Commit message of the commit in progress: a git pre-commit hook runs before the commit object exists, so the message of the new commit is not yet in `git log`. The message is checked by a commit-msg hook in the same folder, with the same rule as the `commit-check` gate (Conventional Commits with the feature scope, DEC a56f231b-d063-4bef-bbc8-3deb4daff76e: `type(feat-N): subject`). Both hooks are installed by the same `just install-hooks` recipe: `core.hooksPath` points to the whole folder, and git finds `pre-commit` and `commit-msg` in it.

Opt-out (DEC cc4449cd): `git commit --no-verify` is the documented bypass for a person. For the bulk commits of the coding agent (for example the import of a large amount of history), a documented environment marker (the name is chosen in Task 120.110 and fixed in the handbook) makes the hooks skip. Within the limits of DEC cc4449cd-78fb-452a-904f-7efda89cf004, an agent must not use the marker for a normal commit: a gate that an agent can disable gives no protection. The pre-push hook (REQ-006) is the backstop for commits that were made with the bypass: they are re-checked against the base before they reach `dev`.

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

- [ ] Task 110.100: Write the pre-commit hook: run `commit-check`, `validate`, `lint`, `check-pins`, `check-workflows` and `check-sudo` as `just` recipes. Stop the commit on the first failing gate.

- [ ] Task 110.110: Write the commit message check for the commit in progress (Conventional Commits with the feature scope, DEC a56f231b-d063-4bef-bbc8-3deb4daff76e) as a commit-msg hook in `tools/hooks/`, with the same rule as the `commit-check` gate.

#### Phase 120: Pre-Push Hook and Opt-Out

- [ ] Task 120.100: Write the pre-push hook: re-run the six fast gates as `just` recipes against the base of the pushed branch.

- [ ] Task 120.110: Implement the documented environment marker for the bulk commits of the coding agent (the hooks skip when it is set), within the limits of DEC cc4449cd-78fb-452a-904f-7efda89cf004.

#### Phase 130: Documentation and Tests

- [ ] Task 130.100: Update the README, the engineering handbook (TXT eff55a59-137b-40b0-8f7b-44c349aa923a) and `tools/README.md`: the install (`just install-hooks`) and the opt-out (`--no-verify` and the environment marker).

- [ ] Task 130.110: Test the hooks in a temporary git repository: a commit message that fails is stopped, a document that fails the validation is stopped, `--no-verify` bypasses, a second run of `install-hooks` changes nothing, the environment marker skips the hooks, and a commit made with `--no-verify` is stopped by the pre-push hook.

- [ ] Task 130.120: The owner examines the hooks, the tests and the documentation.

## Progress

### Current Status

**As of 2026-11-17**: Phase 100 is complete. The `just install-hooks` recipe exists (opt-in: CI does not call it; idempotent: a second run changes nothing; the uninstall path `git config --unset core.hooksPath` is noted in the recipe comment), and the `tools/hooks/` folder exists with a README that names each hook and the `just` recipes it calls. No hook script exists yet: `pre-commit` and `commit-msg` arrive in Phase 110, and `pre-push` in Phase 120. The six fast gates exist as `just` recipes from feat-5-foundation-monorepo-ci (`validate`, `commit-check`, `check-workflows`, `check-pins`, `check-sudo`) and feat-6-contracts-openapi-pipeline (`lint`). The work happens on the branch `feat-48-pre-commit-hooks`, and the commit messages use the scope `feat(feat-48)`.

### Blockers

- None for the start of Phase 100.

### Updates

<!-- Newest entry first -- prepend new entries directly below this comment. -->

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

#### 2026-11-16 22:17:20.000Z - Native git hooks, no hook framework

The hooks are native git hooks (shell scripts in `tools/hooks/` that call the `just` recipes), not the pre-commit framework. The sibling repository biz.dfch.SpecMgr uses the pre-commit framework for its local checks, but a new tool in this repository would need a pin and a license check (DEC 84c37f7d-08cb-457d-8ab3-1db37dba9bc9), and it would bypass the one-entry-point rule of the `justfile` (feat-5 REQ-002, REQ-009). Source: the Scope (out) of GitHub issue #48.

### Related PRs / Commits

- [Issue #48](https://github.com/dfch/biz.dfch.SpecMgrDemo/issues/48): the tracking issue for this feature.
