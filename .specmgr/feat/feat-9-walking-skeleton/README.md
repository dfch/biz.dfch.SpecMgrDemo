---
classification: null
created: '2026-11-15T21:55:00.000+01:00'
id: feat-9-walking-skeleton
status: progress
type: feat
updated: '2026-11-15T22:15:00.000+01:00'
version: 1.0.0
---

# Feature: Walking Skeleton of the Service

## Plan

### Overview

This feature gives the walking skeleton of the service. It is the feature that feat-8-traceability-security-gates blocks: it accepts the first requirement (the operation `GET /status`, written in feat-6-contracts-openapi-pipeline), it adds the first verification case record, and it gives the first running service (the backend and the frontend of the two operations). The feature also adds the new operation `GET /info` (the requirement, the contract, the backend, the frontend), the first system requirements specification, the DEC about the source, the version and the license of the service (the clause about networks of DEC 84c37f7d-08cb-457d-8ab3-1db37dba9bc9), and the threshold of the security tools of feat-8-traceability-security-gates (the decision of the owner of 2026-11-15: a finding that is Critical or High stops the job in each case, a finding that is not in the baseline stops the job, and the baseline is the state of the feature).

The documents of the phase 100 are written at the planning (2026-11-15). The code of the phases 200 to 500 is not written at this time. The branch `feat-9` is on the `dev` that contains the merged feat-8-traceability-security-gates (the pull request #47, 2026-11-15).

### Requirements

- REQ-001: The feature accepts the requirement of `GET /status` and writes the requirement of `GET /info`, the two verification case records and the entry in the first SYSRS, per SOP 95b6735b-03b8-47a0-92aa-7934a4ff1519.

- REQ-002: The backend gives the operations `GET /status` and `GET /info` of the contract. The response of `GET /info` has the version of the build, the commit of the source of the build, the copyright holder, the address of the repository and the license. The values come from the build, not from a fixed text.

- REQ-003: The frontend shows the state of `GET /status` and the notice of `GET /info` (the copyright holder, the address of the repository and the license). The text of the interface is in the i18n per DEC 51b00b5f-d1d8-49d8-9f40-28537ff69698.

- REQ-004: The service runs OpenTelemetry per DEC e3eadec0-a6ea-4efe-8e6d-fd19287122fa. The feature does not give a collector.

- REQ-005: The tests of the two requirements have the name `vcr:<uuid>` of their verification case record, in the backend (the integration test) and in the end-to-end test, per the convention of feat-8-traceability-security-gates.

- REQ-006: The security tools of feat-8-traceability-security-gates (OSV-Scanner, gitleaks, zizmor) run as blocking gates. A finding that is Critical or High stops the job in each case. A finding that is not in the baseline stops the job. The baseline file has the findings of the state of the feature (the identifiers only), so the gate passes at the state of the feature.

- REQ-007: CodeQL stops the job for a new finding that is Critical or High, with the native check of GitHub (the option B of the planning, 2026-11-15). The baseline of the other levels of CodeQL is out of scope.

- REQ-008: The dependencies of the skeleton have no finding that is Critical or High in OSV-Scanner and in CodeQL. If a version of a dependency has one, the feature chooses the version without it. The license gate of DEC 84c37f7d-08cb-457d-8ab3-1db37dba9bc9 examines each dependency.

- REQ-009: The DEC about the source, the version and the license is accepted before the service is offered to users.

- REQ-010: The gates check-workflows, check-pins and check-sudo pass for the changes of the feature. The new tool has a pin that the gate check-pins checks.

### Acceptance Criteria

- [x] ACC-001: The two requirements are accepted, the two verification case records exist, and the first SYSRS has the entry of the two requirements and of the two verification case records. The check of step 6 of SOP 95b6735b-03b8-47a0-92aa-7934a4ff1519 passes (the validation, the STE check and the traceability check). Evidence (2026-11-15, the task 100.150 and the task 100.160): the two requirements have the status `accepted` (the note of each document records the permission of the owner), the two verification case records exist (the status `draft`), and the first SYSRS has the entry of the two requirements (the section Functional Suitability and the section Reliability) and of the two verification case records (the section Verification). `just validate` passes (7 files, 0 failed, specmgr 0.38.0), `just traceability` passes (0 error, 3 warning, the task 100.160), and the STE word check is done (reference only, the gate is on hold, the owner 2026-11-03).

- [ ] ACC-002: The contract has the operation `GET /info` with the identifier of the requirement in the extension `x-specmgr-req`, and the gates of the contract pipeline (lint, breaking changes, the generated code) pass.

- [ ] ACC-003: The backend gives the two operations. The values of `GET /info` come from the build: the test changes the value of the build (the version, the commit) and sees the change of the response.

- [ ] ACC-004: The frontend shows the state of `GET /status` and the notice of `GET /info`. The test for the second language of the i18n shows the translated text.

- [ ] ACC-005: The service runs OpenTelemetry (the check of the feature shows the export of the signal).

- [ ] ACC-006: The tests have the name `vcr:<uuid>` of their verification case record, and the gate 2 gives no warning for the two requirements.

- [ ] ACC-007: The recipes of the security give exit code 0 for a finding of the baseline, and exit code 1 for a new finding, for a finding that is Critical or High, and for the failure of the tool. The self-test shows each case.

- [ ] ACC-008: CodeQL stops the job for a new finding that is Critical or High (the native check of GitHub). If the native mechanism does not exist, CodeQL stays a report and the plan records the decision (REQ-007, the task 500.130).

- [ ] ACC-009: The dependencies of the skeleton have no finding that is Critical or High (the run of OSV-Scanner and the scan of CodeQL show it), and the license gate passes for them.

- [ ] ACC-010: The DEC about the source, the version and the license is accepted (the owner), and the user interface shows the notice. Status (2026-11-15): the DEC is accepted (the task 600.110, the one-time permission of the owner); the criterion is NOT ticked (the part of the user interface is the task 300.110).

- [ ] ACC-011: The `branch-protection.md` has the steps for the owner for the new required checks of the security gates.

### Scope

#### Included

- The documents of the phase 100 (the requirement of `GET /info`, the acceptance of the requirement of `GET /status`, the two verification case records, the first SYSRS, the DEC about the source, the version and the license) — written at the planning (2026-11-15).

- The operation `GET /info` of the contract, the backend (the two operations) and the generated code.

- The frontend that shows the state and the notice, with the i18n and the OpenTelemetry.

- The tests with the name `vcr:<uuid>` of the convention of feat-8-traceability-security-gates.

- The threshold of the security tools (the baseline files and the level gate of the three recipes, the native check of CodeQL).

- The steps for the owner in the `branch-protection.md`.

#### Explicitly Out Of Scope

- The deploy of the service to a public host. The feature makes the service run locally and in CI; the owner decides the offer later (the DEC is ready for it).

- The visualization of the pipeline of CI/CD (the goal of the later feature; the spike is feat-2-react-angular-visualization-spike).

- The baseline of the levels other than Critical and High of CodeQL (the option B of the planning; a later feature or a decision of the owner).

- The pre-commit hooks (GitHub issue #48, created on 2026-11-15; a later feature).

- The close of feat-1-frontend-technology-decision (the owner does it later, not in this feature).

- The change of DEC 84c37f7d-08cb-457d-8ab3-1db37dba9bc9 (the new DEC does not change it; a pointer in that DEC is an option of the owner with a one-time permission).

### Dependencies

#### Depends On

- feat-8-traceability-security-gates (done, merged as the pull request #47 on 2026-11-15): it gives the gate 2 (the traceability check), the recipes of the security and the convention `vcr:<uuid>`.

- feat-7-verification-architecture-tools (done): it gives the model `model/workspace.json`, the pattern of the recipes of the tests and the baseline of the coverage.

- feat-6-contracts-openapi-pipeline (done): it gives the contract `contracts/openapi.yaml` and the pipeline of the generated code.

- feat-5-foundation-monorepo-ci (done): it gives the `justfile`, the CI, the gates and the branch protection.

#### Blocks

- The feature of the visualization of the pipeline (it needs the running service).

- The offer of the service to users (it needs the accepted DEC about the source, the version and the license).

### Design Notes

The owner made these decisions in the planning session of 2026-11-15 (see Decisions Made): the walking skeleton as the next feature, the option 1 of the DEC (the info operation and the notice in the user interface), the threshold of the security (the gate passes now, each new defect blocks, Critical or High is never allowed, the four tools block), the option B for CodeQL, the operation `GET /info` (not `/version`), and the pre-commit hooks as a separate GitHub issue.

#### The response of GET /info

The operation is added to `contracts/openapi.yaml` with the identifier of the requirement (REQ 271168a4-2a6f-40a1-b277-89711b18a087) in the extension `x-specmgr-req`. The response (200, `application/json`):

```
{
  "version": "0.1.0",
  "commit": "<the sha of the commit of the build>",
  "copyright": "Copyright 2026 Ronald Rink",
  "repository": "https://github.com/dfch/biz.dfch.SpecMgrDemo",
  "license": "AGPL-3.0-only"
}
```

The values come from the build (the task 200.120): the build gives the version and the commit (a resource generated at the build from the state of git), and the copyright, the repository and the license are the constants of the project. The test of the ACC-003 changes the value of the build and sees the change of the response.

#### The notice of the user interface

The user interface shows the notice with the values of `GET /info` (the task 300.110):

Copyright 2026 Ronald Rink, https://github.com/dfch/biz.dfch.SpecMgrDemo. Licensed under AGPL-3.0-only.

The sentence of the notice is in the i18n (a template with the values), per DEC 51b00b5f-d1d8-49d8-9f40-28537ff69698; the values are data, not text. The DEC 5ddd8d7a-5e7d-4a9b-860f-7d0b1f05579c gives the reading of the clause and the mechanism.

#### The model

The component `api` of `model/workspace.json` has the property `specmgr-req` of the two requirements (the list that the character comma separates, the convention of feat-8-traceability-security-gates): `1ca335d7-969a-443e-9392-165fdeea99a0, 271168a4-2a6f-40a1-b277-89711b18a087` (the task 200.130).

#### The threshold of the security (the phase 500)

The mechanism is the section "A threshold later, and the baseline file" of `tools/security/README.md` (feat-8-traceability-security-gates):

- The baseline files (the task 500.110): `tools/security/osv-baseline.txt`, `tools/security/gitleaks-baseline.txt`, `tools/security/zizmor-baseline.txt`. The file has one line for each finding of the state of the feature, the identifier only (the OSV identifier and the package for OSV-Scanner, the fingerprint for gitleaks, the audit and the file for zizmor). The file has the counts and the identifiers only, so the condition of the deviation of the OSV data (DEC 93a6d588-e002-4daf-9a47-45e2d77786e9) holds.
- The level gate (the task 500.120): a finding that is Critical or High stops the job in each case (the baseline has no line of these levels; a line of these levels in the baseline is an error of the feature). A finding that is not in the baseline stops the job. A line of the baseline that has no finding any more gives a warning (the baseline can be made smaller).
- The self-test: the case of the new finding, the case of the Critical of the baseline, the case of the old line, and the case of the failure of the tool. The function `run_security_tool` stays: the failure of the tool stops in each case.
- The CI jobs of the three recipes change from "always exit code 0 for a finding" to "exit code 1 for a blocking finding". The steps for the owner for the required checks are the task 500.140.

CodeQL (the option B, the task 500.130): the native check of GitHub stops the pull request for a new finding that is Critical or High. The task verifies the mechanism with the read of the setting (`gh api` GET). If the default setup of GitHub does not give a check that one can require, CodeQL stays a report (no change of the recipe), and the plan records the decision (the ACC-008, the part 2). The baseline of the other levels of CodeQL and the job for the SARIF file are out of scope (a later feature or a decision of the owner).

The dependencies (the task 500.100): the choice of the dependency of the skeleton examines the result of OSV-Scanner and the result of CodeQL before the baseline is written. A finding that is Critical or High stops the choice (the feature chooses the version without it, or the other library, per DEC 84c37f7d-08cb-457d-8ab3-1db37dba9bc9).

### Related Decisions

- DEC 5ddd8d7a-5e7d-4a9b-860f-7d0b1f05579c: Provide the Source, the Version and the License of the Service in the Info Operation and the User Interface (accepted on 2026-11-15, the task 600.110; the part of the user interface of the ACC-010 is pending, the task 300.110).

- DEC 84c37f7d-08cb-457d-8ab3-1db37dba9bc9: Use Only Open Source Libraries That Are Compatible With AGPL-3.0-only (the clause about networks, the license gate).

- DEC 361678a6-f941-473b-a058-1ba2bacf7d3d: Use a Test Pyramid and Blocking Gates for Verification (the threshold is a blocking gate).

- DEC 1a29c825-6862-4fe9-8069-6566262d5c97: Use React for the Frontend.

- DEC f92e35a1-77a2-4749-917f-bf9b644e8ddd: Write Interfaces First in OpenAPI and Use Layers for Validation.

- DEC 51b00b5f-d1d8-49d8-9f40-28537ff69698: Use Internationalization in the Application From the Start.

- DEC e3eadec0-a6ea-4efe-8e6d-fd19287122fa: Use OpenTelemetry for Observability.

- DEC f21920d2-4da5-4cf7-bd94-2e9bcba77342: Use Specmgr Identifiers for Traceability.

- DEC 870244cf-9bea-46bf-8ff2-fe030325743d: Use a Monorepo with Maven, pnpm, just and GitHub Actions.

- DEC 93a6d588-e002-4daf-9a47-45e2d77786e9: Register of the Approved License Deviations (the condition of the OSV data: the baseline has the identifiers only).

### Task List

#### Phase 100: The Documents and the Decisions

- [x] Task 100.100: Write the requirement of the operation `GET /info` (the document, the statement in ASD-STE100, the level, the source, the characteristics, the link to the goal).

- [x] Task 100.110: Accept the requirement of `GET /status` and the requirement of `GET /info` (the owner gives the permission in the planning, 2026-11-15; the note of each document records it).

- [x] Task 100.120: Write the verification case record of the two requirements (the name of the automatic test with `vcr:<uuid>`, per step 4 of SOP 95b6735b-03b8-47a0-92aa-7934a4ff1519).

- [x] Task 100.130: Write the first SYSRS with the entry of the two requirements and of the two verification case records (per step 5 of SOP 95b6735b-03b8-47a0-92aa-7934a4ff1519).

- [x] Task 100.140: Write the DEC about the source, the version and the license (the draft; the acceptance is the task 600.110, the owner).

- [x] Task 100.150: Do the check of the documents (the gate `just validate` on the branch of the feature, the step 6 of SOP 95b6735b-03b8-47a0-92aa-7934a4ff1519). Evidence: `just validate` passes (7 changed files, 0 failed, specmgr 0.38.0, 2026-11-15).

- [x] Task 100.160: Do the traceability check and the STE check (the step 6 of SOP 95b6735b-03b8-47a0-92aa-7934a4ff1519). Evidence: `just traceability` passes (2026-11-15): 64 document files with 240 references, 0 error, 3 warning — the 2 warnings `approved-req-vcr-not-in-test` (the tests are written in the phase 400) and the 1 warning `approved-req-has-no-model-element` of the requirement 271168a4-2a6f-40a1-b277-89711b18a087 (the property is given in the task 200.130). The STE word check is done (the script of feat-3-process-policy-baseline, reference only; the STE gate is on hold, the owner 2026-11-03): the new documents use only the common words that the documents of the repository have before.

#### Phase 200: The Contract and the Backend

- [ ] Task 200.100: Add the operation `GET /info` to `contracts/openapi.yaml` (the response with the five values, the extension `x-specmgr-req` of the requirement 271168a4-2a6f-40a1-b277-89711b18a087).

- [ ] Task 200.110: Implement the operation `GET /status` and the operation `GET /info` in the backend (the error response per the requirement, the media type `application/problem+json`).

- [ ] Task 200.120: Give the value of the build to the operation `GET /info` (the version and the commit come from the build; the unit test sees the change of the value).

- [ ] Task 200.130: Give the property `specmgr-req` of the two requirements to the component `api` of `model/workspace.json` (the list that the character comma separates).

#### Phase 300: The Frontend

- [ ] Task 300.100: Give the page that shows the state of the operation `GET /status` (the React app, the generated types and the generated Zod schemas of the contract pipeline).

- [ ] Task 300.110: Give the notice of the license in the user interface (the copyright holder, the address of the repository and the license from `GET /info`).

- [ ] Task 300.120: Give the text of the interface in the i18n per DEC 51b00b5f-d1d8-49d8-9f40-28537ff69698 (the test shows the text of the second language).

- [ ] Task 300.130: Run the OpenTelemetry of the service per DEC e3eadec0-a6ea-4efe-8e6d-fd19287122fa (the feature gives no collector).

#### Phase 400: The Verification

- [ ] Task 400.100: Write the test of the operation `GET /status` with the name `vcr:<uuid>` of the verification case record 4f98618c-4291-4d60-995f-1fd8a60b9bfd (the integration test of the backend).

- [ ] Task 400.110: Write the test of the operation `GET /info` with the name `vcr:<uuid>` of the verification case record eb8a7f16-880d-42b7-9852-37c96175d344 (the integration test of the backend and the end-to-end test).

- [ ] Task 400.120: Do the gate 2 on the documents of the feature (no error and no warning for the two requirements).

#### Phase 500: The Threshold of the Security

- [ ] Task 500.100: Choose the dependencies of the skeleton without a finding that is Critical or High (OSV-Scanner and CodeQL; the license gate per DEC 84c37f7d-08cb-457d-8ab3-1db37dba9bc9).

- [ ] Task 500.110: Write the baseline files of OSV-Scanner, gitleaks and zizmor (the findings of the state of the feature, the identifiers only).

- [ ] Task 500.120: Give the level gate to the three recipes (a finding that is Critical or High stops in each case; a finding that is not in the baseline stops; an old line gives a warning) and the cases of the self-test.

- [ ] Task 500.130: Give the native check of CodeQL for a new finding that is Critical or High (the option B; if the native mechanism does not exist, CodeQL stays a report and the plan records the decision).

- [ ] Task 500.140: Give the steps for the owner in the `branch-protection.md` for the new required checks of the security gates.

#### Phase 600: The Review and the Close

- [ ] Task 600.100: Walk the acceptance criteria and give the evidence in the plan.

- [x] Task 600.110: The acceptance of the DEC about the source, the version and the license by the owner (the one-time permission, the status accepted). Evidence: the owner gives the one-time permission in the chat (2026-11-15: "I give you one-time permission: I accept the AGPL DEC (Task 600.110)"); the status of the DEC 5ddd8d7a-5e7d-4a9b-860f-7d0b1f05579c is `accepted` (the entry of Updates of the DEC records it).

- [ ] Task 600.120: The review of the owner and the pull request (SOP 766e4c27-31e3-495f-9f37-307c5f3ee0e8).

- [ ] Task 600.130: Set the status to done (the owner gives the permission after the merge).

## Progress

### Current Status

**As of 2026-11-15 (the planning)**: The plan is written in the planning session with the owner. The documents of the phase 100 are written: the requirement of `GET /info` (accepted), the requirement of `GET /status` (accepted, the note records the permission of the owner), the two verification case records (draft), the first SYSRS (draft) and the DEC about the source, the version and the license (draft). The GitHub issue #48 for the pre-commit hooks is created. The checks of the step 6 of the SOP pass (the task 100.150 and the task 100.160: `just validate` 0 failed, `just traceability` 0 error with the 3 warning that the task 200.130 and the phase 400 remove). The DEC about the source, the version and the license is accepted (the task 600.110, the one-time permission of the owner, 2026-11-15). The code of the phases 200 to 500 is not written. The branch `feat-9` is on the `dev` that contains the merged feat-8-traceability-security-gates (the commit `c194d5e`). **The next step is the phase 200 (the contract and the backend), starting with the task 200.100.**

### Blockers

None. The acceptance of the DEC is done (the task 600.110, the one-time permission of the owner, 2026-11-15). The next step is the phase 200 (the task 200.100).

### Updates

<!-- Newest entry first -- prepend new entries directly below this comment. -->

#### 2026-11-15 22:15:00.000+01:00 - The owner accepts the DEC; handover to the phase 200

The owner gives the one-time permission to accept the DEC 5ddd8d7a-5e7d-4a9b-860f-7d0b1f05579c (statement in the chat, 2026-11-15: "I give you one-time permission: I accept the AGPL DEC (Task 600.110)"). The status of the DEC is `accepted` (the entry of Updates of the DEC records it). The task 600.110 is ticked; the ACC-010 stays not ticked (the part of the user interface is the task 300.110). **Handover note for the next session (SOP 766e4c27-31e3-495f-9f37-307c5f3ee0e8, the step 7):** the branch `feat-9` (the worktree `/home/user/src/biz.dfch.SpecMgrDemo.worktree/feat-9`, on the `dev` with the merged feat-8) has the complete phase 100 (the two requirements accepted, the two verification case records, the first SYSRS, the DEC accepted) and the checks pass (`just validate` 7 files 0 failed; `just traceability` 0 error, 3 warning expected). The next task is the task 200.100 (the operation `GET /info` in `contracts/openapi.yaml`, the extension `x-specmgr-req` of the requirement 271168a4-2a6f-40a1-b277-89711b18a087). The commits follow the form `type(feat-9): subject`. The branch is not pushed; the pull request is with the close (the phase 600).

#### 2026-11-15 22:05:00.000+01:00 - The checks of the step 6 of the SOP pass

`just validate` passes for the 7 files that changed (0 failed, specmgr 0.38.0). `just traceability` passes (64 document files, 240 references, 0 error, 3 warning): the 2 warnings `approved-req-vcr-not-in-test` and the 1 warning `approved-req-has-no-model-element` (the requirement 271168a4-2a6f-40a1-b277-89711b18a087) are expected; the phase 400 (the tests) and the task 200.130 (the property of the model) remove them. The STE word check is done (the script of feat-3-process-policy-baseline, reference only; the STE gate is on hold by the owner on 2026-11-03). The GitHub issue #48 (the pre-commit hooks) is created. The task 100.150, the task 100.160 and the ACC-001 are ticked.

#### 2026-11-15 21:55:00.000+01:00 - The planning and the documents of the phase 100

The plan is written in the planning session with the owner. The owner decides: (1) the walking skeleton is the next feature (the feature that the feat-8 blocks), (2) the DEC about the AGPL: the option 1 (the operation `GET /info` and the notice in the user interface), the reading of the clause (section 13 of AGPL-3.0 asks for the source of a modified version that users operate through a network; the owner determined that the clause applies to the party that reuses and modifies the code, and it does not apply to the user that operates the web site; the service gives the frontend to the client of the user, and the mechanism satisfies the source of the copy that is given; a person who has competence in the law must examine the DEC), (3) the threshold of the security: the gate passes at the state of the feature, each new finding blocks, a finding that is Critical or High blocks in each case, the four tools block, CodeQL with the option B (the native check, a new finding that is Critical or High only), (4) the operation is `GET /info` (not `/version`), (5) the close of the feat-1 is later (the owner), (6) the pre-commit hooks are a separate GitHub issue (created now, a later feature). The documents of the phase 100 are written in the branch `feat-9` (the worktree). The feat-8 is merged into the `dev` (the pull request #47) before the branch is created, so the gate 2 and the recipes of the security are on the branch from the start.

### Decisions Made

<!-- Newest entry first -- prepend new entries directly below this comment. -->

#### 2026-11-15 22:15:00.000+01:00 - The owner accepts the DEC about the AGPL

The owner gives the one-time permission to accept the DEC 5ddd8d7a-5e7d-4a9b-860f-7d0b1f05579c (the statement in the chat, 2026-11-15). The status is `accepted`. The remark of the DEC stays open: a person who has competence in the law must examine it.

#### 2026-11-15 21:55:00.000+01:00 - The decisions of the owner in the planning session

- The walking skeleton is the feat-9, after the feat-8 (the feat-8 blocks it explicitly).

- The DEC about the AGPL (5ddd8d7a-5e7d-4a9b-860f-7d0b1f05579c): the option 1. The owner determined that the clause of the section 13 (the network) applies to the reuse and the modification of the code, and it does not apply to the user that operates the web site. The owner gives the notice: "Copyright 2026 Ronald Rink, http://`<repo-url>`. Licensed under AGPL-3.0-only." The framing is confirmed by the owner (2026-11-15).

- The threshold of the security (REQ-006, REQ-007): the baseline is the state of the feature (the gate passes now), each new finding blocks, a finding that is Critical or High blocks in each case, the four tools block. CodeQL: the option B (the native check, a new finding that is Critical or High; if the mechanism does not exist, CodeQL stays a report and the plan records it).

- The operation of the information: `GET /info` (the owner confirms, 2026-11-15).

- The feat-1 stays open; the owner closes it later (not in this feature).

- The pre-commit hooks: the GitHub issue #48 is created now (2026-11-15); the work is a separate later feature.

### Related PRs / Commits

- The pull request #47 (feat-8-traceability-security-gates, merged into the `dev` on 2026-11-15): the dependency of this feature.

- [Issue #48](https://github.com/dfch/biz.dfch.SpecMgrDemo/issues/48): the pre-commit hooks (created on 2026-11-15, this planning session; a later feature).

### More Information

The exact notice of the user interface: "Copyright 2026 Ronald Rink, https://github.com/dfch/biz.dfch.SpecMgrDemo. Licensed under AGPL-3.0-only." The form of the response of `GET /info` is in the Design Notes. The name of the system is **SpecMgrDemo** (the software system of `model/workspace.json`).
