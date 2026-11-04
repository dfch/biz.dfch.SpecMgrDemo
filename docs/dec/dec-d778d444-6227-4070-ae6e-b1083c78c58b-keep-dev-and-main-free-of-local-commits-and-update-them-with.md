---
classification: null
created: '2026-11-04T05:52:39.168+01:00'
id: d778d444-6227-4070-ae6e-b1083c78c58b
status: accepted
type: dec
updated: '2026-11-04T06:02:53.199+01:00'
version: 1.0.0
---

# Keep dev and main Free of Local Commits and Update Them With Fast-Forward Only

## Context and Problem Statement

The branches `dev` and `main` are protected, and each change reaches them through a pull request that the owner squash-merges. A squash merge makes a new commit, so the commits of the merged branch are not in `dev`. On 2026-11-04, nine commits that were on the local `dev` were already in `origin/dev` as one squash commit. The global setting `pull.rebase=true` made `git pull` replay them, and this caused a conflict in a DEC. The project has no written rule for the local `dev`.

## Decision Drivers

- A local `dev` that has diverged must stop the author, and must not start a rebase by itself.
- No commit is lost.
- The rule must be the same for each author and for coding agents.

## Considered Options

- No local commits on `dev` and `main`, a pull with fast-forward only, and a reset to `origin/dev` after a stop.
- Rebase on each pull.
- Merge commits on each pull.

## Decision Outcome

No one makes a commit on `dev` or `main`. Each change, also a change to documents only, goes on a branch and reaches `dev` through a pull request. In each clone, the settings are `pull.ff=only` and `pull.rebase=false`. If `git pull` stops because `dev` has diverged, the author keeps the local commits on a new branch if the author needs them. The author then makes `dev` the same as `origin/dev` with a reset. The exact steps are in the SOP "Update the Local dev Branch". A pull request into `dev` is a squash merge, and a release pull request from `dev` into `main` is a merge commit, because the commit check covers the range `origin/main..HEAD`, and a squash or a rebase on `main` puts each commit of `dev` in the range of the next release again. The owner keeps each feature branch, local and remote, until the next release is done, and no one adds a commit to a branch after the squash merge of its pull request. A new change starts on a new branch from `dev`. After the release, the owner deletes the old feature branches, and the release has a tag.

### Consequences

- `git pull` on `dev` stops with a clear message, and does not change the history.
- A squash merge does not cause a conflict on `dev`.
- A local commit on `dev` is not lost, because a branch keeps it before the reset.
- The author must set two settings in each clone.
- `dev` has one conventional commit for each pull request, so the title of a pull request must pass the commit check.
- The list of branches grows until the release, so the owner must delete the old branches after the release.

### Confirmation

Branch protection stops a push to `dev` and `main`. The SOP has a check: `git log origin/dev..dev` shows no commit.

## Roles and Responsibilities

### Accountable

Project owner.

### Responsible

- Authors of changes, also coding agents.

## Tags

- process
- git

## Source

The conflict of 2026-11-04 after the merge of pull request #21.

## Related Artifacts

### Decisions

- DEC a56f231b-d063-4bef-bbc8-3deb4daff76e: Use Conventional Commits, Feature Branches and a Definition of Done

## Pros and Cons

### Option 1: No Local Commits, Fast-Forward Only

A diverged `dev` is visible at once, and the repair is one reset. The author must keep the two settings in each clone.

### Option 2: Rebase on Each Pull

It is the default of some authors. It replays commits that are already in `dev` as a squash commit, and this causes conflicts.

### Option 3: Merge Commits on Each Pull

It does not cause a conflict at once. It puts the old commits in `dev` a second time, and the history has duplicates.

## More Information

The settings are local to the clone, so a global setting such as `pull.rebase=true` does not apply. The exact steps are in the SOP.

## Updates

<!-- Newest entry first -- prepend new entries directly below this comment. -->

### 2026-11-04 06:45:00.000Z - Merge methods and the life of feature branches

The owner gave a permission for one time to make this change, and no other change (statement of the owner on 2026-11-04, in the chat: "go ahead", after the agent proposed the two rules). The agent added three sentences to the Decision Outcome and two bullets to Consequences. First, a pull request into `dev` is a squash merge, and a release pull request into `main` is a merge commit (see the section "Release case" of the branch protection document of feat-5-foundation-monorepo-ci). Second, feature branches stay, local and remote, until the next release is done (decision of the owner on 2026-11-04), and no one adds a commit to a branch after its squash merge. The rulesets of GitHub are not changed by this entry. The owner applies them. The status of the DEC is not changed.

### 2026-11-04 00:00:00.000Z - Created

The owner told the coding agent to write this decision after the conflict of 2026-11-04. The status is draft until the owner accepts it.
