---
classification: null
created: '2026-11-03T07:53:51.955+01:00'
id: feat-6-contracts-openapi-pipeline
status: progress
type: feat
updated: '2026-11-04T14:01:18.290+01:00'
version: 1.0.0
---

# Feature: Contract Pipeline with OpenAPI

## Plan

### Overview

This feature makes the pipeline for interfaces. The OpenAPI file is the source of truth for the interfaces between the backend and the frontend. The pipeline has a linter, a check for breaking changes, generators for the server interfaces and for the client schemas, and a gate that compares the generated code with the code in the repository. Two small modules show that the pipeline operates: one Maven module (`backend/`) and one pnpm module (`frontend/`). They have no product code. They have only the files that the generated code needs to compile. GitHub issue #6 is for this feature.

The feature has many phases, and each phase is small. A phase can be a pull request on its own. The phases are in this order: tool selection (090), license checks (100), the Maven Wrapper (105), the OpenAPI file and the linter (110), the check for breaking changes (115), the generators (120), the gates (130), the owner actions for the rulesets (135) and the review (140). The refinement of 2026-11-04 made this order, because the pull request that adds the first `pom.xml` must pass `check-pins` and `license-check` (see the section Decisions Made).

### Requirements

- REQ-001: The OpenAPI file must be the only source for interfaces. A change to an interface must start in this file. A generated file has a mark that tells that no person must change it by hand.

- REQ-002: A linter must examine the OpenAPI file in each pull request.

- REQ-003: A tool must find breaking changes. The base of the comparison is the branch that the pull request goes to, and the gate uses the merge base (DEC 93594b2b-be54-4f60-9f53-ec2ce6c84be4). The gate stops if the ignore file has no entry for a breaking change.

- REQ-004: The build must make the Spring server interfaces and the Zod schemas from the OpenAPI file.

- REQ-005: CI must make the generated code again and must stop the pull request if the result is not the same as the code in the repository. This includes a file that is changed, deleted, added or not tracked by git.

- REQ-006: Errors must use RFC 9457 Problem Details. Each response with a status 4xx or 5xx must use the media type `application/problem+json` and one schema. The schema has a `code` from one list in the OpenAPI file and the trace identifier (DEC e3eadec0-a6ea-4efe-8e6d-fd19287122fa). The schema has no text in a language (DEC 51b00b5f-d1d8-49d8-9f40-28537ff69698). The generators make the list of codes for Java and for TypeScript from the same file, so the codes are the same in all languages. A lint rule stops a response that does not obey this.

- REQ-007: Each tool and each library must have a license check before the project uses it. The result is one of the words of DEC 84c37f7d-08cb-457d-8ab3-1db37dba9bc9: Permitted, Review or Not permitted. If a license is not clear, the work stops and the owner makes a decision.

- REQ-008: Each operation in the OpenAPI file must have the identifier of its specmgr requirement (a REQ UUID) in the extension `x-specmgr-req`. A lint rule stops an operation with no value or with a value that is not a UUID. The check that the UUID is the identifier of a real requirement is for GitHub issue #8.

- REQ-009: Each tool of this feature must have a version in `tools/versions.env` and a lock file or a checksum. CI must get each tool from these pins, and `just check-pins` must check them (DEC 2468257f-cb4e-4f30-a8df-6fc1d86759ce).

- REQ-010: The Maven module must have the Maven Wrapper with the Maven version of `tools/versions.env` and a sha256 value, so that `just check-pins` and `just sbom` accept the first `pom.xml`.

- REQ-011: The generators must make the same files each time. The generated files must have no time stamp and no other value that changes for each run.

- REQ-012: An accepted breaking change must follow DEC 93594b2b-be54-4f60-9f53-ec2ce6c84be4: one entry in an ignore file below `tools/`, and a higher version number of the interface in the same pull request.

- REQ-013: Each new gate must obey the conventions of feat-5-foundation-monorepo-ci: the CI job has the name of its recipe, the job is in `tools/gates/required-setup.txt`, the gate has negative tests in `just test-gates`, and the owner adds the job to the required checks of the rulesets.

- REQ-014: The owner must select each tool from a list of candidates, and the agent must not select a tool alone.

### Acceptance Criteria

- [ ] ACC-001: `contracts/` has an OpenAPI file with the operation `GET /status`, the schema for Problem Details with the `code` list and the trace identifier, and the extension `x-specmgr-req` with the UUID of a real REQ document in `docs/req/` (REQ-001, REQ-006, REQ-008).

- [ ] ACC-002: `just` has recipes for lint, the check for breaking changes, code generation and the check of generated code, and CI starts only these recipes (REQ-002, REQ-003, REQ-004, REQ-005).

- [ ] ACC-003: A change of the OpenAPI file that removes a property of a response causes a failure of the gate for breaking changes. The same change with an entry in the ignore file and a higher version number does not cause a failure. The same change with an entry and the same version number causes a failure. A pull request that adds the OpenAPI file for the first time does not cause a failure (REQ-003, REQ-012).

- [ ] ACC-004: Each of these changes causes a failure of the gate for generated code: a change by hand to a generated file, a change of the OpenAPI file with no new generation, a deleted generated file, and an extra file in the folder of generated code (REQ-001, REQ-005).

- [ ] ACC-005: The Maven module and the pnpm module compile with the generated code in a CI job (REQ-004).

- [ ] ACC-006: Each tool and each library of the license table has the result Permitted, or a DEC of the owner for the result Review. No row has the result "open" (REQ-007).

- [ ] ACC-007: Each of these cases causes a failure of the lint gate: a response 4xx or 5xx that does not use `application/problem+json` with the Problem Details schema, a Problem Details schema with no `code` or no trace identifier, an operation with no `x-specmgr-req`, and an operation with a value that is not a UUID (REQ-002, REQ-006, REQ-008).

- [ ] ACC-008: The `code` list in the generated Java code and in the generated Zod schemas has the same values as the list in the OpenAPI file. A test compares them (REQ-006).

- [ ] ACC-009: The README of `contracts/` says that a change starts in the OpenAPI file. Each generated folder has a mark that tells "generated, do not change", and the gate of ACC-004 stops a change by hand (REQ-001).

- [ ] ACC-010: `backend/mvnw` is executable (git mode 100755), and `backend/.mvn/wrapper/maven-wrapper.properties` has the Maven version of `tools/versions.env` and a `distributionSha256Sum` that was verified with a source other than the properties file. `just check-pins`, `just sbom` and `just license-check` return exit code 0 with the real `backend/pom.xml` (REQ-010).

- [ ] ACC-011: Each tool of this feature has a version in `tools/versions.env` and a lock file or a checksum. `just check-pins` returns exit code 0 now, and returns exit code 1 in `just test-gates` for a changed version and for a changed checksum of each tool (REQ-009).

- [ ] ACC-012: The sha256 of the jar of the generator plugin is in `tools/versions.env`, and a gate compares it with the jar in the local Maven repository. `tools/gates/README.md` says that the dependencies of the Maven plugins are not checked. GitHub issue #23 has a comment with this limit, and it stays open for a full pinning of the Maven plugins (REQ-009).

- [ ] ACC-013: Two runs of `just generate` one after the other make no change in the generated files (REQ-011).

- [ ] ACC-014: DEC 93594b2b-be54-4f60-9f53-ec2ce6c84be4 has an update entry with the format of an entry of the ignore file and the way the gate checks the version number. The ignore file and the rules of the linter are below `tools/`, so CODEOWNERS covers them (REQ-012).

- [ ] ACC-015: Each new CI job is in `tools/gates/required-setup.txt` and has the name of its recipe. `just test-gates` has negative cases for each new gate. These recipes return exit code 0 on the branch: `just test-gates`, `just test-license-gate`, `just check-pins`, `just check-workflows`, `just check-sudo`, `just validate`, `just commit-check`, `just license-check` and `just --fmt --unstable --check`. A throwaway pull request (closed, not merged) with a breaking change fails the new job in real CI (REQ-013).

- [ ] ACC-016: The owner added the new jobs to the required checks of the rulesets of `dev` and `main`, and `branch-protection.md` shows the new rows as set (REQ-013).

- [ ] ACC-017: The phase 090 has a list of candidates for each tool, with the criteria, and the owner selected each tool. The decision is in the section Decisions Made (REQ-014).

### Scope

#### Included

- The OpenAPI file with one example operation (`GET /status`), the error schema with the `code` list, and the first REQ document for this operation.

- The linter with its rules, the tool for breaking changes with its ignore file, the server generator and the Zod generator. The owner selects the tools in the phase 090.

- The pins of these tools (`tools/versions.env`, lock files, checksums) and the changes of the gate scripts that the pins need.

- The Maven Wrapper and the first real run of `just sbom` and `just license-check` with the real manifests.

- The gate for generated code and the gate that compiles the two modules.

- Two modules without product code.

- The changes to the files that the gates share: `tools/gates/required-setup.txt`, `tools/gates/selftest.sh`, `tools/gates/check_pins.py`, `tools/gates/sbom.sh`, the READMEs of `tools/`, `branch-protection.md` and `.github/workflows/ci.yml`.

- A comment in GitHub issues #23 and #8 that tells the state of each issue after this feature.

#### Explicitly Out Of Scope

- The layout, the first version of the `justfile` and the first version of the CI workflow. The feature feat-5-foundation-monorepo-ci made them and it is done. This feature only adds to them (see the list of shared files in Included).

- Test tools, mutation tools and architecture tools (feat-7-verification-architecture-tools).

- The interfaces of the canteen application (the walking skeleton).

- The full pinning of the dependencies of Maven plugins. GitHub issue #23 stays open for it (option 3 of the owner). This feature pins only the jar of each plugin that it adds.

- The check that the identifier in `x-specmgr-req` is the identifier of a real requirement. This is GitHub issue #8 (the traceability check).

- The decision for React or Angular (feat-1-frontend-technology-decision). The pnpm module of this feature has no component of a user interface.

### Dependencies

#### Depends On

- FEAT feat-5-foundation-monorepo-ci (done): it gives the layout, the `justfile`, the CI workflow, the gates and the tools on the machine.

- FEAT feat-16-cdxgen-lockfile (done) and FEAT feat-22-python-tools-lockfile (done): they give the pattern for the pins and the lock files.

#### Blocks

- FEAT feat-7-verification-architecture-tools

### Design Notes

The DEC about interfaces names these possible tools: Spectral (linter), oasdiff (breaking changes), openapi-generator (server interfaces) and a Zod generator for the client. The DEC states that the skeleton must make sure that each tool and its license are correct. This feature does that check. If a tool is not successful in the check, the owner selects a different tool or makes a DEC about the deviation.

The DEC about the architecture gives the rule that the code obeys the model. The OpenAPI operation has the identifier of its requirement in the extension `x-specmgr-req`, and the traceability script (GitHub issue #8) reads it.

Base of the check for breaking changes: DEC 93594b2b-be54-4f60-9f53-ec2ce6c84be4 says that a pull request to `dev` is compared with the merge base of `dev`, and a release pull request to `main` is compared with `main`. The recipe uses the variable `base` of the `justfile`, as the other gates do. The DEC has the policy for an accepted breaking change.

How each new tool is pinned (REQ-009). Each decision is final in the phase of the tool:

- Spectral is an npm package. It needs its own pnpm project with a lock file, installed with `--frozen-lockfile --ignore-scripts`. `sbom.sh` and `check_pins.py` know only two manifest files in `tools/sbom/`, so the phase 110 changes both scripts and their tests.
- oasdiff is a binary without a package manager. The owner chose a download with a sha256 value in `tools/versions.env`, started by a `just` recipe. This adds no new GitHub Action.
- The generator plugin for Maven gets a sha256 value for its jar, as the plugin for the SBOM does. The dependencies of the plugin are not checked (GitHub issue #23).
- The Zod generator and Zod itself are in the lock file of the pnpm module. A root `package.json` must not have a `packageManager` field that is different from `PNPM_VERSION`.

Layout rules from the SBOM gate: the Maven module is `backend/pom.xml` with `backend/mvnw`. A pnpm module below `frontend/` is scanned only if `frontend/pnpm-workspace.yaml` and `frontend/pnpm-lock.yaml` exist. A `package.json` in `contracts/` stops the script.

Candidate path of the OpenAPI file: `contracts/openapi.yaml`. Task 090.120 fixes the path, the version of OpenAPI (3.0 or 3.1, because it changes which tools can read the file), the folders of the generated code (they are in git), and the options of the generators (interfaces only, no time stamp, a fixed list of files).

License table (the agent fills it from the license file of each tool and not from memory). The rows for Spectral, oasdiff, openapi-generator and the Zod generator get the name of the selected tool in the phase 090. Result words: Permitted, Review, Not permitted (DEC 84c37f7d-08cb-457d-8ab3-1db37dba9bc9). A tool gets the check of its main license. A library that goes to users gets the check of all its dependencies through the SBOM gate.

| Item | Use | License | Result |
|---|---|---|---|
| Spectral (candidate) | linter | not checked | open |
| oasdiff (candidate) | breaking changes | not checked | open |
| openapi-generator and its Maven plugin | server interfaces | not checked | open |
| Zod generator (not selected) | client schemas | not checked | open |
| Zod | runtime library | not checked | open |
| TypeScript | compiler for ACC-005 | not checked | open |
| Spring Web, `jakarta.annotation`, swagger annotations, `jackson-databind-nullable` | libraries that the generated Java code needs | not checked | open |
| Jakarta Bean Validation and its implementation | runtime library | not checked | open |
| Maven Wrapper and the Maven plugins of the build | build tools | not checked | open |
| New GitHub Actions (if the owner selects one) | CI | not checked | open |

#### Candidates for the Tools (Task 090.100)

The agent wrote these lists on 2026-11-04. The agent does not select a tool (REQ-014). The owner selects the four tools in the task 090.110. The lines that start with "The agent recommends" are not binding. The license table above stays "open" until the phase 100.

**How the agent got the facts**

- License class: the agent read the license file in the upstream repository. The URL of the file is in the list of each candidate. The class is from the table in DEC 84c37f7d-08cb-457d-8ab3-1db37dba9bc9. MIT and Apache-2.0 are in the class Permitted. The check is for the main license of the tool (rule A). The parts that a tool bundles are not checked here (phase 100).
- Maintenance: the dates of the releases and of the last commit are from the GitHub API and from the npm registry (2026-11-04). The number of open issues is also given.
- Node and Java: the `engines` field of the npm package, or the README. The agent also started the tools with the pinned JDK 21.0.13 and the pinned Node 26.13.0 of `tools/versions.env`. A tool with "not tested" was not started.
- Tests: a small OpenAPI file with `GET /status` and a schema `Problem` with a `code` list (3.0.3 and 3.1.0 versions). The files were in `/tmp`, and nothing is in the repository. The agent used `npm` for the tests, because `pnpm` is not on this machine. The package tree of a pnpm project can be different.
- Same output: the agent started each tool two times with the same input. It compared the output with `diff -r` or `cmp`.
- Pin: the three ways are in "How each new tool is pinned" above. The checksums in the lists are from the release files, and the agent checked them with `sha256sum -c`. They are not yet in `tools/versions.env`.
- OpenAPI versions: 3.0, 3.1 and 3.2 exist. The task 090.120 fixes the version of the file.

**Linter (REQ-002, REQ-006, REQ-008)**

- Spectral CLI, `@stoplight/spectral-cli` 6.17.0
  - License: Apache-2.0 (https://github.com/stoplightio/spectral/blob/develop/LICENSE). Class: Permitted.
  - Maintenance: releases on 2026-10-01, 2026-08-03, 2026-07-20 and 2026-06-30. Before that, the last release was 2025-04-22. The last commit is from 2026-11-04. 223 open issues.
  - OpenAPI: the README says OpenAPI v2, v3.0, v3.1 and v3.2. The tool finds the version in the file.
  - Same output: two runs gave the same JSON (`cmp`). The tool writes no file.
  - Node and Java: `engines` is `^22.0 || >= 24.0`. It ran on Node 26.13.0 and on Node 24.22.2. It needs no Java.
  - Pin: an own pnpm project with a lock file, installed with `--frozen-lockfile --ignore-scripts` (as cdxgen). The package has no install script.
  - Rules: the rules are YAML. The agent wrote the rule for `x-specmgr-req` (function `pattern` with a UUID expression) and the rule for 4xx and 5xx (function `truthy` on `application/problem+json`). With a 3.1.0 file, the good file had no error, and the bad file had two errors.
  - Other: the agent found no telemetry code in the installed packages. The tree has 240 packages with `Unlicense` (3 packages) and one old license field. It would be in `tools/`, so rule A applies.
- Redocly CLI, `@redocly/cli` 2.73.0
  - License: MIT (https://github.com/Redocly/redocly-cli/blob/main/LICENSE.md). The file has the MIT text and no name of the license. Class: Permitted (the agent compared the text with MIT, so phase 100 must read it again).
  - Maintenance: many releases each day (the last on 2026-11-03). The last commit is from 2026-11-04. 173 open issues.
  - OpenAPI: the README says OpenAPI 3.x and 2.0. The command `generate-client` says 3.0, 3.1 and 3.2.
  - Same output: two runs gave the same JSON.
  - Node and Java: `engines` is `>=22.12.0 || >=20.19.0 <21.0.0`. It ran on Node 26.13.0. It needs no Java.
  - Pin: an own pnpm project with a lock file (as Spectral). The npm package has no dependency, because it bundles its code.
  - Rules: the rules are in `redocly.yaml` (configurable rules). The agent wrote both rules. The rule for 4xx and 5xx needs the keys `where`, `MediaTypesMap` and `required`. Result with a 3.1.0 file: the good file had no error, and the bad file had one error for each rule.
  - Other: the tool sends telemetry by default. `REDOCLY_TELEMETRY=off` or `telemetry: off` in `redocly.yaml` stops it (https://github.com/Redocly/redocly-cli/blob/main/docs/@v2/usage-data.md). `THIRD_PARTY_NOTICES` of the package lists 122 bundled packages. One has the license "unknown" (`format@0.2.2`) and one has "(MIT AND BSD)" (`dictionary-en@4.0.0`). Rule A does not check them.
- vacuum 0.36.2
  - License: MIT (https://github.com/daveshanley/vacuum/blob/main/LICENSE). Class: Permitted.
  - Maintenance: releases almost each day (the last on 2026-11-01). The last commit is from 2026-11-01. 14 open issues. The version is 0.x.
  - OpenAPI: the README does not list the versions. It names OpenAPI 3.2 tags. The parser is `libopenapi` 0.42.3, and its README says "OpenAPI 3, 3.1 and 3.2". This is not clear in the README of vacuum.
  - Same output: two runs gave the same text (without the lines with the time of the run).
  - Node and Java: a Go binary. It needs no Node and no Java. The npm package `@quobix/vacuum` has a `postinstall` script and `engines` `>=24.16.0`, so the agent does not suggest it (the install uses `--ignore-scripts`).
  - Pin: the sha256 of the `vacuum_0.36.2_linux_x86_64.tar.gz` is `5736f27a806888f7ed89fba6bb8a3a00e5da895f1ad870f699b3018b7c8bcb0d`. The release has `checksums.txt` and a sigstore file.
  - Rules: the tool reads a Spectral ruleset. The same two rules of Spectral gave exit code 0 for the good file and exit code 1 for the bad file. The README says that the compatibility with Spectral has limits.
- The agent recommends Spectral (not binding). The rules for REQ-006 and REQ-008 are YAML and they work with 3.1. The pin is the same as for cdxgen. The agent found no telemetry. Redocly is a good second choice, but it has telemetry and many bundled packages. vacuum is a good choice if the owner wants a binary with a sha256 value, but the version is 0.x.

**Tool for breaking changes (REQ-003, REQ-012)**

- oasdiff 1.35.0
  - License: Apache-2.0 (https://github.com/oasdiff/oasdiff/blob/main/LICENSE). Class: Permitted.
  - Maintenance: releases on 2026-10-28, 2026-10-21, 2026-10-18 and 2026-10-01. The last commit is from 2026-11-03. 79 open issues.
  - OpenAPI: 3.0 and 3.1 (3.1 is generally available since 1.15.0). It reads 3.2 files (https://github.com/oasdiff/oasdiff/blob/main/docs/OPENAPI-31.md).
  - Same output: two runs gave the same text (`cmp`). The text has no time.
  - Node and Java: a Go binary. It needs no Node and no Java.
  - Pin: a download with a sha256 value. `oasdiff_1.35.0_linux_amd64.tar.gz` has the sha256 `a8023002fcb2eaa7f5758148a9303cb63d33b939886df312268bc0fc7b939140`. It is the same in `checksums.txt` of the release and in the digest of GitHub.
  - Test: for a removed required property of a response, `oasdiff breaking old new --fail-on ERR` gave exit code 1. With `--err-ignore <file>` and a line "GET /status removed the required property `note` from the response with the `200` status", it gave exit code 0. For two equal files, it gave exit code 0.
  - Other: the ignore file is a text file with a line for each change. This fits REQ-012. The tool does not know the version number of the interface, so the check of the version number is an own script. `oasdiff breaking origin/main:contracts/openapi.yaml contracts/openapi.yaml` reads a file from a git revision. If the base file does not exist, the tool stops with exit code 102, so the recipe must test for the file first (ACC-003).
- openapi-changes 0.4.1 (pb33f)
  - License: Apache-2.0 (https://github.com/pb33f/openapi-changes/blob/main/LICENSE). Class: Permitted.
  - Maintenance: releases on 2026-11-01 (two), 2026-10-11, 2026-10-10 and 2026-08-26. The last commit is from 2026-11-01. 9 open issues. The version is 0.x.
  - OpenAPI: the README says "OpenAPI or AsyncAPI 3.x" and does not list the OpenAPI versions. The parser is `libopenapi` 0.42.3 (3, 3.1 and 3.2). It found the removed property in a 3.1.0 file.
  - Same output: two runs gave the same text (with `--no-logo --no-color`).
  - Node and Java: a Go binary. It needs no Node and no Java.
  - Pin: `openapi-changes_0.4.1_linux_x86_64.tar.gz` has the sha256 `c8a516f284c0a828f4281966a6190158b0ce1c6a831526e2ce1f3f4c13c9af0c`.
  - Test: `summary` gave exit code 1 for the removed property and exit code 0 for equal files.
  - Other: the agent found no ignore file for one single change. The file `changes-rules.yaml` switches off a whole kind of change. So REQ-012 needs more own work with this tool.
- openapi-diff 2.1.7 (OpenAPITools)
  - License: Apache-2.0 (https://github.com/OpenAPITools/openapi-diff/blob/master/LICENSE). Class: Permitted.
  - Maintenance: the last release is 2026-01-26 (before that 2025-11-26). The last commit is from 2026-08-05. 89 open issues.
  - OpenAPI: the README says "OpenAPI spec v3.0". The tool does not read 3.1 files according to the README.
  - Same output: not tested.
  - Node and Java: a Java program (Java 8 or higher, README). It is on Maven Central and Docker Hub. Not tested with JDK 21.
  - Pin: the jar from Maven Central. Maven Central has `.sha1`, `.md5` and `.asc` files and no `.sha256` file, so the sha256 is computed on the machine of the author (as for the plugin of the SBOM).
  - Other: the agent found no ignore file in the README. The options are `--fail-on-incompatible` and `--fail-on-changed`.
- The agent recommends oasdiff (not binding). It is the only candidate with an ignore file for each change, it reads 3.0 and 3.1, and it is a Go binary with a sha256 value (the way that the owner chose on 2026-11-04).

**Server generator for Spring interfaces (REQ-004, REQ-011)**

The agent found only two candidates for Java with Spring interfaces. The agent did not look at other tools.

- openapi-generator, `openapi-generator-maven-plugin` 7.27.0, generator `spring`
  - License: Apache-2.0 (https://github.com/OpenAPITools/openapi-generator/blob/master/LICENSE). Class: Permitted.
  - Maintenance: releases on 2026-11-02, 2026-10-06, 2026-08-24, 2026-07-20 and 2026-06-08. The last commit is from 2026-11-04. 5810 open issues (a large project).
  - OpenAPI: the README says "1.0, 1.1, 1.2, 2.0, 3.0, 3.1 (beta support)". With a 3.1.0 file the tool writes the warning "OpenAPI 3.1 support is still in beta". The page of the generator `spring` lists the type `Null` as not supported. 3.2 is not in the list. The generator `spring` has the stability STABLE.
  - Options for the task 090.120: `interfaceOnly=true`, `skipDefaultInterface`, `hideGenerationTimestamp=true`, `useSpringBoot3` (true by default), `generateSupportingFiles` (a plugin option), `openApiNullable`.
  - Same output: with `hideGenerationTimestamp=true`, two runs gave the same files (`diff -r`), with JDK 21.0.13 and with JDK 11. Without the option, the `@Generated` annotation has a time (`date = ...`), and two runs are different.
  - Node and Java: the README says Java 11 as the minimum. It needs no Node.
  - Pin: the sha256 of the jar of the plugin 7.27.0 is `9af831e2593931d9fe91a0804cd550f6f040bc690ab96aaf503b20c7558fa1c6`. The sha1 of the file is the same as the `.sha1` on Maven Central. Maven Central has no `.sha256` file. The dependencies of the plugin are not checked (GitHub issue #23).
  - Other: the generated Java code needs libraries (see the license table), and the options of the generator decide which ones.
- swagger-codegen v3, `swagger-codegen-maven-plugin` 3.0.84 (`io.swagger.codegen.v3`)
  - License: Apache-2.0 (https://github.com/swagger-api/swagger-codegen/blob/master/LICENSE). Class: Permitted.
  - Maintenance: releases on 2026-11-02, 2026-10-26, 2026-08-04 and 2026-05-18. The last commit is from 2026-11-02. 3438 open issues. The README of the default branch is for version 2, and the table in it is old (it says 3.0.71 is the stable release).
  - OpenAPI: 3.0 only ("OpenAPI 3.0.X is supported from the 3.X version only").
  - Options: the agent read the source of the generator. The Spring generator has `interfaceOnly`, `jakarta` and the library `spring-boot3`. The template of `@Generated` has `hideGenerationTimestamp`, and its default in `AbstractJavaCodegen` is false, so the option must be set. The agent did not start this tool.
  - Same output: not tested.
  - Node and Java: the Java version is not clear. The agent did not read it.
  - Pin: the sha256 of the jar 3.0.84 is `2395a654ff68d828d8e1ebc241733013d30613217c5c18d5776bbce3fd7d4e08` (the sha1 is the same as on Maven Central).
- The agent recommends openapi-generator (not binding). It is the only candidate that the agent started, and the output was the same in each run with `hideGenerationTimestamp`. If the file has OpenAPI 3.1, the support is beta, so the owner must accept this risk. With OpenAPI 3.0, both candidates read the file.

**Zod generator (REQ-004, REQ-006, REQ-011)**

The candidate `openapi-zod-client` is not in the list. The README says that it is deprecated (commit of 2026-08-05), the last release is from 2025-02-10, and the repository has no license file.

- Kubb, `kubb` 5.15.3 with `@kubb/plugin-zod` 5.8.0
  - License: MIT (https://github.com/kubb-labs/kubb/blob/main/LICENSE). Class: Permitted.
  - Maintenance: many releases (the last on 2026-10-29). The last commit is from 2026-11-03. 7 open issues. The line 5.x is young (the last 100 releases are from the last three months).
  - OpenAPI: the adapter says Swagger 2.0, OpenAPI 3.0 and 3.1. 3.2 is not named. The agent tested 3.0.3 and 3.1.0.
  - Zod: the plugin has the peer dependency `zod ^4.0.0`. Zod 3 is not possible.
  - Same output: two runs gave the same files for 3.0.3 and for 3.1.0, also on Node 26.13.0. The agent got one file for each schema (`problemSchema.ts`, `statusSchema.ts`) and one for the operation. The header is "Generated by Kubb (https://kubb.dev/). Do not edit manually." It has no time. The `code` list is `z.enum(['A', 'B'])`.
  - Node and Java: `engines` is `>=22.22`. It ran on Node 26.13.0. It needs no Java.
  - Pin: the pnpm lock file (in `frontend/` or in an own project). The packages have no install script.
  - Other: the tool sends anonymous data to `https://otlp.kubb.dev`, unless `DO_NOT_TRACK=1` or `KUBB_DISABLE_TELEMETRY=1` is set (the agent read this in `@kubb/cli/dist/Telemetry-*.js`). The workflow gate does not allow `env:`, so the recipe must set the variable. The tool also writes messages about sponsors to the output.
- Hey API, `@hey-api/openapi-ts` 0.99.0 with the plugin `zod`
  - License: MIT (https://github.com/hey-api/hey-api/blob/main/LICENSE). Class: Permitted.
  - Maintenance: the last stable release is 0.99.0 from 2026-06-22. Newer builds are only `0.0.0-next-*` snapshots (the last from 2026-09-30). The last commit on `main` is from 2026-09-30. 660 open issues. The version is 0.x.
  - OpenAPI: the README says "accepts any OpenAPI specification". The agent tested 3.0.3 and 3.1.0.
  - Zod: the plugin makes Zod v3, v4 and mini.
  - Same output: two runs gave the same file for 3.0.3 and 3.1.0, also on Node 26.13.0. The result is one file `zod.gen.ts` with `zStatus`, `zProblem` and the responses. The header is "This file is auto-generated by @hey-api/openapi-ts" (no time, no version).
  - Node and Java: `engines` is `>=22.18.0`. The peer dependency is `typescript >=5.5.3`. It needs no Java.
  - Pin: the pnpm lock file. The package has no install script. The tree has 53 packages.
- Orval, `orval` 8.46.0 with the client `zod`
  - License: MIT (https://github.com/orval-labs/orval/blob/master/LICENSE). Class: Permitted.
  - Maintenance: releases on 2026-10-30, 2026-10-25, 2026-10-21 and 2026-10-14. The last commit is from 2026-11-04. 29 open issues.
  - OpenAPI: the documentation says "any valid OpenAPI v3 or Swagger v2". The agent tested 3.0.3 and 3.1.0. 3.2 is not named.
  - Zod: Zod 3 and Zod 4 (`override.zod.version`), also the variant `mini`.
  - Same output: two runs gave the same file for 3.0.3 and 3.1.0, also on Node 26.13.0. The header has "Generated by orval", the title and the version of the OpenAPI file. It has no time. `override.header` can change it.
  - Test: with `client: 'zod'`, the agent got only the schemas of the operation (`GetStatusResponse`), and not the schema `Problem` of the 500 response. With `schemas: { type: 'zod' }` it got one file for each component, but the tool also made an `api.ts` client. The task 090.120 must test if the client can be switched off.
  - Node and Java: `engines` is `>=22.18.0`. It needs no Java.
  - Pin: the pnpm lock file. The tree has 84 packages.
- The agent recommends Kubb (not binding), if the owner accepts the telemetry with an opt-out in the recipe. If the owner does not accept it, Hey API is the second choice (the tree is small and no telemetry code was found, but there is no stable release since 2026-06-22). The agent suggests Orval last, because the `code` list of the 500 response is only in the output when the `schemas` option is set, and it makes a client too.

**Open questions for the owner**

- OpenAPI version (task 090.120): with 3.0, each candidate in all lists reads the file. With 3.1, `swagger-codegen` and `openapi-diff` can not read it, and `openapi-generator` has beta support only.
- Telemetry: Kubb and Redocly CLI send data by default. Is an opt-out in the recipe acceptable?
- Place of the Zod generator: in `frontend/` its packages go into the SBOM and the license gate. In the npm trees that the agent made, `argparse` (Python-2.0) is in the trees of Hey API and Orval. `Python-2.0` is not in the table of DEC 84c37f7d-08cb-457d-8ab3-1db37dba9bc9, and `Unlicense` (Spectral tree) is not there either. The tree of Kubb has only classes that are Permitted. An own project in `tools/` (as for cdxgen) makes rule A apply. The agent did not test if cdxgen includes the dev dependencies.
- Server generator: the list has only two candidates. Is this enough?

**Overview**

| Tool | Candidate | License | OpenAPI versions | Pin |
|---|---|---|---|---|
| Linter | Spectral CLI 6.17.0 | Apache-2.0 | 3.0, 3.1, 3.2 | pnpm lock file |
| Linter | Redocly CLI 2.73.0 | MIT | 3.0, 3.1 (3.2 for one command) | pnpm lock file |
| Linter | vacuum 0.36.2 | MIT | not clear in the README (parser: 3, 3.1, 3.2) | sha256 of the binary |
| Breaking changes | oasdiff 1.35.0 | Apache-2.0 | 3.0, 3.1 (reads 3.2) | sha256 of the binary |
| Breaking changes | openapi-changes 0.4.1 | Apache-2.0 | not clear in the README (parser: 3, 3.1, 3.2) | sha256 of the binary |
| Breaking changes | openapi-diff 2.1.7 | Apache-2.0 | 3.0 | sha256 of the jar |
| Server generator | openapi-generator 7.27.0 | Apache-2.0 | 3.0, 3.1 (beta) | sha256 of the plugin jar |
| Server generator | swagger-codegen 3.0.84 | Apache-2.0 | 3.0 | sha256 of the plugin jar |
| Zod generator | Kubb 5.15.3 | MIT | 3.0, 3.1 | pnpm lock file |
| Zod generator | Hey API 0.99.0 | MIT | 3.0, 3.1 | pnpm lock file |
| Zod generator | Orval 8.46.0 | MIT | 3.0, 3.1 | pnpm lock file |

### Related Decisions

- DEC f92e35a1-77a2-4749-917f-bf9b644e8ddd: Write Interfaces First in OpenAPI and Use Layers for Validation

- DEC f21920d2-4da5-4cf7-bd94-2e9bcba77342: Use Specmgr Identifiers for Traceability

- DEC 84c37f7d-08cb-457d-8ab3-1db37dba9bc9: Use Only Open Source Libraries That Are Compatible With AGPL-3.0-only

- DEC 361678a6-f941-473b-a058-1ba2bacf7d3d: Use a Test Pyramid and Blocking Gates for Verification

- DEC 870244cf-9bea-46bf-8ff2-fe030325743d: Use a Monorepo with Maven, pnpm, just and GitHub Actions

- DEC 93594b2b-be54-4f60-9f53-ec2ce6c84be4: Accept a Breaking Change of the Interface Only With a New Version and an Entry in a File That the Owner Examines (status draft, written for this feature)

- DEC d778d444-6227-4070-ae6e-b1083c78c58b: Keep dev and main Free of Local Commits and Update Them With Fast-Forward Only

- DEC a56f231b-d063-4bef-bbc8-3deb4daff76e: Use Conventional Commits, Feature Branches and a Definition of Done

- DEC cc4449cd-78fb-452a-904f-7efda89cf004: Set Limits for Coding Agents

- DEC 2468257f-cb4e-4f30-a8df-6fc1d86759ce: Keep One Source of Truth for Each Type of Fact

- DEC 51b00b5f-d1d8-49d8-9f40-28537ff69698: Use Internationalization in the Application From the Start

- DEC e3eadec0-a6ea-4efe-8e6d-fd19287122fa: Use OpenTelemetry for Observability

- DEC eb6e66ca-4ceb-46b5-9865-47e20a44674a: Write Documents in ASD-STE100 English

- RSK f682b3fb-ef1d-48f3-9fef-1e9e5ff147f7: A Code Generator Can Cause Delay

- RSK 3be3ffd7-62e9-4926-9996-a0806d093228: A Necessary Tool Can Break the Open Source License Rule

- SOP 95b6735b-03b8-47a0-92aa-7934a4ff1519: Add a Requirement With Traceability

### Task List

#### Phase 090: Tool Selection

- [x] Task 090.100: For each tool (linter, tool for breaking changes, server generator, Zod generator), write a list of two or three candidates with these criteria: the license class in DEC 84c37f7d-08cb-457d-8ab3-1db37dba9bc9, maintenance, support for the version of OpenAPI, the same output for each run, support for the Node and Java versions in `tools/versions.env`, and the way to pin it. Write the lists in the Design Notes (ACC-017)

- [ ] Task 090.110: The owner selects the four tools. Write the choice and the cause in the section Decisions Made. If the owner does not select a tool, stop (ACC-017)

- [ ] Task 090.120: Fix the path and the version of the OpenAPI file, the folders of the generated code, and the options of the generators. Write them in the Design Notes and in the section Decisions Made (ACC-013)

#### Phase 100: License Checks

- [ ] Task 100.100: Read the license file of each selected tool in the license table, and write the result. Stop and tell the owner if a license is not clear (ACC-006)

- [ ] Task 100.110: Read the license of each library that the generated code needs, of the Maven Wrapper and of the Maven plugins, and write the results. Add a new class of license to DEC 84c37f7d-08cb-457d-8ab3-1db37dba9bc9 only with the permission of the owner (ACC-006)

- [ ] Task 100.120: If a tool or library has the result Review, tell the owner and wait for a decision. Do not use the item before the decision (ACC-006)

#### Phase 105: Maven Wrapper and the Shell of the Backend Module

- [ ] Task 105.100: Make `backend/pom.xml` with no dependencies. Add the Maven Wrapper without a jar (`backend/mvnw` and `backend/.mvn/wrapper/maven-wrapper.properties`) for the Maven version of `tools/versions.env`. Verify the `distributionSha256Sum` with the `.sha512` of Apache and `tools/gates/README.md`, and not only with the value in the properties file (ACC-010)

- [ ] Task 105.110: Set the git mode of `backend/mvnw` to 100755. Run `just check-pins`, `just sbom` and `just license-check` with the real `pom.xml`, and write the result in this plan. Change the section "Limits" of `tools/gates/README.md` for the first real run (ACC-010)

#### Phase 110: OpenAPI Source and Lint

- [ ] Task 110.100: Write the OpenAPI file with the operation `GET /status`, the Problem Details schema (the `code` list, the trace identifier, no text of a language), the response 4xx and 5xx with `application/problem+json`, and the extension `x-specmgr-req` (ACC-001, ACC-009)

- [ ] Task 110.105: Make the first REQ document with specmgr for the operation `GET /status` (this makes the folder `docs/req/`). The document has the status draft. Put its UUID in the extension. Write a README in `contracts/` (ACC-001, ACC-009)

- [ ] Task 110.110: Add the selected linter: pin it (`tools/versions.env`, own pnpm project with a lock file under `tools/`), change `sbom.sh`, `check_pins.py` and their tests for the new manifest, and add it to the license table (ACC-011)

- [ ] Task 110.115: Write the rules of the linter (REQ-006 and REQ-008) in a path below `tools/`, add the `just` recipe `lint`, and add the negative cases of ACC-007 (ACC-002, ACC-007)

#### Phase 115: Check for Breaking Changes

- [ ] Task 115.100: Add the selected tool for breaking changes as a download with a sha256 value in `tools/versions.env`. Add the install in the recipe. Change `check_pins.py` and its tests for the new pin (ACC-011)

- [ ] Task 115.110: Write the recipe for the check. It uses `{{ base }}` and the merge base of `git merge-base`. It goes on if the base has no OpenAPI file (ACC-002, ACC-003)

- [ ] Task 115.120: Make the ignore file below `tools/` and the check of the version number (REQ-012). Add an update entry to DEC 93594b2b-be54-4f60-9f53-ec2ce6c84be4 with the format of an entry and the check. The status of the DEC is not changed by the agent (ACC-003, ACC-014)

- [ ] Task 115.130: Add the four cases of ACC-003 to `just test-gates` (ACC-003)

#### Phase 120: Generators

- [ ] Task 120.100: Add the generation of the Spring server interfaces to the Maven module, with the dependencies that the generated code needs and the options of the task 090.120 (ACC-005, ACC-013)

- [ ] Task 120.105: Add the sha256 of the jar of the generator plugin to `tools/versions.env`, and the comparison to a gate, as `sbom.sh` does for its plugin. Write the limit about the dependencies of the plugin in `tools/gates/README.md` and in a comment in GitHub issue #23 (ACC-012)

- [ ] Task 120.110: Make the pnpm module in `frontend/` (`pnpm-workspace.yaml`, lock file) and the generation of the Zod schemas. Install with `--frozen-lockfile --ignore-scripts` (ACC-005, ACC-011)

- [ ] Task 120.120: Write the `just` recipe `generate` that makes all generated code again, and the test for ACC-008 and ACC-013 (ACC-002, ACC-008, ACC-013)

#### Phase 130: Gates

- [ ] Task 130.100: Write the gate that compares the generated code with the code in the repository. It also finds deleted, extra and untracked files (`git status --porcelain` and not only `git diff`) (ACC-004)

- [ ] Task 130.105: Add the CI job that compiles the Maven module and the pnpm module with the generated code (ACC-005)

- [ ] Task 130.110: Add the lint gate, the gate for breaking changes, the gate for generated code and the compile job to the CI workflow and to `tools/gates/required-setup.txt`. The name of each job is the name of its recipe (ACC-015)

- [ ] Task 130.120: Test each gate with a change that must cause a failure. Add the cases to `just test-gates`, write the results in this plan, and keep one throwaway pull request in real CI as proof (ACC-004, ACC-007, ACC-015)

- [ ] Task 130.130: Change `tools/README.md`, `tools/gates/README.md`, the comments of `tools/versions.env` and the table in `branch-protection.md`. Run all recipes of ACC-015 (ACC-015)

#### Phase 135: Rulesets (Owner Actions)

- [ ] Task 135.100: The owner adds the new jobs to the required checks of the rulesets of `dev` and `main` after the first run of the jobs. The agent cannot do this (ACC-016)

- [ ] Task 135.110: Update `branch-protection.md` for the new rows (ACC-016)

#### Phase 140: Review

- [ ] Task 140.100: The owner examines the license table and the open items (ACC-006)

- [ ] Task 140.110: The owner accepts or changes DEC 93594b2b-be54-4f60-9f53-ec2ce6c84be4 (ACC-014)

- [ ] Task 140.120: Write a comment in GitHub issue #23 (the limit that stays) and in GitHub issue #8 (the extension `x-specmgr-req` and the lint rule that exist). Set this feature to done in the last pull request, as the SOP "Close a Feature With One Pull Request" says (ACC-012)

## Progress

### Current Status

**As of 2026-11-04**: The refinement is done and the status is `progress`. feat-5-foundation-monorepo-ci is done, so the dependency is satisfied. The task 090.100 is done: the Design Notes have the lists of candidates for the four tools. The agent waits for the owner to select the tools in the task 090.110. The tasks 090.110 and 090.120 are not started.

### Blockers

- None. The owner must select the tools in the task 090.110, and the work on the tools stops until the owner does so.

### Updates

<!-- Newest entry first -- prepend new entries directly below this comment. -->

#### 2026-11-04 13:00:00.000Z - Task 090.100 done: lists of candidates

The agent wrote the lists of candidates in the Design Notes (section "Candidates for the Tools (Task 090.100)"). Each tool has two or three candidates: the linter (Spectral, Redocly CLI, vacuum), the tool for breaking changes (oasdiff, openapi-changes, openapi-diff), the server generator (openapi-generator, swagger-codegen v3) and the Zod generator (Kubb, Hey API, Orval). The agent read the license file of each candidate in the upstream repository, got the dates of the releases from the GitHub API and the npm registry, and started the tools with the pinned JDK 21.0.13 and Node 26.13.0 for the tests of the same output. The agent did not select a tool (REQ-014). The lists have the agent's recommendation for each tool, and it is not binding. The lists also have these facts for the owner: only the generator openapi-generator reads OpenAPI 3.1 (in beta), `swagger-codegen` and `openapi-diff` read only 3.0, Kubb and Redocly CLI send telemetry by default, and the Zod generators in a `frontend/` project can add packages with a license that is not in the table of DEC 84c37f7d-08cb-457d-8ab3-1db37dba9bc9 (`Python-2.0`). The tasks 090.110 and 090.120 wait for the owner. No file of the repository other than this plan was changed.

#### 2026-11-04 11:20:00.000Z - Plan refined

A refinement of the plan found these errors and gaps: the status was old (feat-5 is done), the plan had no step to select the tools, the Maven Wrapper was missing (the SBOM gate and `check_pins.py` stop a `pom.xml` with no `mvnw`), the base of the check for breaking changes was `main` and not the branch of the pull request, REQ-006 and REQ-008 had no test, the pins of the new tools were not described, the gate files were not in the plan, and the first real run of the SBOM gate was not in the plan. The owner decided on 2026-11-04 to keep one feature and to use more small phases. The plan now has the phases 090, 105, 115 and 135 in the gaps of the numbers, and the REQ-009 to REQ-014 and ACC-007 to ACC-017. Task 110.120 moved to the phase 115 (tasks 115.100 to 115.130), and no work was done for it. The agent wrote the new DEC 93594b2b-be54-4f60-9f53-ec2ce6c84be4 (status draft) for the policy about breaking changes. The status of the feature is now `progress`.

#### 2026-11-03 00:00:00.000Z - Plan written

The plan is written from the planning session of 2026-11-03.

### Decisions Made

<!-- Newest entry first -- prepend new entries directly below this comment. -->

#### 2026-11-04 11:20:00.000Z - Plan decisions of the refinement

The owner decided these points on 2026-11-04. First, one feature with small phases, and not two features. Second, REQ-006 and REQ-008 get lint rules and acceptance criteria in this feature. Third, the first REQ document is made by specmgr, and the folder `docs/req/` is made with it. Fourth, the example operation is `GET /status`. Fifth, the agent writes the lists of candidates and the owner selects the tools. Sixth, oasdiff (or the selected tool) is a download with a sha256 value in `tools/versions.env`. Seventh, the policy for an accepted breaking change is DEC 93594b2b-be54-4f60-9f53-ec2ce6c84be4 and one ignore file below `tools/`, and not one DEC for each change. Eighth, for GitHub issue #23 this feature pins only the jar of its own plugin (option 2). The full pinning of the dependencies of Maven plugins stays open in issue #23 (option 3). The sentence "against the main branch" in DEC f92e35a1-77a2-4749-917f-bf9b644e8ddd said the wrong base. With a permission of the owner for one time (2026-11-04), the agent changed it to "against the base of the pull request" and added an update entry to that DEC.

#### 2026-11-03 00:00:00.000Z - Own feature for the contracts

The contract pipeline is a different feature (issue #6), because it depends on the foundation and has a pull request for it.

### Related PRs / Commits

- [Issue #6](https://github.com/dfch/biz.dfch.SpecMgrDemo/issues/6): this feature.

- [Issue #23](https://github.com/dfch/biz.dfch.SpecMgrDemo/issues/23): the dependencies of the Maven plugins. It stays open (option 3).

- [Issue #8](https://github.com/dfch/biz.dfch.SpecMgrDemo/issues/8): the traceability check and the security checks.

### More Information

The first design issue is GitHub issue #1.
