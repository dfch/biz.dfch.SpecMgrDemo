---
classification: null
created: '2026-11-03T07:53:51.955+01:00'
id: feat-6-contracts-openapi-pipeline
status: review
type: feat
updated: '2026-11-06T22:02:58.523+01:00'
version: 1.0.0
---

# Feature: Contract Pipeline with OpenAPI

## Plan

### Overview

This feature makes the pipeline for interfaces. The OpenAPI file is the source of truth for the interfaces between the backend and the frontend. The pipeline has a linter, a check for breaking changes, generators for the server interfaces and for the client schemas, a job that makes the API documentation, and a gate that compares the generated code with the code in the repository. Two small modules show that the pipeline operates: one Maven module (`backend/`) and one pnpm module (`frontend/`). They have no product code. They have only the files that the generated code needs to compile. GitHub issue #6 is for this feature.

The feature has many phases, and each phase is small. A phase can be a pull request on its own. The phases are in this order: tool selection (090), license checks (100), the Maven Wrapper (105), the OpenAPI file and the linter (110), the check for breaking changes (115), the generators and the API documentation (120), the gates (130), the owner actions for the rulesets (135) and the review (140). The refinement of 2026-11-04 made this order, because the pull request that adds the first `pom.xml` must pass `check-pins` and `license-check` (see the section Decisions Made).

### Requirements

- REQ-001: The OpenAPI file must be the only source for interfaces. A change to an interface must start in this file. A generated file has a mark that tells that no person must change it by hand.

- REQ-002: A linter must examine the OpenAPI file in each pull request.

- REQ-003: A tool must find breaking changes. The base of the comparison is the branch that the pull request goes to, and the gate uses the merge base (DEC 93594b2b-be54-4f60-9f53-ec2ce6c84be4). The gate stops if the ignore file has no entry for a breaking change.

- REQ-004: The build must make the Spring server interfaces and the Zod schemas from the OpenAPI file.

- REQ-005: CI must make the generated code again and must stop the pull request if the result is not the same as the code in the repository. This includes a file that is changed, deleted, added or not tracked by git.

- REQ-006: Errors must use RFC 9457 Problem Details. Each response with a status 4xx or 5xx must use the media type `application/problem+json` and one schema. The schema has a `code` from one list in the OpenAPI file and the trace identifier (DEC e3eadec0-a6ea-4efe-8e6d-fd19287122fa). The schema has no user-facing text in a language (DEC 51b00b5f-d1d8-49d8-9f40-28537ff69698): the members `title` and `detail` hold English text for the log and the developer, and the client must not show this text to a user. The generators make the list of codes for Java and for TypeScript from the same file, so the codes are the same in all languages. A lint rule stops a response that does not obey this.

- REQ-007: Each tool and each library must have a license check before the project uses it. The result is one of the words of DEC 84c37f7d-08cb-457d-8ab3-1db37dba9bc9: Permitted, Review or Not permitted. If a license is not clear, the work stops and the owner makes a decision.

- REQ-008: Each operation in the OpenAPI file must have the identifier of its specmgr requirement (a REQ UUID) in the extension `x-specmgr-req`. A lint rule stops an operation with no value or with a value that is not a UUID. The check that the UUID is the identifier of a real requirement is for GitHub issue #8.

- REQ-009: Each tool of this feature must have a version in `tools/versions.env` and a lock file or a checksum. CI must get each tool from these pins, and `just check-pins` must check them (DEC 2468257f-cb4e-4f30-a8df-6fc1d86759ce).

- REQ-010: The Maven module must have the Maven Wrapper with the Maven version of `tools/versions.env` and a sha256 value, so that `just check-pins` and `just sbom` accept the first `pom.xml`.

- REQ-011: The generators must make the same files each time. The generated files must have no time stamp and no other value that changes for each run.

- REQ-012: An accepted breaking change must follow DEC 93594b2b-be54-4f60-9f53-ec2ce6c84be4: one entry in an ignore file below `tools/`, and a higher version number of the interface in the same pull request.

- REQ-013: Each new gate must obey the conventions of feat-5-foundation-monorepo-ci: the CI job has the name of its recipe, the job is in `tools/gates/required-setup.txt`, the gate has negative tests in `just test-gates`, and the owner adds the job to the required checks of the rulesets.

- REQ-014: The owner must select each tool from a list of candidates, and the agent must not select a tool alone.

- REQ-015: CI must make the API documentation from the OpenAPI file with the generator `html2` of the plugin that is already pinned. The output must be the same on each run. The HTML is not committed. CI keeps it as an artifact.

### Acceptance Criteria

- [x] ACC-001: `contracts/` has an OpenAPI file with the operation `GET /status`, the schema for Problem Details with the `code` list and the trace identifier, and the extension `x-specmgr-req` with the UUID of a real REQ document in `docs/req/` (REQ-001, REQ-006, REQ-008).

- [x] ACC-002: `just` has recipes for lint, the check for breaking changes, code generation and the check of generated code, and CI starts only these recipes (REQ-002, REQ-003, REQ-004, REQ-005). Phase 110 did the recipe `lint` (and `test-lint-gate`), and phase 115 did the recipe `breaking-changes` (and `test-breaking-changes-gate`). Phase 120 did the recipe `generate` (and `compile`, `api-docs` and `test-generate-gate`). Phase 130 did the recipe `check-generated` (task 130.100) and the CI jobs `lint`, `breaking-changes`, `check-generated`, `compile` and `api-docs` (task 130.110): each job starts only the recipe of its name, and `just check-workflows` and its new cases in `just test-gates` check this. The jobs ran in real CI on head `fbb0653` (run https://github.com/dfch/biz.dfch.SpecMgrDemo/actions/runs/42158874460): all 12 jobs gave exit code 0 (`api-docs` 17s, `breaking-changes` 8s, `check-generated` 32s, `check-pins` 8s, `check-sudo` 7s, `check-workflows` 9s, `commit-check` 6s, `compile` 30s, `license-check` 45s, `lint` 18s, `test-gates` 11m17s, `validate` 24s). The throwaway pull request (task 130.120, ACC-015) still has the proof that a gate stops in real CI.

- [x] ACC-003: A change of the OpenAPI file that removes a property of a response causes a failure of the gate for breaking changes. The same change with an entry in the ignore file and a higher version number does not cause a failure. The same change with an entry and the same version number causes a failure. A pull request that adds the OpenAPI file for the first time does not cause a failure (REQ-003, REQ-012).

- [x] ACC-004: Each of these changes causes a failure of the gate for generated code: a change by hand to a generated file, a change of the OpenAPI file with no new generation, a deleted generated file, and an extra file in the folder of generated code (REQ-001, REQ-005). Done on 2026-11-05: `just test-check-generated-gate` (43 ok, started by `just test-gates`) runs the gate `just check-generated` with the real generators in a temporary git repository, and each of the four cases gives exit code 1 with the file in the message (also the variants: a Java file, a TypeScript file, a README, a new error code and a new `info.version`, a deleted file and a deleted folder, extra files in a sub-folder and one that `.gitignore` ignores). The evidence is in "Result of the Phase 130". The CI job `check-generated` ran in real CI on head `fbb0653` and gave exit code 0 (run 42158874460). The proof that the gate stops in real CI is part of ACC-015 (the throwaway pull request).

- [x] ACC-005: The Maven module and the pnpm module compile with the generated code in a CI job (REQ-004). Phase 120 did the compile through the recipe `just compile` (`./mvnw compile` and `pnpm exec tsc --noEmit --strict`, both return exit code 0, and `just test-generate-gate` runs it). Phase 130 did the CI job `compile` (task 130.105): it has `actions/checkout`, `extractions/setup-just`, `actions/setup-java`, `actions/setup-node` and `pnpm/action-setup`, and starts `just compile`. The job ran in real CI on head `fbb0653` and gave exit code 0 (run 42158874460, 30s). This criterion is met with the evidence of real CI. `just test-build-gates` (10 ok) shows that a Java compile error, a TypeScript type error and a type error in a generated TypeScript file stop the recipe.

- [x] ACC-006: Each tool and each library of the license table has the result Permitted, or a DEC of the owner for the result Review. No row has the result "open" (REQ-007).

- [x] ACC-007: Each of these cases causes a failure of the lint gate: a response 4xx or 5xx that does not use `application/problem+json` with the Problem Details schema, a Problem Details schema with no `code` or no trace identifier, an operation with no `x-specmgr-req`, and an operation with a value that is not a UUID (REQ-002, REQ-006, REQ-008).

- [x] ACC-008: The `code` list in the generated Java code and in the generated Zod schemas has the same values as the list in the OpenAPI file. A test compares them (REQ-006). Done on 2026-11-05: `just test-generate-gate` compares the YAML list with the Java enum (`getValue()`), with `errorCodeSchema.options` and with `Problem.code` of the Zod schemas, and it shows that the comparison stops for a value added, removed, changed or in another order.

- [x] ACC-009: The README of `contracts/` says that a change starts in the OpenAPI file. Each generated folder has a mark that tells "generated, do not change", and the gate of ACC-004 stops a change by hand (REQ-001). Phase 110 did the first part: `contracts/README.md` says that a change starts in the OpenAPI file, and it says where the generated code goes and that nobody changes it by hand. Phase 120 did the second part, the marks: each generated folder has a `README.md` "Generated code, do not change" (written by `generate.sh`), each Java file has `@Generated`, and each TypeScript file has the banner of Kubb (`generate.sh` and `just test-generate-gate` check them). Phase 130 did the third part: the gate `just check-generated` checks the marks in the committed code (the `README.md` with the title "Generated code, do not change" in each folder, `@Generated(` in each Java file, the banner of Kubb in each TypeScript file) and stops a change by hand (ACC-004). `just test-check-generated-gate` has the cases for a missing README, a README with no title, a Java file with no `@Generated` and a TypeScript file with no banner.

- [x] ACC-010: `backend/mvnw` is executable (git mode 100755), and `backend/.mvn/wrapper/maven-wrapper.properties` has the Maven version of `tools/versions.env` and a `distributionSha256Sum` that was verified with a source other than the properties file. `just check-pins`, `just sbom` and `just license-check` return exit code 0 with the real `backend/pom.xml` (REQ-010).

- [x] ACC-011: Each tool of this feature has a version in `tools/versions.env` and a lock file or a checksum. `just check-pins` returns exit code 0 now, and returns exit code 1 in `just test-gates` for a changed version and for a changed checksum of each tool (REQ-009). Phase 110 did Spectral: `SPECTRAL_VERSION` and `SPECTRAL_INTEGRITY` are in `tools/versions.env`, the lock file is `tools/spectral/pnpm-lock.yaml`, and `just test-gates` has the cases for a changed version and a changed integrity value (in `versions.env`, in `package.json` and in the lock file). Phase 115 did oasdiff: `OASDIFF_VERSION` and `OASDIFF_SHA256` are in `tools/versions.env`, the second place is `tools/breaking/oasdiff-checksums.txt` (the file `checksums.txt` of the release), and `just test-gates` has the cases for a changed version and a changed checksum (in `versions.env` alone and in the file alone). Phase 120 did the plugin jar of openapi-generator: `OPENAPI_GENERATOR_MAVEN_PLUGIN_VERSION` and `OPENAPI_GENERATOR_MAVEN_PLUGIN_SHA256` are in `tools/versions.env`, and `just check-pins` returns exit code 1 for a changed version (the second place is the version in `backend/pom.xml`). The checksum of the jar has a second place in `tools/generate/openapi-generator-maven-plugin.sha256`, and `just check-pins` compares the two, as it does for `cyclonedx-maven-plugin` (the second place is `tools/sbom/cyclonedx-maven-plugin.sha256`). This is tested in `just test-gates` (with a stub) and in `just test-generate-gate` (with the real plugin). Phase 120 also did Kubb, Zod and TypeScript: `KUBB_*`, `ZOD_*` and `TYPESCRIPT_*` (the version and the integrity value of each of six packages) are in `tools/versions.env`, the lock file is `frontend/pnpm-lock.yaml`, and `just test-gates` has the cases for a changed version and a changed integrity value in each of the three places, for each package. All four tools of this feature are pinned now.

- [x] ACC-012: The sha256 of the jar of the generator plugin is in `tools/versions.env`, and a gate compares it with the jar in the local Maven repository. `tools/gates/README.md` says that the dependencies of the Maven plugins are not checked. GitHub issue #23 has a comment with this limit, and it stays open for a full pinning of the Maven plugins (REQ-009). Done on 2026-11-05: the sha256 `9af831e2...a1c6` is in `tools/versions.env`, `verify_generator_plugin` compares it, `tools/gates/README.md` has the limit (rule G2 and "Limits"), and the comment is posted in issue #23 (https://github.com/dfch/biz.dfch.SpecMgrDemo/issues/23#issuecomment-6647138618). The issue is open.

- [x] ACC-013: Two runs of `just generate` one after the other make no change in the generated files (REQ-011). Done on 2026-11-05: `just test-generate-gate` compares the list, the mode and the sha256 of the 15 files of the two generated folders after run 1, after run 2 and after run 3 (another working folder, another time zone and locale): no difference. The files have no time stamp and no path of the machine.

- [x] ACC-014: DEC 93594b2b-be54-4f60-9f53-ec2ce6c84be4 has an update entry with the format of an entry of the ignore file and the way the gate checks the version number. The ignore file and the rules of the linter are below `tools/`, so CODEOWNERS covers them (REQ-012). Done in phase 115 (the update entry of 2026-11-05 00:56:45 in the DEC; `tools/breaking/` and `tools/lint/` are below `tools/`). The status of the DEC is still draft. The agent does not change it, and the owner accepts or changes the DEC in task 140.110. The criterion says only that the update entry exists, so it is ticked.

- [ ] ACC-015: Each new CI job is in `tools/gates/required-setup.txt` and has the name of its recipe. `just test-gates` has negative cases for each new gate. These recipes return exit code 0 on the branch: `just test-gates`, `just test-license-gate`, `just check-pins`, `just check-workflows`, `just check-sudo`, `just validate`, `just commit-check`, `just license-check` and `just --fmt --unstable --check`. A throwaway pull request (closed, not merged) with a breaking change fails the new job in real CI (REQ-013). Phase 115 did the negative cases for the gate for breaking changes (`just test-breaking-changes-gate`, started by `just test-gates`), and the listed recipes returned exit code 0 on the branch at the end of phase 115. Phase 120 did the negative cases for the generators and the pins (`just test-generate-gate` and the new cases of `just test-gates`, 725 ok), and the listed recipes returned exit code 0 on the branch at the end of phase 120. Phase 130 did the CI jobs and the lines in `tools/gates/required-setup.txt` (`lint`, `breaking-changes`, `check-generated`, `compile`, `api-docs`, and the changed line of `test-gates`), the gate `check-generated`, and the negative cases (`just test-check-generated-gate`: 43 ok, `just test-build-gates`: 10 ok, and 24 new cases in `selftest.sh` for the jobs; `just test-gates` 749 ok in `selftest.sh`), and the listed recipes returned exit code 0 on the branch at the end of phase 130 (see "Result of the Phase 130"). Not yet done, so this criterion is not ticked: the throwaway pull requests in real CI. The branch is pushed (pull request #33, head `fbb0653`), and the CI of the pull request ran all 12 jobs in real CI (run 42158874460, all exit code 0). Pending: Part A (the jobs `lint`, `check-generated`, `compile`, `api-docs` and `test-gates` with a change that must stop them; the orchestrator does this after the push of the review fixes) and Part B (the job `breaking-changes`, after the merge of feat-6 into `dev`, finding P2). The procedure, the branch names and the jobs that must fail are in "Result of the Phase 130".

- [ ] ACC-016: The owner added the new jobs to the required checks of the rulesets of `dev` and `main`, and `branch-protection.md` shows the new rows as set (REQ-013). Not ticked: this is an owner action (tasks 135.100 and 135.110). The agent made the table with the five new jobs in `branch-protection.md` in phase 130, and each row is "No" in the column "Set in the rulesets". This stays so until the owner adds the checks to the rulesets.

- [x] ACC-017: The phase 090 has a list of candidates for each tool, with the criteria, and the owner selected each tool. The decision is in the section Decisions Made (REQ-014).

- [x] ACC-018: CI makes the API documentation from the OpenAPI file with the generator `html2` of the openapi-generator plugin that is already pinned (no new tool). Two runs one after the other make the same HTML. The HTML is not in git, and CI keeps it as an artifact. The gate for generated code does not check it (REQ-015). Phase 120 did the generation: `just api-docs` makes `build/api-docs/index.html` with the generator `html2` of the pinned plugin, two runs make the same files (`diff -r`), and the folder is not in git. Phase 130 did the CI job `api-docs` (task 130.110): `actions/checkout`, `extractions/setup-just`, `actions/setup-java`, the step `just api-docs`, and then `actions/upload-artifact` (the artifact `api-docs`, path `build/api-docs/`, `if-no-files-found: error`, no `if:`). The gate for generated code does not check the HTML (it checks only the two generated folders). The job ran in real CI on head `fbb0653` (run 42158874460, 17s): it gave exit code 0 and kept the artifact `api-docs`. This criterion is met with the evidence of real CI.

### Scope

#### Included

- The OpenAPI file with one example operation (`GET /status`), the error schema with the `code` list, and the first REQ document for this operation.

- The linter with its rules, the tool for breaking changes with its ignore file, the server generator and the Zod generator. The owner selected the tools in the phase 090 (see the section Decisions Made).

- The API documentation, made from the OpenAPI file with the generator `html2` of the openapi-generator plugin (a second execution of the same plugin). It is a CI artifact and is not committed.

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

- Spectral (selected, CLI 6.17.0) is an npm package. It needs its own pnpm project with a lock file under `tools/` (as cdxgen), installed with `--frozen-lockfile --ignore-scripts`. `sbom.sh` and `check_pins.py` know only two manifest files in `tools/sbom/`, so the phase 110 changes both scripts and their tests.
- oasdiff (selected, 1.35.0) is a binary without a package manager. The owner chose a download with a sha256 value in `tools/versions.env`, started by a `just` recipe. This adds no new GitHub Action.
- The generator plugin for Maven (selected, openapi-generator 7.27.0) gets a sha256 value for its jar, as the plugin for the SBOM does. The dependencies of the plugin are not checked (GitHub issue #23). The second execution of the same plugin for the API documentation (generator `html2`) needs no new pin.
- The Zod generator (selected, Kubb) and Zod itself are in the lock file of the pnpm module `frontend/`. The packages `kubb`, `@kubb/plugin-zod` and `@kubb/plugin-ts` have exact versions that are tested together (see "Selected Tools and Fixed Values"). A root `package.json` must not have a `packageManager` field that is different from `PNPM_VERSION`.

Layout rules from the SBOM gate: the Maven module is `backend/pom.xml` with `backend/mvnw`. A pnpm module below `frontend/` is scanned only if `frontend/pnpm-workspace.yaml` and `frontend/pnpm-lock.yaml` exist. A `package.json` in `contracts/` stops the script.

Fixed values (Task 090.120, owner decision of 2026-11-04):

- Path of the OpenAPI file: `contracts/openapi.yaml`.
- Version of OpenAPI: 3.1.0. Spectral, oasdiff and Kubb read it. The support of openapi-generator for 3.1 is beta, and the tool writes a warning in the log. The owner accepted this.
- Folder of the generated Java code: `backend/src/generated`. The Maven module adds this folder as a source root, with `build-helper-maven-plugin` or with the plugin option `addCompileSourceRoot`. The exact mechanism is open for the phase 120.
- Folder of the generated Zod code: `frontend/src/generated`.
- Both generated folders are committed to git, so the gate of the phase 130 can compare them with a new generation (REQ-005).
- Mark "generated, do not change" (REQ-001, ACC-009): for the Zod code, the banner of Kubb ("Generated by Kubb (https://kubb.dev/). Do not edit manually.") that Kubb writes by default. For the Java code, a `README.md` or a header in the folder. The way and the details (for example, how the generator and the gate keep the file) are open for the phase 120.
- Options of the Spring generator (`spring`): `interfaceOnly=true`, `hideGenerationTimestamp=true`, `skipDefaultInterface=true`, and the plugin option `generateSupportingFiles=false`. Without a time stamp, the files are the same in each run (REQ-011).
- API documentation (REQ-015): a second execution of the same plugin with the generator `html2`. The output is not committed, CI keeps it as an artifact, and the gate for generated code does not check it. The folder of the output and the options are open for the task 120.130.
- Zod generator: Kubb runs in a small programmatic runner and not through the command `kubb generate`. This is set by the agent, and the owner can change it at the review. The cause and the details are in "Selected Tools and Fixed Values" below.

License table (the agent fills it from the license file of each tool and not from memory). The rows for Spectral, oasdiff, openapi-generator and Kubb have the name and the version of the tool that the owner selected in the phase 090. Result words: Permitted, Review, Not permitted (DEC 84c37f7d-08cb-457d-8ab3-1db37dba9bc9). A tool gets the check of its main license. A library that goes to users gets the check of all its dependencies through the SBOM gate.

| Item | Use | License | Result |
|---|---|---|---|
| Spectral CLI 6.17.0 (`@stoplight/spectral-cli`) | linter. Pinned in the phase 110: `SPECTRAL_VERSION` and `SPECTRAL_INTEGRITY` in `tools/versions.env` (the integrity value is the one of the registry, and the sha256 of the tarball `fdff6161...39bf` is the one of the phase 100), and the lock file `tools/spectral/pnpm-lock.yaml` (242 packages, installed with `pnpm install --frozen-lockfile --ignore-scripts`). Rule A applies, so the tree of Spectral is not in the SBOM (finding F3) | Apache-2.0 | Permitted |
| oasdiff 1.35.0 | breaking changes. Pinned in the phase 115: `OASDIFF_VERSION` and `OASDIFF_SHA256` in `tools/versions.env` (the sha256 `a8023002...9140` of `oasdiff_1.35.0_linux_amd64.tar.gz`, the one of the phase 100), and `tools/breaking/oasdiff-checksums.txt` (the file `checksums.txt` of the release). `install_oasdiff` in `tools/gates/_lib.sh` downloads it to `build/tools/` and compares the sha256 before it unpacks the file. Rule A applies, so oasdiff is not in the SBOM | Apache-2.0 | Permitted |
| openapi-generator 7.27.0 and its Maven plugin (`openapi-generator-maven-plugin`) | server interfaces (generator `spring`) and API documentation (generator `html2`, the same plugin, no new tool). Pinned in phase 120: `OPENAPI_GENERATOR_MAVEN_PLUGIN_VERSION` and `OPENAPI_GENERATOR_MAVEN_PLUGIN_SHA256` in `tools/versions.env` (the sha256 of the jar was computed again from Maven Central on 2026-11-05: `9af831e2...a1c6`, and the sha1 `f14a0cf6...` is the `.sha1` of Maven Central). The dependencies of the plugin are not checked (GitHub issue #23) | Apache-2.0 | Permitted |
| Kubb (`kubb` 5.15.3, `@kubb/plugin-zod` 5.8.0, `@kubb/plugin-ts` 5.4.0) | client schemas. Pinned in phase 120 with `@kubb/core` 5.15.3 (the runner imports it) in `frontend/`. Real run of the SBOM gate with the real `frontend/pnpm-lock.yaml` (2026-11-05): 102 components, all Permitted (93 MIT, 3 Apache-2.0, 3 ISC, 2 BSD-3-Clause, 1 PSF-2.0 `argparse` 3.0.4), the same result as the scratch test of the phase 100 | MIT (all three packages) | Permitted |
| Zod 4.6.7 | runtime library | MIT | Permitted |
| `argparse` 3.0.4 (in the tree of Kubb, through `js-yaml` 5.5.0) | library in the tree of the Zod generator. The owner stated on 2026-11-04 that its license PSF-2.0 is Permitted by DEC 84c37f7d-08cb-457d-8ab3-1db37dba9bc9. The phase 100 read the license file. | PSF-2.0 | Permitted |
| TypeScript 5.9.3 (the version that was tested) | compiler for ACC-005 | Apache-2.0 | Permitted |
| Spring Web: `spring-web` and `spring-context` 6.2.19, with their seven dependencies (`spring-beans`, `spring-core`, `spring-jcl`, `spring-aop`, `spring-expression`, `micrometer-observation`, `micrometer-commons`) | libraries that the generated Java code needs. In `backend/pom.xml` since phase 120 (`spring-web` and `spring-context` at 6.2.19, no BOM). Real run of the SBOM gate (2026-11-05): the nine Spring and Micrometer components (micrometer 1.15.12 is the version that `spring-web` 6.2.19 gives, with no BOM) are Apache-2.0 in the SBOM | Apache-2.0 (`spring-core` also has BSD-3-Clause code of ASM, and Apache-2.0 code of CGLIB, JavaPoet and Objenesis) | Permitted |
| `jakarta.validation-api` 3.0.2 (Jakarta Bean Validation, API only) | library that the generated Java code needs | Apache-2.0 | Permitted |
| `jackson-annotations` 2.21 | library that the generated Java code needs | Apache-2.0 | Permitted |
| `swagger-annotations-jakarta` 2.2.55 and `jackson-databind-nullable` 0.2.13 | libraries that the generated Java code needs only with the default options of the generator (the options `annotationLibrary=none`, `documentationProvider=none` and `openApiNullable=false` remove them). Phase 120 uses these three options, so neither library is in `backend/pom.xml` or in the SBOM | Apache-2.0 (both) | Permitted |
| `org.apache.tomcat:tomcat-annotations-api` 10.1.61 (in place of `jakarta.annotation-api`, see the finding F1 below) | library that the generated Java code needs with each option (`import jakarta.annotation.Generated` is in each template). The owner selected it on 2026-11-04. Used in phase 120: version 10.1.61 in `backend/pom.xml`. The real SBOM (`build/sbom/backend.cdx.json`, 12 components) has `org.apache.tomcat:tomcat-annotations-api@10.1.61` (Apache-2.0) and no `jakarta.annotation-api`; `just license-check` says `RESULT: PASS. 114 component(s), all licenses permitted` | Apache-2.0 (POM, `META-INF/LICENSE` and the manifest of the jar) | Permitted |
| `jakarta.annotation-api` 2.1.1 (and 3.0.0) | not used. The owner replaced it on 2026-11-04 (finding F1) | EPL-2.0 OR GPL-2.0-only WITH Classpath-exception-2.0 | Replaced (not used, so no DEC for the class Review is necessary) |
| Implementation of Jakarta Bean Validation (for example `hibernate-validator`) | runtime library | none | Not necessary: the generated code compiles with the API only, and this feature has no product code. A later feature must check the implementation before it adds it |
| Maven Wrapper 3.3.4 (type `only-script`: `mvnw` and `.mvn/wrapper/maven-wrapper.properties`) | build tool | Apache-2.0 | Permitted |
| Maven plugins of the build: `maven-wrapper-plugin` 3.3.4, `maven-clean-plugin` 3.5.0, `maven-resources-plugin` 3.5.0, `maven-compiler-plugin` 3.16.0, `maven-surefire-plugin` 3.6.0, `maven-jar-plugin` 3.5.1 (the versions that Maven 3.10.0 binds), and the two plugins above (`openapi-generator-maven-plugin` 7.27.0 and `cyclonedx-maven-plugin` 2.9.3) | build tools | Apache-2.0 (each plugin) | Permitted |
| New GitHub Actions | CI | None is new. The only action that this feature can add is `actions/upload-artifact` (ACC-018). It is already in `tools/license/allowed-actions.txt` (v7.0.2, MIT, checked in feat-5-foundation-monorepo-ci) and in `ci.yml` | Permitted (no new action) |

#### License Checks (Tasks 100.100 and 100.110)

The agent did the checks on 2026-11-04. The work folder was `/tmp/opencode/p100/` (outside of the repository, nothing from it is in git). The agent read the license file of each item and not only the field of a registry. DEC 84c37f7d-08cb-457d-8ab3-1db37dba9bc9 gives the classes. Rule A: a tool gets the check of its main license. A library that goes to users gets the check of all its dependencies through the SBOM gate. The agent did not add a license class to the DEC and did not change a file of `tools/`.

**Tools: the license file that the agent read**

| Item | Source of the license file | sha256 of the license file | Result of the reading |
|---|---|---|---|
| Spectral CLI 6.17.0 | `package/LICENSE` of the npm package `@stoplight/spectral-cli-6.17.0.tgz` (sha256 `fdff616155068111f5fe00cd06ae8fdb640630f1082ad1e59187d466af7039bf`, the sha512 integrity is the one of the registry), and https://github.com/stoplightio/spectral/blob/develop/LICENSE. The two files are the same | `d45c17f7ecc80e0deab3372ff352c7d00b7d573755c3c672088c21a376673698` | Apache-2.0 (copyright 2018 Stoplight). The field `license` of `package.json` is also Apache-2.0 |
| oasdiff 1.35.0 | `LICENSE` in the release file `oasdiff_1.35.0_linux_amd64.tar.gz` (sha256 `a8023002fcb2eaa7f5758148a9303cb63d33b939886df312268bc0fc7b939140`, the same value as in the plan and in `checksums.txt` of the release), and https://github.com/oasdiff/oasdiff/blob/main/LICENSE. The two files are the same | `c71d239df91726fc519c6eb72d318ec65820627232b2f796219e87dcf35d0ab4` | Apache-2.0 |
| openapi-generator 7.27.0 and plugin | https://github.com/OpenAPITools/openapi-generator/blob/master/LICENSE. The plugin jar (sha256 `9af831e2593931d9fe91a0804cd550f6f040bc690ab96aaf503b20c7558fa1c6`, the value in the plan) has no license file. The POM of its parent `openapi-generator-project` 7.27.0 says "Apache License 2.0". The generators `spring` and `html2` are in the core jar `openapi-generator-7.27.0.jar` (sha256 `0249ca38130103bb4743b08c34d02281dbe07c42df6cef92386efdb1b2cad67d`) of the same project | `91a2fcdfc23cbd1188a22cc3b76647bf6eb05c87889e376a19fe478f0398ff02` | Apache-2.0 (copyright 2018 OpenAPI-Generator Contributors and SmartBear) |
| Kubb: `kubb` 5.15.3, `@kubb/plugin-zod` 5.8.0, `@kubb/plugin-ts` 5.4.0 | `LICENSE` of each npm package (installed with `pnpm install --ignore-scripts`). The file of `kubb` is the same as https://github.com/kubb-labs/kubb/blob/main/LICENSE | `kubb`: `5918197284a9c383f145cee8311448cbc9204d2df7dd9536a432c25844a828be`. `@kubb/plugin-zod` and `@kubb/plugin-ts`: `64d31dd0303198f439f2a59c7ad6e98a3df0100067ec536c42530260d3b7751d` | MIT in all three (the text is the MIT text; the field `license` is MIT) |
| Zod 4.6.7 | `LICENSE` of the npm package. It is the same as https://github.com/colinhacks/zod/blob/main/LICENSE | `3f1189b28e3866e0d979968d466b78f813f76827cfdca1fbb124cc0a5c8841f8` | MIT (copyright 2025 Colin McDonnell) |
| `argparse` 3.0.4 | `LICENSE` of the npm package in the pnpm store of the scratch project. It is the same as https://github.com/nodeca/argparse/blob/master/LICENSE | `ab745c5061d1dea43a3885e5b4b6befc7e983954954775c5736debeefcdfd89b` | "PYTHON SOFTWARE FOUNDATION LICENSE VERSION 2", the field `license` is PSF-2.0. This is the class Permitted of the DEC |
| TypeScript 5.9.3 | `LICENSE.txt` of the npm package. It is the same as https://github.com/microsoft/TypeScript/blob/main/LICENSE.txt | `a7d00bfd54525bc694b6e32f64c7ebcf5e6b7ae3657be5cc12767bce74654a47` | Apache-2.0. The terms agree word for word with the Apache text (only the list markers are different). TypeScript 7.0.2 has the field `license` Apache-2.0 in the registry, and so have the three platform packages that the agent looked at |

For Spectral, oasdiff and openapi-generator, the terms of the file (from "TERMS AND CONDITIONS" to "END OF TERMS AND CONDITIONS", white space made equal) are the same as the text of https://www.apache.org/licenses/LICENSE-2.0.txt (sha256 `cfc7749b96f63bd31c3c42b5c471bf756814053e847c10f3eb003417bc523d30`). The license file of the installed Maven 3.10.0 and of `spring-web`, `micrometer-observation` and `swagger-annotations-jakarta` also has these terms.

**Generated Java code: what it needs**

The agent made a scratch Maven module with the pinned plugin 7.27.0 (generator `spring`, a 3.1.0 file, the four options of the task 090.120, all other options default), JDK 21.0.13 and Maven 3.10.0, a new local repository, and the Spring Boot BOM 3.5.16 for the versions. The generation and `mvn compile` gave BUILD SUCCESS. The generated code imports Spring Web (`ResponseEntity`, `web.bind.annotation.*`, `MultipartFile`), `spring-context` (`@Validated`), `spring-core` (`@Nullable`), Jakarta Validation, `jakarta.annotation.Generated`, Jackson annotations, the swagger annotations (`io.swagger.v3.oas.annotations`) and `JsonNullable`. The agent removed one library at a time and compiled the files with `javac`. Each of these is necessary: `spring-web`, `spring-context`, `spring-core` with `spring-beans`, `jakarta.validation-api`, `jakarta.annotation-api`, `jackson-annotations`, `swagger-annotations-jakarta` and `jackson-databind-nullable`. `jackson-databind` is not necessary to compile (a product that runs the code needs it). With the options `annotationLibrary=none`, `documentationProvider=none` and `openApiNullable=false`, the code compiles without the swagger annotations and without `jackson-databind-nullable` (the tree has 12 components). The options of the generator are for the task 120.100. The versions above are the tested ones, and the phase 120 must repeat the SBOM gate if it uses other versions.

**Java libraries and Maven items: what the agent read**

| Artifact | License in the POM | License file in the jar | sha256 of the jar |
|---|---|---|---|
| `spring-web` 6.2.19 (and `spring-beans`, `spring-core`, `spring-jcl`, `spring-aop`, `spring-expression`) | Apache License, Version 2.0 | `META-INF/license.txt`: Apache terms, and the notices for ASM (BSD-3-Clause) and for CGLIB, JavaPoet and Objenesis (Apache-2.0), which `spring-core` includes | `spring-web`: `ca88e364ecebee61163e2260e8a20584138eca74e28a050d6a2ef6302bad2f2d` |
| `spring-context` 6.2.19 | Apache License, Version 2.0 | the same `license.txt` | `ead4b645f94a7f665f00093eaafde634e97b34524294de653b51e43e0b3fc4a4` |
| `micrometer-observation` and `micrometer-commons` 1.15.12 | The Apache Software License, Version 2.0 | `META-INF/LICENSE`: Apache terms | not written |
| `jakarta.validation-api` 3.0.2 | Apache License 2.0 | none in the jar | `291c25e6910cc6a7ebd96d4c6baebf6d7c37676c5482c2d96146e901b62c1fc9` |
| `jackson-annotations` 2.21 (and `jackson-databind`, `jackson-core` 2.21.4, if a product needs them) | The Apache Software License, Version 2.0 | `META-INF/LICENSE`: the Apache text | `jackson-annotations`: `53ca085f4a150f703f49e1aabd935bd03b43e1ea3d55d135438292af22cef56b` |
| `swagger-annotations-jakarta` 2.2.55 | Apache License 2.0 (in the parent POM `swagger-project-jakarta`) | `META-INF/LICENSE`: Apache terms | `d464521aac0e9ae2cfead9d2f56e9e8c110ef4b15ad9c046408a087a4c58952b` |
| `jackson-databind-nullable` 0.2.13 | Apache License 2.0 | `META-INF/LICENSE`: the Apache text | `afd06e34c42e6724a3ccf7cb2e143bce8d5161c806db610d457cc64205c8f4b7` |
| `jakarta.annotation-api` 2.1.1 (not used, see F1) | two entries: "EPL 2.0" and "GPL2 w/ CPE" | `META-INF/LICENSE.md` (EPL-2.0 text and GPL-2.0 text with the Classpath Exception) and `META-INF/NOTICE.md` | `5f65fdaf424eee2b55e1d882ba9bb376be93fb09b37b808be6e22e8851c909fe` |
| `org.apache.tomcat:tomcat-annotations-api` 10.1.61 (read again on 2026-11-04 after the decision of the owner) | one entry: "Apache License, Version 2.0" (https://repo.maven.apache.org/maven2/org/apache/tomcat/tomcat-annotations-api/10.1.61/tomcat-annotations-api-10.1.61.pom). The POM has no `<parent>` and no `<dependencies>` | `META-INF/LICENSE`: the Apache text (sha256 `cfc7749b96f63bd31c3c42b5c471bf756814053e847c10f3eb003417bc523d30`, the terms are the same as https://www.apache.org/licenses/LICENSE-2.0.txt). `META-INF/NOTICE`: "Apache Tomcat, Copyright 1999-2026 The Apache Software Foundation" (sha256 `0317acaa42a5e48bec061cf009cb5c8b4b8ff845f3c6ba548f67c5c22c29fc96`). The manifest has `Bundle-License: https://www.apache.org/licenses/LICENSE-2.0.txt` | `8d408d675d89da99f86171ead3067f9e947accf722e3785e6775e9af387ff3a6` (the sha1 `5d547bce5b9c60146b965e419704989651ca8803` is the same as the `.sha1` on Maven Central) |
| `maven-wrapper-plugin` 3.3.4 | Apache-2.0 (parent `org.apache:apache`) | `META-INF/LICENSE`: the Apache text | `a355a8d7cb510412da78c2a165e4f500341028a569b12afa7fe99faf87516583` |
| Maven Wrapper `maven-wrapper-distribution` 3.3.4, type `only-script` (the zip with `mvnw`) | not read (the artifact has no POM in the local repository) | `mvnw` and `mvnw.cmd` have the Apache-2.0 header of the ASF. https://github.com/apache/maven-wrapper/blob/maven-wrapper-3.3.4/LICENSE is the Apache text (sha256 `cfc7749b96f63bd31c3c42b5c471bf756814053e847c10f3eb003417bc523d30`) | `6cb584c2bc907b849a0b931d8266d3ff3214cdd3127115ed4f49fb7176413d36` |
| `maven-clean-plugin` 3.5.0 | Apache-2.0 (parent `org.apache:apache`) | `META-INF/LICENSE`: the Apache text | `a15977e3457ff8cd803c1a37e1e53aad76e4609cd23bbca8e8f783e5c78e5fa8` |
| `maven-resources-plugin` 3.5.0 | Apache-2.0 (parent `org.apache:apache`) | `META-INF/LICENSE`: the Apache text | `2c923c63a197565a3e78f2b16d762d0f49bb83250dd2b1e6286704ea0f447060` |
| `maven-compiler-plugin` 3.16.0 | Apache-2.0 (parent `org.apache:apache`) | `META-INF/LICENSE`: the Apache text | `f2a6a4668dd833cfe559dd345929196e7b61ed13f6c03f8e087ffba3d85be807` |
| `maven-surefire-plugin` 3.6.0 | Apache-2.0 (parent `org.apache:apache`) | `META-INF/LICENSE`: the Apache text | `07117c7456920c14b9d3bdb9b1e82fbcb2fc5004ff2a3bd19c8fc6d25d6f15bb` |
| `maven-jar-plugin` 3.5.1 | Apache-2.0 (parent `org.apache:apache`) | `META-INF/LICENSE`: the Apache text | `c83db6059be3fec9a4a68a0e226caefaa944663008617c697e087444415181d5` |
| `cyclonedx-maven-plugin` 2.9.3 | Apache-2.0 | none in the jar. The result of feat-5-foundation-monorepo-ci stays | `c452d5eebe28bc86bef2e7c72d129f04f60877bef843eac8120f01fb655be293` (the value of `CYCLONEDX_MAVEN_PLUGIN_SHA256`) |

The plugins `maven-resources-plugin`, `maven-compiler-plugin`, `maven-surefire-plugin` and `maven-jar-plugin` (and `maven-clean-plugin` for `mvn clean`) are the plugins that the lifecycle of Maven 3.10.0 binds. The agent found them with `mvn clean verify` in the scratch module. `maven-install-plugin` and `maven-deploy-plugin` are not in the planned recipes (no `install` and no `deploy`), so they have no row. `build-helper-maven-plugin` is not necessary: the plugin option `addCompileSourceRoot=true` worked in the test, and the phase 120 uses it or checks `build-helper-maven-plugin` first. The Maven Wrapper downloads the Maven distribution `apache-maven-3.10.0-bin.zip` (the checked result of Maven is in `tools/versions.env`: Apache-2.0). The agent also checked `maven-wrapper-plugin` 3.3.4 with `wrapper:wrapper -Dtype=only-script -Dmaven=3.10.0` in the scratch folder: it makes `mvnw`, `mvnw.cmd` and `.mvn/wrapper/maven-wrapper.properties` and no jar.

**The SBOM gate with the real tools (scratch module and scratch `frontend/`)**

- Maven, default options of the generator (all eight libraries): `cyclonedx-maven-plugin` 2.9.3 gave 16 components. `tools/gates/license-check.sh` said: 15 PERMITTED (all Apache-2.0) and 1 STOP, `jakarta.annotation:jakarta.annotation-api@2.1.1`: `NOT KNOWN (EPL-2.0 AND A license exception symbol can only be used as an exception in a "WITH exception" statement. for token: "GPL-2.0-with-classpath-exception")`. Result: `RESULT: STOP. NOT PERMITTED: 0. NOT KNOWN: 1.`
- Maven, reduced options (12 components): the same one STOP for the same artifact.
- Maven, the artifact `org.apache.tomcat:tomcat-annotations-api` 10.1.61 in place of `jakarta.annotation-api` (see F1, alternative c): the code compiles, and the result is `RESULT: PASS. 12 component(s), all licenses permitted.`
- pnpm, scratch `frontend/` with `zod` 4.6.7 and the dev dependencies `@kubb/core` 5.15.3, `@kubb/plugin-ts` 5.4.0, `@kubb/plugin-zod` 5.8.0, `kubb` 5.15.3 and `typescript` 5.9.3 (91 packages installed): the real `tools/gates/sbom.sh` (with `SBOM_PROJECT_ROOT` and `SBOM_TOOL_DIR` on a copy of the cdxgen project, so that the repository did not change) made 102 components, and `tools/gates/license-check.sh` said `RESULT: PASS. 102 component(s), all licenses permitted.` The licenses in the tree: 93 MIT, 3 Apache-2.0, 3 ISC, 2 BSD-3-Clause and 1 PSF-2.0 (`argparse` 3.0.4, which `js-yaml` 5.5.0 needs). So the tree of Kubb has no license that is not in the DEC and in `tools/license/permitted-licenses.txt`. The package `@kubb/plugin-ts` lists `@typescript/typescript6` as a peer. pnpm did not install it, so it is not in this result.

**Findings**

- F1, `jakarta.annotation-api` (result Review, closed: the owner decided on 2026-11-04 to use alternative (c), see the end of this finding). The file `META-INF/NOTICE.md` of the jar says `SPDX-License-Identifier: EPL-2.0 OR GPL-2.0 WITH Classpath-exception-2.0` (sha256 of the file `3852834ebb4c2e04ecc18c9d099a05eab72cbd6edf35fb191390be6306019b4c`). The version 3.0.0 (jar sha256 `b01f55552284cfb149411e64eabca75e942d26d2e1786b32914250e4330afaa2`) has the same two entries in its POM and the line `SPDX-License-Identifier: EPL-2.0 OR GPL-2.0-only with Classpath-exception-2.0` in its notice, so the user selects one of the two licenses. In the DEC, `GPL-2.0-only WITH Classpath-exception-2.0` is Permitted and `EPL-2.0` is Review. The agent gives the result Review, and not Permitted, for these reasons: the POM has two `<license>` entries, so the SBOM has two entries, and the gate reads more than one entry as AND (README of `tools/license/`). The gate stops for this library, as the test above shows. The agent cannot change the DEC or `tools/license/`, and the selection of one license of an OR pair is not a rule of the DEC. The generator cannot avoid the library: the templates `model.mustache` and `api.mustache` of the generator `spring` have `import {{javaxPackage}}.annotation.Generated;` for each option. The alternatives for the owner (the agent does not select one):
  - (a) The owner states that an OR license is Permitted when one alternative is Permitted, and a change in `tools/license/` (owner review by CODEOWNERS) lets the gate read this library as `EPL-2.0 OR GPL-2.0-only WITH Classpath-exception-2.0`. The agent made no such change.
  - (b) The owner makes a DEC about the deviation for `EPL-2.0` (class Review). The gate must still be changed for the identifier `GPL-2.0-with-classpath-exception`.
  - (c) The project uses `org.apache.tomcat:tomcat-annotations-api` (Apache-2.0, POM and `META-INF/LICENSE` of the jar; jar sha256 `8d408d675d89da99f86171ead3067f9e947accf722e3785e6775e9af387ff3a6`, the sha1 is the one on Maven Central) in place of `jakarta.annotation-api`. The jar has the class `jakarta.annotation.Generated`. The test above shows that the generated code compiles with it and that the gate says PASS. The agent did not test this: a Spring Boot starter in a later feature can bring `jakarta.annotation-api` again.
  - Decision of the owner (2026-11-04): alternative (c). The owner made no change to the DEC and no change to `tools/license/`. The agent read the artifact again (see the row in the table above and the section Decisions Made). The jar has the class `jakarta.annotation.Generated` (interface with `value()`, `date()` and `comments()`, retention SOURCE). The jar has no dependency (the POM has no `<dependencies>`). The jar has the manifest values `Specification-Title: Jakarta Annotations`, `Specification-Version: 2.1` and `Implementation-Version: 2.1.1`, so it is the same API version as `jakarta.annotation-api` 2.1.1 of the Spring Boot 3.5 line, and it matches the option `useSpringBoot3` (Jakarta EE 10, package `jakarta.annotation`). The versions in the line 10.1.x are for this API. The line 9.0.x has the package `javax.annotation`, and the line 11.0.x has Jakarta Annotations 3.0, so neither is for this generated code. The newest version of the line 10.1.x on Maven Central is 10.1.61 (checked on 2026-11-04), which is the tested version. The Spring Boot BOM 3.5.16 manages the artifact at the older version 10.1.55 (`tomcat.version`). The agent did not test 10.1.55, so the `pom.xml` must name the version 10.1.61 and must not use the version of a BOM. The jar has the same package `jakarta.annotation` as `jakarta.annotation-api`, so the two jars must not be on the same class path (see the note in the task 120.100).
- F2, the generator `html2`. The core jar has the folder `htmlDocs2/`, and the generator writes these third-party parts into each HTML file: jQuery 3.7.1 (MIT), Bootstrap 2.3.2 (the header says Apache License 2.0), marked (the header says MIT), the JSON formatter (MIT in the file) and a script for code colors (no license text in the file, not checked). Rule A does not check them, because the HTML is an artifact of CI and not a product for users (REQ-015). If the owner publishes the HTML, this changes. The template `fonts.mustache` also has `@import url('https://fonts.googleapis.com/css?family=Source+Code+Pro')`, so a person who opens the HTML makes a network request. The task 120.130 must know this.
- F3, the tree of Spectral (rule A, not a gate item). The agent installed Spectral 6.17.0 in a scratch project with `pnpm install --ignore-scripts` (241 packages): 188 MIT, 27 Apache-2.0, 16 ISC, 3 Unlicense (`get-source`, `printable-characters`, `stacktracey`), 3 0BSD, 2 BSD-3-Clause, 1 BSD-2-Clause, and 1 with an old license field (`reserved` 0.1.2, MIT). `Unlicense` is not in the DEC. Spectral is a tool in `tools/`, so only its main license counts (Apache-2.0, Permitted). The task 110.110 must keep this project out of the SBOM, as it does for cdxgen, or the gate stops for `Unlicense`. Spectral also depends on `@scarf/scarf` (Apache-2.0), which has a `postinstall` script that makes a report. `--ignore-scripts` stops it, and the files of Spectral do not use it.
- F4, notes for the next phases that are not license questions. `tools/gates/check_workflows.py` allows `if: ${{ !cancelled() }}` only on `actions/upload-artifact` in the job `license-check` (`ALLOWED_IF`), so the job for the API documentation (task 130.110, ACC-018) must have no `if:`, or the gate must change. No new action is necessary: the jobs of this feature use `actions/setup-java`, `actions/setup-node`, `pnpm/action-setup` and `actions/upload-artifact`, and all four are in `tools/license/allowed-actions.txt` already. The row "New GitHub Actions" is therefore Permitted with no new action.

**What the agent could not check**

- The dependencies of the Maven plugins (rule A, GitHub issue #23): they are not in the SBOM and the agent did not read them.
- The Spring Boot 4 line (`useSpringBoot4`) and Spring 7. The agent read the POM and the notice of `jakarta.annotation-api` 3.0.0 only, and did not compile with it.
- TypeScript 7.0.2 (native): the agent read only the registry fields of the main package and of three platform packages (of 20), and did not install it or read the license files. The tested version is 5.9.3.
- The license of the script for code colors in the `html2` template, and the third-party parts in the Maven distribution `apache-maven-3.10.0-bin.zip` (rule A).
- The scratch `frontend/` is not the future `frontend/pnpm-lock.yaml`. The phase 120 must run the gate again with the real lock file.
- No person with legal competence examined the results (the DEC asks for this for the classes).

#### Candidates for the Tools (Task 090.100)

The agent wrote these lists on 2026-11-04. The agent did not select a tool (REQ-014). The owner selected the four tools on 2026-11-04 (task 090.110, see the section Decisions Made and "Selected Tools and Fixed Values" below). The lines that start with "The agent recommends" were not binding. The phase 100 filled the license table above (see "License Checks (Tasks 100.100 and 100.110)").

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

The owner answered on 2026-11-04: OpenAPI 3.1.0 with the beta support of openapi-generator accepted, the opt-out of the telemetry in the recipe accepted, the Zod generator in `frontend/` (with `argparse` 3.0.4 as Permitted), and openapi-generator selected for the server generator.

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

#### Selected Tools and Fixed Values (Tasks 090.110 and 090.120)

The owner selected these tools on 2026-11-04. The causes are in the section Decisions Made. The license class is the one that the agent read in the upstream repository (see the lists above), and the phase 100 reads each license file again.

| Tool | Selected | License (upstream) | Pin |
|---|---|---|---|
| Linter | Spectral CLI 6.17.0 | Apache-2.0 | pnpm lock file under `tools/`, `--frozen-lockfile --ignore-scripts` |
| Breaking changes | oasdiff 1.35.0 | Apache-2.0 | download, sha256 in `tools/versions.env` |
| Server generator and API documentation | openapi-generator 7.27.0, Maven plugin | Apache-2.0 | sha256 of the plugin jar in `tools/versions.env` |
| Zod generator | Kubb (`kubb`, `@kubb/plugin-zod`, `@kubb/plugin-ts`) | MIT | pnpm lock file in `frontend/`, `--frozen-lockfile --ignore-scripts` |

**Kubb**

- Versions: the agent checked the npm registry on 2026-11-04 (`npm view <package> version`): `kubb` 5.15.3, `@kubb/cli` 5.15.3, `@kubb/core` 5.15.3, `@kubb/plugin-zod` 5.8.0, `@kubb/plugin-ts` 5.4.0 and `zod` 4.6.7. These are the versions that the agent tested together in the research (the test project had `@kubb/core` as a direct dependency). The phase 120 pins `kubb`, `@kubb/plugin-zod` and `@kubb/plugin-ts` at exact versions (no `^` and no `~`) that work together. If the phase 120 uses a newer version, it must repeat the check and the tests.
- Network, command `kubb generate`: each start of the command makes one anonymous GET request to `registry.npmjs.org/@kubb/cli/latest`. No option switches it off. In the 5.x line it does not block, and it has a time-out of 3 seconds. With no network, the exit code is 0 and the result is the same. If packets are dropped, the start has a delay of up to about 10.6 seconds.
- Telemetry: Kubb sends data with a POST request to `otlp.kubb.dev`. The variable `KUBB_DISABLE_TELEMETRY=1` or `DO_NOT_TRACK=1` switches it off (only the value `1` or `true` counts).
- Programmatic API: `createKubb` from `@kubb/core`, with a config from `kubb/config`, makes no network call and sends no telemetry. The output is byte-identical to the output of the command.
- Design decision, set by the agent, and the owner can change it at the review: the recipe `generate` starts Kubb with a small programmatic runner (a `.mjs` file in `frontend/`) and not with the command `kubb generate`. So the generation makes no network call. The recipe also sets `KUBB_DISABLE_TELEMETRY=1` and `DO_NOT_TRACK=1`. The workflow gate does not allow `env:` in the workflow file, so the recipe sets them, and the owner accepted this. The phase 120 writes the runner and tests it (also with no network).
- Fallback: Hey API 0.99.0 (`@hey-api/openapi-ts` with the plugin `zod`) is the documented fallback.
- License of `argparse`: the owner chose `argparse` 3.0.4 (PSF-2.0, Permitted by DEC 84c37f7d-08cb-457d-8ab3-1db37dba9bc9). The tree of Kubb has `argparse@3.0.4`, so no pnpm override is necessary for Kubb. If the generator changes to Hey API, use the pnpm override `argparse` 3.0.4. The owner made no change to the DEC for `Python-2.0`.

**Design rule for `ErrorCode` and Problem Details (REQ-006, ACC-008)**

The evidence of the research is in `/tmp/opencode/r/` and `/tmp/opencode/s/`. These folders are not in the repository.

- One shared component schema `ErrorCode`: a string enum with lower snake case values. The values are unique. `Problem.code` uses it with `$ref`.
- The schema `Problem` has the properties `type`, `title`, `status`, `detail`, `instance`, `code` and `traceId`. `code` and `traceId` are required. The schema has no text in a language (REQ-006).
- Each response 4xx and 5xx has ONE media type, `application/problem+json`, with `$ref` to `#/components/schemas/Problem`. A shared `components/responses/ProblemResponse` that has the same content is also possible.
- The test for ACC-008 compares the list in the YAML file with the Java enum by `getValue()`, and not by the names of the constants (the generator adds number suffixes to a name if two names are the same). It compares the list with the Zod export `errorCodeSchema.options` also.

**Rules of the linter (task 110.115)**

The agent tested a ruleset with Spectral 6.17.0 on a 3.1.0 file. The file is `/tmp/opencode/r/spectral/ruleset.yaml` (outside of the repository, so the task 110.115 must copy it to a path below `tools/`). It is the start for the task 110.115. It has these rules: each response 4xx and 5xx has `application/problem+json` as the only media type with `$ref` to the schema `Problem` (or to `ProblemResponse`), `components.responses.ProblemResponse` follows the same rule, `Problem.code` is a `$ref` to `ErrorCode`, `Problem` requires `code` and `traceId`, `ErrorCode` is a unique string enum with lower snake case values, and each operation has `x-specmgr-req` with a UUID. These points are important:

- The rule for `x-specmgr-req` needs BOTH a `truthy` check and a `pattern` check with a UUID expression, because the function `pattern` does not report a missing field.
- The rules that check a `$ref` need `resolved: false`, because Spectral replaces the `$ref` with its target if the option is not set.

#### Result of the Phase 110 (OpenAPI Source and Lint)

The agent did the work on 2026-11-04 with the pinned tools of `~/.config/biz.dfch.SpecMgrDemo/env.sh` (Node 26.13.0, pnpm 12.16.1, just 1.59.0). The scratch folder was `/tmp/opencode/p110/` (outside of the repository, nothing from it is in git).

**Files**

| Path | Content |
|---|---|
| `contracts/openapi.yaml` | OpenAPI 3.1.0, `info.version` 0.1.0, the operation `GET /status` (`operationId` `getStatus`) with `x-specmgr-req: 1ca335d7-969a-443e-9392-165fdeea99a0`, the responses 200 (schema `Status`: `state` (`up` or `degraded`) and `checkedAt`) and 429, 500 and 503 (all `$ref` to `components/responses/ProblemResponse`, which has the one media type `application/problem+json` with `$ref` to `Problem`). `Problem` has `type`, `title`, `status`, `detail`, `instance`, `code` (`$ref` to `ErrorCode`) and `traceId` (OpenTelemetry, 32 hexadecimal characters), and `code` and `traceId` are required. `ErrorCode` has `not_found`, `validation_failed`, `rate_limited`, `internal_error` and `service_unavailable` |
| `docs/req/req-1ca335d7-...-the-system-gives-its-status.md` | REQ `1ca335d7-969a-443e-9392-165fdeea99a0` "The System Gives Its Status", status draft, level MUST, tag `iso29148:syrs`, links to DEC f92e35a1, f21920d2, 51b00b5f and e3eadec0 and to GOL b94e2758. `just validate` lints it |
| `contracts/README.md` | A change starts in the OpenAPI file, the generated folders, no change by hand, `just lint`, the Problem Details rule, the `x-specmgr-req` rule, the link to DEC 93594b2b-be54-4f60-9f53-ec2ce6c84be4 |
| `tools/spectral/` | `package.json`, `pnpm-lock.yaml` and `README.md`: the pnpm project of Spectral, as `tools/sbom/` is for cdxgen |
| `tools/lint/` | `ruleset.yaml`, `README.md` and `fixtures/` (49 OpenAPI files and `expected.txt`) |
| `tools/gates/lint.sh`, `tools/gates/test-lint-gate.sh` | The lint gate and its test. The recipes are `lint` and `test-lint-gate` (`test-gates` starts `test-lint-gate`) |
| `tools/versions.env` | `SPECTRAL_VERSION=6.17.0` and `SPECTRAL_INTEGRITY=sha512-9OTH...ZbL5UA==` |
| `tools/gates/check_pins.py`, `check-pins.sh`, `_lib.sh`, `sbom.sh`, `selftest.sh` | The pin check of cdxgen is now the function `check_pnpm_tool` with the data `CDXGEN` and `SPECTRAL` (the messages of cdxgen are the same). `check_pins.py` has a new argument (`<lint-tool-dir>`, in `check-pins.sh` the variable `LINT_TOOL_DIR`). `manifest_files` and the messages of `sbom.sh` know the two files of `tools/spectral/`. `selftest.sh` has 79 new cases (540 ok, before 461) |

**Rules of the linter** (the file `tools/lint/ruleset.yaml` has the causes): `problem-response-media-type-and-schema`, `problem-response-component`, `problem-schema-exists`, `error-code-schema-exists`, `problem-code-required`, `problem-trace-id-required`, `problem-code-uses-shared-list`, `problem-members`, `error-code-list`, `operation-req-present`, `operation-req-uuid` and `info-version-semver`, and the rules of `spectral:oas` (recommended, with four rules off: `info-contact`, `openapi-tags`, `operation-tags` and `tag-description`). The gate uses `--fail-severity warn`.

**Evidence**

- `just lint`: exit code 0 (`No results with a severity of 'warn' or higher found!`). The first run of the rules on the first version of the file gave one warning, `oas3-api-servers`. The file now has `servers: [{url: /}]`, which is the default of OpenAPI written out.
- `just test-lint-gate`: 59 ok, 0 failed (the real file, 49 fixtures, nine cases of the script). Each bad fixture fails with exactly the rules of its line in `tools/lint/fixtures/expected.txt`. The five cases of ACC-007 were also run with copies of the real file (a response with `application/json`, no `code`, no `traceId`, no `x-specmgr-req`, a value that is not a UUID): each gave exit code 1 with the rule of the case.
- `just check-pins`, `just sbom`, `just license-check` (0 components, PASS), `just test-license-gate` (47 ok), `just test-gates` (540 ok), `just check-workflows`, `just check-sudo`, `just validate` (linted=6), `just commit-check` and `just --fmt --unstable --check` return exit code 0.

**Findings and limits**

- L1, a rule on a part that is not there. A Spectral rule with a `given` path that matches nothing does not fail. So the rules for `Problem` and `ErrorCode` have a second rule that stops if the schema is not there (`problem-schema-exists`, `error-code-schema-exists`), and the fixtures 19 and 20 test it.
- L2, a missing `x-specmgr-req` has two findings. The function `schema` also runs for a field that is not there, so `operation-req-present` and `operation-req-uuid` both report it. This is accepted, and `expected.txt` has both rules.
- L3, `title` and `detail` of `Problem`. RFC 9457 has these two members as text for a person, and the fixed values of the task 090.120 list them. REQ-006 says that the schema has no text in a language. The agent kept the seven members of the fixed values, wrote in the file and in `contracts/README.md` that `title` and `detail` are for logs and for developers (English) and that a client must not show them to a user, and made the rule `problem-members` stop each other member (for example `message`). The owner decides if `title` and `detail` stay (see the open point in the Updates).
- L4, the tests of the lint gate need Node, pnpm and the network, so the CI job `test-gates` needs two more actions (see the task 130.110).
- The check that the UUID is the identifier of a real REQ is not in the linter (GitHub issue #8). Steps 4 and 5 of SOP 95b6735b-03b8-47a0-92aa-7934a4ff1519 (the VCR and the entry in a SYSRS) are not done for the REQ, because the task 110.105 asks only for the REQ.

**Behavior of oasdiff for the phase 115 (tested with 1.35.0)**

- A new enum value in a property of a RESPONSE is an `error` (a breaking change): the exit code is 1 with `--fail-on ERR`. The removal of a value is only `info`. The agent also tested a file of custom levels (`--severity-levels`, with the line `response-property-enum-value-removed err`) that makes a removal an error. The owner keeps the default levels, so a removal is not a breaking change.
- Each status (400, 404, 500, 503) gives its own finding. The ignore file needs one line for each status.
- The format of a line in the ignore file is `METHOD /path <full message>`. The option `-f singleline` prints the findings with one line for each finding, so a person can copy the message to the ignore file.

#### Result of the Phase 115 (Check for Breaking Changes)

The agent did the work on 2026-11-05 with the pinned tools of `~/.config/biz.dfch.SpecMgrDemo/env.sh` (Node 26.13.0, pnpm 12.16.1, just 1.59.0). The scratch folder was `/tmp/opencode/p115/` (outside of the repository, nothing from it is in git).

**Files**

| Path | Content |
|---|---|
| `tools/versions.env` | `OASDIFF_VERSION=1.35.0` and `OASDIFF_SHA256=a8023002...9140`, with a comment (what is checked, the platform) |
| `tools/breaking/` | `breaking-changes-ignore.txt` (the ignore file, with the header that explains the format, no entry), `oasdiff-checksums.txt` (the file `checksums.txt` of the release v1.35.0, without a change) and `README.md` (the format of an entry, how the gate decides, the pin and the procedure to change the version, the limits) |
| `tools/gates/breaking-changes.sh` | The gate: `git merge-base`, `git show <merge base>:<file>`, the install of oasdiff, and the start of `breaking_changes.py` in the virtual environment of PyYAML |
| `tools/gates/breaking_changes.py` | The ignore file, oasdiff, the used and the unused entries, the comparison of the version numbers (Semantic Versioning 2.0.0), and the subcommands `semver` and `rule` for the tests |
| `tools/gates/_lib.sh` | The new function `install_oasdiff` (download, sha256 before the unpack, `build/tools/`) |
| `tools/gates/check_pins.py`, `check-pins.sh` | The new function `check_oasdiff` and the new argument `<breaking-tool-dir>` (the variable `BREAKING_TOOL_DIR` in `check-pins.sh`). The output of `just check-pins` has the new line `Breaking-changes tool pin: ...` |
| `tools/gates/test-breaking-changes-gate.sh`, `selftest.sh` | The test of the gate (147 ok), and the cases of the pin of oasdiff in `selftest.sh` (35 new cases, 575 ok, before 540) |
| `justfile` | The recipes `breaking-changes` (gate number 115.110) and `test-breaking-changes-gate` (115.130). `test-gates` starts `test-breaking-changes-gate` |
| `tools/README.md`, `tools/gates/README.md` | The new folder, the new rows, the rows in the tables of the tools and of rule G2, and the note about `fetch-depth: 0` |
| `docs/dec/dec-93594b2b-...md` | The update entry of 2026-11-05 00:56:45 (the format of an entry, how the gate decides, the check of rule 5). The status is still `draft` |

**The pin (Task 115.100).** The agent got `checksums.txt` of the release v1.35.0 from GitHub, downloaded `oasdiff_1.35.0_linux_amd64.tar.gz`, and compared three values: `sha256sum` of the file, the line in `checksums.txt`, and the digest in the API of GitHub. The three values are `a8023002fcb2eaa7f5758148a9303cb63d33b939886df312268bc0fc7b939140`, the value of the phase 100. The platform is Linux x86_64 only, as the install scripts for just and Node (they hardcode `x86_64-unknown-linux-musl` and `linux-x64`): the gates run on a runner of GitHub (Ubuntu) and on the machine of the author, and `install_oasdiff` stops on another platform. The install location is `build/tools/oasdiff-<version>/` of the repository (the folder `build/` is in `.gitignore`), the test uses the same location. `install_oasdiff` does not use the file that is already there if `.sha256` of the folder is not the pin, and it compares the sha256 before it unpacks the file. `check_pins.py` needs a second place for the pin, or a changed version in `versions.env` would pass `just check-pins` (the check of the form alone does not see it). The second place is the file `checksums.txt` of the release. The check stops if the file has no line for `oasdiff_<OASDIFF_VERSION>_linux_amd64.tar.gz` with the value of `OASDIFF_SHA256`.

**How the gate decides (Tasks 115.110 and 115.120).**

1. `git merge-base <base> HEAD` (`<base>` is `{{ base }}` of the `justfile`: `origin/dev`, or `origin/<GITHUB_BASE_REF>`). If the merge base has no `contracts/openapi.yaml`, the gate passes ("nothing to compare"). If the merge base has the file and the working tree has not, the gate stops.
2. `oasdiff breaking <base file> <file> -f json --fail-on ERR` with no ignore file gives the changes of the level `error` (the default levels stay). Then one start for each entry, with that entry as the only line of the ignore file, shows which changes the entry ignores. A last start with all entries must agree (exit code 1 if and only if a change is left), or the gate stops with exit code 2.
3. A change that no entry ignores: exit code 1, with the line for the entry in the message. Entries that are used and a version that does not go up in the way of rule 5: exit code 1. No change of the level `error`: exit code 0, with entries or without. An entry that matches no change: a WARNING and exit code 0.
4. Rule 5 is read as: the new version is higher by the order of Semantic Versioning 2.0.0, and in addition, if the first number of the base is 0, the pair (first number, second number) is higher (`0.1.0` to `0.2.0` and to `1.0.0` pass, `0.1.0` to `0.1.1` does not), and if the first number is not 0, the first number goes up (`1.4.2` to `2.0.0` passes, `1.4.2` to `1.5.0` does not). So the DEC is stricter than "a higher version".

**Findings of the work with oasdiff 1.35.0 (tested with the real tool)**

- P1, a comment is an entry. oasdiff reads each line of the ignore file with `strings.Fields`, takes the first field that starts with `/` as the path, and ignores a change if the lower case line has the text `<operation> <path>` and the lower case text of the change anywhere in it. A line that starts with `#` is not a comment for oasdiff: `# GET /status removed the required property ...` ignores the change. A text after the message (a cause, a number) is no problem for oasdiff. So the gate gives oasdiff only the first item of each entry, and writes the other items for the owner.
- P2, a configuration file in the repository. oasdiff reads `.oasdiff.*` and `oasdiff.*` in the current folder and the variable `OASDIFF_CONFIG` (`err-ignore` is a key). A file like this switches off the check, and a test showed it. The gate starts oasdiff in a new empty folder and without the variables `OASDIFF_*`. The test has the case with the control that shows the file works without this protection.
- P3, exit codes. A file that oasdiff cannot read gives exit code 102 (also a missing file), and a missing ignore file gives 121. The gate stops with exit code 2 for each code other than 0 and 1. A value `version: 0.2` (a number in YAML) is a file that oasdiff cannot read (exit code 102). A file with no path (for example `a: b`) is read as an interface with no path, so all paths are removed, and the gate stops (a breaking change).
- P4, `-f json` and `--color`. The option `--color never` is only for the formats `text` and `singleline`, and oasdiff stops with exit code 100 for it with `-f json`. The gate does not use it.
- P5, the formats. `-f singleline` prints `error at <file>, in API GET /status <text> [<id>]`, and this is not the line for the ignore file. The JSON has `operation`, `path` and `text`, and the line is `<operation> <path> <text>`. The gate prints this line.

**Evidence of the four cases of ACC-003** (`just test-breaking-changes-gate`, temporary git repositories with the real oasdiff 1.35.0):

| Case | Result |
|---|---|
| (1) The change removes the required property `checkedAt` of the response 200 | exit code 1: `STOP breaking change that no entry ignores: GET /status removed the required property `checkedAt` from the response with the `200` status [response-required-property-removed]` |
| (2) The same change, one entry, `info.version` 0.1.0 to 0.2.0 | exit code 0: `RESULT: PASS. 1 breaking change(s) are ignored by 1 entry(ies), and the version goes up.` |
| (3) The same change, one entry, the same version 0.1.0 | exit code 1: `RESULT: STOP. 1 breaking change(s) are ignored, but the version does not go up.` |
| (4) The base has no OpenAPI file, the pull request adds it | exit code 0: `The base has no contracts/openapi.yaml, so there is nothing to compare` |

The test has 147 cases in all: the four cases, a lower version, the table of the rule for the version number (21 pairs), the table of the order of Semantic Versioning 2.0.0 (18 pairs and 12 texts that are not versions, each on both sides), the changes that are not breaking (an enum value is removed: pass with no entry, an enum value is added: stop), a stale entry (a WARNING), an entry for another change, two changes with one or two entries, a comment with the text of a change, a cause with the text of another change, nine entries that are not correct, a missing ignore file, the merge base (the base branch moves on, the feature merges the base, a release pull request to `main`), a base that does not exist, a deleted OpenAPI file, a configuration file and `OASDIFF_CONFIG`, a file that oasdiff cannot read, and the install (17 cases, with a small file that the test makes, no network). The agent changed the code three times to see if the test finds the change: a version rule that always passes (10 cases failed), oasdiff started in the folder of the repository (2 cases failed), and the variables `OASDIFF_*` not removed (1 case failed). The three changes are removed.

**Evidence of the gates** on this branch at the end of phase 115 (all with exit code 0): `just breaking-changes` (the base is `origin/dev`, the merge base has no `contracts/openapi.yaml`: "PASS. The base has no contracts/openapi.yaml, so there is nothing to compare"), `just test-breaking-changes-gate` (147 ok), `just check-pins`, `just sbom`, `just license-check` (0 components), `just test-gates` (575 ok), `just test-license-gate` (47 ok), `just check-workflows`, `just check-sudo`, `just lint`, `just validate`, `just commit-check` and `just --fmt --unstable --check`. The agent also started the gate with the real file against `HEAD` (the same file): `RESULT: PASS. No breaking change.`

**Limits and open points**

- L1, CI. The job `breaking-changes` of phase 130 needs `actions/checkout` with `fetch-depth: 0` (the merge base needs the history; `commit-check` has the same rule), `extractions/setup-just` and `astral-sh/setup-uv` (PyYAML from the lock file), and the network (GitHub, for the download of oasdiff). It needs no Node and no Java, so its line in `tools/gates/required-setup.txt` is `ci.yml breaking-changes actions/checkout extractions/setup-just astral-sh/setup-uv`. The job `test-gates` also needs the network now (the test downloads oasdiff once).
- L2, the file at the merge base is a copy in a temporary folder, so a relative `$ref` to another file does not resolve (the gate stops with exit code 2). The OpenAPI file of this feature is one file.
- L3, the gate does not check that item 4 of an entry (the release after which it ends) is higher than or equal to the new version.
- L4, a first-time pull request is not examined: the gate does not read the ignore file when the base has no OpenAPI file.
- L5, the ignore file is read from the pull request. The owner examines it by CODEOWNERS (`/tools/`), as the DEC says. The agent made no change to `.github/CODEOWNERS` because `/tools/` already covers `tools/breaking/`.

#### First Real Run (Phase 105)

The agent did the work on 2026-11-04 with the pinned tools of `~/.config/biz.dfch.SpecMgrDemo/env.sh` (JDK 21.0.13, Maven 3.10.0, just 1.59.0). The scratch folder was `/tmp/opencode/p105/` (outside of the repository, nothing from it is in git).

**How the agent made the wrapper files**

- The agent started the real plugin in an empty scratch folder with a new local Maven repository: `mvn org.apache.maven.plugins:maven-wrapper-plugin:3.3.4:wrapper -Dtype=only-script -Dmaven=3.10.0`. The result was BUILD SUCCESS. The plugin jar has the sha256 `a355a8d7cb510412da78c2a165e4f500341028a569b12afa7fe99faf87516583`, and the zip `maven-wrapper-distribution-3.3.4-only-script.zip` has the sha256 `6cb584c2bc907b849a0b931d8266d3ff3214cdd3127115ed4f49fb7176413d36`. Both values are the same as in the phase 100.
- The plugin made `mvnw`, `mvnw.cmd` and `.mvn/wrapper/maven-wrapper.properties` and no jar. The properties file has `wrapperVersion=3.3.4`, `distributionType=only-script` and the `distributionUrl` `https://repo.maven.apache.org/maven2/org/apache/maven/apache-maven/3.10.0/apache-maven-3.10.0-bin.zip`. It has no `distributionSha256Sum`.
- The agent copied `mvnw` (byte for byte, checked with `cmp`) and the properties file to `backend/`, and added the line `distributionSha256Sum=1f6d9909266510f039f59aa0e13dcd2c66da85f043e56276e41f2918f8bddaff` by hand. The agent did not copy `mvnw.cmd`: the task names two files only, the project has no Windows build, and the recipes need `bash`.

**How the agent verified the `distributionSha256Sum` (not with the properties file)**

| Step | Result |
|---|---|
| `apache-maven-3.10.0-bin.zip.sha512` from `repo.maven.apache.org`, from `archive.apache.org` and from `dlcdn.apache.org` | The three files have the same value: `22d31676d5b92ed53308c19ecded3245d0efd0cddfec51ec7bab62f4f13ad70ddddceff8e62940e0e8e2421f3cde8106737f4becec0aa034ffeff2a754e88337` |
| `sha512sum` of the zip from Maven Central and of the zip from `archive.apache.org` (10102082 bytes each) | Both are the value of the `.sha512` file |
| `sha256sum` of the same two files | Both are `1f6d9909266510f039f59aa0e13dcd2c66da85f043e56276e41f2918f8bddaff`. This is the value in `tools/gates/README.md` (section G1, written in feat-5) and the value in `maven-wrapper.properties` |
| `.sha256` file on Maven Central | Does not exist (HTTP 404), so no vendor value for the sha256 exists, and the sha256 is computed from a zip that has the vendor sha512 |
| `.tar.gz` of the same release | The `.sha512` file and `sha512sum` of the file are `908b1501bfb420bf7c8affb855534a9c407fd6099367bfb9f2f2dcb8e9799102bffb84518cde74c679bd76870247c6528683abdd620581bffa90f95d92d175aa`, the same as `MAVEN_SHA512` in `tools/versions.env` |

**Tests of the wrapper (copies in the scratch folder, a new `MAVEN_USER_HOME` for each test)**

- With the real value, `./mvnw -v` downloaded the zip, and Maven said "Apache Maven 3.10.0 (c43a36b8d67be7e0805a411bc0898af1a51f5472)" with Java 21.0.13 (Eclipse Adoptium).
- With the value changed to 64 zeros, `./mvnw -v` returned exit code 1 and the message "Failed to validate Maven distribution SHA-256, your Maven distribution might be compromised."
- With a PATH that has no `unzip`, `mvnw` 3.3.4 downloads the `.tar.gz` and compares it with the sha256 of the zip, so it stops with the same message (exit code 1). The check fails closed, but a machine with no `unzip` cannot use `mvnw`. The agent wrote this limit in `tools/gates/README.md`. The runners of GitHub and the machine of the author have `unzip`.

**`backend/pom.xml`**

The agent chose these values. The owner can change them at the review.

- `groupId` `biz.dfch.specmgrdemo`, `artifactId` `backend`, `version` `0.0.0-SNAPSHOT`. No document in the repository names a Maven `groupId`. The repository is `dfch/biz.dfch.SpecMgrDemo`, and the other projects of the owner use the `biz.dfch` prefix, so the `groupId` is the lower case form of the repository name.
- Packaging `jar`. The phase 120 adds the generated sources and compiles them. A `pom` packaging would not compile them. A jar with no source is empty, and Maven compiles nothing ("No sources to compile").
- `maven.compiler.release` 21 (the JDK of `tools/versions.env`), `project.build.sourceEncoding` UTF-8, and a fixed `project.build.outputTimestamp`, so that the archives of a build are the same in each run (REQ-011).
- No `<dependencies>`, no `<build>` and no version of a plugin. Maven 3.10.0 binds the plugins of the license table (`maven-clean-plugin` 3.5.0, `maven-resources-plugin` 3.5.0, `maven-compiler-plugin` 3.16.0, `maven-surefire-plugin` 3.6.0 and `maven-jar-plugin` 3.5.1).
- A `<licenses>` entry with AGPL-3.0-only, as in `NOTICE`.
- `.gitignore` has a new line `target/`, because the build writes `backend/target/` (the file `target/bom.json` of the SBOM gate). Before, only `/build/` was ignored.

**Result of the gates with the real `pom.xml` and the real `mvnw` (first real run)**

- `just check-pins`: exit code 0. Lines: `Maven pin: Maven Wrapper: 1 file(s), Maven 3.10.0` and `RESULT: PASS. 23 `uses:` step(s) with a full SHA, a comment and the versions of tools/versions.env. The lock file of cdxgen and the lock files of the Python tools are the ones of tools/versions.env.`
- `just sbom` (first run, with no cyclonedx jar in `~/.m2`): exit code 0. `mvnw` downloaded Maven 3.10.0 to `~/.m2/wrapper/dists`, Maven downloaded `cyclonedx-maven-plugin-2.9.3.jar` from Maven Central, and the gate said `sha256 of the plugin jar is the value of CYCLONEDX_MAVEN_PLUGIN_SHA256` (the jar has `c452d5eebe28bc86bef2e7c72d129f04f60877bef843eac8120f01fb655be293`). The plugin said `Creating BOM version 1.6 with 0 component(s)`, and the gate said `backend/pom.xml: 0 declared dependencies`, `0 component(s)` and `[sbom.sh] PASS`. The network was necessary (Maven Central for the Maven distribution, the plugin and the dependencies of the plugin).
- `just license-check` with the first version of the gates: exit code 2 (a gate error, not a license finding): `ERROR: build/sbom/backend.cdx.json: the SBOM has no `components` list (an empty SBOM has `components: []`)`. This is the gap that the stubs of `just test-gates` could not show, see the finding below.
- `just sbom` and `just license-check` after the fix: both exit code 0. The gate said `no `components` key and no declared dependency: wrote `components: []``, then `RESULT: PASS. 0 component(s), all licenses permitted.`
- `just test-gates`: exit code 0, `gates self-test: 461 ok, 0 failed`. `just test-license-gate`: exit code 0, `license gate fixtures: 47 ok, 0 failed`. `just check-workflows`: exit code 0. `just check-sudo`: exit code 0 (22 files). `just --fmt --unstable --check`: exit code 0. `just validate`: exit code 0 (`linted=5 failed=0`). `just commit-check`: exit code 0 (9 commits correct, the new work is not yet in a commit).
- The git mode of `backend/mvnw` is 100755 (`git ls-files -s backend/mvnw`: `100755 bd8896bf2217b46faa0291585e01ac1a3441a958`).

**Findings of the first real run**

- P1, the real plugin and an SBOM with no component. `cyclonedx-maven-plugin` 2.9.3 writes no `components` key for a project with no dependency (the key is optional in CycloneDX), and `license_check.py` stops for an SBOM with no `components` list (fixture `46-error-no-components.cdx.json` tests this on purpose). The stubs of `just test-gates` always wrote `components: []`, so no test found this. The agent made the smallest change that keeps the license gate strict: `sbom_check.py` (it already compares the manifests with the SBOM) writes `"components": []` to the file in the SBOM folder, but only for Maven, only if the SBOM has no `components` key, and only if the manifests declare no dependency. If a manifest declares a dependency, the SBOM stops the script (exit code 1) as before. The file `target/bom.json` of the plugin is not changed. `license_check.py` and its fixtures are not changed. New cases in `selftest.sh` (a stub mode `STUB_NO_COMPONENTS` that writes no key like the real plugin): no dependency (exit 0, the list is written, `license-check.sh` says `RESULT: PASS. 0 component(s)`, `target/bom.json` is not changed), a dependency in the `pom.xml` (exit 1), and a dependency in a module (exit 1). The behavior of cdxgen for a project with no dependency is not tested, so the change is for Maven only.
- P2, a test that expected the old state of the repository. The case "no pom.xml and no wrapper (the real repository)" in `selftest.sh` failed, because the repository now has the Maven project. The agent changed the case to expect `Maven Wrapper: 1 file(s), Maven 3.10.0`.

**What this run did not check**

- A library: the `pom.xml` has no dependency, so the SBOM has 0 components, and the license gate had nothing to compare. The phase 120 adds the libraries and runs the gate again (see the note in the task 120.100).
- The dependencies of `cyclonedx-maven-plugin` and of the other Maven plugins (GitHub issue #23), and the contents of the Maven distribution. The wrapper checks the sha256 of the zip only.
- The real `frontend/` (pnpm). The repository has no `frontend/package.json` yet.
- Maven plugins other than `cyclonedx-maven-plugin`: the SBOM gate does not start them. The agent started `./mvnw -B clean verify` in `backend/` once by hand (after the gates, not part of a recipe): BUILD SUCCESS with `clean` 3.5.0, `resources` 3.5.0, `compiler` 3.16.0 (`No sources to compile`), `surefire` 3.6.0 and `jar` 3.5.1 (`JAR will be empty`). These are the versions of the license table. The dependencies of these plugins were not read (GitHub issue #23). The agent deleted `backend/target/` after the run.

#### Result of the Phase 120 (Generators and API Documentation)

The agent did the work on 2026-11-05 with the pinned tools of `~/.config/biz.dfch.SpecMgrDemo/env.sh` (JDK 21.0.13, Node 26.13.0, pnpm 12.16.1, just 1.59.0, Maven 3.10.0 through `backend/mvnw`). The scratch folder was `/tmp/opencode/p120/` (outside of the repository, nothing from it is in git).

**Files**

| Path | Content |
|---|---|
| `backend/pom.xml` | The plugin `openapi-generator-maven-plugin` (property `openapi-generator.version` 7.27.0) with two executions: `spring-interfaces` (phase `generate-sources`, output `src/generated`, `sourceFolder` `java`, `addCompileSourceRoot`) and `api-docs` (phase `none`, generator `html2`, output `../build/api-docs`). Five libraries with no BOM: `spring-web` and `spring-context` 6.2.19, `jakarta.validation-api` 3.0.2, `jackson-annotations` 2.21 and `tomcat-annotations-api` 10.1.61 |
| `backend/src/generated/` | The generated Java code (committed): `java/biz/dfch/specmgrdemo/api/StatusApi.java`, `java/biz/dfch/specmgrdemo/model/{ErrorCode,Problem,Status}.java`, the marker `.openapi-generator/openapi.yaml-spring-interfaces.sha256` (the hash of the OpenAPI file) and the mark `README.md` |
| `frontend/` | `package.json`, `pnpm-workspace.yaml`, `pnpm-lock.yaml` (102 packages), `kubb.config.mjs`, `generate.mjs` (the runner), `tsconfig.json`, `README.md`, and `src/generated/` (committed): `types/{ErrorCode,GetStatus,Problem,Status}.ts`, `zod/{errorCodeSchema,getStatusSchema,problemSchema,statusSchema}.ts` and the mark `README.md` |
| `tools/gates/` | `generate.sh`, `compile.sh`, `api-docs.sh`, `test-generate-gate.sh`; `_lib.sh` has the new functions `verify_generator_plugin` and `install_frontend`; `check_pins.py` has `check_generator_plugin` and `check_frontend`; `selftest.sh` has 150 new cases (725 ok, before 575) |
| `tools/generate/` | `ErrorCodes.java`, `error-codes.mjs`, `error_codes.py` and `README.md`: the helper programs of the test of ACC-008 |
| `tools/versions.env` | `OPENAPI_GENERATOR_MAVEN_PLUGIN_VERSION`, `OPENAPI_GENERATOR_MAVEN_PLUGIN_SHA256`, and for Kubb, Zod and TypeScript five version keys and six integrity keys (`KUBB_VERSION`, `KUBB_INTEGRITY`, `KUBB_CORE_INTEGRITY`, `KUBB_PLUGIN_ZOD_*`, `KUBB_PLUGIN_TS_*`, `ZOD_*`, `TYPESCRIPT_*`). The agent compared the six integrity values with `npm view <package>@<version> dist.integrity` |
| `justfile` | The recipes `generate`, `compile`, `api-docs` (gate numbers 120.120 and 120.130) and `test-generate-gate`. `test-gates` starts `test-generate-gate` |
| `contracts/README.md`, `backend/README.md`, `frontend/README.md`, `tools/README.md`, `tools/gates/README.md` | The recipes, the generated folders, the options, the libraries, the procedure to change a version of Kubb, the limit about the dependencies of the Maven plugins |

**The plugin jar (Task 120.105).** The agent downloaded `openapi-generator-maven-plugin-7.27.0.jar` from Maven Central and computed the sha256 again: `9af831e2593931d9fe91a0804cd550f6f040bc690ab96aaf503b20c7558fa1c6` (the value of the phase 100). The sha1 of the file is the same as the `.sha1` file of Maven Central. `verify_generator_plugin` starts the goal `generate@spring-interfaces` with `-Dcodegen.skip=true` (Maven loads the plugin and downloads the jar, and nothing is generated), and compares the sha256 of the jar in `~/.m2/repository` with the pin before the real goal starts. The input of the plugin is checked before the property `codegen.skip`, so the call needs the execution id (a call with no execution has no `inputSpec`, and the plugin stops with an error). `just check-pins` ties the version in `versions.env` to the version of the plugin in each `pom.xml`.

**How the generation works.**

- Java: `generate.sh` checks the plugin jar, deletes `backend/src/generated`, starts `./mvnw org.openapitools:openapi-generator-maven-plugin:<version>:generate@spring-interfaces`, writes `README.md`, and stops if a Java file has no `@Generated`. The result is 4 Java files.
- Zod: `generate.sh` installs `frontend/` (`pnpm install --frozen-lockfile --ignore-scripts`, and the installed versions of the six packages must be the ones of `versions.env`), starts `node generate.mjs` with `KUBB_DISABLE_TELEMETRY=1` and `DO_NOT_TRACK=1`, writes `README.md`, and stops if a TypeScript file has no banner. The result is 8 TypeScript files. `@kubb/core` must be a direct dependency, because pnpm does not let the runner import a package that is only a dependency of `kubb`. `kubb` is necessary for `kubb/config`.
- The mark: Java has the annotation `@Generated` in each file (and `StatusApi.java` also has the comment "Do not edit the class manually") and the `README.md`; TypeScript has the banner "Generated by Kubb (https://kubb.dev/). Do not edit manually." in each file (no version and no time) and the `README.md`.
- `compile.sh`: `./mvnw compile` (the build makes the Java code again, because `spring-interfaces` is bound to `generate-sources`, and compiles it), and `pnpm exec tsc --noEmit --strict`.
- `api-docs.sh`: the plugin jar check, then `generate@api-docs` with `-Dapi-docs.dir=<output>`. The recipe uses `build/api-docs`.

**The test (Task 120.120): `just test-generate-gate`** (43 ok, 0 failed; it takes about 50 seconds). It needs JDK 21 (`JAVA_HOME` or the `PATH`), Node, pnpm, `uv` and the network (Maven Central, the npm registry, and the first run downloads Maven). The Maven local repository is `~/.m2/repository` (`GENERATOR_MAVEN_REPO_LOCAL` sets another). The test changes the two generated folders and makes them again.

- ACC-013, defined: "no change" is the same list of files, the same mode and the same sha256 in `backend/src/generated` and `frontend/src/generated` after run 1, run 2 and run 3. Run 3 starts in another working folder with `TZ=Pacific/Kiritimati LC_ALL=C LANG=C`. The test does not need a clean tree and does not compare with git (that is the gate of the task 130.100). If the folders have no change in git at the start, the test also checks that they have none at the end. Result: 15 files, no difference. No file has a time stamp, or the path of the repository, of the home folder or of `/tmp`. A changed file, an extra file in each folder and a deleted file are all gone after one run.
- ACC-008: `compile.sh` runs first. `ErrorCodes.java` (the source launcher of the JDK with `backend/target/classes`) prints the values of `ErrorCode.values()` by `getValue()`, `error-codes.mjs` prints `errorCodeSchema.options` and `problemSchema.shape.code.options`, and `error_codes.py` compares both with `components.schemas.ErrorCode.enum` (the same values in the same order). The comparison stops (exit code 1) for a value added, removed, changed, in another order or twice in the OpenAPI file, for a Java list with a value too many or too few, for a Zod list with a value too many and for `Problem.code` in another order. A file that has not the form gives exit code 2.
- ACC-012: with another `OPENAPI_GENERATOR_MAVEN_PLUGIN_SHA256`, `generate.sh`, `compile.sh` and `api-docs.sh` return exit code 1 before the plugin generates, and `generate.sh` leaves the generated folders as they are.
- ACC-018: two runs of `api-docs.sh` (the second in another working folder with another time zone) make the same files (`diff -r`), the HTML has no time stamp of this year or of last year and no path of the machine, and `build/api-docs` is ignored by git.

**Evidence of the gates** on this branch at the end of phase 120 (all with exit code 0): `just generate` (two runs, then `git diff` of the folders against the index is empty), `just compile`, `just api-docs` (two runs, `diff -r` of the folder against a copy: no difference), `just test-generate-gate` (43 ok), `just lint`, `just breaking-changes` (the base `origin/dev` has no OpenAPI file), `just check-pins`, `just sbom`, `just license-check` (`RESULT: PASS. 114 component(s), all licenses permitted`: 12 Maven components, all Apache-2.0, and 102 components of `frontend/`, 93 MIT, 3 Apache-2.0, 3 ISC, 2 BSD-3-Clause and 1 PSF-2.0; the SBOM has no `jakarta.annotation-api`), `just test-gates` (725 ok), `just test-license-gate` (47 ok), `just check-workflows`, `just check-sudo`, `just validate`, `just commit-check` and `just --fmt --unstable --check`.

**Findings of the work**

- G1, `html2` has no time stamp. Two runs of the generator `html2` made the same files with and without the option `hideGenerationTimestamp` (CLI, 7.27.0, with a pause between the runs). The agent keeps the option in `pom.xml` because it costs nothing and the other generator needs it. The HTML is one file of 606 kB. It has third-party scripts, and one of them has a fixed date of 2015 in a comment, so the test looks for a time stamp of this year or of last year.
- G2, Kubb and the file extension. The default of Kubb 5.15.3 writes imports with no file extension (`from './errorCodeSchema'`). `tsc` with `moduleResolution` `Bundler` reads them. The ESM loader of Node does not, so `error-codes.mjs` has a small hook (`registerHooks`) that tries `.ts`. The option `output.extension` of Kubb 4 does nothing in 5.x. The extension is an option of `parserTs` in `@kubb/parser-ts`, which would be one more direct dependency. The agent did not use it.
- G3, no barrel file. Kubb writes an `index.ts` for each plugin by default, and the barrel file has no banner. The option `barrel: false` of each plugin removes it, so each generated TypeScript file has the banner.
- G4, `input` of Kubb 5. The wrapper `input: { path: ... }` of Kubb 4 stops with `KUBB_LEGACY_INPUT`. The input is a string. The option `root` of the config is the folder of `kubb.config.mjs`, so the result does not depend on the working folder.
- G5, `tsc` and `URL`. Zod 4.6.7 uses the type `URL`, so `lib` has `DOM` (or `@types/node` is necessary). The agent chose `DOM`: it is a browser frontend.
- G6, the generator and the markers. With `generateSupportingFiles=false` the generator writes only the marker `.openapi-generator/openapi.yaml-spring-interfaces.sha256` (the hash of the OpenAPI file) and no `FILES`, `VERSION` or `.openapi-generator-ignore`. The marker is committed (see the section Decisions Made).
- G7, the plugin and `-Dcodegen.skip=true`: see "The plugin jar" above.
- G8, `./mvnw compile` makes the Java code again, because the execution is bound to `generate-sources`. The generation with the plugin option `skip` does not add the source root, so there is no way to compile the committed code without the generation, with this mechanism. The gate for generated code (task 130.100) makes the code again, and the job `compile` (task 130.105) does the same: if the committed code was not the generated code, the gate for generated code stops, not the compile.

**Needs of CI for the task 130.110 (the agent did not change the CI files)**

- `generate`: `actions/checkout`, `extractions/setup-just`, `actions/setup-java` (JDK 21, `temurin`), `actions/setup-node` and `pnpm/action-setup`. It needs the network (Maven Central, the npm registry). It needs no `uv`.
- `compile`: the same actions as `generate`.
- `api-docs`: `actions/checkout`, `extractions/setup-just`, `actions/setup-java` and `actions/upload-artifact` (no `if:`, because `check_workflows.py` allows `if: ${{ !cancelled() }}` only in the job `license-check`, see finding F4). It needs no Node.
- `test-gates` now also needs `actions/setup-java` (JDK 21, with `temurin`) in addition to Node, pnpm and `uv`: `just test-generate-gate` runs the generators and the Maven Wrapper. The cache of `~/.m2` is not a topic of this phase.
- A job that has `actions/setup-java` needs the line in `tools/gates/required-setup.txt` and the version of `tools/versions.env` (`JDK_VERSION`), as `check-pins` wants.

#### Result of the Phase 130 (Gates and CI Jobs)

The agent did the work on 2026-11-05 with the pinned tools of `~/.config/biz.dfch.SpecMgrDemo/env.sh` (JDK 21.0.13, Node 26.13.0, pnpm 12.16.1, just 1.59.0, Maven 3.10.0 through `backend/mvnw`). The agent did not push, did not make a branch or a pull request on GitHub, and did not use `gh` (the branch was pushed after the review: pull request #33, see the Updates). The scratch folders were temporary folders (outside of the repository, nothing from them is in git).

**Files**

| Path | Content |
|---|---|
| `tools/gates/check-generated.sh` | The gate for generated code (recipe `check-generated`, gate number 130.100) |
| `tools/gates/test-check-generated-gate.sh` | The test of the gate (recipe `test-check-generated-gate`): 43 ok. It uses a temporary git repository |
| `tools/gates/test-build-gates.sh` | The failing cases of `compile` and `api-docs` (recipe `test-build-gates`, gate number 130.105): 10 ok |
| `tools/gates/_lib.sh` | The new function `copy_work_tree <dest>`: a temporary git repository with a copy of the files of the work tree (`git ls-files --cached --others --exclude-standard`, so a file that is not yet committed is in the copy), one commit, branch `work`, tag `base`. The two new tests use it, so they never change the real work tree |
| `justfile` | The recipes `check-generated`, `test-check-generated-gate` and `test-build-gates`. `test-gates` starts the two tests too |
| `.github/workflows/ci.yml` | The new jobs `lint`, `breaking-changes`, `check-generated`, `compile` and `api-docs`, and the setup actions of the job `test-gates` |
| `tools/gates/required-setup.txt` | One line for each new job, and the changed line of `test-gates` |
| `tools/gates/selftest.sh` | 24 new cases (749 ok, before 725) for the new jobs |
| `tools/gates/README.md`, `tools/README.md`, `tools/versions.env`, `contracts/README.md`, `frontend/README.md`, `.specmgr/feat/feat-5-foundation-monorepo-ci/branch-protection.md` | The documents of task 130.130 |

**How the gate for generated code decides (Task 130.100)**

1. It compares with HEAD. In CI the work tree is HEAD (the checkout of the merge commit), so the code in the repository is the work tree. The command is `git status --porcelain --untracked-files=all --ignored -- <the two folders>` (with `core.fileMode=true`), and not only `git diff`: it finds a file that is changed, deleted, staged, not tracked (`??`) or ignored by `.gitignore` (`!!`).
2. Before the generation it stops (exit code 1) if a generated folder has no file in HEAD, if a file has the git flag assume-unchanged or skip-worktree (`git ls-files -v`; git status hides a change of such a file), or if `git status` shows any line for the two folders. This is the part that does not let `generate` hide a change: `generate.sh` deletes both folders and makes them again, so a change that exists only in the work tree (not committed, not tracked, or ignored) would be gone before the comparison. The test shows that the gate does not overwrite such a file.
3. It checks the marks in the committed code (ACC-009): the README of each folder with the title "Generated code, do not change", `@Generated(` in each Java file, the banner of Kubb in each TypeScript file, and at least one file of each kind.
4. It starts `generate.sh` (the script of `just generate`).
5. It runs the same `git status` again. After step 2 the work tree was HEAD, so each line is a difference between HEAD and the new generation: ` M` (a change by hand, or a change of the OpenAPI file with no new generation), ` D` (HEAD has a file that the generators do not make: an extra file), `??` (the generators make a file that HEAD has not: a deleted generated file) and `!!`. The gate prints the lines, a legend, and the start of `git diff HEAD`, and returns exit code 1.

The choice (set by the agent): the comparison is with HEAD and not with the index. In CI the index is HEAD, so there is no difference. On a developer machine, a staged or unstaged change in the generated folders stops the gate before the generation with the message that says what to do (commit the generated code first). The cause: a gate that passed for a work tree with a change that is not committed would pass on the machine and stop in CI. A change of `contracts/openapi.yaml` that is not committed does not stop the gate: it uses the file of the work tree. A change of a comment of `contracts/openapi.yaml` gives the same files, and the gate passes (the marker `.openapi-generator/*.sha256` has the hash of the parsed file, so a new `info.version` changes it).

**Evidence of the four cases of ACC-004** (`just test-check-generated-gate`, 43 ok, 0 failed, 78 seconds, real generators, temporary git repository, the change is committed as a pull request has it):

| Case | Result |
|---|---|
| (1) a line added by hand to `ErrorCode.java` (also a TypeScript file and the README of the folder) | exit code 1: `STOP: the code that the generators make now is not the code of HEAD:`, ` M backend/src/generated/java/biz/dfch/specmgrdemo/model/ErrorCode.java`, `RESULT: STOP. The generated code in the repository is not the generated code of contracts/openapi.yaml.` |
| (2) the OpenAPI file has a new error code `teapot`, no new generation (also a new `info.version`) | exit code 1: ` M` for `.openapi-generator/openapi.yaml-spring-interfaces.sha256`, `ErrorCode.java`, `types/ErrorCode.ts` and `zod/errorCodeSchema.ts`. A new `info.version` alone: ` M` for the marker only |
| (3) `StatusApi.java` is deleted (also a TypeScript file, and the whole folder `frontend/src/generated`) | exit code 1: `?? backend/src/generated/java/biz/dfch/specmgrdemo/api/StatusApi.java`. The deleted folder: `frontend/src/generated has no file in HEAD` |
| (4) an extra file in the folder (Java with a mark, TypeScript with a banner in a sub-folder, `notes.txt`, and `extra.log`, which `.gitignore` ignores and `git add -f` added) | exit code 1: ` D <the file>`. An extra Java or TypeScript file with no mark also stops the gate, with the message for the mark |

More cases of the test (all exit code 1): the work tree before the generation (a change by hand that is not committed, a staged change, a file that is not tracked, `Ignored.class` that `.gitignore` ignores, and the flags assume-unchanged and skip-worktree) stops the gate, and the changed file is still there after the run (the gate did not overwrite it); a change of the mode of a file; a missing README, a README with no title, a Java file with no `@Generated`, a TypeScript file with no banner; an OpenAPI file that the generator cannot read (`generate.sh failed`); no argument, a folder that does not exist, a folder that is not a git work tree, and a module that is not in the repository. The good cases (exit code 0): the copy of the repository (twice), a change of a comment of the OpenAPI file, and an untracked file and a change outside of the generated folders.

**CI jobs and `tools/gates/required-setup.txt` (Tasks 130.105 and 130.110).** Each job has the name of its recipe, `actions/checkout` (`fetch-depth: 0`, `persist-credentials: false`) and `extractions/setup-just`, and one `run: just <recipe>`. No action is new (all are in `tools/license/allowed-actions.txt`, and the license-check job already has `actions/setup-java`, so the existing mechanism works). The lines that the agent added to `tools/gates/required-setup.txt`:

```
ci.yml lint actions/checkout extractions/setup-just actions/setup-node pnpm/action-setup
ci.yml breaking-changes actions/checkout extractions/setup-just astral-sh/setup-uv
ci.yml check-generated actions/checkout extractions/setup-just actions/setup-java actions/setup-node pnpm/action-setup
ci.yml compile actions/checkout extractions/setup-just actions/setup-java actions/setup-node pnpm/action-setup
ci.yml api-docs actions/checkout extractions/setup-just actions/setup-java actions/upload-artifact
ci.yml test-gates actions/checkout extractions/setup-just astral-sh/setup-uv actions/setup-java actions/setup-node pnpm/action-setup
```

The last line replaces the old line of `test-gates` (it had only checkout, setup-just and setup-uv). The job `api-docs` has the upload step after `just api-docs` with no `if:` (the artifact `api-docs`, `build/api-docs/`, `if-no-files-found: error`), so the artifact is made only for a run that passes. The job `breaking-changes` needs the history for `git merge-base`, so it has `fetch-depth: 0` (all jobs have it, as `commit-check`), and the base is `origin/<GITHUB_BASE_REF>` of the `justfile`. The job has `astral-sh/setup-uv` (PyYAML) and no Node and no Java.

**Static checks of the workflow** (the agent cannot run real CI): `just check-workflows` (12 `run:` steps), `just check-pins` (47 `uses:` steps, the versions are the ones of `tools/versions.env`), `uvx --from actionlint-py actionlint` 1.7.12 on `ci.yml` (no finding), `yamllint` (only the style warning about the one space before the comment, which `check-pins` needs), and the 24 new cases of `selftest.sh`: for each new job, the missing action and the extra action stop the gate, the `if:` in `api-docs`, `needs`, a job that starts another recipe, and a wrong version of Java, Node, pnpm or uv in one job.

**What could be checked only statically (not in real CI):** the setup steps of the new jobs on a GitHub runner (the actions and the versions are the ones of `license-check`, which ran in real CI in feat-5); the cold start of the jobs (an empty `~/.m2`, an empty pnpm store: the local tests ran with warm caches, but `test-generate-gate` and the first run of each gate start the plugin with the sha256 check); the upload of the artifact `api-docs`; the base of `breaking-changes` in a pull request (`origin/<GITHUB_BASE_REF>` and the merge commit as HEAD, as `commit-check` has it); the time of the jobs (`just test-gates` takes 460 seconds here with warm caches, and the timeout of the job is 30 minutes); and that `just check-generated` passes on a clean checkout of the pull request (the tests use a clean copy, and `just check-generated` passes on the real work tree).

**The throwaway pull request (pending, Task 130.120).** The orchestrator or the owner does this after the branch is pushed. The workflow runs only for pull requests to `dev` and to `main`. The agent checked each expected result with the recipes in a temporary repository (the base `origin/dev` was a commit that has the OpenAPI file, for the case B1).

Part A (the branch is pushed, and feat-6 is not yet in `dev`). For each change: make a branch from the tip of `feat-6-contracts-openapi-pipeline` with one commit (`test(feat-6): throwaway ...`), open a pull request to `dev`, wait for the checks, write the result in this plan, close the pull request without a merge, and delete the branch.

| Branch | The change | The jobs that must fail (the others pass) |
|---|---|---|
| `throwaway/feat-6-lint` | In `contracts/openapi.yaml`, delete the line `x-specmgr-req: ...` of `GET /status`. Run `just generate` and commit the result (the marker has the hash of the file) | `lint` (rule `operation-req-present`) |
| `throwaway/feat-6-generated` | Add the line `// by hand` to `backend/src/generated/java/biz/dfch/specmgrdemo/model/ErrorCode.java` | `check-generated` (the message ` M backend/src/generated/java/.../ErrorCode.java`) |
| `throwaway/feat-6-compile` | Add `frontend/src/broken.ts` with `export const broken: number = "text";` | `compile` (`tsc failed`), and `test-gates` (its tests compile the copy of the repository) |
| `throwaway/feat-6-docs` | Add the line `  broken: [` at the end of `contracts/openapi.yaml` | `api-docs` (`Maven did not make the API documentation`), and also `lint`, `check-generated`, `compile` and `test-gates` |

Part B (after feat-6 is merged into `dev`: the gate for breaking changes passes if the base has no OpenAPI file, as ACC-003 case 4 says, so a pull request to `dev` can fail it only when `dev` has `contracts/openapi.yaml`). Branch `throwaway/feat-6-breaking` from `dev`: in `contracts/openapi.yaml`, delete the property `checkedAt` of the schema `Status` and its line in `required`, run `just generate`, commit. The job that must fail: `breaking-changes` (`GET /status removed the required property checkedAt from the response with the 200 status`). A second commit with an entry in `tools/breaking/breaking-changes-ignore.txt` and `info.version` 0.2.0 (and a new `just generate`) must make `breaking-changes` pass. Then close the pull request without a merge. Write the result of each run of Part A and Part B in this plan (the numbers of the pull requests, the runs, and the jobs that failed), and then tick ACC-015.

**Findings of the work**

- P1, the comment of the OpenAPI file. A change of a comment does not change the generated files, so the gate passes for it. This is right (the code is the same), and the test has it as a good case. The marker of the generator has the hash of the parsed file, so a new `info.version` or a new `description` changes it, and the gate then stops if the generated code is not made again.
- P2, `breaking-changes` cannot fail in real CI before feat-6 is in `dev`. The base of a pull request to `dev` is `dev`, which has no `contracts/openapi.yaml` yet, and the gate passes for such a base (ACC-003 case 4, on purpose). So the throwaway pull request for this gate is Part B, after the merge. The four jobs of Part A can be proven before. This changes the wording of ACC-015 ("a throwaway pull request with a breaking change fails the new job in real CI"): it can only be done after the merge of feat-6 into `dev`. The agent left the criterion open and wrote the two parts.
- P3, `compile` does not stop a broken generated Java file (finding G8 of phase 120): the Maven build makes the Java code again, so the file is replaced before the compile. `just test-build-gates` shows this (the compile passes) and shows that `check-generated` stops the same change. A broken generated TypeScript file stops `compile`, because the recipe compiles the committed TypeScript code.
- P4, `check-workflows` does not check `with:` of `actions/checkout`. A job without `fetch-depth: 0` is found only by its own run (`breaking-changes` stops, because the merge base is not in the clone). The agent did not change `check_workflows.py` (not in the task, and the README of the gates lists this limit).
- P5, the jobs `lint`, `compile`, `check-generated` and `api-docs` do not need `fetch-depth: 0`. The agent kept it in all jobs, as the other jobs have it (one form for the workflow, and the checkout of this repository is small).
- P6, the time of `just test-gates`: 460 seconds on the machine of the author (the test of the generated-code gate takes 78 seconds, `test-build-gates` 48 seconds, `test-generate-gate` about 55 seconds, and `selftest.sh` about 205 seconds).

**Evidence of the gates** on this branch at the end of phase 130 (all with exit code 0, run with the tools of `~/.config/biz.dfch.SpecMgrDemo/env.sh`): `just test-gates` (1124 ok, 0 failed after the review fixes; the parts: `selftest.sh` 761 ok, `test-license-gate` 47 ok, `test-lint-gate` 64 ok, `test-breaking-changes-gate` 155 ok, `test-generate-gate` 44 ok, `test-check-generated-gate` 43 ok, `test-build-gates` 10 ok; at the end of the phase the counts were 749 ok with 59 lint and 147 breaking cases), `just test-license-gate`, `just check-pins`, `just check-workflows` (12 run steps), `just check-sudo` (84 files), `just validate`, `just commit-check` (13 commits), `just sbom`, `just license-check` (`RESULT: PASS. 114 component(s), all licenses permitted.`), `just --fmt --unstable --check`, `just lint`, `just breaking-changes` (the base `origin/dev` has no OpenAPI file), `just generate`, `just check-generated` (`PASS. The generated code (15 files ...)`), `just compile` and `just api-docs`. `bash -n` is correct for each script of `tools/gates/`. The agent changed no Python file, so `ruff` and `py_compile` did not apply to this phase.

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

- [x] Task 090.110: The owner selects the four tools. Write the choice and the cause in the section Decisions Made. If the owner does not select a tool, stop (ACC-017)

- [x] Task 090.120: Fix the path and the version of the OpenAPI file, the folders of the generated code, and the options of the generators. Write them in the Design Notes and in the section Decisions Made (ACC-013)

#### Phase 100: License Checks

- [x] Task 100.100: Read the license file of each selected tool in the license table, and write the result. Stop and tell the owner if a license is not clear (ACC-006)

- [x] Task 100.110: Read the license of each library that the generated code needs, of the Maven Wrapper and of the Maven plugins, and write the results. Add a new class of license to DEC 84c37f7d-08cb-457d-8ab3-1db37dba9bc9 only with the permission of the owner (ACC-006)

- [x] Task 100.120: If a tool or library has the result Review, tell the owner and wait for a decision. Do not use the item before the decision (ACC-006). Done: the one Review (`jakarta.annotation-api`) is closed by the decision of the owner of 2026-11-04 (`tomcat-annotations-api` 10.1.61, Permitted)

#### Phase 105: Maven Wrapper and the Shell of the Backend Module

- [x] Task 105.100: Make `backend/pom.xml` with no dependencies. Add the Maven Wrapper without a jar (`backend/mvnw` and `backend/.mvn/wrapper/maven-wrapper.properties`) for the Maven version of `tools/versions.env`. Verify the `distributionSha256Sum` with the `.sha512` of Apache and `tools/gates/README.md`, and not only with the value in the properties file (ACC-010). Done on 2026-11-04: see the section "First Real Run (Phase 105)" in the Design Notes

- [x] Task 105.110: Set the git mode of `backend/mvnw` to 100755. Run `just check-pins`, `just sbom` and `just license-check` with the real `pom.xml`, and write the result in this plan. Change the section "Limits" of `tools/gates/README.md` for the first real run (ACC-010). Done on 2026-11-04: see the section "First Real Run (Phase 105)" in the Design Notes. The first run found one gap in `sbom_check.py`, and the agent fixed it (see the section Decisions Made)

#### Phase 110: OpenAPI Source and Lint

- [x] Task 110.100: Write the OpenAPI file with the operation `GET /status`, the Problem Details schema (the `code` list, the trace identifier, no text of a language), the response 4xx and 5xx with `application/problem+json`, and the extension `x-specmgr-req` (ACC-001, ACC-009). Done on 2026-11-04: `contracts/openapi.yaml` (see the section "Result of the Phase 110" in the Design Notes)

- [x] Task 110.105: Make the first REQ document with specmgr for the operation `GET /status` (this makes the folder `docs/req/`). The document has the status draft. Put its UUID in the extension. Write a README in `contracts/` (ACC-001, ACC-009). Done on 2026-11-04: REQ `1ca335d7-969a-443e-9392-165fdeea99a0` "The System Gives Its Status" (status draft), and `contracts/README.md`

- [x] Task 110.110: Add the selected linter: pin it (`tools/versions.env`, own pnpm project with a lock file under `tools/`), change `sbom.sh`, `check_pins.py` and their tests for the new manifest, and add it to the license table (ACC-011). Done on 2026-11-04: the pnpm project is `tools/spectral/`, and `SPECTRAL_VERSION` and `SPECTRAL_INTEGRITY` are in `tools/versions.env`

- [x] Task 110.115: Write the rules of the linter (REQ-006 and REQ-008) in a path below `tools/`, add the `just` recipe `lint`, and add the negative cases of ACC-007. The start is the tested ruleset in `/tmp/opencode/r/spectral/ruleset.yaml` (see the Design Notes, "Rules of the linter") (ACC-002, ACC-007). Done on 2026-11-04: the rules and the fixtures are in `tools/lint/`, and the recipes are `lint` and `test-lint-gate`

#### Phase 115: Check for Breaking Changes

- [x] Task 115.100: Add the selected tool for breaking changes as a download with a sha256 value in `tools/versions.env`. Add the install in the recipe. Change `check_pins.py` and its tests for the new pin (ACC-011). Done on 2026-11-05: `OASDIFF_VERSION` and `OASDIFF_SHA256` are in `tools/versions.env`, `install_oasdiff` in `tools/gates/_lib.sh` is the install (the gate starts it), and `check_pins.py` ties the pin to `tools/breaking/oasdiff-checksums.txt` (see the section "Result of the Phase 115")

- [x] Task 115.110: Write the recipe for the check. It uses `{{ base }}` and the merge base of `git merge-base`. It goes on if the base has no OpenAPI file (ACC-002, ACC-003). Done on 2026-11-05: the recipe is `breaking-changes` (`tools/gates/breaking-changes.sh`, gate number 115.110)

- [x] Task 115.120: Make the ignore file below `tools/` and the check of the version number (REQ-012). Add an update entry to DEC 93594b2b-be54-4f60-9f53-ec2ce6c84be4 with the format of an entry and the check. The status of the DEC is not changed by the agent (ACC-003, ACC-014). Done on 2026-11-05: `tools/breaking/breaking-changes-ignore.txt` (no entry), the check is `tools/gates/breaking_changes.py`, and the DEC has the update entry of 2026-11-05 00:56:45 (the status is still draft)

- [x] Task 115.130: Add the four cases of ACC-003 to `just test-gates` (ACC-003). Done on 2026-11-05: `just test-breaking-changes-gate` (`tools/gates/test-breaking-changes-gate.sh`) has the four cases and more, and `test-gates` starts it

#### Phase 120: Generators

- [x] Task 120.100: Add the generation of the Spring server interfaces to the Maven module, with the dependencies that the generated code needs and the options of the task 090.120 (ACC-005, ACC-013). Note (decision of the owner of 2026-11-04, phase 100, finding F1): the module must use `org.apache.tomcat:tomcat-annotations-api` 10.1.61 (with the version in the `pom.xml`, and not the version of a BOM) for `jakarta.annotation.Generated`, and it must NOT bring `jakarta.annotation-api` in again, for example through a Spring Boot starter or a BOM (use an exclusion if a dependency brings it, and look at the tree with `mvn dependency:tree`). Run `just sbom` and `just license-check` with the real `pom.xml`, and expect no `jakarta.annotation-api` in the SBOM (`build/sbom/backend.cdx.json`) and the result PASS. Done on 2026-11-05: `backend/pom.xml` has the plugin with the execution `spring-interfaces` and five libraries with no BOM. `just sbom` and `just license-check` pass with 12 Maven components (all Apache-2.0) and no `jakarta.annotation-api` (see "Result of the Phase 120" in the Design Notes)

- [x] Task 120.105: Add the sha256 of the jar of the generator plugin to `tools/versions.env`, and the comparison to a gate, as `sbom.sh` does for its plugin. Write the limit about the dependencies of the plugin in `tools/gates/README.md` and in a comment in GitHub issue #23 (ACC-012). Done on 2026-11-05: `OPENAPI_GENERATOR_MAVEN_PLUGIN_VERSION` and `OPENAPI_GENERATOR_MAVEN_PLUGIN_SHA256` are in `tools/versions.env`, `verify_generator_plugin` in `tools/gates/_lib.sh` is the comparison (the gates `generate`, `compile` and `api-docs` start it), `check_pins.py` compares the version with `backend/pom.xml`, the limit is in `tools/gates/README.md`, and the comment in issue #23 is posted (https://github.com/dfch/biz.dfch.SpecMgrDemo/issues/23#issuecomment-6647138618)

- [x] Task 120.110: Make the pnpm module in `frontend/` (`pnpm-workspace.yaml`, lock file) and the generation of the Zod schemas with Kubb. Pin `kubb`, `@kubb/plugin-zod` and `@kubb/plugin-ts` at exact versions that work together. Use the programmatic runner and not the command `kubb generate` (see the Design Notes). Install with `--frozen-lockfile --ignore-scripts` (ACC-005, ACC-011). Done on 2026-11-05: `frontend/` has `package.json`, `pnpm-workspace.yaml`, `pnpm-lock.yaml` (102 packages), `kubb.config.mjs`, `generate.mjs` (the runner, `createKubb` of `@kubb/core`) and `tsconfig.json`. The keys `KUBB_*`, `ZOD_*` and `TYPESCRIPT_*` of `tools/versions.env` and `check_pins.py` (`check_frontend`) pin them

- [x] Task 120.120: Write the `just` recipe `generate` that makes all generated code again, and the test for ACC-008 and ACC-013 (ACC-002, ACC-008, ACC-013). Done on 2026-11-05: the recipe is `generate` (`tools/gates/generate.sh`, gate number 120.120). The test is `just test-generate-gate` (`tools/gates/test-generate-gate.sh`, 43 ok), and `test-gates` starts it. The agent also added the recipe `compile` (`tools/gates/compile.sh`), because the quality gate of the phase needs a compile of the two modules through a recipe. The task 130.105 adds only the CI job for it

- [x] Task 120.130: Add the API documentation (REQ-015): a second execution of the plugin `openapi-generator-maven-plugin` that is already pinned, with the generator `html2`, and a `just` recipe for it. The output is below a folder that is not in git, and it is not in the gate for generated code. Test that two runs one after the other make the same HTML (check the options, for example the time stamp). The CI job that keeps the HTML as an artifact is added with the CI jobs of the phase 130. If this job is a required check, it is a question for the owner in the phase 135 (ACC-018). Done on 2026-11-05: the second execution `api-docs` of the plugin (generator `html2`, no phase) and the recipe `api-docs` (`tools/gates/api-docs.sh`, gate number 120.130) with the output `build/api-docs/index.html` (not in git). Two runs make the same files (`diff -r`, in `just test-generate-gate` and by hand). The CI job and the artifact are the task 130.110

#### Phase 130: Gates

- [x] Task 130.100: Write the gate that compares the generated code with the code in the repository. It also finds deleted, extra and untracked files (`git status --porcelain` and not only `git diff`) (ACC-004). Done on 2026-11-05: the recipe is `check-generated` (`tools/gates/check-generated.sh`, gate number 130.100). It stops for a change in the generated folders before the generation, checks the marks, starts `generate.sh`, and stops for each line of `git status --porcelain --untracked-files=all --ignored` for the two folders (it compares with HEAD). The test is `just test-check-generated-gate` (43 ok). See "Result of the Phase 130"

- [x] Task 130.105: Add the CI job that compiles the Maven module and the pnpm module with the generated code (ACC-005). Done on 2026-11-05: the job `compile` in `.github/workflows/ci.yml` (checkout, setup-just, setup-java, setup-node, pnpm/action-setup, `just compile`) and its line in `tools/gates/required-setup.txt`. The agent also added `just test-build-gates` (10 ok) for the failing cases of `compile` and `api-docs`. The job was checked statically only

- [x] Task 130.110: Add the lint gate, the gate for breaking changes, the gate for generated code, the compile job and the job for the API documentation (REQ-015) to the CI workflow and to `tools/gates/required-setup.txt`. The name of each job is the name of its recipe (ACC-015). Note from the phase 110: `just test-gates` now starts `just test-lint-gate`, and this test needs Node, pnpm and the network (it installs Spectral from the lock file). The CI job `test-gates` has only `actions/checkout`, `extractions/setup-just` and `astral-sh/setup-uv` today, so this task must add `actions/setup-node` and `pnpm/action-setup` (with the versions of `tools/versions.env`) to the job `test-gates` and change its line in `tools/gates/required-setup.txt`. The job `lint` needs the same two actions. Until then, the job `test-gates` of CI fails, and `just test-gates` passes on a machine that has the pinned Node and pnpm. Done on 2026-11-05: `.github/workflows/ci.yml` has the new jobs `lint` (Node, pnpm), `breaking-changes` (`fetch-depth: 0`, `uv`), `check-generated` (Java, Node, pnpm), `compile` (Java, Node, pnpm) and `api-docs` (Java, and `actions/upload-artifact` with no `if:`), and the job `test-gates` has `actions/setup-java`, `actions/setup-node` and `pnpm/action-setup` now. `tools/gates/required-setup.txt` has one line for each new job and the changed line of `test-gates`. No new action: each one is in `tools/license/allowed-actions.txt`. `just check-workflows` and `just check-pins` pass (12 run steps, 47 `uses:` steps), `actionlint` 1.7.12 finds nothing, and `selftest.sh` has 24 new cases (the missing and the extra action of each new job, the `if:` in `api-docs`, a wrong version in each new job). The jobs could be checked statically only (see "Result of the Phase 130")

- [ ] Task 130.120: Test each gate with a change that must cause a failure. Add the cases to `just test-gates`, write the results in this plan, and keep one throwaway pull request in real CI as proof (ACC-004, ACC-007, ACC-015). Not ticked: the task is done except the proof in real CI. Done on 2026-11-05: the negative cases of each gate are in `just test-gates` and the results are in "Result of the Phase 130": lint (`test-lint-gate`, 64 ok, the five cases of ACC-007), breaking changes (`test-breaking-changes-gate`, 155 ok), generated code (`test-check-generated-gate`, 43 ok, the four cases of ACC-004), compile and API documentation (`test-build-gates`, 10 ok), the generators (`test-generate-gate`, 44 ok), and the jobs of the workflow (`selftest.sh`, 761 ok; `just test-gates` 1124 ok). Pending: the throwaway pull requests in real CI (Part A after the push of the review fixes, Part B after the merge of feat-6 into `dev`, finding P2). The orchestrator or the owner does this. The branch is pushed (pull request #33). The procedure is in "Result of the Phase 130", section "The throwaway pull request (pending)"

- [x] Task 130.130: Change `tools/README.md`, `tools/gates/README.md`, the comments of `tools/versions.env` and the table in `branch-protection.md`. Run all recipes of ACC-015 (ACC-015). Done on 2026-11-05: `tools/README.md`, `tools/gates/README.md` (the new rows, the section "The CI jobs of feat-6-contracts-openapi-pipeline" and the section "The gate for generated code"), the comments of `tools/versions.env`, `contracts/README.md`, `frontend/README.md`, the header comments of `ci.yml` and `required-setup.txt`, and `branch-protection.md` (a new table with the five jobs, each marked "No" in the column "Set in the rulesets": the owner sets them in phase 135) are changed. All recipes of ACC-015 returned exit code 0 (see "Result of the Phase 130"). ACC-015 stays open for the throwaway pull request

#### Phase 135: Rulesets (Owner Actions)

- [ ] Task 135.100: The owner adds the new jobs to the required checks of the rulesets of `dev` and `main` after the first run of the jobs. The agent cannot do this (ACC-016). Not ticked: this task waits for the owner. The jobs `lint`, `breaking-changes`, `check-generated`, `compile` and `api-docs` (and the changed job `test-gates`) are in the file `ci.yml`, but they are not yet required checks. The first run of each job in real CI must come first (throwaway pull requests, task 130.120)

- [ ] Task 135.110: Update `branch-protection.md` for the new rows (ACC-016). Not ticked: this task waits for the owner, and it follows task 135.100. The agent added the table with the five jobs in phase 130, and each row is "No" in the column "Set in the rulesets". The agent does not change a row to "set". The owner changes each row to "set" after the owner adds the check to the rulesets

#### Phase 140: Review

- [ ] Task 140.100: The owner examines the license table and the open items (ACC-006). Not ticked: this task waits for the owner. ACC-006 is ticked, because no row has the result "open" (the owner decided the one Review in phase 100), but the owner has not yet examined the whole table

- [ ] Task 140.110: The owner accepts or changes DEC 93594b2b-be54-4f60-9f53-ec2ce6c84be4 (ACC-014). Not ticked: this task waits for the owner. The status of the DEC is draft, and the agent does not change it. The DEC has the update entry of phase 115 (the format of an entry and the check of the version number), which is the content of ACC-014

- [ ] Task 140.120: Write a comment in GitHub issue #23 (the limit that stays) and in GitHub issue #8 (the extension `x-specmgr-req` and the lint rule that exist). Set this feature to done in the last pull request, as the SOP "Close a Feature With One Pull Request" says (ACC-012). Not ticked: one part is done and one part is left. Done on 2026-11-05: the comment in issue #23 (https://github.com/dfch/biz.dfch.SpecMgrDemo/issues/23#issuecomment-6647138618, the limit about the dependencies of the Maven plugins, posted in phase 120) and the comment in issue #8 (https://github.com/dfch/biz.dfch.SpecMgrDemo/issues/8#issuecomment-6648179153: the extension `x-specmgr-req`, the rules `operation-req-present` and `operation-req-uuid`, the first REQ document, and what stays for the issue). Both issues are open. Left, on purpose: "Set this feature to done in the last pull request". The owner wants the status `review` for this pull request and `done` later, so the status `done` is set after the owner accepts the work (phases 135 and 140)

## Progress

### Current Status

**As of 2026-11-05 (all agent work, incl. the review fixes, done and pushed)**: All agent work of the phases 090 to 130 is done, the review fixes are in the commit `fbb0653`, and the branch is pushed to pull request #33. CI ran all 12 jobs in real CI on head `fbb0653` (run 42158874460): all jobs gave exit code 0 (`test-gates` in 11m17s). ACC-001 to ACC-014, ACC-017 and ACC-018 are ticked (ACC-005 and ACC-018 with the evidence of real CI), and ACC-015 and ACC-016 are not. Waiting for the owner: the throwaway pull request Part B after the merge of feat-6 into `dev`, the rulesets (phase 135), the review of the license table and of DEC 93594b2b-be54-4f60-9f53-ec2ce6c84be4 (phase 140), and the final status `done` (Part A of the throwaway pull requests is done by the orchestrator after the push of the review fixes).

### Blockers

- Open, for the owner (the points that stop the feature from being `done`):
  - Throwaway pull requests in real CI (task 130.120, ACC-015). The branch is pushed (pull request #33). Part A (the jobs `lint`, `check-generated`, `compile`, `api-docs` and `test-gates` with a change that must stop them) runs after the push of the review fixes; the orchestrator does this. Part B (the job `breaking-changes`) runs only after feat-6 is merged into `dev` (finding P2: the gate passes if the base has no OpenAPI file). The procedure, the branch names and the jobs that must fail are in "Result of the Phase 130", section "The throwaway pull request". After each run, the result goes in this plan.
  - The rulesets (phase 135, ACC-016): the owner adds the new jobs to the required checks of `dev` and `main`, and then changes the rows of `branch-protection.md` to "set". The owner also decides if the artifact job `api-docs` is a required check. The jobs `compile` and `check-generated` must be required checks together (the note is in `branch-protection.md`): a broken generated Java file does not stop `compile` (finding P3 of phase 130), and only `check-generated` stops it.
  - The review (phase 140): the owner examines the license table and the open items (task 140.100, ACC-006), and accepts or changes DEC 93594b2b-be54-4f60-9f53-ec2ce6c84be4 (task 140.110, ACC-014). The status of the DEC is draft.
  - The follow-up of `actions/cache` (the limit in `tools/gates/README.md`): the action is not in `tools/license/allowed-actions.txt`. A new action is a decision of the owner (REQ-014). If the owner adds the action, the cache of `~/.m2`, the pnpm store and `build/tools/` makes the job `test-gates` faster and less dependent on the network.
  - The final status: this feature is set to `review` for this pull request. The owner sets it to `done` later, and then the part "Set this feature to done" of task 140.120 is complete.
- Points that the agent set and that the owner can change at the review (the details are in the section Decisions Made):
  - Phase 105: the values of `backend/pom.xml` (group `biz.dfch.specmgrdemo`, artifact `backend`, version `0.0.0-SNAPSHOT`, packaging `jar`).
  - Phase 115: the version check of the gate for breaking changes is strict (rule 5 is read as higher by SemVer 2.0.0, and for a 0.x version the pair of the first and the second number must be higher, so `0.1.0` to `0.1.1` fails). An entry in the ignore file that matches no change only gives a WARNING. The pin of oasdiff has a second place, `tools/breaking/oasdiff-checksums.txt`, which the owner did not ask for.
  - Phase 120: Kubb starts with a programmatic runner (`frontend/generate.mjs`) and not with `kubb generate`. The generator options that go beyond the four fixed ones (`annotationLibrary`, `documentationProvider` and `openApiNullable` off). The Java source root (`src/generated/java` with the plugin option `addCompileSourceRoot`). The marks and the committed marker `.openapi-generator/*.sha256`. The recipe `compile` that the agent added.
  - Phase 130: the gate for generated code compares with HEAD and stops for a change that is not committed before it generates. `fetch-depth: 0` is in all jobs. The upload step of `api-docs` has no `if:`. `check-workflows` does not check `fetch-depth` (limit, finding P4). The job `test-gates` takes about 8 minutes (460 seconds with warm caches here, and the timeout of the job is 30 minutes).
- Closed: the open question of the phase 100 (`jakarta.annotation-api`): the owner decided on 2026-11-04 to use `tomcat-annotations-api` 10.1.61, and phase 120 uses it (no `jakarta.annotation-api` in the SBOM). The text members of `Problem` (finding L3, phase 110): the owner delegated the review fixes on 2026-11-05; the members `title` and `detail` stay, and REQ-006 is reworded (the section Decisions Made has the decision). The severity levels of oasdiff: the file `tools/breaking/oasdiff-severity-levels.txt` makes the removals of ACC-003 breaking, and DEC 93594b2b-be54-4f60-9f53-ec2ce6c84be4 has the update entry of 2026-11-05 08:45. The checksums of the two plugin jars have a second place in a file (`tools/generate/openapi-generator-maven-plugin.sha256`, `tools/sbom/cyclonedx-maven-plugin.sha256`), and `just check-pins` compares them.

### Updates

<!-- Newest entry first -- prepend new entries directly below this comment. -->

#### 2026-11-05 20:00:00.000Z - Review done: the code fixes are in fbb0653, the document fixes are in this entry, CI is green in real CI

The review of this feature (the feat-reviewer) found points in the code, the gates, the pins, the CI workflow, the documents and the terminology. The owner delegated all fixes to the agent ("fix all"). The code fixes are in the commit `fbb0653` (the test `test-generate-gate` on a temporary copy (E2), the second place of the two plugin jar checksums (D1), the lint rules for webhooks and callbacks with five new fixtures 49 to 53 (G1), the severity levels of oasdiff with the file `tools/breaking/oasdiff-severity-levels.txt` and the update entry of DEC 93594b2b-be54-4f60-9f53-ec2ce6c84be4 (G2), the scope `provided` of `tomcat-annotations-api` (I1), the limit of `actions/cache` written in `tools/gates/README.md` (I2), the retention of 90 days on the two artifact uploads (I3), and the points I4 to I9 and D4 (the note that `compile` and `check-generated` must be required checks together, in `branch-protection.md`)). This entry covers the document fixes: E1 (the members `title` and `detail` stay in `Problem`, and REQ-006 is reworded; the decision is in the section Decisions Made), D2 (the stale text about "the agent did not push" and "checked statically only" is replaced with the facts of the real CI, and the test counts are made consistent: lint 64, breaking 155, generate 44, check-generated 43, build 10, selftest 761, license 47, total 1124), D3 (the phase references are removed from the permanent READMEs; they describe the state now), G4 (the STE pass of the permanent READMEs, and the new terms in the terminology register; the details are in the section Decisions Made), and D4 (the note in `branch-protection.md`). CI ran in real CI on head `fbb0653` (run 42158874460): 11 of the 12 jobs passed at the time of the push of the code fixes, and `test-gates` finished after (11m17s, pass). All 12 jobs give exit code 0. The branch is pushed (pull request #33). Not done (the owner and the orchestrator): the throwaway pull request Part A (after the push of these fixes) and Part B (after the merge of feat-6 into `dev`), the rulesets (phase 135), the review of the license table and of DEC 93594b2b-be54-4f60-9f53-ec2ce6c84be4 (phase 140), the decision about `actions/cache`, and the final status `done`.

#### 2026-11-05 03:45:00.000Z - Agent work done: comment in issue #8, plan made consistent, waiting for the owner

The agent posted the comment in GitHub issue #8 (https://github.com/dfch/biz.dfch.SpecMgrDemo/issues/8#issuecomment-6648179153). It says that each operation in `contracts/openapi.yaml` has the extension `x-specmgr-req`, that the Spectral rules `operation-req-present` and `operation-req-uuid` stop an operation with no value or with a value that is not a UUID, and that the first REQ document is `docs/req/req-1ca335d7-969a-443e-9392-165fdeea99a0-the-system-gives-its-status.md` (status draft). It also says that the check that the UUID is the identifier of a real requirement, and the steps 4 and 5 of SOP 95b6735b-03b8-47a0-92aa-7934a4ff1519 (VCR and SYSRS entry) are not done and stay for the issue. The issue is open. With the comment in issue #23 of phase 120, the comment part of task 140.120 is done. Task 140.120 is not ticked, because the part "Set this feature to done" is left on purpose: the owner wants the status `review` for this pull request, and `done` later. The tasks 135.100, 135.110, 140.100 and 140.110 are owner actions and are not ticked, and no row of `branch-protection.md` is set. ACC-015 and ACC-016 are not ticked. The agent made the sections Current Status and Blockers consistent (one paragraph for the state, one list for the owner). The details of the phases stay in the entries below and in the section Decisions Made. The agent changed the status of no DEC. The changes are not committed.

#### 2026-11-05 03:35:00.000Z - Phase 130 done, except the throwaway pull request: the gate for generated code and the CI jobs

The agent did the tasks 130.100, 130.105, 130.110 and 130.130, and most of task 130.120. The new recipe `check-generated` (`tools/gates/check-generated.sh`) makes the generated code again and compares it with HEAD with `git status --porcelain --untracked-files=all --ignored` for `backend/src/generated` and `frontend/src/generated`, so it finds a file that is changed, deleted, extra, not tracked or ignored. Before the generation it stops if the folders are not clean (a change that is not committed, a staged change, an untracked or ignored file, and the git flags assume-unchanged and skip-worktree), so `generate` cannot hide a change by hand, and it checks the marks "generated, do not change". `just test-check-generated-gate` (43 ok, in a temporary git repository with the real generators) has the four cases of ACC-004 and more, and `just test-build-gates` (10 ok) has the failing cases of `compile` and `api-docs`. `.github/workflows/ci.yml` has the new jobs `lint`, `breaking-changes`, `check-generated`, `compile` and `api-docs` (the artifact `api-docs`, no `if:`), and the job `test-gates` has the actions for Java, Node and pnpm. `tools/gates/required-setup.txt` has a line for each. No new action was necessary. `selftest.sh` has 24 new cases for the jobs (`just test-gates` 749 ok, about 8 minutes). `branch-protection.md` has the five jobs as "not set" (the owner, phase 135). `tools/README.md`, `tools/gates/README.md`, `tools/versions.env`, `contracts/README.md` and `frontend/README.md` are changed. All recipes of ACC-015 return exit code 0 on the branch. ACC-002, ACC-004, ACC-005, ACC-009 and ACC-018 are ticked (ACC-005 and ACC-018 with the note that the jobs were checked statically only). Not done, because the agent did not push: the throwaway pull request in real CI (ACC-015), with the procedure in "Result of the Phase 130". Finding P2: `breaking-changes` can fail in real CI only after feat-6 is in `dev`. The changes are not committed.

#### 2026-11-05 02:45:00.000Z - Phase 120 done: the generators, the pins, the tests and the API documentation

The agent did the tasks 120.100, 120.105, 120.110, 120.120 and 120.130. `backend/pom.xml` has the plugin `openapi-generator-maven-plugin` 7.27.0 with the execution `spring-interfaces` (generator `spring`, the four fixed options and more, output `src/generated`) and the execution `api-docs` (generator `html2`), and five libraries with no BOM (`spring-web`, `spring-context`, `jakarta.validation-api`, `jackson-annotations` and `tomcat-annotations-api` 10.1.61). `frontend/` is a pnpm module (102 packages, `--frozen-lockfile --ignore-scripts`) with Kubb 5.15.3, `@kubb/plugin-zod` 5.8.0, `@kubb/plugin-ts` 5.4.0, Zod 4.6.7 and TypeScript 5.9.3, a runner `generate.mjs` (no network call) and a config. `tools/versions.env` has the pins (the version and the sha256 of the plugin jar, and the version and the integrity value of each of six packages), `check_pins.py` ties the version of the plugin to `backend/pom.xml` and the six packages to `package.json` and the lock file, and `verify_generator_plugin` compares the jar with the sha256 before each start of the plugin. The recipes `generate`, `compile`, `api-docs` and `test-generate-gate` are new. `just test-generate-gate` (43 ok) shows that two runs of `just generate` make the same 15 files (also in another working folder with another time zone), that the list of error codes is the same in the OpenAPI file, in the Java enum (`getValue()`) and in the Zod schema, that the comparison finds a difference, that another sha256 of the plugin jar stops the generators, and that two runs of `just api-docs` make the same HTML. `just test-gates` has 150 new cases (725 ok). `just sbom` and `just license-check` pass with the real manifests: 12 Maven components and 102 components of `frontend/`, all permitted, and no `jakarta.annotation-api`. The agent wrote the limit about the dependencies of the Maven plugins in `tools/gates/README.md`, and posted the comment in GitHub issue #23 (https://github.com/dfch/biz.dfch.SpecMgrDemo/issues/23#issuecomment-6647138618); the issue is open. ACC-008, ACC-011, ACC-012 and ACC-013 are ticked. ACC-002, ACC-004, ACC-005, ACC-009, ACC-015 and ACC-018 are not ticked, because only a part is true (each criterion says what stays: the gate for generated code and the CI jobs are for the phase 130). The findings G1 to G8 and the needs of CI are in "Result of the Phase 120" in the Design Notes. The agent did not change the CI files, and the changes are not committed.

#### 2026-11-05 01:04:20.000Z - Phase 115 done: oasdiff, the gate for breaking changes, the ignore file and the check of the version number

The agent did the tasks 115.100, 115.110, 115.120 and 115.130. oasdiff 1.35.0 is pinned: `OASDIFF_VERSION` and `OASDIFF_SHA256` are in `tools/versions.env` (Linux x86_64 only, as the install scripts for just and Node), the second place is `tools/breaking/oasdiff-checksums.txt` (the file `checksums.txt` of the release), and `check_pins.py` compares the two. The agent compared the sha256 of the download, the line in `checksums.txt` and the digest of GitHub again (all three are the value of the phase 100). `install_oasdiff` in `tools/gates/_lib.sh` downloads the file to `build/tools/` and compares the sha256 before it unpacks the file. The recipe `breaking-changes` (`tools/gates/breaking-changes.sh` with `breaking_changes.py`) finds the merge base with `git merge-base`, reads the OpenAPI file at the merge base, and goes on if the base has no such file. It starts oasdiff with `--fail-on ERR` (default levels), finds the used and the unused entries of the ignore file `tools/breaking/breaking-changes-ignore.txt` (no entry now) with one start of oasdiff for each entry, and checks the version number with rule 5 of DEC 93594b2b-be54-4f60-9f53-ec2ce6c84be4. The DEC has the update entry with the format of an entry and the check (its status is still draft). The test `just test-breaking-changes-gate` (147 ok, started by `just test-gates`, now 575 ok) uses temporary git repositories and the real oasdiff, and has the four cases of ACC-003 (the evidence is in "Result of the Phase 115"). ACC-003 and ACC-014 are ticked. ACC-002, ACC-011 and ACC-015 are not ticked, because only a part is true (each criterion says what stays). On this branch, `just breaking-changes` passes because `origin/dev` has no OpenAPI file. The work found two points of oasdiff that matter: a line that starts with `#` is a normal entry for oasdiff, and a configuration file `.oasdiff.*` in the current folder or the variable `OASDIFF_CONFIG` can switch off the check, so the gate gives oasdiff only the first item of each entry and starts it in an empty folder without `OASDIFF_*`. The agent did not change the CI files and did not change the status of the DEC. The changes are not committed.

#### 2026-11-04 19:05:00.000Z - Phase 110 done: OpenAPI file, first REQ, Spectral and the lint gate

The agent did the tasks 110.100, 110.105, 110.110 and 110.115. `contracts/openapi.yaml` is an OpenAPI 3.1.0 file (`info.version` 0.1.0) with `GET /status` (200 with `Status`, and 429, 500 and 503 as the shared `ProblemResponse` with `application/problem+json` and `Problem`), the schema `Problem` (`type`, `title`, `status`, `detail`, `instance`, `code`, `traceId`; `code` and `traceId` are required) and the list `ErrorCode` (`not_found`, `validation_failed`, `rate_limited`, `internal_error`, `service_unavailable`). The agent made the REQ `1ca335d7-969a-443e-9392-165fdeea99a0` "The System Gives Its Status" with the specmgr tools (status draft, SOP 95b6735b-03b8-47a0-92aa-7934a4ff1519 steps 1 to 3 and 6), which made `docs/req/`, and put its UUID in `x-specmgr-req`. `contracts/README.md` and `docs/README.md` are changed. Spectral 6.17.0 is a pnpm project in `tools/spectral/` with a lock file (242 packages), `SPECTRAL_VERSION` and `SPECTRAL_INTEGRITY` are in `tools/versions.env` (the integrity value is the same as the sha512 of the tarball, and the sha256 of the tarball is the one of the phase 100). `check_pins.py` checks the lock file with the same function as for cdxgen, and `sbom.sh` and `manifest_files` do not scan the two manifest files. The rules are in `tools/lint/ruleset.yaml` with 49 fixtures. The recipes `lint` and `test-lint-gate` are new, and `test-gates` starts `test-lint-gate`. `just test-gates` has 79 new cases (540 ok), and `just test-lint-gate` has 59 ok. ACC-001 and ACC-007 are ticked. ACC-002, ACC-009 and ACC-011 are not ticked, because only a part is true (each criterion says what stays). The details and the findings L1 to L4 are in "Result of the Phase 110" in the Design Notes. Two open points: the members `title` and `detail` of `Problem` (see the Blockers), and the CI job `test-gates`, which needs Node and pnpm (task 130.110). The agent did not change the CI files, the VCR and SYSRS of the REQ are not made, and the changes are not committed.

#### 2026-11-04 18:40:00.000Z - Phase 105 done: Maven Wrapper, shell of the backend module, first real run

The agent made `backend/pom.xml` (group `biz.dfch.specmgrdemo`, artifact `backend`, version `0.0.0-SNAPSHOT`, packaging `jar`, release 21, no dependency) and the Maven Wrapper without a jar (`backend/mvnw` and `backend/.mvn/wrapper/maven-wrapper.properties`). The agent made the wrapper files with the real plugin `maven-wrapper-plugin` 3.3.4 (`wrapper -Dtype=only-script -Dmaven=3.10.0`) in an empty scratch folder, and added the `distributionSha256Sum` by hand. The value `1f6d9909266510f039f59aa0e13dcd2c66da85f043e56276e41f2918f8bddaff` is the `sha256sum` of `apache-maven-3.10.0-bin.zip`. The agent verified it with the `.sha512` file of the zip from Maven Central, from `archive.apache.org` and from `dlcdn.apache.org` (the same value in all three, and `sha512sum` of both zips gives it), and with `tools/gates/README.md` (the same sha256). The `.tar.gz` and `MAVEN_SHA512` of `tools/versions.env` also agree. `./mvnw -v` passes with this value and stops (exit code 1) with a changed value. The git mode of `backend/mvnw` is 100755. `just check-pins`, `just sbom` and `just license-check` return exit code 0 with the real files (0 components, `RESULT: PASS. 0 component(s), all licenses permitted.`). The first real run found that the real plugin writes no `components` key for a project with no dependency, and `license_check.py` stops for this. The agent changed `sbom_check.py` (Maven only, no declared dependency only) to write `"components": []` to the file in the SBOM folder, and added three cases to `selftest.sh`. The agent also changed one case that expected the old state of the repository, added `target/` to `.gitignore`, and changed the section "Limits" and the new section "Maven Wrapper" of `tools/gates/README.md` (with the limit about a machine with no `unzip`), `backend/README.md`, and the comments of `sbom.sh` and `check_pins.py`. These recipes return exit code 0: `just test-gates` (461 ok), `just test-license-gate` (47 ok), `just check-workflows`, `just check-sudo`, `just --fmt --unstable --check`, `just validate` and `just commit-check`. The details and the list of what the run did not check are in the Design Notes ("First Real Run (Phase 105)"). The agent did not commit.

#### 2026-11-04 18:25:00.000Z - Phase 100 done: the owner decided finding F1

The owner decided finding F1 (`jakarta.annotation-api`): the project uses `org.apache.tomcat:tomcat-annotations-api` 10.1.61. The agent wrote the decision in the section Decisions Made and changed the license table: the new row for `tomcat-annotations-api` has the result Permitted, and the row of `jakarta.annotation-api` is "Replaced". The agent read the artifact again from Maven Central: the POM has one license (Apache License, Version 2.0), no `<parent>` and no `<dependencies>`, so the jar has no transitive dependency. The jar (sha256 `8d408d675d89da99f86171ead3067f9e947accf722e3785e6775e9af387ff3a6`, the sha1 is the same as on Maven Central) has `META-INF/LICENSE` (the Apache text) and `META-INF/NOTICE`, and it has the class `jakarta.annotation.Generated`. Its manifest says Jakarta Annotations 2.1 (implementation 2.1.1), the same API as the Spring Boot 3.5 line. 10.1.61 is the newest version of the line 10.1.x. The line 9.0.x has the package `javax.annotation`, and the line 11.0.x has Jakarta Annotations 3.0, so neither fits. The Spring Boot BOM 3.5.16 manages the artifact at 10.1.55, so the `pom.xml` must name the version. The agent ran the license gate again on the SBOM of the tested module: `RESULT: PASS. 12 component(s), all licenses permitted`, and the SBOM has no `jakarta.annotation-api`. The agent added a note to the task 120.100 (use `tomcat-annotations-api`, do not bring `jakarta.annotation-api` in again, expect no `jakarta.annotation-api` in the SBOM). The tasks 100.120 and ACC-006 are ticked, and the Blockers are empty. The next phase is the phase 105. The agent did not change the DEC or `tools/license/`, and changed only this plan.

#### 2026-11-04 16:55:00.000Z - Tasks 100.100 and 100.110 done, one Review open (task 100.120)

The agent read the license file of each tool and library of the license table, and filled the License and Result columns. The sources and the sha256 values are in the new section "License Checks (Tasks 100.100 and 100.110)" of the Design Notes. These items have the result Permitted: Spectral CLI 6.17.0 (Apache-2.0), oasdiff 1.35.0 (Apache-2.0), openapi-generator 7.27.0 with its Maven plugin and the generator `html2` (Apache-2.0), Kubb with `@kubb/plugin-zod` and `@kubb/plugin-ts` (MIT), Zod 4.6.7 (MIT), `argparse` 3.0.4 (PSF-2.0), TypeScript 5.9.3 (Apache-2.0), Spring Web and its seven dependencies (Apache-2.0), `jakarta.validation-api`, `jackson-annotations`, `swagger-annotations-jakarta` and `jackson-databind-nullable` (Apache-2.0), the Maven Wrapper 3.3.4 and the Maven plugins of the build (Apache-2.0). No new GitHub Action is necessary: `actions/upload-artifact` (ACC-018) is already in `tools/license/allowed-actions.txt`. An implementation of Jakarta Bean Validation is not necessary. The agent tested the Java libraries with a real generation (pinned plugin, a 3.1.0 file, the four fixed options) and a compile, and ran the real SBOM gate on the Maven tree and on the tree of Kubb in a scratch `frontend/` (102 components, all permitted). One item has the result Review: `jakarta.annotation-api` (`EPL-2.0 OR GPL-2.0-only WITH Classpath-exception-2.0`). The gate stops for it, and the agent did not change the DEC or `tools/license/`. The task 100.120 and ACC-006 wait for the decision of the owner (alternatives in finding F1). The section also has the findings F2 to F4 (bundled third-party code of `html2`, `Unlicense` in the tree of Spectral, the `if:` rule of `check_workflows.py` for the job of the API documentation) and the list of what the agent could not check. Only this plan was changed. The scratch work is in `/tmp/opencode/p100/`.

#### 2026-11-04 16:45:00.000Z - Phase 090 done: tools selected, values fixed

The owner selected the four tools (task 090.110) and fixed the values of the task 090.120. The agent wrote them in the section Decisions Made (three new entries) and in the Design Notes (the paragraph "Fixed values" and the new section "Selected Tools and Fixed Values"). The Design Notes now also have the ErrorCode design rule, the start for the rules of the linter and the behavior of oasdiff for the phase 115. The agent checked the versions `kubb` 5.15.3, `@kubb/cli` 5.15.3, `@kubb/core` 5.15.3, `@kubb/plugin-zod` 5.8.0, `@kubb/plugin-ts` 5.4.0, `zod` 4.6.7 and `@hey-api/openapi-ts` 0.99.0 against the npm registry (`npm view`, 2026-11-04). The names in the license table have the selected tools, and a row for `argparse` 3.0.4 is new. The results are still "open" for the phase 100. The owner added the API documentation: the plan has REQ-015, ACC-018, one bullet in Scope/Included and the task 120.130. ACC-017 is ticked. The agent set one design point (the programmatic runner for Kubb), and the owner can change it at the review. No file other than this plan was changed.

#### 2026-11-04 13:00:00.000Z - Task 090.100 done: lists of candidates

The agent wrote the lists of candidates in the Design Notes (section "Candidates for the Tools (Task 090.100)"). Each tool has two or three candidates: the linter (Spectral, Redocly CLI, vacuum), the tool for breaking changes (oasdiff, openapi-changes, openapi-diff), the server generator (openapi-generator, swagger-codegen v3) and the Zod generator (Kubb, Hey API, Orval). The agent read the license file of each candidate in the upstream repository, got the dates of the releases from the GitHub API and the npm registry, and started the tools with the pinned JDK 21.0.13 and Node 26.13.0 for the tests of the same output. The agent did not select a tool (REQ-014). The lists have the agent's recommendation for each tool, and it is not binding. The lists also have these facts for the owner: only the generator openapi-generator reads OpenAPI 3.1 (in beta), `swagger-codegen` and `openapi-diff` read only 3.0, Kubb and Redocly CLI send telemetry by default, and the Zod generators in a `frontend/` project can add packages with a license that is not in the table of DEC 84c37f7d-08cb-457d-8ab3-1db37dba9bc9 (`Python-2.0`). The tasks 090.110 and 090.120 wait for the owner. No file of the repository other than this plan was changed.

#### 2026-11-04 11:20:00.000Z - Plan refined

A refinement of the plan found these errors and gaps: the status was old (feat-5 is done), the plan had no step to select the tools, the Maven Wrapper was missing (the SBOM gate and `check_pins.py` stop a `pom.xml` with no `mvnw`), the base of the check for breaking changes was `main` and not the branch of the pull request, REQ-006 and REQ-008 had no test, the pins of the new tools were not described, the gate files were not in the plan, and the first real run of the SBOM gate was not in the plan. The owner decided on 2026-11-04 to keep one feature and to use more small phases. The plan now has the phases 090, 105, 115 and 135 in the gaps of the numbers, and the REQ-009 to REQ-014 and ACC-007 to ACC-017. Task 110.120 moved to the phase 115 (tasks 115.100 to 115.130), and no work was done for it. The agent wrote the new DEC 93594b2b-be54-4f60-9f53-ec2ce6c84be4 (status draft) for the policy about breaking changes. The status of the feature is now `progress`.

#### 2026-11-03 00:00:00.000Z - Plan written

The plan is written from the planning session of 2026-11-03.

### Decisions Made

<!-- Newest entry first -- prepend new entries directly below this comment. -->

#### 2026-11-05 20:00:00.000Z - Review fixes: the terminology register has the new terms (G4)

The STE pass of the permanent READMEs (`contracts/`, `backend/`, `frontend/`, `tools/`, `tools/gates/`, `tools/breaking/`, `tools/spectral/`, `tools/lint/`, `tools/generate/`, `tools/sbom/`) found words that the STE check did not accept and sentences that were longer than 25 words. The agent rewords the prose with approved words and short sentences (the facts, paths, commands and identifiers in backticks stay). The agent adds 61 technical nouns to the register (`terminology/en/technical-nouns.jsonl`), each with a line in the gap log (`terminology/en/gap-log.md`, date 2026-11-05). The terms of the reviewer (Kubb, Maven Wrapper with the spelling `mvnw`, lock file, ignore file, merge base, trace identifier, pin, checksum, severity level, webhook, callback) are in the list. The list has also the terms that the STE pass found (for example generated code, generation, run, jar, binary, manifest, integrity, hash, fixture, ruleset, registry, execution, enum, media type, documentation, environment, Semantic Versioning, clone, stub, self-test, comment, compiler, tree, folder, member, JSON, YAML, PyYAML, PyPI, Python, uv, Linux, Ubuntu, Windows, Maven Central, Jackson, Swagger, Jakarta EE, PSF, SHA, UUID, BOM, API, cdxgen, CycloneDX, time zone, snake case, starter, squash, rebase). The recipe names `lint`, `compile` and `generate` stay identifiers: in the prose they are in backticks, and they have no technical verb record. The checks of the SOP a64703aa-8e74-4c49-b7f5-f0977522a9af (the register check and the STE check, step 5) are done.

#### 2026-11-05 20:00:00.000Z - Review fixes: the members `title` and `detail` stay in `Problem` (E1)

The owner delegated all fixes of the review to the agent ("fix all"). For the point E1, the agent keeps the members `title` and `detail` of the schema `Problem` and rewords REQ-006. The members are standard members of RFC 9457. The schema has no user-facing text in a language (DEC 51b00b5f-d1d8-49d8-9f40-28537ff69698): `title` and `detail` hold English text for the log and the developer, and the client must not show this text to a user. REQ-006 in this plan, the Problem Details paragraph in `contracts/README.md` and the rule `problem-members` have this text. The alternative (the removal of both members) needs a change of the OpenAPI file, the rule `problem-members`, the fixtures 17, 18 and 11, the generated code and the REQ.

#### 2026-11-05 03:35:00.000Z - Phase 130: points that the agent set (the owner can change them at the review)

- The gate for generated code: recipe `check-generated` (the name is in line with `check-pins`, `check-sudo` and `check-workflows`, and it is the name of the CI job), gate number `130.100`. The scripts are `tools/gates/check-generated.sh` and `tools/gates/test-check-generated-gate.sh`. The agent also added `test-build-gates` (gate number `130.105`) for the failing cases of `compile` and `api-docs`, and the function `copy_work_tree` in `_lib.sh` for the two tests.
- The gate compares with HEAD, and not with the index. In CI the index is HEAD. On a developer machine a change in the generated folders that is not committed (unstaged, staged, untracked or ignored) stops the gate BEFORE it generates, with the message that says what to do. The causes: `generate.sh` deletes the folders and makes them again, so a change that exists only in the work tree would be hidden by the generation; and a gate that passed for an uncommitted change would pass on the machine and stop in CI. The cost: on a developer machine, commit the generated code before `just check-generated`. The gate also stops for a file with the git flag assume-unchanged or skip-worktree, and for an ignored file in the folders (`--ignored`). A change of `contracts/openapi.yaml` that is not committed does not stop the gate (it uses the work tree).
- The gate checks the marks (ACC-009) in the committed code before it generates, with the text of the README title "Generated code, do not change", `@Generated(` and the banner of Kubb. The texts are the ones of `generate.sh`. If the text in `generate.sh` changes, `check-generated.sh` and its test must change too (the test fails if not).
- The CI jobs: one job for each recipe (`lint`, `breaking-changes`, `check-generated`, `compile`, `api-docs`), each with the name of its recipe. There is no job `generate`: `check-generated` runs `generate.sh`, and the name of a job must be the name of the recipe that it starts. The actions of each job are the ones that its tools need (see the lines of `required-setup.txt` in "Result of the Phase 130"). All five jobs and `test-gates` have `fetch-depth: 0`, as the other jobs (one form for the workflow). JDK, Node and pnpm come from the existing setup actions (`actions/setup-java` with `temurin`, `actions/setup-node`, `pnpm/action-setup`), and Maven comes from the Maven Wrapper, so no action is new and no Maven setup action is necessary.
- `api-docs`: the upload step is after `just api-docs`, has no `if:` (`check_workflows.py` is not changed), and has `if-no-files-found: error`. So the artifact `api-docs` exists only for a run that passes. The name of the artifact is `api-docs` and the path is `build/api-docs/`. The owner decides in phase 135 whether this job is a required check (it is an artifact job).
- The tests use a temporary git repository (a copy of the work tree in one commit) and the real generators, and not the real work tree. The cases run in the same repository one after the other, with a `git reset --hard` to the tag `base` between them (the install of `frontend/` is made once). The runtime is practical: 78 seconds for the generated-code gate and 48 seconds for the build gates.
- `check_workflows.py` is not changed. A job that loses `fetch-depth: 0` is not found by `check-workflows` (limit, finding P4).
- The throwaway pull request is not done in this phase (the owner of the session said that nothing is pushed). The procedure is in "Result of the Phase 130". ACC-015 stays open. ACC-005 and ACC-018 are ticked after the static check, as the orchestrator asked, with a note in each criterion.

#### 2026-11-05 02:45:00.000Z - Phase 120: points that the agent set (the owner can change them at the review)

- Source root of the Java code: the plugin option `addCompileSourceRoot` of the execution `spring-interfaces`, with `output` `backend/src/generated` and the generator option `sourceFolder` `java`. So the source root is `backend/src/generated/java`, and no other plugin is necessary (`build-helper-maven-plugin` is not used, so it needs no license row and no pin). The result of this choice: the source root is added only when the plugin runs, so `./mvnw compile` also makes the Java code again (the same bytes). A later feature with product code in `src/main/java` can keep this mechanism.
- Mark "generated, do not change": Java: the annotation `@Generated` in each file (the generator writes it, and `generate.sh` stops if a file has none) and a `README.md` in `backend/src/generated` that `generate.sh` writes after the generation. TypeScript: the banner of Kubb in each file (no version and no time; `generate.sh` stops if a file has none) and a `README.md` in `frontend/src/generated`. The agent set `barrel: false` for the two Kubb plugins, because a barrel file `index.ts` has no banner. The `README.md` texts are in `generate.sh` (one place), and the gate for generated code (phase 130) sees them as part of the generated folder, because `generate.sh` writes them each time.
- Marker of the generator: `.openapi-generator/openapi.yaml-spring-interfaces.sha256` (the hash of the OpenAPI file) is the only marker file (the generator writes no `FILES`, `VERSION` or ignore file with `generateSupportingFiles=false`). It is committed to git and not removed, so a `./mvnw compile` after `just generate` leaves the tree clean (the marker has the same bytes), and the file shows which OpenAPI file the code is from. It is the same in each run.
- Options of the Spring generator: the four fixed options stay (`interfaceOnly`, `skipDefaultInterface`, `hideGenerationTimestamp` and the plugin option `generateSupportingFiles=false`). The agent added: `annotationLibrary=none`, `documentationProvider=none` and `openApiNullable=false` (the phase 100 showed that the generated code compiles without `swagger-annotations-jakarta` and `jackson-databind-nullable`, so the module has five libraries and 12 components in the SBOM, and not the 16 of the default options of the phase 100), `useSpringBoot3=true` (the default, written out), `generateJsonIncludeAnnotations=false` and `generateJsonSetterNullsAnnotations=false` (the defaults of 7.27.0, written out, because the generator writes a warning if they are not set), `sourceFolder=java`, `apiPackage` `biz.dfch.specmgrdemo.api`, `modelPackage` `biz.dfch.specmgrdemo.model`, and the plugin options `generateApiTests`, `generateModelTests`, `generateApiDocumentation` and `generateModelDocumentation` set to `false` (only the interfaces and the model are code). The group name of the packages is the `groupId` of the module.
- Libraries and versions: `spring-web` and `spring-context` 6.2.19, `jakarta.validation-api` 3.0.2, `jackson-annotations` 2.21 and `tomcat-annotations-api` 10.1.61, each with its version in a property of the `pom.xml` and with no BOM. The agent did not manage the transitive versions: Maven gives the Spring modules 6.2.19 and Micrometer 1.15.12 (the same tree as the test of the phase 100, 12 components, `mvn dependency:tree` has no `jakarta.annotation-api`).
- Executions: `spring-interfaces` is bound to `generate-sources`; `api-docs` has the phase `none` and is started with the goal `generate@api-docs` (the recipe `api-docs`). The output is `build/api-docs/index.html` (the folder `/build/` is in `.gitignore`). The option `hideGenerationTimestamp` is set for `html2` too, although `html2` has no time stamp (finding G1).
- Recipes and numbers: the recipes are `generate`, `compile`, `api-docs` and `test-generate-gate`. The gate numbers are `120.120` (and `120.130` for `api-docs`). The agent added the recipe `compile` (`tools/gates/compile.sh`): the quality gate of the phase needs a compile through a recipe, and the task 130.105 adds only the CI job. The name `api-docs` will be the name of the CI job. The scripts are in `tools/gates/`, and the helper programs of the test are in `tools/generate/`.
- Pins: `OPENAPI_GENERATOR_MAVEN_PLUGIN_VERSION` and `OPENAPI_GENERATOR_MAVEN_PLUGIN_SHA256` are in `versions.env`. The version has a second place (`backend/pom.xml`, checked by `check_pins.py`). The sha256 has no second place in a file: `verify_generator_plugin` compares it with the jar at run time, as `sbom.sh` does for `cyclonedx-maven-plugin`, and the tests of this are in `selftest.sh` (a stub) and in `test-generate-gate.sh` (the real plugin). For `frontend/`, each of the six direct packages has a version key and an integrity key (`kubb` and `@kubb/core` have the version key `KUBB_VERSION`), which gives `check_pins.py` three places for each package (`versions.env`, `package.json` and the lock file). `check_frontend` is stricter than needed for the next features on purpose (the keys of `package.json` and the files of the folder are a list), so a later feature that changes `frontend/` must change this check and its tests.
- Kubb: `@kubb/core` is a direct dependency (the runner imports it, and pnpm does not let it import a package that only `kubb` has), `kubb` is necessary for `kubb/config`, and `@kubb/plugin-ts` is used (it makes the types in `src/generated/types`). The imports of the generated files have no file extension, and `tsconfig.json` has `moduleResolution` `Bundler` and `lib` `DOM`. The recipe and the script set `KUBB_DISABLE_TELEMETRY=1` and `DO_NOT_TRACK=1`, as the owner accepted.
- The test of ACC-008: the Java side is a program for the source launcher of the JDK (`java -cp backend/target/classes tools/generate/ErrorCodes.java`) that uses `getValue()`, the Zod side is a Node program with a small hook for imports with no extension, and the comparison is `error_codes.py`. The agent chose this to add no library (no JUnit, no `dependency:build-classpath`, no TypeScript runner). The test needs JDK 21, Node, pnpm, `uv` and the network. It is part of `just test-gates`, so the job `test-gates` of CI needs `actions/setup-java` in the task 130.110. The test defines ACC-013 as the same files after three runs (see "Result of the Phase 120").
- GitHub issue #23: the agent posted one comment (the pin of the plugin jar only, the dependencies of the Maven plugins are not checked, the issue stays open). `gh auth status` was OK for `dfch`, and the repository is `dfch/biz.dfch.SpecMgrDemo`. The agent did not push.
- Not done on purpose: the CI jobs and `tools/gates/required-setup.txt` (phase 130), the gate for generated code (task 130.100), and a change of `tools/license/` or of a DEC.

#### 2026-11-05 01:04:20.000Z - Phase 115: points that the agent set (the owner can change them at the review)

- Folder and names: the files of the gate are in `tools/breaking/` (as `tools/lint/` is for the linter), and the recipes are `breaking-changes` (the name of the CI job in phase 130, REQ-013) and `test-breaking-changes-gate` (as `test-lint-gate`). The gate numbers are `115.110` and `115.130`. The folder has no pnpm project, so the rule of `check_pins.py` for extra files in the folders of the pnpm tools does not apply to it. CODEOWNERS already covers `tools/breaking/` with `/tools/`, so `.github/CODEOWNERS` is not changed.
- Pin: the keys are `OASDIFF_VERSION` and `OASDIFF_SHA256` in `tools/versions.env` (as `JUST_SHA256`). The pin is for Linux x86_64 only, because the install scripts for just and Node do the same, and the runners and the machine of the author are Linux x86_64. The install stops on another platform. The install location is `build/tools/oasdiff-<version>/` (gitignored). `install_oasdiff` takes the URL from `OASDIFF_URL` and the folder from `OASDIFF_HOME` for the tests, and the sha256 of the pin applies to each URL.
- Second place of the pin: `tools/breaking/oasdiff-checksums.txt` is the file `checksums.txt` of the release, without a change. The owner chose "a sha256 value in `tools/versions.env`", and a pin in one place alone cannot make `just check-pins` stop for a changed version (ACC-011), because a changed version with its own checksum has no other place to disagree with. The vendor file is the second place, and the procedure to change the version is in `tools/breaking/README.md`. If the owner does not want this file, the check of `check_pins.py` can only check the form of the two values, and a changed version stops at the install in the gate and not in `check-pins`.
- Format of an entry (rule 4 of the DEC): one line, four items separated by ` | `: `<METHOD> <path> <the change as oasdiff names it> | <cause> | #<issue or pull request> | <release>`. The gate gives oasdiff only item 1 (see finding P1). The release is a Semantic Versioning 2.0.0 version.
- Rule 5 of the DEC: the check is "higher by the order of SemVer 2.0.0", and in addition: if the first number of the base is 0, the pair (first number, second number) is higher, and if not, the first number is higher. The text of the DEC says "the second number must go up" for a 0 version. The agent reads this as the pair, so `0.1.0` to `1.0.0` passes. This is stricter than "a higher version": `0.1.0` to `0.1.1` fails. The gate checks the version only if an entry is used.
- Entry that matches no change (rule 6): a WARNING and no failure. The DEC says only that the owner removes it. The cause: after the release, the entry matches nothing in each next pull request, and a failure would stop the pull requests of other authors. The DEC update entry says this.
- Other: the ignore file is read from the pull request (the revision), the gate stops if the pull request deletes the OpenAPI file (the merge base has it), the gate does not read the ignore file when the base has no OpenAPI file, and the gate uses PyYAML (`make_python_env pyyaml`) to read `info.version`, so the CI job needs `uv`. The comparison of the version numbers is in `breaking_changes.py` (the subcommands `semver` and `rule`), and the test has tables for it.
- Not done on purpose: the CI job and the line in `tools/gates/required-setup.txt` (phase 130), and a change of the status of DEC 93594b2b-be54-4f60-9f53-ec2ce6c84be4 (the owner, task 140.110).

#### 2026-11-04 19:05:00.000Z - Phase 110: points that the agent set (the owner can change them at the review)

- Folders: `tools/spectral/` is the pnpm project of Spectral (the lock file, `package.json` and `README.md` only, as `tools/sbom/` is for cdxgen, so a ruleset in this folder would stop `just check-pins`). The rules and the fixtures are in `tools/lint/`. Both folders are below `tools/`, so CODEOWNERS covers them.
- Pin: the keys in `tools/versions.env` are `SPECTRAL_VERSION` and `SPECTRAL_INTEGRITY` (as `CDXGEN_VERSION` and `CDXGEN_INTEGRITY`). The pin check of cdxgen is now one function (`check_pnpm_tool`) with the data for cdxgen and for Spectral, so both checks have the same rules. The messages of Spectral start with `Lint tool:`.
- Gate numbers: the number after the script name in the `justfile` is the number of the task that wrote the gate. The gates of feat-5 keep `130.xxx`. `lint` and `test-lint-gate` have `110.115`, the task of this feature. The message "NOT IMPLEMENTED" of `_gate` no longer names feat-5.
- Lint gate: `just lint` runs `tools/gates/lint.sh contracts/openapi.yaml tools/lint/ruleset.yaml`. The gate installs Spectral with `pnpm install --frozen-lockfile --ignore-scripts`, compares the installed version with `SPECTRAL_VERSION`, and starts Spectral with `--fail-severity warn`, so a warning is a failure too. The group `spectral:oas` (recommended) is part of the rules, with `info-contact`, `openapi-tags`, `operation-tags` and `tag-description` off (they need a decision about the organization). The file has `servers: [{url: /}]` for the rule `oas3-api-servers`.
- Rules that the agent added to the tested start: the rule that a response `4XX`, `5XX` and `default` follows the same rule as `4xx` and `5xx` (a `default` response is an error response too), a response with no content fails, `Problem` has exactly the seven members (no `message`, no other text member), `code` and `traceId` have a rule each, the schemas `Problem` and `ErrorCode` must exist, `x-specmgr-req` has two rules (a missing or empty value, and the form of a UUID) for each HTTP method, the values of `ErrorCode` have the pattern `^[a-z][a-z0-9_]*$` (no hyphen), and `info.version` is a Semantic Versioning 2.0.0 version (DEC 93594b2b-be54-4f60-9f53-ec2ce6c84be4 says this, and the phase 115 needs it).
- Tests: the real Spectral tests each rule with the fixtures in `tools/lint/fixtures/`. A fixture must fail with exactly the rules of its line in `expected.txt`. The test is the recipe `test-lint-gate`, and `test-gates` starts it (as it starts `test-license-gate`). The cases of the script (a missing file, a lock file that does not fit, another version) are in the same test. `selftest.sh` has the cases of the pin check and of `sbom.sh` for Spectral.
- Values of the OpenAPI file: `info.version` 0.1.0, the responses 429, 500 and 503 for `GET /status`, the schema `Status` with `state` (`up` or `degraded`) and `checkedAt`, and `traceId` with the pattern of 32 lower case hexadecimal characters (the form of the trace identifier of OpenTelemetry). `title` and `detail` stay in `Problem` as the fixed values say, with a note that they are for logs and developers (finding L3, the owner decides).
- The REQ: the level MUST, the priority 50, the tag `iso29148:syrs`, the characteristics Functional Suitability and Reliability. The agent made only the REQ (the task 110.105). The VCR and the entry in a SYSRS (steps 4 and 5 of the SOP) stay open.
- The agent did not change the CI workflow and `tools/gates/required-setup.txt` (the plan puts them in the phase 130). `check-workflows` has no test that every recipe has a job, so it passes. The note about the CI job `test-gates` is in the task 130.110.

#### 2026-11-04 18:40:00.000Z - Phase 105: points that the agent set (the owner can change them at the review)

- Values of the `pom.xml`: group `biz.dfch.specmgrdemo`, artifact `backend`, version `0.0.0-SNAPSHOT`, packaging `jar`. The cause: no document names a Maven group. The group is the lower case form of the repository name. A `jar` can compile the generated sources of the phase 120 (a `pom` packaging cannot), and an empty jar is not a problem for the phase 105.
- The wrapper has no `mvnw.cmd`. The task names `mvnw` and the properties file only, the project has no Windows build, and the recipes need `bash`.
- Fix of the first real run (finding P1): the real `cyclonedx-maven-plugin` writes no `components` key for a project with no dependency, and the license gate stops for an SBOM with no `components` list. The agent did not make the license gate accept such a file, because the rule is on purpose (fixture 46 tests it) and the fail-closed behavior protects against a file that is not complete. The agent changed `sbom_check.py` (it compares the manifests with the SBOM) to write `"components": []` to the copy in `build/sbom/`. This is only for Maven, only if no manifest declares a dependency. With a declared dependency, the script stops. If the owner prefers a change of `license_check.py` (a missing key is the same as an empty list), this is a change of a rule of the license gate, and `tools/` has a CODEOWNERS review.
- The limit about `unzip` is only written in `tools/gates/README.md`. The wrapper fails closed, so no change of the gates was necessary.

#### 2026-11-04 18:20:00.000Z - The owner decides finding F1: `tomcat-annotations-api` in place of `jakarta.annotation-api`

The owner decided on 2026-11-04 to use alternative (c) of finding F1: the generated Java code gets `jakarta.annotation.Generated` from `org.apache.tomcat:tomcat-annotations-api` 10.1.61 and not from `jakarta.annotation-api`. The cause: the license of `tomcat-annotations-api` is Apache-2.0, which is in the class Permitted, so the license check needs no change of DEC 84c37f7d-08cb-457d-8ab3-1db37dba9bc9 and no change of the gate in `tools/license/` (the gate says PASS for it). Alternatives (a) (a rule for OR licenses and a change of the gate) and (b) (a DEC about the deviation for EPL-2.0) are not used. The result Review for `jakarta.annotation-api` is closed, because the project does not use that library. Consequences for the phase 120: the `pom.xml` names the version 10.1.61 (the Spring Boot BOM 3.5.16 has 10.1.55), no dependency brings `jakarta.annotation-api` in again, and the SBOM has no `jakarta.annotation-api` (note in the task 120.100).

#### 2026-11-04 16:55:00.000Z - Result of the license checks: `jakarta.annotation-api` gets Review (task 100.120)

The agent gave the result Review to `jakarta.annotation-api` and not Permitted. The reasons: the library has two licenses (EPL-2.0 is the class Review, and GPL-2.0-only WITH Classpath-exception-2.0 is the class Permitted), the POM has two license entries that the SBOM gate reads as AND, and the gate stops for it. The selection of the license of an OR pair is a decision of the owner, so the agent did not select it. The agent did not add a license class to the DEC (task 100.110), did not change `tools/license/` and did not add a library to a `pom.xml`. The alternatives for the owner are (a) to state the OR rule and change the gate, (b) a DEC about the deviation for EPL-2.0 and (c) `tomcat-annotations-api` in place of the library (see finding F1). The task 100.120 stays open until the owner decides. The other items have the result Permitted, and the rule A of the DEC (main license for a tool) applied to the tools in `tools/` and to the Maven plugins.

#### 2026-11-04 16:42:00.000Z - The owner adds the API documentation (REQ-015)

The owner chose option (b) for the documentation of the API: CI makes it from the OpenAPI file with the generator `html2` of the openapi-generator plugin, as a second execution of the plugin that is already pinned. So it needs no new tool and no new pin. The output must be the same on each run (REQ-015). The HTML is not committed, and CI keeps it as an artifact. The documentation is not in the gate for generated code, because it is an artifact and not a committed file. The plan has the new REQ-015, ACC-018, one bullet in Scope/Included and the new Task 120.130 (a new number, no task is renumbered). The license table has a note in the row of openapi-generator. The job for the documentation is added with the CI jobs of the phase 130 (task 130.110).

#### 2026-11-04 16:41:00.000Z - Fixed values of the task 090.120

The owner fixed these values on 2026-11-04. The paragraph "Fixed values" in the Design Notes has the same list.

- OpenAPI file: `contracts/openapi.yaml`, version 3.1.0. Spectral, oasdiff and Kubb read 3.1. The support of openapi-generator for 3.1 is beta, and the tool writes a warning in the log. The owner accepted this.
- Generated Java code: `backend/src/generated`. The Maven module adds it as a source root (`build-helper-maven-plugin` or the plugin option `addCompileSourceRoot`). The exact mechanism is open for the phase 120.
- Generated Zod code: `frontend/src/generated`. Both generated folders are committed to git.
- Mark "generated, do not change": the banner of Kubb (default) for the Zod code. A `README.md` or a header in the folder for the Java code. The way and the details are open for the phase 120.
- Options of the Spring generator: `interfaceOnly=true`, `hideGenerationTimestamp=true`, `skipDefaultInterface=true`, `generateSupportingFiles=false`.
- ErrorCode design rule (from the research): one shared schema `ErrorCode` (string enum, lower snake case, unique values) that `Problem.code` uses with `$ref`. The schema `Problem` has `type`, `title`, `status`, `detail`, `instance`, `code` and `traceId`, and `code` and `traceId` are required. Each response 4xx and 5xx has the one media type `application/problem+json` with `$ref` to `#/components/schemas/Problem` (or to a shared `components/responses/ProblemResponse`). The test for ACC-008 compares the YAML list with the Java enum by `getValue()` (not by the names of the constants, which get number suffixes if names clash) and with the Zod export `errorCodeSchema.options`. The details are in the Design Notes.
- Set by the agent, and the owner can change it at the review: the recipe `generate` starts Kubb with a small programmatic runner (a `.mjs` file in `frontend/`) and not with the command `kubb generate`. The cause: the command makes one network call at each start (see the entry of 16:40), and the programmatic API makes none and gives the same output. The recipe also sets `KUBB_DISABLE_TELEMETRY=1` and `DO_NOT_TRACK=1`. The workflow gate does not allow `env:`, so the recipe sets them, and the owner accepted this.

#### 2026-11-04 16:40:00.000Z - The owner selects the four tools (task 090.110)

The owner selected these tools on 2026-11-04. The agent did not select a tool (REQ-014).

- Linter: Spectral (CLI 6.17.0, Apache-2.0). Cause: the rules for `x-specmgr-req` and for Problem Details are plain YAML and work on a 3.1 file. It is pinned with a pnpm lock file, as cdxgen is. Redocly CLI is not selected as linter.
- Breaking changes: oasdiff 1.35.0 (Apache-2.0), a download with a sha256 value in `tools/versions.env`. Cause: it is the only candidate with an ignore file for each change (REQ-012).
- Server generator: openapi-generator 7.27.0, Maven plugin (Apache-2.0), generator `spring`.
- Zod generator: Kubb. The owner selected Kubb after the agent compared it with Hey API and Orval and the owner challenged the choice. Packages: `kubb`, `@kubb/plugin-zod`, `@kubb/plugin-ts` and `zod` 4.x in the pnpm module `frontend/`. `kubb`, `@kubb/plugin-zod` and `@kubb/plugin-ts` get exact versions that work together. The agent checked the npm registry on 2026-11-04: `kubb` and `@kubb/cli` 5.15.3, `@kubb/plugin-zod` 5.8.0, `@kubb/plugin-ts` 5.4.0 (and `zod` 4.6.7). Hey API 0.99.0 is the documented fallback.
- Facts of the comparison that the owner recorded: the command `kubb generate` makes one anonymous GET request to `registry.npmjs.org/@kubb/cli/latest` at each start. This cannot be switched off. In 5.x it does not block, it has a time-out of 3 seconds, and the exit code is 0 and the result is the same with no network. If packets are dropped, the start has a delay of up to about 10.6 seconds. The telemetry of Kubb (a POST request to `otlp.kubb.dev`) is switched off by `KUBB_DISABLE_TELEMETRY=1` or `DO_NOT_TRACK=1` (only the value `1` or `true`). The programmatic API (`createKubb` from `@kubb/core`, config from `kubb/config`) makes no network call, sends no telemetry and gives byte-identical output.
- Licenses: the owner chose `argparse` 3.0.4 (PSF-2.0, Permitted by DEC 84c37f7d-08cb-457d-8ab3-1db37dba9bc9). The tree of Kubb has `argparse@3.0.4`, so no pnpm override is necessary for Kubb. If the generator changes to Hey API, use the pnpm override `argparse` 3.0.4. The DEC is not changed for `Python-2.0`.
- Behavior of oasdiff for the phase 115 (tested with 1.35.0): a new enum value in a property of a RESPONSE is an error (a breaking change, exit code 1 with `--fail-on ERR`). The removal of a value is only info. Each status (400, 404, 500, 503) gives its own finding, so the ignore file needs one line for each status. The format is `METHOD /path <full message>`. The owner keeps the default levels, so a removal is not a breaking change.
- Rules of the linter: a tested ruleset is in `/tmp/opencode/r/spectral/ruleset.yaml`. It is the start for the task 110.115. The rule for `x-specmgr-req` needs a `truthy` check and a UUID `pattern` check, and the rules that check a `$ref` need `resolved: false`.
- The license table keeps the results "not checked" and "open" until the phase 100.

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
