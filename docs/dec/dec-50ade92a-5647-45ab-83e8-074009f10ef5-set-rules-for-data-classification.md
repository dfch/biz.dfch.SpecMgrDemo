---
classification: null
created: '2026-11-02T14:43:17.396+01:00'
id: 50ade92a-5647-45ab-83e8-074009f10ef5
status: draft
type: dec
updated: '2026-11-02T15:17:51.670+01:00'
version: 1.0.0
---

# Set Rules for Data Classification

## Context and Problem Statement

Some documents can have sensitive data. The project must have one system to show the data class of a document. It must also have one rule for coding agents and for external services.

## Decision Drivers

- Each specmgr document has the frontmatter field `classification`.
- Specmgr does not limit the values of the field.
- Coding agents can send the text of a document to external services.

## Considered Options

- Use the field classification with three set values, and examine it in CI.
- Use tags for the data class.
- Do not show the data class of documents.

## Decision Outcome

The project uses the field `classification`. The values are INTERN, VERTRAULICH and GEHEIM. If the field has no value, the document has no data class. A coding agent must not send the text of a document with the value VERTRAULICH or GEHEIM to an external AI service. If the owner accepts a different action, a DEC must record it.

### Consequences

- A person sets the value with `set_classification`.
- An agent must read the value before it sends text to a service.

### Confirmation

A gate stops the pull request if the value is not INTERN, VERTRAULICH or GEHEIM, and is not empty.

## Roles and Responsibilities

### Accountable

Project owner.

### Responsible

- Authors of documents.
- Maintainers of the gates.

## Tags

- process
- security

## Source

Planning session of 2026-11-02.

## Related Artifacts

### Goals

- GOL fde907fd-6fa5-4d87-b0ce-10babc0b4562: Make Software of High Quality

## Updates

<!-- Newest entry first -- prepend new entries directly below this comment. -->

### 2026-11-02 00:00:00.000Z - Draft written

The first version of this decision is written.
