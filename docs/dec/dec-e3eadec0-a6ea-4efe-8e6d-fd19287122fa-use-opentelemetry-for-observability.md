---
classification: null
created: '2026-11-02T14:44:57.769+01:00'
id: e3eadec0-a6ea-4efe-8e6d-fd19287122fa
status: draft
type: dec
updated: '2026-11-02T15:17:58.307+01:00'
version: 1.0.0
---

# Use OpenTelemetry for Observability

## Context and Problem Statement

GitHub issue #1 has the task for OpenTelemetry. The first FEAT did not include it. The project must have one standard method to collect traces, metrics and logs. Checks of reliability and maintainability use this data.

## Decision Drivers

- Reliability and maintainability must have data from operation.
- The solution must operate with more than one vendor.
- Telemetry must not have data about persons.

## Considered Options

- OpenTelemetry in the backend and in the frontend.
- Metrics of Spring Boot only.
- No telemetry.

## Decision Outcome

The project uses OpenTelemetry for traces, metrics and logs in the backend and in the browser. The telemetry backend is not part of this decision. The deployment selects it. Each error response of Problem Details has the trace identifier.

### Consequences

- The code must not write data about persons or secrets into telemetry.
- A test examines that each error has the trace identifier.

### Confirmation

A test examines the error responses. A review examines that the attributes of telemetry have no data about persons.

## Roles and Responsibilities

### Accountable

Project owner.

### Responsible

- Maintainers of the backend and the frontend.

## Tags

- technology
- observability

## Source

GitHub issue #1. The first FEAT did not include it.

## Related Artifacts

### Goals

- GOL fde907fd-6fa5-4d87-b0ce-10babc0b4562: Make Software of High Quality

## More Information

The library for the browser and the collector configuration are open. The skeleton FEAT selects them and examines their licenses.

## Updates

<!-- Newest entry first -- prepend new entries directly below this comment. -->

### 2026-11-02 00:00:00.000Z - Draft written

The first version of this decision is written.
