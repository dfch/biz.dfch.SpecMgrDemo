---
created: '2026-11-15T21:50:00.000+01:00'
id: 5ddd8d7a-5e7d-4a9b-860f-7d0b1f05579c
status: accepted
type: dec
updated: '2026-11-15T22:15:00.000+01:00'
version: 1.0.0
---

# Provide the Source, the Version and the License of the Service in the Info Operation and the User Interface

## Context and Problem Statement

The repository has the license AGPL-3.0-only (DEC 84c37f7d-08cb-457d-8ab3-1db37dba9bc9). The More Information of that DEC says that the AGPL clause about networks applies if users operate the web application through a network, and the owner must make a decision about how the project obeys this clause. The feature feat-9-walking-skeleton is the first feature that gives a service that users operate through a network. This DEC gives the decision before the first running service is offered to users (the blocker that the plan of feat-8-traceability-security-gates records).

## Decision Drivers

- The license of the repository is AGPL-3.0-only.
- The service gives the frontend to the client of the user, and the client stores a copy of the code.
- A user must identify the version of the service and must get the source of it.
- The mechanism must be cheap to obey and cheap to check.

## Considered Options

- The operation `GET /info` gives the version, the commit, the copyright holder, the address of the repository and the license, and the user interface shows the notice (option 1).
- The operation `GET /info` only, with no element of the user interface (option 2).
- A second license for the offer of the service to users (option 3).
- No public offer of the service (option 4).

## Decision Outcome

The project uses option 1. The operation `GET /info` gives the version of the build, the commit of the source of the build, the copyright holder, the address of the repository and the license. The user interface shows the notice: "Copyright 2026 Ronald Rink, https://github.com/dfch/biz.dfch.SpecMgrDemo. Licensed under AGPL-3.0-only." The service is built from a pinned commit of the public repository, and the value of the commit of `GET /info` is the commit of the build.

### Consequences

- The operation `GET /info` is the requirement REQ 271168a4-2a6f-40a1-b277-89711b18a087 with the verification case record VCR eb8a7f16-880d-42b7-9852-37c96175d344 (DEC f21920d2-4da5-4cf7-bd94-2e9bcba77342).
- The sentence of the notice is in the i18n of the frontend (DEC 51b00b5f-d1d8-49d8-9f40-28537ff69698). The values are data, not text.
- A user can check the service: the user reads the commit of `GET /info` and gets the source of that commit from the repository.
- The project does not obey this DEC if the repository is not public, if the build is not from a pinned commit, or if the user interface does not show the notice.
- A person who has competence in the law must examine this DEC (the convention of DEC 84c37f7d-08cb-457d-8ab3-1db37dba9bc9). This DEC does not change that DEC.

### Confirmation

The response of `GET /info` has the five values, and the user interface shows the notice. The verification case record VCR eb8a7f16-880d-42b7-9852-37c96175d344 confirms both. The walking skeleton of feat-9-walking-skeleton gives the first running service.

## Roles and Responsibilities

### Accountable

Project owner.

### Responsible

- The author of feat-9-walking-skeleton.
- The maintainer of the build of the service.

## Tags

- license
- technology

## Source

The clause about networks in DEC 84c37f7d-08cb-457d-8ab3-1db37dba9bc9, and the decision of the owner on 2026-11-15 in the planning of feat-9-walking-skeleton.

## Related Artifacts

### Requirements

- REQ 1ca335d7-969a-443e-9392-165fdeea99a0: The System Gives Its Status
- REQ 271168a4-2a6f-40a1-b277-89711b18a087: The System Gives Its Version and Its License

### Decisions

- DEC 84c37f7d-08cb-457d-8ab3-1db37dba9bc9: Use Only Open Source Libraries That Are Compatible With AGPL-3.0-only
- DEC 51b00b5f-d1d8-49d8-9f40-28537ff69698: Use Internationalization in the Application From the Start
- DEC f21920d2-4da5-4cf7-bd94-2e9bcba77342: Use Specmgr Identifiers for Traceability

### Goals

- GOL fde907fd-6fa5-4d87-b0ce-10babc0b4562: Make Software of High Quality

## Pros and Cons

### Option 1: The Info Operation and the Notice in the User Interface

The user sees the notice in the user interface, and the user gets the exact values from the operation. The check by the user is cheap: the user reads the commit and gets the source of the commit. The cost is the operation, the values of the build and the element of the user interface.

### Option 2: The Info Operation Only

The user must know the address of the operation. The notice is not visible in the user interface. This option is weaker for a user that does not read the documentation.

### Option 3: A Second License for the Offer of the Service

The project keeps the license AGPL-3.0-only of the repository and gives a second license for the use of the service. This option changes the policy of the license of DEC 84c37f7d-08cb-457d-8ab3-1db37dba9bc9 and needs the work with a person who has competence in the law.

### Option 4: No Public Offer of the Service

The project does not offer the service to users. This option does not avoid the clause (a user that operates the service through a network is a user), and it does not give the product of the project.

## More Information

### The reading of the clause (the determination of the owner, 2026-11-15)

Section 13 of AGPL-3.0 (Remote Network Interaction) asks for the source of a modified version that users operate through a network. The owner determined that this clause applies to the party that reuses and modifies the code, and it does not apply to the user that operates the web site. The project gives its own code as a service; the project does not modify the code of another party to give the service.

### The giving of the frontend

The service gives the frontend to the client of the user, and the client stores a copy of the code. AGPL-3.0 asks for the source of a copy that is given. The notice of this DEC gives it: the address of the repository gives the source of the monorepo (the backend and the frontend), and the value of the commit gives the exact source of the build.

### The form of the notice

Copyright 2026 Ronald Rink, https://github.com/dfch/biz.dfch.SpecMgrDemo. Licensed under AGPL-3.0-only.

The values of the copyright holder and the year come from the owner. The identifier of the license is the exact expression `AGPL-3.0-only` (the SPDX identifier of the file LICENSE of the repository).

## Updates

<!-- Newest entry first -- prepend new entries directly below this comment. -->

### 2026-11-15 22:15:00.000+01:00 - Accepted

The owner gives the one-time permission to accept this decision (statement of the owner in the chat, 2026-11-15: "I give you one-time permission: I accept the AGPL DEC (Task 600.110)"). The status is now `accepted`. The remark of the Consequences stays true: a person who has competence in the law must examine this DEC.

### 2026-11-15 21:50:00.000+01:00 - Draft written

The first version of this decision is written in the planning of feat-9-walking-skeleton (the task 100.140 of the plan). The owner confirms the reading of the clause and the mechanism on 2026-11-15. The status stays `draft` until the owner accepts the DEC in the review of the feature (the task 600.110 of the plan).
