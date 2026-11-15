---
classification: null
created: '2026-11-15T08:09:18.000+01:00'
id: feat-8-traceability-security-gates
status: planning
type: feat
updated: '2026-11-15T08:51:36.952+01:00'
version: 1.0.0
---

# Feature: Traceability Check and Security Checks as Gates

## Plan

### Overview

This feature adds the two blocking gates of DEC 361678a6-f941-473b-a058-1ba2bacf7d3d that have no feature at this time (GitHub issue #8). Gate 2 is the traceability check (DEC f21920d2-4da5-4cf7-bd94-2e9bcba77342). Gate 9 is the security checks. The feature does not make the security checks blocking. The verification DEC says that the skeleton sets each threshold from a measured baseline, so the security tools run as reports without a threshold, and the owner decides when a threshold is turned on. The traceability check is different: it stops a pull request for a reference that has no target, and for an approved REQ that has no VCR. The traceability check only gives a warning for the links that no approved REQ needs yet.

The security tools are OSV-Scanner (known vulnerabilities in the dependencies, from the SBOM), gitleaks (secrets), zizmor (the workflow files) and CodeQL (code analysis). CodeQL is the hosted default setup of GitHub and not a recipe of the `justfile`. A deviation in the register DEC 93a6d588-e002-4daf-9a47-45e2d77786e9 records it, because the terms of CodeQL are not open source. The feature is planned and not started.

### Requirements

- REQ-001: A script in CI must read the references of the specmgr documents, and it must stop the pull request for a reference that has no target. The script must use the reader of references of the pinned specmgr, and it must not have a second copy of the syntax of the references.

- REQ-002: The script must stop the pull request if the value of `x-specmgr-req` of an operation in `contracts/openapi.yaml` is not the identifier of a REQ document, or if an approved REQ has no VCR.

- REQ-003: The script must read the identifiers in the Structurizr workspace (the property `specmgr-req` of an element, one identifier or a list that the character comma separates) and in the tests (the text `vcr:<uuid>` in the name of a test). It must stop the pull request for an identifier that has no document. It must give a warning, and no stop, if an approved REQ has no element in the model, or if the VCR of an approved REQ is not in the name of a test. The feature does not make the warning an error. The owner decides this when the first approved REQ exists.

- REQ-004: Each gate is a `just` recipe, each CI job starts one recipe, and the gates of the workflow files (check-workflows, check-pins, check-sudo) pass for the new jobs. The new tools have a pin that the gate check-pins checks.

- REQ-005: The security tools OSV-Scanner, gitleaks and zizmor must run as reports with no threshold. A finding is part of the report and does not stop the job. A failure of the tool (no network, a file that cannot be read, a wrong configuration) must stop the job.

- REQ-006: CodeQL must run as the default setup of GitHub for the code that GitHub detects, and the setting is a report with no threshold. The setting must not need a workflow file, and it must not change the gate check-workflows.

- REQ-007: Each tool must have a license check before the project uses it. The result is one of the words of DEC 84c37f7d-08cb-457d-8ab3-1db37dba9bc9: Permitted, Review or Not permitted. If a license is not clear, the work stops and the owner makes a decision. A tool with the result Review has a deviation in the register DEC 93a6d588-e002-4daf-9a47-45e2d77786e9, and the owner must accept it.

- REQ-008: The feature must measure the baseline of the findings of each security tool, and must write the values in this plan. The feature must not set a threshold.

- REQ-009: The instructions for the branch protection must have the new gates. The feature gives the steps for the owner to add the new checks to the rulesets of `dev` and `main`.

### Acceptance Criteria

- [ ] ACC-001: `just` has a recipe for the traceability check and a recipe for each of the three security tools, and CI starts only these recipes.

- [ ] ACC-002: The traceability check stops for each of these: a reference that has no target, an `x-specmgr-req` that is not the identifier of a REQ, an identifier in the model or in a test that has no document, and an approved REQ that has no VCR. The self-test shows each case with a fixture, and it shows the case that is successful.

- [ ] ACC-003: The traceability check gives a warning, and no stop, for an approved REQ that has no element in the model or whose VCR is not in the name of a test. The self-test shows both warnings.

- [ ] ACC-004: The script of the traceability check gets its references from the reader of the pinned specmgr. A self-test stops if the function of the reader is not there or has a different form.

- [ ] ACC-005: Each security recipe ends with exit code 0 for a finding and with an exit code that is not 0 for a failure of the tool. The self-test of each recipe shows the two cases.

- [ ] ACC-006: The pins of OSV-Scanner, gitleaks and zizmor are in `tools/versions.env` and are checked by `just check-pins`. The binary of gitleaks and of OSV-Scanner has a sha256, and zizmor has a lock file with hashes.

- [ ] ACC-007: CodeQL runs as the default setup, and the first scan is complete. The deviation for CodeQL is in the register DEC 93a6d588-e002-4daf-9a47-45e2d77786e9 (accepted by the owner).

- [ ] ACC-008: Each tool has an entry in the license table of this plan with the result of the check. The result is Permitted, or a deviation of the owner for the result Review. No row has the result open.

- [ ] ACC-009: The baseline values of OSV-Scanner, gitleaks, zizmor and CodeQL are in this plan, and no threshold is set.

- [ ] ACC-010: `branch-protection.md` has the new checks and the steps of the owner. The CI run of the pull request of this feature is green with the new jobs.

### Scope

#### Included

- The script, the recipe, the fixtures and the self-test of the traceability check (Gate 2).

- The convention `specmgr-req` for the Structurizr elements and the convention `vcr:<uuid>` for the names of tests, with the property in `model/workspace.json` for the component that the first REQ needs.

- OSV-Scanner, gitleaks and zizmor as recipes and CI jobs (reports).

- CodeQL as the hosted default setup, and its deviation in the register DEC 93a6d588-e002-4daf-9a47-45e2d77786e9 (with the one-time permission of the owner).

- The license table, the pins, the baseline, and the changes to `branch-protection.md`, `required-setup.txt` and the READMEs of the gates.

#### Explicitly Out Of Scope

- A threshold for a security tool. The skeleton, or a later decision of the owner, sets it from the baseline.

- The AGPL clause about use through a network (DEC 84c37f7d-08cb-457d-8ab3-1db37dba9bc9). It is a blocker for a new DEC that comes with the feature for the walking skeleton.

- The CodeQL command line, and other tools for code analysis (SpotBugs, find-sec-bugs, Semgrep).

- A scheduled job and the upload of SARIF files. The gate check-workflows fixes `on:` and `permissions:` of the workflow, and this feature does not change them.

- GitHub issue #23 (the pinning of the dependencies of `cyclonedx-maven-plugin`), issue #31 (the cost of pull requests for documents) and issue #45 (the Python environment of the self-test).

- The VCR and the SYSRS entry of REQ 1ca335d7-969a-443e-9392-165fdeea99a0 (steps 4 and 5 of SOP 95b6735b-03b8-47a0-92aa-7934a4ff1519), and new REQ documents. The owner decides in Task 110.100 if the feature adds them.

- The change of the check levels from warning to error for the links of the model and the tests.

### Dependencies

#### Depends On

- feat-7-verification-architecture-tools (done): it gives the Structurizr workspace `model/workspace.json`, the tests, the recipe pattern of the eleven jobs and the register DEC 93a6d588-e002-4daf-9a47-45e2d77786e9.

- feat-6-contracts-openapi-pipeline (done): it gives `contracts/openapi.yaml` with the extension `x-specmgr-req`.

- feat-5-foundation-monorepo-ci (done): it gives the `justfile`, the workflow, the SBOM and the branch protection.

- feat-22-python-tools-lockfile (done): it gives the hash-locked install of the Python tools, with the lock file of specmgr.

#### Blocks

- The feature for the walking skeleton: it adds the first approved REQ and the first VCR, and Gate 2 must exist before.

### Design Notes

The owner made these decisions in the planning session of 2026-11-15 (see Decisions Made): one feature for the two gates, CodeQL as the hosted default setup, no threshold for a security tool, OSV-Scanner online on the SBOM, gitleaks and zizmor as reports, the reader of the pinned specmgr for the references, and the two conventions below.

#### Gate 2: what the check does

| Check | Level | Source |
|---|---|---|
| Each reference in the documents of `docs/` and `.specmgr/` has a target | Error | `find_references` of the pinned specmgr |
| `x-specmgr-req` of each operation is the identifier of a REQ | Error | `contracts/openapi.yaml` |
| An approved REQ has a VCR | Error | The REQ and VCR documents. The state now: the only REQ has the status draft |
| An identifier in `specmgr-req` of the model, or `vcr:<uuid>` in a test, has a document | Error | `model/workspace.json`, the test sources |
| An approved REQ has an element in the model | Warning | `model/workspace.json` |
| The VCR of an approved REQ is in the name of a test | Warning | The test sources of the backend and of the frontend |

Facts that the plan uses (read on 2026-11-15, on `origin/dev`):

- `docs/` has one REQ (status draft), no VCR and no SYSRS. The elements of `model/workspace.json` have no `properties`. No test has `vcr:`.
- The specmgr command line has no command for references. `list_references` is a tool of the MCP server, and the reader is the function `find_references` in the module `biz.dfch.specmgr.general.tools._references`. The name of the module starts with an underscore, so it is not a public interface. The pin `tools/python/specmgr.lock` limits the risk, and the self-test of ACC-004 shows a change.
- DEC f21920d2-4da5-4cf7-bd94-2e9bcba77342 says "a properties entry" for the model and "the name or an annotation" for a test. The conventions of this feature (`specmgr-req` and `vcr:<uuid>`) are in the READMEs of the gates and in this plan. The agent does not change the DEC. The owner can add them to More Information of the DEC with a one-time permission.
- A name with `vcr:<uuid>` in the name of a test is one regular expression for all test languages (JUnit with a display name, Vitest and Playwright with the title of `describe` or `it`). An annotation needs a reader for each language.

#### Gate 9: the tools

| Tool | What it examines | How it runs | Failure of the tool |
|---|---|---|---|
| OSV-Scanner | The known vulnerabilities in the dependencies. The input is the SBOM files of `just sbom` (`build/sbom/*.cdx.json`). The query uses the network | A recipe and a CI job. A report with no threshold | A non-zero exit that is not the exit code for a finding |
| gitleaks | Secrets in the files and the history of the pull request | A recipe and a CI job. A report with no threshold. An allowlist in `tools/`, which CODEOWNERS covers | A configuration error |
| zizmor | The workflow files. The run is `--offline` because the workflow has no token | A recipe and a CI job. A report with no threshold | A file that cannot be read |
| CodeQL | The code in the languages that GitHub detects (actions, java-kotlin, javascript-typescript, python) | The hosted default setup. No file in the repository | The state of the setup |

Notes:

- zizmor has low value at this time, because the gates check-workflows, check-pins and check-sudo already fix the trigger, the permissions, the form of the `run:` step and the pins. The owner chose to add it as a report (see Decisions Made). It can give a second opinion if a gate of the workflow is relaxed later.
- GitHub secret scanning and push protection are on for the repository. The setting for the patterns that are not of a provider is off, and Dependabot security updates are off. The steps for the owner are in Task 140.130.
- The feature must keep a report of a finding apart from a failure of the tool. The recipes use one function for this, and the self-test shows both cases. A finding of a later threshold must be new compared with a baseline file in the repository (the pattern of `tools/breaking/breaking-changes-ignore.txt`). The feature does not write this file.
- The CI jobs follow the form of feat-7-verification-architecture-tools: one job for each recipe, the name of the job is the name of the recipe, and one `run:` step `just <recipe>`. The names in this plan are `traceability`, `vuln-scan`, `secret-scan` and `workflow-scan`, and Task 110.130 can change them. `tools/gates/required-setup.txt` has a line for each job. The workflow has `on: pull_request` and `permissions: contents: read` only.

#### CodeQL

The terms are the file `LICENSE.md` of the repository github/codeql-cli-binaries (GitHub CodeQL Terms and Conditions). The agent read them on 2026-11-15. They permit the analysis of an open source codebase (a codebase with an OSI-approved license) that is on GitHub.com, and they permit the creation of CodeQL databases for CI of such a codebase. They do not permit the use with a code base that is not open source (for example a private repository) unless the customer has a license for GitHub Advanced Security. The terms are per user, and they do not permit a hosted offer of the software. The terms are not an open source license, so DEC 84c37f7d-08cb-457d-8ab3-1db37dba9bc9 needs a deviation.

The reasons for the hosted default setup (the owner chose it): the condition fails safely (a derived private repository gets no scan, and with the command line in a recipe it would break the terms in silence), the setup needs no download, no install script and no pin, and it needs no change of the gate check-workflows. The costs: the version of CodeQL and of its queries is not pinned, the scan does not run on a developer machine (an exception to REQ-002 and REQ-009 of feat-5-foundation-monorepo-ci), and the scan needs GitHub. The deviation text records the terms with the date, the condition, the exception and what happens when the condition ends. The default branch is `dev`. The state of the setup on 2026-11-15 is `not-configured`.

The agent changes no setting of the repository without the approval of the exact command by the owner.

#### License table

The agent fills the table from the license file of each tool and not from memory (Phase 100). The row of CodeQL has the terms that the agent read, but the result stays Review until the owner accepts the deviation. The licenses that the GitHub API shows (OSV-Scanner Apache-2.0, gitleaks MIT, zizmor MIT) are not a check of the license file.

| Tool | Use | License | Result |
|---|---|---|---|
| OSV-Scanner 2.7.1 | known vulnerabilities | Apache-2.0 (main license, rule A). Source: `LICENSE` at the tag v2.7.1 of github.com/google/osv-scanner, the full text of the Apache License, Version 2.0, sha256 of the file `cfc7749b96f63bd31c3c42b5c471bf756814053e847c10f3eb003417bc523d30`. Read on 2026-11-15. The release file `osv-scanner_linux_amd64` is the binary only | Permitted |
| OSV data (the database that OSV-Scanner queries) | known vulnerabilities | Not clear: the data is an aggregate of many sources with their own licenses (CC-BY 4.0, CC0, MIT, Apache-2.0, BSD, CC-BY-SA 4.0 and CC-BY-NC-ND 4.0), and the agent found no terms of use of OSV.dev for the data or the API. See the Result of the Phase 100 below | open (the owner decides, Task 100.130) |
| gitleaks 8.30.1 | secrets | MIT (main license, rule A). Source: `LICENSE` at the tag v8.30.1 of github.com/gitleaks/gitleaks, the full text of the MIT License, copyright 2019 Zachary Rice, sha256 of the file `e3884b252b3bfc045e55be43a34d1e80da070bc6f804ac95bf4660e97d62ebc6`. The file `LICENSE` in the release archive `gitleaks_8.30.1_linux_x64.tar.gz` is the same. Read on 2026-11-15 | Permitted |
| zizmor 1.32.0 | workflow files | MIT (main license, rule A). Source: `LICENSE` in the source archive of the tag v1.32.0 of github.com/zizmorcore/zizmor (`zizmor-src.tar.gz`, sha256 `8f4ebf26fef5920c0d133925a162dd4e772c088bdbb7a4971bbd589ebf572c47`), the full text of the MIT License, copyright 2024 William Woodruff, sha256 of the file `a6fd1bd18da7cec8284639d5b0d351b90934317be1b9f9ea94a077621c6f35af`. The same file is in the wheel (`zizmor-1.32.0.dist-info/licenses/LICENSE`, METADATA `License: MIT`). The lock file `tools/python/zizmor.lock` has one package (zizmor) and no dependency. Read on 2026-11-15 | Permitted |
| CodeQL | code analysis | GitHub CodeQL Terms (not open source) | Review |

#### Result of the Phase 100 (License Checks)

The agent read the license files at the pinned releases on 2026-11-15, and not from memory (the GitHub API shows the same licenses, but it is not a check of the file). The three tools do not go to users, so rule A of DEC 84c37f7d-08cb-457d-8ab3-1db37dba9bc9 applies (only the main license). Apache-2.0 and MIT are in the class Permitted. The pins (Task 100.150) are these:

| Tool | Version | Release file for Linux x86_64 | sha256 | Where the sha256 was compared |
|---|---|---|---|---|
| OSV-Scanner | 2.7.1 (published 2026-11-09) | `osv-scanner_linux_amd64` (the binary, no archive) | `fb7dab19a8bd9bbe5c3189f09d4b7ee1820c9553a23bac202648a56efd2f6ee8` | `osv-scanner_SHA256SUMS` of the release, the digest of GitHub, and `sha256sum` of the download. `osv-scanner --version` gives 2.7.1 |
| gitleaks | 8.30.1 (published 2026-03-21) | `gitleaks_8.30.1_linux_x64.tar.gz` | `551f6fc83ea457d62a0d98237cbad105af8d557003051f41f3e7ca7b3f2470eb` | `gitleaks_8.30.1_checksums.txt` of the release, the digest of GitHub, and `sha256sum` of the download. `gitleaks version` gives 8.30.1 |
| zizmor | 1.32.0 (published 2026-11-02) | the PyPI package `zizmor` (wheels), the lock file `tools/python/zizmor.lock` has 12 hashes | the 12 sha256 values of the files of the release | the values of the PyPI entry of 1.32.0 (the same 12 values). The wheel for Linux x86_64 installs from the lock file with `--require-hashes --only-binary :all:`, and `zizmor --version` gives 1.32.0 |

These are the latest releases that are not a pre-release on 2026-11-15 (`gh api repos/<owner>/<repo>/releases/latest`). The repository of zizmor is github.com/zizmorcore/zizmor (the old name woodruffw/zizmor gives the same release). The four crates in the source archive of zizmor (`github-actions-models`, `subfeature`, `yamlpatch`, `yamlpath`) have an MIT `LICENSE` too. zizmor has no `Requires-Dist` in the PyPI entry, so the lock file has no other package to check (the license gate of feat-22-python-tools-lockfile has nothing more to read).

The OSV data (Task 100.130) is not clear, so the agent stops here and the owner decides. The agent read `docs/data.md` of github.com/google/osv.dev (master, and the page google.github.io/osv.dev/data/), the FAQ of OSV.dev, the `README.md` of OSV-Scanner at the tag v2.7.1 (the section Data Sources and Privacy) and the `LICENSE` of the repository osv.dev (Apache-2.0, for the code). The facts:

- The data of OSV.dev is a set of databases with their own license. The page names: CC-BY 4.0 (GitHub Advisory Database, PyPI Advisory Database, Go Vulnerability Database, OSS-Fuzz, PSF and others), CC0 1.0, MIT, Apache 2.0, BSD, CC-BY-SA 4.0 (Ubuntu, Alpine SecDB) and CC-BY-NC-ND 4.0 or the Chainguard License for Commercial Scanners (Chainguard / Wolfi). Converted data (Debian, Alpine, NVD) has the license of its source. The page has no license or terms for the OSV.dev aggregate or for the answers of the API.
- The FAQ says that the API has no rate limit at this time, and it gives service level objectives (a target, not a promise). The agent found no terms of use for the API, no link to terms on osv.dev, and no statement about use in CI or in a product.
- The input of OSV-Scanner is the SBOM of the project, which has Maven and npm packages. For these the main source is the GitHub Advisory Database (CC-BY 4.0, which asks for attribution). The licenses CC-BY-NC-ND (Wolfi) and CC-BY-SA (Ubuntu, Alpine) are for ecosystems that this project does not have, but the agent cannot show that OSV-Scanner never returns such a record.
- OSV-Scanner sends package names, versions, ecosystems and file hashes to api.osv.dev (the README of OSV-Scanner). Source code is not sent. The SBOM of this project is for a public repository. The tool can also ask deps.dev (for the dependency tree, and for `--licenses`), and the registries Maven Central and npm.
- DEC 84c37f7d-08cb-457d-8ab3-1db37dba9bc9 has classes for the licenses of software. It has no class for CC-BY-4.0 (the precedent is the deviation for caniuse-lite in the register DEC 93a6d588-e002-4daf-9a47-45e2d77786e9) and no rule for data that a tool queries. The agent does not decide if the DEC applies to data.

The options for the owner: (a) accept the use of the data as a deviation in the register DEC, with the condition that the report keeps the attribution of the sources (CC-BY 4.0) and that the project stores counts only; (b) a statement that the DEC does not apply to the data that a tool queries, with a short note in the DEC (a permission for one time); (c) the offline mode with a downloaded database (the same licenses, and no query of the project data to the network); (d) leave OSV-Scanner out. The row stays `open` until the owner decides, and ACC-008 is not done.

### Related Decisions

- DEC 361678a6-f941-473b-a058-1ba2bacf7d3d: Use a Test Pyramid and Blocking Gates for Verification
- DEC f21920d2-4da5-4cf7-bd94-2e9bcba77342: Use Specmgr Identifiers for Traceability
- DEC 84c37f7d-08cb-457d-8ab3-1db37dba9bc9: Use Only Open Source Libraries That Are Compatible With AGPL-3.0-only
- DEC 93a6d588-e002-4daf-9a47-45e2d77786e9: Register of the Approved License Deviations
- DEC 9edc1071-4fd0-48b6-a037-1a4cb2331f73: Make Sure That the Code Obeys the Structurizr Model
- DEC a56f231b-d063-4bef-bbc8-3deb4daff76e: Use Conventional Commits, Feature Branches and a Definition of Done
- SOP 95b6735b-03b8-47a0-92aa-7934a4ff1519: Add a Requirement With Traceability

### Task List

#### Phase 100: License Checks and Pins

- [x] Task 100.100: Read the license file of OSV-Scanner at the pinned release, and fill the row of the license table. Use the result words of DEC 84c37f7d-08cb-457d-8ab3-1db37dba9bc9. Rule A of the DEC applies (the main license of a tool that does not go to users). Done on 2026-11-15: Apache-2.0, Permitted

- [x] Task 100.110: Read the license file of gitleaks at the pinned release, and fill the row. Done on 2026-11-15: MIT, Permitted

- [x] Task 100.120: Read the license file of zizmor in the source archive of the pinned release, and fill the row. Do the same for the packages that the lock file brings in, with the license gate of feat-22-python-tools-lockfile. Done on 2026-11-15: MIT, Permitted. The lock file has one package (zizmor) and no dependency

- [ ] Task 100.130: Read the terms of use of the OSV data that OSV-Scanner queries, and fill the row. If the terms are not clear, the work stops and the owner decides. Read on 2026-11-15, and the terms are not clear (see the Result of the Phase 100). The row stays `open`, and the owner decides

- [x] Task 100.140: Record the terms of CodeQL in the license table (the file and the date of the read), and write the text of the deviation for the register DEC 93a6d588-e002-4daf-9a47-45e2d77786e9. Do not change the DEC before the owner gives a one-time permission. Done on 2026-11-15: the owner gave the one-time permission, and the dated section is in the DEC (see Updates)

- [x] Task 100.150: Select the version of each tool, and write the pins in `tools/versions.env` (the version, and the sha256 for the binary of gitleaks and of OSV-Scanner). Make the lock file with hashes for zizmor, as in feat-22-python-tools-lockfile. Extend the gate check-pins for the new pins. Done on 2026-11-15: OSV-Scanner 2.7.1, gitleaks 8.30.1, zizmor 1.32.0 (see the Result of the Phase 100 and the entry of Updates)

- [ ] Task 100.160: The owner reviews the license table and the deviation text, and gives the permission for the entry in the register DEC (ACC-007, ACC-008)

#### Phase 110: Gate 2, the Traceability Check

- [ ] Task 110.100: Read the VCR document structure and the REQ status values. Define "an approved REQ has a VCR" with these (the link between a VCR and a REQ), and ask the owner if the feature adds the VCR and the SYSRS entry for REQ 1ca335d7-969a-443e-9392-165fdeea99a0 as a positive example. Do not assume the answer

- [ ] Task 110.110: Write the script of the traceability check. It runs in the hash-locked environment of specmgr, imports `find_references` and applies the table of checks of the Design Notes. It prints each finding with the file and the rule, and the warnings apart from the errors

- [ ] Task 110.120: Write the reader of the identifiers in the Structurizr workspace (`specmgr-req`) and in the test sources (`vcr:<uuid>`) for the backend and the frontend

- [ ] Task 110.130: Write the recipe and the gate script in `tools/gates/` in the form of the other gates. Fix the recipe names of Phase 120 and of the CI jobs

- [ ] Task 110.140: Add the property `specmgr-req` to the component of `model/workspace.json` that the REQ 1ca335d7-969a-443e-9392-165fdeea99a0 needs. Run the architecture tests of feat-7-verification-architecture-tools (`just architecture-model`) to show that the property does not break the comparison

- [ ] Task 110.150: Write the fixtures and the self-test: each case of ACC-002 and ACC-003, the case that is successful, and the test of ACC-004 (the function of the reader). Add the self-test to `just test-gates`

- [ ] Task 110.160: Write the conventions (`specmgr-req` and `vcr:<uuid>`) and the check levels in `tools/gates/README.md` and in the READMEs of `model/` and of the tests. Tell the owner that DEC f21920d2-4da5-4cf7-bd94-2e9bcba77342 does not have them

#### Phase 120: Gate 9, the Security Recipes

- [ ] Task 120.100: Write the function that separates a finding from a failure of the tool, with the self-test (ACC-005)

- [ ] Task 120.110: Write the recipe `vuln-scan` (OSV-Scanner on the SBOM files of `just sbom`), the install script with the sha256, and the self-test with a stub for the tool and the network

- [ ] Task 120.120: Write the recipe `secret-scan` (gitleaks), the install script with the sha256, and the allowlist for the fixtures of the gates. The allowlist has an entry for each false positive with the reason. CODEOWNERS covers the file

- [ ] Task 120.130: Write the recipe `workflow-scan` (zizmor with `--offline`), and the self-test with a workflow that has a known problem

- [ ] Task 120.140: Write the README of the security gates (the tools, the exit codes, the form of the report, how a later threshold works with a baseline file). Add the new scripts to `tools/gates/README.md`

#### Phase 130: CodeQL and Baseline

- [x] Task 130.100: Show the exact `gh api` command for the default setup of CodeQL to the owner. Run it only after the approval, and record the command and the result. Done on 2026-11-15: the owner approved with "CodeQL: go ahead", and the command was run (see Updates). The agent did not show the exact command before the run (see the entry of Updates)

- [ ] Task 130.110: Wait for the first complete scan, and read the alerts with `gh api repos/{owner}/{repo}/code-scanning/alerts`. Record the number of alerts for each language and each severity

- [ ] Task 130.120: Run the three recipes on the repository, and record the baseline (the number of findings of each severity for OSV-Scanner, the number of findings of gitleaks, the number of findings of zizmor). Record the date, the version of each tool and the state of the databases

- [ ] Task 130.130: Write the baseline in the subsection Baseline of the Design Notes, with the values of Task 130.110 and 130.120. Do not set a threshold (ACC-009)

#### Phase 140: CI and Branch Protection

- [ ] Task 140.100: Add the four jobs to `.github/workflows/ci.yml` (one `run:` step each) and the four lines to `tools/gates/required-setup.txt`. Set the timeout of the job that uses the network. Run `just check-workflows`, `just check-pins` and `just test-gates`

- [ ] Task 140.110: Add the four gates to `.specmgr/feat/feat-5-foundation-monorepo-ci/branch-protection.md`: the rows of the table, the entry for Gate 2 and Gate 9 of DEC 361678a6-f941-473b-a058-1ba2bacf7d3d, and the statement of the exception for CodeQL (no recipe)

- [ ] Task 140.120: Update the sentences in feat-5-foundation-monorepo-ci that say that gates 2 and 9 have no feature (the record only, as an entry of Updates and not a change of the old text), and the READMEs of the gates and of `tools/`

- [ ] Task 140.130: Write the steps for the owner, each with the exact command or the page: add the new check names to the `required_status_checks` of the rulesets of `dev` and `main` (the decision of the owner if a job that is a report must be a required check, because it stops for a failure of the tool), turn on the Dependabot alerts, and turn on the secret scanning for the patterns that are not of a provider

- [ ] Task 140.140: Show the CI run of the pull request with the new jobs, and record the run (ACC-010)

#### Phase 150: Review and Close

- [ ] Task 150.100: Walk the acceptance criteria. Tick each criterion with the evidence, and set the status of the feature to `review`

- [ ] Task 150.110: Write the comment in GitHub issue #8 (the gates, the baseline, the open items) and the comments that link issues #23, #31 and #45 as related. Do not close an issue before the owner agrees

- [ ] Task 150.120: Write the entry of the AGPL clause (DEC 84c37f7d-08cb-457d-8ab3-1db37dba9bc9) as a blocker for the feature for the walking skeleton

## Progress

### Current Status

**As of 2026-11-15**: The plan is written. The owner decided the open points in the session of 2026-11-15 (see Decisions Made). The branch `feat-8` is rebased onto `origin/dev`, which has feat-7-verification-architecture-tools with the status `done`, and GitHub issue #7 is closed. Two tasks are done: the deviation for CodeQL is in the register DEC 93a6d588-e002-4daf-9a47-45e2d77786e9 (Task 100.140), and the default setup of CodeQL is turned on (Task 130.100). The first scan is not complete yet (Task 130.110). The tools of the other phases are not selected, and no recipe, no script and no workflow is changed. The next step is the rest of Phase 100.

**Update 2026-11-15 (Phase 100)**: Tasks 100.100, 100.110, 100.120 and 100.150 are done. OSV-Scanner (Apache-2.0), gitleaks (MIT) and zizmor (MIT) are Permitted, and the pins are in `tools/versions.env` and checked by `just check-pins` (OSV-Scanner 2.7.1, gitleaks 8.30.1, zizmor 1.32.0 with `tools/python/zizmor.lock`). Task 100.130 (the terms of the OSV data) is not done: the terms are not clear, and the owner decides (see the Result of the Phase 100). Task 100.160 is for the owner. No recipe, no install script and no workflow is changed. The next phase (110) needs no decision about the OSV data. Phase 120 (`vuln-scan`) needs it.

### Blockers

- The owner must decide about the license of the OSV data (Task 100.130, row `OSV data` of the license table, open): the data is an aggregate with the licenses CC-BY 4.0, CC0, MIT, Apache-2.0, BSD, CC-BY-SA 4.0 and CC-BY-NC-ND 4.0, and no terms of use of OSV.dev were found. The options (a) to (d) are in the Result of the Phase 100. ACC-008 needs this decision, and the recipe `vuln-scan` of Phase 120 needs it before the project uses OSV-Scanner.

- The owner must review the license table and the deviation text of CodeQL (Task 100.160). The deviation is written in the register DEC 93a6d588-e002-4daf-9a47-45e2d77786e9, but the agent did not read the terms of GitHub for the hosted service (the GitHub Terms of Service and the terms for GitHub Advanced Security), and a person who has competence in the law has not examined the section.

- The AGPL clause about use through a network is open in DEC 84c37f7d-08cb-457d-8ab3-1db37dba9bc9. It does not stop this feature, and it needs a new DEC with the feature for the walking skeleton.

- GitHub issue #31 (the cost of pull requests for documents) is not decided. It can change which gates run for a pull request that has only documents.

- The conventions `specmgr-req` and `vcr:<uuid>` are not in DEC f21920d2-4da5-4cf7-bd94-2e9bcba77342. The owner decides if they go into the DEC (Task 110.160).

### Updates

<!-- Newest entry first -- prepend new entries directly below this comment. -->

#### 2026-11-15 08:51:30.000Z - Phase 100: licenses of the three tools read, pins and lock file written, OSV data stops for the owner

The agent did Tasks 100.100, 100.110, 100.120 and 100.150. It did not do Task 100.130 (the terms are not clear, see below), Task 100.140 (done before) and Task 100.160 (for the owner). About the time of this entry: the real UTC time of the machine was 07:51, and the local time (UTC+01:00) was 08:51. The earlier entry of this section has the local time of its author with the letter Z (08:30:00.000Z), and the validation of the plan needs the entries newest first. So this entry has the local time with the letter Z, as the entry below. The agent did not change the entry below.

1. Licenses (Tasks 100.100 to 100.120): the agent got the license file of each tool at the pinned release and recorded the file, the release, the sha256 of the file and the date of the read in the license table (the Result of the Phase 100 has the details). OSV-Scanner 2.7.1: Apache-2.0. gitleaks 8.30.1: MIT. zizmor 1.32.0: MIT (the source archive, the wheel, and the four crates in the archive). All three are Permitted by rule A. The lock file of zizmor has one package and no dependency, so there is no other license to read. The row of CodeQL is not changed.
2. Versions and checksums (Task 100.150): the latest releases that are not a pre-release are OSV-Scanner 2.7.1 (`osv-scanner_linux_amd64`, `fb7dab19...2c6ee8`), gitleaks 8.30.1 (`gitleaks_8.30.1_linux_x64.tar.gz`, `551f6fc8...3f2470eb`) and zizmor 1.32.0 (the lock file has the 12 hashes of the PyPI entry). The agent compared each sha256 with the vendor file of the release, with the digest of GitHub and with `sha256sum` of the download. The three tools run (`osv-scanner --version`, `gitleaks version`, `zizmor --version` after the install from the lock file with `--require-hashes --only-binary :all:`).
3. Files changed: `tools/versions.env` (the keys `OSV_SCANNER_*`, `GITLEAKS_*`, `ZIZMOR_VERSION`, and the comments), `tools/python/zizmor.lock` (new, made by `tools/python/make-locks.sh`, which has a new line for zizmor; the three old lock files did not change), `tools/security/` (new: `osv-scanner-checksums.txt` and `gitleaks-checksums.txt` are the vendor files of the releases without a change, and `README.md`), `tools/gates/check_pins.py` and `check-pins.sh` (the function `check_release_checksum` is the check of oasdiff with the data of the tool, and it checks the two new tools; `PYTHON_LOCKS` has zizmor; the new argument is `<security-tool-dir>`), `tools/gates/selftest.sh` (the new cases for the pins of the two tools and for the lock file of zizmor), and `tools/README.md`, `tools/gates/README.md`, `tools/python/README.md`.
4. The OSV data (Task 100.130) stops for the owner: the data is an aggregate with the licenses CC-BY 4.0, CC0, MIT, Apache-2.0, BSD, CC-BY-SA 4.0 and CC-BY-NC-ND 4.0, and the agent found no terms of use of OSV.dev for the data or the API. The row stays `open`. The options (a) to (d) are in the Result of the Phase 100. The agent did not choose and did not change the register DEC.
5. The agent changed no setting of the repository, no workflow, no recipe and no DEC.

#### 2026-11-15 08:30:00.000Z - The deviation for CodeQL is in the register DEC, CodeQL default setup is turned on, issue #7 is closed

The owner gave three instructions on 2026-11-15: the one-time permission for the register DEC 93a6d588-e002-4daf-9a47-45e2d77786e9, "CodeQL: go ahead", and "close #7". The agent did this:

1. DEC (Task 100.140): the agent added the dated section "CodeQL (GitHub CodeQL Terms) as the hosted default setup of GitHub" to More Information, and an entry in Updates. No other text and not the status are changed. The agent set `updated` of the DEC by hand, because it used a file edit for the DEC and not a specmgr tool. `specmgr lint` passes. The changes are not committed.
2. CodeQL (Task 130.100): the agent ran `gh api -X PATCH repos/{owner}/{repo}/code-scanning/default-setup -f state=configured -f query_suite=default` (no `languages` field, so GitHub chooses the detected languages). The state before was `not-configured`, and the state after is `configured`. The run `CodeQL Setup` (run 43689662335) was `in_progress` and the list of languages was still empty at the last read, so the first scan is not complete (Task 130.110). The agent ran the command after "CodeQL: go ahead" and did not show the exact command to the owner first, which the plan of Task 130.100 asked for. The setting can be turned off with the same call and `state=not-configured`.
3. Issue #7: the agent wrote a comment and closed the issue as completed, after feat-7-verification-architecture-tools was `done` on `origin/dev`.

The agent did not read the terms of GitHub for the hosted service. This is in the Blockers.

#### 2026-11-15 07:07:55.000Z - Plan written

The agent wrote the plan after the planning session of 2026-11-15. The agent read the three DEC documents of the gates, the state of the repository on `origin/dev`, the licenses of the candidate tools on the GitHub API, and the terms of CodeQL. The agent rebased `feat-8` onto `origin/dev` (the status of feat-7 is `done` there). The agent changed no file other than this plan.

### Decisions Made

<!-- Newest entry first -- prepend new entries directly below this comment. -->

#### 2026-11-15 08:51:30.000Z - The pins of the security tools: a folder tools/security/ with the vendor files, and the latest releases

The agent pinned the three tools to the latest releases that are not a pre-release: OSV-Scanner 2.7.1, gitleaks 8.30.1 and zizmor 1.32.0. For the two binaries the agent used the pattern of oasdiff: the version and the sha256 are in `tools/versions.env`, and the vendor file of the release (without a change) is the second place, in the new folder `tools/security/`. `just check-pins` compares both places, and the check is the function `check_release_checksum` that oasdiff uses too (the messages of oasdiff did not change). zizmor has a lock file `tools/python/zizmor.lock` as the other Python tools. The plan did not name the folder, so this is a decision of the agent; the owner can ask for another name. The decision about the license of the OSV data is open (see the Blockers).

#### 2026-11-15 07:07:55.000Z - One feature for Gate 2 and Gate 9, and no threshold for a security tool

The owner chose one feature for the two gates, as GitHub issue #8 asks. The security tools run as reports, and the owner turns on a threshold later from the baseline (the same way as in feat-7-verification-architecture-tools). Of the other options, two features (traceability first) was not chosen, and a block for high severity from the first run was not chosen.

#### 2026-11-15 07:07:55.000Z - CodeQL is the hosted default setup, with a deviation DEC

The owner chose the hosted default setup of GitHub, and a deviation in the register DEC 93a6d588-e002-4daf-9a47-45e2d77786e9. The agent recommended it, because the terms of CodeQL permit the use for this public repository on GitHub.com and not for a derived private repository, and the hosted setup fails safely in that case. The command line in a recipe, and a leave out of CodeQL, were not chosen. The agent runs the `gh api` command only after the owner approves the exact command.

#### 2026-11-15 07:07:55.000Z - OSV-Scanner online on the SBOM, and gitleaks and zizmor as reports

The owner chose OSV-Scanner with the online query on the SBOM files, as a report. A later threshold must stop only for the findings that are new compared with a baseline file. The owner included gitleaks as a report. The owner included zizmor as a report, also after the statement of the agent that its value is low (the gates of the workflow fix the trigger, the permissions and the pins already). The Dependabot alerts are a step for the owner.

#### 2026-11-15 07:07:55.000Z - The traceability script uses the reader of the pinned specmgr

The owner chose to import `find_references` from the pinned specmgr, and not to copy the syntax of the references. The function is not a public interface, so a self-test must show a change (ACC-004).

#### 2026-11-15 07:07:55.000Z - Conventions of the links: `specmgr-req` in the model and `vcr:<uuid>` in the name of a test

The owner chose the key `specmgr-req` for the properties of the Structurizr elements (an identifier, or a list with commas), and the text `vcr:<uuid>` in the name of a test. The reference checks and the check of an approved REQ without a VCR are errors from the start. The checks of the links of the model and the tests are warnings until the first approved REQ exists.

#### 2026-11-15 07:07:55.000Z - The AGPL clause about networks is not in this feature

The owner chose to keep the clause out of this feature. A new DEC decides the policy (a link to the source in the user interface, and the version and the commit in the status) with the feature for the walking skeleton.

### Related PRs / Commits

- [Issue #8](https://github.com/dfch/biz.dfch.SpecMgrDemo/issues/8): the traceability check and the security checks.
- Related issues: #23 (the pins of the dependencies of `cyclonedx-maven-plugin`), #31 (the cost of pull requests for documents) and #45 (the Python environment of the self-test).
- PR #46 (`feat(feat-7)`): the feature that this feature depends on (merged, commit `ecd5ee2`).
