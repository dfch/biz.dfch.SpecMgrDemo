---
classification: null
created: '2026-11-04T19:43:07.634+01:00'
id: 1ca335d7-969a-443e-9392-165fdeea99a0
status: draft
type: req
updated: '2026-11-04T19:43:07.634+01:00'
version: 1.0.0
---

# The System Gives Its Status

WHEN a client sends the request `GET /status`, THE system must send a response with its state.

## Description

A client uses the operation `GET /status` to get the state of the system. If the system is in operation, the response has the status code 200. The body of the response has the state (`up` or `degraded`) and the time of the check.

If the system cannot give its state, it sends an error response. The error response has the media type `application/problem+json`, an error code and a trace identifier. It has no text in a language, because the frontend shows the text for each error code.

The operation in `contracts/openapi.yaml` has the identifier of this requirement in the extension `x-specmgr-req`.

## Characteristics

1. Functional Suitability
2. Reliability

## Level

MUST

## Priority

50

## Tags

- iso29148:syrs
- contracts
- openapi

## Source

FEAT feat-6-contracts-openapi-pipeline (GitHub issue #6). The owner chose the example operation `GET /status` on 2026-11-04.

## Related Artifacts

### Decisions

- DEC f92e35a1-77a2-4749-917f-bf9b644e8ddd: Write Interfaces First in OpenAPI and Use Layers for Validation
- DEC f21920d2-4da5-4cf7-bd94-2e9bcba77342: Use Specmgr Identifiers for Traceability
- DEC 51b00b5f-d1d8-49d8-9f40-28537ff69698: Use Internationalization in the Application From the Start
- DEC e3eadec0-a6ea-4efe-8e6d-fd19287122fa: Use OpenTelemetry for Observability

### Goals

- GOL b94e2758-3368-407e-8fee-827c897e192b: Show the Goal and the Test of Each Requirement

## More Information

This is the first requirement of the project. It is the example for the contract pipeline. The verification case record and the entry in a SYSRS (steps 4 and 5 of SOP 95b6735b-03b8-47a0-92aa-7934a4ff1519) are not yet written.
