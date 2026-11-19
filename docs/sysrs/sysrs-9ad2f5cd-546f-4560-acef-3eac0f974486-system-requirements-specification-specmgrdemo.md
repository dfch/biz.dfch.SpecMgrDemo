---
created: '2026-11-15T21:50:00.000+01:00'
id: 9ad2f5cd-546f-4560-acef-3eac0f974486
status: draft
type: sysrs
updated: '2026-11-15T21:50:00.000+01:00'
version: 1.0.0
---

# System Requirements Specification: SpecMgrDemo

## System Purpose

The SpecMgrDemo system is a web app with a backend and a frontend. The system gives its state and its identification to a client and shows them to the user in the user interface. The feature feat-9-walking-skeleton gives the walking skeleton: the first operations, the first frontend and the first verification. The later feature gives the visualization of the pipeline of CI/CD (the goal of the project, the spike is feat-2-react-angular-visualization-spike).

## System Scope

- The system is named **SpecMgrDemo** (the software system of `model/workspace.json`).
- The system has the backend (the Maven module, the Java interfaces and the model classes) and the frontend (the pnpm module, the React app).
- The system gives the operations `GET /status` and `GET /info` at this time. The system does not give the visualization of the pipeline (the later feature).

## Business Context and Goals

### Goals

- GOL b94e2758-3368-407e-8fee-827c897e192b: Show the Goal and the Test of Each Requirement

  Each requirement of the system has a goal and a test. The walking skeleton gives the first example of this rule (the two requirements below and their two verification case records).

- GOL fde907fd-6fa5-4d87-b0ce-10babc0b4562: Make Software of High Quality

  The test pyramid and the blocking gates (DEC 361678a6-f941-473b-a058-1ba2bacf7d3d) give the quality of the software. The walking skeleton runs under the gates from the first code.

## Decisions

- DEC 870244cf-9bea-46bf-8ff2-fe030325743d: Use a Monorepo with Maven, pnpm, just and GitHub Actions

  The system is in the monorepo, with the backend (Maven) and the frontend (pnpm).

- DEC 1a29c825-6862-4fe9-8069-6566262d5c97: Use React for the Frontend

  The frontend is the React app of the pnpm module.

- DEC f92e35a1-77a2-4749-917f-bf9b644e8ddd: Write Interfaces First in OpenAPI and Use Layers for Validation

  The operations are in `contracts/openapi.yaml`; the code is generated from the contract.

- DEC 51b00b5f-d1d8-49d8-9f40-28537ff69698: Use Internationalization in the Application From the Start

  The text of the interface is in the i18n from the first page.

- DEC e3eadec0-a6ea-4efe-8e6d-fd19287122fa: Use OpenTelemetry for Observability

  The service runs OpenTelemetry from the first running service.

- DEC 5ddd8d7a-5e7d-4a9b-860f-7d0b1f05579c: Provide the Source, the Version and the License of the Service in the Info Operation and the User Interface

  The operation `GET /info` and the notice of the user interface satisfy the source availability of the service (the license AGPL-3.0-only).

## Assumptions and Dependencies

Assumptions:

- **A-01** The repository stays public (the condition of the DEC 5ddd8d7a-5e7d-4a9b-860f-7d0b1f05579c and of the deviation of CodeQL in DEC 93a6d588-e002-4daf-9a47-45e2d77786e9).
- **A-02** The service is built from a pinned commit of the repository (the value of the commit of `GET /info` is the commit of the build).

Dependencies:

- **D-01** feat-8-traceability-security-gates (the gate 2 and the recipes of the security, merged as the pull request #47 on 2026-11-15).
- **D-02** The later feature of the visualization needs the running service of this specification (this feature blocks it).

## System Overview

### System Context

The system has two technical elements (the containers of `model/workspace.json`) and one human element. The backend (the Maven module) gives the operations `GET /status` and `GET /info`; the frontend (the pnpm module) consumes the API of the backend and shows the state and the notice to the user. The user (a person with a web browser) operates the system through the network (HTTP).

```mermaid
flowchart LR
  U[User (web browser)] -->|I-01 HTTP| FE[Frontend (React app)]
  FE -->|I-02 HTTP (the API)| BE[Backend (Java, Maven)]
```

The interfaces that cross the boundary of the system:

- **I-01 User to frontend**: the user opens the page of the frontend over HTTPS.
- **I-02 Frontend to backend**: the frontend calls the operations `GET /status` and `GET /info` of the backend (the contract `contracts/openapi.yaml`).

### System Functions

- **F-1 Status**: the system gives its state (`up` or `degraded`) and the time of the check with the operation `GET /status` (REQ 1ca335d7-969a-443e-9392-165fdeea99a0).
- **F-2 Identification and license**: the system gives its version, its commit, its copyright holder, the address of its repository and its license with the operation `GET /info` (REQ 271168a4-2a6f-40a1-b277-89711b18a087). The user interface shows the notice of the license.
- **Conditions and constraints**: F-2 runs only if the build is from a pinned commit of the public repository (the assumptions A-01 and A-02).

## Requirements

### Functional Suitability

- REQ 1ca335d7-969a-443e-9392-165fdeea99a0: The System Gives Its Status

  WHEN a client sends the request `GET /status`, THE system must send a response with its state.

- REQ 271168a4-2a6f-40a1-b277-89711b18a087: The System Gives Its Version and Its License

  WHEN a client sends the request `GET /info`, THE system must send a response with its version, its commit, its copyright holder, the address of its repository and its license.

### Reliability

- REQ 1ca335d7-969a-443e-9392-165fdeea99a0: The System Gives Its Status

  The requirement has the characteristic Reliability (the second characteristic of the requirement): the system gives its state in each case, or it gives the error response (the media type `application/problem+json`).

## Verification

- VCR 4f98618c-4291-4d60-995f-1fd8a60b9bfd: Verification of the Status Operation

  Verifies REQ 1ca335d7-969a-443e-9392-165fdeea99a0 above with the test method (the integration test of the backend with the name `vcr:<uuid>`). Full coverage.

- VCR eb8a7f16-880d-42b7-9852-37c96175d344: Verification of the Info Operation

  Verifies REQ 271168a4-2a6f-40a1-b277-89711b18a087 above with the test method (the integration test of the backend and the end-to-end test with the name `vcr:<uuid>`). Full coverage.

## References

- ISO/IEC/IEEE 29148:2018, *Systems and software engineering — Life cycle processes — Requirements engineering*

- ISO/IEC 25010:2023, *Systems and software engineering — Systems and software Quality Requirements and Evaluation (SQuaRE) — System and software quality models*

## More Information

This is the first version of the specification. It covers the walking skeleton (feat-9-walking-skeleton). The later feature adds the requirements of the visualization of the pipeline. The status of this document is `draft` at the time of the writing; the acceptance of the document is with the review of the feature.

## Updates

<!-- Newest entry first -- prepend new entries directly below this comment. -->

### 2026-11-15 21:50:00.000+01:00 - Draft written

The first version of this specification is written in the planning of feat-9-walking-skeleton (the task 100.130 of the plan), per step 5 of SOP 95b6735b-03b8-47a0-92aa-7934a4ff1519. The two requirements of the walking skeleton and their two verification case records are in this document.
