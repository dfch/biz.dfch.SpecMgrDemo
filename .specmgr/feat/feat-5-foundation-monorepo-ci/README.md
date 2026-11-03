---
classification: null
created: '2026-11-03T07:53:33.591+01:00'
id: feat-5-foundation-monorepo-ci
status: planning
type: feat
updated: '2026-11-03T10:36:35.193+01:00'
version: 1.0.0
---

# Feature: Foundation of the Monorepo, the Justfile and CI

## Plan

### Overview

This feature makes the base of the toolchain. It gives the layout of the monorepo, one `justfile` as the entry point, version pins for the tools, the CI workflow on GitHub Actions, and the first gates. The gates in this feature are the specmgr validation, the check of the commit messages and a first license check with an SBOM. It also has the install scripts for the tools on the machine of the author. The DEC documents about the monorepo, about verification and about licenses are the source. GitHub issue #5 is for this feature. The feature is planned and not started.

### Requirements

- REQ-001: The repository must have the layout that the DEC about the monorepo gives: `backend/`, `frontend/`, `contracts/`, `model/`, `terminology/`, `tools/`, `docs/` and `.specmgr/`.

- REQ-002: A `justfile` must be the one entry point for local work and for CI. Each CI job must start one `just` recipe.

- REQ-003: The versions of the JDK, Maven, Node, pnpm and just must be in one file. The JDK and Node must be LTS versions.

- REQ-004: Each tool must have a license check before the project uses it. If a license is not clear, the work stops and the owner makes a decision.

- REQ-005: CI must have a gate for the specmgr validation of the changed documents and a gate for the commit messages. CI has no gate for the STE check and no script for the register at this time (decision of the owner on 2026-11-03).

- REQ-006: CI must make an SBOM and must compare the licenses of all dependencies with a list of permitted licenses.

- REQ-007: A CODEOWNERS file must give dfch as the owner of the DEC documents, the CI configuration, the thresholds and the list of licenses.

- REQ-008: The install scripts must put the tools in the home directory of the user and must not use sudo.

### Acceptance Criteria

- [ ] ACC-001: The layout from REQ-001 is in the repository, and each folder has a short README.

- [ ] ACC-002: `just --list` shows the recipes for validation, license check, SBOM and commit check. Each CI job starts only a `just` recipe.

- [ ] ACC-003: A script that is not in the `justfile` is not a build command in a workflow. A gate shows this.

- [ ] ACC-004: The file for versions has the pins. The install scripts read the versions from it. A new shell shows the pinned versions after the scripts operate.

- [ ] ACC-005: Each tool in the Task List has an entry in the license table of this plan with the result of the check. A tool with a license that is not clear is not in use.

- [ ] ACC-006: A pull request with a document that is not correct or a commit message that is not correct causes a failure in CI.

- [ ] ACC-007: CODEOWNERS and NOTICE are in the repository.

- [ ] ACC-008: The owner has set the branch protection with the gates of this feature, or the plan shows the open item for the owner.

### Scope

#### Included

- The layout, the `justfile`, the version file and the CI workflow.

- The install scripts in the `bin` folder of this feature.

- The gates for specmgr validation, commit messages, licenses and SBOM.

- CODEOWNERS and NOTICE.

- A suggestion for a skill about the names of scripts.

#### Explicitly Out Of Scope

- The OpenAPI pipeline (feat-6-contracts-openapi-pipeline).

- Test tools, mutation tools and architecture tools (feat-7-verification-architecture-tools).

- Product code and the walking skeleton.

- The STE check as a gate and the script that validates the register (on hold, decision of the owner on 2026-11-03).

- Thresholds. The skeleton sets them from a measured baseline.

### Dependencies

#### Depends On

- feat-3-process-policy-baseline: its DEC documents are the source for this feature.

#### Blocks

- feat-6-contracts-openapi-pipeline

- feat-7-verification-architecture-tools

### Design Notes

The names of the install scripts have the format `TTT.MMM-NN-name.sh`. TTT.MMM is the number of the task in this plan. NN is the number of the step in the task. Each script has a header with the feature and the task, sets `set -euo pipefail`, can be operated again with no error, and does not need sudo. A `_common.sh` file has the shared functions. A README in the `bin` folder gives the sequence of the scripts.

Facts from the machine at 2026-11-03: JDK 11 is installed. Maven, pnpm and just are not installed. Node 24, Docker, gh, uv and corepack are installed. The agent has no sudo.

The prototypes are in the folder of feat-2-react-angular-visualization-spike. They are not part of the layout.

The JDK has the license GPL-2.0 with the Classpath exception. On 2026-11-03 the owner amended the DEC about licenses: the class Permitted has the row `GPL-2.0-only WITH Classpath-exception-2.0`. Task 100.110 must read the license file of the selected JDK build and must confirm that it has this license. The owner selected Eclipse Temurin 21 (an OpenJDK build from Eclipse Adoptium, LTS) on 2026-11-03. The version 21 is the LTS version that the owner selected. A later LTS version needs a new decision of the owner.

License table (the agent fills it in task 100.100 to 100.120, from the license file of each tool and not from memory):

| Tool | Use | License | Result |
|---|---|---|---|
| JDK: Eclipse Temurin 21 (selected by the owner) | build and run | expected GPL-2.0-only WITH Classpath-exception-2.0 (source: the page of Adoptium, not the license file of the download) | open until task 100.110 reads the license file |
| Maven | build | not checked | open |
| Node | build and run | not checked | open |
| pnpm | build | not checked | open |
| just | task runner | not checked | open |
| Commit message checker (not selected) | gate | not checked | open |
| SBOM tool (not selected) | gate | not checked | open |
| License check tool (not selected) | gate | not checked | open |

### Related Decisions

- DEC 870244cf-9bea-46bf-8ff2-fe030325743d: Use a Monorepo with Maven, pnpm, just and GitHub Actions
- DEC 361678a6-f941-473b-a058-1ba2bacf7d3d: Use a Test Pyramid and Blocking Gates for Verification
- DEC 84c37f7d-08cb-457d-8ab3-1db37dba9bc9: Use Only Open Source Libraries That Are Compatible With AGPL-3.0-only
- DEC a56f231b-d063-4bef-bbc8-3deb4daff76e: Use Conventional Commits, Feature Branches and a Definition of Done
- DEC cc4449cd-78fb-452a-904f-7efda89cf004: Set Limits for Coding Agents
- DEC 2468257f-cb4e-4f30-a8df-6fc1d86759ce: Keep One Source of Truth for Each Type of Fact
- DEC eb6e66ca-4ceb-46b5-9865-47e20a44674a: Write Documents in ASD-STE100 English
- TXT eff55a59-137b-40b0-8f7b-44c349aa923a: Engineering Handbook

### Task List

#### Phase 100: License Checks and Decisions

- [ ] Task 100.100: Read the license file of Maven, Node, pnpm and just, and write the result in the license table

- [ ] Task 100.110: Read the license file of the Eclipse Temurin 21 download (the owner selected it), confirm the license `GPL-2.0-only WITH Classpath-exception-2.0`, and write the result in the license table

- [ ] Task 100.120: Select the tools for the commit message check, the license check and the SBOM, read their license files, and write the results in the license table

#### Phase 110: Install Scripts

- [ ] Task 110.100: Write the file for the versions and the `_common.sh` file in the `bin` folder of this feature

- [ ] Task 110.110: Write the install scripts `TTT.MMM-NN-name.sh` for the JDK, Maven, pnpm (with corepack) and just. They use the home directory, check the checksums and can be operated again

- [ ] Task 110.120: Operate the scripts on the machine of the author, and write the installed versions in this plan

- [ ] Task 110.130: Write the README of the `bin` folder with the sequence of the scripts

#### Phase 120: Layout and Justfile

- [ ] Task 120.100: Make the directories of the layout with a short README in each

- [ ] Task 120.110: Write the `justfile` with the recipes for validation, license check, SBOM and commit check

- [ ] Task 120.120: Write NOTICE and CODEOWNERS (dfch is the owner of the DEC documents, the CI configuration, the thresholds and the list of licenses)

#### Phase 130: CI and Gates

- [ ] Task 130.100: Write the GitHub Actions workflow. Each job starts one `just` recipe

- [ ] Task 130.110: Write the gate for the specmgr validation of the changed documents

- [ ] Task 130.120: Write the gate for the commit messages (Conventional Commits with the feature identifier as scope)

- [ ] Task 130.130: Write the license gate with the list of permitted licenses, and the SBOM

- [ ] Task 130.140: Write the gate that finds a build command in a workflow that is not in the `justfile`

- [ ] Task 130.150: Write the instructions for the owner to set the branch protection, with the gates of this feature

#### Phase 140: Skill Suggestion

- [ ] Task 140.100: Write a suggestion for a skill about the names of scripts in the format `TTT.MMM-NN-name.sh`. The suggestion is a document in the folder of this feature. The owner decides where the skill goes

#### Phase 150: Review

- [ ] Task 150.100: Run all gates on a test pull request and write the result in this plan

- [ ] Task 150.110: The owner examines the license table and the open items

## Progress

### Current Status

**As of 2026-11-03**: The plan is written. Work has not started. The JDK vendor is selected: Eclipse Temurin 21. The next step is phase 100 (license checks). Branch: create `feat-5-foundation-monorepo-ci` from `dev` before the first change to files that are not documents.

### Blockers

- None for the start of phase 100. The JDK vendor is selected (Eclipse Temurin 21) and the license class is permitted since 2026-11-03. A person with competence in the law has not examined the new license class at this time.

### Updates

<!-- Newest entry first -- prepend new entries directly below this comment. -->

#### 2026-11-03 00:00:00.000Z - Handoff at the end of the session

The owner selected Eclipse Temurin 21 as the JDK. Work has not started. Nothing is pushed. The work of the session is in commits on the branch `dev`.

For the next agent:

1. Start with phase 100. Read the license file of each tool and not a web page or memory. Stop and tell the owner if a license is not clear.
2. The agent has no sudo. The install scripts must use the home directory only. Names: `TTT.MMM-NN-name.sh` in the `bin` folder of this feature (example: `110.110-01-install-jdk.sh`). Look at `/home/user/src/biz.dfch.LlmOps/.specmgr/feat/feat-0-screen-record/bin/` for the style (header comment, `set -euo pipefail`, `_common.sh`, can be operated again).
3. The machine has JDK 11 (Ubuntu build) and Node 24. Maven, pnpm and just are not installed. See Design Notes.
4. Use `specmgr_edit` for changes to a document. Do not change a status. An agent must not accept a DEC. The owner can give a permission for one time and for one change (for example, the permission for the license DEC on 2026-11-03).
5. Use the issue numbers for the FEAT names. Issues #5, #6 and #7 are the numbers of feat-5, feat-6 and feat-7. Get the number from `gh issue create`, and do not assume it.
6. Write documents in ASD-STE100 English. Use the asdste100 MCP. For a word check of many documents, give the work to a subagent. The script for the word check is in `.specmgr/feat/feat-3-process-policy-baseline/bin/500.120-01-ste-word-check.py` (a reference only, not a gate). Its paths are fixed for the machine of the author. The flag `--plans` makes it read the plans of the FEAT documents. Two more scripts are in the same folder: one for passive sentences and long sentences, and one for words with a conflict in the part of speech.
7. The STE check as a gate and the script for the register are on hold (decision of the owner on 2026-11-03). CI has no gate for them.
8. Make separate commits and use Conventional Commits with the feature as scope.

Open items that are not for the agent: the review of ACC-007 by dfch (feat-3), the register records of feat-3 that are not accepted, the review of the new license class by a person with competence in the law, and GitHub issue #4 (the French heading table belongs to specmgr).

#### 2026-11-03 00:00:00.000Z - License class for the JDK added to the DEC

The owner told the agent to amend the DEC about licenses, for one time. The class Permitted has the new row `GPL-2.0-only WITH Classpath-exception-2.0`. Task 100.110 changed: it now confirms the license in the file of the selected JDK build.

#### 2026-11-03 00:00:00.000Z - Plan written

The plan is written from the planning session of 2026-11-03. The owner selected three features for the toolchain, the format of the script names, and dfch as the owner in CODEOWNERS.

### Decisions Made

<!-- Newest entry first -- prepend new entries directly below this comment. -->

#### 2026-11-03 00:00:00.000Z - Three features for the toolchain

The toolchain is in three features: the foundation (this feature, issue #5), the contracts (issue #6) and the verification and architecture tools (issue #7). One feature with all tools has too many tasks for one pull request.

### Related PRs / Commits

- [Issue #5](https://github.com/dfch/biz.dfch.SpecMgrDemo/issues/5): this feature.

### More Information

GitHub issue #1 is the first design issue.
