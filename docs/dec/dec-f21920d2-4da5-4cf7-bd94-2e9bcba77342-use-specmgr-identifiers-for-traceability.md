---
classification: null
created: '2026-11-02T14:43:15.040+01:00'
id: f21920d2-4da5-4cf7-bd94-2e9bcba77342
status: accepted
type: dec
updated: '2026-11-02T15:17:51.653+01:00'
version: 1.0.0
---

# Use Specmgr Identifiers for Traceability

## Context and Problem Statement

A requirement must have links to a goal, to a design element, to an interface and to a test. If the links use titles or file names, they break when a title or a file name changes.

## Decision Drivers

- Goal: show the goal and the test of each requirement.
- Titles and file names change. Identifiers do not change.
- A script must find a link that has no target, and an item that has no link.

## Considered Options

- Use the specmgr identifier in each artifact.
- Use titles as references.
- Use a different file for the matrix of links.

## Decision Outcome

The project uses the specmgr identifier as the only reference. The links go in this sequence: GOL, REQ, SYSRS, REQ of the SRS level, Structurizr element, OpenAPI operation, test.

### Consequences

- A new title for an artifact does not break a link.
- Each test that examines a requirement gives the identifier of its VCR.

### Confirmation

A script in CI reads the references from the specmgr documents and the identifiers in the model, in the OpenAPI file and in the tests. The pull request cannot merge if a reference has no target, or if an approved REQ has no VCR.

## Roles and Responsibilities

### Accountable

Project owner.

### Responsible

- Maintainers of the gates.

## Tags

- process
- traceability

## Source

Planning session of 2026-11-02.

## Related Artifacts

### Goals

- GOL b94e2758-3368-407e-8fee-827c897e192b: Show the Goal and the Test of Each Requirement

## More Information

- A Structurizr element has the identifier in a `properties` entry.
- An OpenAPI operation has the identifier in an `x-` extension.
- A test gives the identifier of its VCR in its name or in an annotation.

## Updates

<!-- Newest entry first -- prepend new entries directly below this comment. -->

### 2026-11-02 00:00:00.000Z - Draft written

The first version of this decision is written.
