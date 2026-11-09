---
classification: null
created: '2026-11-03T07:54:08.480+01:00'
id: feat-7-verification-architecture-tools
status: progress
type: feat
updated: '2026-11-09T18:20:26.000+01:00'
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

License table (the agent fills it from the license file of each tool and not from memory). All 13 rows are checked (Task 100.100, 2026-11-09; the evidence is below in the Result of the Phase 100):

| Tool | Use | License | Result |
|---|---|---|---|
| JUnit | unit tests | EPL-2.0 | Review |
| Testcontainers | integration tests | MIT | Permitted |
| Vitest | unit tests | MIT | Permitted |
| Playwright | end-to-end tests | Apache-2.0 | Permitted |
| axe-core | accessibility check | MPL-2.0 | Review |
| PIT | mutation tests | Apache-2.0 | Permitted |
| Stryker | mutation tests | Apache-2.0 | Permitted |
| jqwik | random data | EPL-2.0 | Review |
| fast-check | random data | MIT | Permitted |
| Spring Modulith | architecture | Apache-2.0 | Permitted |
| ArchUnit | architecture | Apache-2.0 (main) and BSD-3-Clause (bundled OW2 ASM) | Permitted |
| ArchUniTS | architecture | MIT | Permitted |
| Structurizr tools | model | Apache-2.0 (structurizr-java and structurizr-cli) | Permitted |

#### Result of the Phase 100 (License Checks)

The check of Task 100.100 (2026-11-09) reads the license file of the current stable release of each tool, and not from memory. For the Maven tools, the `<licenses>` block of the POM on Maven Central and the LICENSE file of the vendor repository at the release tag. For the npm tools, the `license` field of the registry entry at registry.npmjs.org and the LICENSE file of the package tarball of the same version. The two sources agree for each tool. The class is the class of DEC 84c37f7d-08cb-457d-8ab3-1db37dba9bc9. These tools do not go to users, so rule A of the DEC applies: only the main license of the tool is classified, and the parts that a tool bundles are not checked.

| Tool | Version looked at | Where the license was read | License found | Class |
|---|---|---|---|---|
| JUnit (org.junit.jupiter:junit-jupiter) | 6.1.3 | the POM on Maven Central (repo1.maven.org/maven2/org/junit/jupiter/junit-jupiter/6.1.3/junit-jupiter-6.1.3.pom, the entry Eclipse Public License v2.0) and the LICENSE.md of github.com/junit-team/junit-framework at the tag r6.1.3 (the full text of the Eclipse Public License - v 2.0) | EPL-2.0 | Review |
| Testcontainers (org.testcontainers:testcontainers; the module org.testcontainers:junit-jupiter is 1.21.4 with the same license) | 2.0.5 | the POM on Maven Central (repo1.maven.org/maven2/org/testcontainers/testcontainers/2.0.5/testcontainers-2.0.5.pom, the entry MIT) and the LICENSE of github.com/testcontainers/testcontainers-java at the tag 2.0.5 (the full text of the MIT license) | MIT | Permitted |
| Vitest (npm vitest) | 5.1.0 | the registry entry registry.npmjs.org/vitest/5.1.0 (the license field MIT) and the LICENSE.md of the package tarball (the full text of the MIT license, Vitest is released under the MIT license) | MIT | Permitted |
| Playwright (npm @playwright/test) | 1.65.0 | the registry entry registry.npmjs.org/@playwright/test/1.65.0 (the license field Apache-2.0) and the LICENSE of the package tarball (the full text of the Apache License, Version 2.0) | Apache-2.0 | Permitted |
| axe-core (npm axe-core) | 4.14.0 | the registry entry registry.npmjs.org/axe-core/4.14.0 (the license field MPL-2.0) and the LICENSE of the package tarball (the full text of the Mozilla Public License, version 2.0) | MPL-2.0 | Review |
| PIT (org.pitest:pitest-maven, the plugin; the core org.pitest:pitest has the same license) | 1.30.2 | the POM on Maven Central (repo1.maven.org/maven2/org/pitest/pitest-maven/1.30.2/pitest-maven-1.30.2.pom, the entry The Apache Software License, Version 2.0) and the LICENSE.txt of github.com/hcoles/pitest at the tag 1.30.2 (the full text of the Apache License, Version 2.0) | Apache-2.0 | Permitted |
| Stryker (npm @stryker-mutator/core, the package with the stryker binary) | 10.1.1 | the registry entry registry.npmjs.org/@stryker-mutator/core/10.1.1 (the license field Apache-2.0) and the LICENSE of the package tarball (the full text of the Apache License, Version 2.0) | Apache-2.0 | Permitted |
| jqwik (net.jqwik:jqwik) | 1.10.2 | the POM on Maven Central (repo1.maven.org/maven2/net/jqwik/jqwik/1.10.2/jqwik-1.10.2.pom, the entry Eclipse Public License - v 2.0) and the LICENSE.md of github.com/jqwik-team/jqwik at the tag 1.10.2 (the full text of the Eclipse Public License - v 2.0) | EPL-2.0 | Review |
| fast-check (npm fast-check) | 4.10.2 | the registry entry registry.npmjs.org/fast-check/4.10.2 (the license field MIT) and the LICENSE of the package tarball (the full text of the MIT license) | MIT | Permitted |
| Spring Modulith (org.springframework.modulith:spring-modulith) | 2.1.2, the last general-availability release (2.2.0-RC1 is a release candidate) | the POM on Maven Central (repo1.maven.org/maven2/org/springframework/modulith/spring-modulith/2.1.2/spring-modulith-2.1.2.pom, the entry Apache License, Version 2.0) and the LICENSE of github.com/spring-projects/spring-modulith at the tag 2.1.2 (the full text of the Apache License, Version 2.0) | Apache-2.0 | Permitted |
| ArchUnit (com.tngtech.archunit:archunit and archunit-junit5) | 1.5.1 | the POM on Maven Central (repo1.maven.org/maven2/com/tngtech/archunit/archunit/1.5.1/archunit-1.5.1.pom, two entries: The Apache Software License, Version 2.0, and BSD with the url asm.ow2.io/license.html, the page that says ASM is released under the 3-Clause BSD License, for the bundled OW2 ASM) and the LICENSE of github.com/TNG/ArchUnit at the tag v1.5.1 (the full text of the Apache License, Version 2.0) | Apache-2.0, the main license; BSD-3-Clause for the bundled OW2 ASM | Permitted |
| ArchUniTS (npm archunit, the package ArchUnit TypeScript of the repository github.com/LukasNiessen/ArchUnitTS) | 2.5.4 | the registry entry registry.npmjs.org/archunit/2.5.4 (the license field MIT) and the LICENSE of the package tarball (the full text of the MIT license) | MIT | Permitted |
| Structurizr tools (the library com.structurizr:structurizr and the CLI github.com/structurizr/cli) | structurizr-java 6.2.4; structurizr-cli v2025.11.09, the last release of the repository | for the library, the POM on Maven Central (repo1.maven.org/maven2/com/structurizr/structurizr/6.2.4/structurizr-6.2.4.pom, the entry The Apache License, Version 2.0) and the LICENSE of github.com/structurizr/java at the branch master (the full text of the Apache License, Version 2.0; the repository has no tag for the 6.x line, the last tag is v5.0.3); for the CLI, the LICENSE of github.com/structurizr/cli at the tag v2025.11.09 (the full text of the Apache License, Version 2.0) | Apache-2.0, both candidates | Permitted |

The result: ten rows are Permitted, three rows are Review (JUnit EPL-2.0, jqwik EPL-2.0, axe-core MPL-2.0), and no row is Not permitted and no row is open. A row that is Review is clear, not unclear: the license has an identifiable SPDX identifier, and the class Review of the DEC applies. A DEC of the owner about the deviation is necessary before the project uses one of the three tools. No license was not clear, so the stop rule of the task does not trigger.

Two identifications of tools that the table names in a different form:

- Stryker is the npm package @stryker-mutator/core (it provides the stryker binary). The package stryker (0.35.1, the same description) is the old line of the same project and is not checked separately.
- ArchUniTS is the npm package archunit (the description ArchUnit TypeScript, an architecture testing library for TypeScript). There is no npm package named archunits.

The row Structurizr tools: both candidates that phase 130 can pin are checked, the library structurizr-java (com.structurizr:structurizr, a test dependency of the Maven module) and the CLI structurizr-cli (a Java release of the repository github.com/structurizr/cli, not a Go release). Both are Apache-2.0, so the choice is not a license question. The recommendation for the pin of phase 130 is the structurizr-java library (the DEC of 2026-11-09 under Decisions Made): the test of REQ-004 reads the workspace of model/ in process and compares the components with the modules and the packages of the code. The pin is made in phase 130, not in this phase.

### Related Decisions

- DEC 361678a6-f941-473b-a058-1ba2bacf7d3d: Use a Test Pyramid and Blocking Gates for Verification
- DEC 9edc1071-4fd0-48b6-a037-1a4cb2331f73: Make Sure That the Code Obeys the Structurizr Model
- DEC 7784ddef-ee8b-4ede-8f7a-ce4e27a1cac7: Give Quality Targets as ISO 25010 Scenarios and Fitness Tests
- DEC 1a29c825-6862-4fe9-8069-6566262d5c97: Use React for the Frontend
- DEC 84c37f7d-08cb-457d-8ab3-1db37dba9bc9: Use Only Open Source Libraries That Are Compatible With AGPL-3.0-only
- RSK 025202ba-e4a7-4f6b-a65b-92f945b6f321: ArchUniTS Cannot Do Each Necessary Rule

### Task List

#### Phase 100: License Checks

- [x] Task 100.100: Read the license file of each tool in the license table, and write the result. Stop and tell the owner if a license is not clear

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

**As of 2026-11-09**: Work has started. Phase 100 (License Checks) is done: the 13 rows of the license table are filled from the license file of the current stable release of each tool (the evidence is in the Design Notes, Result of the Phase 100). Ten rows are Permitted: Testcontainers, Vitest, Playwright, PIT, Stryker, fast-check, Spring Modulith, ArchUnit, ArchUniTS and the Structurizr tools. Three rows are Review and wait for a DEC of the owner: JUnit (EPL-2.0), jqwik (EPL-2.0) and axe-core (MPL-2.0). No row is Not permitted and no row is open. The dependencies feat-5-foundation-monorepo-ci and feat-6-contracts-openapi-pipeline are done. Phases 110 to 150 are not started.

### Blockers

None.

### Updates

<!-- Newest entry first -- prepend new entries directly below this comment. -->

#### 2026-11-09 17:18:06.000Z - Phase 100 done: the license table is filled (10 Permitted, 3 Review, 0 Not permitted)

Task 100.100 is done. The license of each of the 13 tools is read from the license file of the current stable release, and not from memory: the `<licenses>` block of the POM on Maven Central and the LICENSE file of the vendor repository at the release tag for the Maven tools, the `license` field of the registry entry and the LICENSE file of the package tarball for the npm tools. The result: ten rows are Permitted (Testcontainers MIT, Vitest MIT, Playwright Apache-2.0, PIT Apache-2.0, Stryker Apache-2.0, fast-check MIT, Spring Modulith Apache-2.0, ArchUnit Apache-2.0, ArchUniTS MIT, the Structurizr tools Apache-2.0), three rows are Review and wait for a DEC of the owner (JUnit EPL-2.0, jqwik EPL-2.0, axe-core MPL-2.0), and no row is Not permitted and no row is open. No license was not clear, so the stop rule of the task does not trigger. The per-tool evidence (version looked at, where the license was read, the license text found, the class) is in the Design Notes, subsection Result of the Phase 100. The recommendation for the pin of the Structurizr reader of phase 130 is the structurizr-java library (a DEC is added below).

#### 2026-11-09 00:00:00.000Z - Dependency released, plan refined

The dependencies feat-5-foundation-monorepo-ci and feat-6-contracts-openapi-pipeline are done. The blocker of 2026-11-03 is released. The plan is refined from the refinement report of 2026-11-09: one error, three gaps, five discrepancies and eight improvements are fixed in this document.

#### 2026-11-03 00:00:00.000Z - Plan written

The plan is written from the planning session of 2026-11-03.

### Decisions Made

<!-- Newest entry first -- prepend new entries directly below this comment. -->

#### 2026-11-09 17:18:06.000Z - The Structurizr reader of phase 130 is the structurizr-java library

Both candidates of the row Structurizr tools are Apache-2.0 (Permitted): the library structurizr-java (com.structurizr:structurizr, 6.2.4 on Maven Central) and the CLI structurizr-cli (github.com/structurizr/cli, the Java release v2025.11.09; the repository is Java, not Go). The reader that phase 130 pins is the structurizr-java library, as a test dependency of the Maven module. The test of REQ-004 reads the workspace of model/ in process: the library parses the DSL or the JSON file into a Workspace object, and the test compares the components and the dependencies of the workspace with the modules and the packages of the code. The CLI is not the natural fit: its last release is a single 98 MB zip with no published checksum file, and its inspect command needs a custom inspector jar in a plugins folder next to the workspace. This is a recommendation for phase 130, which makes the pin; no pin is made in this phase.

#### 2026-11-09 00:00:00.000Z - The test for the node without Handle belongs to the walking skeleton

The DEC 1a29c825-6862-4fe9-8069-6566262d5c97 names a test that must examine a custom node that has no `Handle` elements. This feature does not take the test. It belongs to the feature for the walking skeleton (not yet created), because that feature owns the code of the React frontend. The pnpm module has no product code, and the license table has no row for React or for the graph library.

#### 2026-11-03 00:00:00.000Z - Own feature for verification and architecture

The tools for verification and architecture are a separate feature (issue #7), because they need the modules of the contract pipeline.

### Related PRs / Commits

- [Issue #7](https://github.com/dfch/biz.dfch.SpecMgrDemo/issues/7): this feature.

### More Information

The first design issue is GitHub issue #1.
