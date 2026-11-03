---
classification: null
created: '2026-11-03T07:53:33.591+01:00'
id: feat-5-foundation-monorepo-ci
status: planning
type: feat
updated: '2026-11-03T11:58:31.769+01:00'
version: 1.0.0
---

# Feature: Foundation of the Monorepo, the Justfile and CI

## Plan

### Overview

This feature makes the base of the toolchain. It gives the layout of the monorepo, one `justfile` as the entry point, version pins for the tools, the CI workflow on GitHub Actions, and the first gates. The gates in this feature are the specmgr validation, the check of the commit messages, the check of the build commands and a first license check with an SBOM. It also has the install scripts for the tools on the machine of the author. The DEC documents about the monorepo, about verification and about licenses are the source. GitHub issue #5 is for this feature. The feature is planned and not started.

### Requirements

- REQ-001: The repository must have the layout that the DEC about the monorepo gives: `backend/`, `frontend/`, `contracts/`, `model/`, `terminology/`, `tools/`, `docs/` and `.specmgr/`. The folder `tools/` has the version file (`tools/versions.env`), the gate scripts (`tools/gates/`) and the license files (`tools/license/`). The install scripts for the machine of the author are not part of the layout. They stay in the `bin` folder of this feature, so that a new project that copies the layout does not get them.

- REQ-002: A `justfile` must be the one entry point for local work and for CI.

- REQ-003: The versions of the JDK, Maven, Node, pnpm and just must be in one file, `tools/versions.env`. The JDK and Node must be LTS versions. The install scripts and the CI workflow must read the versions from this file.

- REQ-004: Each tool must have a license check before the project uses it.

- REQ-005: CI must have a gate for the specmgr validation of the changed documents.

- REQ-006: CI must make an SBOM and must compare the licenses of all dependencies with a list of permitted licenses (`tools/license/permitted-licenses.txt`). The gate must stop the pull request if a license is not permitted or not known.

- REQ-007: A CODEOWNERS file must give dfch as the owner of these paths: the DEC documents (`/docs/dec/`), the CI configuration (`/.github/workflows/`), the `justfile`, `/tools/` (the version file, the gate scripts and the list of licenses), the thresholds (when they exist) and the CODEOWNERS file itself.

- REQ-008: The install scripts must put the tools in the home directory of the user and must not use sudo.

- REQ-009: Each CI job must start one `just` recipe.

- REQ-010: If a license of a tool is not clear, or has no class in the DEC about licenses, the work stops and the owner makes a decision.

- REQ-011: CI must have a gate for the commit messages.

- REQ-012: A NOTICE file must be in the repository. It gives the license of the project and the place of the license list and of the SBOM.

- REQ-013: The owner must have written instructions to set the branch protection with the gates of this feature.

- REQ-014: The owner must have a suggestion for a skill about the names of scripts in the format `TTT.MMM-NN-name.sh`.

### Acceptance Criteria

- [ ] ACC-001: The layout from REQ-001 is in the repository, and each folder has a short README. The `tools/` README tells where the install scripts are.

- [ ] ACC-002: `just --list` shows the recipes for validation, license check, SBOM, commit check and check of the build commands. Each CI job starts only a `just` recipe (REQ-002, REQ-009).

- [ ] ACC-003: In each workflow, each `run:` step is exactly `just <recipe>`, and the recipe is in the `justfile`. The only exception is the bootstrap step that installs `just`, and it is in the list of exceptions of the gate. The gate stops the pull request if a `run:` step does not obey this rule. The `uses:` steps must be the actions that are in the license table.

- [ ] ACC-004: The file `tools/versions.env` has the pins. The install scripts and the CI workflow read the versions from it. In a new shell, after the scripts operate, `java -version` shows Eclipse Temurin 21 (not the JDK 11 of the system), and Maven, Node, pnpm and just show the pinned versions.

- [ ] ACC-005: Each tool and each GitHub Action in the license table of this plan has the result of the check. A tool with a license that is not clear, or with no class in the DEC, is not in use.

- [ ] ACC-006: A pull request with a document that is not valid according to specmgr, or a commit message that is not correct, causes a failure in CI.

- [ ] ACC-007: CODEOWNERS and NOTICE are in the repository. CODEOWNERS has an entry for each path of REQ-007 that exists.

- [ ] ACC-008: The owner has set the branch protection with all the gates of this feature, one review, and the review of a code owner for the files in CODEOWNERS, or the plan shows the open item for the owner.

- [ ] ACC-009: The license gate, on a fixture list of licenses, stops for a license that is not permitted, stops for a license that is not known, stops for `GPL-2.0-only` with no exception, and does not stop for `GPL-2.0-only WITH Classpath-exception-2.0` and the other permitted licenses (REQ-006).

- [ ] ACC-010: The `sbom` recipe operates and writes the SBOM file at the path in the `justfile` (REQ-006). The test of the content with real dependencies is open until feat-6 gives the manifests.

- [ ] ACC-011: No script of this feature has the word `sudo` in a command, and the scripts operate for a user that has no sudo (REQ-008). A check in the `justfile` shows this.

- [ ] ACC-012: The instructions for the branch protection and the suggestion for the skill are documents in the folder of this feature (REQ-013, REQ-014).

### Scope

#### Included

- The layout, the `justfile`, the version file and the CI workflow.

- The install scripts in the `bin` folder of this feature.

- The gates for specmgr validation, commit messages, licenses, SBOM, build commands and `sudo` in scripts.

- CODEOWNERS and NOTICE.

- The instructions for the owner for the branch protection.

- A suggestion for a skill about the names of scripts.

#### Explicitly Out Of Scope

- The OpenAPI pipeline (feat-6-contracts-openapi-pipeline).

- Test tools, mutation tools and architecture tools (feat-7-verification-architecture-tools).

- Product code and the walking skeleton.

- The STE check as a gate and the script that validates the register (on hold, decision of the owner on 2026-11-03).

- Thresholds. The walking skeleton sets them from a measured baseline. The entry for the thresholds in CODEOWNERS is added then.

- The traceability gate and the security checks (gates 2 and 9 of DEC 361678a6-f941-473b-a058-1ba2bacf7d3d). No feature has them at this time (see Design Notes).

- The test of the license gate and of the SBOM with real dependencies. The Maven and pnpm manifests come from feat-6-contracts-openapi-pipeline. This feature tests the gate with a fixture list of licenses (ACC-009, ACC-010).

### Dependencies

#### Depends On

- FEAT feat-3-process-policy-baseline: its DEC documents are the source for this feature.

#### Blocks

- FEAT feat-6-contracts-openapi-pipeline

- FEAT feat-7-verification-architecture-tools

### Design Notes

The names of the install scripts have the format `TTT.MMM-NN-name.sh`. TTT.MMM is the number of the task in this plan. NN is the number of the step in the task. Each script has a header with the feature and the task, sets `set -euo pipefail`, can be operated again with no error, and does not need sudo. A `_common.sh` file has the shared functions. A README in the `bin` folder gives the sequence of the scripts. The style comes from the scripts of the sibling repository `biz.dfch.LlmOps` (folder `feat-0-screen-record/bin/`). This plan has the rules, so a missing sibling repository does not stop the work.

The install scripts are for the machine of the author only. CI does not use them. CI gets the tools with pinned setup actions that read the versions from `tools/versions.env`. The one bootstrap step that installs `just` is the only `run:` step that is not `just <recipe>`.

The version file has the version of each tool and the checksum of each download. The checksums come from the files that the vendor publishes with the release. The install script compares them with the checksum of the downloaded file. The file `tools/versions.env` is at repository level, because CI, feat-6 and feat-7 also read it.

The JDK comes first in the `PATH`. A script writes the file `~/.config/biz.dfch.SpecMgrDemo/env.sh` that sets `JAVA_HOME` and the `PATH` before the entries of the system, and adds one line that reads this file to the shell profile of the user, only if the line is not there. The script can be operated again with no change. The corepack shims go in a directory of the home directory (`corepack enable --install-directory`), so that no sudo is necessary. Node has its own install script, and the scripts do not use the Node 24 of the machine without a check of its version.

Facts from the machine at 2026-11-03: JDK 11 is installed. Maven, pnpm and just are not installed. Node 24, Docker, gh, uv and corepack are installed. The agent has no sudo. Node 24 is not confirmed as an LTS release. Task 100.100 confirms the LTS release from the release schedule of Node and pins it.

The prototypes are in the folder of feat-2-react-angular-visualization-spike. They are not part of the layout.

The JDK has the license GPL-2.0 with the Classpath exception. On 2026-11-03 the owner amended the DEC about licenses: the class Permitted has the row `GPL-2.0-only WITH Classpath-exception-2.0`. Task 100.110 must read each license file of the selected JDK build, including the files in the `legal/` folder of the distribution, and must confirm that the main license is this license. The DEC gives a class only for the main license. A license in the `legal/` folder with a different class is a stop-and-ask case. The owner selected Eclipse Temurin 21 (an OpenJDK build from Eclipse Adoptium, LTS) on 2026-11-03. The version 21 is the LTS version that the owner selected. A later LTS version needs a new decision of the owner.

The tool `just` is, as far as the author of this plan knows, under CC0-1.0. This is not in the DEC about licenses, and the author did not read the license file. If Task 100.100 shows this license, the gate treats it as not known. The work stops, and the owner decides about an amendment of the DEC or a DEC about the deviation (REQ-010).

The license gate reads the list `tools/license/permitted-licenses.txt` and the SBOM. Its fixtures for the test are in `tools/license/fixtures/`. The gate must match the complete license expression (DEC 84c37f7d-08cb-457d-8ab3-1db37dba9bc9).

The commit scope is the number of the feature, for example `feat(feat-5): ...` (the scope in the DEC and in the history). The name of the branch is the full identifier, `feat-5-foundation-monorepo-ci`. The gate for the commit messages checks the format and the scope. It does not check the name of the branch.

Gates with no feature at this time: the traceability check (gate 2) and the security checks (part of gate 9) of DEC 361678a6-f941-473b-a058-1ba2bacf7d3d. GitHub issue #8 is for them, and the owner makes a FEAT for it later. When a gate exists, Task 130.150 and the instructions for the branch protection must have it.

License table (the agent fills it in tasks 100.100 to 100.120, from the license file of each tool and not from memory):

| Tool | Use | License | Result |
|---|---|---|---|
| JDK: Eclipse Temurin 21 (selected by the owner) | build and run | expected GPL-2.0-only WITH Classpath-exception-2.0 (source: the page of Adoptium, not the license file of the download) | open until task 100.110 reads each license file |
| Maven | build | not checked | open |
| Node | build and run | not checked | open |
| pnpm | build | not checked | open |
| corepack | build | not checked | open |
| just | task runner | not checked (can be CC0-1.0, no class in the DEC) | open |
| specmgr | gate | not checked | open |
| GitHub Actions in the workflow (checkout and the setup actions, not selected) | CI | not checked | open |
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

- [ ] Task 100.100: Select the releases of Maven, Node (an LTS release, confirmed from the release schedule), pnpm and just. Read the license file of each, and write the result in the license table

- [ ] Task 100.105: Read the license file of corepack and of specmgr, and write the result in the license table

- [ ] Task 100.110: Read each license file of the Eclipse Temurin 21 download (the owner selected it), including the `legal/` folder. Confirm the main license `GPL-2.0-only WITH Classpath-exception-2.0`, and write the result in the license table

- [ ] Task 100.115: Select the GitHub Actions for the checkout and for the setup of the tools, read their license files, and write the results in the license table

- [ ] Task 100.120: Select the tools for the commit message check, the license check and the SBOM, read their license files, and write the results in the license table

- [ ] Task 100.130: Tell the owner about each license that has no class in the DEC about licenses (for example `just`), and wait for the decision of the owner

#### Phase 110: Install Scripts

- [ ] Task 110.100: Write the version file `tools/versions.env` (versions and checksums from the files of the vendors) and the `_common.sh` file in the `bin` folder of this feature

- [ ] Task 110.105: Write the install script for Node. It checks the version, and does not use the Node of the machine without this check

- [ ] Task 110.110: Write the install scripts `TTT.MMM-NN-name.sh` for the JDK, Maven, pnpm (with corepack in a directory of the home directory) and just. They use the home directory, check the checksums and can be operated again. One script writes `~/.config/biz.dfch.SpecMgrDemo/env.sh` (`JAVA_HOME` and `PATH`) and adds one line to the shell profile only if the line is not there

- [ ] Task 110.120: Operate the scripts on the machine of the author, check the versions in a new shell, and write the installed versions in this plan

- [ ] Task 110.130: Write the README of the `bin` folder with the sequence of the scripts

#### Phase 120: Layout and Justfile

- [ ] Task 120.100: Make the directories of the layout with a short README in each

- [ ] Task 120.110: Write the `justfile` with the recipes for validation, license check, SBOM, commit check, check of the build commands and check for `sudo`

- [ ] Task 120.120: Write NOTICE and CODEOWNERS with the paths of REQ-007 (dfch is the owner). The license list is at the path `tools/license/permitted-licenses.txt`, which is fixed in this plan, so the file can follow in Task 130.130

#### Phase 130: CI and Gates

- [ ] Task 130.100: Write the GitHub Actions workflow. Each job starts one `just` recipe. The tools come from the pinned setup actions with the versions from `tools/versions.env`

- [ ] Task 130.110: Write the gate for the specmgr validation of the changed documents

- [ ] Task 130.120: Write the gate for the commit messages (Conventional Commits with the feature number as scope, for example `feat(feat-5)`)

- [ ] Task 130.130: Write the license gate with the list `tools/license/permitted-licenses.txt`, and the SBOM

- [ ] Task 130.135: Test the license gate with the fixtures in `tools/license/fixtures/`: a license that is not permitted, a license that is not known, `GPL-2.0-only` with no exception, the complete expression with the Classpath exception, and a permitted license. Write the expected result of each

- [ ] Task 130.140: Write the gate for the build commands: each `run:` step must be `just <recipe>` with a recipe in the `justfile`, with the list of exceptions (the bootstrap step of `just`)

- [ ] Task 130.145: Write the check for `sudo` in the scripts and make it a recipe in the `justfile`

- [ ] Task 130.150: Write the instructions for the owner to set the branch protection: all gates of this feature, one review, and the review of a code owner for the files in CODEOWNERS. Add the gates that other features give later

#### Phase 140: Skill Suggestion

- [ ] Task 140.100: Write a suggestion for a skill about the names of scripts in the format `TTT.MMM-NN-name.sh`. The suggestion is a document in the folder of this feature. The owner decides where the skill goes

#### Phase 150: Review

- [ ] Task 150.100: Run all gates on test pull requests and write the result in this plan. Make one pull request that passes. Make one pull request for each failure that a gate must stop: a document that is not valid, a commit message that is not correct, a license that is not permitted, a license that is not known, and a `run:` step that is not `just <recipe>`. Write the expected result and the actual result of each

- [ ] Task 150.110: The owner examines the license table and the open items

## Progress

### Current Status

**As of 2026-11-03**: The plan is written and refined (see the update of 2026-11-03 09:58). Work has not started. The JDK vendor is selected: Eclipse Temurin 21. The next step is phase 100 (license checks). Branch: create `feat-5-foundation-monorepo-ci` from `dev` before the first change to files that are not documents.

### Blockers

- None for the start of phase 100. The JDK vendor is selected (Eclipse Temurin 21) and the license class is permitted since 2026-11-03. The owner told the agent on 2026-11-03 that the review of the new license class is done. DEC 84c37f7d-08cb-457d-8ab3-1db37dba9bc9 has an entry about this statement.
- Stop-and-ask case for phase 100: `just` can have the license CC0-1.0, which has no class in the DEC about licenses. If the license file shows this, the owner must decide (an amendment of the DEC or a DEC about the deviation). Task 100.130 is for this.
- Open item for the owner (not a blocker): the work of this plan and the earlier plans is in commits on `dev`, and DEC a56f231b-d063-4bef-bbc8-3deb4daff76e says that each change goes through a pull request. Documents on `dev` before the branch protection exists are a start exception that the DEC does not give. The owner must confirm it or make a rule.
- Open item for the owner (not a blocker): the traceability gate and the security checks have no feature at this time. [Issue #8](https://github.com/dfch/biz.dfch.SpecMgrDemo/issues/8) is for them. The owner makes a FEAT for it later.
- Open item for the owner (not a blocker): the CODEOWNERS entry for the thresholds is added when the walking skeleton makes them.

### Updates

<!-- Newest entry first -- prepend new entries directly below this comment. -->

#### 2026-11-03 10:58:28.000Z - Open items of the review closed

The owner told the agent: the commits go to `dev` before the branch protection exists (this is a start exception to DEC a56f231b-d063-4bef-bbc8-3deb4daff76e, for the documents of this plan only). The reviewer of the license row is dfch, and the date is 2026-11-03 (DEC 84c37f7d-08cb-457d-8ab3-1db37dba9bc9 has the entry). The agent made GitHub issue #8 for the traceability gate and the security checks.

#### 2026-11-03 09:58:03.000Z - Plan refined after the review

The owner told the agent to apply all the results of the review of the plan. The changes:

- The requirements REQ-002, REQ-004 and REQ-005 are split (new REQ-009, REQ-010, REQ-011), and REQ-012 to REQ-014 are new. ACC-009 to ACC-012 are new, and ACC-003, ACC-004, ACC-006 and ACC-008 are more exact.
- The layout has `tools/` for the version file, the gate scripts and the license files. The install scripts stay in the `bin` folder of this feature (the owner told the agent to extend the layout).
- CODEOWNERS has more paths: the `justfile`, `/tools/`, the workflows and CODEOWNERS itself (the owner told the agent to extend it).
- New tasks: 100.105, 100.115, 100.130, 110.105, 130.135 and 130.145. The tasks 100.100, 100.110, 110.100, 110.110, 120.110, 120.120, 130.100, 130.120, 130.140, 130.150 and 150.100 have a new text. No number changed.
- The links in Depends On and Blocks now have the tag `FEAT`, so that `list_references` finds them.
- The correction of the text of ACC-007 in the handoff (see below), and real times for the older entries (the times are the times of the commits).
- DEC a56f231b-d063-4bef-bbc8-3deb4daff76e (STE check on hold in the definition of done), DEC 84c37f7d-08cb-457d-8ab3-1db37dba9bc9 (the statement of the owner about the review of the license class), DEC 870244cf-9bea-46bf-8ff2-fe030325743d and the Engineering Handbook (the owner of each task, instead of "skeleton FEAT") have an update. The owner gave a permission for one time to change these documents.

#### 2026-11-03 09:45:52.000Z - Handoff at the end of the session

The owner selected Eclipse Temurin 21 as the JDK. Work has not started. Nothing is pushed. The work of the session is in commits on the branch `dev`.

For the next agent:

1. Start with phase 100. Read the license file of each tool and not a web page or memory. Stop and tell the owner if a license is not clear.
2. The agent has no sudo. The install scripts must use the home directory only. Names: `TTT.MMM-NN-name.sh` in the `bin` folder of this feature (example: `110.110-01-install-jdk.sh`). Look at `/home/user/src/biz.dfch.LlmOps/.specmgr/feat/feat-0-screen-record/bin/` for the style (header comment, `set -euo pipefail`, `_common.sh`, can be operated again).
3. The machine has JDK 11 (Ubuntu build) and Node 24. Maven, pnpm and just are not installed. See Design Notes.
4. Use `specmgr_edit` for changes to a document. Do not change a status. An agent must not accept a DEC. The owner can give a permission for one time and for one change (for example, the permission for the license DEC on 2026-11-03).
5. Use the issue numbers for the FEAT names. Issues #5, #6 and #7 are the numbers of feat-5, feat-6 and feat-7. Get the number from `gh issue create`, and do not assume it.
6. Write documents in ASD-STE100 English. Use the asdste100 MCP. For a word check of many documents, give the work to a subagent. The script for the word check is in `.specmgr/feat/feat-3-process-policy-baseline/bin/500.120-01-ste-word-check.py` (a reference only, not a gate). Its paths are relative to the repository root. Start it with `uv run --with biz-dfch-asdste100mcp python3 <script>`, so that it finds the base dictionary. The technical words are in the sibling repository `biz.dfch.AsdSte100TechnicalWords` (or set `STE_TECH_WORDS_DIR`). The flag `--plans` makes it read the plans of the FEAT documents. Two more scripts are in the same folder: one for passive sentences and long sentences, and one for words with a conflict in the part of speech.
7. The STE check as a gate and the script for the register are on hold (decision of the owner on 2026-11-03). CI has no gate for them.
8. Make separate commits and use Conventional Commits with the feature as scope.

Open items that are not for the agent: GitHub issue #4 (the French heading table belongs to specmgr). Update of 2026-11-03: dfch did the review of ACC-007 of feat-3-process-policy-baseline (the STE review worksheet, not the ACC-007 of this plan), and the owner told the agent that the review of the new license class is done.

#### 2026-11-03 09:32:10.000Z - License class for the JDK added to the DEC

The owner told the agent to amend the DEC about licenses, for one time. The class Permitted has the new row `GPL-2.0-only WITH Classpath-exception-2.0`. Task 100.110 changed: it now confirms the license in the file of the selected JDK build.

#### 2026-11-03 07:22:48.000Z - Plan written

The plan is written from the planning session of 2026-11-03. The owner selected three features for the toolchain, the format of the script names, and dfch as the owner in CODEOWNERS.

### Decisions Made

<!-- Newest entry first -- prepend new entries directly below this comment. -->

#### 2026-11-03 09:58:03.000Z - Extended CODEOWNERS and layout of `tools/`

The owner told the agent to extend CODEOWNERS. A gate is easy to disable if an author changes the `justfile`, a gate script, the version file or CODEOWNERS. The four categories of DEC cc4449cd-78fb-452a-904f-7efda89cf004 stay. This plan adds the `justfile`, `/tools/`, the workflows and CODEOWNERS itself. The owner also told the agent to extend the layout for the install scripts: `tools/` has the version file, the gate scripts and the license files. The install scripts stay in the `bin` folder of this feature, because their names have the number of a task of this plan, and a copy of the template does not need them.

#### 2026-11-03 09:58:03.000Z - STE check is not a requirement

The owner decided on 2026-11-03 that CI has no gate for the STE check and no script for the register at this time. The requirements REQ-005 and REQ-011 have only the specmgr validation and the commit messages.

#### 2026-11-03 07:22:48.000Z - Three features for the toolchain

The toolchain is in three features: the foundation (this feature, issue #5), the contracts (issue #6) and the verification and architecture tools (issue #7). One feature with all tools has too many tasks for one pull request.

### Related PRs / Commits

- [Issue #5](https://github.com/dfch/biz.dfch.SpecMgrDemo/issues/5): this feature.
- [Issue #8](https://github.com/dfch/biz.dfch.SpecMgrDemo/issues/8): the traceability gate and the security checks (no feature at this time).

### More Information

GitHub issue #1 is the first design issue.
