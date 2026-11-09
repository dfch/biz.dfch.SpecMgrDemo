---
classification: null
created: '2026-11-03T07:54:08.480+01:00'
id: feat-7-verification-architecture-tools
status: planning
type: feat
updated: '2026-11-09T12:03:32.982+01:00'
version: 1.0.0
---

# Feature: Verification and Architecture Tools with Baseline Measurement

## Plan

### Overview

This feature adds the tools for verification and for architecture checks. These are the unit and integration test tools, the end-to-end tool, the tools for mutation tests and for random data, the architecture tools, and the check of the code against the Structurizr model. The two small modules of feat-6-contracts-openapi-pipeline (the Maven module and the pnpm module) show that each tool operates. This feature adds to the modules and does not make new ones. The feature measures a baseline. It does not set thresholds, because the verification DEC says that the skeleton sets each threshold from a measured baseline. GitHub issue #7 is for this feature. The feature is planned and not started.

### Requirements

- REQ-001: The backend must have JUnit and Testcontainers. The frontend must have Vitest. End-to-end tests must use Playwright.

- REQ-002: Mutation tests must use PIT in the backend and Stryker in the frontend. Tests with random data must use jqwik and fast-check.

- REQ-003: The backend must have Spring Modulith and ArchUnit. The frontend must have ArchUniTS.

- REQ-004: A test must read the Structurizr workspace and compare its components with the modules and the packages of the code.

- REQ-005: Each tool must have a license check before the project uses it. The result is one of the words of DEC 84c37f7d-08cb-457d-8ab3-1db37dba9bc9: Permitted, Review or Not permitted. If a license is not clear, the work stops and the owner makes a decision.

- REQ-006: The feature must measure the baseline for the coverage (line and branch in the Maven module, line in the pnpm module) and for the mutation score (PIT in the Maven module, Stryker in the pnpm module), and must write the values in this plan. The feature must not set a threshold.

- REQ-007: The end-to-end test must have an accessibility check.

- REQ-008: The maturity of ArchUniTS must be examined. If a rule is not possible with it, the owner makes a decision about one more tool in a new DEC.

### Acceptance Criteria

- [ ] ACC-001: `just` has recipes for each kind of test of this feature: unit tests (Maven module and pnpm module), integration tests (Maven module), end-to-end tests with the accessibility check, mutation tests (PIT for the Maven module, Stryker for the pnpm module), tests with random data (jqwik for the Maven module, fast-check for the pnpm module), architecture tests (Spring Modulith and ArchUnit for the Maven module, ArchUniTS for the pnpm module), and the check against the Structurizr model. CI starts only these recipes.

- [ ] ACC-002: Each tool operates on the example module and shows a test that is successful and a test that is not successful.

- [ ] ACC-003: The test that compares the Structurizr workspace with the code is not successful in two conditions: a module or a package has no component in the model, or a dependency is not in the model.

- [ ] ACC-004: The baseline values are in this plan: the line and the branch coverage of the Maven module, the line coverage of the pnpm module, and the mutation score of PIT and Stryker.

- [ ] ACC-005: Each tool has an entry in the license table of this plan with the result of the check. The result is Permitted, or a DEC of the owner for the result Review. No row has the result open.

- [ ] ACC-006: The result of the check of ArchUniTS is in this plan. It names each rule that is not possible with ArchUniTS and states whether the mitigation of RSK 025202ba-e4a7-4f6b-a65b-92f945b6f321 (a DEC for one more tool) is triggered.

### Scope

#### Included

- JUnit, Testcontainers, Vitest, Playwright, axe-core, PIT, Stryker, jqwik and fast-check.

- Spring Modulith, ArchUnit, ArchUniTS and the check against the Structurizr model.

- The accessibility check in the end-to-end test.

- The measurement of the baseline.

- The additions to the files that the features share: the `justfile` and `.github/workflows/ci.yml`.

#### Explicitly Out Of Scope

- The layout, the first version of the `justfile` and the first version of the CI workflow. The feature feat-5-foundation-monorepo-ci made them and it is done. This feature only adds to them (see the list of the shared files in Included).

- The OpenAPI pipeline (feat-6-contracts-openapi-pipeline).

- Thresholds. The walking skeleton sets them from the baseline.

- Security scans and load tests.

- OpenTelemetry (a subsequent feature).

### Dependencies

#### Depends On

- FEAT feat-6-contracts-openapi-pipeline: it gives the Maven module and the pnpm module.

- FEAT feat-5-foundation-monorepo-ci: through FEAT feat-6-contracts-openapi-pipeline.

#### Blocks

- The feature for the walking skeleton (not yet created).

### Design Notes

The DEC about verification states that no gate must stop a pull request before the pull request can merge. If the skeleton does not obey a gate, the project turns the gate on after the skeleton obeys it. In this feature, the tools run in CI as a report without a threshold, and the owner makes the decision when a gate is turned on.

The DEC about the React frontend names a condition: a custom node that has no `Handle` elements shows no edges and gives no warning, and a test must examine this condition. This feature does not take that test. It belongs to the feature for the walking skeleton, because that feature owns the code of the React frontend. The DEC gives its other open risks (large data, changes with time, integration with the backend, work of developers) to the DEC about verification (DEC 361678a6-f941-473b-a058-1ba2bacf7d3d) and the DEC about quality (DEC 7784ddef-ee8b-4ede-8f7a-ce4e27a1cac7). This feature covers accessibility only, the check that the DEC about verification names for the end-to-end test.

The DEC about the Structurizr model (DEC 9edc1071-4fd0-48b6-a037-1a4cb2331f73) and the risk RSK 025202ba-e4a7-4f6b-a65b-92f945b6f321 give the rules of ArchUniTS to the feature for the walking skeleton. This feature writes the rules and examines the maturity first, because this feature blocks the walking skeleton. The walking skeleton reuses the result.

License table (the agent fills it from the license file of each tool and not from memory). The licenses of PIT and Stryker are not checked at this time:

| Tool | Use | License | Result |
|---|---|---|---|
| JUnit | unit tests | not checked | open |
| Testcontainers | integration tests | not checked | open |
| Vitest | unit tests | not checked | open |
| Playwright | end-to-end tests | not checked | open |
| axe-core | accessibility check | not checked | open |
| PIT | mutation tests | not checked | open |
| Stryker | mutation tests | not checked | open |
| jqwik | random data | not checked | open |
| fast-check | random data | not checked | open |
| Spring Modulith | architecture | not checked | open |
| ArchUnit | architecture | not checked | open |
| ArchUniTS | architecture | not checked | open |
| Structurizr tools | model | not checked | open |

### Related Decisions

- DEC 361678a6-f941-473b-a058-1ba2bacf7d3d: Use a Test Pyramid and Blocking Gates for Verification
- DEC 9edc1071-4fd0-48b6-a037-1a4cb2331f73: Make Sure That the Code Obeys the Structurizr Model
- DEC 7784ddef-ee8b-4ede-8f7a-ce4e27a1cac7: Give Quality Targets as ISO 25010 Scenarios and Fitness Tests
- DEC 1a29c825-6862-4fe9-8069-6566262d5c97: Use React for the Frontend
- DEC 84c37f7d-08cb-457d-8ab3-1db37dba9bc9: Use Only Open Source Libraries That Are Compatible With AGPL-3.0-only
- RSK 025202ba-e4a7-4f6b-a65b-92f945b6f321: ArchUniTS Cannot Do Each Necessary Rule

### Task List

#### Phase 100: License Checks

- [ ] Task 100.100: Read the license file of each tool in the license table, and write the result. Stop and tell the owner if a license is not clear

#### Phase 110: Test Tools

- [ ] Task 110.100: Add JUnit and Testcontainers to the Maven module, with a `just` recipe

- [ ] Task 110.110: Add Vitest to the pnpm module, with a `just` recipe

- [ ] Task 110.120: Add Playwright and the accessibility check, with a `just` recipe

- [ ] Task 110.130: Add jqwik and fast-check with one example test each, one that is successful and one that is not successful

#### Phase 120: Mutation Tests

- [ ] Task 120.100: Add PIT to the Maven module, with a `just` recipe that makes a report

- [ ] Task 120.110: Add Stryker to the pnpm module, with a `just` recipe that makes a report

#### Phase 130: Architecture Tools

- [ ] Task 130.100: Add Spring Modulith and ArchUnit with example rules, one that is successful and one that is not successful

- [ ] Task 130.110: Add ArchUniTS, write the same rules (one that is successful and one that is not successful), and write the result about its maturity in this plan

- [ ] Task 130.120: Write the test that compares the Structurizr workspace with the modules, the packages and the dependencies (ACC-003)

#### Phase 140: Baseline and CI

- [ ] Task 140.100: Add the tools to the CI workflow as reports without thresholds

- [ ] Task 140.110: Measure the baseline for coverage and for the mutation score, and write the values in this plan

#### Phase 150: Review

- [ ] Task 150.100: The owner examines the license table, the result for ArchUniTS and the open items

## Progress

### Current Status

**As of 2026-11-09**: The plan is written and refined. Work has not started. The dependencies feat-5-foundation-monorepo-ci and feat-6-contracts-openapi-pipeline are done. The feature is ready to start.

### Blockers

None.

### Updates

<!-- Newest entry first -- prepend new entries directly below this comment. -->

#### 2026-11-09 00:00:00.000Z - Dependency released, plan refined

The dependencies feat-5-foundation-monorepo-ci and feat-6-contracts-openapi-pipeline are done. The blocker of 2026-11-03 is released. The plan is refined from the refinement report of 2026-11-09: one error, three gaps, five discrepancies and eight improvements are fixed in this document.

#### 2026-11-03 00:00:00.000Z - Plan written

The plan is written from the planning session of 2026-11-03.

### Decisions Made

<!-- Newest entry first -- prepend new entries directly below this comment. -->

#### 2026-11-09 00:00:00.000Z - The test for the node without Handle belongs to the walking skeleton

The DEC 1a29c825-6862-4fe9-8069-6566262d5c97 names a test that must examine a custom node that has no `Handle` elements. This feature does not take the test. It belongs to the feature for the walking skeleton (not yet created), because that feature owns the code of the React frontend. The pnpm module has no product code, and the license table has no row for React or for the graph library.

#### 2026-11-03 00:00:00.000Z - Own feature for verification and architecture

The tools for verification and architecture are a separate feature (issue #7), because they need the modules of the contract pipeline.

### Related PRs / Commits

- [Issue #7](https://github.com/dfch/biz.dfch.SpecMgrDemo/issues/7): this feature.

### More Information

The first design issue is GitHub issue #1.
