---
classification: null
created: '2026-11-02T14:44:48.525+01:00'
id: 84c37f7d-08cb-457d-8ab3-1db37dba9bc9
status: accepted
type: dec
updated: '2026-11-03T18:21:48.116+01:00'
version: 1.0.0
---

# Use Only Open Source Libraries That Are Compatible With AGPL-3.0-only

## Context and Problem Statement

The repository has the license AGPL-3.0. Each library that the project uses must be open source and compatible with this license. The project must have a rule and a method to examine it.

## Decision Drivers

- The license of the repository is AGPL-3.0-only.
- Licenses that are not compatible can stop the project from giving the software to users.
- Coding agents add dependencies. They must have a clear rule.

## Considered Options

- A list of permitted licenses that a gate in CI examines, and one register DEC for all approved deviations.
- A person examines each dependency by hand.
- No rule.

## Decision Outcome

The project uses only open source libraries that are compatible with AGPL-3.0-only. A gate in CI compares the licenses of all dependencies of the backend and the frontend with a list of permitted licenses. This includes the direct dependencies and the transitive dependencies. A library with a different license is possible only with a DEC that records the deviation. The owner must accept the DEC.

### Consequences

- The rule includes build tools, test libraries and tools in CI, and also the libraries that go to users. For a tool that does not go to users, the check covers the main license of the tool only. The licenses of the parts that the tool bundles are not checked. For a library that goes to users, the gate checks each dependency, with no exception.
- If the gate finds a license that it does not know, it stops the pull request.
- Each tool in the DECs about technology has a status of license check. The first operation of the gate gives the result.

### Confirmation

A gate in CI examines the licenses for Maven and for pnpm. It compares them with the list in the repository. The gate also makes an SBOM.

## Roles and Responsibilities

### Accountable

Project owner.

### Responsible

- Maintainers of the license gate.
- Authors of changes that add dependencies.

## Tags

- technology
- license

## Source

Requirement of the owner on 2026-11-02.

## Related Artifacts

### Goals

- GOL fde907fd-6fa5-4d87-b0ce-10babc0b4562: Make Software of High Quality

## More Information

These are the first classes of licenses. The owner must make sure that they are correct before the owner accepts the DEC. A person who has competence in the law must help.

| Class | Licenses | Rule |
|---|---|---|
| Permitted | MIT, BSD-2-Clause, BSD-3-Clause, ISC, 0BSD, Apache-2.0, CC0-1.0, Zlib, Unicode-3.0, Unicode-DFS-2016, BlueOak-1.0.0, Artistic-2.0, LGPL-3.0, GPL-3.0-only, GPL-3.0-or-later, AGPL-3.0-only, AGPL-3.0-or-later | Permitted. The gate must match the complete expression. |
| Permitted | GPL-2.0-only WITH Classpath-exception-2.0 | Permitted. The gate must match the complete expression. The license GPL-2.0-only with no exception stays not permitted. |
| Review | EPL-2.0, MPL-2.0 | A DEC about the deviation is necessary |
| Not permitted | GPL-2.0-only, SSPL, BUSL, licenses with no right to commercial use, proprietary licenses | Not permitted |

Some tools for security scans can have terms that are not open source, for example the engine of CodeQL. The gate must examine each tool. The AGPL clause about networks applies if users operate the web application through a network. The owner must make a decision about how the project obeys this clause.

All approved deviations are in one register DEC, with one dated section for each deviation. The register is made when the first deviation is approved. Each new section is a change to an accepted DEC, so the owner must accept it. No deviation exists at this time.

## Updates

<!-- Newest entry first -- prepend new entries directly below this comment. -->

### 2026-11-03 17:21:41.000Z - GPL-3.0-only and GPL-3.0-or-later in the class Permitted

The owner gave a permission for one time to make this change, and no other change (statement of the owner on 2026-11-03: "we want to allow GPL v3 only AND -later"). The agent changed one row of the class Permitted in More Information. The short form `GPL-3.0` is now `GPL-3.0-only`, and `GPL-3.0-or-later` is added. The gate reads the deprecated identifier `GPL-3.0` as `GPL-3.0-only`, so the meaning of the old entry does not change. The reason is that `GPL-3.0-or-later` gives the user the choice of version 3, so it is not more restrictive than `GPL-3.0-only`, and dependencies of the frontend and the backend can have it. The gate stopped on it (see the review of feat-5-foundation-monorepo-ci, finding D2). A person who has competence in the law must examine the new entry, in the same way as for the other rows. The entry `LGPL-3.0` stays in the short form. The decision for LGPL and for `GPL-2.0-or-later` is open for the owner, and this change does not include them. The status and the text of the Decision Outcome are not changed.

### 2026-11-03 11:45:17.000Z - Rule for tools and one register for deviations

The owner gave a permission for one time to make these changes, and no other change. The agent made three changes. First, the first bullet in Consequences now says that, for a tool that does not go to users, the check covers the main license only (decision of the owner on 2026-11-03: "Option A"). Second, the option in Considered Options now says one register DEC for all deviations, and a paragraph in More Information gives the form of the register (decision of the owner on 2026-11-03). Third, this entry. The text of the Decision Outcome is not changed. A DEC that is a register is also "a DEC that records the deviation". The class table is not changed.

### 2026-11-03 11:22:16.000Z - Five licenses added to the class Permitted

The owner gave a permission for one time to make this change, and no other change. The agent added `Zlib`, `Unicode-3.0`, `Unicode-DFS-2016`, `BlueOak-1.0.0` and `Artistic-2.0` to the row of the class Permitted in More Information. The reason is that libraries can have them, and the license files of Node (zlib, ICU, minimatch, npm) and of the JDK (zlib, CLDR, ICU4J) have them. A person who has competence in the law must examine the new entries, in the same way as for the Classpath row. The text of the decision is not changed.

### 2026-11-03 11:17:19.000Z - CC0-1.0 added and AGPL identifiers made exact

The owner gave a permission for one time to make these two changes, and no other change. The agent changed one row of the class Permitted in More Information. First, the identifier `CC0-1.0` is added. The reason is that the task runner `just` has this license (feat-5-foundation-monorepo-ci, Task 100.100). The row also permits other libraries with CC0-1.0. Second, `AGPL-3.0` is now `AGPL-3.0-only, AGPL-3.0-or-later`. The code of the project is AGPL-3.0-only, and the project also accepts AGPL-3.0-or-later (statement of the owner). The gate must match the complete expression, so the short form `AGPL-3.0` is no longer in the list. A person who has competence in the law must examine the new `CC0-1.0` entry, in the same way as for the Classpath row. The text of the decision is not changed.

### 2026-11-03 09:56:46.000Z - Review of the new license row

The owner gave a permission for one time to add this entry. The owner told the coding agent on 2026-11-03 that the review of the row `GPL-2.0-only WITH Classpath-exception-2.0` is done. The reviewer is dfch, and the date of the review is 2026-11-03 (the owner told the agent both on 2026-11-03). The agent has no other source for this fact. The text of the decision is not changed.

### 2026-11-03 00:00:00.000Z - License class for the Classpath exception added

The owner told the coding agent to amend this DEC. The permission is for one time and for this change only. The agent added one row to the class Permitted in More Information: `GPL-2.0-only WITH Classpath-exception-2.0`. The reason is that OpenJDK has this license, and the JDK is a build tool and a runtime of the project. Some Java libraries can have the same license. The row has no effect on the license GPL-2.0-only with no exception, which stays not permitted. The Assembly exception is not in the row, because no dependency of the project needs it at this time. The text of the decision is not changed. A person who has competence in the law must examine the new row together with the other classes. Task 100.110 of feat-5-foundation-monorepo-ci must read the license file of the selected JDK build before the project uses the row.

### 2026-11-02 00:00:00.000Z - Draft written

The first version of this decision is written.
