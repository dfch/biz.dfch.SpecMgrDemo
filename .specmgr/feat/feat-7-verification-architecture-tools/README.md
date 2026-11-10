---
classification: null
created: '2026-11-03T07:54:08.480+01:00'
id: feat-7-verification-architecture-tools
status: progress
type: feat
updated: '2026-11-10T20:30:00.000+01:00'
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

License table (the agent fills it from the license file of each tool and not from memory). All 16 rows are checked (Task 100.100, 2026-11-09; the evidence is below in the Result of the Phase 100, the row JaCoCo was checked at the time of the decision of the owner on the same day, for the new row, and the rows Vite and PostgreSQL JDBC driver were checked in the phase 110 on 2026-11-10, for the new pins of that phase):

| Tool | Use | License | Result |
|---|---|---|---|
| JUnit | unit tests | EPL-2.0 | Review (DEC 93a6d588-e002-4daf-9a47-45e2d77786e9) |
| Testcontainers | integration tests | MIT | Permitted |
| PostgreSQL JDBC driver | integration tests (the driver of the Testcontainers example; the scope test keeps it out of the SBOM) | BSD-2-Clause | Permitted |
| Vitest | unit tests | MIT | Permitted |
| Vite | build tool (the pinned peer of vitest and of the tree of Kubb; the pin keeps the tree without lightningcss — see the Result of the Phase 110) | MIT | Permitted |
| Playwright | end-to-end tests | Apache-2.0 | Permitted |
| axe-core | accessibility check | MPL-2.0 | Review (DEC 93a6d588-e002-4daf-9a47-45e2d77786e9) |
| PIT | mutation tests | Apache-2.0 | Permitted |
| Stryker | mutation tests | Apache-2.0 | Permitted |
| jqwik | random data | EPL-2.0 | Review (DEC 93a6d588-e002-4daf-9a47-45e2d77786e9) |
| fast-check | random data | MIT | Permitted |
| JaCoCo | coverage (line and branch in the Maven module; the pin is in the phase 140) | EPL-2.0 | Review (DEC 93a6d588-e002-4daf-9a47-45e2d77786e9) |
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
| PostgreSQL JDBC driver (org.postgresql:postgresql) | 42.7.14 | the `<licenses>` entry of the POM on Maven Central (repo.maven.apache.org/maven2/org/postgresql/postgresql/42.7.14/postgresql-42.7.14.pom, the entry BSD-2-Clause, the comment BSD-2-Clause, copyright PostgreSQL Global Development Group); checked in the phase 110 on 2026-11-10, for the new pin | BSD-2-Clause | Permitted |
| Vitest (npm vitest) | 5.1.0 | the registry entry registry.npmjs.org/vitest/5.1.0 (the license field MIT) and the LICENSE.md of the package tarball (the full text of the MIT license, Vitest is released under the MIT license) | MIT | Permitted |
| Vite (npm vite) | 7.3.8 | the registry entry registry.npmjs.org/vite/7.3.8 (the license field MIT) and the LICENSE.md of the package (the full text of the MIT license, copyright VoidZero Inc. and Vite contributors); checked in the phase 110 on 2026-11-10, for the new pin | MIT | Permitted |
| Playwright (npm @playwright/test) | 1.65.0 | the registry entry registry.npmjs.org/@playwright/test/1.65.0 (the license field Apache-2.0) and the LICENSE of the package tarball (the full text of the Apache License, Version 2.0) | Apache-2.0 | Permitted |
| axe-core (npm axe-core) | 4.14.0 | the registry entry registry.npmjs.org/axe-core/4.14.0 (the license field MPL-2.0) and the LICENSE of the package tarball (the full text of the Mozilla Public License, version 2.0) | MPL-2.0 | Review |
| PIT (org.pitest:pitest-maven, the plugin; the core org.pitest:pitest has the same license) | 1.30.2 | the POM on Maven Central (repo1.maven.org/maven2/org/pitest/pitest-maven/1.30.2/pitest-maven-1.30.2.pom, the entry The Apache Software License, Version 2.0) and the LICENSE.txt of github.com/hcoles/pitest at the tag 1.30.2 (the full text of the Apache License, Version 2.0) | Apache-2.0 | Permitted |
| Stryker (npm @stryker-mutator/core, the package with the stryker binary) | 10.1.1 | the registry entry registry.npmjs.org/@stryker-mutator/core/10.1.1 (the license field Apache-2.0) and the LICENSE of the package tarball (the full text of the Apache License, Version 2.0) | Apache-2.0 | Permitted |
| jqwik (net.jqwik:jqwik) | 1.10.2 | the POM on Maven Central (repo1.maven.org/maven2/net/jqwik/jqwik/1.10.2/jqwik-1.10.2.pom, the entry Eclipse Public License - v 2.0) and the LICENSE.md of github.com/jqwik-team/jqwik at the tag 1.10.2 (the full text of the Eclipse Public License - v 2.0) | EPL-2.0 | Review |
| fast-check (npm fast-check) | 4.10.2 | the registry entry registry.npmjs.org/fast-check/4.10.2 (the license field MIT) and the LICENSE of the package tarball (the full text of the MIT license) | MIT | Permitted |
| JaCoCo (org.jacoco:jacoco, the plugin org.jacoco:jacoco-maven-plugin) | 0.8.16, the latest on Maven Central at 2026-11-09 | the LICENSE.md of github.com/jacoco/jacoco (the full text of the Eclipse Public License Version 2.0); checked at the time of the decision of the owner (2026-11-09), for the new row of the license table | EPL-2.0 | Review |
| Spring Modulith (org.springframework.modulith:spring-modulith) | 2.1.2, the last general-availability release (2.2.0-RC1 is a release candidate) | the POM on Maven Central (repo1.maven.org/maven2/org/springframework/modulith/spring-modulith/2.1.2/spring-modulith-2.1.2.pom, the entry Apache License, Version 2.0) and the LICENSE of github.com/spring-projects/spring-modulith at the tag 2.1.2 (the full text of the Apache License, Version 2.0) | Apache-2.0 | Permitted |
| ArchUnit (com.tngtech.archunit:archunit and archunit-junit5) | 1.5.1 | the POM on Maven Central (repo1.maven.org/maven2/com/tngtech/archunit/archunit/1.5.1/archunit-1.5.1.pom, two entries: The Apache Software License, Version 2.0, and BSD with the url asm.ow2.io/license.html, the page that says ASM is released under the 3-Clause BSD License, for the bundled OW2 ASM) and the LICENSE of github.com/TNG/ArchUnit at the tag v1.5.1 (the full text of the Apache License, Version 2.0) | Apache-2.0, the main license; BSD-3-Clause for the bundled OW2 ASM | Permitted |
| ArchUniTS (npm archunit, the package ArchUnit TypeScript of the repository github.com/LukasNiessen/ArchUnitTS) | 2.5.4 | the registry entry registry.npmjs.org/archunit/2.5.4 (the license field MIT) and the LICENSE of the package tarball (the full text of the MIT license) | MIT | Permitted |
| Structurizr tools (the library com.structurizr:structurizr and the CLI github.com/structurizr/cli) | structurizr-java 6.2.4; structurizr-cli v2025.11.09, the last release of the repository | for the library, the POM on Maven Central (repo1.maven.org/maven2/com/structurizr/structurizr/6.2.4/structurizr-6.2.4.pom, the entry The Apache License, Version 2.0) and the LICENSE of github.com/structurizr/java at the branch master (the full text of the Apache License, Version 2.0; the repository has no tag for the 6.x line, the last tag is v5.0.3); for the CLI, the LICENSE of github.com/structurizr/cli at the tag v2025.11.09 (the full text of the Apache License, Version 2.0) | Apache-2.0, both candidates | Permitted |

The result: twelve rows are Permitted (Testcontainers, the PostgreSQL JDBC driver, Vitest, Vite, Playwright, PIT, Stryker, fast-check, Spring Modulith, ArchUnit, ArchUniTS and the Structurizr tools), four rows are Review (JUnit EPL-2.0, jqwik EPL-2.0, axe-core MPL-2.0, JaCoCo EPL-2.0), and no row is Not permitted and no row is open. A row that is Review is clear, not unclear: the license has an identifiable SPDX identifier, and the class Review of the DEC applies. A DEC of the owner about the deviation is necessary before the project uses one of the four tools of a row that is Review. The owner made that decision on 2026-11-09 ("all approved"), and the four deviations are recorded in the register DEC 93a6d588-e002-4daf-9a47-45e2d77786e9 (status accepted), so the four tools may be used. No license was not clear, so the stop rule of the task does not trigger.

Two identifications of tools that the table names in a different form:

- Stryker is the npm package @stryker-mutator/core (it provides the stryker binary). The package stryker (0.35.1, the same description) is the old line of the same project and is not checked separately.
- ArchUniTS is the npm package archunit (the description ArchUnit TypeScript, an architecture testing library for TypeScript). There is no npm package named archunits.

The row Structurizr tools: both candidates that phase 130 can pin are checked, the library structurizr-java (com.structurizr:structurizr, a test dependency of the Maven module) and the CLI structurizr-cli (a Java release of the repository github.com/structurizr/cli, not a Go release). Both are Apache-2.0, so the choice is not a license question. The recommendation for the pin of phase 130 is the structurizr-java library (the DEC of 2026-11-09 under Decisions Made): the test of REQ-004 reads the workspace of model/ in process and compares the components with the modules and the packages of the code. The pin is made in phase 130, not in this phase.

#### Result of the Phase 110 (Test Tools)

The four tasks of the phase are done (2026-11-10). Each tool operates on the example module (the generated code; the two modules have no product code), and each shows a test that is successful and a test that is not successful (ACC-002). The recipe of a tool runs the successful case (it must be green), and it runs the case that is not successful against a bad input (a broken assertion, a broken property, a page with violations) and stops for it: the tool reports the failure, and the recipe gives exit code 0. The cases that are not successful are named without the suffix that the normal run has (the class without the suffix `Test` or `IT` of the Maven module, the file with the part `broken` in the name of the pnpm module, and the folder `e2e/negative/` of Playwright), so the committed run of the tests is green, and a test that fails is never in the normal run.

The recipes (the number after the script in the `justfile` is the task of the phase):

| Recipe | Task | The script |
|---|---|---|
| `just test-unit-backend` | 110.100 | `tools/gates/test-unit-backend.sh` |
| `just test-integration-backend` | 110.100 | `tools/gates/test-integration-backend.sh` |
| `just test-unit-frontend` | 110.110 | `tools/gates/test-unit-frontend.sh` |
| `just test-e2e` | 110.120 | `tools/gates/test-e2e.sh` |
| `just test-random-backend` | 110.130 | `tools/gates/test-random-backend.sh` |
| `just test-random-frontend` | 110.130 | `tools/gates/test-random-frontend.sh` |

The pinned versions (`tools/versions.env`, tied to the manifests by `just check-pins`; the versions that the phase 100 looked at are in the evidence table above, and the difference is in the compatibility decisions below):

| Tool | Version | The manifest and the key |
|---|---|---|
| JUnit (org.junit.jupiter:junit-jupiter) | 5.14.4 | `backend/pom.xml`, `JUNIT_VERSION` |
| Testcontainers (the modules org.testcontainers:testcontainers, junit-jupiter and postgresql) | 1.21.4 | `backend/pom.xml`, `TESTCONTAINERS_VERSION` |
| The JDBC driver (org.postgresql:postgresql, BSD-2-Clause) | 42.7.14 | `backend/pom.xml`, `POSTGRESQL_VERSION` |
| jqwik (net.jqwik:jqwik) | 1.10.2 | `backend/pom.xml`, `JQWIK_VERSION` |
| maven-surefire-plugin (the test runner) | 3.6.1 | `backend/pom.xml`, `MAVEN_SUREFIRE_PLUGIN_VERSION` |
| Vitest (npm vitest) | 5.1.0 | `frontend/package.json` and `frontend/pnpm-lock.yaml`, `VITEST_VERSION` and `VITEST_INTEGRITY` |
| Playwright (npm @playwright/test) | 1.65.0 | `frontend/package.json` and `frontend/pnpm-lock.yaml`, `PLAYWRIGHT_VERSION` and `PLAYWRIGHT_INTEGRITY` |
| axe-core (npm axe-core) | 4.14.0 | `frontend/package.json` and `frontend/pnpm-lock.yaml`, `AXE_CORE_VERSION` and `AXE_CORE_INTEGRITY` |
| fast-check (npm fast-check) | 4.10.2 | `frontend/package.json` and `frontend/pnpm-lock.yaml`, `FAST_CHECK_VERSION` and `FAST_CHECK_INTEGRITY` |
| Vite (npm vite) | 7.3.8 | `frontend/package.json` and `frontend/pnpm-lock.yaml`, `VITE_VERSION` and `VITE_INTEGRITY` |

Where the tests and the fixtures live:

- The Maven module: `backend/src/test/java/biz/dfch/specmgrdemo/testtools/` (the classes `ErrorCodeTest`, `BrokenAssertion`, `PostgresIT`, `BrokenPostgres`, `ErrorCodePropertyTest` and `BrokenProperty`).
- The pnpm module: `frontend/src/test/` (the files `status-schema.test.ts`, `property.test.ts`, `broken-assertion.broken.test.ts` and `broken-property.broken.test.ts`, the configs `vitest.config.ts` and `vitest.config.negative.ts` in the folder `frontend/`), and `frontend/e2e/` (the spec `accessibility.spec.ts`, the spec of the case that is not successful `negative/no-violations.spec.ts`, the HTML fixtures `fixtures/good.html` and `fixtures/bad.html`, and the static server `fixtures/serve.mjs` that the `webServer` of the Playwright configs starts on the loopback address; no server of the recipe is necessary).

The case that is successful, and the case that is not successful, of each tool (ACC-002):

| Tool | The case that is successful | The case that is not successful (what the tool reports, and what the recipe asserts) |
|---|---|---|
| JUnit | `ErrorCodeTest`: 8 tests on the generated enum (the values of the contract, the round trip through `fromValue`, a value that is not a code) and the path of the generated interface `StatusApi` | `BrokenAssertion` (no suffix `Test`): a wrong assertion. JUnit reports `expected: <3> but was: <2>`, and the run stops (exit code not 0). The recipe asserts the text and the exit code |
| Testcontainers | `PostgresIT` (the suffix IT): one lightweight container (postgres:16-alpine, the PostgreSQL license, and not an image of the SSPL/RSAL class), a JDBC connection, a trivial query (a table, an insert, a select) | `BrokenPostgres` (no suffix IT): the container works, and the assertion against the real result is wrong. JUnit reports `expected: <2> but was: <1>`. The recipe asserts the text and the exit code |
| Vitest | `status-schema.test.ts`: 6 tests on the generated Zod schemas (a valid status, a state that is not in the list, the five error codes of the contract, a valid problem, a code that is not in the list) | `broken-assertion.broken.test.ts` (the part `broken`): a wrong assertion. Vitest reports `expected 2 to be 3`. The recipe asserts the text and the exit code |
| Playwright and axe-core | `accessibility.spec.ts`: the good page gives zero violations of axe-core (the package is used directly: the source of `axe.min.js` is read from `node_modules` and injected into the page, and `axe.run` operates), and the bad page (an image without alt, and a text with low contrast) gives the violations that axe reports (the rules `image-alt` and `color-contrast`) | `negative/no-violations.spec.ts`: the test expects no violations on the bad page. axe-core reports the violations, Playwright stops (exit code not 0), and the output names `image-alt` and `color-contrast`. The recipe asserts the text and the exit code |
| jqwik | `ErrorCodePropertyTest`: 3 properties on the generated enum (the value round trips through `fromValue`, the list has no duplicate value) and on a small function of the test (the count of the characters that are no letter is between zero and the length) | `BrokenProperty` (no suffix `Test`): a property that is wrong (the sum of two numbers is always 3). jqwik finds a counterexample (the run stops), and the output has the text of the failed property. The recipe asserts the text and the exit code |
| fast-check | `property.test.ts`: 3 properties on the generated Zod schemas (each status the generator gives parses, a state that is not up or degraded is rejected) and on a small function of the test (it keeps only the lower case letters, and it does it once) | `broken-property.broken.test.ts` (the part `broken`): a property that is wrong. fast-check finds the counterexample `[0, 0]` (the run stops), and the output names it. The recipe asserts the text and the exit code |

The compatibility decisions (the versions that operate, and the difference to the versions that the phase 100 looked at; the full entry is in the Decisions Made):

- JUnit is the 5.x line (5.14.4) and not the 6.x line (6.1.3): jqwik 1.10.2 needs the JUnit Platform 1.14.x (its engine has the dependency `junit-platform-engine` 1.14.4), and the engines of the two lines do not mix on one run of surefire. The license class of the 5.x line is the one that the phase 100 checked (EPL-2.0, the entry of the POM of 5.14.4 is Eclipse Public License v2.0), and the deviation DEC of the owner covers the tool.
- Testcontainers is the 1.21.x line (1.21.4) and not the 2.x core (2.0.5): the module `org.testcontainers:junit-jupiter` has no 2.x release (the last is 1.21.4, and it has the core 1.21.4 as a dependency), and the core 2.0.5 with the module 1.21.4 would give two cores on the class path. The license class is the one that the phase 100 checked (MIT).
- Vite is pinned (7.3.8) as a direct devDependency of the module: vitest takes vite as a dependency (the range `^6.4.0 || ^7.0.0 || ^8.0.0`), and the tree of Kubb takes it as a peer (unplugin-kubb, the range `>=3`). The resolution of pnpm without a pin gives vite 8, and the tree of vite 8 has the package lightningcss (MPL-2.0, not in `tools/license/permitted-licenses.txt`, and no DEC of the owner for it) as a dependency. The lines of vite 7 and lower have lightningcss as an optional peer that pnpm can resolve in the tree of the project (a change of the old lock file keeps that resolution; a clean lock file does not). The pin 7.3.8 and a clean lock file give a tree without lightningcss.
- The version of maven-surefire-plugin went from 3.6.0 (bound by Maven 3.10.0, the value in the plan of feat-6) to 3.6.1: the plugin is now explicit in the pom.xml with the version of `tools/versions.env`, and its license is Apache-2.0 (unchanged). No row of the license table is necessary for the build plugin.

The SBOM and the license check (`just sbom` and `just license-check` give exit code 0):

- The SBOM of the backend has 12 components before and after the phase (all Apache-2.0): the test tools are in the scope `test`, and the cyclonedx plugin (`includeTestScope`, the default false) keeps them out of the SBOM.
- The SBOM of the frontend has 102 components before (93 MIT, 3 Apache-2.0, 3 ISC, 2 BSD-3-Clause, 1 PSF-2.0), and 187 after (173 MIT, 7 Apache-2.0, 3 ISC, 3 BSD-3-Clause, 1 PSF-2.0; all in the permitted list). The lock file has 188 packages.
- The package axe-core (MPL-2.0, not in the permitted list) is not in the SBOM: `sbom.sh` removes the pinned package after cdxgen made the file (the rule X1, the script `sbom_exclude.py`; a component with another version of the package is not removed, and the license gate stops for it). The reason: rule A (the tool does not go to users), and the deviation DEC 93a6d588-e002-4daf-9a47-45e2d77786e9. cdxgen 12.9.0 has no package filter for a pnpm lock file: its option `--exclude` is a file path pattern (the control check of the phase: the pattern `pnpm-lock.yaml` excludes the lock file from the scan, and no pattern for the package name removes the package from the BOM that cdxgen makes from the lock file), so the removal is a documented step of the gate (`tools/sbom/README.md`), and not a flag of the tool.
- The JDBC driver (org.postgresql:postgresql, 42.7.14, BSD-2-Clause) is a test dependency of the module, not in the SBOM (the scope test), and its license is in the class Permitted.
- The license table of the plan has a row for each tool of the phase (REQ-005): the two new rows are Vite (MIT, Permitted, checked in the phase 110 on 2026-11-10 from the registry entry and the LICENSE.md of the package) and the PostgreSQL JDBC driver (BSD-2-Clause, Permitted, checked in the phase 110 on 2026-11-10 from the `<licenses>` entry of the POM of 42.7.14 on Maven Central). The evidence is in the table of the Result of the Phase 100.

The evidence (the runs of 2026-11-10, the exit code of each recipe is 0):

- `just test-unit-backend`: 3 ok, 0 failed (the run of part 1 has 11 tests, no failure and no error, and the two engines of the JUnit Platform; the run of part 2 stops for the assertion of `BrokenAssertion`).
- `just test-integration-backend`: 3 ok, 0 failed (one test against the container; the run of part 2 stops for the assertion of `BrokenPostgres`).
- `just test-unit-frontend`: 3 ok, 0 failed (2 test files, 9 tests; the run of part 2 stops for the assertion of `broken-assertion.broken.test.ts`).
- `just test-e2e`: 4 ok, 0 failed (the chromium browser of the pinned version is in the user cache of the home, and the install is idempotent; 2 tests pass; the run of part 2 stops for the page with violations).
- `just test-random-backend`: 3 ok, 0 failed (3 properties; the run of part 2 stops for the counterexample of `BrokenProperty`).
- `just test-random-frontend`: 3 ok, 0 failed (3 properties; the run of part 2 stops for the counterexample of `broken-property.broken.test.ts`).
- `just check-pins`: PASS (the new lines `Maven test pins:` and `Frontend pin:` have the test tools of the module, and the negative self-test cases of each pin are in `selftest.sh`).
- `just sbom` and `just license-check`: PASS, 199 components (12 of the backend, 187 of the frontend), all licenses permitted, and axe-core is not in the SBOM of the frontend.

The observation of the output of jqwik. The pinned jqwik (the jar `jqwik-engine` 1.10.2, the file of the local Maven repository) writes a line that looks like an instruction for an agent of the language model in the output of each property test (the text is in the report of each property, and it asks the agent to disregard the result of the executions of jqwik). The gate asserts the lines of the summary of surefire and of the property report (the `Tests run:` and the `tries =`), and not the line, so the run of the gate is not influenced, and the result of the test is the result that the engine gives. The owner should examine the version of jqwik: a different version, or a different tool, is a decision of the owner, and not a decision of this phase.

### Related Decisions

- DEC 361678a6-f941-473b-a058-1ba2bacf7d3d: Use a Test Pyramid and Blocking Gates for Verification
- DEC 9edc1071-4fd0-48b6-a037-1a4cb2331f73: Make Sure That the Code Obeys the Structurizr Model
- DEC 7784ddef-ee8b-4ede-8f7a-ce4e27a1cac7: Give Quality Targets as ISO 25010 Scenarios and Fitness Tests
- DEC 1a29c825-6862-4fe9-8069-6566262d5c97: Use React for the Frontend
- DEC 84c37f7d-08cb-457d-8ab3-1db37dba9bc9: Use Only Open Source Libraries That Are Compatible With AGPL-3.0-only
- DEC 93a6d588-e002-4daf-9a47-45e2d77786e9: Register of the Approved License Deviations
- RSK 025202ba-e4a7-4f6b-a65b-92f945b6f321: ArchUniTS Cannot Do Each Necessary Rule

### Task List

#### Phase 100: License Checks

- [x] Task 100.100: Read the license file of each tool in the license table, and write the result. Stop and tell the owner if a license is not clear

#### Phase 110: Test Tools

- [x] Task 110.100: Add JUnit and Testcontainers to the Maven module, with a `just` recipe

- [x] Task 110.110: Add Vitest to the pnpm module, with a `just` recipe

- [x] Task 110.120: Add Playwright and the accessibility check, with a `just` recipe

- [x] Task 110.130: Add jqwik and fast-check with one example test each, one that is successful and one that is not successful

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

**As of 2026-11-10**: Work has started. Phase 100 (License Checks) is done: the 14 rows of the license table are filled from the license file of the current stable release of each tool (the evidence is in the Design Notes, Result of the Phase 100). Twelve rows are Permitted: Testcontainers, the PostgreSQL JDBC driver, Vitest, Vite, Playwright, PIT, Stryker, fast-check, Spring Modulith, ArchUnit, ArchUniTS and the Structurizr tools. Four rows are Review: JUnit (EPL-2.0), jqwik (EPL-2.0), axe-core (MPL-2.0) and JaCoCo (EPL-2.0). The owner approved the four deviations on 2026-11-09 ("all approved"); they are recorded in the register DEC 93a6d588-e002-4daf-9a47-45e2d77786e9 (status accepted), and each of the four rows names that DEC. No row is Not permitted and no row is open. Phase 110 (Test Tools) is done: the tools are in the two modules (JUnit and Testcontainers in the Maven module; Vitest, Playwright with the accessibility check of axe-core, jqwik and fast-check in the pnpm module), with the recipes `test-unit-backend`, `test-integration-backend`, `test-unit-frontend`, `test-e2e`, `test-random-backend` and `test-random-frontend`, the pins in `tools/versions.env` (checked by `just check-pins` with the new self-test cases), and the case that is not successful of each tool in its recipe and not in the normal run (ACC-002). The result and the evidence are in the Design Notes, the Result of the Phase 110. The dependencies feat-5-foundation-monorepo-ci and feat-6-contracts-openapi-pipeline are done. Phases 120 to 150 are not started.

### Blockers

None.

### Updates

<!-- Newest entry first -- prepend new entries directly below this comment. -->

#### 2026-11-10 18:13:00.000Z - Phase 110 done: the test tools are in the two modules, with the recipes and the pins

The four tasks of the phase are done. The Maven module has JUnit (5.14.4) and Testcontainers (1.21.4, one container postgres:16-alpine), with the recipes `test-unit-backend` and `test-integration-backend`. The pnpm module has Vitest (5.1.0), Playwright (1.65.0) with the accessibility check of axe-core (4.14.0, used directly, and not a wrapper package), and fast-check (4.10.2), with the recipes `test-unit-frontend`, `test-e2e` and `test-random-frontend`. The property tests of jqwik (1.10.2) are in the recipe `test-random-backend`. Each tool shows a test that is successful and a test that is not successful (ACC-002): the case that is not successful is named without the suffix that the normal run has, and the recipe runs it and stops for it (the tool reports the failure, and the recipe gives exit code 0). The pins are in `tools/versions.env`, tied to `backend/pom.xml` and to `frontend/package.json` and `frontend/pnpm-lock.yaml` by `just check-pins` (the negative self-test cases are in `selftest.sh`). The license table has the two new rows Vite (MIT, Permitted) and PostgreSQL JDBC driver (BSD-2-Clause, Permitted), checked from the license file in the phase 110 (REQ-005). The test tools of the Maven module are in the scope test (not in the SBOM), and the package axe-core is removed from the SBOM of the frontend by the rule X1 of `sbom.sh` (the reason is in `tools/sbom/README.md`). The compatibility decisions (JUnit 5 and not 6, Testcontainers 1.21 and not 2.0.5, the pin of vite 7.3.8 against the tree of lightningcss) are in the Decisions Made. The result, the evidence and the observation of the output of jqwik are in the Design Notes, the Result of the Phase 110.

#### 2026-11-09 20:10:45.000Z - The decision of the owner about the four Review rows is recorded (register DEC 93a6d588-e002-4daf-9a47-45e2d77786e9)

The owner approved on 2026-11-09 (in the chat: "all approved") the four deviations JUnit (EPL-2.0), jqwik (EPL-2.0), axe-core (MPL-2.0) and JaCoCo (EPL-2.0). The decision is in the register DEC 93a6d588-e002-4daf-9a47-45e2d77786e9 (status accepted, one dated section per deviation). The four rows of the license table now name the DEC as their result, and the table has a new row for JaCoCo (0.8.16, checked at the time of the decision, the pin in the phase 140). The evidence for the row is in the Design Notes, the Result of the Phase 100.

#### 2026-11-09 17:18:06.000Z - Phase 100 done: the license table is filled (10 Permitted, 3 Review, 0 Not permitted)

Task 100.100 is done. The license of each of the 13 tools is read from the license file of the current stable release, and not from memory: the `<licenses>` block of the POM on Maven Central and the LICENSE file of the vendor repository at the release tag for the Maven tools, the `license` field of the registry entry and the LICENSE file of the package tarball for the npm tools. The result: ten rows are Permitted (Testcontainers MIT, Vitest MIT, Playwright Apache-2.0, PIT Apache-2.0, Stryker Apache-2.0, fast-check MIT, Spring Modulith Apache-2.0, ArchUnit Apache-2.0, ArchUniTS MIT, the Structurizr tools Apache-2.0), three rows are Review and wait for a DEC of the owner (JUnit EPL-2.0, jqwik EPL-2.0, axe-core MPL-2.0), and no row is Not permitted and no row is open. No license was not clear, so the stop rule of the task does not trigger. The per-tool evidence (version looked at, where the license was read, the license text found, the class) is in the Design Notes, subsection Result of the Phase 100. The recommendation for the pin of the Structurizr reader of phase 130 is the structurizr-java library (a DEC is added below).

#### 2026-11-09 00:00:00.000Z - Dependency released, plan refined

The dependencies feat-5-foundation-monorepo-ci and feat-6-contracts-openapi-pipeline are done. The blocker of 2026-11-03 is released. The plan is refined from the refinement report of 2026-11-09: one error, three gaps, five discrepancies and eight improvements are fixed in this document.

#### 2026-11-03 00:00:00.000Z - Plan written

The plan is written from the planning session of 2026-11-03.

### Decisions Made

<!-- Newest entry first -- prepend new entries directly below this comment. -->

#### 2026-11-10 18:13:00.000Z - The pins of the phase 110: JUnit 5 (not 6), Testcontainers 1.21 (not 2.0.5), and the pin of vite 7.3.8

The versions that operate are not always the current stable that the phase 100 looked at, and the difference is recorded here. JUnit is the 5.x line (5.14.4) and not the 6.x line (6.1.3): jqwik 1.10.2 needs the JUnit Platform 1.14.x (the engine has the dependency junit-platform-engine 1.14.4), and the engines of the two lines do not mix on one run of surefire. The license class of the 5.x line is the one that the phase 100 checked (EPL-2.0, the entry of the POM of 5.14.4 is Eclipse Public License v2.0), and the deviation DEC of the owner covers the tool. Testcontainers is the 1.21.x line (1.21.4) and not the 2.x core (2.0.5): the module org.testcontainers:junit-jupiter has no 2.x release (the last is 1.21.4, and it has the core 1.21.4 as a dependency), and the core 2.0.5 with the module 1.21.4 would give two cores on the class path. The license class is the one that the phase 100 checked (MIT). Vite is pinned (7.3.8) as a direct devDependency of the module: vitest takes vite as a dependency (the range ^6.4.0 || ^7.0.0 || ^8.0.0), and unplugin-kubb (the tree of Kubb) takes it as a peer (the range >=3). Without the pin, the resolution of pnpm gives vite 8, and the tree of vite 8 has the package lightningcss (MPL-2.0, not in the permitted list, and no DEC of the owner for it) as a dependency. The lines of vite 7 and lower have lightningcss as an optional peer that pnpm can resolve in the tree of the project (a change of the old lock file keeps that resolution, and a clean lock file does not). The pin 7.3.8 and a clean lock file (a new pnpm install, and not a change of the old lock file) give a tree without lightningcss, and the SBOM of the frontend has 187 components, all in the permitted list (the package axe-core is removed by the rule X1 of sbom.sh, see the Result of the Phase 110).

#### 2026-11-09 20:10:45.000Z - The owner approved the four deviations of the class Review: JUnit, jqwik, axe-core and JaCoCo

The owner approved on 2026-11-09 (in the chat: "all approved") the four deviations JUnit (EPL-2.0), jqwik (EPL-2.0), axe-core (MPL-2.0) and JaCoCo (EPL-2.0). They are recorded in the register DEC 93a6d588-e002-4daf-9a47-45e2d77786e9 (status accepted), with one dated section for each deviation. The owner chose axe-core (the tool the plan names in the scope) and not the alternative pa11y that was named in the question. The rows of the license table name the DEC for each of the four tools.

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
