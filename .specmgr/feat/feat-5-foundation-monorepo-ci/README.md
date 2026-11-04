---
classification: null
created: '2026-11-03T07:53:33.591+01:00'
id: feat-5-foundation-monorepo-ci
status: done
type: feat
updated: '2026-11-03T22:23:58.483+01:00'
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

- [x] ACC-002: `just --list` shows the recipes for validation, license check, SBOM, commit check and check of the build commands. Each CI job starts only a `just` recipe (REQ-002, REQ-009).

- [x] ACC-003: In each workflow, each `run:` step is exactly `just <recipe>`, and the recipe is in the `justfile`. There is no exception: the action `extractions/setup-just` installs `just`, so no bootstrap `run:` step is necessary. The gate stops the pull request if a `run:` step does not obey this rule. The `uses:` steps must be the actions that are in the license table.

- [x] ACC-004: The file `tools/versions.env` has the pins. The install scripts read the versions from it. The versions in the CI workflow are the same as in the file, and the `just` recipe for the pin check shows this (ACC-013). In a new shell, after the scripts operate, `java -version` shows Eclipse Temurin 21 (not the JDK 11 of the system), and Maven, Node, pnpm and just show the pinned versions.

- [x] ACC-005: Each tool and each GitHub Action in the license table of this plan has the result of the check. A tool with a license that is not clear, or with no class in the DEC, is not in use.

- [x] ACC-006: A pull request with a document that is not valid according to specmgr, or a commit message that is not correct, causes a failure in CI.

- [x] ACC-007: CODEOWNERS and NOTICE are in the repository. CODEOWNERS has an entry for each path of REQ-007 that exists.

- [x] ACC-008: The owner has set the branch protection with all the gates of this feature, one review, and the review of a code owner for the files in CODEOWNERS, or the plan shows the open item for the owner.

- [x] ACC-009: The license gate, on a fixture list of licenses, stops for a license that is not permitted, stops for a license that is not known, stops for `GPL-2.0-only` with no exception, and does not stop for `GPL-2.0-only WITH Classpath-exception-2.0` and the other permitted licenses (REQ-006). The gate does not parse license expressions by itself. It uses the library `license-expression` (see Design Notes). An expression is permitted if the library evaluates it as permitted: `OR` needs one permitted alternative (for example `MIT OR Apache-2.0`), `AND` needs all parts permitted, `WITH` is matched as a complete expression, and parentheses are handled by the library. The gate fails closed: an expression that the library cannot parse is "not known", and the gate stops. For a license name that is not an SPDX identifier (for example `Apache License, Version 2.0` in an SBOM), the gate uses a table of names. A name that is not in the table is "not known", and the gate stops.

- [x] ACC-010: The `sbom` recipe operates and writes the SBOM file at the path in the `justfile` (REQ-006). The test of the content with real dependencies is open until feat-6 gives the manifests.

- [x] ACC-011: No script of this feature has the word `sudo` in a command, and the scripts operate for a user that has no sudo (REQ-008). A check in the `justfile` shows this.

- [x] ACC-012: The instructions for the branch protection and the suggestion for the skill are documents in the folder of this feature (REQ-013, REQ-014).

- [x] ACC-013: In each workflow, each `uses:` step has a full commit SHA (40 hexadecimal characters) and not a tag or a branch. A comment on the same line gives the name of the action and the tag of the release, for example `uses: actions/checkout@<sha> # actions/checkout v7.0.1`. A `just` recipe checks this form, and checks that the versions of the tools in the workflow are the same as in `tools/versions.env` (REQ-003, REQ-015).

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

For the Maven version, the Maven Wrapper (`mvnw`) is the rule (decision of the agent on 2026-11-03, finding G1 of the review; before this it was a choice for feat-6-contracts-openapi-pipeline). No Maven setup action is in the license table, so the wrapper is the way to pin Maven in the repository, and a local run and a CI run then use the same Maven. `sbom.sh` starts only the `mvnw` next to the scanned `pom.xml` and stops if it does not exist, and `check-pins` checks that a wrapper has the Maven version of `tools/versions.env` and a `distributionSha256Sum`. Until feat-6 adds the wrapper, a `pom.xml` stops both gates (fail closed).

License expressions (decision on 2026-11-03, after a question of the owner): an own parser for `OR`, `AND`, `WITH` and parentheses is error prone. The license gate uses the library `license-expression` (Apache-2.0, a dependency of the gate that is a library of a tool and not of the product), which parses SPDX expressions. The gate has one small function that evaluates the parsed tree against the list of permitted licenses (`OR` is any, `AND` is all, a license with `WITH` is one symbol that must be in the list as a complete expression). The gate fails closed: it stops for each expression that the library cannot parse, and for each name that is not in the table of names. The gate runs with `uv run --with license-expression==<version>`, with the version in `tools/versions.env`. The alternative, a list of compound expressions that are permitted one by one, needs a manual entry for each expression of each transitive dependency, and the agent does not recommend it.

Tools for the gates (decision of the owner on 2026-11-03). The commit message gate and the license gate are scripts of this project in `tools/gates/`, and need no tool of another vendor. The gate for the commit messages reads the format `type(feat-N): subject`. The license gate reads the SBOM in the CycloneDX format and the list `tools/license/permitted-licenses.txt`. The SBOM for Maven comes from `cyclonedx-maven-plugin` 2.9.3. The SBOM for pnpm comes from `@cyclonedx/cdxgen` 12.9.0 (the latest release on npm; the GitHub page of the project shows v13.6.0, which is not on npm under this name, so the agent pins 12.9.0). `@cyclonedx/cyclonedx-node-pnpm` is not in use because its repository is archived. `mojohaus/license-maven-plugin` is not in use because it covers Maven only. The library `license-expression` is in use for the license gate (see above). The specmgr gate needs `uv`, and the action `astral-sh/setup-uv` installs it.

The version file has the version of each tool and a checksum for the direct artifact of each tool, except `uv` and the GitHub Actions (`UV_VERSION` has no checksum, because the action `astral-sh/setup-uv` downloads `uv`, and the actions are pinned to a commit SHA). The checksums come from the files that the vendor publishes with the release (PyPI, npm and Maven Central for the gate tools). What is checked, and where (finding G2 of the review, 2026-11-03): (a) the install script compares the download of the JDK, Maven, Node, pnpm and just with its checksum; (b) the gate scripts check the direct artifact of the Python tools at run time with `uv pip install --require-hashes` (`license-expression` and `boolean.py`, the wheels; PyYAML, the source archive) or `--verify-hashes` (specmgr, the wheel `SPECMGR_SHA256`); (c) `sbom.sh` compares `pnpm view @cyclonedx/cdxgen@<version> dist.integrity` with `CDXGEN_INTEGRITY` before `pnpm dlx`, and compares the sha256 of the jar of `cyclonedx-maven-plugin` in the local Maven repository with `CYCLONEDX_MAVEN_PLUGIN_SHA256` before the real run. The dependencies of the direct artifacts are NOT checked: the 40 packages that specmgr needs, the build tools of the PyYAML source archive, the 29 dependencies of cdxgen and the dependencies of the Maven plugin. This is an accepted limit that the owner can change (see Blockers). The file `tools/versions.env` is at repository level, because CI, feat-6 and feat-7 also read it.

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
| just 1.59.0 (candidate) | task runner | CC0-1.0. Source: `LICENSE` of the download | Permitted since 2026-11-03 11:17 (the DEC has `CC0-1.0`). The owner reviewed the DEC, with this entry, on 2026-11-03 (statement of the owner) |
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
| Library `PyYAML` 6.0.3 (used by the gates for workflows, Tasks 130.140 and 130.142) | gate | MIT. Source: `LICENSE` in the source archive (sha256 `d76623373421df22fb4cf8817020cbb7ef15c725b9d5e45f17e189bfc384190f`, the same as on PyPI, and the same as `PYYAML_SHA256` in `tools/versions.env`). The field `License` of `PKG-INFO` is `MIT` | Permitted (added on 2026-11-03 by Task 130.140) |
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

- [x] Task 130.100: Write the GitHub Actions workflow. Each job starts one `just` recipe. The tools come from the setup actions of the license table. Each action is pinned to a full commit SHA with a comment (name and release tag, REQ-015). Resolve the SHAs again with `git ls-remote` before writing them. The versions are inputs of the actions, and they are the same as in `tools/versions.env`

- [x] Task 130.110: Write the gate for the specmgr validation of the changed documents

- [x] Task 130.120: Write the gate for the commit messages (Conventional Commits with the feature number as scope, for example `feat(feat-5)`)

- [x] Task 130.130: Write the license gate with the list `tools/license/permitted-licenses.txt`, and the SBOM. The gate uses the library `license-expression` for the expressions, and fails closed

- [x] Task 130.135: Test the license gate with the fixtures in `tools/license/fixtures/`: a license that is not permitted, a license that is not known, `GPL-2.0-only` with no exception, the complete expression with the Classpath exception, a permitted license, an expression with `OR` and one permitted alternative (for example `MIT OR Apache-2.0`), an expression with `OR` and no permitted alternative, an expression with `AND` (all permitted, and one not permitted), an expression with parentheses and `WITH` (for example `(MIT OR GPL-2.0-only) AND Apache-2.0`), an expression that cannot be parsed, and a license name that is not an SPDX identifier (one in the table of names, one not in the table). Write the expected result of each

- [x] Task 130.140: Write the gate for the build commands: each `run:` step must be `just <recipe>` with a recipe in the `justfile`. There is no list of exceptions

- [x] Task 130.142: Write the check for the pins, as a recipe in the `justfile`: each `uses:` step has a full commit SHA and a comment with the name and the release tag (ACC-013), and the versions of the tools in the workflow are the same as in `tools/versions.env`

- [x] Task 130.145: Write the check for `sudo` in the scripts and make it a recipe in the `justfile`

- [x] Task 130.150: Write the instructions for the owner to set the branch protection: all gates of this feature, one review, and the review of a code owner for the files in CODEOWNERS. Add the gates that other features give later

#### Phase 140: Skill Suggestion

- [x] Task 140.100: Write a suggestion for a skill about the names of scripts in the format `TTT.MMM-NN-name.sh`. The suggestion is a document in the folder of this feature. The owner decides where the skill goes

#### Phase 150: Review

- [x] Task 150.100: Run all gates on test pull requests and write the result in this plan. Make one pull request that passes. Make one pull request for each failure that a gate must stop: a document that is not valid, a commit message that is not correct, a license that is not permitted, a license that is not known, and a `run:` step that is not `just <recipe>`. Write the expected result and the actual result of each

- [x] Task 150.110: The owner examines the license table and the open items

## Progress

### Current Status

**As of 2026-11-03**: The plan is written and refined (see the update of 2026-11-03 09:58). Phase 100 is done (Tasks 100.100 to 100.130): the licenses of all tools, actions and gate tools are read, and all of them are permitted. The owner chose Node 26.13.0 (LTS) and rule A for the licenses of tools (only the main license). Rule A is now in the text of DEC 84c37f7d-08cb-457d-8ab3-1db37dba9bc9. The gate tools are two scripts of this project (commit messages and licenses), `cyclonedx-maven-plugin` 2.9.3 and `@cyclonedx/cdxgen` 12.9.0 for the SBOM. The actions are pinned to full commit SHAs with a comment. Phase 110 is done (Tasks 110.100 to 110.130): `tools/versions.env` and the install scripts are written and were run on the machine of the author, and all five tools have the pinned versions (see Design Notes). The work is on the branch `feat-5-foundation-monorepo-ci`. Phase 120 is done (Tasks 120.100 to 120.120): the layout with READMEs, the `justfile`, NOTICE and `.github/CODEOWNERS` are written (ACC-001 and ACC-007 are ticked). Phase 130 is done (Tasks 130.100 to 130.150, see the update of 2026-11-03 14:30): the workflow `.github/workflows/ci.yml` with seven jobs (one `just` recipe each), the seven gate scripts in `tools/gates/`, the license list, the table of names, the list of allowed actions, the fixtures of the license gate (36 files with the expected result of each) and the instructions for the branch protection (`branch-protection.md`) are written. All recipes and the self-tests pass on this branch (94 cases in `just test-gates`, 36 fixtures in `just test-license-gate`). ACC-002, ACC-003, ACC-005, ACC-009, ACC-010, ACC-011 and ACC-013 are ticked. ACC-004 and ACC-006 need a real CI run (Phase 150), and ACC-008 is for the owner. Phase 140 is done (Task 140.100, see the update of 2026-11-03 14:39): the suggestion for the skill about the names of scripts is `skill-suggestion-script-names.md` in the folder of this feature, and ACC-012 is ticked. The owner decides where the skill goes. Phase 150 is started (see the update of 2026-11-03 14:46): the local simulation of the six test pull requests is done and all results are as expected (one finding: the job `license-check` has no `pnpm`, so a real pull request with a bad dependency stops for the wrong reason). The finding was fixed (see the update of 2026-11-03 14:48). The branch is pushed and the main pull request is #9 (7 checks pass). The real test pull requests #10 to #14 gave the expected result in real CI and are closed and not merged (see the update of 2026-11-03 14:56): Task 150.100 is done, and ACC-004 and ACC-006 are ticked. Update of 2026-11-03 18:03 (see the entry of that time): all tasks and all ACC boxes are ticked, so no `[ ]` box is open. The owner set the ruleset `dev` (ACC-008) and the owner said that the license table is reviewed (Task 150.110). The owner also decided that `GPL-2.0-only` with no exception stays not permitted. Open (not blocking): PR #9 cannot be merged yet (state BLOCKED, REVIEW_REQUIRED), `main` has no ruleset, the legal review of the license entries added on 2026-11-03 is open, and the findings E1, E2, G1 and G2 of the post-implementation review were not worked on at that time. Update of 2026-11-03 18:28 (see the entry of that time): the agent fixed E1, E2, G1 and G2 in the gates (work not committed). `just test-gates` now has 269 cases (101 before) and `just test-license-gate` has 46 fixtures. G1 and G2 have limits that stay open for the owner: until feat-6 adds the Maven Wrapper, a `pom.xml` stops `just check-pins` and `just sbom` on purpose, and the checksums cover the direct artifact of a tool only, not its dependencies (see Blockers). The local commits de04687 and 25089cd are not pushed. Update of 2026-11-03 18:55 (see the entry of that time): the owner asked to protect `main` too. The workflow now runs for pull requests to `dev` and to `main`, the `justfile` compares with the target branch of the pull request (`GITHUB_BASE_REF`, `origin/dev` if not set), `just test-gates` has 294 cases, and `branch-protection.md` has the section "Ruleset for `main`" (the owner applies it, in the order that the section gives). The release case from `dev` to `main` was checked: 4 of 43 old commits (scope `dec`) fail `commit-check`, and the owner must decide how the first release is made (open, not blocking, see Blockers). The work is not committed and not pushed. The handoff of 2026-11-03 21:23:19 in Updates has the state at the end of the third session.

**Update of 2026-11-03 19:40** (see the entry of that time): the owner merged PR #9 into `dev` (squash merge, commit 945e669, 2026-11-03T19:38:09Z). With the permission of the owner, `main` was made the same as `dev` with a fast-forward push (option A of the release case), so `main` is at 945e669 too. The workflow and the gate files are now in `main`. Open items for the owner: apply the ruleset for `main` now (`branch-protection.md`, "Ruleset for `main`"); the bypass mode on `dev` (`always` or `pull_request`); the merge method for `main`; the legal review of the license entries added on 2026-11-03; the lock file for cdxgen (the largest gap left in G2); the remote branch `feat-5-foundation-monorepo-ci` can be deleted. The feature unblocks feat-6-contracts-openapi-pipeline (it must add `mvnw` with the pinned Maven version and sha256, because `sbom.sh` stops on a `pom.xml` without it) and feat-7-verification-architecture-tools.

### Blockers

- Resolved (the owner changed the ruleset `dev`, its last change is 2026-11-03 18:08 UTC; the agent found it on 2026-11-03 18:55): the ruleset `dev` now has a bypass actor (the role `maintain`, mode `always`), so the owner can merge PR #9 although the owner is the only collaborator and the author. This replaces the old item "no bypass actor". Open item for the owner (not a blocker): the mode `always` also allows a direct push to `dev`. The agent advises the mode `pull_request`. The proposed ruleset for `main` has `pull_request`.
- Open item for the owner (not a blocker): the branch `main` has no ruleset (state on 2026-11-03 19:40 UTC: `main` and `dev` are both at 945e669, see the item below). The workflow now has the trigger for `main` and the `justfile` compares with the target branch, so the seven checks run for a pull request to `main`. The workflow and the gate files are now in `main` (the first release, option A, is done). Open: the owner applies the ruleset for `main` now. The steps are in `branch-protection.md` ("Ruleset for `main`"). Steps 1 (merge PR #9 into `dev`) and 2 (bring the workflow to `main`) of the order in that section are done. Only the ruleset step is open.
- Resolved on 2026-11-03 (the release case, option A, with the permission of the owner): for a pull request from `dev` to `main`, `commit-check` covers each commit of `dev` that is not in `main`. Before the release, that was 43 commits, and 4 of them fail the gate because their scope is `dec` and not `feat-N`: `bc2742a`, `42ad0e8`, `64cc6f5`, `c677418` (all `docs(dec): ...`). `validate` passes for the same range. The agent did not hide or special-case them. The orchestrator did option A: it made `main` the same as `dev` with a fast-forward push (`git push origin origin/dev:refs/heads/main`, no force), when `main` had no ruleset. This was possible because the "Initial commit" of `main` (23a259e) is an ancestor of `dev`. `main` is now at 945e669, the same as `dev` (checked with `git ls-remote --heads origin`). There was no release pull request, so the commit gate did not meet the four old `dec` commits. Options B (a release pull request with a one-time bypass of the owner) and C (a list of these four commit hashes in `tools/gates/`, which weakens the gate) were not used. Open for the next release: releases must be merge commits (a squash or a rebase brings all old commits back into the next range).
- Resolved on 2026-11-03 18:28 (finding E1 of the post-implementation review): `sbom.sh` stops for a `pom.xml`, `package.json`, `pnpm-lock.yaml` or `pnpm-workspace.yaml` outside the set that it scans, and for an SBOM with no component when the scanned manifests declare dependencies. Tested in `just test-gates` (see the update of 2026-11-03 18:28). Accepted limit: the gate does not read the `<modules>` list of a `pom.xml` or the `packages` list of a pnpm workspace. It assumes that each `pom.xml` below `backend/` is a module of the scanned one, and that each `package.json` below `frontend/` is in the workspace (with a workspace file and a lock file). Folders that the gate does not enter: `.git`, `node_modules`, `build`, `target` (at each level), and from the root `.specmgr`, `tools/license/fixtures`, `tools/gates/fixtures` (as the owner said).
- Resolved on 2026-11-03 18:28 (finding E2): `check-workflows` stops for the variants of the finding (`if:` and `continue-on-error`, `working-directory` and `env:`, another trigger, `permissions:` other than `contents: read`, removed setup actions, and the other keys). The data file `tools/gates/required-setup.txt` lists the seven jobs and the actions of each job. Accepted limit (open for the owner): the gates do not check the other inputs of a `uses:` step (for example `with:` of `actions/checkout`) except the versions of the setup actions, and they do not check `runs-on`.
- Resolved on 2026-11-03 18:28, with a condition (finding G1): the Maven pin in CI is now enforced by the Maven Wrapper rule (`sbom.sh` needs `mvnw`, `check-pins` checks the wrapper). The rule fails closed until feat-6 adds the wrapper: a `pom.xml` stops `just sbom` and `just check-pins`. feat-6-contracts-openapi-pipeline must add `mvnw` and `.mvn/wrapper/maven-wrapper.properties` with the `distributionUrl` for the Maven version of `tools/versions.env` and with a `distributionSha256Sum` (see the update of 2026-11-03 18:28). The text of REQ-003 and of the ACC is not changed.
- Resolved on 2026-11-03 18:28, with an accepted limit that stays open for the owner (finding G2): the gates check the checksum of the direct artifact of each CI-time tool (the wheels of `license-expression` and `boolean.py`, the PyYAML source archive, the specmgr wheel, the npm integrity value of `@cyclonedx/cdxgen`, the jar of `cyclonedx-maven-plugin`). NOT checked: the 40 dependencies of specmgr, the build tools of the PyYAML source archive, the 29 dependencies of cdxgen, the dependencies of the Maven plugin, `uv` itself (`UV_VERSION` has no checksum, the action downloads it) and the GitHub Actions (pinned by commit SHA only). An option for the owner if the limit is not acceptable: a lock file for cdxgen (`pnpm` with `package.json` and `pnpm-lock.yaml` in `tools/`), a `uv` lock file for specmgr, and a checksum list of the Maven plugin dependencies. Each of these needs a decision (a new manifest in `tools/` would also be an unscanned manifest for E1).
- Resolved (the first real CI run, [run 41696229449](https://github.com/dfch/biz.dfch.SpecMgrDemo/actions/runs/41696229449) of PR #9 at commit `220cb85`, started 2026-11-03 18:41 UTC): all 7 checks passed with uv 0.13.7 in CI (uv 0.12.5 on the machine of the author). The tool installs with `--require-hashes` (`uv venv` and `uv pip install`) work on the runner. This replaces the old item "the first real CI run is not done". `uv` builds the PyYAML source archive (about 3 seconds on the machine of the author, it needs `setuptools` from PyPI).
- The finding D2 of the review is done (see the updates of 2026-11-03 17:22 and 17:38).
- Resolved on 2026-11-03: the owner decided that `GPL-2.0-only` with no exception stays not permitted. ACC-009 is not changed. This answers the question in the item below about `GPL-2.0-only`.

- None for the start of phase 100. The JDK vendor is selected (Eclipse Temurin 21) and the license class is permitted since 2026-11-03. The owner told the agent on 2026-11-03 that the review of the new license class is done. DEC 84c37f7d-08cb-457d-8ab3-1db37dba9bc9 has an entry about this statement.
- Resolved on 2026-11-03 (statement of the owner; DEC 84c37f7d-08cb-457d-8ab3-1db37dba9bc9 has an entry of 21:17): the owner reviewed the DEC. The review covers the entries that the agent added to the class Permitted on 2026-11-03: `CC0-1.0`, `Zlib`, `Unicode-3.0`, `Unicode-DFS-2016`, `BlueOak-1.0.0` and `Artistic-2.0`. The review of the Classpath row was done before (dfch, 2026-11-03).
- Resolved on 2026-11-03 (statement of the owner; the DEC has an entry of 21:17): the owner reviewed the DEC. The review covers the entries `GPL-3.0-only` and `GPL-3.0-or-later` that the agent added to the class Permitted of DEC 84c37f7d-08cb-457d-8ab3-1db37dba9bc9 on 2026-11-03 17:21 (after a permission of the owner for this change only). The decision for `LGPL-3.0-or-later` and `GPL-2.0-or-later` was open at that time. It is done (see the update of 2026-11-03 17:38).
- Resolved on 2026-11-03 (statement of the owner; the DEC has an entry of 21:17): the owner reviewed the DEC. The review covers the entries `LGPL-3.0-only` (was the short form `LGPL-3.0`), `LGPL-3.0-or-later` and `GPL-2.0-or-later` that the agent added to the class Permitted of DEC 84c37f7d-08cb-457d-8ab3-1db37dba9bc9 on 2026-11-03 17:38 (after a permission of the owner for this change only). `GPL-2.0-only` with no exception is not changed and stays not permitted: the owner decided this on 2026-11-03 (see the Resolved item above, "the owner decided that `GPL-2.0-only` with no exception stays not permitted").
- Resolved on 2026-11-03 14:28 (Task 130.130): the GitHub page of `cdxgen` shows v13.6.0, and npm has 12.9.0 as the latest release of `@cyclonedx/cdxgen`. From v13 the project publishes under a new npm name, `@cdxgen/cdxgen` (13.6.0, Apache-2.0 in the npm data). The old name stays on npm with 12.9.0 as its last release. The pin stays `@cyclonedx/cdxgen` 12.9.0, and no license of another package was read. A change to `@cdxgen/cdxgen` 13.x is a decision of the owner for a later feature (it needs a license check of the new package and its dependencies).
- Open item for the owner (not a blocker): the plan has no check yet that the pinned SHA belongs to the tag of its comment. `just check-pins` compares both with `tools/license/allowed-actions.txt`, and the agent resolved the SHAs with `git ls-remote` on 2026-11-03 (Task 130.100). A change of a SHA needs a new check by a person.
- No deviation DEC is necessary at this time. Under rule A, the EPL-2.0 in Maven and the MPL-2.0 in the JDK are not checked. If a deviation is necessary later, the owner wants one DEC for all deviations (see the update of 2026-11-03 11:22).
- Resolved on 2026-11-03: `just` (CC0-1.0 is in the class Permitted) and specmgr (`AGPL-3.0-or-later` is in the class Permitted) are not a blocker. pnpm and corepack (MIT) were not a blocker. The owner reviewed the DEC, with the CC0-1.0 entry, on 2026-11-03 (statement of the owner; the DEC has an entry of 21:17).
- Open item for the owner (not a blocker): the traceability gate and the security checks have no feature at this time. [Issue #8](https://github.com/dfch/biz.dfch.SpecMgrDemo/issues/8) is for them. The owner makes a FEAT for it later.
- Open item for the owner (not a blocker): the CODEOWNERS entry for the thresholds is added when the walking skeleton makes them.
- Open item for the owner (not a blocker): NOTICE has no copyright line. Add one if the project needs it. The syntax of `.github/CODEOWNERS` can be checked only after a push to the default branch (`gh api repos/dfch/biz.dfch.SpecMgrDemo/codeowners/errors`).

### Updates

<!-- Newest entry first -- prepend new entries directly below this comment. -->

#### 2026-11-03 21:23:19.000Z - Handoff at the end of the third session (replaces the second handoff)

This entry replaces the second handoff (2026-11-03 13:35:40). The agent checked the facts with `gh`, `git ls-remote` and `gh api` on 2026-11-03 at 21:23 UTC. The text of the requirements and of the acceptance criteria is not changed, and no box is ticked or unticked. The status is not changed. Nothing in this entry is committed or pushed yet.

The second handoff is out of date in these points: "Phase 130 is next", "nothing is pushed" and "the branch is `feat-5-foundation-monorepo-ci`". The real state is below. Its rules for documents and commits (item 7) are still valid and are repeated at the end of this entry.

State

1. feat-5 (issue #5, PR #9) and feat-16-cdxgen-lockfile (issue #16, PR #17) are merged into `dev`. Both have the status `done`. All phases of feat-5 are done.
2. Release: `dev` went to `main` with PR #20 (merge commit 0584392). `main` is 1 commit ahead of `dev` (that merge commit). A merge of `main` back into `dev` is NOT necessary, because the owner set `strict_required_status_checks_policy` to false on the ruleset `main`.
3. Open PR: #21, from the branch `docs/dec-84c37f7d-license-review`. It records the review of DEC 84c37f7d-08cb-457d-8ab3-1db37dba9bc9 by the owner (an entry in the DEC and plan updates). The 7 checks are green. The state is BLOCKED and REVIEW_REQUIRED, so the owner merges it with the bypass (role `maintain`, mode `pull_request`). This handoff entry is part of PR #21. The owner must merge the PR, or the next agent must push to the branch while the PR is open.
4. Rulesets. The owner set them. Agents must not change them without the owner.
   - `dev`: 1 approval, code owner review, stale reviews dismissed, 7 required checks with the strict policy, bypass `maintain` in mode `pull_request`, merge methods merge, squash and rebase.
   - `main`: the same, but the strict policy is false and the merge method is `merge` only.
   - The 7 required checks are the job names of `.github/workflows/ci.yml`: `validate`, `commit-check`, `license-check`, `check-workflows`, `check-pins`, `check-sudo` and `test-gates`. The list is in `tools/gates/required-setup.txt`. The workflow runs for pull requests to `dev` and `main`, and the `justfile` takes the base from `GITHUB_BASE_REF`.
5. Branches. These branches are left on purpose, on the remote and on the local machine: `feat-5-foundation-monorepo-ci`, `docs/feat-5-set-done`, `feat-16-cdxgen-lockfile` and `docs/feat-16-set-done`. Do not delete them unless the owner asks.
6. The local checkout of `dev` can be old. Run `git fetch origin` and make new branches from `origin/dev`.

Decisions of the owner in this session (do not change them)

1. `GPL-2.0-only` alone stays NOT permitted.
2. These licenses are permitted since 2026-11-03: `GPL-3.0-only`, `GPL-3.0-or-later`, `LGPL-3.0-only`, `LGPL-3.0-or-later` and `GPL-2.0-or-later`. DEC 84c37f7d-08cb-457d-8ab3-1db37dba9bc9 and `tools/license/permitted-licenses.txt` have the same 20 entries.
3. The owner reviewed DEC 84c37f7d-08cb-457d-8ab3-1db37dba9bc9 on 2026-11-03.

Rules of the gates (easy to miss)

1. The commit scope must be `feat-N`. A scope like `dec` stops `commit-check`. Use the feature of the plan, for example `docs(feat-5): ...`.
2. Each `run:` step in a workflow is exactly `just <recipe>`.
3. Each `uses:` is a full commit SHA with a comment, and it is in `tools/license/allowed-actions.txt`.
4. A new tool or action needs a license check first (rule A, DEC 84c37f7d-08cb-457d-8ab3-1db37dba9bc9). If the license class is not clear, the owner decides.
5. `just test-gates` (418 cases at the end of feat-16) and `just test-license-gate` (46 cases) must stay green.
6. A `pom.xml` stops `just sbom` until `mvnw` exists with the pinned Maven version and the sha256 (feat-6 adds it). `just check-pins` checks the wrapper.
7. A manifest outside `backend/` and `frontend/` stops `sbom.sh`. The two files of `tools/sbom/` are the exception.

Tools

1. Run `source ~/.config/biz.dfch.SpecMgrDemo/env.sh` first. A shell that is not interactive needs it. It gives java 21 (Temurin), mvn 3.10.0, node 26.13.0, pnpm 12.16.1 and just 1.59.0.
2. `gh` is version 2.4.0 and is old. `gh pr close` has no `--comment`. `gh run view --json jobs` does not exist. Use `gh api` for these.

How the session worked (the owner asked for it; the next agent can do the same)

1. The agent is the orchestrator. It gives each phase to a new `phase-implementer` subagent, runs the quality gate again itself, reads `git diff`, and then makes the commit (Conventional Commit, scope `feat-N`).
2. The agent does not push a feature branch without the "go ahead" of the owner. The agent opens PRs with `gh pr create` and never merges them. The owner merges.
3. Test PRs (`test/feat-N-pr-<case>`) show the failure of a gate in real CI. The agent closes them (does not merge them) and deletes their branches.

Next work (the owner decides the order. The agent asks first)

1. The owner merges PR #21.
2. Issue #22: hash-locked install of the Python tools (the 40 dependencies of specmgr and the build tools of PyYAML). This is a small FEAT like feat-16: `uv pip compile --generate-hashes` and `--require-hashes`, and `check-pins` ties it to `tools/versions.env`. The name of the FEAT uses the issue number: `feat-22-...`. This is the recommended next small work.
3. Issue #23: pin the dependencies of `cyclonedx-maven-plugin`. Wait until feat-6 has a `pom.xml`.
4. feat-6-contracts-openapi-pipeline (issue #6) and feat-7-verification-architecture-tools (issue #7) are planned and not blocked. They are not started (status `planning`). feat-6 must add `mvnw` with the pinned Maven version and the sha256, and must decide the Maven setup for CI.
5. Issue #8 (traceability gate and security checks) has no feature yet. When these gates exist, the branch protection must get them (`branch-protection.md` has the table). Issue #4 (French heading table) belongs to specmgr. feat-1-frontend-technology-decision is still `planning`.

Open items for the owner (not blockers)

1. The cdxgen warning about `NODE_PATH`. A later change can add `env -u NODE_PATH` in `sbom.sh`.
2. NOTICE has no copyright line.
3. The CODEOWNERS entry for the thresholds comes with the walking skeleton.
4. The owner is the only reviewer that the DEC records. No person with legal competence is named as a reviewer.

Rules for documents and commits (from the second handoff, still valid)

1. Use `specmgr_edit` (not scripts) for plans and DECs.
2. Do not change the status of a DEC. An agent must not accept a DEC. A permission of the owner is for one time and one change.
3. Take timestamps from `date -u`. Never write a made-up time.
4. Write documents in ASD-STE100 English.
5. Make separate commits with the scope `feat-N`.
6. Tick a task or an acceptance criterion only after the check ran.

#### 2026-11-03 21:18:40.000Z - Release PR #20 merged, strict status checks off on `main`, DEC reviewed by the owner

The agent checked these facts with `gh` on 2026-11-03 at 21:17 UTC.

1. Release: PR #20 ("release: dev to main (feat-5, feat-16)", from `dev` to `main`) is MERGED (merged by dfch at 2026-11-03T20:59:57Z, merge commit 0584392f635e4e3b7a07883d37413f28e4178413).
2. Ruleset `main` (id 26481206): `strict_required_status_checks_policy` is now `false`. The owner or the orchestrator set it (the agent does not know which). The reason is that a release with a merge commit makes a commit on `main` that `dev` does not have, and the strict policy would make each next release pull request wait for a merge of `main` back into `dev`. The seven required checks are not changed.
3. DEC 84c37f7d-08cb-457d-8ab3-1db37dba9bc9: the owner told the agent on 2026-11-03 that the owner reviewed the DEC, and gave a permission for one time to record this. The DEC has an entry of 21:17. The text of the decision, the status and the class table are not changed. The items about the review of the license entries in Blockers and the license table are updated. `GPL-2.0-only` with no exception stays not permitted. The work is not committed and not pushed.

#### 2026-11-03 19:41:00.000Z - PR #9 merged into `dev`, `main` made the same as `dev` (release case, option A)

The text of the requirements and of the acceptance criteria is not changed, and no box is ticked or unticked. The status is not changed in this entry (the orchestrator sets it with `specmgr_set_status`). The agent checked the facts with `gh pr view 9 --json state,mergedAt,mergeCommit` and `git ls-remote --heads origin`.

1. Merge. The owner merged PR #9 into `dev` on 2026-11-03 (squash merge, commit 945e66969e64290c521530ae8c5cc81482ed3ae1, merged by dfch at 2026-11-03T19:38:09Z). The state of PR #9 is MERGED.
2. Release case, option A (the owner said "go ahead"). The orchestrator made `main` the same as `dev` with a fast-forward push (`git push origin origin/dev:refs/heads/main`, no force). Before the push, `main` was at 23a259e ("Initial commit"), an ancestor of `dev`. Now `main` is at 945e669, the same as `dev`. There was no release pull request, so the commit gate did not meet the four old `dec` commits (`bc2742a`, `42ad0e8`, `64cc6f5`, `c677418`). `main` had no ruleset at that time. The workflow with the trigger for `main` and the gate files are now in `main`.
3. Branches on the remote (`git ls-remote --heads origin`): `dev` and `main` at 945e669, `feat-2-react-angular-visualization-spike`, and `feat-5-foundation-monorepo-ci` (9a85d62, can be deleted).

Open items for the owner (also in Blockers and in Current Status):
- Apply the ruleset for `main` now. The steps are in `branch-protection.md`, section "Ruleset for `main`". Steps 1 and 2 of the order in that section are done.
- Bypass mode on `dev`: `always` or `pull_request` (the agent advises `pull_request`).
- The merge method for `main` (merge commit only is proposed).
- The legal review of the license entries that the agent added on 2026-11-03.
- The lock file for cdxgen (the largest gap left in G2).
- The remote branch `feat-5-foundation-monorepo-ci` can be deleted.

This feature unblocks feat-6-contracts-openapi-pipeline and feat-7-verification-architecture-tools. feat-6 must add `mvnw` with the pinned Maven version and sha256, because `sbom.sh` stops on a `pom.xml` without it.

#### 2026-11-03 18:55:27.000Z - The gates also run for pull requests to `main`, and the release case is checked

The owner asked to protect `main` too, in PR #9. The agent changed the workflow, the `justfile`, the gates, their tests and the instructions. The text of the requirements and of the acceptance criteria is not changed, and no box is ticked or unticked. The status is not changed. No new GitHub Action is used. ACC-012 and ACC-008 stay ticked. Nothing is committed or pushed, and the agent made no GitHub ruleset (the owner applies it).

1. Trigger. `.github/workflows/ci.yml` has `branches: [dev, main]` (the same block style). In `tools/gates/check_workflows.py` the constant `ALLOWED_TRIGGERS` is now `{"pull_request": {"branches": ["dev", "main"]}}`. It is still the one place for the trigger, and its comment and the header of the script are updated. The list is compared exactly, so `[main, dev]` stops the gate too.
2. Base of the comparison. The `justfile` variable `base` is now `origin/` and the value of `GITHUB_BASE_REF` if that variable is set and not empty, and `origin/dev` if not (just 1.59, checked with `just --evaluate base`: no variable gives `origin/dev`, `main` gives `origin/main`, `dev` gives `origin/dev`, an empty value gives `origin/dev`). `GITHUB_BASE_REF` is a default variable of the runner (GitHub documentation, "Variables reference": the target branch of a pull request, set only for `pull_request` and `pull_request_target`), so the workflow sets no `env:` and each `run:` is still exactly `just <recipe>`. The log of the real run of PR #9 (run 41696229449, job commit-check) shows that `actions/checkout` with `fetch-depth: 0` runs `git fetch ... +refs/heads/*:refs/remotes/origin/*` and gets `main -> origin/main`, so `origin/main` is in the clone.
3. Tests. `just test-gates`: 294 ok, 0 failed (269 before). New: the real workflow passes; for the trigger the cases `dev` only, `main` only, `[dev, main, other]`, `master`, the order `[main, dev]`, a branch pattern `**`, `paths-ignore`, `types`, `branches-ignore`, no `branches`, `pull_request_target`, a text and a list for `on:`, and no `on:` all stop (the old cases that used the position of `- dev` were adapted); `just --evaluate base` with the variable not set, empty, `dev`, `main` and `release/1`; the dry run of the recipes `validate` and `commit-check` gives the base of the variable to the gate script; `commit-check.sh` and `validate-docs.sh` accept the base `origin/main` (pass and stop); the release case with an old commit of another scope stops the gate (it is not hidden) and passes when the base is after that commit.
4. Release case (the range `origin/main..HEAD` for a pull request from `dev` to `main`). The agent checked it on 2026-11-03 with a temporary worktree of `origin/dev` (commit ece112f, removed afterwards) and `GATE_WORK_ROOT`. `origin/main` is the "Initial commit" (23a259e) only, and `origin/dev` is 43 commits ahead (`git log --no-merges origin/main..origin/dev`). `bash tools/gates/commit-check.sh origin/main` stops: 4 of 43 commit messages are not correct. All four have the scope `dec` and not `feat-N`: `bc2742a docs(dec): permit GPL-2.0-only WITH Classpath-exception-2.0 in the license DEC`, `42ad0e8 docs(dec): replace words that STE does not approve in the on-hold entries`, `64cc6f5 docs(dec): record on-hold decisions for STE check and register script` and `c677418 docs(dec): set status to accepted`. The other 39 are correct. With the branch of this feature (68 commits, `GITHUB_BASE_REF=main just commit-check`) the same four fail and no commit of feat-5 fails. `validate-docs.sh origin/main` passes: for `origin/dev` 43 changed files, 40 linted, 0 failed, 3 skipped; with this branch 48 files, 40 linted, 0 failed, 8 skipped. The agent did not hide or special-case the four commits. `dev` cannot be fixed with a force push (the ruleset blocks it). The options are in `branch-protection.md` ("Release case") and in the open items below. A squash or a rebase release would bring all old commits back for each release, so the proposed ruleset for `main` allows the merge commit only.
5. Instructions. `branch-protection.md` has a new section "Ruleset for `main`": the order, the steps in the web page, a `gh api --method POST .../rulesets --input -` command with the JSON body (checked with a JSON parser: it is the same as the real ruleset of `dev` that the agent read with `gh api repos/dfch/biz.dfch.SpecMgrDemo/rulesets/26472506`, except the target `refs/heads/main`, the bypass mode `pull_request` and the merge method `merge` only), the text "Bypass mode: `pull_request` is better than `always`", and the "Release case". The two out-of-date points are rewritten, and the table of settings has a row for the bypass list. `tools/gates/README.md` and the comment of `required-setup.txt` are updated.
6. Facts that the agent found with the GitHub API: the ruleset `dev` already has a bypass actor (the role `maintain`, `actor_id` 2, mode `always`; the entry of 18:03 said "no bypass actor", and the ruleset was last changed at 18:08 UTC), and PR #9 has the seven checks green in real CI (run 41696229449). `allowed_merge_methods` of `dev` is merge, squash and rebase.

Order to apply the ruleset for `main` (the owner does it): (1) merge PR #9 into `dev`; (2) bring the workflow and the gate files to `main` with the first release (see option A in the open items), because a pull request to `main` runs the checks only if its merge commit has the workflow with the trigger for `main`; (3) apply the ruleset for `main` last, so that no pull request waits for a check that never runs.

Open items for the owner (also in Blockers):
- Apply the ruleset for `main` (`branch-protection.md`), after steps 1 and 2 above.
- The result of the release case (point 4): the first release has 4 old commits that fail `commit-check`. The agent proposes option A: after PR #9 is merged, make `main` the same as `dev` with a fast-forward push (`git push origin origin/dev:refs/heads/main`, possible because "Initial commit" is an ancestor of `dev`) while `main` has no ruleset. Option B: a release pull request with the one-time bypass of the owner. Option C: a list of the four commit hashes in `tools/gates/` (weakens the gate). The agent did not weaken the gate.
- Bypass mode on `dev`: the owner set `always`, which also allows a direct push. The agent advises `pull_request`. The proposed ruleset for `main` has `pull_request`.
- The merge method of releases: merge commit only (proposed for `main`). Then `main` has a merge commit that `dev` has not, and the next release pull request needs `main` merged into `dev` first (strict policy).

#### 2026-11-03 18:29:00.000Z - Findings E1, E2, G1 and G2 of the post-implementation review fixed in the gates

The owner told the agent: "fix E1, E2, G1, G2". The agent changed only the gates, their tests and their documents. The text of the requirements and of the acceptance criteria is not changed, and no box is ticked or unticked. No new GitHub Action is used. Nothing is committed or pushed. The work is in the working tree for the orchestrator.

**E1 (SBOM and license gate passed with a manifest outside the scanned paths).** `tools/gates/sbom.sh`:
1. Part a: it stops (exit code 1, with the path of each manifest) if a `pom.xml`, `package.json`, `pnpm-lock.yaml` or `pnpm-workspace.yaml` is outside the scanned set. The scanned set is `pom.xml` (root) or `backend/pom.xml`, with each `pom.xml` below `backend/` as a module of the aggregate BOM, and `frontend/package.json`, `frontend/pnpm-lock.yaml` and `frontend/pnpm-workspace.yaml`. A `package.json` below `frontend/` counts only with a workspace file and a lock file in `frontend/` (the agent tested cdxgen 12.9.0: it reads the packages of a workspace from the lock file, and it does not read a nested `package.json` with no workspace). A `package.json` in the root or in `contracts/`, and a `pom.xml` in `model/` or in `backend/svc/` with no `backend/pom.xml`, stop the script. The script does not enter `.git`, `node_modules`, `build`, `target` (each level) and, from the root, `.specmgr`, `tools/license/fixtures` and `tools/gates/fixtures`. The script stops before it deletes or writes any SBOM file. The rule is in the header of `sbom.sh` and in `tools/gates/README.md`.
2. Part b: the new script `tools/gates/sbom_check.py` (standard library only, started with `uv run --no-project`) counts the declared dependencies of the scanned manifests (`dependencies`, `devDependencies`, `optionalDependencies`, `peerDependencies` with at least one entry; a `<dependency>` in the `<dependencies>` of the project or of a profile, and not in `<dependencyManagement>` or in a plugin) and the components of the SBOM (nested ones too). It stops if dependencies are declared and the SBOM has no component. A manifest that cannot be read also stops the script.

**E2 (`check-workflows` and `check-pins` checked only `run:` and `uses:`).** `tools/gates/check_workflows.py` was extended (it needs the new data file `tools/gates/required-setup.txt`, the third argument of `check-workflows.sh`, with that file as the default). The gate now stops for: a trigger that is not exactly `pull_request` with the branches `dev` and no other key (the constant `ALLOWED_TRIGGERS` at the top of the script: to add `main` later, add it to the list there); `permissions:` of the workflow or of a job that is not exactly `contents: read`; each key that is not in the allowed sets of the workflow, the job and the step (so `env`, `defaults`, `concurrency`, `if`, `continue-on-error`, `container`, `services`, `strategy`, `needs`, `shell`, `working-directory` and others stop it); every `if:` except `${{ !cancelled() }}` on `actions/upload-artifact` in the job `license-check` (`ALLOWED_IF`); a job whose `name:` is not its identifier, that has not exactly one `run:` step, or whose identifier is not its recipe; a job or a workflow file that is not in `required-setup.txt`, a job of the file that is missing, and a job whose `uses:` actions are not exactly the actions of its line (a missing setup action, or an extra one). The file `required-setup.txt` is under `/tools/`, so CODEOWNERS covers it. The agent also ran the OLD gate on four changed copies of the real workflow (a job with `if: false` and `continue-on-error: true`; `working-directory` and `env: PATH` on a `run:` step; `pull_request_target` with `permissions: write-all`; the Java, Node and pnpm steps removed from `license-check`): the old gate said PASS for all four, and the new gate stops for all four.

**G1 (REQ-003: Maven is not in CI).** No new action. `sbom.sh` starts only the `mvnw` next to the scanned `pom.xml`, and stops (fail closed) if it does not exist or is not executable. It never starts the `mvn` of the runner (a test puts a `mvn` in the `PATH` that records a call and fails: no call was made). `check-pins` (`check_pins.py`, new argument: the project root, `GATE_WORK_ROOT` as the default for tests) looks for `.mvn/wrapper/maven-wrapper.properties` in the project (same excluded folders as `sbom.sh`). The `distributionUrl` must have `apache-maven-<MAVEN_VERSION>-bin.zip` (or `.tar.gz`) with `MAVEN_VERSION` of `tools/versions.env`, and the file must have a `distributionSha256Sum` of 64 hexadecimal characters (the gate cannot compare it with a pinned value, because `versions.env` has the sha512 of the tar.gz). A `pom.xml` with no wrapper stops the gate. With no `pom.xml` and no wrapper the gate passes and says "no Maven project". feat-6 must add `mvnw` and `.mvn/wrapper/maven-wrapper.properties` for Maven 3.10.0 with `distributionSha256Sum`. Check by hand: the agent made a real wrapper with `mvn wrapper:wrapper -Dmaven=3.10.0 -Dtype=only-script`. It has no `distributionSha256Sum`, so `check-pins` stopped. The sha256 of `apache-maven-3.10.0-bin.zip` is `1f6d9909266510f039f59aa0e13dcd2c66da85f043e56276e41f2918f8bddaff` (computed from a download whose sha512 is the value on Maven Central; Maven Central has no `.sha256` file for it, so feat-6 must check the value again). With this value, `check-pins` passed, and `sbom.sh` with the real `mvnw`, the real plugin and the network wrote a real SBOM (1 component), and `license-check.sh` gave PASS (commons-lang3, Apache-2.0).

**G2 (the checksums of the CI-time tools were never checked).** New key `SPECMGR_SHA256` in `tools/versions.env` (the sha256 of the wheel `biz_dfch_specmgr-0.38.0-py3-none-any.whl`, read from the PyPI JSON API). New function `make_python_env` in `tools/gates/_lib.sh`: it writes a temporary requirements text from `versions.env` (`name==version --hash=sha256:<value>`, so `versions.env` stays the one source), makes a temporary virtual environment and runs `uv pip install` with `--require-hashes` or `--verify-hashes`. The agent found that `uv run` (0.12.5) has no `--require-hashes` option and ignores hashes in `--with-requirements`, so it uses `uv venv` and `uv pip install`. What is verified: `license-check.sh` (wheels of `license-expression` and `boolean.py`, mode require: the install is complete and every package has a hash); `check-workflows.sh` and `check-pins.sh` (PyYAML: `PYYAML_SHA256` is the hash of the SOURCE ARCHIVE, so uv builds the archive, and the build tools are not verified; a wrong hash made uv take a wheel and stop with "Hash mismatch"); `validate-docs.sh` (specmgr wheel, mode verify: only the package with a hash is checked, its 40 dependencies are not; `uvx` is no longer used); `sbom.sh` for cdxgen (`pnpm view @cyclonedx/cdxgen@12.9.0 dist.integrity` must be `CDXGEN_INTEGRITY` before `pnpm dlx`); `sbom.sh` for the Maven plugin (first a run with `-Dcyclonedx.skip=true`: the plugin loads and does nothing, then the sha256 of the jar in the local repository must be `CYCLONEDX_MAVEN_PLUGIN_SHA256`, then the real run; a new variable `SBOM_MAVEN_REPO_LOCAL` sets the repository, the default is `~/.m2/repository`). The header of `tools/versions.env`, the sentence in Design Notes and `tools/gates/README.md` now say what is verified and what is not. Real checks by hand with the network: the real jar of the plugin has the pinned sha256, the real npm integrity value is the pinned value, and a changed value stops `sbom.sh` in both cases (exit code 1).

**Tests.** `just test-gates`: 269 ok, 0 failed (101 before; the license fixtures are 46 ok, 0 failed). New negative cases (most of them are inputs that the old gates accepted): for E1 the root `package.json`, `contracts/package.json`, `model/pom.xml`, `backend/svc/pom.xml` with no `backend/pom.xml`, lock and workspace files in the root, nested manifests with no workspace and with no lock file, a manifest in `docs/.specmgr/`, two manifests at once, a stop before an SBOM is written, and the empty SBOM with dependencies for `dependencies`, `devDependencies`, `optionalDependencies`, `peerDependencies`, a `pom.xml` (also in a profile and in a module) and a broken manifest; positive cases for no manifest, `backend/pom.xml` alone, modules below `backend/`, root `pom.xml` with `backend/pom.xml`, `frontend/package.json` alone, a lock file alone, a workspace, the excluded folders (also at a deeper level), and `dependencyManagement` or plugin dependencies with an empty SBOM. For E2 56 variants of the real workflow (see the list in `selftest.sh`; three of them must still pass), the real workflow as a positive case, and cases for `required-setup.txt` itself. For G1 the `sbom.sh` cases for no `mvnw`, a `mvnw` in the wrong folder, a `mvnw` that is not executable and the `mvn` of the `PATH`, and 19 cases of `check-pins` for the wrapper (good, other version, version that only starts like the pinned one, other distribution, no sha256, wrong sha256, no URL, URL in a comment, a second wrapper, excluded folders, `.specmgr` below the root). For G2 a wrong, missing and badly formed hash for each of the five Python and the two SBOM tools, a wrong version with the old hash, and a package with a dependency that has no hash in mode require. The existing synthetic workflow cases were changed to workflows that follow the policy (job `validate`, one `run:` step), and the case with two `run:` steps is now a negative case. `just --fmt --unstable --check`, `just test-license-gate`, `just validate`, `just commit-check`, `just license-check`, `just check-workflows`, `just check-pins`, `just check-sudo`: exit code 0. `ruff check` and `ruff format --check` (line length 120) pass for the Python files (the agent also removed five `noqa` comments for rules that are not enabled). `bash -n` is correct for all scripts. `ci.yml` is not changed except one comment in the job `license-check` about Maven (the pins and the `run:` steps are the same).

**Open (also in Blockers).** The limits: only the direct artifact has a checksum (no check of the dependencies of specmgr, cdxgen, the Maven plugin, nor of the PyYAML build tools, `uv` and the actions); the gates do not read the `<modules>` of a `pom.xml` or the `packages` of a workspace; the gates do not check the `with:` inputs of a `uses:` step (except the versions) or `runs-on`; the `pom.xml` rule fails closed until feat-6 adds the Maven Wrapper; a real CI run of the new install of the tools is not done (uv 0.13.7 in CI, 0.12.5 here).

#### 2026-11-03 18:03:30.000Z - Ruleset `dev` set, license table reviewed, GPL-2.0-only decision (owner)

The agent checked the facts with the GitHub API on 2026-11-03 at 18:03 UTC (`gh api repos/dfch/biz.dfch.SpecMgrDemo/rulesets` and `.../rulesets/26472506`, `gh pr view 9`).

1. Ruleset: the owner set the ruleset `dev` (id 26472506). It is active. Its target is the default branch `dev`. It has no bypass actor. Its rules are: deletion blocked, non-fast-forward (force push) blocked, a pull request with 1 required approving review, review of a code owner required, stale reviews dismissed on a push, and required status checks (strict policy, integration id 15368 = GitHub Actions) `validate`, `commit-check`, `license-check`, `check-workflows`, `check-pins`, `check-sudo` and `test-gates`. These are the seven gate jobs of `.github/workflows/ci.yml`. ACC-008 is ticked.
2. License table: the owner said on 2026-11-03 that the owner reviewed the license table and set Task 150.110 to complete. The source is the statement of the owner. Task 150.110 is ticked. The statement covers the license table only. It is not a legal review of the entries that the agent added on 2026-11-03 (`CC0-1.0`, `Zlib`, `Unicode-3.0`, `Unicode-DFS-2016`, `BlueOak-1.0.0`, `Artistic-2.0`, `GPL-3.0-only`, `GPL-3.0-or-later`, `LGPL-3.0-only`, `LGPL-3.0-or-later`, `GPL-2.0-or-later`), so the items in Blockers about that review stay open.
3. Decision of the owner on 2026-11-03 (answer to the question of the agent after the finding D2): `GPL-2.0-only` with no exception stays not permitted. ACC-009 stays as it is. The owner allowed `GPL-3.0-only`, `GPL-3.0-or-later`, `LGPL-3.0-or-later` and `GPL-2.0-or-later` (see the entries of 17:22 and 17:38).
4. State: `gh pr view 9` shows `mergeStateStatus` BLOCKED and `reviewDecision` REVIEW_REQUIRED. The local commits de04687 and 25089cd are not pushed (`git rev-list --count origin/feat-5-foundation-monorepo-ci..HEAD` shows 2). No `[ ]` box is left in the plan.

Open items (all in Blockers, none of them blocks the ticks):
- For the owner: the ruleset has no bypass actor, and the owner is the only collaborator and the author of PR #9, so nobody can approve and merge PR #9 until the owner adds a second reviewer or a bypass actor.
- For the owner: `main` has no ruleset.
- For the owner: the legal review of the license entries that the agent added on 2026-11-03.
- For the agent (findings of the post-implementation review, not worked on): E1 (SBOM manifests outside the scanned paths), E2 (the gates do not check `if:`, `continue-on-error`, the triggers and the permissions), G1 (Maven is not pinned in CI) and G2 (the checksums of the tools that CI installs are not enforced). The finding D2 is done.

#### 2026-11-03 17:38:43.000Z - LGPL-3.0-or-later and GPL-2.0-or-later permitted (decision of the owner)

The owner decided in the chat on 2026-11-03 that `LGPL-3.0-or-later` and `GPL-2.0-or-later` are allowed. The owner also gave a permission for one time to change DEC 84c37f7d-08cb-457d-8ab3-1db37dba9bc9 for this and no other change. The reason is that the license gate stopped on these licenses (see the review of this feature, finding D2), and dependencies of the frontend and the backend can have them. A license with `-or-later` gives the user the choice of a version, so it is not more restrictive than the `-only` entries that are already permitted. The agent made these changes. The work is not committed and not pushed.

1. DEC 84c37f7d-08cb-457d-8ab3-1db37dba9bc9: in the class Permitted of More Information, the short form `LGPL-3.0` is now `LGPL-3.0-only`, and `LGPL-3.0-or-later` and `GPL-2.0-or-later` are added. The DEC has a dated entry in Updates. The status (`accepted`), the text of the Decision Outcome, the row Not permitted (`GPL-2.0-only`) and the row of the Classpath exception are not changed.
2. `tools/license/permitted-licenses.txt`: the line `LGPL-3.0` is `LGPL-3.0-only`, and the lines `LGPL-3.0-or-later` and `GPL-2.0-or-later` are added. The list has 20 entries (18 before) and has the same entries as the DEC. The header comment is corrected.
3. Fixtures: `38-lgpl3-or-later` and `39-gpl2-or-later` (renamed, they were "not permitted") now pass. Four new files: `40-lgpl3-plus-form` (`LGPL-3.0+`, pass), `41-gpl2-plus-form` (`GPL-2.0+`, pass), `42-lgpl21-only-not-permitted` (`LGPL-2.1-only` stops, it is not part of the decision) and `43-lgpl3-only` (`LGPL-3.0-only`, pass). There was no free number below 40, so the three error fixtures are renumbered from 40-42 to 44-46 (no other document used the old numbers). The case `GPL-2.0-only` alone (fixture 04) is not changed and still stops. `just test-license-gate` now has 46 fixtures (42 before), and all 46 give the expected result. The counts "42 fixtures" and "18 entries" in the older entries are the counts of that time.
4. `tools/license/README.md`: the note about deprecated identifiers and the GPL entries is updated.

`GPL-2.0-only` alone is NOT changed by this decision. The owner asked for it too, but it reverses an explicit rule of the DEC and of ACC-009. The owner is asked to confirm it. A person who has competence in the law must examine the new entries (see Blockers).

#### 2026-11-03 17:22:33.000Z - GPL-3.0-only and GPL-3.0-or-later permitted (decision of the owner)

The owner decided in the chat on 2026-11-03: "we want to allow GPL v3 only AND -later". The owner also gave a permission for one time to change DEC 84c37f7d-08cb-457d-8ab3-1db37dba9bc9 for this and no other change. The reason is that the license gate stopped on `GPL-3.0-or-later` (see the review of this feature, finding D2), and dependencies of the frontend and the backend can have it. `GPL-3.0-or-later` gives the user the choice of version 3, so it is not more restrictive than `GPL-3.0-only`. The agent made these changes. The work is not committed and not pushed.

1. DEC 84c37f7d-08cb-457d-8ab3-1db37dba9bc9: in the class Permitted of More Information, the short form `GPL-3.0` is now `GPL-3.0-only`, and `GPL-3.0-or-later` is added. The DEC has a dated entry in Updates. The status (`accepted`) and the text of the Decision Outcome are not changed. `LGPL-3.0` stays in the short form.
2. `tools/license/permitted-licenses.txt`: the line `GPL-3.0` is `GPL-3.0-only`, and the line `GPL-3.0-or-later` is added. The list has 18 entries (17 before) and has the same entries as the DEC. The header comment is corrected.
3. Fixtures: six new files, 34 to 39, with the expected results in `expected.txt`. `GPL-3.0-only`, `GPL-3.0-or-later`, the plus form `GPL-3.0+` and the deprecated `GPL-3.0` pass. `LGPL-3.0-or-later` and `GPL-2.0-or-later` are not permitted. The case `GPL-2.0-only` alone (fixture 04) is not changed and still stops. The agent checked with a list of one entry that the library reads `GPL-3.0+` as `GPL-3.0-or-later` and `GPL-3.0` as `GPL-3.0-only`. `just test-license-gate` now has 42 fixtures (36 before). The counts "36 fixtures" and "17 entries" in the older entries and in Current Status are the counts of that time.
4. `tools/license/README.md`: the note about deprecated identifiers and the GPL entries is updated. `tools/gates/selftest.sh` has no count of entries and needed no change.

Open for the owner: the decision for `LGPL-3.0-or-later` and `GPL-2.0-or-later`. They are not part of this decision, they are not in the list, and the gate stops on them. A person who has competence in the law must examine the new entries (see Blockers).

#### 2026-11-03 14:56:01.000Z - Real pull requests of the gates (phase 150, part 2)

The agent did the real part of Task 150.100 on GitHub. Each test pull request has one change and starts from the head `9861f48` of the branch `feat-5-foundation-monorepo-ci`. The base is `dev`. The workflow ran from the merge ref. The test pull requests are **closed and not merged**: the agent closed each one with `gh pr close --delete-branch` and the comment "Test pull request done. Closed, not merged." The remote test branches, the local test branches and the worktrees are deleted. Only the main pull request #9 is open. Nothing was pushed to `dev`, `main` or the feature branch.

Result (a check is `pass` or `fail`; the other checks of the case all pass if the table does not say otherwise):

| Case | Pull request, run | Expected | Actual | Key line of the log |
|---|---|---|---|---|
| Pass (main pull request) | [#9](https://github.com/dfch/biz.dfch.SpecMgrDemo/pull/9), [run 41657603169](https://github.com/dfch/biz.dfch.SpecMgrDemo/actions/runs/41657603169) | All 7 checks pass | As expected. All 7 pass: check-pins, check-sudo, check-workflows, commit-check, license-check, test-gates, validate | - |
| `invalid-document` (the heading `## Impact` of the problem statement is `## Impactt`; commit `docs(feat-5): ...`) | [#10](https://github.com/dfch/biz.dfch.SpecMgrDemo/pull/10), [run 41657943669](https://github.com/dfch/biz.dfch.SpecMgrDemo/actions/runs/41657943669) | Only `validate` fails | As expected. Only `validate` fails | `✗ docs/prb/prb-85f4d435-...-development-work.md (prb): Prb > FutureState: expected FutureState (heading 'Future State'), found no match` and `summary: linted=6 failed=1 skipped=5 excluded=0` |
| `bad-commit-message` (a commit `fixed stuff`) | [#11](https://github.com/dfch/biz.dfch.SpecMgrDemo/pull/11), [run 41657956937](https://github.com/dfch/biz.dfch.SpecMgrDemo/actions/runs/41657956937) | Only `commit-check` fails | As expected. Only `commit-check` fails | `FAIL 6b1eb93 fixed stuff` and `1 of 21 commit message(s) not correct.` |
| `license-not-permitted` (`frontend/package.json` and `pnpm-lock.yaml` with `left-pad` 1.3.0, WTFPL; commit `build(feat-5): ...`) | [#12](https://github.com/dfch/biz.dfch.SpecMgrDemo/pull/12), [run 41657972282](https://github.com/dfch/biz.dfch.SpecMgrDemo/actions/runs/41657972282) | Only `license-check` fails with NOT PERMITTED | As expected. Only `license-check` fails. The SBOM tool (`pnpm dlx @cyclonedx/cdxgen@12.9.0`) ran in the runner, so the fix of the 14:48 update works in real CI | `STOP left-pad@1.3.0: NOT PERMITTED (WTFPL)` and `RESULT: STOP. NOT PERMITTED: 1. NOT KNOWN: 0.` |
| `license-not-known` (the same with `jsonify` 0.0.1, license `Public Domain`) | [#13](https://github.com/dfch/biz.dfch.SpecMgrDemo/pull/13), [run 41657986698](https://github.com/dfch/biz.dfch.SpecMgrDemo/actions/runs/41657986698) | Only `license-check` fails with NOT KNOWN | As expected. Only `license-check` fails | `STOP jsonify@0.0.1: NOT KNOWN (the license name 'Public Domain' is not in the table of names)` and `RESULT: STOP. NOT PERMITTED: 0. NOT KNOWN: 1.` |
| `bad-run-step` (in `ci.yml`, one `run: just commit-check` is `run: echo hello`; commit `ci(feat-5): ...`) | [#14](https://github.com/dfch/biz.dfch.SpecMgrDemo/pull/14), [run 41657996598](https://github.com/dfch/biz.dfch.SpecMgrDemo/actions/runs/41657996598) | `check-workflows` and `test-gates` fail, the other five pass | As expected. `check-workflows` and `test-gates` fail, and the other five pass | `STOP .github/workflows/ci.yml: job 'commit-check', step 3: run: is not exactly just <recipe>: 'echo hello'` (check-workflows). `FAIL the real workflow: expected exit code 0 and 'RESULT: PASS', got exit code 1` and `gates self-test: 100 ok, 1 failed` (test-gates) |

All six cases gave the expected result, so Task 150.100 is ticked. ACC-006 is ticked: the pull request with the document that is not valid (#10) and the pull request with the commit message that is not correct (#11) failed in real CI, each in the right check. ACC-004 is ticked: `check-pins` passed in real CI on #9 (the versions in the workflow, 23 `uses:` steps, are the same as in `tools/versions.env`), and a new interactive shell on the machine of the author (`bash -ic`, today) shows Eclipse Temurin 21.0.13+9, Apache Maven 3.10.0, Node v26.13.0, pnpm 12.16.1 and just 1.59.0.

Findings:

1. No fault in a gate or in the workflow was found. The seven jobs, the names of the checks, the merge ref, `uv` 0.13.7 and the runner image work as designed. The finding of the local simulation (no `pnpm` in the job `license-check`) is closed: with the fix (`setup-java`, `setup-node`, `pnpm/action-setup`) the real runs stop for the right reason (NOT PERMITTED and NOT KNOWN, and not "Required command 'pnpm' not found").
2. A check takes 5 to 32 seconds. The longest is `test-gates` (about 30 s). The checks that start `uvx` (`validate`) and `pnpm dlx` (`license-check`) need the network.
3. In the jobs `license-check` of #12 and #13, `cdxgen` writes a warning (`NODE_PATH is set and may cause unexpected modules`). It does not stop the gate, as in the local test.
4. The test pull request #14 shows that the self-test `test-gates` stops together with `check-workflows` when the real workflow is changed. This is the expected side effect (see the local simulation), and it is not a separate fault.
5. `gh pr close --delete-branch` did not delete the remote test branches here, because the local branches were still checked out in worktrees. The agent deleted them with `git push origin --delete` after it removed the worktrees. Cleanup is complete: `gh pr list --state open` shows only #9, `git ls-remote --heads origin` shows no `test/feat-5-pr-*` branch, and `git worktree list` shows only the main working tree.

Open and not done: Task 150.110 and ACC-008 (items of the owner).

#### 2026-11-03 14:48:37.000Z - Java, Node and pnpm added to the license-check job (correction of phase 130)

The local simulation of the test pull requests (phase 150) showed a fault in `.github/workflows/ci.yml`. The job `license-check` had no `pnpm`, no `node` and no JDK. `tools/gates/sbom.sh` needs `pnpm` if `frontend/package.json` or `frontend/pnpm-lock.yaml` exists, and `mvn` if `pom.xml` exists. So the job would stop with "Required command 'pnpm' not found" as soon as feat-6 adds manifests, and not because of a license. The agent changed this:

1. The job `license-check` now has three more steps, before `run: just license-check` and the upload step: `actions/setup-java` (`distribution: temurin`, `java-version: "21.0.13+9"`), `actions/setup-node` (`node-version: "26.13.0"`) and `pnpm/action-setup` (`version: "12.16.1"`). The SHAs and the comments are the ones of `tools/license/allowed-actions.txt`. The other six jobs are not changed. Each `run:` is still exactly `just <recipe>`.
2. The agent read `action.yml` and `dist/index.js` of `pnpm/action-setup` at the SHA `ea17c68df8912ef543352723c149a84f56e3d413`. The input `version` is optional, and the action installs exactly this version. A `package.json` is not necessary: the action reads `package.json` at the repository root, and it accepts a missing file. It stops only if a root `package.json` has a `packageManager` field with another pnpm version. feat-6 must keep this field the same as `PNPM_VERSION`, or leave it out. The action installs the `pnpm` package from npm for this version, and the local machine uses the standalone release of the same version.
3. `check_pins.py` already maps `java-version` (with `distribution: temurin`), `node-version` and `version` of `pnpm/action-setup` to `JDK_VERSION`, `NODE_VERSION` and `PNPM_VERSION`, so it needed no change. `just check-pins` now checks 23 `uses:` steps (20 before). `selftest.sh` has seven new cases that change the real workflow: a missing and a wrong Java version, a Java distribution that is not temurin, a missing and a wrong Node version, and a missing and a wrong pnpm version. `just test-gates` gives 101 ok, 0 failed (94 before).
4. Maven is not in the job. The pinned Maven version is `MAVEN_VERSION` in `tools/versions.env`, and the runner image has its own Maven. feat-6-contracts-openapi-pipeline must decide about the Maven Wrapper (`mvnw`, see Design Notes): `sbom.sh` uses `mvnw` if it exists, and so the wrapper pins Maven for the SBOM run too. If feat-6 does not use the wrapper, it must add a Maven setup to the job and a check for its version.

Checks (real runs): `just --fmt --unstable --check` has no change. `just validate`, `just commit-check` (18 commits), `just check-workflows` (7 run steps), `just check-pins` (23 `uses:` steps), `just check-sudo` (20 files), `just license-check` and `just test-gates`: all exit code 0. No criterion is ticked or changed. The workflow did not run on GitHub yet.

#### 2026-11-03 14:46:00.000Z - Local simulation of the test pull requests (phase 150, part 1)

The agent did the local part of Task 150.100. **The real GitHub pull requests are still open.** Nothing is pushed, and nothing is committed in the real branch. The owner has not permitted a push yet. The orchestrator makes the real pull requests after the push, so Task 150.100 is not ticked. ACC-006 is also not ticked.

How the agent made the test: for each case, one throwaway `git worktree` (detached, at commit `c20f28d`, 17 commits after `origin/dev`) in `/tmp/opencode/feat5-pr-tests/`. In it, the agent made the one change that a test pull request has, and committed it there. Then it ran the recipes that CI runs, with the same `justfile`: `just validate`, `commit-check`, `license-check`, `check-workflows`, `check-pins`, `check-sudo` and `test-gates`. The base is `origin/dev` (after `git fetch origin`). The tools are those of `~/.config/biz.dfch.SpecMgrDemo/env.sh`, with `uv` 0.12.5 (CI has 0.13.7). All worktrees are deleted. The SBOM tool path ran for real here: `pnpm` 12.16.1 and `@cyclonedx/cdxgen` 12.9.0 with the network on, and a `pnpm-lock.yaml` made with `pnpm install --lockfile-only`.

Result (a stop is exit code 1 of the recipe; "pass" is exit code 0):

| Case | Change in the test | Expected | Actual (local) |
|---|---|---|---|
| 1 `pass` | One line added to a valid problem statement. The commit message is `docs(feat-5): ...` | All seven recipes pass | As expected. All seven pass: validate (6 files linted, 0 failed), commit-check (18 commits correct), license-check (0 components), check-workflows (7 steps), check-pins (20 steps), check-sudo (20 files), test-gates (94 ok, 0 failed) |
| 2 `invalid-document` | A copy of a problem statement with the heading `## Impact` changed to `## Impactt`. A second test: `status: not-a-status` in a goal | `validate` stops, the others pass | As expected. `validate` stops with exit code 1: `Prb > FutureState: expected FutureState (heading 'Future State'), found no match` (second test: `status must be one of [...], got 'not-a-status'`). The other six pass |
| 3 `bad-commit-message` | Two commits: `fixed stuff` and `feat: no scope` | `commit-check` stops, the others pass | As expected. `commit-check` stops with exit code 1: `FAIL 56291f7 fixed stuff`, `FAIL ce36739 feat: no scope`, `2 of 19 commit message(s) not correct`. The other six pass |
| 4 `license-not-permitted` | `frontend/package.json` and `pnpm-lock.yaml` with the dependency `left-pad` 1.3.0 (license `WTFPL`, a real SPDX license that is not in the list) | `license-check` stops with "not permitted", the others pass | As expected, with the real SBOM path (`sbom` ran `pnpm dlx @cyclonedx/cdxgen@12.9.0`). `license-check` stops with exit code 1: `STOP left-pad@1.3.0: NOT PERMITTED (WTFPL)`, `RESULT: STOP. NOT PERMITTED: 1. NOT KNOWN: 0.` The other six pass |
| 5 `license-not-known` | The same, with the dependency `jsonify` 0.0.1 (license `Public Domain`, a name that is not an SPDX identifier and not in `license-names.txt`) | `license-check` stops with "not known", the others pass | As expected. `license-check` stops with exit code 1: `STOP jsonify@0.0.1: NOT KNOWN (the license name 'Public Domain' is not in the table of names)`, `RESULT: STOP. NOT PERMITTED: 0. NOT KNOWN: 1.` The other six pass |
| 6 `bad-run-step` | In `.github/workflows/ci.yml`, `run: just commit-check` changed to `run: echo hello`. A second test: `run: just does-not-exist` | `check-workflows` stops, `check-pins` and the others pass | `check-workflows` stops with exit code 1 as expected: `job 'commit-check', step 3: run: is not exactly just <recipe>: 'echo hello'` (second test: `the recipe 'does-not-exist' is not in the justfile`). `check-pins` and `check-sudo` pass, as expected. **`test-gates` also stops** (93 ok, 1 failed: `FAIL the real workflow: expected exit code 0 and 'RESULT: PASS'`). This is a correct side effect: the self-test checks that the real workflow passes `check-workflows`. validate, commit-check and license-check pass |

Extra check: with real dependencies that are permitted (`lodash.get` 4.4.2 `MIT` and `pako` 3.0.3 `MIT AND Zlib`) `license-check` passes with 2 components. This shows the content of the SBOM with real dependencies for the pnpm path. The Maven path (`pom.xml`) is not tested, and ACC-010 stays as it is.

**Finding for the real pull requests (cases 4 and 5):** the job `license-check` in `.github/workflows/ci.yml` has no `pnpm` (and no `actions/setup-node` and no `pnpm/action-setup`), because the plan said that no job needs them until feat-6. `sbom.sh` stops with `Required command 'pnpm' not found.` if `frontend/package.json` exists and `pnpm` is not in the `PATH`. The agent made this stop here with a `PATH` with no `pnpm` (exit code 1). It is a very likely result on a GitHub runner too, because the standard image has no `pnpm` on the `PATH` (the agent did not check the runner image). So a real test pull request with a bad dependency stops the job `license-check`, but for the wrong reason (no `pnpm`) and not with "NOT PERMITTED". Options for the owner or the orchestrator: (a) the test pull requests 4 and 5 also change the job `license-check` and add `actions/setup-node` and `pnpm/action-setup` (the versions are inputs, and `check-pins` knows them); (b) the same change goes into the workflow of the feature before the test, as a decision of the owner; (c) the agent accepts the stop for this reason and writes it. The agent did not change the workflow. Small notes: cdxgen writes a warning for `NODE_PATH` in the environment (it does not stop the gate), and the gate `validate` needs the network for `uvx` at the first run.

Not simulated: the checkout of the merge ref of a pull request (CI has a merge commit, here HEAD is the last commit), the `uv` 0.13.7 and the runner image, the names of the checks and the upload of the SBOM artifact. These parts need the real runs. Not done and not ticked: Task 150.100 (the real pull requests), Task 150.110 (the owner), ACC-004, ACC-006 and ACC-008.

#### 2026-11-03 14:39:37.000Z - Suggestion for a skill about the names of scripts (phase 140)

The agent did Task 140.100. Nothing is committed or pushed. The agent wrote `skill-suggestion-script-names.md` in the folder of this feature. It is a plain Markdown document and not a specmgr artifact. It has an introduction (what, why, and that the owner decides where the skill goes) and a draft of a complete `SKILL.md` that the owner can copy. The agent did not install the skill in any other folder.

The draft of the skill has: the frontmatter (`name: script-names` and a `description` in the "Use when ..." style of the existing skills); the name format `TTT.MMM-NN-name.sh` (the number of the task, the number of the step with two digits from `01`, and a short kebab-case name that starts with a verb); the folder (`bin` in the folder of the feature, with `_common.sh` and a `README.md` that has the sequence); ten rules for a script (shebang, header with feature and task on line 2, `set -euo pipefail`, can be run again, no sudo, functions from `_common.sh`, versions from `tools/versions.env`, checksums, executable); a table of the difference between these scripts and the gate scripts in `tools/gates/` (the gates have names for their function with no number, are started from a recipe in the `justfile`, and have the task in the header only); the seven real scripts of this feature as examples; a check list; a table of common mistakes; and one optional `grep` command that lists names that do not match the format. The agent did not add a gate, and did not change the `justfile` or CI.

Facts that the agent checked in the repository: the seven scripts in `bin` match the regex of the draft, line 2 of each has the feature and the task, each has `set -euo pipefail`, and `feat-3-process-policy-baseline/bin/` has scripts with the same format and the extension `.py` (so the draft allows `.py`). The regex does not match the four wrong names that the agent tried.

Open points for the owner (also in the document): where the skill goes (for all projects or for this project only), and whether the line that refers to the skill `feat-numbering` stays.

Checks that the agent ran (with the tools of `~/.config/biz.dfch.SpecMgrDemo/env.sh`): `just test-gates` (94 ok, 0 failed), `just validate` (5 linted, 0 failed), `just check-sudo` (20 files, PASS), `just check-workflows` (7 run steps, PASS) and `just check-pins` (20 `uses:` steps, PASS). All exit code 0. `check-sudo` does not read `.md` files, and the document has no command to get more rights in any case. ACC-012 is ticked: `branch-protection.md` (phase 130) and the suggestion for the skill are both in the folder of this feature.

#### 2026-11-03 14:30:21.000Z - CI workflow and gates written and tested (phase 130)

The agent did Tasks 130.100 to 130.150. Nothing is committed or pushed. The agent did this:

1. SHAs (Task 130.100): the agent resolved all eight tags again with `git ls-remote` (the commit of the tag, `^{}` where the tag is annotated). All SHAs are the same as in the license table. `extractions/setup-just` v4 and v4.0.0 are the same commit, and the comment has `v4.0.0`.
2. Workflow (Task 130.100): `.github/workflows/ci.yml` runs for pull requests to `dev`, with `permissions: contents: read`. It has seven jobs, and each one has `actions/checkout` (`fetch-depth: 0`, `persist-credentials: false`), the setup actions it needs (`setup-just` 1.59.0 in each job, `setup-uv` 0.13.7 where a gate starts Python) and one `run: just <recipe>`: `validate`, `commit-check`, `license-check` (and `upload-artifact` of `build/sbom/`, also after a failure), `check-workflows`, `check-pins`, `check-sudo`, `test-gates`. The job names are the names of the checks for the branch protection. No job has `setup-java`, `setup-node` or `pnpm/action-setup`, because no job needs them until feat-6 gives the manifests. `check-pins` knows the version inputs of these actions, so feat-6 gets the check for free.
3. specmgr in CI (Task 130.110): the PyPI package is `biz-dfch-specmgr` (the name `specmgr` is not on PyPI), and the command line needs the extra `mcp`. The gate runs `uvx --from "biz-dfch-specmgr[mcp]==<SPECMGR_VERSION>" specmgr lint --skip-unrecognized <files>` for the changed Markdown files under `docs/` and `.specmgr/` (`git diff --diff-filter=ACMRT` against the merge base, with the working tree; deleted files are skipped). `specmgr lint` does the full parse with the model of the type of each document, the same as the MCP tools. A README that is not a document of a type is skipped by specmgr. The gate needs `SPECMGR_VERSION=0.38.0` in `tools/versions.env` (new key).
4. Commit gate (Task 130.120): the subject must match `^(feat|fix|docs|chore|refactor|test|ci|build|perf|style|revert)\(feat-[0-9]+\)!?: [^ ].*$`. DEC a56f231b-d063-4bef-bbc8-3deb4daff76e gives the scope (the feature identifier) and does not list the types, so the agent took the types of the Conventional Commits specification. Merge commits are skipped (`git log --no-merges`), because CI checks out the merge of the pull request. Messages that git makes (`Revert "..."`, `fixup! ...`) are not correct. All 15 commits of `origin/dev..HEAD` pass. The workflow runs for pull requests to `dev` only (see item 10).
5. License gate (Tasks 130.130 and 130.135): `license-check.sh` starts `license_check.py` with `uv run --with license-expression==30.4.4 --with boolean.py==5.0`. The library parses the expression, and the script evaluates the tree (OR is any, AND is all, `X WITH Y` is one entry in its normal form). Facts that the agent found in the tests: (a) the library knows the alias `LicenseRef-Apache` for `Apache-2.0`, so the gate stops for each `LicenseRef-` and `DocumentRef-` as "not known"; (b) `validate()` raises an `AttributeError` or an `IndexError` for some wrong expressions (for example `MIT, Apache-2.0`), so the gate treats each error of the library as "not known"; (c) the library writes a deprecated identifier in its current form (`LGPL-3.0` becomes `LGPL-3.0-only`), so the list and the SBOM use the same form; (d) the `WITH` of an unknown exception is "not known". The gate reads CycloneDX JSON (`license.id`, `license.name`, `expression`, nested components). A name is read only with the table `tools/license/license-names.txt`. 36 fixtures in `tools/license/fixtures/` have the expected result in `expected.txt`, and `just test-license-gate` runs all of them (36 ok, 0 failed). The list `permitted-licenses.txt` has the 17 entries of the class Permitted of the DEC.
6. SBOM (Task 130.130): `sbom.sh <dir>` makes `backend.cdx.json` with `cyclonedx-maven-plugin` 2.9.3 if `pom.xml` or `backend/pom.xml` exists, `frontend.cdx.json` with `pnpm dlx @cyclonedx/cdxgen@12.9.0` if `frontend/package.json` or `frontend/pnpm-lock.yaml` exists, and `project.cdx.json` with `components: []` if no manifest exists (now). It deletes the old `*.json` files first. The self-test runs the script with stubs for `mvn` and `pnpm`. The test with real Maven and pnpm manifests is open until feat-6. The command line of cdxgen (`--type js --spec-version 1.6 --profile license-compliance --fail-on-error --output <file> frontend`) is from `--help` of 12.9.0, and no real project ran with it.
7. cdxgen version (Task 130.130): `npm view @cyclonedx/cdxgen` shows 12.9.0 as `latest` (changed 2026-10-22). The GitHub project publishes v13 under a new npm name, `@cdxgen/cdxgen` (13.6.0, Apache-2.0 in the npm data), and its README says that the package was renamed in v13. The pin stays 12.9.0. The agent read no license of another package. See Blockers.
8. Workflow gates (Tasks 130.140 and 130.142): `check-workflows.sh` and `check-pins.sh` read the YAML with PyYAML 6.0.3 (MIT, now in the license table; the keys `PYYAML_VERSION` and `PYYAML_SHA256` are new in `tools/versions.env`), started with `uv run --with`. The loader stops for a key that is twice in a mapping. `check-workflows` accepts a `run:` only if it is exactly `just <recipe>` (one line, a public recipe from `just --summary`), and it stops for a `shell:` key, a job with no `steps`, and a step with no `run:` and no `uses:`. `check-pins` reads the comments from the text and the inputs from the YAML, and stops if the two lists of `uses:` are not the same. It checks the full SHA, the comment `# <owner>/<name> <tag>`, the action in the new file `tools/license/allowed-actions.txt` (the license table as a file, with the tag and the SHA), and the version inputs: `just-version`, `version` of `setup-uv`, `java-version` (with `distribution: temurin`), `node-version` and `version` of `pnpm/action-setup` against `JUST_VERSION`, `UV_VERSION`, `JDK_VERSION`, `NODE_VERSION` and `PNPM_VERSION`. A version input that the gate does not know stops it. The `justfile` passes the file of allowed actions as a third argument to `check-pins.sh`.
9. `sudo` check (Task 130.145): `check-sudo.sh <path>...` looks at `*.sh`, `*.bash`, `*.just`, `justfile`, `*.yml` and `*.yaml`. It stops if `sudo`, `doas` or `pkexec` is a word of a command (at the start of a line, or after a space, `;`, `&`, `|`, a bracket, a quote, `/`, `\` or `=`), and skips lines that start with `#`. A name like `check-sudo.sh` is not a command. The script writes the words in parts, so that it does not stop for its own text. The `justfile` recipe looks at `justfile`, `tools`, `.specmgr/feat` and `.github`. The check is a check of the text and not a proof. The agent ran every script as a user with no sudo.
10. Decisions of the agent (for the Decisions Made log): (a) the workflow runs for pull requests to `dev` only, because the gates compare with `origin/dev`, and a release pull request from `dev` to `main` would show false failures. If `main` needs a protection, the owner must decide which gates and which base; (b) a component with more than one entry in `licenses` is permitted only if all entries are permitted (the strict reading of CycloneDX); (c) `OR` with one unknown license is "not known" (fail closed); (d) the self-tests make the bad input in a temporary folder, and only the fixtures for `check-sudo.sh` are files (`*.fixture` in `tools/gates/fixtures/`, so no gate reads them as scripts); (e) the variable `GATE_WORK_ROOT` and `SBOM_PROJECT_ROOT` set another folder for the tests only; (f) `__pycache__/` is in `.gitignore`.
11. Branch protection (Task 130.150): `branch-protection.md` in the folder of this feature lists the settings, the seven required checks with their recipes, the steps in the web page and the `gh api` call, the check of CODEOWNERS, and the table of the gates that other features give later. It says that gates 2 and 9 of DEC 361678a6-f941-473b-a058-1ba2bacf7d3d have no feature (issue #8). It also tells the owner two points: the author cannot approve the own pull request (so "1 approval and the review of a code owner" blocks each pull request of dfch unless a second account or a bypass exists), and the workflow has no check for pull requests to `main`.

Checks that the agent ran (all on this branch, with the tools of `~/.config/biz.dfch.SpecMgrDemo/env.sh`): `just --fmt --unstable --check` (no change); `just validate`, `just commit-check` (15 commits), `just sbom`, `just license-check` (0 components), `just check-workflows` (7 run steps), `just check-pins` (20 `uses:` steps), `just check-sudo` (20 files), `just test-license-gate` (36 ok, 0 failed) and `just test-gates` (94 ok, 0 failed): all exit code 0. The cases of `just test-gates` that must stop are: a `run:` that is not `just` (also with `&&`, with an argument, with an expression, in a block scalar with two lines, a private recipe, a recipe that does not exist, a `shell:` key, a key that is twice, a job with `uses:`); a `uses:` with a tag, a branch, a short SHA, no comment, a wrong comment, a SHA or tag that is not the one of the table, an action that is not in the table, a local action, a Docker image, a value in quotes; a version of just, uv, Java, Node or pnpm that is not the one of `versions.env`, `latest`, a number, a missing input; the command `sudo` in a script, a pipe, a path, a `justfile` and a workflow; sixteen wrong commit subjects, and a bad commit in a git repository; an invalid document (in a commit and in the working tree only), and a base that does not exist; a Maven run that makes no file. `bash -n` is correct for all scripts. `shellcheck` is not installed on this machine, so the agent did not run it. `ruff check` and `ruff format --check` (line length 120) are correct for the Python files.

Not done: ACC-004 (it needs a CI run and Task 130.142 shows only the file side), ACC-006 (needs real pull requests, Task 150.100), ACC-008 (the owner), and ACC-012 (the suggestion for the skill is Task 140.100). The workflow did not run on GitHub yet, so a problem that only CI shows (for example the checkout of the merge ref, or `uvx` in the runner) is open until Task 150.100.

#### 2026-11-03 13:35:40.000Z - Handoff at the end of the second session (replaces the first handoff)

Phases 100, 110 and 120 are done. Phase 130 (CI and gates) is next. Nothing is pushed. The work is on the branch `feat-5-foundation-monorepo-ci` (from `dev`), and the working tree is clean at commit `dc4eea2`. The first handoff (2026-11-03 09:45:52) is out of date in these points: it said "start with phase 100", "use the home directory for corepack" and "commits on `dev`".

For the next agent:

1. Start with Task 130.100. Read this plan first, mainly Requirements, Acceptance Criteria, Design Notes (the license table and the rules) and the Updates since 2026-11-03 09:58. Read DEC 84c37f7d-08cb-457d-8ab3-1db37dba9bc9 (licenses) before the license gate.
2. Rules that the owner decided (do not change them without the owner):
   - Rule A for licenses: for a tool that does not go to users, the check covers the main license only. For a library that goes to users, the gate checks each dependency.
   - The license gate uses the library `license-expression` (with `boolean.py`), and fails closed. `OR` needs one permitted alternative, `AND` needs all, and `WITH` must match as a complete expression. Names that are not SPDX ids need a table of names.
   - One register DEC for all license deviations. It does not exist, because no deviation exists.
   - Pin each GitHub Action to a full commit SHA with a comment on the same line: `uses: <name>@<sha> # <name> <tag>`. The SHAs in the license table are from 2026-11-03. Resolve them again with `git ls-remote` before writing the workflow.
   - The commit message gate and the license gate are scripts of this project in `tools/gates/`. The commit scope is `feat-N` (example: `feat(feat-5): ...`).
   - No bootstrap `run:` step: `extractions/setup-just` installs `just`. Every `run:` step is `just <recipe>`.
3. The `justfile` is written. Each gate recipe starts `tools/gates/<script>` and stops with "NOT IMPLEMENTED" if the script is missing. The scripts and their arguments that the recipes expect:
   - `validate-docs.sh <base>` (Task 130.110), base is `origin/dev`
   - `commit-check.sh <base>` (Task 130.120)
   - `sbom.sh <dir>` (Task 130.130), dir is `build/sbom`
   - `license-check.sh <sbom-dir> <permitted-list>` (Task 130.130), list is `tools/license/permitted-licenses.txt`
   - `check-workflows.sh justfile .github/workflows` (Task 130.140)
   - `check-pins.sh tools/versions.env .github/workflows` (Task 130.142)
   - `check-sudo.sh tools .specmgr/feat` (Task 130.145)
   Change the `justfile` if a script needs other arguments, and run `just --fmt --unstable` after a change.
4. The tools are installed in `~/.local/opt/biz.dfch.SpecMgrDemo/` and the profile `~/.bashrc` reads `~/.config/biz.dfch.SpecMgrDemo/env.sh`. A new interactive shell has `java` (Temurin 21), `mvn`, `node` (26), `pnpm` and `just`. A shell that is not interactive does not: use `source ~/.config/biz.dfch.SpecMgrDemo/env.sh`. `just verify-tools` checks the install. The machine has its own `uv` 0.12.5 (the pin 0.13.7 is for CI).
5. Facts that are easy to miss:
   - Node 26.13.0 has no corepack. pnpm is the standalone release.
   - `@cyclonedx/cdxgen`: the GitHub page shows v13.6.0, and npm has 12.9.0 as the latest. The pin is 12.9.0. Task 130.130 must check this again, and read the license of any other version before it changes the pin.
   - No Maven or pnpm manifest exists (feat-6 adds them). Test the license gate and the SBOM with fixtures in `tools/license/fixtures/` (Task 130.135). The test with real dependencies is out of scope.
   - `.github/workflows/` does not exist yet. `.github/CODEOWNERS` has the owner `@dfch`, and GitHub can check it only after a push to the default branch.
   - `extractions/setup-just` calls `extractions/setup-crate` (both MIT OR Apache-2.0).
6. Before the first push: create the pull request at the end of the feature (the owner agreed). Use `gh`, and use the issue number #5. The owner turns on the branch protection later (Task 130.150), so the instructions for it must be a document in this feature folder.
7. Rules for documents and commits:
   - Use `specmgr_edit` for the plan. Do not change a status. An agent must not accept a DEC. A permission of the owner is for one time and one change.
   - Take timestamps from `date -u`, and never write a made-up time.
   - Write documents in ASD-STE100 English (see the first handoff, item 6, for the word check scripts, which are a reference and not a gate).
   - Make separate commits with the scope `feat-5`. Use the types `feat` for code and `docs` for plan changes.
   - Tick a task or an acceptance criterion only after you ran the check.
8. Open items for the owner (also in Blockers): the legal review of the licenses is done by the owner (dfch, 2026-11-03). NOTICE has no copyright line. The CODEOWNERS entry for the thresholds comes with the walking skeleton. Issue #8 (traceability gate and security checks) has no feature. GitHub issue #4 is for specmgr.
9. State of the acceptance criteria: ACC-001 and ACC-007 are ticked. ACC-002 to ACC-006 and ACC-008 to ACC-013 are open. ACC-004 is shown on this machine (the versions are correct in a new shell), but the part about the CI workflow needs Task 130.142, so it is not ticked.

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

#### 2026-11-03 18:55:27.000Z - The base of the gates is the target branch of the pull request (the owner can change it)

The owner asked for the protection of `main` in PR #9. This replaces the decision of 2026-11-03 14:30, point (1) ("the workflow runs for pull requests to `dev` only"). The agent made these design choices:

1. The base comes from `GITHUB_BASE_REF`. The `justfile` variable `base` is `origin/` and `GITHUB_BASE_REF` if that variable is set and not empty, and `origin/dev` if not. The reasons: `GITHUB_BASE_REF` is a default variable of the runner (the target branch of a pull request), so the workflow needs no `env:` (the gate `check-workflows` does not allow it) and each `run:` stays `just <recipe>`; one workflow and one `justfile` serve both branches; and a local run has the same default as before (`origin/dev`). The value is empty for events that are not pull requests, so an empty value is the same as "not set" (a plain `env("GITHUB_BASE_REF", "dev")` would give `origin/` for an empty value). Rejected: a second workflow file for `main` (more files for the gate to compare, and a second set of job names), and a recipe parameter (the gate wants `run:` to be exactly `just <recipe>`).
2. The trigger list is `[dev, main]` and the gate compares it exactly (the order too). A new protected branch is a change of this one constant, and CODEOWNERS covers `/tools/`.
3. The gate is not weakened for the first release. The four old commits with the scope `dec` are reported as failures, not hidden (see the update of 2026-11-03 18:55:27). The owner decides how the first release is made.
4. The proposed ruleset for `main` has the bypass mode `pull_request` and only the merge method "merge commit", because a squash or a rebase release would bring all old commits of `dev` into the range of the next release. This is a proposal in `branch-protection.md`. The agent did not make the ruleset.

#### 2026-11-03 18:30:00.000Z - Rules for the findings E1, E2, G1 and G2 (the owner can change them)

The owner said "fix E1, E2, G1, G2". The agent made these design choices:

1. Maven wrapper rule (G1). The Maven pin in CI is enforced by the Maven Wrapper, because no Maven setup action is in the license table and a new action needs a license check and a decision of the owner. `sbom.sh` starts only the `mvnw` next to the scanned `pom.xml` (no `mvnw` stops it). `check-pins` stops for a `pom.xml` with no wrapper, and for a wrapper whose `distributionUrl` has not `apache-maven-<MAVEN_VERSION>-bin.zip` (or `.tar.gz`) or that has no `distributionSha256Sum` (64 hexadecimal characters; `versions.env` has the sha512 of the tar.gz, so the value cannot be compared). Fail closed until feat-6 adds the wrapper. REQ-003 and the ACC are not changed.
2. Scanned set (E1). The Maven root is the root `pom.xml`, or `backend/pom.xml` if there is no root one. The poms below `backend/` are modules. The Node set is `frontend/package.json`, `frontend/pnpm-lock.yaml` and `frontend/pnpm-workspace.yaml`, and nested `package.json` files only with a workspace file and a lock file (tested with cdxgen 12.9.0). `<modules>` and workspace `packages` lists are not read (accepted limit). The excluded folders are the ones of the owner: `.git`, `node_modules`, `build`, `target` at each level, and from the root only `.specmgr`, `tools/license/fixtures`, `tools/gates/fixtures`. `.specmgr` is excluded at the root only, so `docs/.specmgr/package.json` stops the script. Two copies of this list exist (bash in `_lib.sh`, Python in `check_pins.py`), and both are tested.
3. Empty SBOM (E1 part b). The check counts `<dependency>` of the project and of profiles only (not `dependencyManagement`, not plugin dependencies), so a BOM-only `pom.xml` does not stop the gate for no reason. For Node it counts the four dependency fields. The check uses the Python standard library through `uv run --no-project` (no new dependency).
4. Policy of the workflow (E2). The allowed trigger, the allowed permissions, the allowed keys and the one allowed `if:` are constants at the top of `check_workflows.py`. The keys are an allow list (each other key stops the gate), so an unknown key is a stop and not a pass. The jobs and the actions of each job are in the data file `tools/gates/required-setup.txt` (format: workflow file, job, actions). The job name is its identifier and its recipe. A new job, workflow file or action needs a change of that file first (CODEOWNERS covers `/tools/`). Not checked (open for the owner): the other inputs of `uses:` steps and `runs-on`.
5. Hash enforcement scope (G2). `uv run` ignores hashes (0.12.5), so the gates install the tools with `uv venv` and `uv pip install`, with a temporary requirements text that comes from `versions.env` (it stays the one source). Mode `--require-hashes` for packages that have no other dependency (`license-expression` with `boolean.py`, PyYAML). Mode `--verify-hashes` for specmgr (a new key `SPECMGR_SHA256`, the sha256 of the wheel from PyPI), where the 40 dependencies are not verified. `PYYAML_SHA256` is the hash of the source archive, so uv builds it (the build tools are not verified); the agent kept this value, because the wheels depend on the Python version and the platform. For cdxgen: `pnpm view ... dist.integrity` against `CDXGEN_INTEGRITY` before `pnpm dlx` (the 29 dependencies are not verified; a `pnpm` lock file for cdxgen would be the better way, but it needs a new manifest in `tools/` and a decision of the owner). For the Maven plugin: a run with `-Dcyclonedx.skip=true` loads the plugin and does nothing, then the sha256 of the jar in the local repository must be `CYCLONEDX_MAVEN_PLUGIN_SHA256`, then the real run (the check is done before the plugin reads the project; the dependencies of the plugin are not verified). Tests use `VERSIONS_FILE` (already used by the gates) and, for `sbom.sh`, `SBOM_MAVEN_REPO_LOCAL`. No variable switches a check off.

#### 2026-11-03 14:30:21.000Z - Rules of the gates of phase 130

The agent made these decisions in phase 130 (the owner can change them): (1) the workflow runs for pull requests to `dev` only; (2) the types of the commit subject are the types of the Conventional Commits specification, and merge commits are not checked; (3) the license gate reads a license name only with the table `tools/license/license-names.txt`, treats `LicenseRef-` and each error of the library as "not known", and permits a component with many license entries only if all are permitted; (4) `check-pins` compares the workflow with `tools/license/allowed-actions.txt` (the license table as a file) and with `tools/versions.env`; (5) PyYAML 6.0.3 (MIT) reads the workflows, and specmgr is started with `uvx --from "biz-dfch-specmgr[mcp]==0.38.0" specmgr lint`; (6) the `cdxgen` pin stays at `@cyclonedx/cdxgen` 12.9.0, because v13 has another npm name.

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
