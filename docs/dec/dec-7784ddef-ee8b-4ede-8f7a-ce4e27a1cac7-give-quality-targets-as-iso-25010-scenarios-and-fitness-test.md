---
classification: null
created: '2026-11-02T14:44:53.811+01:00'
id: 7784ddef-ee8b-4ede-8f7a-ce4e27a1cac7
status: accepted
type: dec
updated: '2026-11-02T15:17:51.887+01:00'
version: 1.0.0
---

# Give Quality Targets as ISO 25010 Scenarios and Fitness Tests

## Context and Problem Statement

A quality target that has no measure cannot be examined. The project uses ISO/IEC 25010:2023 as the quality model and ISO/IEC 25030 for quality requirements. It must have a link from each characteristic to an automatic test.

## Decision Drivers

- Goal: make software of high quality.
- Each REQ must name one or more ISO/IEC 25010 characteristics.
- Each quality target must have a measure and a threshold.

## Considered Options

- Quality scenarios in REQ documents, each with a fitness test.
- A general quality plan in free text.
- Quality checks only for security and performance.

## Decision Outcome

The project writes each quality target as a REQ with a measure, a threshold and an ISO/IEC 25010 characteristic. Each such REQ has a verification case record that names an automatic fitness test. ISO/IEC 25030 gives the template of the requirement. ISO/IEC 25023 gives the measures.

### Consequences

- Each of the nine characteristics has one or more REQ with a measure, or the project records an explanation for the characteristic.
- The thresholds come from the measured baseline of the skeleton.
- The QA interview of each level has the nine categories as headings.

### Confirmation

The traceability gate stops the pull request if a quality REQ has no verification case record. The gate also stops it if a row of the matrix of the nine characteristics is empty and has no explanation.

## Roles and Responsibilities

### Accountable

Project owner.

### Responsible

- Authors of requirements.
- Maintainers of the gates.

## Tags

- technology
- quality
- iso25010

## Source

Planning session of 2026-11-02.

## Related Artifacts

### Goals

- GOL fde907fd-6fa5-4d87-b0ce-10babc0b4562: Make Software of High Quality

## More Information

Possible checks: accessibility with axe-core in Playwright, load tests, scans of dependencies and images, an SBOM, and telemetry for reliability. The skeleton FEAT makes sure that each tool is correct and examines its license.

## Updates

<!-- Newest entry first -- prepend new entries directly below this comment. -->

### 2026-11-02 00:00:00.000Z - Draft written

The first version of this decision is written.
