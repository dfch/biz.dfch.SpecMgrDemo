---
classification: null
created: '2026-11-15T08:09:18.000+01:00'
id: feat-8-traceability-security-gates
status: planning
type: feat
updated: '2026-11-15T12:45:00.000+01:00'
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

- The VCR and the SYSRS entry of REQ 1ca335d7-969a-443e-9392-165fdeea99a0 (steps 4 and 5 of SOP 95b6735b-03b8-47a0-92aa-7934a4ff1519), and new REQ documents. The owner decided in Task 110.100 (2026-11-15) that the feature adds neither the VCR nor the SYSRS entry.

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
| OSV data (the database that OSV-Scanner queries) | known vulnerabilities | Not clear: the data is an aggregate of many sources with their own licenses (CC-BY 4.0, CC0, MIT, Apache-2.0, BSD, CC-BY-SA 4.0 and CC-BY-NC-ND 4.0), and the agent found no terms of use of OSV.dev for the data or the API. See the Result of the Phase 100 below | Review. Deviation accepted by the owner on 2026-11-15 (option (a)), recorded in the register DEC 93a6d588-e002-4daf-9a47-45e2d77786e9 (the section of 2026-11-15, OSV data) |
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

The OSV data (Task 100.130) was not clear, so the agent stopped and the owner decided on 2026-11-15 (see the end of this section). The agent read `docs/data.md` of github.com/google/osv.dev (master, and the page google.github.io/osv.dev/data/), the FAQ of OSV.dev, the `README.md` of OSV-Scanner at the tag v2.7.1 (the section Data Sources and Privacy) and the `LICENSE` of the repository osv.dev (Apache-2.0, for the code). The facts:

- The data of OSV.dev is a set of databases with their own license. The page names: CC-BY 4.0 (GitHub Advisory Database, PyPI Advisory Database, Go Vulnerability Database, OSS-Fuzz, PSF and others), CC0 1.0, MIT, Apache 2.0, BSD, CC-BY-SA 4.0 (Ubuntu, Alpine SecDB) and CC-BY-NC-ND 4.0 or the Chainguard License for Commercial Scanners (Chainguard / Wolfi). Converted data (Debian, Alpine, NVD) has the license of its source. The page has no license or terms for the OSV.dev aggregate or for the answers of the API.
- The FAQ says that the API has no rate limit at this time, and it gives service level objectives (a target, not a promise). The agent found no terms of use for the API, no link to terms on osv.dev, and no statement about use in CI or in a product.
- The input of OSV-Scanner is the SBOM of the project, which has Maven and npm packages. For these the main source is the GitHub Advisory Database (CC-BY 4.0, which asks for attribution). The licenses CC-BY-NC-ND (Wolfi) and CC-BY-SA (Ubuntu, Alpine) are for ecosystems that this project does not have, but the agent cannot show that OSV-Scanner never returns such a record.
- OSV-Scanner sends package names, versions, ecosystems and file hashes to api.osv.dev (the README of OSV-Scanner). Source code is not sent. The SBOM of this project is for a public repository. The tool can also ask deps.dev (for the dependency tree, and for `--licenses`), and the registries Maven Central and npm.
- DEC 84c37f7d-08cb-457d-8ab3-1db37dba9bc9 has classes for the licenses of software. It has no class for CC-BY-4.0 (the precedent is the deviation for caniuse-lite in the register DEC 93a6d588-e002-4daf-9a47-45e2d77786e9) and no rule for data that a tool queries. The agent does not decide if the DEC applies to data.

The options for the owner: (a) accept the use of the data as a deviation in the register DEC, with the condition that the report keeps the attribution of the sources (CC-BY 4.0) and that the project stores counts only; (b) a statement that the DEC does not apply to the data that a tool queries, with a short note in the DEC (a permission for one time); (c) the offline mode with a downloaded database (the same licenses, and no query of the project data to the network); (d) leave OSV-Scanner out.

The decision of the owner (2026-11-15): option (a). The owner accepted a deviation for the OSV data, with the conditions that the use is a report only, that the project keeps the attribution, that the repository has only counts and finding identifiers, and that the project does not store or redistribute the records. The agent wrote the dated section "OSV data (the OSV.dev database, mixed source licenses) that OSV-Scanner queries" and an entry of Updates in the register DEC 93a6d588-e002-4daf-9a47-45e2d77786e9, with the one-time permission of the owner (no other change of the DEC, the status is not changed). The section has the sources and licenses as found (with CC-BY-SA 4.0, and CC-BY-NC-ND 4.0 / Chainguard for Wolfi), what OSV-Scanner sends to api.osv.dev, the conditions, the exposure that the project cannot exclude, and what happens if the condition ends (the recipe `vuln-scan` and its CI job must be switched off until the owner decides again). The agent did not read the terms of Google for the service or the license texts of the single sources, and a person who has competence in the law has not examined the section (this is in the section and in the Blockers). The result of the row is Review, as for CodeQL, and the license table has no row with the result open.

#### Baseline

The baseline is the measured state of the findings of the four security tools on 2026-11-15 (Phase 130, ACC-009). **No threshold is set.** Each value is a count for a report, and no gate, recipe, CI job or file in the repository compares a run with these values. The owner or the feature for the walking skeleton can set a threshold from them later (a threshold must then be new compared with a baseline file, see `tools/security/README.md`). The agent wrote no baseline file for the tools.

The date and the scope of the runs:

| Item | Value |
|---|---|
| CodeQL: the scan | The default setup of GitHub, state `configured` (languages: actions, java-kotlin, javascript, javascript-typescript, python, typescript; query suite `default`; schedule weekly). The run `CodeQL Setup` (43689662335) was `completed` with the result `success` on 2026-11-15 (07:22 UTC) and its four jobs `Analyze (...)` were `success` |
| CodeQL: what was analyzed | The default branch `dev` at the commit `ecd5ee200e39bc6a77685774da4b6a9748b2cf7a` (the head of `dev` on 2026-11-15 at the read). The branch `feat-8` is not pushed, so the baseline of CodeQL is that of `dev` and does not have the changes of this feature. The four analyses have `error` and `warning` empty, and the build mode is `none` |
| CodeQL: the version | CodeQL 2.27.4 (the version of the analyses, `tool.version`). It is not pinned (the setup is hosted, see the section CodeQL) |
| The three recipes: what was scanned | The working tree of the branch `feat-8` at the commit `399ab939a279bffe55043ea8d94d0645a7014e21` (7 commits after `origin/dev` = `ecd5ee2`, with no change in the working tree). The runs were on 2026-11-15 between 12:34 and 12:38 (UTC+01:00, 11:34 to 11:38 UTC) |

CodeQL (Task 130.110). The agent read the analyses with `gh api repos/dfch/biz.dfch.SpecMgrDemo/code-scanning/analyses` (4 analyses) and the alerts with `gh api repos/dfch/biz.dfch.SpecMgrDemo/code-scanning/alerts --paginate` (the state open, dismissed and fixed, and the ref `refs/heads/dev`: 0 alerts each). The token had the scope for the read of the alerts. The `rules_count` is the number of queries that the analysis ran:

| Language (the category of the analysis) | Analyzed commit | Queries | Alerts | Critical | High | Medium | Low | Note / Error |
|---|---|---|---|---|---|---|---|---|
| actions (`/language:actions`) | `ecd5ee2` | 17 | 0 | 0 | 0 | 0 | 0 | |
| java-kotlin (`/language:java-kotlin`) | `ecd5ee2` | 76 | 0 | 0 | 0 | 0 | 0 | |
| javascript-typescript (`/language:javascript-typescript`) | `ecd5ee2` | 87 | 0 | 0 | 0 | 0 | 0 | The labels `javascript` and `typescript` of the setup are covered by this one analysis |
| python (`/language:python`) | `ecd5ee2` | 43 | 0 | 0 | 0 | 0 | 0 | |
| Total | | 223 | 0 | 0 | 0 | 0 | 0 | |

The first scan is complete: an analysis exists for each of the four languages with the result `success`, and the first scan of `dev` has no alert. An empty list of alerts is a valid result. It says that the default queries found nothing on this commit. It does not say that the code has no vulnerability.

Recipes (Task 130.120). The recipes ran as in CI: `just vuln-scan` (it makes the SBOM files first), `just secret-scan` (the base `origin/dev`) and `just workflow-scan`. Each recipe ended with exit code 0 (a report with no threshold, ACC-005).

| Tool | Version | Result | Findings | By severity |
|---|---|---|---|---|
| OSV-Scanner | 2.7.1 (the pin of `tools/versions.env`, `osv-scalibr` 0.5.3, build 2026-11-09, sha256 of the binary compared at the install) | The tool exit code was 1 (findings), the recipe ended with 0 | 5 vulnerabilities in 2 of the 432 packages of the two SBOM files (`backend.cdx.json` 12 packages, 0 findings; `frontend.cdx.json` 420 packages, 5 findings) | 0 Critical, 0 High, 5 Medium, 0 Low, 0 Unknown (the summary line of the report). The CVSS is 6.9 for 1 finding and 6.3 for 4 findings. The identifiers: `minimatch` 10.2.6 (GHSA-g3hv-75wg-m249); `qs` 6.15.1 (GHSA-4mjr-xmp4-gh2g, GHSA-6pq8-jhm2-2vcw, GHSA-q8mj-m7cp-5q26, GHSA-x5fp-wj9c-mxmx). All are in the npm ecosystem, and the report names a fixed version for each |
| gitleaks | 8.30.1 (the pin of `tools/versions.env`, sha256 of the archive compared at the install) | The tool exit code was 0 (no finding) | 0 in the files (a copy of the 2.64 MB of the files that git knows or `.gitignore` does not ignore), 0 in the history `origin/dev..HEAD` (7 commits). The run of Phase 120 over the whole history (158 commits) also had 0 | No severity (gitleaks has none). The rules are the default rules of the release (`useDefault = true`, the allowlist `tools/security/gitleaks.toml` has no entry) |
| zizmor | 1.32.0 (the lock file `tools/python/zizmor.lock`, `--offline`) | The tool exit code was 13 (findings), the recipe ended with 0 | 12 findings in 1 workflow file (`.github/workflows/ci.yml`): 11 shown and 1 suppressed. The 11 shown are all the audit `artipacked` ("credential persistence through GitHub Actions artifacts": `actions/checkout` has no `persist-credentials: false`, 11 of the 23 steps `actions/checkout`). The summary does not say which finding is the suppressed one, and the repository has no `zizmor` ignore comment or configuration file | 0 informational, 0 low, 11 medium, 0 high (the summary line of the report, `12 findings (1 suppressed, 11 unsafe fixes)`). The suppressed finding is not in the count of the severities, so the severities add up to 11 |

The state of the databases and rules (Task 130.120):

- OSV-Scanner: the query goes online to `api.osv.dev` for the packages of the SBOM files. The data is **not pinned** and not a snapshot of this repository: the count depends on the state of OSV.dev at the time of the query (2026-11-15, 12:34 to 12:35 UTC+01:00), and a later run can give another count for the same files. The tool does not print a version or a date of the database. The SBOM files are the output of `just sbom` of the same commit (`cdxgen` 12.9.0 and `cyclonedx-maven-plugin`, with `axe-core` and `caniuse-lite` removed by the script, see feat-7-verification-architecture-tools). The option `--licenses` was not used, and the records are not stored (the conditions of the deviation for the OSV data in the register DEC 93a6d588-e002-4daf-9a47-45e2d77786e9). The repository has the counts and the finding identifiers only. The data is OSV.dev (https://osv.dev) with the licenses of its sources (for example the GitHub Advisory Database, CC-BY 4.0).
- gitleaks: no database. The rules are built into the release 8.30.1 (the pin fixes them).
- zizmor: no database. The audits are built into the release 1.32.0, and `--offline` turns off the audits that need the network (no token). The pin fixes the rules.
- CodeQL: the queries are those of the hosted `default` query suite and the version of CodeQL is 2.27.4 on the date of the analysis (2026-11-15, 07:23 to 07:24 UTC). It is not pinned: GitHub updates it, and the weekly schedule runs it again.

The values to keep (the counts for the later comparison): CodeQL 0 alerts (actions 0, java-kotlin 0, javascript-typescript 0, python 0); OSV-Scanner 5 (0 Critical, 0 High, 5 Medium, 0 Low, 0 Unknown); gitleaks 0; zizmor 12 (11 shown: 0 informational, 0 low, 11 medium, 0 high; 1 suppressed).

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

- [x] Task 100.130: Read the terms of use of the OSV data that OSV-Scanner queries, and fill the row. If the terms are not clear, the work stops and the owner decides. Done on 2026-11-15: the terms are not clear (see the Result of the Phase 100), and the owner decided on option (a), a deviation in the register DEC 93a6d588-e002-4daf-9a47-45e2d77786e9. The row has the result Review

- [x] Task 100.140: Record the terms of CodeQL in the license table (the file and the date of the read), and write the text of the deviation for the register DEC 93a6d588-e002-4daf-9a47-45e2d77786e9. Do not change the DEC before the owner gives a one-time permission. Done on 2026-11-15: the owner gave the one-time permission, and the dated section is in the DEC (see Updates)

- [x] Task 100.150: Select the version of each tool, and write the pins in `tools/versions.env` (the version, and the sha256 for the binary of gitleaks and of OSV-Scanner). Make the lock file with hashes for zizmor, as in feat-22-python-tools-lockfile. Extend the gate check-pins for the new pins. Done on 2026-11-15: OSV-Scanner 2.7.1, gitleaks 8.30.1, zizmor 1.32.0 (see the Result of the Phase 100 and the entry of Updates)

- [ ] Task 100.160: The owner reviews the license table and the deviation text, and gives the permission for the entry in the register DEC (ACC-007, ACC-008). Open on 2026-11-15: the owner gave the permission for the sections of CodeQL and of the OSV data (one-time permissions for the register DEC), but the owner has not yet reviewed the whole table

#### Phase 110: Gate 2, the Traceability Check

- [x] Task 110.100: Read the VCR document structure and the REQ status values. Define "an approved REQ has a VCR" with these (the link between a VCR and a REQ), and ask the owner if the feature adds the VCR and the SYSRS entry for REQ 1ca335d7-969a-443e-9392-165fdeea99a0 as a positive example. Do not assume the answer. Done on 2026-11-15: an approved REQ is a REQ with the status `accepted` or `implemented`, and the VCR of a REQ is a VCR whose section `## Verifies` has the reference `REQ <uuid>` of the REQ (see the Decisions Made). The owner answered that the feature adds neither the VCR nor the SYSRS entry (the positive case is shown by the fixtures only)

- [x] Task 110.110: Write the script of the traceability check. It runs in the hash-locked environment of specmgr, imports `find_references` and applies the table of checks of the Design Notes. It prints each finding with the file and the rule, and the warnings apart from the errors. Done on 2026-11-15: `tools/gates/traceability.py` (the checks) and `tools/gates/traceability.sh` (the hash-locked environment). It examines the form of `find_references` before each run (exit code 2 if it is not the expected form)

- [x] Task 110.120: Write the reader of the identifiers in the Structurizr workspace (`specmgr-req`) and in the test sources (`vcr:<uuid>`) for the backend and the frontend. Done on 2026-11-15: the functions `read_model` and `read_tests` in `tools/gates/traceability.py`. The tests are the `.java` and `.kt` files in `backend/src/test/`, and the TypeScript and JavaScript files in `frontend/src/test/` and `frontend/e2e/`

- [x] Task 110.130: Write the recipe and the gate script in `tools/gates/` in the form of the other gates. Fix the recipe names of Phase 120 and of the CI jobs. Done on 2026-11-15: the recipe `traceability` (script `traceability.sh`, number 110.130) and the recipe `test-traceability-gate`. The names for the next phases do not change: `vuln-scan`, `secret-scan` and `workflow-scan`, and the CI jobs have the names of the recipes (`traceability`, `vuln-scan`, `secret-scan`, `workflow-scan`). The CI workflow and `required-setup.txt` are not changed (Phase 140)

- [x] Task 110.140: Add the property `specmgr-req` to the component of `model/workspace.json` that the REQ 1ca335d7-969a-443e-9392-165fdeea99a0 needs. Run the architecture tests of feat-7-verification-architecture-tools (`just architecture-model`) to show that the property does not break the comparison. Done on 2026-11-15: the component `api` has the property. The first run of `just architecture-model` showed that the frontend side (`frontend/architecture/compare.mjs`, a strict reader) stopped for the key `properties`, so the script accepts the key now (see the Decisions Made). The run is green after that change (6 ok, 0 failed)

- [x] Task 110.150: Write the fixtures and the self-test: each case of ACC-002 and ACC-003, the case that is successful, and the test of ACC-004 (the function of the reader). Add the self-test to `just test-gates`. Done on 2026-11-15: `tools/gates/test-traceability-gate.sh` (45 cases) with `tools/gates/fixtures/traceability/` and `tools/gates/fixtures/traceability-reader/`. The recipe `test-traceability-gate` is a prerequisite of `test-gates`

- [x] Task 110.160: Write the conventions (`specmgr-req` and `vcr:<uuid>`) and the check levels in `tools/gates/README.md` and in the READMEs of `model/` and of the tests. Tell the owner that DEC f21920d2-4da5-4cf7-bd94-2e9bcba77342 does not have them. Done on 2026-11-15: the section "The traceability check (Gate 2)" in `tools/gates/README.md`, and the sections in `model/README.md`, `backend/README.md` and `frontend/README.md`. The DEC is not changed. The notice for the owner is in the Blockers and in the entry of Updates of 2026-11-15 11:35

#### Phase 120: Gate 9, the Security Recipes

- [x] Task 120.100: Write the function that separates a finding from a failure of the tool, with the self-test (ACC-005). Done on 2026-11-15: `security_classify` and `run_security_tool` in `tools/gates/_security.sh`, and part 1 of `tools/gates/test-security-gates.sh` (the table of exit codes of the three tools, the markers, 39 cases)

- [x] Task 120.110: Write the recipe `vuln-scan` (OSV-Scanner on the SBOM files of `just sbom`), the install script with the sha256, and the self-test with a stub for the tool and the network. Done on 2026-11-15: the recipe `vuln-scan` (prerequisite `sbom`), `tools/gates/vuln-scan.sh`, `install_osv_scanner` in `_security.sh`, and part 2 of the self-test (a stub of the tool, the install with a `file://` URL, and the real tool without network by a proxy that refuses the connection)

- [x] Task 120.120: Write the recipe `secret-scan` (gitleaks), the install script with the sha256, and the allowlist for the fixtures of the gates. The allowlist has an entry for each false positive with the reason. CODEOWNERS covers the file. Done on 2026-11-15: the recipe `secret-scan`, `tools/gates/secret-scan.sh`, `install_gitleaks`, `tools/security/gitleaks.toml` and the line for it in `.github/CODEOWNERS`. The allowlist has no entry: the first run found no false positive (see the Decisions Made)

- [x] Task 120.130: Write the recipe `workflow-scan` (zizmor with `--offline`), and the self-test with a workflow that has a known problem. Done on 2026-11-15: the recipe `workflow-scan`, `tools/gates/workflow-scan.sh`, the fixtures in `tools/gates/fixtures/security/` (a clean workflow, a workflow with a known problem, a file that cannot be read) and part 4 of the self-test

- [x] Task 120.140: Write the README of the security gates (the tools, the exit codes, the form of the report, how a later threshold works with a baseline file). Add the new scripts to `tools/gates/README.md`. Done on 2026-11-15: `tools/security/README.md` and the rows and the section "The security gates (Gate 9)" in `tools/gates/README.md`. The recipe `test-security-gates` is a prerequisite of `test-gates`

#### Phase 130: CodeQL and Baseline

- [x] Task 130.100: Show the exact `gh api` command for the default setup of CodeQL to the owner. Run it only after the approval, and record the command and the result. Done on 2026-11-15: the owner approved with "CodeQL: go ahead", and the command was run (see Updates). The agent did not show the exact command before the run (see the entry of Updates)

- [x] Task 130.110: Wait for the first complete scan, and read the alerts with `gh api repos/{owner}/{repo}/code-scanning/alerts`. Record the number of alerts for each language and each severity. Done on 2026-11-15: the first scan was complete when the agent looked (the run `CodeQL Setup` 43689662335 `success`, 4 analyses with `error` empty, all on `dev` at `ecd5ee2`), and the alerts are 0 for each language and each severity (see the subsection Baseline)

- [x] Task 130.120: Run the three recipes on the repository, and record the baseline (the number of findings of each severity for OSV-Scanner, the number of findings of gitleaks, the number of findings of zizmor). Record the date, the version of each tool and the state of the databases. Done on 2026-11-15: OSV-Scanner 2.7.1 5 findings (all Medium), gitleaks 8.30.1 0 findings, zizmor 1.32.0 12 findings (11 Medium shown, 1 suppressed); the date, the versions and the state of the databases are in the subsection Baseline

- [x] Task 130.130: Write the baseline in the subsection Baseline of the Design Notes, with the values of Task 130.110 and 130.120. Do not set a threshold (ACC-009). Done on 2026-11-15: the subsection Baseline of the Design Notes has the values, and it says that no threshold is set. The agent wrote no baseline file for the tools

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

**Update 2026-11-15 (Phase 100)**: Tasks 100.100, 100.110, 100.120 and 100.150 are done. OSV-Scanner (Apache-2.0), gitleaks (MIT) and zizmor (MIT) are Permitted, and the pins are in `tools/versions.env` and checked by `just check-pins` (OSV-Scanner 2.7.1, gitleaks 8.30.1, zizmor 1.32.0 with `tools/python/zizmor.lock`). Task 100.130 (the terms of the OSV data) was not clear, and the owner decided on option (a) (see the update below). Task 100.160 is for the owner. No recipe, no install script and no workflow is changed.

**Update 2026-11-15 (Task 100.130)**: The owner decided on option (a): a deviation for the OSV data. The dated section "OSV data (the OSV.dev database, mixed source licenses) that OSV-Scanner queries" and an entry of Updates are in the register DEC 93a6d588-e002-4daf-9a47-45e2d77786e9 (the one-time permission of the owner; no other change, the status is not changed). The row of the license table has the result Review, and Task 100.130 is done. No row of the license table has the result open. Task 100.160 stays open: the owner has not yet reviewed the whole table. The conditions of the deviation apply to Phase 120 (`vuln-scan`): a report only, the repository has counts and finding identifiers only, the attribution is kept (the README of the security gates), no copy of the records, and no use of the option `--licenses` of OSV-Scanner.

**Update 2026-11-15 (Phase 110)**: Phase 110 is done (Tasks 110.100 to 110.160). The recipe `just traceability` (Gate 2) and its test `just test-traceability-gate` exist, and the test is a part of `just test-gates`. The real repository passes (the only REQ has the status `draft`, no VCR is needed, and all 193 unique references of the 58 document files have a target). The component `api` of `model/workspace.json` has the property `specmgr-req` with the identifier of the REQ "The System Gives Its Status". The CI workflow and `required-setup.txt` are not changed (Phase 140). The next step is Phase 120 (the security recipes).

**Update 2026-11-15 (Phase 120)**: Phase 120 is done (Tasks 120.100 to 120.140). The recipes `just vuln-scan` (OSV-Scanner, the prerequisite is `sbom`), `just secret-scan` (gitleaks) and `just workflow-scan` (zizmor, `--offline`) exist, and each runs as a report with no threshold: a finding ends with exit code 0, and a failure of the tool ends with exit code 1 (ACC-005). One function separates the two cases for the three tools (`tools/gates/_security.sh`). The binaries of OSV-Scanner and gitleaks are installed to `build/tools/` with the sha256 of `tools/versions.env` (ACC-006), and zizmor from its lock file. The self-test `just test-security-gates` (137 cases, with stubs and with the three real tools) is a prerequisite of `just test-gates`. The first real runs on the repository are not the baseline (Phase 130): OSV-Scanner 5 vulnerabilities (all Medium) in 2 packages of the frontend SBOM, gitleaks 0 findings, zizmor 12 findings (11 shown and 1 suppressed, all `artipacked`, Medium). The allowlist of gitleaks (`tools/security/gitleaks.toml`, covered by CODEOWNERS) has no entry because there is no false positive. The CI workflow and `required-setup.txt` are not changed (Phase 140). The next step is Phase 130 (CodeQL and the baseline).

**Update 2026-11-15 (Phase 130)**: Phase 130 is done (Tasks 130.100 to 130.130). The first CodeQL scan of `dev` is complete (4 analyses, one for each language group, at the commit `ecd5ee2`, no error) and has 0 alerts. The three recipes ran on the branch `feat-8` (commit `399ab93`): OSV-Scanner 5 vulnerabilities (all Medium), gitleaks 0 findings, zizmor 12 findings (11 shown, all `artipacked` and Medium, 1 suppressed). The values, the dates, the versions and the state of the databases are in the subsection Baseline of the Design Notes. No threshold is set and no baseline file is written (ACC-009; the criterion stays open until the review of Phase 150). The CodeQL baseline is that of `dev`, because `feat-8` is not pushed. The agent changed no setting of the repository (it used `gh api` for GET only), no workflow, no DEC and no file other than this plan. The next step is Phase 140 (CI and branch protection).

### Blockers

- The conventions `specmgr-req` (the property of an element of the model) and `vcr:<uuid>` (the text in the name of a test) are not in DEC f21920d2-4da5-4cf7-bd94-2e9bcba77342. The DEC says only "a `properties` entry" for the model and "the name or an annotation" for a test. The conventions are now in `tools/gates/README.md`, `model/README.md`, `backend/README.md`, `frontend/README.md` and in this plan. The agent did not change the DEC. The owner decides if the conventions go into More Information of the DEC (this needs a one-time permission), and if the annotation stays an option (the check reads the name only). The same for the definition of an "approved REQ" (the status `accepted` or `implemented`): the DEC says "an approved REQ" and the REQ has no status `approved`.

- The owner must review the whole license table and the deviation texts of CodeQL and of the OSV data (Task 100.160). Both deviations are written in the register DEC 93a6d588-e002-4daf-9a47-45e2d77786e9. For CodeQL, the agent did not read the terms of GitHub for the hosted service (the GitHub Terms of Service and the terms for GitHub Advanced Security). For the OSV data, the agent did not read the terms of Google for the service or the license texts of the single sources, and it cannot exclude a record with the license CC-BY-SA 4.0 or CC-BY-NC-ND 4.0 from an ecosystem that the project does not have. A person who has competence in the law has not examined either section.

- The AGPL clause about use through a network is open in DEC 84c37f7d-08cb-457d-8ab3-1db37dba9bc9. It does not stop this feature, and it needs a new DEC with the feature for the walking skeleton.

- GitHub issue #31 (the cost of pull requests for documents) is not decided. It can change which gates run for a pull request that has only documents.

### Updates

<!-- Newest entry first -- prepend new entries directly below this comment. -->

#### 2026-11-15 12:45:00.000Z - Phase 130: CodeQL scan read and baseline of the four security tools

The agent did Tasks 130.110 to 130.130 (Task 130.100 was done before). The time of this entry is the local time with the letter Z, as for the earlier entries.

1. CodeQL (Task 130.110): the agent used `gh api` with GET only (`code-scanning/default-setup`, `code-scanning/analyses`, `code-scanning/alerts` with `--paginate` and the states open, dismissed and fixed and the ref `refs/heads/dev`, `actions/runs` and `actions/runs/43689662335/jobs`). The setting is `configured` (actions, java-kotlin, javascript, javascript-typescript, python, typescript; `default`; weekly). The run `CodeQL Setup` 43689662335 is `completed`/`success` and its four jobs `Analyze (...)` are `success` (`Adjust Configuration` was skipped). The four analyses (`/language:actions`, `/language:java-kotlin`, `/language:javascript-typescript`, `/language:python`) are on `refs/heads/dev` at the commit `ecd5ee200e39bc6a77685774da4b6a9748b2cf7a` (the head of `dev` at the read), with `error` and `warning` empty, CodeQL 2.27.4, build mode `none`, and 17, 76, 87 and 43 queries. The alerts: 0 in every state. The first scan was complete at the first read, so the agent did not wait. The token had the scope for the read of the alerts.
2. Recipes (Task 130.120): `just vuln-scan`, `just secret-scan` and `just workflow-scan` ran on `feat-8` at `399ab93` (7 commits after `origin/dev`, the working tree was clean before and after the runs). OSV-Scanner 2.7.1: 5 vulnerabilities in 2 of 432 packages, 0 Critical, 0 High, 5 Medium, 0 Low, 0 Unknown (the summary line of the report). gitleaks 8.30.1: 0 in the files and 0 in `origin/dev..HEAD` (7 commits). zizmor 1.32.0: `12 findings (1 suppressed, 11 unsafe fixes): 0 informational, 0 low, 11 medium, 0 high`. Each recipe ended with exit code 0.
3. Baseline (Task 130.130): the subsection Baseline of the Design Notes has the tables, the date and time, the commits, the versions and the state of the databases (the OSV data is queried online and is not pinned; gitleaks and zizmor have the rules in the release; CodeQL is not pinned). It says that no threshold is set. The agent wrote no baseline file for the tools and set no threshold.
4. The agent changed no setting of the repository, no workflow, no DEC and no file other than this plan. The changes are not committed. The acceptance criteria ACC-007 and ACC-009 are not ticked: Task 150.100 does that with the evidence, and ACC-007 also needs the review of the owner (Task 100.160).

#### 2026-11-15 12:15:00.000Z - Phase 120: Gate 9, the security recipes

The agent did Tasks 120.100 to 120.140. The time of this entry is the local time with the letter Z, as for the earlier entries.

1. The function (Task 120.100): `tools/gates/_security.sh` has `security_classify <exit code> <finding codes>` (the word `clean`, `finding` or `failure`) and `run_security_tool <label> <finding codes> <finding marker> <failure marker> -- <command>` (it starts the tool, writes the output, and sets `SECURITY_RESULT`, `SECURITY_EXIT` and `SECURITY_OUTPUT`; it returns 0 for clean and finding and 1 for failure). The exit codes were checked in the documentation of the pinned releases and by a run of each tool: OSV-Scanner 0 clean, 1 findings, 127 general error (the run without network gives 127 and a table with 0 packages), 128 no packages found; gitleaks 0 clean, with `--exit-code 2` the code 2 is "leaks found", 1 is a fatal error (a wrong config, a path that does not exist), 126 is a wrong flag; zizmor 0 clean, 11 to 14 findings, 1 error, 2 wrong argument, 3 no inputs collected. Each other code is a failure. Two more checks: a finding code of gitleaks is accepted only if the output has "leaks found" (a Go crash has exit code 2 too), and an output with an `ERR` or `FTL` line is a failure (gitleaks ends with exit code 0 and an `ERR` line if git cannot read `--log-opts`, and scans 0 commits).
2. `vuln-scan` (Task 120.110): `tools/gates/vuln-scan.sh <sbom dir>` starts `osv-scanner scan source --no-resolve -L <file> ...` for the files `<sbom dir>/*.cdx.json`. No `--licenses` (the condition of the OSV deviation). The script prints the summary line and the attribution of the OSV data after the report. `install_osv_scanner` downloads `osv-scanner_linux_amd64`, compares its sha256 with `OSV_SCANNER_SHA256` before it makes the file executable, and keeps the binary in `build/tools/osv-scanner-<version>/` with a file `.sha256`.
3. `secret-scan` (Task 120.120): `tools/gates/secret-scan.sh <base> <config>` scans (1) a copy of the files that git knows or that `.gitignore` does not ignore (`gitleaks dir .`, relative paths) and (2) the history `<base>..HEAD` (`gitleaks git <git dir>`). A shallow clone with no merge base stops the script (exit code 1, `fetch-depth: 0`). `install_gitleaks` is the same as the install of OSV-Scanner, for `gitleaks_<version>_linux_x64.tar.gz` (it unpacks `gitleaks` and `LICENSE` only). The config is `tools/security/gitleaks.toml` (`useDefault = true`, no allowlist entry), and `.github/CODEOWNERS` has an own line for it.
4. `workflow-scan` (Task 120.130): `tools/gates/workflow-scan.sh <path>...` installs zizmor from `tools/python/zizmor.lock` (`make_python_env zizmor`), checks the version of the installed binary, and starts `zizmor --offline --no-progress --color never --strict-collection`. The fixtures are in `tools/gates/fixtures/security/`.
5. Self-test (Tasks 120.100 to 120.130): `tools/gates/test-security-gates.sh` (137 cases, about 45 seconds with the real tools in the cache of `build/tools/`). Part 1 the function, part 2 `vuln-scan` (a stub, the install with a `file://` URL, and the real tool without network and with an SBOM with no package and with an SBOM that cannot be read), part 3 `secret-scan` (a stub, the install, and the real gitleaks in temporary repositories: a secret in a file, in the history only, in the base only, not committed, ignored by git, a `gitleaks:allow` comment, a `.gitleaksignore` file, an allowlist entry, a wrong config, a shallow clone), part 4 `workflow-scan` (the real zizmor), part 5 the form of the scripts, the recipes and CODEOWNERS. The fake secrets are made while the test runs. The recipe `test-security-gates` is a prerequisite of `test-gates`.
6. Documents (Task 120.140): `tools/security/README.md` (the tools, the exit codes, the form of the report, the conditions of the OSV deviation, what `secret-scan` scans, the allowlist, and the way of a later threshold with a baseline file), `tools/gates/README.md` (the rows of the recipes, the tools table, the section "The security gates (Gate 9)", the rows of the checksums), `tools/README.md`, `tools/python/README.md` and the comments of `tools/versions.env`.
7. The real runs on the repository (not the baseline, Phase 130 records it): `just vuln-scan` found 5 vulnerabilities, all Medium, in 2 packages of the 420 packages of `frontend.cdx.json` (`minimatch` 10.2.6: GHSA-g3hv-75wg-m249; `qs` 6.15.1: GHSA-4mjr-xmp4-gh2g, GHSA-6pq8-jhm2-2vcw, GHSA-q8mj-m7cp-5q26, GHSA-x5fp-wj9c-mxmx), and none in the 12 packages of `backend.cdx.json` (exit code 0). `just secret-scan` found 0 in the files and 0 in `origin/dev..HEAD` (6 commits), and a run of `gitleaks git` over the whole history (158 commits) found 0 (exit code 0). `just workflow-scan` found 12 findings (1 suppressed, 11 shown, all `artipacked` in `.github/workflows/ci.yml`, Medium: `actions/checkout` has no `persist-credentials: false`), exit code 0. The agent changed no workflow, as the gates of the workflow fix it (Phase 140 and the owner decide).
8. The agent changed no setting of the repository, no DEC, not `ci.yml` and not `required-setup.txt`. The changes are not committed.

#### 2026-11-15 11:35:00.000Z - Phase 110: Gate 2, the traceability check

The agent did Tasks 110.100 to 110.160. The time of this entry is the local time with the letter Z, as for the earlier entries.

1. Definitions (Task 110.100): the REQ model has the statuses `draft`, `proposed`, `accepted`, `superseded`, `deprecated`, `rejected` and `implemented` (no `approved`), and the VCR model has `draft`, `progress`, `complete` and `approved`. A VCR has exactly one link, the section `## Verifies` (`REQ <uuid>: <title>` or `UC <uuid>: <title>`). The check defines "an approved REQ has a VCR" this way: an approved REQ is a REQ with the status `accepted` or `implemented`, and a VCR of a REQ is a VCR whose section `## Verifies` has the reference `REQ <uuid>` of this REQ (any VCR status). The owner answered the question about the positive example: the feature adds neither the VCR nor the SYSRS entry for REQ 1ca335d7-969a-443e-9392-165fdeea99a0. The positive case is shown by the fixtures only.
2. The check (Tasks 110.110, 110.120): `tools/gates/traceability.py` and `tools/gates/traceability.sh`. The rules are `reference-has-no-target`, `openapi-req-not-found`, `model-id-has-no-document`, `test-vcr-has-no-document` and `approved-req-has-no-vcr` (errors, exit code 1), and `approved-req-has-no-model-element` and `approved-req-vcr-not-in-test` (warnings, exit code 0). The output has the warnings and the errors as two parts, and each finding has the file (with the line if there is one) and the rule. Exit code 2 is for an input that cannot be read, and for a reader of references with another form. The script imports `find_references` of the pinned specmgr and has no second copy of the syntax of the references. It examines the form of the function before each run (the parameter `text`, and the pairs for a probe text).
3. Recipes and names (Task 110.130): `just traceability` (`traceability.sh`, 110.130) and `just test-traceability-gate` (`test-traceability-gate.sh`, 110.150). The recipe names of the next phases and the names of the CI jobs do not change: `vuln-scan`, `secret-scan`, `workflow-scan` and `traceability`. The CI workflow and `required-setup.txt` are not changed (Phase 140).
4. Model (Task 110.140): the component `api` of `model/workspace.json` has `"specmgr-req": "1ca335d7-969a-443e-9392-165fdeea99a0"`. The first run of `just architecture-model` was not green: the backend side (structurizr-java) read the key, but the frontend side (`frontend/architecture/compare.mjs`, a strict reader) stopped for the key `properties` (exit code 2, and the four steps of ACC-003 that use the frontend were not successful). The agent changed `compare.mjs`: the software system, the container and the component can have the key `properties` (a map of texts, and the script stops if the value is not a map of texts), and the script does not use the values. The second run was green (6 ok, 0 failed).
5. Fixtures and self-test (Task 110.150): `tools/gates/test-traceability-gate.sh` has 45 cases. The case that is successful, the five errors of ACC-002 (a reference with no target: a REQ, a FEAT and an identifier of another type; an `x-specmgr-req` that is not a REQ: no document and a DEC; an identifier in the model with no document: no document and a VCR; a `vcr:<uuid>` with no document in the backend, in the frontend and in the end-to-end tests; an approved REQ with no VCR, with the status `implemented` and `accepted`), the two warnings of ACC-003 (exit code 0), the other statuses of a REQ (no error), the input that cannot be read (exit code 2), and the form of the reader (ACC-004: no function, another parameter, another result, another case of the type, an error, a module that does not exist). It also runs the entry `traceability.sh` on the real repository.
6. Conventions (Task 110.160): the sections are in `tools/gates/README.md`, `model/README.md`, `backend/README.md` and `frontend/README.md`. The agent also changed one sentence in `contracts/README.md` (it said that GitHub issue #8 has the check of the `x-specmgr-req`) and one sentence in `tools/README.md`. DEC f21920d2-4da5-4cf7-bd94-2e9bcba77342 does not have the conventions `specmgr-req` and `vcr:<uuid>`, and not the definition of an approved REQ. The agent did not change the DEC. This is the notice for the owner (see the Blockers).
7. The real run: `just traceability` passes (58 document files, 193 unique references, all have a target, 1 REQ with the status `draft`, 0 VCR, 1 identifier in the OpenAPI file, 1 in the model, 0 in the tests, no warning). The check found no reference in the repository that has no target, so no reference is excluded.
8. The agent changed no setting of the repository, no workflow, no DEC and not `required-setup.txt`. The changes are not committed.

#### 2026-11-15 09:44:00.000Z - Task 100.130: the owner accepts a deviation for the OSV data, and the section is in the register DEC

The owner decided on 2026-11-15 on option (a) for the OSV data: a deviation in the register DEC, with the attribution kept, only counts and finding identifiers stored, and no storage or redistribution of the records. The owner's choice is the one-time permission to add one dated section and one entry of Updates to the register DEC 93a6d588-e002-4daf-9a47-45e2d77786e9, and no other change. The agent did this (the time of this entry is the local time with the letter Z, as for the earlier entries):

1. Register DEC: the section "OSV data (the OSV.dev database, mixed source licenses) that OSV-Scanner queries" in More Information (after the section of CodeQL), and an entry in Updates. The text has the sources and licenses as the agent found them (CC-BY 4.0, CC0, MIT, Apache-2.0, BSD, CC-BY-SA 4.0, and CC-BY-NC-ND 4.0 / Chainguard License for Commercial Scanners for Wolfi), the statement that no terms of use of OSV.dev were found, what OSV-Scanner sends to api.osv.dev (package names, versions, ecosystems and file hashes, no source code), the conditions (a report only, no copy of the records, counts and finding identifiers in the repository, the attribution kept, no use of `--licenses`), the exposure that cannot be excluded (a record with CC-BY-SA 4.0 or CC-BY-NC-ND 4.0 from an ecosystem that the project does not have), and what happens if the condition ends (the recipe `vuln-scan` and its CI job are switched off until the owner decides again; the offline mode ends the transmission only and not the license question). The status of the DEC and the other sections are not changed. The agent used the tool `edit` of specmgr, so `updated` of the DEC is set by the tool.
2. This plan: the row of the OSV data of the license table has the result Review (the deviation accepted by the owner on 2026-11-15, option (a)). Task 100.130 is done. The Current Status and the Blockers are updated (the OSV blocker is removed).
3. Task 100.160 stays open. The owner has not yet reviewed the whole license table. The Blockers say that the texts of CodeQL and of the OSV data have not been examined by a person who has competence in the law.

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

#### 2026-11-15 12:45:00.000Z - Phase 130: the baseline is the state of `dev` for CodeQL and of `feat-8` for the recipes, and a zero is a value

1. **The scan of CodeQL is that of `dev`**: the default setup scans the default branch and the pull requests, and `feat-8` is not pushed. So the baseline of CodeQL is the commit `ecd5ee2` of `dev`, and it does not have the code of this feature. The recipes ran on the commit of `feat-8` (`399ab93`), which has the files of this feature. The two scopes are in the subsection Baseline. The plan did not say which commit.
2. **A count of zero is recorded as a value**: CodeQL has 0 alerts and gitleaks has 0 findings. The agent did not treat this as a missing scan, because the analyses exist with the result `success` and no error (the check of "complete" was the run, the four jobs, and the four analyses). The `rules_count` of each analysis is in the table to show that queries ran.
3. **The zizmor count has 12, and the severities add up to 11**: the summary line of zizmor says `12 findings (1 suppressed, ...)` and counts the severities of the 11 shown findings. The agent recorded both numbers as zizmor prints them and did not invent the suppressed finding. The owner can ask for a look at the suppressed finding when a threshold is set.
4. **The OSV counts are those of the time of the query**: the data is queried online and is not pinned, so the baseline of OSV-Scanner is a measure of 2026-11-15 and not a value that a later run must reproduce. The deviation of the OSV data limits what the repository keeps (counts and finding identifiers).
5. **No threshold and no baseline file**: as the owner decided (see "One feature for Gate 2 and Gate 9, and no threshold for a security tool"), the values are in this plan only, and nothing in the repository reads them.

#### 2026-11-15 12:15:00.000Z - Phase 120: the function, the exit codes, the scan of gitleaks, the empty SBOM and the allowlist

1. **The home of the code**: a new file `tools/gates/_security.sh` (it sources `_lib.sh`) has the function that separates a finding from a failure of the tool and the two install functions, and not `_lib.sh`. The three scripts and the self-test source it. The plan did not say where. The install functions use the same form as `install_oasdiff` (the sha256 before the file is opened, the folder `build/tools/<tool>-<version>/` with the file `.sha256`). The variables for the test are `OSV_SCANNER_HOME`, `OSV_SCANNER_URL`, `GITLEAKS_HOME` and `GITLEAKS_URL`. The test uses a stub that the install knows as "already installed" (the file `.sha256` and the version are right), so the scripts have no variable that skips the check of the sha256.
2. **A finding code is exact**: the exit codes that mean "findings" are OSV-Scanner 1, gitleaks 2 (the script sets `--exit-code 2`, because the default 1 is also the code of a fatal error) and zizmor 11 to 14. Each other non-zero code is a failure, also an undocumented one (a new release stops the gate and does not pass in silence). The finding marker "leaks found" for gitleaks, and the failure marker `ERR`/`FTL` for gitleaks, are the answer to two real cases that the agent found by a run: a Go crash has the exit code 2, and a git error of the range has exit code 0.
3. **An SBOM with no package is a failure** (OSV-Scanner exit code 128, "no package sources found"). The same as a folder with no `*.cdx.json` file: a scan of nothing must not pass. The option `--allow-no-lockfiles` would make it pass. The current SBOM files have 12 and 420 packages, so the case does not happen. The owner can change this rule if a project with no dependency comes (the rule is in `tools/security/README.md`). This is a decision of the agent that the owner has not reviewed.
4. **What `secret-scan` scans**: (1) a copy of the files that git knows or that `.gitignore` does not ignore (`gitleaks dir .` in the copy, so the paths are relative to the repository, and `node_modules`, `target` and `build` are out), and (2) the commits `<base>..HEAD` (`base` of the `justfile`). A shallow clone with no merge base stops the script, and the CI job needs `fetch-depth: 0`, as `commit-check` and `breaking-changes`. A partial scan of a shallow clone would pass for a range that it did not see. The report is redacted (`--redact`), `gitleaks:allow` comments and `.gitleaksignore` files do not hide a finding (`--ignore-gitleaks-allow`, an empty `--gitleaks-ignore-path`, no `.gitleaksignore` in the copy, and the history scan runs on the git folder: the agent found that gitleaks reads the `.gitleaksignore` of the source folder of a scan, and the option does not stop it). So the allowlist (covered by CODEOWNERS) is the one place that hides a finding.
5. **The allowlist has no entry**: the default rules find nothing in the files and in all 158 commits of the repository, and the self-test makes its fake secrets while it runs, so no fixture has a value that looks like a secret. The file `tools/security/gitleaks.toml` has `useDefault = true` and the format of an entry with the reason. The self-test shows that an entry hides a finding and that each entry needs a `description`. The folder `/tools/` of CODEOWNERS covers the file already, and the agent added a line for the file too, so the intent is visible.
6. **One self-test for the three recipes**: `test-security-gates` (script `test-security-gates.sh`, task 120.100) and not one test for each recipe. The plan names "the self-test of each recipe", and the one script has a part for each recipe and for the function. The recipes `vuln-scan`, `secret-scan` and `workflow-scan` have the task numbers 120.110, 120.120 and 120.130 in the `justfile`.
7. **zizmor**: `--offline` (as the plan says) and `--strict-collection` (a workflow file that zizmor cannot read is an error, as the plan says "a file that cannot be read" is a failure of the tool; without the option zizmor warns and goes on). The persona is the default (regular). A folder that is not a Git repository root needs the files below `.github/workflows` to be collected, so the recipe starts with `.github/workflows` and the test makes that form.

#### 2026-11-15 11:35:00.000Z - Phase 110: the definition of an approved REQ, the answer about the VCR and the SYSRS entry, and the details of the check

1. **An approved REQ** is a REQ with the status `accepted` or `implemented`. The REQ model has no status `approved`, and DEC f21920d2-4da5-4cf7-bd94-2e9bcba77342 says "an approved REQ". `accepted` is the status that says that a person accepted the requirement, and `implemented` is the status after it. The statuses `draft` and `proposed` are not accepted, and `superseded`, `deprecated` and `rejected` are not valid requirements any more. The owner can change the set in `APPROVED_REQ_STATUSES` of `tools/gates/traceability.py`. This is a decision of the agent that the owner has not reviewed.
2. **The VCR of a REQ** is a VCR whose section `## Verifies` has the reference `REQ <uuid>` of the REQ. This is the only link that the VCR model has. Any VCR status counts (`draft`, `progress`, `complete`, `approved`), because the plan says "has a VCR". The owner can ask for a stronger rule (for example a VCR with the status `approved`) when the first approved REQ exists.
3. **The VCR and the SYSRS entry for REQ 1ca335d7-969a-443e-9392-165fdeea99a0**: the owner decided on 2026-11-15 that the feature adds neither. The REQ keeps the status `draft`, and the positive case of the check is shown by the fixtures only. The steps 4 and 5 of SOP 95b6735b-03b8-47a0-92aa-7934a4ff1519 stay for the feature for the walking skeleton.
4. **Recipe names and CI jobs**: `traceability`, `vuln-scan`, `secret-scan` and `workflow-scan`, as the plan said. No reason to change them was found. The self-test is the recipe `test-traceability-gate`, a prerequisite of `test-gates`.
5. **The model**: the property `specmgr-req` is read from each object of the `model` of the workspace (a software system, a container, a component), and each identifier must be the identifier of a REQ document (the key is named for the REQ, so the identifier of another document type is an error with the same rule). The agent changed `frontend/architecture/compare.mjs` to accept the key `properties`, because the strict reader of feat-7-verification-architecture-tools stopped for it. The change does not compare the values.
6. **The tests**: one regular expression for all languages (`vcr:<uuid>`), read in the `.java` and `.kt` files of `backend/src/test/` and in the TypeScript and JavaScript files of `frontend/src/test/` and `frontend/e2e/`. The text counts if a quote character is before it in the line and the line is not a comment line. The check reads the text of the source and not the report of the test run. A `vcr:` text with no UUID is not read.
7. **The input**: a file or a folder that the check needs and that does not exist (`contracts/openapi.yaml`, `model/workspace.json`, `.specmgr/feat/`, the three test folders) stops the check with exit code 2. A missing input must not make the gate pass.
8. **The documents that count as targets**: the documents directly in `docs/<type>/` and the feature folders of `.specmgr/feat/` that have a `README.md`. A reference with the right identifier and the wrong type has no target. The reader `find_references` is called for the whole body of a document, and the line number in the message is the first line of the document that has the identifier.

#### 2026-11-15 09:44:00.000Z - OSV data: a deviation in the register DEC (option (a))

The owner chose option (a) for the OSV data. The data of OSV.dev has the licenses of its sources and no terms of use of OSV.dev were found, so the data is not a clear case. The owner accepted a deviation with these conditions: a report only, only counts and finding identifiers in the repository, the attribution kept, and no storage or redistribution of the records. The owner's choice is the one-time permission for the dated section in the register DEC 93a6d588-e002-4daf-9a47-45e2d77786e9. Of the other options, the statement that the DEC does not apply to data (b), the offline mode (c; it does not end the license question, because the database has the same source licenses) and no OSV-Scanner (d) were not chosen. The exposure that cannot be excluded (a record with CC-BY-SA 4.0 or CC-BY-NC-ND 4.0) is in the section of the DEC. The owner has not yet reviewed the whole license table (Task 100.160 is open).

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
