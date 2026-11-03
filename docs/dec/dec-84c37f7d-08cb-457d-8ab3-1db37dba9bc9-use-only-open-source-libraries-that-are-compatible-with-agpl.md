---
classification: null
created: '2026-11-02T14:44:48.525+01:00'
id: 84c37f7d-08cb-457d-8ab3-1db37dba9bc9
status: draft
type: dec
updated: '2026-11-02T15:17:51.870+01:00'
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

- A list of permitted licenses that a gate in CI examines, and a DEC for each approved deviation.
- A person examines each dependency by hand.
- No rule.

## Decision Outcome

The project uses only open source libraries that are compatible with AGPL-3.0-only. A gate in CI compares the licenses of all dependencies of the backend and the frontend with a list of permitted licenses. This includes the direct dependencies and the transitive dependencies. A library with a different license is possible only with a DEC that records the deviation. The owner must accept the DEC.

### Consequences

- The rule includes build tools, test libraries and tools in CI, and also the libraries that go to users.
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
| Permitted | MIT, BSD-2-Clause, BSD-3-Clause, ISC, 0BSD, Apache-2.0, LGPL-3.0, GPL-3.0, AGPL-3.0 | Permitted |
| Review | EPL-2.0, MPL-2.0 | A DEC about the deviation is necessary |
| Not permitted | GPL-2.0-only, SSPL, BUSL, licenses with no right to commercial use, proprietary licenses | Not permitted |

Some tools for security scans can have terms that are not open source, for example the engine of CodeQL. The gate must examine each tool. The AGPL clause about networks applies if users operate the web application through a network. The owner must make a decision about how the project obeys this clause.

## Updates

<!-- Newest entry first -- prepend new entries directly below this comment. -->

### 2026-11-02 00:00:00.000Z - Draft written

The first version of this decision is written.
