---
classification: null
created: '2026-11-02T14:43:08.160+01:00'
id: 2468257f-cb4e-4f30-a8df-6fc1d86759ce
status: draft
type: dec
updated: '2026-11-02T15:17:51.620+01:00'
version: 1.0.0
---

# Keep One Source of Truth for Each Type of Fact

## Context and Problem Statement

A fact about requirements, structure, interfaces, domain rules or quality can be in many locations. Copies of a fact become different after some time. The project must have one source for each type of fact.

## Decision Drivers

- Goal: keep one source of truth for each fact.
- Coding agents must know where to change a fact.
- A gate in CI can compare a source with the artifacts that come from it.

## Considered Options

- One source for each type of fact. Artifacts come from the source, or a gate compares them with the source.
- Each team selects the source.
- One document that has all facts.

## Decision Outcome

The project uses one source for each type of fact. An artifact must come from its source, or a gate must compare the artifact with its source.

### Consequences

- A change to a fact starts in its source.
- If a person changes an artifact that comes from a source by hand, the gate stops the pull request.

### Confirmation

A gate compares each artifact with its source. If they are different, the pull request cannot merge.

## Roles and Responsibilities

### Accountable

Project owner.

### Responsible

- Maintainers of the gates.

## Tags

- process
- source

## Source

Planning session of 2026-11-02.

## Related Artifacts

### Goals

- GOL 9ffb930c-44e8-4d0e-b4fd-f94c7162a894: Keep One Source of Truth for Each Fact

## More Information

| Type of fact | Source of truth |
|---|---|
| Requirements, goals, decisions, risks | Specmgr documents |
| Structure of the system | Structurizr workspace |
| Interfaces between components | OpenAPI file |
| Domain rules | Domain code |
| Quality targets | Automatic fitness tests |
| Terms | Terminology register |

## Updates

<!-- Newest entry first -- prepend new entries directly below this comment. -->

### 2026-11-02 00:00:00.000Z - Draft written

The first version of this decision is written.
