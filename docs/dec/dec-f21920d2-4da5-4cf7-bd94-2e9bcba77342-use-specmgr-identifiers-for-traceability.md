---
classification: null
created: '2026-11-02T14:43:15.040+01:00'
id: f21920d2-4da5-4cf7-bd94-2e9bcba77342
status: accepted
type: dec
updated: '2026-11-16T10:06:00.000+01:00'
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
- An approved REQ is a REQ with the status `accepted` or `implemented`. A REQ has no status `approved`.
- A VCR of a REQ is a VCR whose section `## Verifies` has the reference of that REQ. The section can have any number of references. The check does not examine the status of the VCR.
- The property `specmgr-req` of an element in `model/workspace.json` has one identifier, or a list of identifiers with commas between them. Each identifier must be the identifier of a REQ.
- The extension `x-specmgr-req` of an operation in `contracts/openapi.yaml` has one identifier of a REQ, or a list of identifiers (a text with commas, or a YAML list). Each identifier must be the identifier of a REQ.
- A test gives `vcr:<uuid>` inside a string literal of the test source, for example in the display name or in the title of the test. A comment does not count.
- The details are in `tools/gates/README.md` (the section "The traceability check (Gate 2)"). That file is the one place for the details. Read the details there.

## Updates

<!-- Newest entry first -- prepend new entries directly below this comment. -->

### 2026-11-16 10:05:00.000Z - The conventions and the approved REQ are in More Information

On 2026-11-16, the owner made the decision that the conventions and the definition of an approved REQ go into More Information. The gate of feat-8-traceability-security-gates uses them.

### 2026-11-02 00:00:00.000Z - Draft written

The first version of this decision is written.
