---
classification: null
created: '2026-11-03T07:54:08.480+01:00'
id: feat-7-verification-architecture-tools
status: progress
type: feat
updated: '2026-11-11T16:20:00.000+01:00'
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

License table (the agent fills it from the license file of each tool and not from memory). All 18 rows are checked (Task 100.100, 2026-11-09; the evidence is below in the Result of the Phase 100, the row JaCoCo was checked at the time of the decision of the owner on the same day, for the new row, the rows Vite and PostgreSQL JDBC driver were checked in the phase 110 on 2026-11-10, for the new pins of that phase, and the rows PIT JUnit5 plugin and Stryker vitest runner were checked in the phase 120 on 2026-11-11, for the new pins of that phase):

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
| PIT JUnit5 plugin | mutation tests (the JUnit5 support of PIT, a plugin dependency of pitest-maven in the Maven module) | Apache-2.0 | Permitted |
| Stryker | mutation tests | Apache-2.0 | Permitted |
| Stryker vitest runner | mutation tests (the plugin of Stryker that runs Vitest as the test runner, in the pnpm module) | Apache-2.0 | Permitted |
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
| PIT JUnit5 plugin (org.pitest:pitest-junit5-plugin, the JUnit5 support of PIT as a plugin dependency of pitest-maven) | 1.2.3 | the POM on Maven Central (repo.maven.apache.org/maven2/org/pitest/pitest-junit5-plugin/1.2.3/pitest-junit5-plugin-1.2.3.pom, the entry The Apache Software License, Version 2.0) and the LICENSE.txt of github.com/pitest/pitest-junit5-plugin at the tag 1.2.3 (the full text of the Apache License, Version 2.0); checked in the phase 120 on 2026-11-11, for the new pin | Apache-2.0 | Permitted |
| Stryker (npm @stryker-mutator/core, the package with the stryker binary) | 10.1.1 | the registry entry registry.npmjs.org/@stryker-mutator/core/10.1.1 (the license field Apache-2.0) and the LICENSE of the package tarball (the full text of the Apache License, Version 2.0) | Apache-2.0 | Permitted |
| Stryker vitest runner (npm @stryker-mutator/vitest-runner, the plugin that runs Vitest as the test runner of Stryker) | 10.1.1 | the registry entry registry.npmjs.org/@stryker-mutator/vitest-runner/10.1.1 (the license field Apache-2.0) and the LICENSE of the package tarball (the full text of the Apache License, Version 2.0); checked in the phase 120 on 2026-11-11, for the new pin | Apache-2.0 | Permitted |
| jqwik (net.jqwik:jqwik) | 1.10.2 | the POM on Maven Central (repo1.maven.org/maven2/net/jqwik/jqwik/1.10.2/jqwik-1.10.2.pom, the entry Eclipse Public License - v 2.0) and the LICENSE.md of github.com/jqwik-team/jqwik at the tag 1.10.2 (the full text of the Eclipse Public License - v 2.0) | EPL-2.0 | Review |
| fast-check (npm fast-check) | 4.10.2 | the registry entry registry.npmjs.org/fast-check/4.10.2 (the license field MIT) and the LICENSE of the package tarball (the full text of the MIT license) | MIT | Permitted |
| JaCoCo (org.jacoco:jacoco, the plugin org.jacoco:jacoco-maven-plugin) | 0.8.16, the latest on Maven Central at 2026-11-09 | the LICENSE.md of github.com/jacoco/jacoco (the full text of the Eclipse Public License Version 2.0); checked at the time of the decision of the owner (2026-11-09), for the new row of the license table | EPL-2.0 | Review |
| Spring Modulith (org.springframework.modulith:spring-modulith) | 2.1.2, the last general-availability release (2.2.0-RC1 is a release candidate) | the POM on Maven Central (repo1.maven.org/maven2/org/springframework/modulith/spring-modulith/2.1.2/spring-modulith-2.1.2.pom, the entry Apache License, Version 2.0) and the LICENSE of github.com/spring-projects/spring-modulith at the tag 2.1.2 (the full text of the Apache License, Version 2.0) | Apache-2.0 | Permitted |
| ArchUnit (com.tngtech.archunit:archunit and archunit-junit5) | 1.5.1 | the POM on Maven Central (repo1.maven.org/maven2/com/tngtech/archunit/archunit/1.5.1/archunit-1.5.1.pom, two entries: The Apache Software License, Version 2.0, and BSD with the url asm.ow2.io/license.html, the page that says ASM is released under the 3-Clause BSD License, for the bundled OW2 ASM) and the LICENSE of github.com/TNG/ArchUnit at the tag v1.5.1 (the full text of the Apache License, Version 2.0) | Apache-2.0, the main license; BSD-3-Clause for the bundled OW2 ASM | Permitted |
| ArchUniTS (npm archunit, the package ArchUnit TypeScript of the repository github.com/LukasNiessen/ArchUnitTS) | 2.5.4 | the registry entry registry.npmjs.org/archunit/2.5.4 (the license field MIT) and the LICENSE of the package tarball (the full text of the MIT license) | MIT | Permitted |
| Structurizr tools (the library com.structurizr:structurizr and the CLI github.com/structurizr/cli) | structurizr-java 6.2.4; structurizr-cli v2025.11.09, the last release of the repository | for the library, the POM on Maven Central (repo1.maven.org/maven2/com/structurizr/structurizr/6.2.4/structurizr-6.2.4.pom, the entry The Apache License, Version 2.0) and the LICENSE of github.com/structurizr/java at the branch master (the full text of the Apache License, Version 2.0; the repository has no tag for the 6.x line, the last tag is v5.0.3); for the CLI, the LICENSE of github.com/structurizr/cli at the tag v2025.11.09 (the full text of the Apache License, Version 2.0) | Apache-2.0, both candidates | Permitted |

The result: fourteen rows are Permitted (Testcontainers, the PostgreSQL JDBC driver, Vitest, Vite, Playwright, PIT, the PIT JUnit5 plugin, Stryker, the Stryker vitest runner, fast-check, Spring Modulith, ArchUnit, ArchUniTS and the Structurizr tools), four rows are Review (JUnit EPL-2.0, jqwik EPL-2.0, axe-core MPL-2.0, JaCoCo EPL-2.0), and no row is Not permitted and no row is open. A row that is Review is clear, not unclear: the license has an identifiable SPDX identifier, and the class Review of the DEC applies. A DEC of the owner about the deviation is necessary before the project uses one of the four tools of a row that is Review. The owner made that decision on 2026-11-09 ("all approved"), and the four deviations are recorded in the register DEC 93a6d588-e002-4daf-9a47-45e2d77786e9 (status accepted), so the four tools may be used. No license was not clear, so the stop rule of the task does not trigger.

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

#### Result of the Phase 120 (Mutation Tests)

Both tasks are done. Task 120.100 (PIT) is done (2026-11-10). Task 120.110 (Stryker) is done (2026-11-11): the recipe operates and makes the report, and the stop of the license gate for the transitive package of the tree of Stryker (caniuse-lite, CC-BY-4.0, no class in the DEC 84c37f7d-08cb-457d-8ab3-1db37dba9bc9 and not in `tools/license/permitted-licenses.txt`) is resolved by the decision (b) of the owner of 2026-11-11 (the deviation for caniuse-lite in the register DEC 93a6d588-e002-4daf-9a47-45e2d77786e9, and the exclusion of the pinned package from the SBOM by the rule X1, generalized for the two packages; the stop and the resolution are below).

The recipes (the number after the script in the `justfile` is the task of the phase):

| Recipe | Task | The script |
|---|---|---|
| `just mutation-backend` | 120.100 | `tools/gates/mutation-backend.sh` |
| `just mutation-frontend` | 120.110 | `tools/gates/mutation-frontend.sh` |

The pinned versions (`tools/versions.env`, tied to the manifests by `just check-pins`; the negative self-test cases of each pin are in `selftest.sh`, 32 new cases):

| Tool | Version | The manifest and the key |
|---|---|---|
| PIT (org.pitest:pitest-maven, the build plugin) | 1.30.2 | `backend/pom.xml`, `PIT_VERSION` |
| PIT JUnit5 plugin (org.pitest:pitest-junit5-plugin, a dependency of the plugin) | 1.2.3 | `backend/pom.xml`, `PIT_JUNIT5_PLUGIN_VERSION` |
| Stryker (npm @stryker-mutator/core) | 10.1.1 | `frontend/package.json` and `frontend/pnpm-lock.yaml`, `STRYKER_VERSION` and `STRYKER_INTEGRITY` |
| Stryker vitest runner (npm @stryker-mutator/vitest-runner) | 10.1.1 | `frontend/package.json` and `frontend/pnpm-lock.yaml`, `STRYKER_VITEST_RUNNER_VERSION` and `STRYKER_VITEST_RUNNER_INTEGRITY` |

The mutation of PIT (Task 120.100):

- The exact command: in `backend/`, `./mvnw --batch-mode --no-transfer-progress test-compile org.pitest:pitest-maven:1.30.2:mutationCoverage -Dcodegen.skip=true` (one run: the phase test-compile compiles the module, and the goal runs the mutation).
- The JUnit5 support of PIT is the plugin dependency `org.pitest:pitest-junit5-plugin` (1.2.3) in `backend/pom.xml`: pitest-maven loads the test framework plugins from its own classpath, and not from the test classpath of the module. The two engines of the JUnit Platform (the JUnit engine and the jqwik engine) are found and run (the run names them).
- The run needs the phase in front of the goal: the generator execution of the phase generate-sources adds `src/generated/java` as a compile source root, and the goal skips a project with no compile source root (the message "Project has either no tests or no production code").
- The scope (in the configuration of the plugin in `backend/pom.xml`): `targetClasses` is `biz.dfch.specmgrdemo.model.*` (the generated model code; the package `biz.dfch.specmgrdemo.api` has only the interface StatusApi, and an interface has no bytecode with logic), and `targetTests` are the two unit test classes of the generated code (ErrorCodeTest and ErrorCodePropertyTest; the class that is not successful and the integration test, that needs the Docker daemon, are no target tests). The run is small (52 mutants, about 5 seconds, see below), and it stays small for the CI of the phase 140.
- The report: `backend/target/pit-reports/` (the folder is not in git, through `target/` of `.gitignore`). The formats are HTML (index.html) and XML (mutations.xml), the parameter `outputFormats` of the plugin (the JSON format of a later line of PIT is not in 1.30.2, the formats of 1.30.2 are HTML, XML, CSV and the progress listener).
- Part 1 of the recipe runs the mutation, and asserts: the exit code 0, the two report files, the text "Mutating from" of the run (the run is not skipped), and the summary line `>> Generated 52 mutations Killed 3 (6%)`.
- Part 2 of the recipe asserts the finding (ACC-002): at least one mutant with the status SURVIVED in the XML report (the deterministic source: the attribute `status` of each element `<mutation>` of `target/pit-reports/mutations.xml`). The deterministic surviving mutant: the method `toString()` of the generated enum ErrorCode (line 47), the mutator EmptyObjectReturnValsMutator ("replaced return value with \"\" for biz/dfch/specmgrdemo/model/ErrorCode::toString"): the target tests never assert the return value of `toString()`, so the mutant survives in each run. The run is deterministic for the pinned code and the pinned tests: three runs of the recipe and two runs of the goal give the same 52 mutants with the same statuses (3 KILLED, 48 NO_COVERAGE, 1 SURVIVED).
- The runtime: about 5.5 seconds for the recipe (warm, the machine of the author with 120 cores; the mutation analysis itself is under 1 second), and 16 seconds for the first run (the download of the plugin and its dependencies). The test strength of the run is 75%, and the line coverage of the mutated classes is 15/124 (12%): the values for the baseline of the phase 140 (ACC-004).

The mutation of Stryker (Task 120.110):

- The exact command: in `frontend/`, `pnpm exec stryker run` (the config `frontend/stryker.config.json`, read by the tool; the module is installed first by the recipe with the frozen install of `install_frontend`).
- The version combination: `@stryker-mutator/core` 10.1.1 (the package with the stryker binary, the line that the phase 100 checked) and `@stryker-mutator/vitest-runner` 10.1.1 (the plugin that runs Vitest as the test runner; the name `@stryker-mutator/vitest` of the task does not exist in the registry, the package is `@stryker-mutator/vitest-runner`). The peer of the plugin is `vitest >=2.0.0`, and it operates with the pinned Vitest 5.1.0 (the plugin loads the Vitest of the project, not its own).
- The config (`frontend/stryker.config.json`): `testRunner` is `vitest` (the name of the plugin), `vitest.configFile` is `vitest.config.ts` (the config of the normal run: it includes the weak test of the example, and it excludes the files with the part `broken`), `mutate` is `src/mutation-example.ts` and `src/generated/zod/**/*.ts`, the reporters are clear-text, html and json, the reports are in `frontend/mutation-report/` (mutation.html and mutation.json; the folder and the temp folder `.stryker-tmp` are in `.gitignore`), and `concurrency` is 4 (a fixed number of workers, for the machine of the author with many cores and for the runner of CI with two cores).
- The explicit `plugins` entry (`["@stryker-mutator/vitest-runner"]`) is necessary: the automatic discovery of Stryker globs `@stryker-mutator/*` from the real path of the package core, and with pnpm that path is in the store `.pnpm/`, where only the own dependencies of core are (api, util, instrumenter). With the explicit entry, the plugin is imported by name from the `node_modules` of the project.
- The example for the mutation tests (constraint of the task): `frontend/src/mutation-example.ts` (not a test file, and marked as the example for the mutation tests, not product code; the module has no product code) has two small pure functions (`countLetters` and `stateLabel`), and `frontend/src/test/mutation-example.test.ts` exercises them weakly on purpose (one input for `countLetters`, one state for `stateLabel`), so that at least one mutant of the example survives. The weak test is green, and it runs in the normal run (`just test-unit-frontend` has now 3 test files and 11 tests, no failure).
- The exit code of the run is 0 also with surviving mutants: the config has no breaking threshold (the default of `thresholds.break` is null, and the plan does not set a threshold: the tool operates as a report, the DEC about verification).
- Part 1 of the recipe runs Stryker, and asserts: the exit code 0, the two report files, the text "Instrumented" and "Done in" of the run, and the summary line of the mutation score (`All files | 49.12 | 57.14 | 28 | 0 | 21 | 8 | 0`).
- Part 2 of the recipe asserts the finding (ACC-002): at least one mutant with the status Survived in the JSON report (the deterministic source: the field `status` of each entry of `files` of `frontend/mutation-report/mutation.json`, the value `"Survived"`). The run has 21 surviving mutants, also the deterministic ones of the example (the mutator ConditionalExpression of line 17 and line 29 of `src/mutation-example.ts`, the mutator StringLiteral of line 17, and the mutator EqualityOperator of line 17, each with its replacement in the output of the recipe). The run is deterministic for the pinned code and the pinned tests: five runs of Stryker and three runs of the recipe give the same 57 mutants with the same statuses (28 Killed, 21 Survived, 8 NoCoverage).
- The runtime: about 4.5 seconds for the recipe (warm, including the frozen install), the mutation analysis itself is 3 seconds ("Done in 3 seconds"). The values for the baseline of the phase 140 (ACC-004): 57 mutants, 28 killed, 21 survived, 8 with no coverage, the mutation score 49.12% (57.14% of the covered mutants).
- The SBOM: the tree of Stryker enters the SBOM of the frontend as devDependencies (cdxgen includes them). The SBOM has 340 components of the frontend after the phase (187 before; the two pinned packages axe-core and caniuse-lite are excluded by the rule X1), and 352 in total (12 of the backend). `just sbom` and `just license-check` give exit code 0 (the license check passes for all 352 components, the evidence is below).

The stop of the license gate, and the resolution (the decision of the owner of 2026-11-11):

- The component: caniuse-lite 1.0.30001823, the license CC-BY-4.0 (the field `license` of the registry entry registry.npmjs.org/caniuse-lite/1.0.30001823, and the LICENSE of the package tarball: the full text of the Creative Commons Attribution 4.0 International license).
- The chain in `frontend/pnpm-lock.yaml`: @stryker-mutator/core 10.1.1 -> @stryker-mutator/instrumenter 10.1.1 (a dependency of core, it instruments the code for the mutation) -> @babel/core 8.0.10 -> @babel/helper-compilation-targets 8.0.7 -> browserslist 4.29.5 -> caniuse-lite 1.0.30001823. The chain is necessary for the operation of Stryker (the instrumenter of Stryker has Babel in each released line, and Babel has browserslist for the targets of the compilation).
- The class: CC-BY-4.0 is not in `tools/license/permitted-licenses.txt`, and it has no row in the class table of the DEC 84c37f7d-08cb-457d-8ab3-1db37dba9bc9 (Permitted, Review and Not permitted). The gate stops fail closed (the Consequences of the DEC: "If the gate finds a license that it does not know, it stops the pull request"), and the work stops for the decision of the owner (REQ-005 and the constraint of the task). The license is identifiable (the SPDX identifier CC-BY-4.0), but the class is not made: the DEC says that a person with competence in the law must help for the entries of the class table.
- The stop, at 2026-11-10: `just sbom` gives exit code 0, and `just license-check` stops (exit code 1, the message `STOP caniuse-lite@1.0.30001823: NOT PERMITTED (CC-BY-4.0)`, the result `NOT PERMITTED: 1. NOT KNOWN: 0`). Per the constraint of the task, the work stops, and no exclusion and no workaround are made (the rule X1 is not touched). The options are (a) a class for CC-BY-4.0 in the DEC and in the list of permitted licenses (with the review of the law), (b) a DEC of the deviation for the package caniuse-lite, with the exclusion of the SBOM as the rule X1 of axe-core (the tool does not go to users, rule A), or (c) a decision about the tool of the mutation of the pnpm module (the line Stryker is not possible without the package).
- The resolution, at 2026-11-11: the owner chooses the option (b) (the chat: "(b)" and "go ahead"). The deviation is in the register DEC 93a6d588-e002-4daf-9a47-45e2d77786e9 (the dated section caniuse-lite, the file is not changed by this feature). The pin `CANIUSE_LITE_VERSION=1.0.30001823` is in `tools/versions.env`, and `just check-pins` ties the lock file of `frontend/` to the pin (the check `Caniuse-lite pin`, fail closed: a key that is missing, a lock file with no entry of the package, or an entry with another version stops the check). The rule X1 of `sbom.sh` is generalized: after cdxgen made the frontend SBOM, `sbom_exclude.py` removes the two pinned packages (axe-core @ `AXE_CORE_VERSION` and caniuse-lite @ `CANIUSE_LITE_VERSION`), one version per package, and a component with another version is not removed and the license gate stops for it (fail closed). After the change, `just sbom` gives exit code 0 (the two removals are logged: `removed 1 component(s) axe-core@4.14.0` and `removed 1 component(s) caniuse-lite@1.0.30001823`), and `just license-check` gives exit code 0 (`RESULT: PASS. 352 component(s), all licenses permitted`, 12 of the backend and 340 of the frontend).
- The two rows new of the license table (the PIT JUnit5 plugin and the Stryker vitest runner) are checked and Permitted (Apache-2.0), and they are not part of the stop. A row of the license table is not necessary for the transitive package caniuse-lite: the table names the tools of the feature, and the package is named in the register of the deviations.

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

- [x] Task 120.100: Add PIT to the Maven module, with a `just` recipe that makes a report

- [x] Task 120.110: Add Stryker to the pnpm module, with a `just` recipe that makes a report

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

**As of 2026-11-11**: Work has started. Phase 100 (License Checks) is done: the 18 rows of the license table are filled from the license file of the current stable release of each tool (the evidence is in the Design Notes, Result of the Phase 100). Fourteen rows are Permitted: Testcontainers, the PostgreSQL JDBC driver, Vitest, Vite, Playwright, PIT, the PIT JUnit5 plugin, Stryker, the Stryker vitest runner, fast-check, Spring Modulith, ArchUnit, ArchUniTS and the Structurizr tools. Four rows are Review: JUnit (EPL-2.0), jqwik (EPL-2.0), axe-core (MPL-2.0) and JaCoCo (EPL-2.0). The owner approved the four deviations on 2026-11-09 ("all approved"); they are recorded in the register DEC 93a6d588-e002-4daf-9a47-45e2d77786e9 (status accepted), and each of the four rows names that DEC. No row is Not permitted and no row is open. Phase 110 (Test Tools) is done: the tools are in the two modules (JUnit and Testcontainers in the Maven module; Vitest, Playwright with the accessibility check of axe-core, jqwik and fast-check in the pnpm module), with the recipes `test-unit-backend`, `test-integration-backend`, `test-unit-frontend`, `test-e2e`, `test-random-backend` and `test-random-frontend`, the pins in `tools/versions.env` (checked by `just check-pins` with the new self-test cases), and the case that is not successful of each tool in its recipe and not in the normal run (ACC-002). The result and the evidence are in the Design Notes, the Result of the Phase 110. Phase 120 (Mutation Tests) is done (2026-11-10 to 2026-11-11): the Maven module has PIT (the plugin pitest-maven 1.30.2 and the JUnit5 support pitest-junit5-plugin 1.2.3), and the pnpm module has Stryker (@stryker-mutator/core 10.1.1 and the plugin @stryker-mutator/vitest-runner 10.1.1), with the recipes `mutation-backend` (the report in `backend/target/pit-reports`, the surviving mutant asserted from the XML report) and `mutation-frontend` (the report in `frontend/mutation-report`, the 21 surviving mutants asserted from the JSON report), the pins in `tools/versions.env` (checked by `just check-pins` with the new self-test cases), and each recipe deterministic for the pinned code and tests. The stop of the SBOM gate for the transitive package caniuse-lite (CC-BY-4.0, the chain of Stryker through Babel and browserslist; no class in the DEC 84c37f7d-08cb-457d-8ab3-1db37dba9bc9) is resolved by the decision (b) of the owner of 2026-11-11: the deviation is in the register DEC 93a6d588-e002-4daf-9a47-45e2d77786e9, and the package is kept out of the SBOM of the frontend by the rule X1 (generalized for the two pinned packages, the pin `CANIUSE_LITE_VERSION` tied to the lock file, fail closed). The result, the evidence and the resolution are in the Design Notes, the Result of the Phase 120. The dependencies feat-5-foundation-monorepo-ci and feat-6-contracts-openapi-pipeline are done. Phases 130 to 150 are not started.

### Blockers

None.

### Updates

<!-- Newest entry first -- prepend new entries directly below this comment. -->

#### 2026-11-11 15:20:00.000Z - Phase 120 done: the stop of the license gate is resolved by the decision (b) of the owner, the task 120.110 is closed

The owner chose on 2026-11-11 the option (b) for the stop of the license gate of the phase 120 (the chat: "(b)" and "go ahead"): the deviation for the package caniuse-lite (CC-BY-4.0, the transitive package of the tree of Stryker, the chain @stryker-mutator/core -> @stryker-mutator/instrumenter -> @babel/core -> @babel/helper-compilation-targets -> browserslist -> caniuse-lite) is recorded in the register DEC 93a6d588-e002-4daf-9a47-45e2d77786e9 (the dated section of 2026-11-11; the file is not changed by this feature). The mechanism is in place: the pin `CANIUSE_LITE_VERSION=1.0.30001823` in `tools/versions.env` (the package is transitive, so the lock file of `frontend/` is the tie, and `just check-pins` checks it with the new check `Caniuse-lite pin`, fail closed), and the rule X1 of `sbom.sh` generalized for the two pinned packages (after cdxgen made the frontend SBOM, `sbom_exclude.py` removes axe-core @ `AXE_CORE_VERSION` and caniuse-lite @ `CANIUSE_LITE_VERSION`; a component with another version of a package is not removed, and the license gate stops for it). The self-test has the cases, for the pin and for the exclusion (the removal, the no-op, a component with another version, and a missing key for each package). The evidence: `just sbom` gives exit code 0 (the two removals are logged: `removed 1 component(s) axe-core@4.14.0` and `removed 1 component(s) caniuse-lite@1.0.30001823`, 340 components of the frontend), and `just license-check` gives exit code 0 (`RESULT: PASS. 352 component(s), all licenses permitted`). The recipes `mutation-backend` and `mutation-frontend` are green and deterministic (the evidence is in the previous entry of 2026-11-11). Task 120.110 is ticked, and the phase 120 (Mutation Tests) is done. No row of the license table is necessary for the transitive package (the table names the tools of the feature; the register of the deviations names the package).

#### 2026-11-11 09:10:00.000Z - Phase 120: PIT is done, Stryker operates and stops for the license of a transitive package (caniuse-lite, CC-BY-4.0)

Task 120.100 is done. The Maven module has PIT (the plugin org.pitest:pitest-maven 1.30.2 and the JUnit5 support org.pitest:pitest-junit5-plugin 1.2.3 as a dependency of the plugin, the versions in `tools/versions.env` as `PIT_VERSION` and `PIT_JUNIT5_PLUGIN_VERSION`). The recipe `just mutation-backend` runs `./mvnw test-compile org.pitest:pitest-maven:1.30.2:mutationCoverage -Dcodegen.skip=true` (one run), makes the HTML and the XML report in `backend/target/pit-reports` (not in git), and asserts: the run is green and not skipped, the report is made, the summary `>> Generated 52 mutations Killed 3 (6%)`, and at least one mutant with the status SURVIVED in the XML report (the deterministic source). The surviving mutant is deterministic for the pinned code and tests: `toString()` of the generated enum ErrorCode (line 47, the mutator EmptyObjectReturnValsMutator, "replaced return value with \"\""), the target tests never assert the return value of `toString()`. Three runs of the recipe and two runs of the goal give the same 52 mutants with the same statuses (3 KILLED, 48 NO_COVERAGE, 1 SURVIVED). The scope is the generated model code (targetClasses) and the two unit test classes (targetTests, the integration test and the class that is not successful are no target tests). The runtime is about 5.5 seconds (warm).

Task 120.110 is implemented and operates, and it is not closed (the owner makes the decision). The pnpm module has Stryker (the package @stryker-mutator/core 10.1.1 and the plugin @stryker-mutator/vitest-runner 10.1.1, the peer of the plugin is vitest >=2.0.0 and it operates with the pinned Vitest 5.1.0, the versions and the integrity values in `tools/versions.env`). The config `frontend/stryker.config.json` scopes the mutation to `src/mutation-example.ts` (the example for the mutation tests, not product code; the module has no product code) and to the generated Zod schemas, and runs Vitest (the config vitest.config.ts, the normal run with the weak test of the example). The recipe `just mutation-frontend` runs `pnpm exec stryker run` (exit code 0, the config has no breaking threshold: the tool operates as a report), makes the HTML and the JSON report in `frontend/mutation-report` (the folder and the temp folder `.stryker-tmp` are in `.gitignore`), and asserts the finding: 21 mutants with the status Survived in the JSON report (the deterministic source). Five runs of Stryker and three runs of the recipe give the same 57 mutants with the same statuses (28 Killed, 21 Survived, 8 NoCoverage). The runtime is about 4.5 seconds. The normal run `just test-unit-frontend` is green with the weak test (3 test files, 11 tests).

The SBOM gate stops for the decision of the owner: the tree of Stryker enters the SBOM of the frontend (341 components after the phase, 187 before), and the component caniuse-lite 1.0.30001823 has the license CC-BY-4.0 (the registry entry and the LICENSE of the tarball), which is not in `tools/license/permitted-licenses.txt` and has no row in the class table of the DEC 84c37f7d-08cb-457d-8ab3-1db37dba9bc9. The chain is @stryker-mutator/core -> @stryker-mutator/instrumenter -> @babel/core -> @babel/helper-compilation-targets -> browserslist -> caniuse-lite (the instrumenter of Stryker has Babel in each released line, and Babel has browserslist for the targets). Per the constraint of the task, the work stops and no exclusion and no workaround are made (the rule X1 is not touched). The options for the owner are in the Blockers and in the Result of the Phase 120.

The pins are in `tools/versions.env`, tied to `backend/pom.xml` and to `frontend/package.json` and `frontend/pnpm-lock.yaml` by `just check-pins` (PASS), and the 32 new negative self-test cases are in `selftest.sh`. The license table has the two new rows PIT JUnit5 plugin (Apache-2.0, Permitted, checked in the phase 120 on 2026-11-11 from the POM of 1.2.3 on Maven Central and the LICENSE.txt of github.com/pitest/pitest-junit5-plugin at the tag 1.2.3) and Stryker vitest runner (Apache-2.0, Permitted, checked in the phase 120 on 2026-11-11 from the registry entry and the LICENSE of the package tarball) (REQ-005). The result, the evidence, the deterministic sources and the values for the baseline of the phase 140 are in the Design Notes, the Result of the Phase 120.

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

#### 2026-11-11 15:20:00.000Z - The stop of the license gate of the phase 120 is resolved by the decision (b) of the owner: the deviation for caniuse-lite, and the rule X1 for the two pinned packages

The license gate stopped for the transitive package caniuse-lite 1.0.30001823 (the license CC-BY-4.0, no class in the DEC 84c37f7d-08cb-457d-8ab3-1db37dba9bc9, not in `tools/license/permitted-licenses.txt`), in the tree of Stryker of the pnpm module (the chain @stryker-mutator/core 10.1.1 -> @stryker-mutator/instrumenter 10.1.1 -> @babel/core 8.0.10 -> @babel/helper-compilation-targets 8.0.7 -> browserslist 4.29.5 -> caniuse-lite; the instrumenter of Stryker has Babel in each released line, and the package is necessary for it). The owner chose on 2026-11-11 the option (b) (the chat: "(b)" and "go ahead"): the targeted deviation with the SBOM exclusion, and not a class for CC-BY-4.0 in the DEC (the option (a), the question of the law stays for the owner), and not a decision about the tool of the mutation of the pnpm module (the option (c)). The deviation is in the register DEC 93a6d588-e002-4daf-9a47-45e2d77786e9 (the dated section of 2026-11-11). The mechanism: the pin `CANIUSE_LITE_VERSION=1.0.30001823` in `tools/versions.env` (the package is transitive, so it has no entry in `frontend/package.json` and no integrity key: the lock file is the tie, and `just check-pins` checks it, fail closed), and the rule X1 of `sbom.sh` generalized for the two pinned packages that must not reach the SBOM of the frontend: axe-core (the devDependency of the module, MPL-2.0, the class Review, the deviation of 2026-11-09) and caniuse-lite (the transitive package of Stryker, CC-BY-4.0, the deviation of 2026-11-11). The common ground is rule A of the DEC (the tools do not go to users, so the license of the tools is checked in the plan and the package is kept out of the SBOM). `sbom_exclude.py` removes the components of the pinned version of each package (and the references to them), one version per package; a component with another version is not removed, and the license gate stops for it (fail closed). A row of the license table is not necessary for the transitive package: the table names the tools of the feature, and the register of the deviations names the package.

#### 2026-11-11 09:10:00.000Z - The pins and the scope of the phase 120: PIT 1.30.2 with the JUnit5 plugin 1.2.3, Stryker 10.1.1 with the vitest-runner 10.1.1, and the scoping of the two runs

The versions that operate are recorded here, and the difference to the names of the task is noted. The JUnit5 support of PIT is the package org.pitest:pitest-junit5-plugin (1.2.3) as a dependency of the plugin pitest-maven in `backend/pom.xml` (and not a test dependency of the module): pitest-maven loads the test framework plugins from its own classpath, and not from the test classpath of the module. With the plugin dependency, the two engines of the JUnit Platform (JUnit and jqwik) are found and run in the mutation. The recipe runs the goal after the phase test-compile in one run of ./mvnw: the generator execution of the phase generate-sources adds `src/generated/java` as a compile source root, and the goal skips a project with no compile source root. The scope of the run of PIT is the generated model code (targetClasses `biz.dfch.specmgrdemo.model.*`, the package `biz.dfch.specmgrdemo.api` has only an interface with no bytecode with logic) and the two unit test classes of the generated code (targetTests; the integration test needs the Docker daemon, and the class that is not successful must not run in the mutation). The report formats are HTML and XML (the parameter `outputFormats` of pitest-maven 1.30.2; the JSON format is not in this line of PIT), and the deterministic source of the recipe is the attribute `status` of the XML report. The mutation tool of the pnpm module is the plugin @stryker-mutator/vitest-runner (10.1.1), and not the package @stryker-mutator/vitest that the task names: that package does not exist in the registry, and the runner plugin of Stryker for Vitest is @stryker-mutator/vitest-runner (the peer vitest >=2.0.0 operates with the pinned Vitest 5.1.0, and the plugin loads the Vitest of the project). The config `frontend/stryker.config.json` has the explicit entry `plugins` with the runner: the automatic discovery of Stryker globs `@stryker-mutator/*` from the real path of the package core, and with pnpm that path is in the store `.pnpm/`, where only the own dependencies of core are (without the explicit entry, no TestRunner plugin is loaded). The scope of the mutation is the example file `src/mutation-example.ts` (with the weak test `src/test/mutation-example.test.ts`, both marked as the example for the mutation tests and not product code; the module has no product code) and the generated Zod schemas (`src/generated/zod/**/*.ts`), and the test runner is the config of the normal run (vitest.config.ts, it excludes the files with the part `broken`). The exit code of the run is 0 also with surviving mutants: the config has no breaking threshold (the default of `thresholds.break` is null), and the plan does not set a threshold (the tool operates as a report, the DEC about verification; the threshold is for the walking skeleton). The decision about the license CC-BY-4.0 of the transitive package caniuse-lite in the tree of Stryker (the chain through the instrumenter of Stryker, Babel and browserslist) is made by the owner on 2026-11-11 (option (b)): no class for CC-BY-4.0 in the DEC; the deviation is in the register DEC 93a6d588-e002-4daf-9a47-45e2d77786e9 (the dated section), and the package is kept out of the SBOM of the frontend by the rule X1 (the pin CANIUSE_LITE_VERSION, fail closed).

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
