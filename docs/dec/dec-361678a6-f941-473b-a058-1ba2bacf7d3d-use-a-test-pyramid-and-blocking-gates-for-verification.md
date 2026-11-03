---
classification: null
created: '2026-11-02T14:44:37.133+01:00'
id: 361678a6-f941-473b-a058-1ba2bacf7d3d
status: accepted
type: dec
updated: '2026-11-03T07:50:56.943+01:00'
version: 1.0.0
---

# Use a Test Pyramid and Blocking Gates for Verification

## Context and Problem Statement

The project must show that the software does the functions in the requirements. The checks must operate for each change with no deviation. The owner selected blocking gates from the first day.

## Decision Drivers

- Goal: make software of high quality.
- Goal: show the goal and the test of each requirement.
- A threshold that has no measured value can be incorrect.

## Considered Options

- Blocking gates from the first day, with thresholds from a measured baseline.
- Gates that only give a warning at first, and gates that stop the merge after some time.
- Blocking gates for contracts and architecture only.

## Decision Outcome

The project uses a test pyramid and blocking gates from the first day. The backend uses JUnit and Testcontainers. The frontend uses Vitest. End-to-end tests use Playwright. Mutation testing uses PIT in the backend and Stryker in the frontend. Tests with random data use jqwik and fast-check. Vite is a build tool. It is not a tool for verification. The skeleton FEAT measures a baseline and sets each threshold from the baseline.

### Consequences

- No gate must stop the pull request before it can merge.
- If the skeleton does not obey a gate, the project turns the gate on after the skeleton obeys it.
- A code owner must accept a change to a threshold.

### Confirmation

Branch protection must have each gate that the list in More Information gives.

## Roles and Responsibilities

### Accountable

Project owner.

### Responsible

- Maintainers of the gates.

## Tags

- technology
- verification

## Source

Planning session of 2026-11-02.

## Related Artifacts

### Goals

- GOL fde907fd-6fa5-4d87-b0ce-10babc0b4562: Make Software of High Quality
- GOL b94e2758-3368-407e-8fee-827c897e192b: Show the Goal and the Test of Each Requirement

## More Information

Blocking gates for each pull request:

1. Specmgr validation and STE check of the changed documents.
2. Traceability check.
3. Linter and check for breaking changes of the OpenAPI file.
4. The code that a generator makes is the same as the code in the repository.
5. Architecture tests.
6. Unit tests and integration tests with a threshold for coverage.
7. Threshold for the mutation score.
8. End-to-end tests with an accessibility check.
9. Security checks and SBOM.
10. License check.
11. Check of the commit messages.

## Updates

<!-- Newest entry first -- prepend new entries directly below this comment. -->

### 2026-11-03 00:00:00.000Z - STE check is on hold

The owner decided that the STE check of changed documents is not a blocking gate for now. CI runs without it. Gate 1 in More Information is only the specmgr validation of the changed documents until the owner makes a new decision. The text of the decision is not changed.

### 2026-11-02 00:00:00.000Z - Draft written

The first version of this decision is written.
