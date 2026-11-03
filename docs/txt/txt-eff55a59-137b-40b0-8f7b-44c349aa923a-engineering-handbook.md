---
classification: null
created: '2026-11-02T14:45:48.242+01:00'
id: eff55a59-137b-40b0-8f7b-44c349aa923a
status: draft
type: txt
updated: '2026-11-03T07:34:53.937+01:00'
version: 1.0.0
---

# Engineering Handbook

This handbook is the index of the development policies and standards of this repository. It has links to each goal, decision, procedure and risk. The repository is a template for new projects. The first application is a web application for menu selection in a company canteen.

## Goals and Problem

- GOL fde907fd-6fa5-4d87-b0ce-10babc0b4562: Make Software of High Quality
- GOL 9ffb930c-44e8-4d0e-b4fd-f94c7162a894: Keep One Source of Truth for Each Fact
- GOL b94e2758-3368-407e-8fee-827c897e192b: Show the Goal and the Test of Each Requirement
- GOL 330a042f-8be7-4358-b451-25a4dfcba359: Make a Template for New Projects
- PRB 85f4d435-0023-4983-8f5a-03542be56576: Projects Have No Standard for Development Work

## Process Policies

- DEC 2468257f-cb4e-4f30-a8df-6fc1d86759ce: Keep One Source of Truth for Each Type of Fact
- DEC 00a85fb8-19a2-4850-bf5f-4a18e47d46e9: Use One Mapping of ISO 29148 Levels to Specmgr Artifacts
- DEC f21920d2-4da5-4cf7-bd94-2e9bcba77342: Use Specmgr Identifiers for Traceability
- DEC 50ade92a-5647-45ab-83e8-074009f10ef5: Set Rules for Data Classification
- DEC eb6e66ca-4ceb-46b5-9865-47e20a44674a: Write Documents in ASD-STE100 English
- DEC 9eade4ab-2f03-439b-b798-770e43154f8b: Keep a Terminology Register for Technical Nouns and Verbs
- DEC a56f231b-d063-4bef-bbc8-3deb4daff76e: Use Conventional Commits, Feature Branches and a Definition of Done
- DEC cc4449cd-78fb-452a-904f-7efda89cf004: Set Limits for Coding Agents

## Technology Policies

- DEC 1a29c825-6862-4fe9-8069-6566262d5c97: Use React for the Frontend
- DEC 870244cf-9bea-46bf-8ff2-fe030325743d: Use a Monorepo with Maven, pnpm, just and GitHub Actions
- DEC f92e35a1-77a2-4749-917f-bf9b644e8ddd: Write Interfaces First in OpenAPI and Use Layers for Validation
- DEC 9edc1071-4fd0-48b6-a037-1a4cb2331f73: Make Sure That the Code Obeys the Structurizr Model
- DEC 361678a6-f941-473b-a058-1ba2bacf7d3d: Use a Test Pyramid and Blocking Gates for Verification
- DEC 51b00b5f-d1d8-49d8-9f40-28537ff69698: Use Internationalization in the Application From the Start
- DEC 84c37f7d-08cb-457d-8ab3-1db37dba9bc9: Use Only Open Source Libraries That Are Compatible With AGPL-3.0-only
- DEC 7784ddef-ee8b-4ede-8f7a-ce4e27a1cac7: Give Quality Targets as ISO 25010 Scenarios and Fitness Tests
- DEC e3eadec0-a6ea-4efe-8e6d-fd19287122fa: Use OpenTelemetry for Observability

## Procedures

- SOP 95b6735b-03b8-47a0-92aa-7934a4ff1519: Add a Requirement With Traceability
- SOP a64703aa-8e74-4c49-b7f5-f0977522a9af: Add a Term to the Terminology Register

## Risks

- RSK f126e1b7-3804-4d2e-abb5-3e9d89b6a066: STE Limits the Words for Software Specifications
- RSK 025202ba-e4a7-4f6b-a65b-92f945b6f321: ArchUniTS Cannot Do Each Necessary Rule
- RSK f682b3fb-ef1d-48f3-9fef-1e9e5ff147f7: A Code Generator Can Cause Delay
- RSK edee1891-1428-41ac-9877-d8deb20d07e9: Blocking Gates Make Work Slow for Coding Agents and Authors
- RSK 5dfbf884-0ba4-4ecc-b97e-191aca335b98: Specmgr Has No French Heading Table and No SRS Type
- RSK 3be3ffd7-62e9-4926-9996-a0806d093228: A Necessary Tool Can Break the Open Source License Rule

## Review Aids

- TXT 2e96237c-0bee-45ac-b44a-c7ffee105ab7: List of the DEC Documents for the Acceptance by the Owner
- TXT 852a2766-971a-4b1e-82c7-5d8a1539e77f: Worksheet for the STE Review

## Tools and Data

- The asdste100 MCP gives the STE rules and words. It loads the register files as more word lists.
- `terminology/en/` has the terminology register (technical nouns and technical verbs) and the gap log.

## Open Items

- The DEC about React has the status accepted. Task 300.100 of feature feat-1 is done.
- All other DEC documents have the status accepted. The STE gate and the script for the register are on hold (decision of the owner on 2026-11-03).
- The user configuration of the asdste100 MCP must load the register files in `terminology/en/`.
- The skeleton FEAT must set the versions, examine the licenses of the tools and set the thresholds from a measured baseline.
- GitHub issue #4 is about the French heading table in specmgr.

## Updates

<!-- Newest entry first -- prepend new entries directly below this comment. -->

### 2026-11-02 00:00:00.000Z - Draft written

The first version of the handbook is written as the index of the policy baseline.
