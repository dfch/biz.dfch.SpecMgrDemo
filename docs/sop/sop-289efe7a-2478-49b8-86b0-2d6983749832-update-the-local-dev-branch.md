---
classification: null
created: '2026-11-04T05:52:47.603+01:00'
id: 289efe7a-2478-49b8-86b0-2d6983749832
status: active
type: sop
updated: '2026-11-04T05:52:48.603+01:00'
version: 1.0.0
---

# Update the Local dev Branch

## Purpose

This procedure tells how to bring the local `dev` branch to the state of `origin/dev` without a conflict, also after a squash merge.

## Scope

This procedure applies to each author and each coding agent that works in a clone of this repository. It does not cover feature branches.

## Definitions

- A diverged `dev` is a local `dev` that has commits that `origin/dev` does not have.
- A squash merge puts the changes of a pull request in `dev` as one new commit.

## Roles and Responsibilities

### Accountable

Project owner.

### Responsible

- Authors of changes, also coding agents, run the steps.

### Support

### Consulted

### Informed

## Safety and Precautions

Do not use `git reset --hard` before you complete Step 4. A reset removes local commits and uncommitted changes from the branch. Do not use `git pull --rebase` on `dev`.

## Procedure

### Step 1: Set the pull settings once for each clone

Run `git config pull.ff only` and `git config pull.rebase false`. Run `git config --local --get-regexp '^pull\.'` and make sure that it shows both values.

### Step 2: Fetch and switch to dev

Commit or stash your changes. Run `git fetch --prune` and then `git switch dev`.

### Step 3: Pull with fast-forward only

Run `git pull`. If it ends with no error, the procedure is complete. If it stops with the message "Not possible to fast-forward", `dev` has diverged. Go to Step 4.

### Step 4: Keep the local commits

Run `git log origin/dev..dev --oneline` to see the local commits. If you need them, run `git branch backup/dev-<date> dev`. The name has the date of the day, for example `backup/dev-2026-11-04`. If a commit is a change that must stay, make a branch for it and open a pull request. Do not commit on `dev` again.

### Step 5: Make dev the same as origin/dev

Run `git reset --hard origin/dev`. Run `git status -sb` and make sure that it shows `dev...origin/dev` with no `ahead` and no `behind`.

### Step 6: Check

Run `git log origin/dev..dev`. The output must be empty. Delete a backup branch that you do not need with `git branch -D <name>`. Delete a feature branch whose pull request is merged.

## Related Artifacts

### Decisions

- DEC d778d444-6227-4070-ae6e-b1083c78c58b: Keep dev and main Free of Local Commits and Update Them With Fast-Forward Only

## More Information

The conflict of 2026-11-04 was the reason for this procedure. A squash merge makes new commits, so a rebase of old local commits on `dev` conflicts with the squash commit.

## Updates

<!-- Newest entry first -- prepend new entries directly below this comment. -->

### 2026-11-04 00:00:00.000Z - Created

The owner told the coding agent to write this procedure after the conflict of 2026-11-04.
