---
classification: null
created: '2026-11-03T07:54:08.480+01:00'
id: feat-7-verification-architecture-tools
status: planning
type: feat
updated: '2026-11-03T07:54:08.480+01:00'
version: 1.0.0
---

# Feature: Verification and Architecture Tools with Baseline Measurement

## Plan

### Overview

This feature adds the tools for verification and for architecture checks. These are the unit and integration test tools, the end-to-end tool, the tools for mutation tests and for random data, the architecture tools, and the check of the code against the Structurizr model. Two small modules show that each tool operates. The feature measures a baseline. It does not set thresholds, because the verification DEC says that the skeleton sets each threshold from a measured baseline. GitHub issue #7 is for this feature. The feature is planned and not started.

### Requirements

- REQ-001: The backend must have JUnit and Testcontainers. The frontend must have Vitest. End-to-end tests must use Playwright.

- REQ-002: Mutation tests must use PIT in the backend and Stryker in the frontend. Tests with random data must use jqwik and fast-check.

- REQ-003: The backend must have Spring Modulith and ArchUnit. The frontend must have ArchUniTS.

- REQ-004: A test must read the Structurizr workspace and compare its components with the modules and the packages of the code.

- REQ-005: Each tool must have a license check before the project uses it. If a license is not clear, the work stops and the owner makes a decision.

- REQ-006: The feature must measure the baseline for coverage and for the mutation score, and must write the values in this plan. The feature must not set a threshold.

- REQ-007: The end-to-end test must have an accessibility check.

- REQ-008: The maturity of ArchUniTS must be examined. If a rule is not possible with it, the owner makes a decision about one more tool in a new DEC.

### Acceptance Criteria

- [ ] ACC-001: `just` has recipes for each kind of test, and CI starts only these recipes.

- [ ] ACC-002: Each tool operates on the example module and shows a test that is successful and a test that is not successful.

- [ ] ACC-003: The test that compares the Structurizr workspace with the code is not successful if a module has no component in the model.

- [ ] ACC-004: The baseline values are in this plan.

- [ ] ACC-005: Each tool has an entry in the license table of this plan with the result of the check.

- [ ] ACC-006: The result of the check of ArchUniTS is in this plan.

### Scope

#### Included

- JUnit, Testcontainers, Vitest, Playwright, PIT, Stryker, jqwik and fast-check.

- Spring Modulith, ArchUnit, ArchUniTS and the check against the Structurizr model.

- The accessibility check in the end-to-end test.

- The measurement of the baseline.

#### Explicitly Out Of Scope

- The layout and the CI workflow (feat-5-foundation-monorepo-ci).

- The OpenAPI pipeline (feat-6-contracts-openapi-pipeline).

- Thresholds. The walking skeleton sets them from the baseline.

- Security scans and load tests.

- OpenTelemetry (a subsequent feature).

### Dependencies

#### Depends On

- feat-6-contracts-openapi-pipeline: it gives the Maven module and the pnpm module.

- feat-5-foundation-monorepo-ci: through feat-6.

#### Blocks

- The feature for the walking skeleton.

### Design Notes

The DEC about verification states that no gate must stop a pull request before the pull request can merge. If a tool does not obey a gate, the project turns the gate on after the skeleton obeys it. In this feature, the tools run in CI as a report without a threshold, and the owner makes the decision when a gate is turned on.

The DEC about the React frontend gives a test for a custom node that has no `Handle` elements. This feature can add it as an example for Vitest. The DEC also names open risks (large data, changes with time, integration with the backend, accessibility, work of developers). This feature covers accessibility only.

License table (the agent fills it from the license file of each tool and not from memory). The licenses of CodeQL, PIT and Stryker are not checked at this time:

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

- [ ] Task 110.130: Add jqwik and fast-check with one example test each

#### Phase 120: Mutation Tests

- [ ] Task 120.100: Add PIT to the Maven module, with a `just` recipe that makes a report

- [ ] Task 120.110: Add Stryker to the pnpm module, with a `just` recipe that makes a report

#### Phase 130: Architecture Tools

- [ ] Task 130.100: Add Spring Modulith and ArchUnit with example rules

- [ ] Task 130.110: Add ArchUniTS, write the same rules, and write the result about its maturity in this plan

- [ ] Task 130.120: Write the test that compares the Structurizr workspace with the modules and packages

#### Phase 140: Baseline and CI

- [ ] Task 140.100: Add the tools to the CI workflow as reports without thresholds

- [ ] Task 140.110: Measure the baseline for coverage and for the mutation score, and write the values in this plan

#### Phase 150: Review

- [ ] Task 150.100: The owner examines the license table, the result for ArchUniTS and the open items

## Progress

### Current Status

**As of 2026-11-03**: The plan is written. Work has not started. This feature waits for feat-6-contracts-openapi-pipeline.

### Blockers

- feat-6-contracts-openapi-pipeline must give the modules first.

### Updates

<!-- Newest entry first -- prepend new entries directly below this comment. -->

#### 2026-11-03 00:00:00.000Z - Plan written

The plan is written from the planning session of 2026-11-03.

### Decisions Made

<!-- Newest entry first -- prepend new entries directly below this comment. -->

#### 2026-11-03 00:00:00.000Z - Own feature for verification and architecture

The tools for verification and architecture are a separate feature (issue #7), because they need the modules of the contract pipeline.

### Related PRs / Commits

- [Issue #7](https://github.com/dfch/biz.dfch.SpecMgrDemo/issues/7): this feature.

### More Information

The first design issue is GitHub issue #1.
