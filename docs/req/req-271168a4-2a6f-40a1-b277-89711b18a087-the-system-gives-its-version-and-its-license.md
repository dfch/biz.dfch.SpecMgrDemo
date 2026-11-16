---
classification: null
created: '2026-11-15T21:50:00.000+01:00'
id: 271168a4-2a6f-40a1-b277-89711b18a087
status: accepted
type: req
updated: '2026-11-15T21:50:00.000+01:00'
version: 1.0.0
---

# The System Gives Its Version and Its License

WHEN a client sends the request `GET /info`, THE system must send a response with its version, its commit, its copyright holder, the address of its repository and its license.

## Description

A client uses the operation `GET /info` to get the identification of the system and the notice of the license. The response has the status code 200 and the media type `application/json`. The body of the response has the version of the build, the commit of the source of the build, the copyright holder, the address of the repository and the license.

The values come from the build. The build is from a pinned commit of the public repository (DEC 5ddd8d7a-5e7d-4a9b-860f-7d0b1f05579c: Provide the Source, the Version and the License of the Service in the Info Operation and the User Interface).

The operation in `contracts/openapi.yaml` has the identifier of this requirement in the extension `x-specmgr-req`.

## Characteristics

1. Functional Suitability

## Level

MUST

## Priority

50

## Tags

- iso29148:syrs
- contracts
- openapi

## Source

FEAT feat-9-walking-skeleton. The owner chose the operation `GET /info` on 2026-11-15.

## Related Artifacts

### Requirements

- REQ 1ca335d7-969a-443e-9392-165fdeea99a0: The System Gives Its Status

### Decisions

- DEC 5ddd8d7a-5e7d-4a9b-860f-7d0b1f05579c: Provide the Source, the Version and the License of the Service in the Info Operation and the User Interface
- DEC f92e35a1-77a2-4749-917f-bf9b644e8ddd: Write Interfaces First in OpenAPI and Use Layers for Validation
- DEC f21920d2-4da5-4cf7-bd94-2e9bcba77342: Use Specmgr Identifiers for Traceability
- DEC 51b00b5f-d1d8-49d8-9f40-28537ff69698: Use Internationalization in the Application From the Start

### Goals

- GOL b94e2758-3368-407e-8fee-827c897e192b: Show the Goal and the Test of Each Requirement

## More Information

This is the second requirement of the project. It gives the notice of the license of DEC 5ddd8d7a-5e7d-4a9b-860f-7d0b1f05579c. The user interface shows the notice (the copyright holder, the address of the repository and the license). The verification case record of this requirement is VCR eb8a7f16-880d-42b7-9852-37c96175d344: Verification of the Info Operation.

## Notes

The status is `accepted` on 2026-11-15. The owner gives the permission in the planning of FEAT feat-9-walking-skeleton (the task 100.110 of the plan).
