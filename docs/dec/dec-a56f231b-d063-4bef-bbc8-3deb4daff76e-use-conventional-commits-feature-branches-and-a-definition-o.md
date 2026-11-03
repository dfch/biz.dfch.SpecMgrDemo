---
classification: null
created: '2026-11-02T14:43:39.068+01:00'
id: a56f231b-d063-4bef-bbc8-3deb4daff76e
status: accepted
type: dec
updated: '2026-11-02T15:17:51.720+01:00'
version: 1.0.0
---

# Use Conventional Commits, Feature Branches and a Definition of Done

## Context and Problem Statement

The repository uses Conventional Commits and feature identifiers, for example `feat(feat-2): ...`. The project must have a written rule for commits, branches and the end of a task.

## Decision Drivers

- The history must show the feature of each change.
- All pull requests must obey the same gates for each author.
- Coding agents write many commits.

## Considered Options

- Conventional Commits with the feature identifier as scope, one branch for each feature, and a definition of done.
- Free commit messages.
- Do not use pull requests.

## Decision Outcome

The project uses Conventional Commits with the feature identifier as scope. Each feature has one branch. The name of the branch is the identifier of the feature. Each change goes through a pull request. A task is done only if no blocking gate stops the pull request.

### Consequences

- A tool can read the commit messages.
- A pull request that a gate stops cannot merge.

### Confirmation

A gate examines the format of the commit messages. Branch protection must have all gates and one review.

## Roles and Responsibilities

### Accountable

Project owner.

### Responsible

- Authors of changes.
- Reviewers.

## Tags

- process
- git

## Source

Planning session of 2026-11-02.

## Related Artifacts

### Goals

- GOL fde907fd-6fa5-4d87-b0ce-10babc0b4562: Make Software of High Quality

## More Information

Definition of done:

- No blocking gate stops the pull request.
- Each changed requirement has a verification case record.
- The STE check shows no error in changed documents.
- The license gate shows no error.
- The section `Progress` of the FEAT has correct data.

## Updates

<!-- Newest entry first -- prepend new entries directly below this comment. -->

### 2026-11-02 00:00:00.000Z - Draft written

The first version of this decision is written.
