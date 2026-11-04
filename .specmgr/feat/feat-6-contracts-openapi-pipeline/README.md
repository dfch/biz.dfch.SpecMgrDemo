---
classification: null
created: '2026-11-03T07:53:51.955+01:00'
id: feat-6-contracts-openapi-pipeline
status: progress
type: feat
updated: '2026-11-04T12:20:00.000+01:00'
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

- [ ] Task 090.100: For each tool (linter, tool for breaking changes, server generator, Zod generator), write a list of two or three candidates with these criteria: the license class in DEC 84c37f7d-08cb-457d-8ab3-1db37dba9bc9, maintenance, support for the version of OpenAPI, the same output for each run, support for the Node and Java versions in `tools/versions.env`, and the way to pin it. Write the lists in the Design Notes (ACC-017)

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

**As of 2026-11-04**: The refinement is done and the status is `progress`. feat-5-foundation-monorepo-ci is done, so the dependency is satisfied. No task of the Task List is done. The next step is the phase 090 (the selection of the tools by the owner).

### Blockers

- None. The owner must select the tools in the task 090.110, and the work on the tools stops until the owner does so.

### Updates

<!-- Newest entry first -- prepend new entries directly below this comment. -->

#### 2026-11-04 11:20:00.000Z - Plan refined

A refinement of the plan found these errors and gaps: the status was old (feat-5 is done), the plan had no step to select the tools, the Maven Wrapper was missing (the SBOM gate and `check_pins.py` stop a `pom.xml` with no `mvnw`), the base of the check for breaking changes was `main` and not the branch of the pull request, REQ-006 and REQ-008 had no test, the pins of the new tools were not described, the gate files were not in the plan, and the first real run of the SBOM gate was not in the plan. The owner decided on 2026-11-04 to keep one feature and to use more small phases. The plan now has the phases 090, 105, 115 and 135 in the gaps of the numbers, and the REQ-009 to REQ-014 and ACC-007 to ACC-017. Task 110.120 moved to the phase 115 (tasks 115.100 to 115.130), and no work was done for it. The agent wrote the new DEC 93594b2b-be54-4f60-9f53-ec2ce6c84be4 (status draft) for the policy about breaking changes. The status of the feature is now `progress`.

#### 2026-11-03 00:00:00.000Z - Plan written

The plan is written from the planning session of 2026-11-03.

### Decisions Made

<!-- Newest entry first -- prepend new entries directly below this comment. -->

#### 2026-11-04 11:20:00.000Z - Plan decisions of the refinement

The owner decided these points on 2026-11-04. First, one feature with small phases, and not two features. Second, REQ-006 and REQ-008 get lint rules and acceptance criteria in this feature. Third, the first REQ document is made by specmgr, and the folder `docs/req/` is made with it. Fourth, the example operation is `GET /status`. Fifth, the agent writes the lists of candidates and the owner selects the tools. Sixth, oasdiff (or the selected tool) is a download with a sha256 value in `tools/versions.env`. Seventh, the policy for an accepted breaking change is DEC 93594b2b-be54-4f60-9f53-ec2ce6c84be4 and one ignore file below `tools/`, and not one DEC for each change. Eighth, for GitHub issue #23 this feature pins only the jar of its own plugin (option 2). The full pinning of the dependencies of Maven plugins stays open in issue #23 (option 3). The agent reads "the check against the main branch" in DEC f92e35a1-77a2-4749-917f-bf9b644e8ddd as "against the base of the pull request". DEC f92e35a1-77a2-4749-917f-bf9b644e8ddd is not changed. An update entry for it needs the permission of the owner.

#### 2026-11-03 00:00:00.000Z - Own feature for the contracts

The contract pipeline is a different feature (issue #6), because it depends on the foundation and has a pull request for it.

### Related PRs / Commits

- [Issue #6](https://github.com/dfch/biz.dfch.SpecMgrDemo/issues/6): this feature.

- [Issue #23](https://github.com/dfch/biz.dfch.SpecMgrDemo/issues/23): the dependencies of the Maven plugins. It stays open (option 3).

- [Issue #8](https://github.com/dfch/biz.dfch.SpecMgrDemo/issues/8): the traceability check and the security checks.

### More Information

The first design issue is GitHub issue #1.
