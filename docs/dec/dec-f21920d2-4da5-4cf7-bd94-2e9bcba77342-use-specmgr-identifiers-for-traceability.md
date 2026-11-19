---
classification: null
created: '2026-11-02T14:43:15.040+01:00'
id: f21920d2-4da5-4cf7-bd94-2e9bcba77342
status: accepted
type: dec
updated: '2026-11-19T00:42:09.342+01:00'
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

### Decisions

- DEC e85e9685-0787-4dff-9ee5-9d46670e9ee4: The Model Conventions
  This decision fixes the form of the property `specmgr-refs` of the model.

### Goals

- GOL b94e2758-3368-407e-8fee-827c897e192b: Show the Goal and the Test of Each Requirement

## More Information

- A Structurizr element has the references to the specmgr artifacts in the property `specmgr-refs` (the form `TYPE UUID; TYPE UUID`: the text `; ` separates the entries, and the entry is the document type and the identifier with one space between them; the types are the document types that the tag of reference uses with an identifier of the form UUID; DEC e85e9685-0787-4dff-9ee5-9d46670e9ee4 fixes the form). The old property `specmgr-req` (the identifier bare, that the character comma separates) keeps working for one release (the compatibility of Phase 150 of feat-50-structurizr-model-rules): the gate reads the two properties independently, and the warning counts the REQ identifiers of the element in the two forms (an identifier that the element gives in the two forms is counted one time). The removal of the old form is a change of a later release.
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

### 2026-11-18 20:42:00.000Z - The form `specmgr-refs` of the model (Phase 150 of feat-50-structurizr-model-rules)

On 2026-11-18, Phase 150 of feat-50-structurizr-model-rules (Task 150.100 to 150.120) extends the traceability gate for the property `specmgr-refs` (the form `TYPE UUID; TYPE UUID`, DEC e85e9685-0787-4dff-9ee5-9d46670e9ee4): the gate reads the entries of each element of the model, it checks the form of each entry, the type of each entry, and the document of the type, and the warning counts the REQ identifiers of the element in the two forms (the property `specmgr-req`, and an entry of the type `REQ` of the property `specmgr-refs`; an identifier that the element gives in the two forms is counted one time). The property of the component `api` of the model is in the new form. The old property `specmgr-req` keeps working for one release (the compatibility, Task 150.110): the removal of the old form is a change of a later release.

### 2026-11-16 10:05:00.000Z - The conventions and the approved REQ are in More Information

On 2026-11-16, the owner made the decision that the conventions and the definition of an approved REQ go into More Information. The gate of feat-8-traceability-security-gates uses them.

### 2026-11-02 00:00:00.000Z - Draft written

The first version of this decision is written.
