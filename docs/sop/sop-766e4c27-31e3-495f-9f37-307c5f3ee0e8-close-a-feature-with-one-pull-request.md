---
classification: null
created: '2026-11-04T07:16:35.637+01:00'
id: 766e4c27-31e3-495f-9f37-307c5f3ee0e8
status: active
type: sop
updated: '2026-11-04T10:40:44.636+01:00'
version: 1.0.0
---

# Close a Feature With One Pull Request

## Purpose

This procedure tells how to finish a feature with one pull request, how a reviewer accepts it, and how to keep the notes for the next session, with no extra pull request after the merge.

## Scope

This procedure applies to each author and each coding agent. It covers the status of a feature, the plan, the handover notes, the review and the merge of the pull request of a feature. It does not cover the release of `dev` to `main`.

## Definitions

- A close-out is the set of document changes that tell that a feature is finished.
- A handover note is a short entry for the next session.
- The reviewer is the person who reviews and accepts the pull request. At this time the reviewer is the project owner (see Safety and Precautions).
- The status `review` of a feature means that the work is complete and a person must examine it. The status `done` means that a person accepted the work.

## Roles and Responsibilities

### Accountable

Project owner.

### Responsible

- Authors of changes, also coding agents, do the work, set the status of the feature, open the pull request and push the final change.
- The project owner reviews, accepts and squash-merges the pull request.

### Support

### Consulted

### Informed

## Safety and Precautions

Each pull request runs all gates and needs a review. Do not make a pull request only for a close-out. Do not push to a branch after its pull request is merged.

An agent must not approve a pull request and must not merge it. The agent must not decide by itself that the review is accepted. The agent sets the status `done` only after the owner tells it to do so.

At this time, agents work with the access token of the project owner, and the project has no other user for the review. For this reason, the project owner reviews each pull request and merges it, and the approval of the owner replaces the approval of a second person. The system does not enforce this rule. Each agent must obey it. When the project has other users, the owner changes this rule and the reviewer is a person who is not the author.

The ruleset of `dev` dismisses an approval when a new commit is pushed. Each push after an approval therefore needs a new approval.

## Procedure

### Step 1: Set the status to review and open the pull request

When the work of the feature is complete, set the status of the feature to `review` with `set_status`. Tick the tasks and the acceptance criteria that the checks prove. Write the result in the plan. Write the handover note in the plan (see Step 7). Open the pull request from the feature branch into `dev`. The title of the pull request must pass the commit check, because the squash merge uses it as the commit message.

### Step 2: Wait for the review

The agent does not approve and does not merge. The owner reviews the pull request. If the owner asks for a change, make the change and push it to the same branch. The status of the feature stays `review`. Each push needs a new review.

### Step 3: Set the status to done after the owner accepts

When the owner accepts the work and tells the agent to close the feature, set the status of the feature to `done` with `set_status`. Tick the criteria that needed the review. Add the decision of the owner to the plan if it is not there. Push the change to the same branch, so the same pull request has it. Do not open a new pull request.

### Step 4: Merge after approval and green CI

The push of Step 3 dismisses the first approval. The owner approves the pull request again, and all gates must be green. Then the owner squash-merges the pull request. The agent does not merge. If the branch is not up to date with `origin/dev`, merge `origin/dev` into the feature branch and push. Do not rebase and do not force push. The owner must approve again after such a push.

### Step 5: Keep the branch

Do not delete the feature branch, local or remote, after the merge. The owner keeps feature branches until the next release is done and deletes them after the release (see DEC d778d444-6227-4070-ae6e-b1083c78c58b). Do not push to the branch after the merge.

### Step 6: Do not copy facts that GitHub has

Do not write the number of the pull request, the merge commit or the time of the merge in the plan. The history of git and of GitHub has these facts. Keep each entry in Updates short: the result, the decision, and what is open.

### Step 7: Put the handover note in the pull request that exists

Write the handover note in the plan of the feature, in the first push of the pull request (Step 1). If no pull request is open, wait for the next work and add the note to its pull request. Do not open a pull request only for a handover note.

### Step 8: Handle a change that comes after the merge

If the owner reviews or decides something after the merge, do not make a pull request at once. Collect these items, and put them in the next pull request that is open. If the item is urgent, tell the owner and ask first. If the pull request was merged while the status of the feature was still `review`, tell the owner, and set the status `done` in the next pull request.

### Step 9: Start clean

After the owner merges, run the procedure SOP 289efe7a-2478-49b8-86b0-2d6983749832 to update the local `dev` branch. Start the next work on a new branch from `origin/dev`.

## Related Artifacts

### Decisions

- DEC 2468257f-cb4e-4f30-a8df-6fc1d86759ce: Keep One Source of Truth for Each Type of Fact
- DEC d778d444-6227-4070-ae6e-b1083c78c58b: Keep dev and main Free of Local Commits and Update Them With Fast-Forward Only
- DEC a56f231b-d063-4bef-bbc8-3deb4daff76e: Use Conventional Commits, Feature Branches and a Definition of Done
- DEC cc4449cd-78fb-452a-904f-7efda89cf004: Set Limits for Coding Agents

### Sops

- SOP 289efe7a-2478-49b8-86b0-2d6983749832: Update the Local dev Branch

## More Information

The reason was the work on feat-22-python-tools-lockfile. The review of one license entry came after the merge, and it needed its own pull request with the full gate. The gates run for about 100 seconds, but the pull request, the review and the sync cost more than the gates.

The first version of this procedure set the status `done` before the review. This was not correct, because `done` then said that the work was ready for a review, not that a person accepted it. The status `review` now tells that the work waits for a person, and `done` tells that a person accepted it. The cost is one more small review, because the push of Step 3 dismisses the first approval.

The project does not enforce the status `done` with a gate. If the owner needs this, a required check can examine the status of the feature before the merge. This is a change to a gate, and only the owner can decide it.

## Updates

<!-- Newest entry first -- prepend new entries directly below this comment. -->

### 2026-11-04 09:40:44.636Z - SOP is now active

SOP review is completed. The SOP is now active.

### 2026-11-04 09:20:24.000Z - Review flow with the status review and the final push

The owner decided on 2026-11-04 (in the chat) that the agent sets the status `review` and opens the pull request, the owner reviews and accepts, the owner tells the agent to set `done` and to push to the same pull request, and the owner approves again and squash-merges after green CI. Branches stay until the release. The Procedure now has these steps, and the Safety section tells that the agent does not approve and does not merge, and that the owner replaces the second person for now. Step 6 to Step 9 are the old Step 2 to Step 5, with the handover note moved to the first push.

### 2026-11-04 06:16:10.000Z - Created

The owner told the coding agent to write this rule after feat-22-python-tools-lockfile (statement of the owner on 2026-11-04: "do A now").
