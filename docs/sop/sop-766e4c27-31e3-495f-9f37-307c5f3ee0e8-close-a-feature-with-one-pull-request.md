---
classification: null
created: '2026-11-04T07:16:35.637+01:00'
id: 766e4c27-31e3-495f-9f37-307c5f3ee0e8
status: draft
type: sop
updated: '2026-11-04T07:16:35.637+01:00'
version: 1.0.0
---

# Close a Feature With One Pull Request

## Purpose

This procedure tells how to finish a feature, and how to keep the notes for the next session, with no extra pull request after the merge.

## Scope

This procedure applies to each author and each coding agent. It covers the status of a feature, the plan, and the handover notes. It does not cover the release of `dev` to `main`.

## Definitions

- A close-out is the set of document changes that tell that a feature is finished.
- A handover note is a short entry for the next session.

## Roles and Responsibilities

### Accountable

Project owner.

### Responsible

- Authors of changes, also coding agents, run the steps.

### Support

### Consulted

### Informed

## Safety and Precautions

Each pull request runs all gates and needs a review. Do not make a pull request only for a close-out. Do not push to a branch after its pull request is merged.

## Procedure

### Step 1: Do the close-out before the merge

In the pull request of the last work of the feature, set the status of the feature to `done` with `set_status`. Tick the tasks and the acceptance criteria that the checks prove. Write the result in the plan. The merge of the pull request is then the end of the feature.

### Step 2: Do not copy facts that GitHub has

Do not write the number of the pull request, the merge commit or the time of the merge in the plan after the merge. The history of git and of GitHub has these facts. Keep each entry in Updates short: the result, the decision, and what is open.

### Step 3: Put the handover note in a pull request that exists

Write the handover note in the plan of the feature, in the same pull request as the last work. If no pull request is open, wait for the next work and add the note to its pull request. Do not open a pull request only for a handover note.

### Step 4: Handle a change that comes after the merge

If the owner reviews or decides something after the merge, do not make a pull request at once. Collect these items, and put them in the next pull request that is open. If the item is urgent, tell the owner and ask first.

### Step 5: Start clean

After the owner merges, run the procedure SOP 289efe7a-2478-49b8-86b0-2d6983749832 to update the local `dev` branch. Start the next work on a new branch from `origin/dev`.

## Related Artifacts

### Decisions

- DEC 2468257f-cb4e-4f30-a8df-6fc1d86759ce: Keep One Source of Truth for Each Type of Fact
- DEC d778d444-6227-4070-ae6e-b1083c78c58b: Keep dev and main Free of Local Commits and Update Them With Fast-Forward Only

## More Information

The reason was the work on feat-22-python-tools-lockfile. The review of one license entry came after the merge, and it needed its own pull request with the full gate. The gates run for about 100 seconds, but the pull request, the review and the sync cost more than the gates.

## Updates

<!-- Newest entry first -- prepend new entries directly below this comment. -->

### 2026-11-04 06:16:10.000Z - Created

The owner told the coding agent to write this rule after feat-22-python-tools-lockfile (statement of the owner on 2026-11-04: "do A now").
