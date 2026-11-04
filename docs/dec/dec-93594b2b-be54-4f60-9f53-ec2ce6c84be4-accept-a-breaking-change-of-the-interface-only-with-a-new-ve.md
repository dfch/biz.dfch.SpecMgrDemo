---
classification: null
created: '2026-11-04T12:13:01.518+01:00'
id: 93594b2b-be54-4f60-9f53-ec2ce6c84be4
status: draft
type: dec
updated: '2026-11-04T12:13:01.518+01:00'
version: 1.0.0
---

# Accept a Breaking Change of the Interface Only With a New Version and an Entry in a File That the Owner Examines

## Context and Problem Statement

The project uses OpenAPI as the source of truth for interfaces (DEC f92e35a1-77a2-4749-917f-bf9b644e8ddd). CI has a tool that finds breaking changes. By default, a breaking change stops the pull request. Sometimes a breaking change is correct, for example when the project replaces a field. The project has no written rule for this case. If each breaking change has its own DEC, the project gets many DEC documents in the long term. If the author can switch off the check, the check gives no protection.

The DEC about interfaces says that the tool compares the OpenAPI file with the main branch. Pull requests go to `dev`, and only a release pull request goes to `main` (DEC d778d444-6227-4070-ae6e-b1083c78c58b). The two bases give different results. The project must say which one applies.

## Decision Drivers

- The default must be that a breaking change stops the pull request.
- Each accepted breaking change must have a record with a cause that a person can read.
- The owner must examine each accepted breaking change.
- The record must not be a new DEC for each change.
- The list of accepted changes must not become larger without an end.

## Considered Options

- One policy in this DEC, and the accepted changes in an ignore file of the tool, in a path that the owner examines.
- One DEC for each accepted breaking change.
- One DEC that lists all accepted breaking changes.
- No special case. The author makes a new interface version with a new path.

## Decision Outcome

The project uses one policy, and keeps each accepted breaking change as an entry in an ignore file of the breaking-change tool. Rule 1: A pull request to `dev` is compared with the merge base of the pull request and `dev`. A release pull request to `main` is compared with `main`. The gate uses the same base as the other gates of the `justfile`. If the base has no OpenAPI file, the gate goes on, because there is nothing to compare. Rule 2: A breaking change stops the gate. If the ignore file has an entry for it, the gate does not stop. Rule 3: The ignore file is in a path below `tools/`. CODEOWNERS makes the owner the code owner of this path, and the owner must examine each new entry (DEC cc4449cd-78fb-452a-904f-7efda89cf004). A coding agent adds an entry only if the owner tells it to do so. Rule 4: Each entry has four items: the change as the tool names it, the cause, the number of the issue or pull request, and the release after which the entry ends. Rule 5: An entry is valid only if the version number of the interface goes up in the same pull request. The version is `info.version` in the OpenAPI file, and it follows Semantic Versioning 2.0.0. When the first number is 0, the second number must go up. If the first number is not 0, the first number must go up. The gate checks this rule. Rule 6: An entry ends after the release that has the change. After that release, `main` has the change, and the owner removes the entry in the next pull request. The owner also removes an entry that matches no change. The phase of feat-6-contracts-openapi-pipeline that selects the breaking-change tool sets the format of the entry and the way the gate checks rule 5. That phase adds an update entry to this DEC.

### Consequences

- A breaking change is possible, but it has a version change, and the owner examines it.
- Git history of the ignore file gives the record of each accepted change. The project has no DEC for each change.
- The ignore file has only the changes that are not in a release. It is short.
- A release pull request from `dev` to `main` compares all changes of the release. An accepted change in `dev` does not stop the release, because the entry is in the file.
- The gate needs a small check for the version number. If the tool cannot do this check, a script does it.
- The DEC about interfaces says "against the main branch". This DEC gives the rule for the base, and the DEC about interfaces is not changed.

### Confirmation

The gate for breaking changes has tests with these cases:
- a change that removes a field of a response stops the gate;
- the same change with an entry and a higher version does not stop the gate;
- the same change with an entry and the same version stops the gate;
- a pull request that adds the OpenAPI file for the first time goes on.

CODEOWNERS has the path of the ignore file, and the branch protection has the review of a code owner.

## Roles and Responsibilities

### Accountable

Project owner.

### Responsible

- Authors of changes to the OpenAPI file, also coding agents.
- The owner examines each entry of the ignore file.

### Informed

- Maintainers of the backend and the frontend.

## Tags

- contracts
- process

## Source

Planning session of 2026-11-04 for feat-6-contracts-openapi-pipeline. The owner told the agent to write one policy and not one DEC for each breaking change.

## Related Artifacts

### Decisions

- DEC f92e35a1-77a2-4749-917f-bf9b644e8ddd: Write Interfaces First in OpenAPI and Use Layers for Validation
- DEC d778d444-6227-4070-ae6e-b1083c78c58b: Keep dev and main Free of Local Commits and Update Them With Fast-Forward Only
- DEC cc4449cd-78fb-452a-904f-7efda89cf004: Set Limits for Coding Agents
- DEC 361678a6-f941-473b-a058-1ba2bacf7d3d: Use a Test Pyramid and Blocking Gates for Verification

## Pros and Cons

### Option 1: One Policy and an Ignore File

The record is small, and the owner examines each entry. It needs a check for the version number. The tool sets the format of the entry.

### Option 2: One DEC for Each Accepted Breaking Change

Each change is open to all persons. The project gets many DEC documents in the long term, and each one is a long text for a small change.

### Option 3: One DEC for All Accepted Breaking Changes

It has one document. The DEC must change each time, and the owner must give a permission for each change of an accepted DEC. The list has no end.

### Option 4: No Special Case

The rule is simple. A field that must change needs a new path and two interfaces for a long time. The rule is too hard for a project that starts with the version 0.

## More Information

The ignore file and its tool are not selected at this time. The tool of the DEC about interfaces is oasdiff, and it has a file for ignored changes. The tool must have a license check first (DEC 84c37f7d-08cb-457d-8ab3-1db37dba9bc9).

## Updates

<!-- Newest entry first -- prepend new entries directly below this comment. -->

### 2026-11-04 11:13:01.520Z - Created

The owner told the coding agent to write this decision. The owner told the agent to write one policy with the accepted changes in the tool, and not for one DEC for each breaking change. The status is draft until the owner accepts it.
