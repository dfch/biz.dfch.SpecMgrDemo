---
classification: null
created: '2026-11-02T14:44:22.801+01:00'
id: 9edc1071-4fd0-48b6-a037-1a4cb2331f73
status: accepted
type: dec
updated: '2026-11-02T15:17:51.813+01:00'
version: 1.0.0
---

# Make Sure That the Code Obeys the Structurizr Model

## Context and Problem Statement

A model that no tool compares with the code becomes incorrect. The project uses C4 with Structurizr as the architecture model. It must have a method to show that the code obeys the model.

## Decision Drivers

- The model must be the source of truth for the structure.
- Rules must be tests that operate with the other tests.
- It is easy to use one tool for each language.

## Considered Options

- ArchUnit and Spring Modulith for the backend, ArchUniTS for the frontend.
- The same tools, and also dependency-cruiser and eslint-plugin-boundaries.
- No automatic check.

## Decision Outcome

The project uses the Structurizr workspace as the model. In the backend, each top-level package is a Spring Modulith module and is one component of the model. Spring Modulith examines the module boundaries. ArchUnit examines the layers in a module. ArchUniTS examines the layers and the imports in the frontend. The project adds other tools only if a rule is not possible with these tools.

### Consequences

- The name of a package is the same as the identifier of its component in the model.
- A test reads the workspace and compares the components with the modules and the packages.
- After the skeleton, the owner makes a decision about the annotations of jMolecules.

### Confirmation

CI operates the architecture tests. The pull request cannot merge in two conditions. A module or a package has no component in the model. Or a dependency is not in the model.

## Roles and Responsibilities

### Accountable

Project owner.

### Responsible

- Maintainers of the architecture.

## Tags

- technology
- architecture

## Source

Planning session of 2026-11-02.

## Related Artifacts

### Goals

- GOL 9ffb930c-44e8-4d0e-b4fd-f94c7162a894: Keep One Source of Truth for Each Fact

## More Information

The maturity of ArchUniTS is not known. The skeleton FEAT must write the same rules with ArchUniTS. If a rule is not possible, the owner makes a decision about one more tool in a new DEC.

## Updates

<!-- Newest entry first -- prepend new entries directly below this comment. -->

### 2026-11-02 00:00:00.000Z - Draft written

The first version of this decision is written.
