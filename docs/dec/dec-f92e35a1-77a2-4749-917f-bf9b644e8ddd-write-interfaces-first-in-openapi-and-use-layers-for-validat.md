---
classification: null
created: '2026-11-02T14:44:18.230+01:00'
id: f92e35a1-77a2-4749-917f-bf9b644e8ddd
status: draft
type: dec
updated: '2026-11-02T15:17:51.797+01:00'
version: 1.0.0
---

# Write Interfaces First in OpenAPI and Use Layers for Validation

## Context and Problem Statement

The backend and the frontend have one interface. If each side writes it by hand, the two interface files become different. Rules about data are also in different layers: format, interface and domain.

## Decision Drivers

- Goal: keep one source of truth for each fact.
- The schemas for Java and for TypeScript must be the same.
- The rules of the domain must operate with no framework.
- Java does not have preconditions and postconditions in the language.

## Considered Options

- OpenAPI is the source. The build makes the server interfaces and the client schemas from it.
- Write the code first. A tool makes the OpenAPI file from the backend.
- Schemas that persons write by hand on each side.

## Decision Outcome

The project uses OpenAPI as the source of truth for interfaces. The build makes the Spring server interfaces and the Zod schemas from the OpenAPI file. Jakarta Bean Validation examines the format of the data at the boundary. Domain objects make sure of their invariants in their constructors and factory methods. A precondition is a check at the start of a method. Property-based tests examine postconditions and invariants.

### Consequences

- A change to an interface starts in the OpenAPI file.
- Errors use RFC 9457 Problem Details. The error codes are the same for all languages.
- The project does not use a library with annotations for the rules of the domain.

### Confirmation

CI operates a linter on the OpenAPI file and a tool that finds breaking changes against the main branch. CI makes the code again and stops the pull request if the result is different from the code in the repository. Tests make sure that responses obey the OpenAPI file.

## Roles and Responsibilities

### Accountable

Project owner.

### Responsible

- Maintainers of the backend and the frontend.

## Tags

- technology
- contracts

## Source

Planning session of 2026-11-02.

## Related Artifacts

### Goals

- GOL 9ffb930c-44e8-4d0e-b4fd-f94c7162a894: Keep One Source of Truth for Each Fact

## More Information

Possible tools: Spectral (linter), oasdiff (breaking changes), openapi-generator (server interfaces), a Zod generator for the client, and jqwik and fast-check (property-based tests). The skeleton FEAT must make sure that each tool and its license are correct.

## Updates

<!-- Newest entry first -- prepend new entries directly below this comment. -->

### 2026-11-02 00:00:00.000Z - Draft written

The first version of this decision is written.
