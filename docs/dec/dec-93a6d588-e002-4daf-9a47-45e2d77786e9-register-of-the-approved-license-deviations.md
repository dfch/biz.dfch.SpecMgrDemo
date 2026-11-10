---
classification: null
created: '2026-11-09T20:05:19.449+01:00'
id: 93a6d588-e002-4daf-9a47-45e2d77786e9
status: accepted
type: dec
updated: '2026-11-10T21:00:43.996+01:00'
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

## Updates

<!-- Newest entry first -- prepend new entries directly below this comment. -->

### 2026-11-10 19:59:06.000Z - The pinned version of JUnit is the 5.x line

The section JUnit names the version 6.1.3 (the one the phase 100 of feat-7-verification-architecture-tools looked at). The pin the feature makes in `backend/pom.xml` is the 5.x line (5.14.4), because jqwik 1.10.2 needs the JUnit Platform 1.14.x (the plan records the decision). The 5.x line has the same license (EPL-2.0, the class Review), so the deviation of this register covers the pinned version too. The text of the section is not changed.

### 2026-11-09 19:04:09.000Z - Created with the four approved deviations of feat-7-verification-architecture-tools

The register is created on the decision of the owner of 2026-11-09 (in the chat: "all approved", the answer to the four questions: JUnit EPL-2.0, jqwik EPL-2.0, axe-core MPL-2.0, JaCoCo EPL-2.0). The four dated sections of More Information are written, and the owner accepted the DEC with the same statement.
