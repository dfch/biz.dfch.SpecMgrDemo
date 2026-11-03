---
classification: null
created: '2026-11-02T14:43:43.283+01:00'
id: cc4449cd-78fb-452a-904f-7efda89cf004
status: draft
type: dec
updated: '2026-11-02T15:17:51.742+01:00'
version: 1.0.0
---

# Set Limits for Coding Agents

## Context and Problem Statement

Coding agents write most of the code. An agent can make a change that makes a gate less strong, adds a dependency, or changes a decision with no review. The project must have limits.

## Decision Drivers

- The project makes the application with coding agents.
- A gate that an agent can disable gives no protection.
- The project owner makes the decisions.

## Considered Options

- A written list of limits. Branch protection and CI make sure that the limits are obeyed.
- Do not limit the agent. Examine each change after it is done.
- Do not use coding agents.

## Decision Outcome

Coding agents must obey written limits. An agent must not accept a DEC. An agent must not decrease a threshold, disable a gate, or add a dependency without an inspection of the license. Only the project owner can do these actions.

### Consequences

- An agent writes a DEC with the status draft. The owner sets the status accepted.
- A person who is not the agent must examine a change to a gate or to a threshold.

### Confirmation

A CODEOWNERS file gives the project owner as the owner of the DEC documents, the CI configuration, the thresholds and the list of licenses. Branch protection must have the review of a code owner for each change to these files.

## Roles and Responsibilities

### Accountable

Project owner.

### Responsible

- Reviewers.
- Maintainers of the gates.

## Tags

- process
- agents

## Source

Planning session of 2026-11-02.

## Related Artifacts

### Goals

- GOL fde907fd-6fa5-4d87-b0ce-10babc0b4562: Make Software of High Quality

## More Information

An agent must also obey the DEC about data classification. It must not send text with the value VERTRAULICH or GEHEIM to an external service.

## Updates

<!-- Newest entry first -- prepend new entries directly below this comment. -->

### 2026-11-02 00:00:00.000Z - Draft written

The first version of this decision is written.
