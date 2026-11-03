---
classification: null
created: '2026-11-03T07:53:33.591+01:00'
id: feat-5-foundation-monorepo-ci
status: planning
type: feat
updated: '2026-11-03T14:05:09.199+01:00'
version: 1.0.0
---

# Feature: Foundation of the Monorepo, the Justfile and CI

## Plan

### Overview

This feature makes the base of the toolchain. It gives the layout of the monorepo, one `justfile` as the entry point, version pins for the tools, the CI workflow on GitHub Actions, and the first gates. The gates in this feature are the specmgr validation, the check of the commit messages, the check of the build commands and a first license check with an SBOM. It also has the install scripts for the tools on the machine of the author. The DEC documents about the monorepo, about verification and about licenses are the source. GitHub issue #5 is for this feature. The feature is planned and not started.

### Requirements

- REQ-001: The repository must have the layout that the DEC about the monorepo gives: `backend/`, `frontend/`, `contracts/`, `model/`, `terminology/`, `tools/`, `docs/` and `.specmgr/`. The folder `tools/` has the version file (`tools/versions.env`), the gate scripts (`tools/gates/`) and the license files (`tools/license/`). The install scripts for the machine of the author are not part of the layout. They stay in the `bin` folder of this feature, so that a new project that copies the layout does not get them.

- REQ-002: A `justfile` must be the one entry point for local work and for CI.

- REQ-003: The versions of the JDK, Maven, Node, pnpm and just must be in one file, `tools/versions.env`. The JDK and Node must be LTS versions. The install scripts must read the versions from this file. The CI workflow must have the same versions, and a check must show that they are the same (a GitHub Action cannot read this file without a `run:` step).

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

- REQ-015: Each GitHub Action in a workflow must be pinned to a full commit SHA. A comment next to the SHA must give the name of the action and the tag of the release.

### Acceptance Criteria

- [x] ACC-001: The layout from REQ-001 is in the repository, and each folder has a short README. The `tools/` README tells where the install scripts are.

- [ ] ACC-002: `just --list` shows the recipes for validation, license check, SBOM, commit check and check of the build commands. Each CI job starts only a `just` recipe (REQ-002, REQ-009).

- [ ] ACC-003: In each workflow, each `run:` step is exactly `just <recipe>`, and the recipe is in the `justfile`. There is no exception: the action `extractions/setup-just` installs `just`, so no bootstrap `run:` step is necessary. The gate stops the pull request if a `run:` step does not obey this rule. The `uses:` steps must be the actions that are in the license table.

- [ ] ACC-004: The file `tools/versions.env` has the pins. The install scripts read the versions from it. The versions in the CI workflow are the same as in the file, and the `just` recipe for the pin check shows this (ACC-013). In a new shell, after the scripts operate, `java -version` shows Eclipse Temurin 21 (not the JDK 11 of the system), and Maven, Node, pnpm and just show the pinned versions.

- [ ] ACC-005: Each tool and each GitHub Action in the license table of this plan has the result of the check. A tool with a license that is not clear, or with no class in the DEC, is not in use.

- [ ] ACC-006: A pull request with a document that is not valid according to specmgr, or a commit message that is not correct, causes a failure in CI.

- [x] ACC-007: CODEOWNERS and NOTICE are in the repository. CODEOWNERS has an entry for each path of REQ-007 that exists.

- [ ] ACC-008: The owner has set the branch protection with all the gates of this feature, one review, and the review of a code owner for the files in CODEOWNERS, or the plan shows the open item for the owner.

- [ ] ACC-009: The license gate, on a fixture list of licenses, stops for a license that is not permitted, stops for a license that is not known, stops for `GPL-2.0-only` with no exception, and does not stop for `GPL-2.0-only WITH Classpath-exception-2.0` and the other permitted licenses (REQ-006). The gate does not parse license expressions by itself. It uses the library `license-expression` (see Design Notes). An expression is permitted if the library evaluates it as permitted: `OR` needs one permitted alternative (for example `MIT OR Apache-2.0`), `AND` needs all parts permitted, `WITH` is matched as a complete expression, and parentheses are handled by the library. The gate fails closed: an expression that the library cannot parse is "not known", and the gate stops. For a license name that is not an SPDX identifier (for example `Apache License, Version 2.0` in an SBOM), the gate uses a table of names. A name that is not in the table is "not known", and the gate stops.

- [ ] ACC-010: The `sbom` recipe operates and writes the SBOM file at the path in the `justfile` (REQ-006). The test of the content with real dependencies is open until feat-6 gives the manifests.

- [ ] ACC-011: No script of this feature has the word `sudo` in a command, and the scripts operate for a user that has no sudo (REQ-008). A check in the `justfile` shows this.

- [ ] ACC-012: The instructions for the branch protection and the suggestion for the skill are documents in the folder of this feature (REQ-013, REQ-014).

- [ ] ACC-013: In each workflow, each `uses:` step has a full commit SHA (40 hexadecimal characters) and not a tag or a branch. A comment on the same line gives the name of the action and the tag of the release, for example `uses: actions/checkout@<sha> # actions/checkout v7.0.1`. A `just` recipe checks this form, and checks that the versions of the tools in the workflow are the same as in `tools/versions.env` (REQ-003, REQ-015).

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

The install scripts are for the machine of the author only. CI does not use them. CI gets the tools with setup actions (see the table below). An action cannot read `tools/versions.env` without a `run:` step, and ACC-003 does not allow such a step. So the workflow has the versions as inputs of the actions, and a `just` recipe checks that they are the same as in `tools/versions.env` (decision of the owner on 2026-11-03: option A, one source of truth with a check). The action `extractions/setup-just` installs `just`, so the workflow has no bootstrap `run:` step.

Each action is pinned to a full commit SHA with a comment on the same line that gives the name and the release tag (REQ-015). Example: `uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # actions/checkout v7.0.1`. The SHAs in the table below are the commits of the tags on 2026-11-03. Task 130.100 must resolve them again with `git ls-remote` before it writes them. The action `extractions/setup-just` calls `extractions/setup-crate`, so the workflow has this second action in use too, but only as a part of the first. The pin of the first action fixes the second one.

For the Maven version, the Maven Wrapper (`mvnw`) is a choice for feat-6-contracts-openapi-pipeline, when `pom.xml` exists. The wrapper pins Maven in the repository, and a local run and a CI run then use the same Maven.

License expressions (decision on 2026-11-03, after a question of the owner): an own parser for `OR`, `AND`, `WITH` and parentheses is error prone. The license gate uses the library `license-expression` (Apache-2.0, a dependency of the gate that is a library of a tool and not of the product), which parses SPDX expressions. The gate has one small function that evaluates the parsed tree against the list of permitted licenses (`OR` is any, `AND` is all, a license with `WITH` is one symbol that must be in the list as a complete expression). The gate fails closed: it stops for each expression that the library cannot parse, and for each name that is not in the table of names. The gate runs with `uv run --with license-expression==<version>`, with the version in `tools/versions.env`. The alternative, a list of compound expressions that are permitted one by one, needs a manual entry for each expression of each transitive dependency, and the agent does not recommend it.

Tools for the gates (decision of the owner on 2026-11-03). The commit message gate and the license gate are scripts of this project in `tools/gates/`, and need no tool of another vendor. The gate for the commit messages reads the format `type(feat-N): subject`. The license gate reads the SBOM in the CycloneDX format and the list `tools/license/permitted-licenses.txt`. The SBOM for Maven comes from `cyclonedx-maven-plugin` 2.9.3. The SBOM for pnpm comes from `@cyclonedx/cdxgen` 12.9.0 (the latest release on npm; the GitHub page of the project shows v13.6.0, which is not on npm under this name, so the agent pins 12.9.0). `@cyclonedx/cyclonedx-node-pnpm` is not in use because its repository is archived. `mojohaus/license-maven-plugin` is not in use because it covers Maven only. The library `license-expression` is in use for the license gate (see above). The specmgr gate needs `uv`, and the action `astral-sh/setup-uv` installs it.

The version file has the version of each tool and the checksum of each download. The checksums come from the files that the vendor publishes with the release. The install script compares them with the checksum of the downloaded file. The file `tools/versions.env` is at repository level, because CI, feat-6 and feat-7 also read it.

The JDK comes first in the `PATH`. A script writes the file `~/.config/biz.dfch.SpecMgrDemo/env.sh` that sets `JAVA_HOME` and the `PATH` before the entries of the system, and adds one line that reads this file to the shell profile of the user, only if the line is not there. The script can be operated again with no change. Node 26.13.0 has no corepack (its `bin/` has `node`, `npm` and `npx` only), although its `LICENSE` file still lists corepack. So pnpm comes from the standalone release on GitHub (`pnpm-linux-x64.tar.gz`), and the checksum is the digest of the GitHub release. Node has its own install script, and the scripts do not use the Node 24 of the machine.

Facts from the machine at 2026-11-03: JDK 11 is installed. Maven, pnpm and just are not installed. Node 24, Docker, gh, uv and corepack are installed. The agent has no sudo. Node 24 is not confirmed as an LTS release. Task 100.100 confirms the LTS release from the release schedule of Node and pins it.

Installed on the machine of the author on 2026-11-03 (Task 110.120), in `~/.local/opt/biz.dfch.SpecMgrDemo/`: Eclipse Temurin 21.0.13+9 (`jdk-21.0.13_9`), Apache Maven 3.10.0, Node v26.13.0, pnpm 12.16.1 and just 1.59.0. `110.110-06-verify-tools.sh` shows that each tool in the PATH is the pinned version and comes from this folder. A new interactive shell (`bash -ic`) shows the JDK 21 (the system JDK 11 is not changed), and `java`, `mvn`, `node`, `pnpm` and `just` are the pinned versions (ACC-004 for the local machine). The scripts added two lines to `~/.bashrc`. The machine has its own uv 0.12.5, and the pin 0.13.7 in `tools/versions.env` is for CI.

The prototypes are in the folder of feat-2-react-angular-visualization-spike. They are not part of the layout.

The JDK has the license GPL-2.0 with the Classpath exception. On 2026-11-03 the owner amended the DEC about licenses: the class Permitted has the row `GPL-2.0-only WITH Classpath-exception-2.0`. Task 100.110 must read each license file of the selected JDK build, including the files in the `legal/` folder of the distribution, and must confirm that the main license is this license. The DEC gives a class only for the main license, and under rule A (see below) the licenses in the `legal/` folder are not checked. The owner selected Eclipse Temurin 21 (an OpenJDK build from Eclipse Adoptium, LTS) on 2026-11-03. The version 21 is the LTS version that the owner selected. A later LTS version needs a new decision of the owner.

The tool `just` has the license CC0-1.0 (read in Task 100.100). The owner added `CC0-1.0` to the class Permitted on 2026-11-03.

Rule A for tools (decision of the owner on 2026-11-03, after a first choice of rule B): for a tool that does not go to users (JDK, Maven, Node, pnpm, just, specmgr and the tools in CI), the license check covers the main license of the tool. The licenses of the parts that the tool bundles are not checked. For a library that goes to users, the gate checks the license of each dependency, with no exception. DEC 84c37f7d-08cb-457d-8ab3-1db37dba9bc9 does not yet have this rule in its text (its Consequences say that the rule includes the tools). The change needs a permission of the owner (see Blockers).

The license gate reads the list `tools/license/permitted-licenses.txt` and the SBOM. Its fixtures for the test are in `tools/license/fixtures/`. The gate must match the complete license expression (DEC 84c37f7d-08cb-457d-8ab3-1db37dba9bc9).

The commit scope is the number of the feature, for example `feat(feat-5): ...` (the scope in the DEC and in the history). The name of the branch is the full identifier, `feat-5-foundation-monorepo-ci`. The gate for the commit messages checks the format and the scope. It does not check the name of the branch.

Gates with no feature at this time: the traceability check (gate 2) and the security checks (part of gate 9) of DEC 361678a6-f941-473b-a058-1ba2bacf7d3d. GitHub issue #8 is for them, and the owner makes a FEAT for it later. When a gate exists, Task 130.150 and the instructions for the branch protection must have it.

License table (the agent filled it in tasks 100.100 to 100.120, from the license file of each tool and not from memory. Under rule A, the licenses of the parts that a tool or an action bundles are not checked. The GitHub Actions of `actions/*` are JavaScript actions with their dependencies in `dist/`):

| Tool | Use | License | Result |
|---|---|---|---|
| JDK: Eclipse Temurin 21.0.13+9 (selected by the owner) | build and run | GPL-2.0-only WITH Classpath-exception-2.0. Source: `legal/java.base/LICENSE` of the download. It has GPL version 2 and the text of the "Classpath" exception. The sha256 of the download is the same as the value of Adoptium | Permitted (main license, rule A of the owner). The folder `legal/` has 36 notices of third-party parts and an Assembly exception text in each of 69 modules. Under rule A the gate does not check them, because the JDK does not go to users |
| Maven 3.10.0 (candidate) | build | Apache-2.0. Source: `LICENSE` of the download. `lib/*.license`: Apache-2.0, BSD-3-Clause (asm, jansi, jline), MIT (slf4j), public domain (aopalliance), EPL-2.0 (sisu), CDDL-1.1 (javax.annotation-api) | Permitted (main license, rule A of the owner). The bundled EPL-2.0 (class Review) and CDDL-1.1 are not checked under rule A, because Maven does not go to users |
| Node 26.13.0 (selected by the owner on 2026-11-03: LTS "Lithium") | build and run | MIT. Source: `LICENSE` of the download. It lists 43 bundled components (see the inventory in Design Notes) | Permitted (main license, rule A of the owner). The bundled Unicode-3.0, Zlib, Artistic-2.0 and BlueOak-1.0.0 are also in the class Permitted since 2026-11-03 11:22. The other bundled licenses are not checked under rule A |
| pnpm 12.16.1 (standalone release `pnpm-linux-x64.tar.gz`, sha256 `565ff81174a14f6f7bd5d84c1b17e51031a80230d370a1fe24be5d16bd02a825`, the same as the digest on GitHub) | build | MIT. Source: `LICENSE` of the repository at the tag v12.16.1. The npm package has no `LICENSE` file, only the field `license` in `package.json` and `THIRD-PARTY-NOTICES.md` (BSD-2-Clause, ISC) | Permitted |
| corepack | not in use | MIT (the corepack part of the `LICENSE` of Node 26.13.0). Node 26.13.0 does not ship corepack, and no script installs it | Not in use. The row is for information |
| just 1.59.0 (candidate) | task runner | CC0-1.0. Source: `LICENSE` of the download | Permitted since 2026-11-03 11:17 (the DEC has `CC0-1.0`). The legal review of this entry is open |
| specmgr 0.38.0 | gate | AGPL-3.0-or-later. Source: `licenses/LICENSE` in the dist-info of the installed package | Permitted (the DEC has `AGPL-3.0-or-later` since 2026-11-03 11:17) |
| Action `actions/checkout` v7.0.1, SHA `3d3c42e5aac5ba805825da76410c181273ba90b1` | CI | MIT. Source: `LICENSE` at this commit | Permitted |
| Action `actions/setup-java` v6.1.0, SHA `b843ebf9b913146b38da2eaa7aeddf76074ae1ad` | CI | MIT. Source: `LICENSE` at this commit | Permitted |
| Action `actions/setup-node` v7.1.0, SHA `949feb2413d6458794dcd2491c4babbbce0c15c1` | CI | MIT. Source: `LICENSE` at this commit | Permitted |
| Action `pnpm/action-setup` v6.1.0, SHA `ea17c68df8912ef543352723c149a84f56e3d413` | CI | MIT. Source: `LICENSE` at this commit | Permitted |
| Action `actions/upload-artifact` v7.0.2, SHA `cf430e030ddbb5b0abf93d22962f4752f3646cd9` | CI (SBOM file) | MIT. Source: `LICENSE` at this commit | Permitted |
| Action `astral-sh/setup-uv` v10.3.3, SHA `68559e99cc807c1eb7e9238fd43a15bba460eec2` | CI (for specmgr) | MIT. Source: `LICENSE` at this commit | Permitted |
| Action `extractions/setup-just` v4 (the same commit as v4.0.0), SHA `53165ef7e734c5c07cb06b3c8e7b647c5aa16db3` | CI | MIT OR Apache-2.0. Source: `LICENSE-MIT`, `LICENSE-APACHE` and the license part of the `README.md` ("either at your option") at this commit. The GitHub metadata shows only Apache-2.0 | Permitted (both alternatives are permitted) |
| Action `extractions/setup-crate` v2.0.0, SHA `0551596312d4008a6dfbc4d3c38fa20eaef46d2d` (called by `setup-just`) | CI | MIT OR Apache-2.0. Source: `LICENSE-MIT`, `LICENSE-APACHE` and the `README.md` at this commit | Permitted |
| uv (latest release on GitHub: 0.13.7; version for Task 110.100) | CI (for specmgr) | MIT OR Apache-2.0. Source: `LICENSE-MIT`, `LICENSE-APACHE` and the `README.md` at the release tag | Permitted |
| Commit message gate (script of this project) | gate | AGPL-3.0-only (project code). No tool of another vendor | Permitted (no check necessary) |
| License gate (script of this project) | gate | AGPL-3.0-only (project code) | Permitted (no check necessary) |
| Library `license-expression` 30.4.4 (used by the license gate) | gate | Apache-2.0. Source: `licenses/apache-2.0.LICENSE` and `licenses/NOTICE` in the wheel (sha256 `421788fdcadb41f049d2dc934ce666626265aeccefddd25e162a26f23bcbf8a4`, the same as on PyPI). The wheel has a data file (`scancode-licensedb-index.json`) under CC-BY-4.0 (`data/cc-by-4.0.LICENSE`). Under rule A, the CC-BY-4.0 data file is not checked | Permitted |
| Library `boolean.py` 5.0 (a dependency of `license-expression`) | gate | BSD-2-Clause. Source: `licenses/LICENSE.txt` in the wheel (sha256 `ef28a70bd43115208441b53a045d1549e2f0ec6e3d08a9d142cbc41c1938e8d9`, the same as on PyPI) | Permitted |
| SBOM for Maven: `cyclonedx-maven-plugin` 2.9.3 | gate | Apache-2.0. Source: `LICENSE` in the repository at the tag commit `93e97e1c7e50b08cbba62549c2ed88c95202ed62`, and `<licenses>` in the POM. The jar has no license file. sha256 of the jar: `c452d5eebe28bc86bef2e7c72d129f04f60877bef843eac8120f01fb655be293` (the same as the value on Maven Central) | Permitted |
| SBOM for pnpm: `@cyclonedx/cdxgen` 12.9.0 | gate | Apache-2.0. Source: `package/LICENSE` in the npm package. The integrity value of the package is `sha512-+LWBiyTgdSWdprdsA7xpNEhD9NV/Wo3TvqaVYQHjP3kEeNEZTV+08U8CYh+P2+2CHycwKFWHhtSREN+p/r6Sgw==`. The package has 29 dependencies, and under rule A they are not checked | Permitted |

Inventory of the bundled licenses of the JDK, Maven and Node (2026-11-03). The owner first chose rule B (each bundled license needs a class) and then rule A (only the main license of a tool is checked). Under rule A the inventory is for information. It is the list that rule B needed, and it helps if a tool goes to users later. On 2026-11-03 11:22 the owner gave a permission to add the five rows that the agent proposed as Permitted (Zlib, Unicode-3.0, Unicode-DFS-2016, BlueOak-1.0.0, Artistic-2.0), and the agent added them. The other rows are not in the DEC. "Proposal" is the view of the agent. The legal classes are for a person with competence in the law.

| License (SPDX name where one exists) | Found in | Proposal |
|---|---|---|
| Zlib | Node (zlib), JDK (zlib) | Permitted |
| Unicode-3.0 | Node (ICU) | Permitted |
| Unicode-DFS-2016 | JDK (CLDR, Unicode Character Database, ICU4J) | Permitted |
| BlueOak-1.0.0 | Node (minimatch) | Permitted |
| Artistic-2.0 | Node (npm) | Permitted (the owner decides) |
| Public domain with no SPDX name (aopalliance, SipHash, HdrHistogram) | Maven, Node, JDK | Owner decides. CC0-1.0 is in the DEC, and HdrHistogram also offers BSD-2-Clause |
| CDDL-1.1 | Maven (javax.annotation-api) | Review (a DEC about the deviation) |
| EPL-2.0 | Maven (sisu) | Review (the class in the DEC). A DEC about the deviation is necessary |
| GPL-3.0-or-later WITH Autoconf-exception | Node (ICU, configuration scripts) | Owner decides. The text is for build files, not for the program |
| GPL-3.0 with the GCC runtime library exception | JDK (libgcc, libstdc++) | Owner decides |
| MPL-2.0 | JDK (Public Suffix List, data) | Review (the class in the DEC). A DEC about the deviation is necessary |
| FreeType (FTL or GPL-2.0, a choice), IJG, Libpng, W3C Software Notice, Old MIT (HarfBuzz), Mesa (MIT style), PC/SC Lite (BSD style), jQuery and jQuery UI (MIT) | JDK | Owner decides, or "Permitted" for the licenses of the MIT and BSD kind |
| Cryptix General License, Eastman Kodak Notice, OASIS PKCS #11 License, IAIK License, CUP Parser Generator License, Dynalink (BSD-3-Clause) | JDK | Owner decides. These have no SPDX name or an unusual text |
| Assembly exception text (in each of 69 JDK modules) | JDK | Owner decides. The DEC row for the Classpath exception says that the Assembly exception is not in the row |

The JDK, Maven and Node are build and run tools. None of them goes to users. The rule B list is long because of the JDK. The agent read every block of the Node license and every `lib/*.license` file of Maven. For the JDK, the agent read the first lines of each of the 36 notices, and not the full text.

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

- [x] Task 100.100: Select the releases of Maven, Node (an LTS release, confirmed from the release schedule), pnpm and just. Read the license file of each, and write the result in the license table

- [x] Task 100.105: Read the license file of corepack and of specmgr, and write the result in the license table

- [x] Task 100.110: Read each license file of the Eclipse Temurin 21 download (the owner selected it), including the `legal/` folder. Confirm the main license `GPL-2.0-only WITH Classpath-exception-2.0`, and write the result in the license table

- [x] Task 100.115: Select the GitHub Actions for the checkout and for the setup of the tools, read their license files, and write the results in the license table

- [x] Task 100.120: Select the tools for the commit message check, the license check and the SBOM, read their license files, and write the results in the license table

- [x] Task 100.130: Tell the owner about each license that has no class in the DEC about licenses (for example `just`), and wait for the decision of the owner

#### Phase 110: Install Scripts

- [x] Task 110.100: Write the version file `tools/versions.env` (versions and checksums from the files of the vendors, for the JDK, Maven, Node, pnpm, just, uv, `cyclonedx-maven-plugin`, `@cyclonedx/cdxgen` and `license-expression`; read the license file of `license-expression` and of `boolean.py` in the release) and the `_common.sh` file in the `bin` folder of this feature

- [x] Task 110.105: Write the install script for Node. It checks the version, and does not use the Node of the machine without this check

- [x] Task 110.110: Write the install scripts `TTT.MMM-NN-name.sh` for the JDK, Maven, pnpm (the standalone release, because Node 26 has no corepack) and just. They use the home directory, check the checksums and can be operated again. One script writes `~/.config/biz.dfch.SpecMgrDemo/env.sh` (`JAVA_HOME` and `PATH`) and adds one line to the shell profile only if the line is not there

- [x] Task 110.120: Operate the scripts on the machine of the author, check the versions in a new shell, and write the installed versions in this plan

- [x] Task 110.130: Write the README of the `bin` folder with the sequence of the scripts

#### Phase 120: Layout and Justfile

- [x] Task 120.100: Make the directories of the layout with a short README in each

- [x] Task 120.110: Write the `justfile` with the recipes for validation, license check, SBOM, commit check, check of the build commands and check for `sudo`

- [x] Task 120.120: Write NOTICE and CODEOWNERS with the paths of REQ-007 (dfch is the owner). The license list is at the path `tools/license/permitted-licenses.txt`, which is fixed in this plan, so the file can follow in Task 130.130

#### Phase 130: CI and Gates

- [ ] Task 130.100: Write the GitHub Actions workflow. Each job starts one `just` recipe. The tools come from the setup actions of the license table. Each action is pinned to a full commit SHA with a comment (name and release tag, REQ-015). Resolve the SHAs again with `git ls-remote` before writing them. The versions are inputs of the actions, and they are the same as in `tools/versions.env`

- [ ] Task 130.110: Write the gate for the specmgr validation of the changed documents

- [ ] Task 130.120: Write the gate for the commit messages (Conventional Commits with the feature number as scope, for example `feat(feat-5)`)

- [ ] Task 130.130: Write the license gate with the list `tools/license/permitted-licenses.txt`, and the SBOM. The gate uses the library `license-expression` for the expressions, and fails closed

- [ ] Task 130.135: Test the license gate with the fixtures in `tools/license/fixtures/`: a license that is not permitted, a license that is not known, `GPL-2.0-only` with no exception, the complete expression with the Classpath exception, a permitted license, an expression with `OR` and one permitted alternative (for example `MIT OR Apache-2.0`), an expression with `OR` and no permitted alternative, an expression with `AND` (all permitted, and one not permitted), an expression with parentheses and `WITH` (for example `(MIT OR GPL-2.0-only) AND Apache-2.0`), an expression that cannot be parsed, and a license name that is not an SPDX identifier (one in the table of names, one not in the table). Write the expected result of each

- [ ] Task 130.140: Write the gate for the build commands: each `run:` step must be `just <recipe>` with a recipe in the `justfile`. There is no list of exceptions

- [ ] Task 130.142: Write the check for the pins, as a recipe in the `justfile`: each `uses:` step has a full commit SHA and a comment with the name and the release tag (ACC-013), and the versions of the tools in the workflow are the same as in `tools/versions.env`

- [ ] Task 130.145: Write the check for `sudo` in the scripts and make it a recipe in the `justfile`

- [ ] Task 130.150: Write the instructions for the owner to set the branch protection: all gates of this feature, one review, and the review of a code owner for the files in CODEOWNERS. Add the gates that other features give later

#### Phase 140: Skill Suggestion

- [ ] Task 140.100: Write a suggestion for a skill about the names of scripts in the format `TTT.MMM-NN-name.sh`. The suggestion is a document in the folder of this feature. The owner decides where the skill goes

#### Phase 150: Review

- [ ] Task 150.100: Run all gates on test pull requests and write the result in this plan. Make one pull request that passes. Make one pull request for each failure that a gate must stop: a document that is not valid, a commit message that is not correct, a license that is not permitted, a license that is not known, and a `run:` step that is not `just <recipe>`. Write the expected result and the actual result of each

- [ ] Task 150.110: The owner examines the license table and the open items

## Progress

### Current Status

**As of 2026-11-03**: The plan is written and refined (see the update of 2026-11-03 09:58). Phase 100 is done (Tasks 100.100 to 100.130): the licenses of all tools, actions and gate tools are read, and all of them are permitted. The owner chose Node 26.13.0 (LTS) and rule A for the licenses of tools (only the main license). Rule A is now in the text of DEC 84c37f7d-08cb-457d-8ab3-1db37dba9bc9. The gate tools are two scripts of this project (commit messages and licenses), `cyclonedx-maven-plugin` 2.9.3 and `@cyclonedx/cdxgen` 12.9.0 for the SBOM. The actions are pinned to full commit SHAs with a comment. Phase 110 is done (Tasks 110.100 to 110.130): `tools/versions.env` and the install scripts are written and were run on the machine of the author, and all five tools have the pinned versions (see Design Notes). The work is on the branch `feat-5-foundation-monorepo-ci`. Phase 120 is done (Tasks 120.100 to 120.120): the layout with READMEs, the `justfile`, NOTICE and `.github/CODEOWNERS` are written (ACC-001 and ACC-007 are ticked). Each gate recipe in the `justfile` stops with the message "NOT IMPLEMENTED" until its script exists. The next step is phase 130 (CI and gates). Branch: create `feat-5-foundation-monorepo-ci` from `dev` before the first change to files that are not documents.

### Blockers

- None for the start of phase 100. The JDK vendor is selected (Eclipse Temurin 21) and the license class is permitted since 2026-11-03. The owner told the agent on 2026-11-03 that the review of the new license class is done. DEC 84c37f7d-08cb-457d-8ab3-1db37dba9bc9 has an entry about this statement.
- Open item for the owner (not a blocker): a person who has competence in the law must examine the entries that the agent added to the class Permitted of DEC 84c37f7d-08cb-457d-8ab3-1db37dba9bc9 on 2026-11-03: `CC0-1.0`, `Zlib`, `Unicode-3.0`, `Unicode-DFS-2016`, `BlueOak-1.0.0` and `Artistic-2.0`. The review of the Classpath row is done (dfch, 2026-11-03).
- Open item for the agent: the GitHub page of `cdxgen` shows v13.6.0, but npm has 12.9.0 as the latest release. Task 130.130 must check again which version is correct, and must not change the pin without a check of the license.
- No deviation DEC is necessary at this time. Under rule A, the EPL-2.0 in Maven and the MPL-2.0 in the JDK are not checked. If a deviation is necessary later, the owner wants one DEC for all deviations (see the update of 2026-11-03 11:22).
- Resolved on 2026-11-03: `just` (CC0-1.0 is in the class Permitted) and specmgr (`AGPL-3.0-or-later` is in the class Permitted) are not a blocker. pnpm and corepack (MIT) were not a blocker. The legal review of the CC0-1.0 entry is open.
- Open item for the owner (not a blocker): the traceability gate and the security checks have no feature at this time. [Issue #8](https://github.com/dfch/biz.dfch.SpecMgrDemo/issues/8) is for them. The owner makes a FEAT for it later.
- Open item for the owner (not a blocker): the CODEOWNERS entry for the thresholds is added when the walking skeleton makes them.
- Open item for the owner (not a blocker): NOTICE has no copyright line. Add one if the project needs it. The syntax of `.github/CODEOWNERS` can be checked only after a push to the default branch (`gh api repos/dfch/biz.dfch.SpecMgrDemo/codeowners/errors`).

### Updates

<!-- Newest entry first -- prepend new entries directly below this comment. -->

#### 2026-11-03 13:04:44.000Z - Layout, justfile, NOTICE and CODEOWNERS (phase 120)

The owner had no more questions, and the agent continued. The agent did this:

1. Layout (Task 120.100): `backend/`, `frontend/`, `contracts/`, `model/`, `tools/gates/`, `tools/license/fixtures/` are new. A short README is in each layout folder, also in the folders that existed (`docs/`, `terminology/`, `.specmgr/`). The README of an empty folder says that it is empty and which feature fills it. The README of `tools/` tells where the install scripts are (ACC-001). The specmgr tools still list all features with no error.
2. `justfile` (Task 120.110): the recipes are `validate`, `commit-check`, `sbom`, `license-check`, `check-workflows`, `check-pins`, `check-sudo` and `verify-tools`. `just --list` shows them. A private recipe `_gate` starts the script `tools/gates/<name>` and stops with "NOT IMPLEMENTED" and the number of the task if the script does not exist. The agent ran each recipe: all fail with exit code 1, and none passes because a script is missing. A test script showed that the arguments reach the script. `just verify-tools` works. The file obeys `just --fmt`. The folder `build/` (the SBOM files) is in `.gitignore`.
3. Design choices of the agent in the `justfile`: the recipes `validate` and `commit-check` compare with the branch `origin/dev` (the variable `base`), and `license-check` depends on `sbom`. Tasks 130.110 to 130.145 must write the scripts with these arguments, or change the `justfile`.
4. NOTICE (Task 120.120): it gives the license AGPL-3.0-only, the place of the license list and the place of the SBOM. It has no copyright line, because the text of a copyright line is for the owner.
5. CODEOWNERS is `.github/CODEOWNERS` with the owner `@dfch` for `/docs/dec/`, `/.github/workflows/`, `/.github/CODEOWNERS`, `/justfile` and `/tools/`. `/.github/workflows/` does not exist yet. The agent could not check the file with GitHub, because the check works only for the default branch after a push.

Not done: ACC-002 stays open, because no CI job exists yet. The `tools/versions.env` check for the workflow (Task 130.142) is not written.

#### 2026-11-03 12:00:37.000Z - Install scripts written and run (phase 110), license expressions

The owner asked how the license gate must handle complex license expressions, and agreed to continue on a feature branch. The agent did this:

1. License expressions: an own parser for `OR`, `AND`, `WITH` and parentheses is error prone. The plan now uses the library `license-expression` 30.4.4 (Apache-2.0, with `boolean.py` 5.0, BSD-2-Clause). The gate has one small function that evaluates the parsed tree against the permitted list, and fails closed. ACC-009, Task 130.130 and Task 130.135 have this. The agent read the license files in both wheels.
2. Branch: the agent made the branch `feat-5-foundation-monorepo-ci` from `dev`. The work of phase 110 is on this branch, and the commits go through a pull request.
3. `tools/versions.env` has the pins and the checksums. Each checksum is the value that the vendor publishes, and the agent compared it with the download.
4. Discrepancy: Node 26.13.0 has no corepack, so the plan to install pnpm with corepack did not work. The agent used the standalone pnpm release from GitHub (the sha256 is the same as the digest on GitHub). The corepack row in the license table is "not in use".
5. The scripts `110.105-01` and `110.110-01` to `110.110-06` install Node, the JDK, Maven, pnpm and just, write `~/.config/biz.dfch.SpecMgrDemo/env.sh`, add two lines to `~/.bashrc`, and verify the versions. The agent tested the failure paths in a copy with a wrong checksum and with a missing variable: each stops with an error and leaves no temporary files. The agent found and fixed one error in `_common.sh` (the cleanup function made the verify script exit with code 1 after a correct result).
6. The scripts run again with no change (the second run of each script made no change to the files). A new interactive shell shows the JDK 21, and the system JDK 11 is not changed.

Open: the `just` recipes and the check for `sudo` (Task 130.145) are not written yet. The scripts do not have the word `sudo`.

#### 2026-11-03 11:48:13.000Z - Actions and gate tools selected, DEC changed for rule A (Tasks 100.115, 100.120)

The owner agreed to the suggestions of the agent and to the change of the DEC. The agent did this:

1. DEC 84c37f7d-08cb-457d-8ab3-1db37dba9bc9: the first bullet in Consequences has rule A, the option in Considered Options says one register DEC for all deviations, and More Information has a paragraph about the register. The Decision Outcome and the class table are not changed. The DEC has an Updates entry.
2. Task 100.115: the agent resolved each tag to a commit SHA with `git ls-remote` and read the `LICENSE` file at that commit. The actions are `actions/checkout`, `actions/setup-java`, `actions/setup-node`, `actions/upload-artifact`, `pnpm/action-setup`, `astral-sh/setup-uv` (all MIT) and `extractions/setup-just` with `extractions/setup-crate` (MIT OR Apache-2.0). `extractions/setup-just` installs `just`, so there is no bootstrap `run:` step, and ACC-003 has no exception. `setup-uv` is new in the plan, because the specmgr gate needs `uv`.
3. Pin form (owner): a full commit SHA, and a comment on the same line with the name of the action and the release tag (REQ-015, ACC-013, Task 130.142).
4. Task 100.120: the commit message gate and the license gate are scripts of this project. The SBOM tools are `cyclonedx-maven-plugin` 2.9.3 (Apache-2.0) and `@cyclonedx/cdxgen` 12.9.0 (Apache-2.0). The pin check recipe in the `justfile` shows that the versions in the workflow are the same as in `tools/versions.env` (option A).
5. The license gate must handle `OR` expressions (permitted if one alternative is permitted) and names that are not SPDX identifiers (ACC-009, Task 130.135). `extractions/setup-just` and `uv` have `MIT OR Apache-2.0`, so the gate needs this rule.

Not done: the agent did not install a tool and did not write a version file. The cdxgen page on GitHub and npm show different latest versions (see Blockers).

#### 2026-11-03 11:22:16.000Z - Rule A for tools, five licenses added, one DEC for deviations

The owner decided:

1. Permission granted to add the five rows that the agent proposed as Permitted. The agent added `Zlib`, `Unicode-3.0`, `Unicode-DFS-2016`, `BlueOak-1.0.0` and `Artistic-2.0` to DEC 84c37f7d-08cb-457d-8ab3-1db37dba9bc9 (Updates entry made).
2. Rule A for the JDK and in general. This replaces rule B. The questions about the "Owner decides" rows in the inventory are not necessary, because the gate does not check the bundled licenses of a tool.
3. One DEC for all deviations, and not one DEC for each. No deviation is necessary now. The agent does not make the DEC until a first deviation exists.

Task 100.130 has nothing to ask for the JDK, Maven, Node, pnpm, corepack, just and specmgr. The text of rule A is not in DEC 84c37f7d-08cb-457d-8ab3-1db37dba9bc9 yet, and the agent asked the owner for a permission for this change.

#### 2026-11-03 11:17:19.000Z - Answers of the owner to the four license questions

1. Bundled licenses: rule B (stricter). Each bundled license needs a class in the DEC. The agent made an inventory in Design Notes. The agent did not add these rows to the DEC, because the owner has not yet given a permission for them and because many classes are a legal decision.
2. Node: the owner selected Node 26 (LTS "Lithium"). The release is 26.13.0, and the agent read its license. Task 100.100 pins it in Task 110.100.
3. `just` (CC0-1.0): option A. The agent added `CC0-1.0` to the class Permitted in DEC 84c37f7d-08cb-457d-8ab3-1db37dba9bc9 (permission for one time).
4. AGPL: the project code is AGPL-3.0-only, and the project also accepts AGPL-3.0-or-later. The agent changed the row in the same DEC to `AGPL-3.0-only, AGPL-3.0-or-later`.

The DEC has an Updates entry for points 3 and 4. The licenses of the JDK `legal/` folder were a keyword scan at first. Now the agent has read the first lines of each notice.

#### 2026-11-03 11:07:18.000Z - Licenses read for the JDK, Maven, Node, pnpm, corepack, just and specmgr

The agent read the license file in each download (Tasks 100.100, 100.105, 100.110). The results are in the license table. The JDK has the expected main license with the Classpath exception. The DEC has no class for some other licenses. The work stops here. The owner must decide:

1. Which rule applies to licenses in the bundled parts of a tool (the JDK `legal/` folder, Maven `lib/`, Node)? Option A: the DEC checks the main license of a tool that does not go to users, and the bundled licenses only if the tool goes to users. Option B: the DEC gets a class for each bundled license (for example Unicode, zlib, Artistic-2.0, CDDL-1.1, CC0-1.0). Option A is shorter. Option B is stricter.
2. Which Node LTS release? Node 26 "Lithium" is in active LTS since 2026-10-28, with end of life on 2029-04-30. Node 24 "Krypton" is in maintenance LTS since 2026-10-20, with end of life on 2028-04-30, and it is installed on the machine. The agent read the license of Node 26.13.0 only.
3. How does the DEC handle `just` (CC0-1.0)? Option A: add CC0-1.0 to the class Permitted (it also permits other libraries with CC0-1.0, and needs the same legal review as the Classpath row). Option B: a DEC about the deviation for `just` only.
4. Does `AGPL-3.0` in the DEC include `AGPL-3.0-or-later` (the license of specmgr)? The gate matches the complete expression.

Other facts from the check: Maven 4 is still a release candidate, so the candidate is Maven 3.10.0. The npm package of pnpm has no `LICENSE` file. The agent read the license in the repository at the tag v12.16.1. The agent has not pinned any version or checksum yet (Task 110.100).

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
