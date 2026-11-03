---
classification: null
created: '2026-11-03T07:33:24.405+01:00'
id: 2e96237c-0bee-45ac-b44a-c7ffee105ab7
status: draft
type: txt
updated: '2026-11-03T10:46:59.085+01:00'
version: 1.0.0
---

# List of the DEC Documents for the Acceptance by the Owner

This document helps the owner to examine the DEC documents of feat-3-process-policy-baseline and to accept them. The owner sets the status of a DEC to accepted. A coding agent must not do this (see the DEC about limits for coding agents). One case is on record: the owner told an agent to accept the DEC about React on 2026-11-03.

## Status of the DEC Documents

| DEC | Status |
|---|---|
| Use React for the Frontend | accepted |
| All other DEC documents (16) | accepted (on 2026-11-03) |

## Summary of Each DEC

### Process Policies

- DEC 2468257f-cb4e-4f30-a8df-6fc1d86759ce: Keep One Source of Truth for Each Type of Fact. Each type of fact has one source (specmgr documents, Structurizr workspace, OpenAPI file, domain code, fitness tests, terminology register). A gate compares each artifact with its source.
- DEC 00a85fb8-19a2-4850-bf5f-4a18e47d46e9: Use One Mapping of ISO 29148 Levels to Specmgr Artifacts. A REQ tag `iso29148:strs`, `iso29148:syrs` or `iso29148:srs` gives the level. A QA title prefix gives the level of an interview. One SYSRS for each software item holds the SRS level until specmgr has an SRS type.
- DEC f21920d2-4da5-4cf7-bd94-2e9bcba77342: Use Specmgr Identifiers for Traceability. Only the specmgr identifier is a reference. The chain is GOL, REQ, SYSRS, REQ of the SRS level, Structurizr element, OpenAPI operation, test.
- DEC 50ade92a-5647-45ab-83e8-074009f10ef5: Set Rules for Data Classification. The values of `classification` are INTERN, VERTRAULICH and GEHEIM. An agent must not send VERTRAULICH or GEHEIM text to an external AI service.
- DEC eb6e66ca-4ceb-46b5-9865-47e20a44674a: Write Documents in ASD-STE100 English. All documents are in STE and in EN. A word that is not approved must be in the register.
- DEC 9eade4ab-2f03-439b-b798-770e43154f8b: Keep a Terminology Register for Technical Nouns and Verbs. The register is in `terminology/en/` and the project writes the meanings. The owner accepted the records of the agent on 2026-11-03.
- DEC a56f231b-d063-4bef-bbc8-3deb4daff76e: Use Conventional Commits, Feature Branches and a Definition of Done. One branch for each feature, a pull request for each change, and no merge if a blocking gate stops it.
- DEC cc4449cd-78fb-452a-904f-7efda89cf004: Set Limits for Coding Agents. An agent must not accept a DEC, decrease a threshold, disable a gate or add a dependency with no inspection of the license.

### Technology Policies

- DEC 1a29c825-6862-4fe9-8069-6566262d5c97: Use React for the Frontend. Accepted.
- DEC 870244cf-9bea-46bf-8ff2-fe030325743d: Use a Monorepo with Maven, pnpm, just and GitHub Actions. A `justfile` is the one entry point for local work and for CI.
- DEC f92e35a1-77a2-4749-917f-bf9b644e8ddd: Write Interfaces First in OpenAPI and Use Layers for Validation. OpenAPI is the source for interfaces. Errors use RFC 9457 Problem Details.
- DEC 9edc1071-4fd0-48b6-a037-1a4cb2331f73: Make Sure That the Code Obeys the Structurizr Model. Spring Modulith, ArchUnit and ArchUniTS examine the code against the model.
- DEC 361678a6-f941-473b-a058-1ba2bacf7d3d: Use a Test Pyramid and Blocking Gates for Verification. 11 blocking gates for each pull request. The skeleton FEAT sets the thresholds from a measured baseline.
- DEC 51b00b5f-d1d8-49d8-9f40-28537ff69698: Use Internationalization in the Application From the Start. Message catalogs from the first day. The first release has EN only.
- DEC 84c37f7d-08cb-457d-8ab3-1db37dba9bc9: Use Only Open Source Libraries That Are Compatible With AGPL-3.0-only. A CI gate compares the licenses of all dependencies with a list.
- DEC 7784ddef-ee8b-4ede-8f7a-ce4e27a1cac7: Give Quality Targets as ISO 25010 Scenarios and Fitness Tests. Each quality REQ has a measure, a threshold and a VCR.
- DEC e3eadec0-a6ea-4efe-8e6d-fd19287122fa: Use OpenTelemetry for Observability. Traces, metrics and logs. Each error response has the trace identifier.

## Open Items for the Owner

1. License classes. The classes in the DEC about licenses (permitted, review, not permitted) are a first draft. A person who has competence in the law must examine them.
2. AGPL clause about networks. The owner must make a decision on how the AGPL-3.0 clause about use through a network applies to this project.
3. Licenses of the planned tools. No person has examined the licenses of CodeQL, PIT, Stryker and the other tools.
4. ArchUniTS. The maturity of the tool is not known. The skeleton FEAT must write the same rules and test them.
5. Terminology register. The register has more than 300 records that an agent wrote. The owner accepted them on 2026-11-03 (task 500.140).
6. GitHub issue #4. The issue is about specmgr and not about this repository. The owner can move it.
7. Gate for the STE check and script for the register. On hold (decision of the owner on 2026-11-03).

## Items on Hold

- The DEC about verification lists the STE check of changed documents as blocking gate 1. The DEC about the STE language tells authors not to use a different script for the STE check. The owner put this on hold. CI operates without the STE check, and authors do it with the asdste100 MCP.
- The DEC about the register has the same item on hold. The project has no script that validates the register at this time.

## Other Items

- The DEC about React has open risks. They are large data sets, data that changes with time, integration with the backend, accessibility and the work of developers each day. The DEC about verification and the DEC about quality must include them.
- A reviewer must examine the STE rules that a search for a word does not show. See the document about the STE review.
- A DEC must have no error in the STE check before the owner accepts it (see the DEC about the STE language).

## Updates

<!-- Newest entry first -- prepend new entries directly below this comment. -->

### 2026-11-03 00:00:00.000Z - Draft written

The first version of this document is written for the owner of the project.
