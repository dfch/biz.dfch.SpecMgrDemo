---
classification: null
created: '2026-11-09T20:05:19.449+01:00'
id: 93a6d588-e002-4daf-9a47-45e2d77786e9
status: accepted
type: dec
updated: '2026-11-18T23:57:02.120+01:00'
version: 1.0.0
---

# Register of the Approved License Deviations

## Context and Problem Statement

DEC 84c37f7d-08cb-457d-8ab3-1db37dba9bc9 permits the use of a library whose license is in the class Review only with a DEC that records the deviation. Its More Information names the form: all approved deviations are in one register DEC, with one dated section for each deviation, and the register is made when the first deviation is approved. This document is that register. The first four deviations are approved for the tools of feat-7-verification-architecture-tools: the phase 100 of that feature checked the license of each tool from the license file, and the owner made the decision on 2026-11-09.

## Decision Drivers

- The license of the repository is AGPL-3.0-only (DEC 84c37f7d-08cb-457d-8ab3-1db37dba9bc9).
- The classes of the licenses and the rule for a deviation are fixed by that DEC.
- Each tool of this register is a build or a test tool. It does not go to users, so rule A of the DEC applies: only the main license of the tool is examined.

## Considered Options

- One register DEC for all approved deviations, with one dated section for each deviation (the option of DEC 84c37f7d-08cb-457d-8ab3-1db37dba9bc9).
- One separate DEC for each deviation.
- No record of the deviation.

## Decision Outcome

The project keeps all approved deviations of the class Review of DEC 84c37f7d-08cb-457d-8ab3-1db37dba9bc9 in this one register DEC. Each deviation is one dated section in the More Information with the tool, the use, the license, the class, the decision of the owner and the date. A new approved deviation is a new section of this DEC (a change of an accepted DEC, so the owner must accept each new section).

### Consequences

- A dated section of this DEC is the permission for the use of the tool of the section.
- The license table of the plan of a feature names this DEC for each row with the result Review (the ACC-005 of feat-7-verification-architecture-tools).
- The agent writes a new section and sets the status of this DEC only on the explicit permission of the owner.

### Confirmation

The gate license-check of the SBOM is not affected: rule A applies, and the tree of a tool is not in the SBOM. The use of each tool of a section is visible in the module that the plan of the feature names.

## Roles and Responsibilities

### Accountable

The project owner.

### Responsible

- The maintainer of the license gate.
- The author of the feature that uses the tool of a section.

## Tags

- license
- process

## Source

The decision of the owner on 2026-11-09 (in the chat: "all approved", the answer to the question about the three Review rows of the phase 100 of feat-7-verification-architecture-tools and the tool JaCoCo of the baseline), and DEC 84c37f7d-08cb-457d-8ab3-1db37dba9bc9.

## Related Artifacts

### Decisions

- DEC 84c37f7d-08cb-457d-8ab3-1db37dba9bc9: Use Only Open Source Libraries That Are Compatible With AGPL-3.0-only

## More Information

The dated sections of the register, one for each approved deviation. Each section names the tool and the version that the phase 100 of feat-7-verification-architecture-tools looked at, where the license was read, the class of the DEC, the use in the feature, and the decision of the owner with the date.

### 2026-11-09 - JUnit (EPL-2.0) for the unit tests of the backend

The tool is JUnit (org.junit.jupiter:junit-jupiter), the version 6.1.3. The license EPL-2.0 is read from the entry of the POM on Maven Central and the LICENSE.md of the repository junit-team/junit-framework at the tag r6.1.3 (the evidence is in the Result of the Phase 100 of the plan of feat-7-verification-architecture-tools). The class of DEC 84c37f7d-08cb-457d-8ab3-1db37dba9bc9 is Review. The use is the unit tests of the Maven module (REQ-001 of the feature). The owner approved the deviation on 2026-11-09 (in the chat: "all approved").

### 2026-11-09 - jqwik (EPL-2.0) for the tests with random data of the backend

The tool is jqwik (net.jqwik:jqwik), the version 1.10.2. The license EPL-2.0 is read from the entry of the POM on Maven Central and the LICENSE.md of the repository jqwik-team/jqwik at the tag 1.10.2 (the evidence is in the Result of the Phase 100 of the plan of feat-7-verification-architecture-tools). The class of DEC 84c37f7d-08cb-457d-8ab3-1db37dba9bc9 is Review. The use is the tests with random data of the Maven module (REQ-002 of the feature). The owner approved the deviation on 2026-11-09 (in the chat: "all approved").

### 2026-11-09 - axe-core (MPL-2.0) for the accessibility check of the end-to-end test

The tool is axe-core (npm axe-core), the version 4.14.0. The license MPL-2.0 is read from the license field of the registry entry at registry.npmjs.org and the LICENSE of the package tarball (the evidence is in the Result of the Phase 100 of the plan of feat-7-verification-architecture-tools). The class of DEC 84c37f7d-08cb-457d-8ab3-1db37dba9bc9 is Review. The use is the accessibility check in the end-to-end test (REQ-007 of the feature). The owner approved the deviation on 2026-11-09 (in the chat: "all approved") and chose the tool axe-core, which the plan names in the scope, and not the alternative pa11y (MIT) that was named in the question.

### 2026-11-09 - JaCoCo (EPL-2.0) for the line and branch coverage of the Maven module

The tool is JaCoCo (org.jacoco:jacoco, the Maven plugin org.jacoco:jacoco-maven-plugin), the version 0.8.16 (the latest on Maven Central at the moment of the decision; the pin is made in the phase 140 of feat-7-verification-architecture-tools). The license EPL-2.0 is read from the LICENSE.md of the repository jacoco/jacoco (the Eclipse Public License Version 2.0). The class of DEC 84c37f7d-08cb-457d-8ab3-1db37dba9bc9 is Review. The use is the measurement of the line and the branch coverage of the Maven module (REQ-006 of the feature). The owner approved the deviation on 2026-11-09 (in the chat: "all approved").

### 2026-11-11 - caniuse-lite (CC-BY-4.0), a transitive package of the tool Stryker

The package is caniuse-lite (the data of the browser features), the version 1.0.30001823. The license CC-BY-4.0 is read from the license field of the registry entry registry.npmjs.org/caniuse-lite/1.0.30001823 and the LICENSE of the package tarball (the full text of the Creative Commons Attribution 4.0 International license) (the phase 120 of feat-7-verification-architecture-tools; the evidence is in the Result of the Phase 120 of the plan of that feature). The license has no class in DEC 84c37f7d-08cb-457d-8ab3-1db37dba9bc9, and the package is not in tools/license/permitted-licenses.txt, so the license gate stopped fail closed (REQ-005 of the feature: if a license is not clear, the work stops and the owner makes a decision). The package is a transitive dependency of the tool Stryker (@stryker-mutator/core 10.1.1): the chain in the lock file is @stryker-mutator/instrumenter 10.1.1 to @babel/core 8.0.10 to @babel/helper-compilation-targets 8.0.7 to browserslist 4.29.5 to caniuse-lite 1.0.30001823 (the instrumenter of Stryker has Babel in each released line). The tool does not go to users (rule A of DEC 84c37f7d-08cb-457d-8ab3-1db37dba9bc9), and the package is not used directly. The owner approved the deviation on 2026-11-11 (in the chat: "(b)", the answer to the question about the license stop of the phase 120 of feat-7-verification-architecture-tools). The package is kept out of the SBOM of the frontend by the rule X1 of tools/gates/sbom.sh (the pinned version CANIUSE_LITE_VERSION, fail closed), in the same way as axe-core (MPL-2.0).

### 2026-11-15 - CodeQL (GitHub CodeQL Terms) as the hosted default setup of GitHub

The tool is CodeQL, the code analysis of GitHub. The terms are the file `LICENSE.md` of the repository github/codeql-cli-binaries ("GitHub CodeQL Terms and Conditions"), which the agent read on 2026-11-15 (the plan of feat-8-traceability-security-gates, Task 100.140, has the evidence). These terms are not an open source license, so the class of DEC 84c37f7d-08cb-457d-8ab3-1db37dba9bc9 is Review, and the DEC does not have a class for them. The terms permit the analysis of an Open Source Codebase (a codebase with an OSI-approved license), and the creation of CodeQL databases for CI of such a codebase that is hosted and maintained on GitHub.com. They do not permit the use with a codebase that is not an Open Source Codebase (for example a private repository), unless the user has a paid customer license for GitHub Advanced Security. The terms are per user, and they do not permit a hosted offer of the software by a third party. The queries of the repository github/codeql are MIT (the license of the GitHub API, not read from the file).

The use is the code analysis of the repository with the hosted default setup of GitHub (REQ-006 of feat-8-traceability-security-gates). GitHub runs the engine. The project does not download or install the engine, no workflow file and no recipe starts it, and the scan stays a report (no recipe and no job of the repository decides a finding of the scan). Since feat-9-walking-skeleton (the task 500.120 of that plan), the pull request is stopped by the native check of GitHub, and not by a recipe of the repository: the rule `code_scanning` of the ruleset (the tool `CodeQL`, `security_alerts_threshold` `high_or_higher` and `alerts_threshold` `none`) stops the pull request for a new alert that is `high_or_higher` when the owner applies it (the step 2 of `branch-protection.md` in the folder of feat-5-foundation-monorepo-ci). The default setup is `configured` (read on 2026-11-18), and the check `CodeQL` runs on the pull requests. The tool does not go to users (rule A of DEC 84c37f7d-08cb-457d-8ab3-1db37dba9bc9), and it is not in the SBOM.

Conditions of this deviation:

- The condition for the use is that the repository is public, has an OSI-approved license (AGPL-3.0-only) and is on GitHub.com. If one of these stops to be true, for example in a derived private repository (GOL 330a042f-8be7-4358-b451-25a4dfcba359), this deviation does not apply, and the default setup must be turned off or covered by a license for GitHub Advanced Security. The hosted setup gives no scan for a private repository without such a license, so the case fails safely.
- The version of CodeQL and of its queries is not pinned, and the scan does not run on a developer machine. This is an exception to REQ-002 and REQ-009 of feat-5-foundation-monorepo-ci (one entry point, `just`, for local work and for CI).
- The agent did not read the terms of GitHub for the hosted service (the GitHub Terms of Service and the terms for GitHub Advanced Security). This section covers only the CodeQL Terms. A person who has competence in the law must examine the section, in the same way as for the other rows of DEC 84c37f7d-08cb-457d-8ab3-1db37dba9bc9.

The owner approved the deviation on 2026-11-15 (in the chat: "I give the one-time permission for DEC 93a6d588" and "CodeQL: go ahead", after the choice of the hosted default setup).

### 2026-11-15 - OSV data (the OSV.dev database, mixed source licenses) that OSV-Scanner queries

The data is the OSV.dev database (vulnerability records), which the tool OSV-Scanner 2.7.1 queries on the network (api.osv.dev) for the packages of the SBOM files of the project (`build/sbom/*.cdx.json`: Maven and npm packages). The tool itself is Apache-2.0 and Permitted (the license table of the plan of feat-8-traceability-security-gates). The data is not a library, and DEC 84c37f7d-08cb-457d-8ab3-1db37dba9bc9 has no class for it. The agent read on 2026-11-15: `docs/data.md` of the repository github.com/google/osv.dev (master) and the page google.github.io/osv.dev/data/, the FAQ of OSV.dev, the `LICENSE` of the repository osv.dev (Apache-2.0, for the code only), and the `README.md` of OSV-Scanner at the tag v2.7.1 (the section Data Sources and Privacy). The plan of feat-8-traceability-security-gates (Task 100.130, the Result of the Phase 100) has the evidence.

The sources and their licenses, as the page names them: CC-BY 4.0 (GitHub Advisory Database, PyPI Advisory Database, Go Vulnerability Database, OSS-Fuzz, Python Software Foundation Database, and others), CC0 1.0 (for example RustSec, Global Security Database), MIT, Apache 2.0 and BSD (for example OpenSSF Malicious Packages, Curl, AlmaLinux, Rocky Linux), CC-BY-SA 4.0 (Ubuntu and Alpine SecDB), and CC-BY-NC-ND 4.0 or the Chainguard License for Commercial Scanners (Chainguard / Wolfi). Converted data (Debian, Alpine, NVD) has the license of its source. The page gives no license or terms for the OSV.dev aggregate and for the answers of the API. The agent found no terms of use of OSV.dev for the data or the API (the FAQ says that the API has no rate limit at this time, and it gives service level objectives that are targets). The agent did not read the terms of Google for the service (for example the Google APIs Terms of Service), and did not read the license texts of the single sources. This section covers the licenses as the OSV.dev page names them.

The class of DEC 84c37f7d-08cb-457d-8ab3-1db37dba9bc9 is Review (the DEC has no class for CC-BY-4.0 and the other data licenses; the precedent is the section of caniuse-lite, CC-BY-4.0, above). The use is the report of known vulnerabilities in the dependencies (REQ-005 of feat-8-traceability-security-gates): a recipe and a CI job, and since feat-9-walking-skeleton (the task 500.120 of that plan) a blocking job. The level gate (tools/security/README.md, tools/gates/security_threshold.py) decides the finding: a finding that is Critical or High stops the job in each case, a finding that is not in the baseline stops the job, a line of the baseline that has no finding any more is a warning, and a failure of the tool stops the job. The baseline file (tools/security/osv-baseline.txt) has the counts and the identifiers of the findings only, so the conditions of this section hold. The tool and the data do not go to users (rule A of DEC 84c37f7d-08cb-457d-8ab3-1db37dba9bc9).

What OSV-Scanner sends to api.osv.dev (the README of OSV-Scanner): package names, versions and ecosystems, and file hashes for vendored C/C++ code. No source code is sent. The SBOM files are made from public code of a public repository. The tool can also ask the API of deps.dev (the dependency tree and `--licenses`) and the registries Maven Central and npm, depending on the options of the recipe. The recipe of Phase 120 must keep these queries to the minimum that the report needs, and must not use the option `--licenses`.

Conditions of this deviation:

- The use is a report with a level gate (the job is blocking since feat-9-walking-skeleton, the task 500.120 of that plan; the description of the use above). The project stores no copy of the records, and it does not redistribute them: no advisory text, no database dump and no downloaded database in the repository (a cache in a CI run is not a copy in the repository). The repository has only the counts of the findings (the baseline and the number for each severity) and the identifiers of the findings (the OSV, GHSA or CVE identifier). The report of a run is shown in the log of the job and is not committed.
- The attribution is kept: the README of the security gates names OSV.dev as the source of the data, names the license of the GitHub Advisory Database (CC-BY 4.0) as the main source of the records for Maven and npm, and links to the page of the data sources of OSV.dev.
- The exposure that the project cannot exclude: the project has Maven and npm packages, for which the records are mainly from the GitHub Advisory Database (CC-BY 4.0), but OSV-Scanner can return a record that has a license that is stricter, for example CC-BY-SA 4.0 (Ubuntu, Alpine) or CC-BY-NC-ND 4.0 (Chainguard / Wolfi), from an ecosystem that the project does not have (for example by a package name that two ecosystems share, or by the C/C++ detection with file hashes). The agent cannot show that this does not occur. The condition that no record is copied or redistributed limits the exposure to the use of the record in a report that shows counts and identifiers. Whether the rest is covered by the terms of the source is not examined, and a person who has competence in the law must examine the section, in the same way as for the other rows of DEC 84c37f7d-08cb-457d-8ab3-1db37dba9bc9.
- If the condition ends (a record is stored or redistributed, the attribution cannot be kept, a person who has competence in the law finds that a source license does not permit the use, or OSV.dev publishes terms that do not permit it), this deviation does not apply, and the recipe `vuln-scan` and its CI job must be switched off until the owner decides again. The offline mode of OSV-Scanner with a downloaded database does not end the license question (the database has the same source licenses), it ends only the transmission of the package names to the network. The owner decides whether offline mode, a limit to the ecosystems of the project, or the removal of OSV-Scanner follows.

The owner approved the deviation on 2026-11-15 (in the chat: option (a), the deviation for the OSV data with the attribution kept, only counts and finding identifiers stored, and no storage or redistribution of the records, the answer to the question of Task 100.130 of feat-8-traceability-security-gates). The owner gave the one-time permission for this section and for the entry of Updates, and for no other change of this DEC.

## Updates

<!-- Newest entry first -- prepend new entries directly below this comment. -->

### 2026-11-18 22:52:00.000Z - The sections of CodeQL and of the OSV data state the mechanism of feat-9 (the level gate and the native check of the pull request)

The owner gave a permission for one time to make this change, and no other change (statement of the owner on 2026-11-18, in the chat: "I give you one-time permission to update the DEC"). The reason is the review of the plan of feat-9-walking-skeleton (the finding S3 of 2026-11-17): since the task 500.120 of that plan the text of the two sections was not accurate. The sentence "a report with no threshold" of the section CodeQL is replaced: the scan stays a report (no recipe and no job of the repository decides a finding of the scan), and the pull request is stopped by the native check of GitHub, the rule `code_scanning` of the ruleset (the tool `CodeQL`, `security_alerts_threshold` `high_or_higher`, `alerts_threshold` `none`) that the owner applies in the step 2 of `branch-protection.md` (the folder of feat-5-foundation-monorepo-ci; the default setup is `configured`, read on 2026-11-18, and the check runs on the pull requests). The sentences "a report with no threshold" and "a report only" of the section OSV data are replaced: the recipe and the CI job are blocking since feat-9, and the level gate (tools/security/README.md, tools/gates/security_threshold.py) decides the finding (a finding that is Critical or High stops the job in each case, a finding that is not in the baseline stops the job, a line of the baseline that has no finding any more is a warning, a failure of the tool stops the job). The baseline file has the counts and the identifiers of the findings only, so the conditions of the section (no copy of the records, no redistribution, the attribution kept) hold without a change. The text of the other sections and the dated sections of More Information are not changed. The status is not changed (the status stays accepted).

### 2026-11-15 09:43:30.000Z - The deviation for the OSV data (mixed source licenses) is recorded

The owner gave a permission for one time to make this change, and no other change (statement of the owner on 2026-11-15, in the chat: option (a) for Task 100.130 of feat-8-traceability-security-gates, the deviation for the OSV data; the one-time permission for this DEC is part of this choice). The agent added the dated section "OSV data (the OSV.dev database, mixed source licenses) that OSV-Scanner queries" to More Information. The reason is the plan of feat-8-traceability-security-gates (Task 100.130): OSV-Scanner queries the OSV.dev database, whose records have the licenses of their sources (CC-BY 4.0, CC0, MIT, Apache-2.0, BSD, CC-BY-SA 4.0 and CC-BY-NC-ND 4.0), and the agent found no terms of use of OSV.dev. The section has the conditions (a report only, no copy of the records, counts and finding identifiers only, the attribution kept) and the exposure that the project cannot exclude. The time of this entry is the local time of the machine with the letter Z, as in the entry below. The text of the Decision Outcome and the other sections are not changed. The status is not changed.

### 2026-11-15 08:30:00.000Z - The deviation for CodeQL (GitHub CodeQL Terms) is recorded

The owner gave a permission for one time to make this change, and no other change (statement of the owner on 2026-11-15, in the chat: "I give the one-time permission for DEC 93a6d588"). The agent added the dated section "CodeQL (GitHub CodeQL Terms) as the hosted default setup of GitHub" to More Information. The reason is the plan of feat-8-traceability-security-gates (Task 100.140, Task 100.160): the owner chose the hosted default setup of CodeQL for the code analysis, and the terms of CodeQL are not an open source license. The text of the Decision Outcome and the other sections are not changed. The status is not changed.

### 2026-11-11 10:57:00.000Z - The deviation for caniuse-lite (CC-BY-4.0) is approved and recorded

The owner approved on 2026-11-11 (in the chat: "(b)", the answer to the question about the license stop of the phase 120 of feat-7-verification-architecture-tools: the targeted deviation with the exclusion of the SBOM, and not a class of the DEC, not the move of the tool to its own project, and not a change of the tool) the deviation for the package caniuse-lite (CC-BY-4.0, the transitive dependency of the tool Stryker, which does not go to users). The dated section of More Information is written, and the package is kept out of the SBOM of the frontend by the rule X1 of sbom.sh (the pinned version, fail closed), in the same way as axe-core. The status stays accepted (the statement of the owner is the permission for this change of an accepted DEC).

### 2026-11-10 19:59:06.000Z - The pinned version of JUnit is the 5.x line

The section JUnit names the version 6.1.3 (the one the phase 100 of feat-7-verification-architecture-tools looked at). The pin the feature makes in `backend/pom.xml` is the 5.x line (5.14.4), because jqwik 1.10.2 needs the JUnit Platform 1.14.x (the plan records the decision). The 5.x line has the same license (EPL-2.0, the class Review), so the deviation of this register covers the pinned version too. The text of the section is not changed.

### 2026-11-09 19:04:09.000Z - Created with the four approved deviations of feat-7-verification-architecture-tools

The register is created on the decision of the owner of 2026-11-09 (in the chat: "all approved", the answer to the four questions: JUnit EPL-2.0, jqwik EPL-2.0, axe-core MPL-2.0, JaCoCo EPL-2.0). The four dated sections of More Information are written, and the owner accepted the DEC with the same statement.
