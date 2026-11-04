---
classification: null
created: '2026-11-03T07:53:51.955+01:00'
id: feat-6-contracts-openapi-pipeline
status: progress
type: feat
updated: '2026-11-04T17:56:19.181+01:00'
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

- REQ-006: Errors must use RFC 9457 Problem Details. Each response with a status 4xx or 5xx must use the media type `application/problem+json` and one schema. The schema has a `code` from one list in the OpenAPI file and the trace identifier (DEC e3eadec0-a6ea-4efe-8e6d-fd19287122fa). The schema has no text in a language (DEC 51b00b5f-d1d8-49d8-9f40-28537ff69698). The generators make the list of codes for Java and for TypeScript from the same file, so the codes are the same in all languages. A lint rule stops a response that does not obey this.

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

- [x] ACC-017: The phase 090 has a list of candidates for each tool, with the criteria, and the owner selected each tool. The decision is in the section Decisions Made (REQ-014).

- [ ] ACC-018: CI makes the API documentation from the OpenAPI file with the generator `html2` of the openapi-generator plugin that is already pinned (no new tool). Two runs one after the other make the same HTML. The HTML is not in git, and CI keeps it as an artifact. The gate for generated code does not check it (REQ-015).

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
| Spectral CLI 6.17.0 (`@stoplight/spectral-cli`) | linter | Apache-2.0 | Permitted |
| oasdiff 1.35.0 | breaking changes | Apache-2.0 | Permitted |
| openapi-generator 7.27.0 and its Maven plugin (`openapi-generator-maven-plugin`) | server interfaces (generator `spring`) and API documentation (generator `html2`, the same plugin, no new tool) | Apache-2.0 | Permitted |
| Kubb (`kubb` 5.15.3, `@kubb/plugin-zod` 5.8.0, `@kubb/plugin-ts` 5.4.0) | client schemas | MIT (all three packages) | Permitted |
| Zod 4.6.7 | runtime library | MIT | Permitted |
| `argparse` 3.0.4 (in the tree of Kubb, through `js-yaml` 5.5.0) | library in the tree of the Zod generator. The owner stated on 2026-11-04 that its license PSF-2.0 is Permitted by DEC 84c37f7d-08cb-457d-8ab3-1db37dba9bc9. The phase 100 read the license file. | PSF-2.0 | Permitted |
| TypeScript 5.9.3 (the version that was tested) | compiler for ACC-005 | Apache-2.0 | Permitted |
| Spring Web: `spring-web` and `spring-context` 6.2.19, with their seven dependencies (`spring-beans`, `spring-core`, `spring-jcl`, `spring-aop`, `spring-expression`, `micrometer-observation`, `micrometer-commons`) | libraries that the generated Java code needs | Apache-2.0 (`spring-core` also has BSD-3-Clause code of ASM, and Apache-2.0 code of CGLIB, JavaPoet and Objenesis) | Permitted |
| `jakarta.validation-api` 3.0.2 (Jakarta Bean Validation, API only) | library that the generated Java code needs | Apache-2.0 | Permitted |
| `jackson-annotations` 2.21 | library that the generated Java code needs | Apache-2.0 | Permitted |
| `swagger-annotations-jakarta` 2.2.55 and `jackson-databind-nullable` 0.2.13 | libraries that the generated Java code needs only with the default options of the generator (the options `annotationLibrary=none`, `documentationProvider=none` and `openApiNullable=false` remove them) | Apache-2.0 (both) | Permitted |
| `jakarta.annotation-api` 2.1.1 (and 3.0.0) | library that the generated Java code needs with each option (`import jakarta.annotation.Generated` is in each template) | EPL-2.0 OR GPL-2.0-only WITH Classpath-exception-2.0 (see the finding F1 below) | Review (open question for the owner) |
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
| `jakarta.annotation-api` 2.1.1 | two entries: "EPL 2.0" and "GPL2 w/ CPE" | `META-INF/LICENSE.md` (EPL-2.0 text and GPL-2.0 text with the Classpath Exception) and `META-INF/NOTICE.md` | `5f65fdaf424eee2b55e1d882ba9bb376be93fb09b37b808be6e22e8851c909fe` |
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

- F1, `jakarta.annotation-api` (result Review, open question for the owner). The file `META-INF/NOTICE.md` of the jar says `SPDX-License-Identifier: EPL-2.0 OR GPL-2.0 WITH Classpath-exception-2.0` (sha256 of the file `3852834ebb4c2e04ecc18c9d099a05eab72cbd6edf35fb191390be6306019b4c`). The version 3.0.0 (jar sha256 `b01f55552284cfb149411e64eabca75e942d26d2e1786b32914250e4330afaa2`) has the same two entries in its POM and the line `SPDX-License-Identifier: EPL-2.0 OR GPL-2.0-only with Classpath-exception-2.0` in its notice, so the user selects one of the two licenses. In the DEC, `GPL-2.0-only WITH Classpath-exception-2.0` is Permitted and `EPL-2.0` is Review. The agent gives the result Review, and not Permitted, for these reasons: the POM has two `<license>` entries, so the SBOM has two entries, and the gate reads more than one entry as AND (README of `tools/license/`). The gate stops for this library, as the test above shows. The agent cannot change the DEC or `tools/license/`, and the selection of one license of an OR pair is not a rule of the DEC. The generator cannot avoid the library: the templates `model.mustache` and `api.mustache` of the generator `spring` have `import {{javaxPackage}}.annotation.Generated;` for each option. The alternatives for the owner (the agent does not select one):
  - (a) The owner states that an OR license is Permitted when one alternative is Permitted, and a change in `tools/license/` (owner review by CODEOWNERS) lets the gate read this library as `EPL-2.0 OR GPL-2.0-only WITH Classpath-exception-2.0`. The agent made no such change.
  - (b) The owner makes a DEC about the deviation for `EPL-2.0` (class Review). The gate must still be changed for the identifier `GPL-2.0-with-classpath-exception`.
  - (c) The project uses `org.apache.tomcat:tomcat-annotations-api` (Apache-2.0, POM and `META-INF/LICENSE` of the jar; jar sha256 `8d408d675d89da99f86171ead3067f9e947accf722e3785e6775e9af387ff3a6`, the sha1 is the one on Maven Central) in place of `jakarta.annotation-api`. The jar has the class `jakarta.annotation.Generated`. The test above shows that the generated code compiles with it and that the gate says PASS. The agent did not test this: a Spring Boot starter in a later feature can bring `jakarta.annotation-api` again.
  - Until the owner decides: no `pom.xml` in the repository has `jakarta.annotation-api` or `tomcat-annotations-api`. The phases 105 and 110 do not need a Java library. The task 120.100 is blocked for this library.
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

**Behavior of oasdiff for the phase 115 (tested with 1.35.0)**

- A new enum value in a property of a RESPONSE is an `error` (a breaking change): the exit code is 1 with `--fail-on ERR`. The removal of a value is only `info`. The agent also tested a file of custom levels (`--severity-levels`, with the line `response-property-enum-value-removed err`) that makes a removal an error. The owner keeps the default levels, so a removal is not a breaking change.
- Each status (400, 404, 500, 503) gives its own finding. The ignore file needs one line for each status.
- The format of a line in the ignore file is `METHOD /path <full message>`. The option `-f singleline` prints the findings with one line for each finding, so a person can copy the message to the ignore file.

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

- [ ] Task 100.120: If a tool or library has the result Review, tell the owner and wait for a decision. Do not use the item before the decision (ACC-006)

#### Phase 105: Maven Wrapper and the Shell of the Backend Module

- [ ] Task 105.100: Make `backend/pom.xml` with no dependencies. Add the Maven Wrapper without a jar (`backend/mvnw` and `backend/.mvn/wrapper/maven-wrapper.properties`) for the Maven version of `tools/versions.env`. Verify the `distributionSha256Sum` with the `.sha512` of Apache and `tools/gates/README.md`, and not only with the value in the properties file (ACC-010)

- [ ] Task 105.110: Set the git mode of `backend/mvnw` to 100755. Run `just check-pins`, `just sbom` and `just license-check` with the real `pom.xml`, and write the result in this plan. Change the section "Limits" of `tools/gates/README.md` for the first real run (ACC-010)

#### Phase 110: OpenAPI Source and Lint

- [ ] Task 110.100: Write the OpenAPI file with the operation `GET /status`, the Problem Details schema (the `code` list, the trace identifier, no text of a language), the response 4xx and 5xx with `application/problem+json`, and the extension `x-specmgr-req` (ACC-001, ACC-009)

- [ ] Task 110.105: Make the first REQ document with specmgr for the operation `GET /status` (this makes the folder `docs/req/`). The document has the status draft. Put its UUID in the extension. Write a README in `contracts/` (ACC-001, ACC-009)

- [ ] Task 110.110: Add the selected linter: pin it (`tools/versions.env`, own pnpm project with a lock file under `tools/`), change `sbom.sh`, `check_pins.py` and their tests for the new manifest, and add it to the license table (ACC-011)

- [ ] Task 110.115: Write the rules of the linter (REQ-006 and REQ-008) in a path below `tools/`, add the `just` recipe `lint`, and add the negative cases of ACC-007. The start is the tested ruleset in `/tmp/opencode/r/spectral/ruleset.yaml` (see the Design Notes, "Rules of the linter") (ACC-002, ACC-007)

#### Phase 115: Check for Breaking Changes

- [ ] Task 115.100: Add the selected tool for breaking changes as a download with a sha256 value in `tools/versions.env`. Add the install in the recipe. Change `check_pins.py` and its tests for the new pin (ACC-011)

- [ ] Task 115.110: Write the recipe for the check. It uses `{{ base }}` and the merge base of `git merge-base`. It goes on if the base has no OpenAPI file (ACC-002, ACC-003)

- [ ] Task 115.120: Make the ignore file below `tools/` and the check of the version number (REQ-012). Add an update entry to DEC 93594b2b-be54-4f60-9f53-ec2ce6c84be4 with the format of an entry and the check. The status of the DEC is not changed by the agent (ACC-003, ACC-014)

- [ ] Task 115.130: Add the four cases of ACC-003 to `just test-gates` (ACC-003)

#### Phase 120: Generators

- [ ] Task 120.100: Add the generation of the Spring server interfaces to the Maven module, with the dependencies that the generated code needs and the options of the task 090.120 (ACC-005, ACC-013)

- [ ] Task 120.105: Add the sha256 of the jar of the generator plugin to `tools/versions.env`, and the comparison to a gate, as `sbom.sh` does for its plugin. Write the limit about the dependencies of the plugin in `tools/gates/README.md` and in a comment in GitHub issue #23 (ACC-012)

- [ ] Task 120.110: Make the pnpm module in `frontend/` (`pnpm-workspace.yaml`, lock file) and the generation of the Zod schemas with Kubb. Pin `kubb`, `@kubb/plugin-zod` and `@kubb/plugin-ts` at exact versions that work together. Use the programmatic runner and not the command `kubb generate` (see the Design Notes). Install with `--frozen-lockfile --ignore-scripts` (ACC-005, ACC-011)

- [ ] Task 120.120: Write the `just` recipe `generate` that makes all generated code again, and the test for ACC-008 and ACC-013 (ACC-002, ACC-008, ACC-013)

- [ ] Task 120.130: Add the API documentation (REQ-015): a second execution of the plugin `openapi-generator-maven-plugin` that is already pinned, with the generator `html2`, and a `just` recipe for it. The output is below a folder that is not in git, and it is not in the gate for generated code. Test that two runs one after the other make the same HTML (check the options, for example the time stamp). The CI job that keeps the HTML as an artifact is added with the CI jobs of the phase 130. If this job is a required check, it is a question for the owner in the phase 135 (ACC-018)

#### Phase 130: Gates

- [ ] Task 130.100: Write the gate that compares the generated code with the code in the repository. It also finds deleted, extra and untracked files (`git status --porcelain` and not only `git diff`) (ACC-004)

- [ ] Task 130.105: Add the CI job that compiles the Maven module and the pnpm module with the generated code (ACC-005)

- [ ] Task 130.110: Add the lint gate, the gate for breaking changes, the gate for generated code, the compile job and the job for the API documentation (REQ-015) to the CI workflow and to `tools/gates/required-setup.txt`. The name of each job is the name of its recipe (ACC-015)

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

**As of 2026-11-04**: The phase 090 (Tool Selection) is done. The tasks 090.100, 090.110 and 090.120 are done, and ACC-017 is met. The owner selected Spectral 6.17.0, oasdiff 1.35.0, openapi-generator 7.27.0 and Kubb, and fixed the path, the version (OpenAPI 3.1.0), the folders and the options (see the section Decisions Made and the Design Notes). The owner also added the API documentation (REQ-015, ACC-018, task 120.130). feat-5-foundation-monorepo-ci is done, so the dependency is satisfied.

**As of 2026-11-04 (phase 100)**: The tasks 100.100 and 100.110 are done. The agent read the license file of each item and filled the license table. All items have the result Permitted, except one: `jakarta.annotation-api` has the result Review (an open question for the owner, finding F1 in "License Checks (Tasks 100.100 and 100.110)"). The task 100.120 is not done, because it waits for the decision of the owner. ACC-006 is not met until then. The phase 105 and the phase 110 need no Java library, so the Review does not block them. It blocks the task 120.100. The next step is the decision of the owner for F1.

### Blockers

- Open question for the owner (task 100.120, ACC-006): the library `jakarta.annotation-api` (the generated Java code imports `jakarta.annotation.Generated` with each option) has two licenses (`EPL-2.0 OR GPL-2.0-only WITH Classpath-exception-2.0`). The result is Review. The license gate stops for it (`NOT KNOWN`), and the agent must not change the DEC or `tools/license/`. The owner selects the alternative (a), (b) or (c) of finding F1 in "License Checks (Tasks 100.100 and 100.110)". No `pom.xml` in the repository may have this library before the decision. The task 120.100 is blocked for it.
- One point is set by the agent and the owner can change it at the review: the recipe `generate` starts Kubb with a programmatic runner and not with the command `kubb generate`. The details of the mechanism for the source root of the Java code and of the mark "generated, do not change" for the Java code are open for the phase 120.

### Updates

<!-- Newest entry first -- prepend new entries directly below this comment. -->

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
