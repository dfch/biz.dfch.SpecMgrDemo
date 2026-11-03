---
classification: null
created: '2026-11-02T14:37:17.816+01:00'
id: feat-3-process-policy-baseline
status: planning
type: feat
updated: '2026-11-03T06:59:13.362+01:00'
version: 1.0.0
---

# Feature: Process Policy and Standards Baseline

## Plan

### Overview

This feature gives the policies and standards for development in this repository. The repository is a template for new projects. The policies are about requirements, architecture, contracts, verification, quality, language and licenses. This feature writes the policies as specmgr documents. It does not write code for the product or the structure of the repository. GitHub issue #1 had two items for work after the first FEAT: OpenTelemetry and the levels of ISO/IEC/IEEE 29148. This feature includes the two items.

### Requirements

- REQ-001: Each policy must be a specmgr document (DEC, SOP, GOL, PRB, RSK or TXT).

- REQ-002: Each document must use the writing style of ASD-STE100. A word that is not an approved STE word must be in the terminology register.

- REQ-003: The policies must give one source of truth for each type of fact.

- REQ-004: The policies must give a mapping of the ISO/IEC/IEEE 29148 levels to specmgr artifacts.

- REQ-005: Each software library must be compatible with AGPL-3.0-only.

- REQ-006: The application must work in EN, DE and FR. The first release uses EN only.

- REQ-007: The policies must give the gates that stop a pull request.

### Acceptance Criteria

- [x] ACC-001: The goals and the problem statement are in the repository, and the handbook has links to them.

- [x] ACC-002: One DEC is in the repository for each policy in the Task List.

- [x] ACC-003: The handbook (TXT) has links to each DEC, SOP and RSK.

- [x] ACC-004: Each document has no error in the specmgr validation.

- [ ] ACC-005: The owner accepts the DEC about the frontend technology. Then task 300.100 of feat-1 is done.

- [x] ACC-006: A word check of the documents of this feature found no rejected word and no unknown word. A temporary script did the check with the word data of the asdste100 MCP. The project does not keep the script.

- [ ] ACC-007: A reviewer examines the STE rules that the tool does not examine.

### Scope

#### Included

- Goals, the problem statement, DECs, SOPs, RSKs and the handbook.

- The mapping of the ISO/IEC/IEEE 29148 levels.

- The terminology register and the process for new terms.

- The license policy.

#### Explicitly Out Of Scope

- Code for the product and the structure of the monorepo (a different FEAT).

- The walking skeleton, a web application for menu selection in a company canteen (a different FEAT).

- The French heading table in specmgr (GitHub issue #4).

- Translations of documents. Documents stay in EN.

### Dependencies

#### Depends On

- feat-2-react-angular-visualization-spike: its results are input for the DEC about the frontend technology.

#### Blocks

- The FEAT for the structure of the monorepo.

- The FEATs for contracts, architecture, verification and the walking skeleton.

### Design Notes

Each fact has one source of truth. Other artifacts come from it, or a gate compares them with it. Specmgr documents are the source for requirements. The Structurizr workspace is the source for the structure. The OpenAPI file is the source for interfaces. Domain code is the source for domain rules. Automatic fitness tests are the source for quality targets. The terminology register is the source for terms.

The levels of ISO/IEC/IEEE 29148 use QA documents and REQ tags. The title of a QA document starts with the level (BRS, StRS, SyRS or SRS). A REQ has one tag in the format `iso29148:strs`, `iso29148:syrs` or `iso29148:srs`. Specmgr has no SRS type. One SYSRS for each software item holds the SRS requirements until specmgr has an SRS type.

The frontmatter field `classification` holds the data class. The values are INTERN, VERTRAULICH and GEHEIM. Specmgr does not limit the values. A gate must examine them.

The first application is a web application for menu selection in a company canteen.

STE check: the asdste100 MCP gives the rules and the words of ASD-STE100. It loads the terminology register in `terminology/en/` as an extra word list. The project does not use its own script for the STE check. A reviewer must examine the rules that a word lookup does not show. The register has technical nouns that are not approved nouns in the base dictionary. An agent wrote the records, and they have the source `SPECMGR-DEMO:1`. The owner has not accepted them at this time.

### Related Decisions

- TXT eff55a59-137b-40b0-8f7b-44c349aa923a: Engineering Handbook
- DEC 2468257f-cb4e-4f30-a8df-6fc1d86759ce: Keep One Source of Truth for Each Type of Fact
- DEC 00a85fb8-19a2-4850-bf5f-4a18e47d46e9: Use One Mapping of ISO 29148 Levels to Specmgr Artifacts
- DEC f21920d2-4da5-4cf7-bd94-2e9bcba77342: Use Specmgr Identifiers for Traceability
- DEC 50ade92a-5647-45ab-83e8-074009f10ef5: Set Rules for Data Classification
- DEC eb6e66ca-4ceb-46b5-9865-47e20a44674a: Write Documents in ASD-STE100 English
- DEC 9eade4ab-2f03-439b-b798-770e43154f8b: Keep a Terminology Register for Technical Nouns and Verbs
- DEC a56f231b-d063-4bef-bbc8-3deb4daff76e: Use Conventional Commits, Feature Branches and a Definition of Done
- DEC cc4449cd-78fb-452a-904f-7efda89cf004: Set Limits for Coding Agents
- DEC 1a29c825-6862-4fe9-8069-6566262d5c97: Use React for the Frontend
- DEC 870244cf-9bea-46bf-8ff2-fe030325743d: Use a Monorepo with Maven, pnpm, just and GitHub Actions
- DEC f92e35a1-77a2-4749-917f-bf9b644e8ddd: Write Interfaces First in OpenAPI and Use Layers for Validation
- DEC 9edc1071-4fd0-48b6-a037-1a4cb2331f73: Make Sure That the Code Obeys the Structurizr Model
- DEC 361678a6-f941-473b-a058-1ba2bacf7d3d: Use a Test Pyramid and Blocking Gates for Verification
- DEC 51b00b5f-d1d8-49d8-9f40-28537ff69698: Use Internationalization in the Application From the Start
- DEC 84c37f7d-08cb-457d-8ab3-1db37dba9bc9: Use Only Open Source Libraries That Are Compatible With AGPL-3.0-only
- DEC 7784ddef-ee8b-4ede-8f7a-ce4e27a1cac7: Give Quality Targets as ISO 25010 Scenarios and Fitness Tests
- DEC e3eadec0-a6ea-4efe-8e6d-fd19287122fa: Use OpenTelemetry for Observability

### Task List

#### Phase 100: Basic Items

- [x] Task 100.100: Make the goals and the problem statement

- [x] Task 100.110: Make the DEC about the terminology register

- [x] Task 100.120: Make the handbook (TXT)

- [x] Task 100.130: Make the terminology register

#### Phase 200: Process Policies

- [x] Task 200.100: DEC about the source of truth

- [x] Task 200.110: DEC about the mapping of the ISO/IEC/IEEE 29148 levels

- [x] Task 200.120: DEC about identifiers and traceability

- [x] Task 200.130: DEC about data classification

- [x] Task 200.140: DEC about language and STE

- [x] Task 200.150: DEC about commits, branches and the definition of done

- [x] Task 200.160: DEC about limits for coding agents

#### Phase 300: Technology Policies

- [x] Task 300.100: DEC about the frontend technology (React). The owner must accept it. Then task 300.100 of feat-1 is done.

- [x] Task 300.110: DEC about the monorepo, the build and CI

- [x] Task 300.120: DEC about interfaces in OpenAPI and layers for validation

- [x] Task 300.130: DEC about the architecture

- [x] Task 300.140: DEC about verification and blocking gates

- [x] Task 300.150: DEC about internationalization of the application

- [x] Task 300.160: DEC about the license policy

- [x] Task 300.170: DEC about the quality model

- [x] Task 300.180: DEC about observability

#### Phase 400: Procedures and Risks

- [x] Task 400.100: SOP to add a requirement with traceability

- [x] Task 400.110: SOP to add a term to the register

- [x] Task 400.120: SOP for the translation of a document (not made: documents stay in EN, decision of the owner on 2026-11-02)

- [x] Task 400.130: RSK records

#### Phase 500: Review

- [x] Task 500.100: Validate all documents with specmgr

- [ ] Task 500.110: The owner examines the documents and sets the status of the DEC documents to accepted

- [x] Task 500.120: Write the documents again. Then the word check shows no rejected word and no unknown word

- [ ] Task 500.130: A reviewer examines the STE rules that the tool does not examine

- [ ] Task 500.140: The owner examines the records of the terminology register and accepts them

## Progress

### Current Status

**As of 2026-11-02**: All planned documents have the status draft: 4 GOL, 1 PRB, 17 DEC, 2 SOP, 6 RSK and the handbook. All documents have no error in the specmgr validation. A word check found no rejected word and no unknown word in these documents. The terminology register has more than 300 records. A person has not examined the records and the other STE rules at this time.

### Blockers

- None for the review by the owner.

### Updates

<!-- Newest entry first -- prepend new entries directly below this comment. -->

#### 2026-11-02 00:00:00.000Z - Terminology register and new text in STE

The terminology register in `terminology/en/` is written. The asdste100 MCP loads it. All documents of this feature are written again in STE. Some titles are different, and the file names have the new titles. The gap log is the file `terminology/en/gap-log.md`.

#### 2026-11-02 00:00:00.000Z - Policy documents written

All planned documents have the status draft and have no error in the specmgr validation. The handbook has links to all of them.

#### 2026-11-02 00:00:00.000Z - Feature written

The feature is written from the planning session. The scope is policy documents only.

### Decisions Made

<!-- Newest entry first -- prepend new entries directly below this comment. -->

#### 2026-11-02 00:00:00.000Z - Keep the register in the repository and write the meanings

The project keeps the terminology register in this repository and writes the meanings. The NOTICE file of the TechnicalWords package gives these facts. IREB must agree in writing before a project stores the text of the CPRE glossary. The data of ASD-STE100 has limits of copyright.

#### 2026-11-02 00:00:00.000Z - Use DEC and not ADR

The owner selected DEC for decisions, because ADR will be removed from specmgr. SOP and TXT complete the set.

### Related PRs / Commits

- [Issue #4](https://github.com/dfch/biz.dfch.SpecMgrDemo/issues/4): the French heading table for specmgr.

### More Information

GitHub issue #1 is the first design issue. Features feat-1 and feat-2 are the first work.
