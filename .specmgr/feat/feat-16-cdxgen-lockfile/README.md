---
classification: null
created: '2026-11-03T21:02:30.390+01:00'
id: feat-16-cdxgen-lockfile
status: planning
type: feat
updated: '2026-11-03T21:35:00.923+01:00'
version: 1.0.0
---

# Feature: Lock File for the SBOM Tool cdxgen

## Plan

### Overview

The gate `tools/gates/sbom.sh` makes the SBOM of the frontend with `@cyclonedx/cdxgen` 12.9.0. Today the gate starts `pnpm dlx` after it compares the integrity value of the cdxgen package with `CDXGEN_INTEGRITY` in `tools/versions.env`. This protects the package cdxgen only. The 29 direct dependencies of cdxgen, and their own dependencies, come at run time in the version that npm selects. So the code that makes the SBOM for the license gate is not fully pinned. This is the accepted limit G2 of the review of feat-5-foundation-monorepo-ci. On 2026-11-03 the owner decided to remove this limit now, with a small feature and a GitHub issue.

This feature adds a small pnpm project for cdxgen only, in `tools/sbom/`. It has a `package.json` with one dependency and a `pnpm-lock.yaml` with an integrity value for each package. `sbom.sh` installs from the lock file with `pnpm install --frozen-lockfile --ignore-scripts` and starts cdxgen from that install. `just check-pins` shows that the lock file has the version and the integrity value of `tools/versions.env`. GitHub issue #16 is for this feature. The feature is planned and not started.

### Requirements

- REQ-001: The folder `tools/sbom/` must be a pnpm project for cdxgen only. Its `package.json` must have one dependency, `@cyclonedx/cdxgen`, in the exact version `CDXGEN_VERSION` of `tools/versions.env` (no range). Its `pnpm-lock.yaml` must have a `resolution.integrity` value for each package in it. The project must have a `README.md`.

- REQ-002: `sbom.sh` must start cdxgen only from an install that `pnpm install --frozen-lockfile --ignore-scripts` made in `tools/sbom/`. It must not use `pnpm dlx` or `pnpm view` for cdxgen. It must stop (exit code 1, no SBOM file) if the install fails, for example if the lock file and `package.json` are not the same, or if a package has another integrity value than the lock file.

- REQ-003: The file `tools/versions.env` must stay the one source of truth for the version and the integrity value of cdxgen (`CDXGEN_VERSION`, `CDXGEN_INTEGRITY`). `just check-pins` must stop if the dependency in `tools/sbom/package.json`, the version in the lock file or the integrity value of cdxgen in the lock file is not the value of `tools/versions.env`. It must also stop if `package.json` has another dependency, or if a package in the lock file has no integrity value.

- REQ-004: The check for manifests that the SBOM does not scan (finding E1) must not stop for `tools/sbom/package.json` and `tools/sbom/pnpm-lock.yaml`. It must still stop for each other manifest, also for one in another folder under `tools/` and for another manifest file in `tools/sbom/`. The exclusion must be written in the header of `sbom.sh` and in `tools/gates/README.md`.

- REQ-005: `tools/sbom/README.md` must give the procedure to change the version of cdxgen: the version and the integrity value in `tools/versions.env`, the version in `tools/sbom/package.json`, and a new lock file that the pinned pnpm writes, all in one commit. A change of only one of the three places must stop `just check-pins`.

- REQ-006: The feature must not add a GitHub Action and must not change `.github/CODEOWNERS`. The line `/tools/` must cover `tools/sbom/`. The job `license-check` must run the install with the Node and the pnpm that it has now. The pnpm that writes the lock file must be `PNPM_VERSION` of `tools/versions.env`.

- REQ-007: Under rule A of DEC 84c37f7d-08cb-457d-8ab3-1db37dba9bc9, only the main license of cdxgen (Apache-2.0) is checked, because cdxgen does not go to users. This plan must record this and the licenses of the packages in the lock file, for information.

### Acceptance Criteria

- [x] ACC-001: `tools/sbom/` has `package.json`, `pnpm-lock.yaml` and `README.md`. In a clean copy of the repository, `cd tools/sbom && pnpm install --frozen-lockfile --ignore-scripts` returns exit code 0, and `node_modules/.bin/cdxgen --version` shows 12.9.0 (REQ-001).

- [x] ACC-002: `sbom.sh` has no `pnpm dlx` command and no `pnpm view` command. A run with a test frontend (`SBOM_PROJECT_ROOT` set to a folder with `frontend/package.json` and a lock file) writes `frontend.cdx.json` with the components of the test frontend, and the log shows the install in `tools/sbom/` (REQ-002).

- [x] ACC-003: `sbom.sh` stops with exit code 1 and writes no SBOM file in each of these cases, tested with the real pnpm and by hand: the version in `tools/sbom/package.json` is not the version in the lock file; a package integrity value in the lock file is wrong; the installed cdxgen has another version than `CDXGEN_VERSION`. `just test-gates` has the cases with a stub (REQ-002).

- [x] ACC-004: `just check-pins` returns exit code 0 now. It returns exit code 1 for each of these cases in `just test-gates`: another version in `package.json`; a version range in `package.json`; another dependency in `package.json`; another version of cdxgen in the lock file; another integrity value in the lock file; another `CDXGEN_VERSION` or `CDXGEN_INTEGRITY` in `versions.env`; a package without an integrity value in the lock file; no `tools/sbom/package.json` and no lock file (REQ-003, REQ-005).

- [x] ACC-005: `just test-gates` has these E1 cases. Positive: `tools/sbom/package.json` and `tools/sbom/pnpm-lock.yaml` with a `frontend/package.json` do not stop `sbom.sh`. Negative (exit code 1 with the path of the file): `tools/other/package.json`, `tools/sbom/pnpm-workspace.yaml`, `tools/sbom/sub/package.json` and a `package.json` in the root (REQ-004).

- [x] ACC-006: The procedure in `tools/sbom/README.md` ran once in a copy of the repository (delete the lock file, `pnpm install --lockfile-only`, then the three places have the same version and integrity value), and `just check-pins` returns exit code 0 after it (REQ-005).

- [x] ACC-007: `.github/CODEOWNERS` and `tools/gates/required-setup.txt` are not changed, and the line `/tools/` of CODEOWNERS covers the new files. `just check-workflows` and `just check-pins` return exit code 0 (REQ-006).

- [ ] ACC-008: These recipes return exit code 0 on the branch: `just test-gates`, `just test-license-gate`, `just check-pins`, `just check-workflows`, `just check-sudo`, `just validate`, `just commit-check`, `just license-check`, and `just --fmt --unstable --check`. The pull request has all seven checks green.

- [ ] ACC-009: A throwaway test pull request (closed, not merged) that adds `frontend/package.json` and `frontend/pnpm-lock.yaml` shows in the log of the job `license-check` the install in `tools/sbom/` with `--frozen-lockfile --ignore-scripts` and the SBOM file, and the job passes (REQ-002, REQ-006).

### Scope

#### Included

- The project `tools/sbom/` with `package.json`, `pnpm-lock.yaml` and `README.md`.

- The change of `tools/gates/sbom.sh`: install from the lock file and start cdxgen from it.

- The exclusion of the two files of `tools/sbom/` in the E1 check (`manifest_files` in `tools/gates/_lib.sh`).

- The check of the lock file against `tools/versions.env` in `tools/gates/check_pins.py`.

- The tests in `tools/gates/selftest.sh`, the entry `node_modules/` in `.gitignore`, and the text in `tools/versions.env`, `tools/README.md` and `tools/gates/README.md`.

- The record of the license facts and of the decisions in this plan.

#### Explicitly Out Of Scope

- The Python tools of the gates (specmgr, PyYAML) and the dependencies of `cyclonedx-maven-plugin`. They have the same limit. The owner can open a separate issue for each of them.

- The traceability gate and the security checks (GitHub issue #8).

- The change of the cdxgen version or the change to the new npm name `@cdxgen/cdxgen` (13.x). The pin stays `@cyclonedx/cdxgen` 12.9.0 (see feat-5).

- The SBOM of `tools/sbom/` itself, and a license check of the packages in its lock file (rule A: cdxgen is a tool that does not go to users).

- The first real SBOM run on `frontend/`. FEAT feat-6-contracts-openapi-pipeline adds `frontend/`.

- An automatic update of the lock file (for example a bot).

### Dependencies

#### Depends On

- FEAT feat-5-foundation-monorepo-ci (done): it has `sbom.sh`, `check_pins.py`, `tools/versions.env` and the CI jobs.

- GitHub issue #16: the issue for this feature.

#### Blocks

- None.

- Related, but not blocked: FEAT feat-6-contracts-openapi-pipeline. It adds `frontend/` and the first real SBOM run, so it is the first user of the new install path of `sbom.sh`.

### Design Notes

**Facts that the agent checked on 2026-11-03** (pnpm 12.16.1 and Node 26.13.0 from `~/.config/biz.dfch.SpecMgrDemo/env.sh`, in a temporary folder, not in the repository):

- `npm view @cyclonedx/cdxgen@12.9.0 dependencies` lists 29 direct dependencies, all with an exact version. The package has 21 `optionalDependencies` (for example `@cdxgen/cdxgen-plugins-bin` and ten platform packages `@cdxgen/cdxgen-plugins-bin-<os>-<cpu>`), `engines` Node `^20 || ^22 || ^24 || ^25 || ^26` and pnpm `>=10`, and the license Apache-2.0. The `bin` entry `cdxgen` is `bin/cdxgen.js`.

- `pnpm install --lockfile-only` with a `package.json` that has `@cyclonedx/cdxgen` 12.9.0 only writes a lock file of 1695 lines (53 KB) with `lockfileVersion: '9.0'`. It has 199 entries in `packages:`, and each entry has a `resolution.integrity` value (no tarball URL, no git source). The entry of cdxgen has the value of `CDXGEN_INTEGRITY` (`sha512-+LWBiy...6Sgw==`).

- `pnpm install --frozen-lockfile --ignore-scripts` installs 187 packages on linux-x64 (pnpm installs only the platform package of the optional ones). `node_modules` has 332 MB. No package in the install has a `preinstall`, `install` or `postinstall` script (the agent read all 472 `package.json` files). So `--ignore-scripts` costs nothing, and cdxgen runs. pnpm 12 also blocks build scripts by default, but the flag makes it explicit and does not depend on a pnpm setting.

- A `package.json` that does not match the lock file stops the frozen install (`1 dependency is mismatched: @cyclonedx/cdxgen (lockfile: 12.9.0, manifest: 12.8.0)`). A wrong integrity value in the lock file also stops it (`The downloaded tarball does not match the integrity recorded in the lockfile`), and no `node_modules` stays.

- `node_modules/.bin/cdxgen --version` prints 12.9.0 when it runs from another folder, and cdxgen with the options of `sbom.sh` (`--type js --spec-version 1.6 --profile license-compliance --fail-on-error --output <file> <dir>`) makes an SBOM with one component for a test project with the dependency `left-pad`.

- With a `packageManager` field in `package.json`, pnpm 12.16.1 writes a lock file with a second YAML document (the pnpm packages as `packageManagerDependencies`) and 158 more lines. This makes the check of the lock file harder, so the project has no `packageManager` field. The pinned pnpm is a rule of the procedure and of `tools/versions.env`.

- `pnpm --dir tools/sbom exec cdxgen` changes the current folder to `tools/sbom`. The paths `frontend/` and the output folder would then be wrong. So `sbom.sh` starts the file `tools/sbom/node_modules/.bin/cdxgen` and gives absolute paths.

**The solution.** The simplest sound solution is a lock file, because pnpm checks the integrity value of each tarball against it (`--frozen-lockfile` also stops if the lock file and `package.json` differ). It replaces the check with `pnpm view`: the frozen install covers cdxgen and all its dependencies, and the pin check ties the lock file to `tools/versions.env`.

**The single source of truth** (DEC 2468257f-cb4e-4f30-a8df-6fc1d86759ce). `tools/versions.env` keeps `CDXGEN_VERSION` and `CDXGEN_INTEGRITY` (the integrity value is the same text in the lock file). `package.json` and the lock file are copies that a check compares, in the same way as the workflow versions of feat-5. The check is in `check_pins.py`, because `just check-pins` already compares the files of the repository with `tools/versions.env`, and CI runs it for each pull request. The new function reads `tools/sbom/package.json` with the JSON module and `tools/sbom/pnpm-lock.yaml` with PyYAML (the library that `check_pins.py` already uses) and checks these facts: (1) `dependencies` of `package.json` is exactly `{"@cyclonedx/cdxgen": "<CDXGEN_VERSION>"}` and no other dependency key has an entry; (2) `lockfileVersion` starts with `9.`; (3) `importers["."].dependencies["@cyclonedx/cdxgen"]` has `specifier` and `version` equal to `CDXGEN_VERSION`; (4) `packages["@cyclonedx/cdxgen@<version>"].resolution.integrity` is `CDXGEN_INTEGRITY`; (5) each entry in `packages` has `resolution.integrity` and nothing else that the check does not know (`tarball`, `repo`, `directory`). The check is always on, also when `frontend/` does not exist, and it stops (fail closed) if `tools/sbom/` is missing. `sbom.sh` has one cheap check after the install: the version in `node_modules/@cyclonedx/cdxgen/package.json` (read with `node`) must be `CDXGEN_VERSION`. So `just sbom` alone also stops if the lock file has another version, also on a machine where `just check-pins` did not run.

**`sbom.sh`.** If a Node manifest is scanned, the script runs `pnpm install --frozen-lockfile --ignore-scripts --dir <tools/sbom>` (or `cd` in a subshell), checks the version, and starts `tools/sbom/node_modules/.bin/cdxgen` with the options of today. A variable `SBOM_TOOL_DIR` sets another folder for the tests (the default is `tools/sbom` of the repository, and not of `SBOM_PROJECT_ROOT`, because the tool belongs to the gates and not to the scanned project). If no Node manifest is scanned, the script does not install (no network is necessary). If `tools/sbom/` has no lock file, the script stops. pnpm must not find a `pnpm-workspace.yaml` in a folder above `tools/sbom/`, otherwise it would install for that workspace. The E1 check already stops for such a file in the root, so no new rule is necessary.

**The E1 exclusion** (REQ-004). `manifest_files` in `_lib.sh` prunes the two files `./tools/sbom/package.json` and `./tools/sbom/pnpm-lock.yaml` by path, and not the folder. So `tools/sbom/pnpm-workspace.yaml`, `tools/sbom/sub/package.json` and each manifest in another folder under `tools/` still stop the script. `node_modules` in `tools/sbom/` is already pruned (the rule for `node_modules` is at each level). `check_pins.py` has a second copy of the excluded folders (`EXCLUDED_*`), but it searches for `pom.xml` and for the Maven Wrapper only, so it needs no change. The reason is in a comment next to both lists.

**CODEOWNERS and CI.** `.github/CODEOWNERS` has `/tools/ @dfch`, which covers `tools/sbom/`, so a change of the lock file needs the review of the owner. The job `license-check` in `.github/workflows/ci.yml` has `actions/setup-node` (26.13.0) and `pnpm/action-setup` (12.16.1), and `tools/gates/required-setup.txt` lists them, so no action and no change of `required-setup.txt` is necessary. The job `check-pins` does not need Node: the check reads the lock file as text with PyYAML. The pnpm of CI is the pinned pnpm 12.16.1, the same version that writes the lock file, and it reads `lockfileVersion: '9.0'`. A change of the pnpm version in `tools/versions.env` can change the lock file format, so the procedure says to write the lock file again with the new pnpm in the same commit.

**Licenses** (rule A). cdxgen 12.9.0 has the license Apache-2.0 (the main license, read in feat-5 from `package/LICENSE`), which is Permitted. The packages in the lock file are not checked, because cdxgen does not go to users. For information, the licenses in `package.json` of the 187 packages installed on linux-x64 are: MIT 124, ISC 34, BSD-2-Clause 11, BlueOak-1.0.0 10, Apache-2.0 3, BSD-3-Clause 2, CC0-1.0 1, `(Apache-2.0 AND BSD-3-Clause)` 1 and CC-BY-3.0 1 (`spdx-exceptions`, a package of license data). Under rule A, the CC-BY-3.0 is not checked. The lock file lists all 199 packages, so a reader can find each one. The feat-5 plan is not changed. This plan has the new facts, and the old limit G2 for cdxgen is closed by this feature.

### Related Decisions

- DEC 84c37f7d-08cb-457d-8ab3-1db37dba9bc9: Use Only Open Source Libraries That Are Compatible With AGPL-3.0-only (rule A for tools)

- DEC 361678a6-f941-473b-a058-1ba2bacf7d3d: Use a Test Pyramid and Blocking Gates for Verification

- DEC a56f231b-d063-4bef-bbc8-3deb4daff76e: Use Conventional Commits, Feature Branches and a Definition of Done

- DEC 2468257f-cb4e-4f30-a8df-6fc1d86759ce: Keep One Source of Truth for Each Type of Fact

- DEC cc4449cd-78fb-452a-904f-7efda89cf004: Set Limits for Coding Agents (CODEOWNERS covers `tools/`)

- DEC eb6e66ca-4ceb-46b5-9865-47e20a44674a: Write Documents in ASD-STE100 English

### Task List

#### Phase 100: The Project tools/sbom and the Install in sbom.sh

- [x] Task 100.100: Make `tools/sbom/package.json` (name, `private`, one dependency `@cyclonedx/cdxgen` 12.9.0, no `packageManager` field), write `tools/sbom/pnpm-lock.yaml` with the pinned pnpm (`pnpm install --lockfile-only`), add `node_modules/` to `.gitignore`, and confirm by hand that the frozen install with `--ignore-scripts` works and that cdxgen starts (ACC-001)

- [x] Task 100.110: Change `tools/gates/sbom.sh`: replace `pnpm view` and `pnpm dlx` with the frozen install in `tools/sbom/` (variable `SBOM_TOOL_DIR` for the tests), the version check of the installed cdxgen, and the start of `node_modules/.bin/cdxgen` with absolute paths. Change the header of the script (rule G2 and the Node line) (ACC-002, ACC-003)

- [x] Task 100.120: Add the exclusion of `tools/sbom/package.json` and `tools/sbom/pnpm-lock.yaml` to `manifest_files` in `tools/gates/_lib.sh`, and write the rule in the header of `sbom.sh` and in the comment of `EXCLUDED_*` in `check_pins.py` (ACC-005)

- [x] Task 100.130: Change the tests in `tools/gates/selftest.sh`: the stub of pnpm (`install` and the file `.bin/cdxgen` in a stub `SBOM_TOOL_DIR`), replace the cases for `pnpm view` and the integrity value, and add the cases for the install (flags, failure, version of cdxgen) and the E1 cases of ACC-005. Test the real pnpm cases of ACC-003 once by hand (ACC-003, ACC-005)

#### Phase 110: Pin Check, Documents and Pull Request

- [x] Task 110.100: Add the check of `tools/sbom/` to `tools/gates/check_pins.py` (facts 1 to 5 of Design Notes), keep the header of the script correct, give the existing `check-pins.sh` cases a project root with a good `tools/sbom/`, and add the cases of ACC-004 to `selftest.sh` (ACC-004)

- [x] Task 110.110: Write `tools/sbom/README.md` (purpose, the install command, the update procedure in one commit, the pinned pnpm and `lockfileVersion`, no `packageManager` field, rule A). Run the procedure once in a copy of the repository (ACC-006)

- [x] Task 110.120: Change the texts that say "29 dependencies are not checked" or `pnpm view`: the header of `tools/versions.env`, `tools/README.md`, `tools/gates/README.md` (table of G2, list of E1, the pin check, the limits). The limits of specmgr, PyYAML and the Maven plugin stay (ACC-007)

- [x] Task 110.130: Run the whole gate: `just test-gates`, `just test-license-gate`, `just check-pins`, `just check-workflows`, `just check-sudo`, `just validate`, `just commit-check`, `just license-check`, `just --fmt --unstable --check`, `ruff check` and `ruff format --check` for the Python files. Confirm that `.github/CODEOWNERS` and `required-setup.txt` are not changed (ACC-007, ACC-008)

- [ ] Task 110.140: Write the record in this plan (Progress), open the pull request with `Closes #16` (commit type `build`, scope `feat-16`), let all seven checks pass, and run the throwaway test pull request of ACC-009 (close it, do not merge it). The owner merges the pull request (ACC-008, ACC-009)

## Progress

### Current Status

**As of 2026-11-03 20:34**: Phase 100 is committed. Tasks 110.100 to 110.130 of Phase 110 are done and not committed. `check_pins.py` has the pin check of `tools/sbom/` (`check_sbom_tool`), `tools/sbom/README.md` has the full update procedure (the agent ran it in a copy of the repository, see the update of this time), and the texts of `tools/versions.env`, `tools/README.md`, `tools/gates/README.md`, `sbom.sh` and `check_pins.py` are correct. `just test-gates` has 418 cases and all are ok (335 before). The whole gate is green, also with `GITHUB_BASE_REF=dev`. ACC-001 to ACC-007 are checked. Open: Task 110.140 (the record, the pull request with `Closes #16`, the seven checks, and the throwaway pull request of ACC-009), so ACC-008 and ACC-009 are open. The branch is `feat-16-cdxgen-lockfile`. No decision of the owner is open.

### Blockers

- None that blocks the pull request.

- Open item, for information (not a blocker): a wrong integrity value of an optional dependency of cdxgen does not stop the install. The agent checked it again with the real pnpm 12.16.1 on 2026-11-03 20:34: pnpm logs `optional dependency that could not be fetched` and `ERR_PNPM_TARBALL_INTEGRITY`, installs 186 packages and not the one with the wrong value, and returns exit code 0. A required package with a wrong value stops the install. The package that is not installed does not run. `just check-pins` cannot see this case. The limit is in `tools/versions.env`, `tools/sbom/README.md`, `sbom.sh` and `tools/gates/README.md`.

- Open item, for information (not a blocker): the Python tools of the gates (specmgr, PyYAML) and the dependencies of `cyclonedx-maven-plugin` still have the limit of finding G2 (only the direct artifact has a checksum). This is out of scope of this feature. The owner can open a separate issue for each of them.

### Updates

<!-- Newest entry first -- prepend new entries directly below this comment. -->

#### 2026-11-03 20:34:30.000Z - Phase 110 (Tasks 110.100 to 110.130) done: pin check, procedure, texts and gate

The agent did Tasks 110.100 to 110.130. Nothing is committed. Task 110.140 (the pull request) is open.

- **Pin check (Task 110.100, ACC-004).** `check_pins.py` has a new function `check_sbom_tool` and a new argument `<sbom-tool-dir>`. `check-pins.sh` gives it `SBOM_TOOL_DIR`, and the default is `tools/sbom` of the repository (as in `sbom.sh`). The check is always on and fails closed. It stops for: a missing folder, `package.json` or lock file; another file in the folder (`.npmrc`, `pnpm-workspace.yaml`, `.pnpmfile.cjs`, a sub-folder); `CDXGEN_VERSION` that is not an exact version or `CDXGEN_INTEGRITY` that is not a `sha512-` value, or a missing key; `package.json` with another version, a range or a tag, another or a second dependency, or any key other than `name`, `private`, `description` and `dependencies`; a lock file that is not exactly one YAML document, has a key two times, has a `lockfileVersion` that is not a text that starts with `9.`, has another top-level key than `lockfileVersion`, `settings`, `importers`, `packages` and `snapshots`, has not exactly one importer `.` with exactly one direct dependency cdxgen (`specifier` and `version` = `CDXGEN_VERSION`), has another cdxgen version or another integrity value for cdxgen than `versions.env`, or has a package with no integrity value, with an integrity value that is not sha256, sha384 or sha512, with a `resolution` key other than `integrity` (tarball, git, folder), or with a key that is not `<name>@<exact version>`; a `snapshots` entry with no package. A file that PyYAML cannot read also stops it. `selftest.sh` has 83 new cases (all in the section "check-pins.sh: the lock file of cdxgen"): the three places each alone (`versions.env` version, `versions.env` integrity, `package.json`, the lock file importer, the lock file package, the lock file integrity), all three places with the same new value (pass), 12 ranges and tags, the extra dependencies and keys, and the cases of the lock file, the folder and `versions.env`. The existing `check-pins.sh` cases need no change: they use the real `tools/sbom/`.
- **Procedure (Task 110.110, ACC-006).** `tools/sbom/README.md` has the full procedure in 7 steps (read the license under rule A, use the pinned tools, `versions.env` with `pnpm view @cyclonedx/cdxgen@<v> dist.integrity`, `package.json`, a new lock file with `rm pnpm-lock.yaml && pnpm install --lockfile-only`, `just check-pins` and `just test-gates`, one commit), the table of the three places, the install, the limit for optional dependencies and the table of what `just check-pins` stops. The agent ran the procedure in a throwaway copy of the repository (`/tmp/opencode/procrun`, not the repository). Same version 12.9.0: the new lock file is the same as the old one byte for byte (`cmp`), and `just check-pins` returns exit code 0. Version 12.8.0 (it is on npm, license Apache-2.0 from `package/LICENSE` and `package.json`, `dist.integrity` `sha512-l8QYX3bfYxfKCkwMwp4F8MM0IpuOMV+tmzJiCa6ffIhiSVmTuTqQzrGIaJ6Tt7HJioIP88iiq3RW5Ax6yZZjAw==`): only `versions.env` changed gives exit code 1 with 4 problems (`package.json`, importer `specifier`, importer `version`, package entry); `versions.env` and `package.json` changed gives exit code 1 with 3 problems (the three lock file lines); all three changed (lock file written by pnpm 12.16.1, 192 packages, each with an integrity value, no `tarball`, `repo` or `directory`) gives exit code 0. In that copy `just test-gates` gave 418 ok and 0 failed, the frozen install in a clean copy of the three files gave exit code 0 and `cdxgen --version` showed 12.8.0, and `sbom.sh` with a test frontend wrote `frontend.cdx.json` (log: install in `tools/sbom/`, version 12.8.0). The run found an error in the tests of Phase 100: the cases "another version of cdxgen" used `12.8.0` and `12.10.0` as the "wrong" version, so a real update to 12.8.0 made 3 cases fail. The cases now use `0.0.1` and `0.0.2` (no real versions). The repository is not changed by the test.
- **Texts (Task 110.120, ACC-007).** Changed: the header of `tools/versions.env` (cdxgen is checked with all its dependencies; the Python tools and the Maven plugin are not; the limit for optional dependencies; a comment at the keys that the three places must be the same), `tools/README.md` (the row `sbom/`), `tools/gates/README.md` (the row of `check-pins`, the G2 intro and table, a new part "The pin check of the cdxgen project", the list of files and the limits), the header of `sbom.sh` (the limit for optional dependencies, the pin check) and the header of `check_pins.py`. No text says "29 dependencies are not checked" or `pnpm view` for cdxgen any more (the lock file has 199 packages, 187 installed on linux-x64). The plan of feat-5 is not changed.
- **Optional dependency (checked again).** With the real pnpm 12.16.1, the lock file with a wrong integrity value for `@appthreat/atom-common@1.1.0` (an optional dependency): `[WARN] @appthreat/atom-common@1.1.0 is an optional dependency that could not be fetched. Excluding it from installation.`, then `ERR_PNPM_TARBALL_INTEGRITY` with the wanted and the actual value, `Packages: +186` (187 resolved), exit code 0, `node_modules/.bin/cdxgen` exists, and the package is not installed. A required package with a wrong value stops the install (Phase 100: `yargs`).
- **Gate (Task 110.130, ACC-007).** Exit code 0 for: `just --fmt --unstable --check`, `just test-gates` (418 ok, 0 failed), `just test-license-gate` (46 ok, 0 failed), `just validate`, `just commit-check` (2 commits correct), `just license-check` (0 components), `just check-workflows` (7 run steps), `just check-pins` (23 `uses:` steps and the cdxgen lock file), `just check-sudo` (21 files) and `just sbom`. The same recipes with `GITHUB_BASE_REF=dev`: exit code 0. `ruff check` and `ruff format --check` with line length 120 for `tools/gates/*.py`: pass. `bash -n` for `tools/gates/*.sh`: pass. `.github/CODEOWNERS`, `.github/workflows/ci.yml` and `tools/gates/required-setup.txt` are the same as in `origin/dev` (`git diff origin/dev` shows no change). The line `/tools/ @dfch` of CODEOWNERS covers `tools/sbom/`.
- Files changed (not committed): `tools/gates/check_pins.py`, `tools/gates/check-pins.sh`, `tools/gates/selftest.sh`, `tools/gates/sbom.sh` (comments only), `tools/gates/README.md`, `tools/sbom/README.md`, `tools/README.md`, `tools/versions.env` (comments only) and this plan.

#### 2026-11-03 20:15:33.000Z - Phase 100 done: tools/sbom and the install in sbom.sh

The agent did Tasks 100.100 to 100.130. Nothing is committed.

- `tools/sbom/package.json` has one dependency, `@cyclonedx/cdxgen` 12.9.0, and no `packageManager` field. pnpm 12.16.1 wrote `pnpm-lock.yaml` (1695 lines, `lockfileVersion: '9.0'`, 199 packages, each with `resolution.integrity`). A second run of `pnpm install --lockfile-only` gave a byte-equal file. The integrity value of cdxgen in the lock file is `CDXGEN_INTEGRITY`. `node_modules/` is in `.gitignore`, and the lock file is not ignored. `tools/sbom/README.md` is a first version (Phase 110 writes the full procedure).
- A frozen install with `--ignore-scripts` in a clean copy of the three files returned exit code 0 (187 packages), and `cdxgen --version` shows 12.9.0. The agent read the 472 `package.json` files of the install: no package has a `preinstall`, `install` or `postinstall` script.
- `sbom.sh` installs with `pnpm install --frozen-lockfile --ignore-scripts` in `tools/sbom/` (`SBOM_TOOL_DIR` sets another folder), checks the installed version, and starts `node_modules/.bin/cdxgen` with absolute paths. It has no `pnpm dlx` and no `pnpm view`. It stops with exit code 1 if the folder, `package.json` or the lock file is missing, if the install fails, or if the version is not `CDXGEN_VERSION`. It does not install if no Node manifest is scanned.
- `manifest_files` skips `tools/sbom/package.json` and `tools/sbom/pnpm-lock.yaml` by path. The rule is in the header of `sbom.sh`, in `_lib.sh`, in the comment of `EXCLUDED_*` in `check_pins.py` and in `tools/gates/README.md` (E1 list, G2 table and limits). Phase 110 changes the other texts.
- `selftest.sh`: the stub of pnpm has only `install` (it writes a stub cdxgen and its `package.json`; `dlx` and `view` give exit code 64). New cases: flags of the install, folder of the install, absolute paths, one pnpm call, no install without a Node manifest, failed install, another version of cdxgen (lock file and `versions.env`), missing folder, `package.json` or lock file, no old SBOM stays, and all E1 cases of ACC-005 (positive and negative, also `tools/sbom/sub/pnpm-lock.yaml`, `tools/sbom/pom.xml`, `tools/other/pnpm-lock.yaml` and a root `pnpm-lock.yaml`). `just test-gates`: 335 ok, 0 failed.
- Test with the real pnpm and cdxgen (test frontend with `left-pad` 1.3.0 in `/tmp/opencode/fe`, `SBOM_PROJECT_ROOT` set): the run wrote `frontend.cdx.json` with 1 component (left-pad 1.3.0), and the log shows the install in `tools/sbom/`. Stop with exit code 1 and no SBOM file: `package.json` with 12.8.0 and the lock file with 12.9.0 (`ERR_PNPM_OUTDATED_LOCKFILE`); a wrong integrity value of cdxgen (`ERR_PNPM_TARBALL_INTEGRITY`); a wrong integrity value of `yargs` (`ERR_PNPM_TARBALL_INTEGRITY`); `package.json` and lock file for 12.8.0 (the version check: installed 12.8.0, `CDXGEN_VERSION` is 12.9.0); no lock file.
- Unexpected, for information: a wrong integrity value of an optional dependency (`@appthreat/atom-common`) does not stop the install. pnpm logs `ERR_PNPM_TARBALL_INTEGRITY`, does not install that package, and returns exit code 0. The package with the wrong value is not installed and does not run, so no code of it is trusted. A real tampering would at most remove a feature of cdxgen. The statement is in the G2 table of `tools/gates/README.md`.
- Unexpected, for information: cdxgen shows a warning "NODE_PATH is set" in its environment audit (in the shell of the agent `NODE_PATH` is set and empty). The run is not affected.

#### 2026-11-03 19:58:43.000Z - Plan written

The agent wrote this plan for GitHub issue #16. It read the issue, `sbom.sh`, `check_pins.py`, `_lib.sh`, the tests, `tools/versions.env`, CODEOWNERS, `required-setup.txt` and the plan of feat-5. In a temporary folder under `/tmp/opencode` it tested `pnpm install --lockfile-only`, `pnpm install --frozen-lockfile --ignore-scripts`, a wrong version and a wrong integrity value in the lock file, and cdxgen on a test project (the results are in Design Notes). Nothing is implemented, and no file is committed or pushed.

### Decisions Made

<!-- Newest entry first -- prepend new entries directly below this comment. -->

#### 2026-11-03 20:34:30.000Z - Decisions of Phase 110

1. The folder for the pin check is `SBOM_TOOL_DIR` of `check-pins.sh`, and the default is `tools/sbom` of the repository (`REPO_ROOT`), not of `GATE_WORK_ROOT`. Reason: the same rule as in `sbom.sh` (the tool belongs to the gates and not to the scanned project). The existing Maven cases (they use an empty `GATE_WORK_ROOT`) then need no copy of `tools/sbom/`, and they still run the real check.
2. The check uses an allow-list for the keys of `package.json` (`name`, `private`, `description`, `dependencies`) and for the top-level keys of the lock file, and for the files in `tools/sbom/`. Reason: fail closed. A deny-list would miss a key that pnpm reads and that nobody knew (for example `pnpm`, `overrides`, `resolutions`, `scripts`, `.npmrc`). A new legal key means a change of the check, which the owner reviews through CODEOWNERS.
3. A key two times in `package.json` or in the lock file stops the check (own JSON and YAML loaders). Reason: PyYAML and the standard JSON reader keep the last value without a message, so a second entry could hide the first one.
4. A package integrity value must be sha256, sha384 or sha512 (sha1 stops the check), and a `resolution` must have `integrity` and nothing else. The cdxgen value must be a `sha512-` value of 88 characters. Reason: fail closed for a weaker hash and for a package from another place than the registry (REQ-003).
5. The text of an unreadable or wrong lock file gives exit code 1 (a problem with a message) and not exit code 2, so that each wrong input of `tools/sbom/` has the same result (STOP) as the ACC-004 cases. Exit code 2 stays for a wrong `versions.env` or workflow.
6. Tests of Phase 100 that used `12.8.0` and `12.10.0` as a wrong version of cdxgen use `0.0.1` and `0.0.2` now. Reason: the procedure run in the copy showed that a real update to 12.8.0 made them fail.
7. The procedure in `tools/sbom/README.md` starts with the license (rule A, the license file of the release and not only the field), because a new version is new code.

#### 2026-11-03 20:15:33.000Z - Decisions of Phase 100

1. `sbom.sh` reads the installed version of cdxgen with the Python of `uv run --no-project` (the same way as `sbom_check.py`) and not with `node`. Reason: the job `test-gates` has no Node setup, and the self-test must not depend on the Node of the runner. The job `license-check` has `uv`. The result is the same: the `version` field of `node_modules/@cyclonedx/cdxgen/package.json`.
2. The install runs in a subshell with `cd <tool dir>` and not with `pnpm --dir`, so that the stub of pnpm in the self-test can write its files in the current folder. The paths for cdxgen are absolute, and cdxgen runs from the root of the project.
3. `sbom.sh` stops if `package.json` or `pnpm-lock.yaml` is missing in the tool folder, before it starts pnpm (without the lock file pnpm would write one and the install would not be frozen).
4. The key `CDXGEN_INTEGRITY` stays in `tools/versions.env`. `sbom.sh` does not read it now, and the pin check of Phase 110 will. The self-test no longer changes it.
5. In `tools/gates/README.md` Phase 100 changed only the lines that were wrong after the change (E1 exclusion, G2 row, `sbom` tool row, one limit). Task 110.120 does the other texts.

#### 2026-11-03 19:58:43.000Z - Choices of the plan (the owner can change them)

The owner gave no detail except "do it now, with a small FEAT backed by a GitHub issue". The agent made these choices:

1. A pnpm lock file in `tools/sbom/` (the way that issue #16 proposes). The project has one dependency, with the exact version, and no `packageManager` field (it changes the lock file layout).

2. `sbom.sh` installs with `--frozen-lockfile --ignore-scripts` and starts `node_modules/.bin/cdxgen`. `--ignore-scripts` is safe because no package in the install has an install script. The check `pnpm view ... dist.integrity` is removed, because the frozen install checks the integrity value of cdxgen and of all its dependencies against the lock file.

3. `tools/versions.env` stays the source for `CDXGEN_VERSION` and `CDXGEN_INTEGRITY`. `check_pins.py` (so `just check-pins`, which is a required check of each pull request) compares `package.json` and the lock file with it. `sbom.sh` also checks the installed version, so that `just sbom` alone is safe.

4. The E1 exclusion is for the two files `tools/sbom/package.json` and `tools/sbom/pnpm-lock.yaml`, and not for the folder.

5. Rule A: only the main license of cdxgen is checked. The licenses of the packages in the lock file are in this plan for information. The feat-5 plan is not changed.

6. No new GitHub Action and no change of CODEOWNERS or of `required-setup.txt`.

7. The Python tools and the Maven plugin are not part of this feature.

### Related PRs / Commits

- [Issue #16](https://github.com/dfch/biz.dfch.SpecMgrDemo/issues/16): Gates: lock file for the SBOM tool cdxgen. The name of this feature uses the number of the issue.

### More Information

Origin: finding G2 of the review of feat-5-foundation-monorepo-ci (see its Design Notes, Blockers, the update of 2026-11-03 18:28 and Decisions Made). The owner decided on 2026-11-03 to do this now.

Note (2026-11-03): this feature closes the cdxgen part of finding G2: the lock file pins cdxgen and its 198 other packages with an integrity value, and `just check-pins` ties it to `tools/versions.env`. Only a wrong integrity value of an optional dependency does not stop the install (see Blockers). The Python tools and the Maven plugin still have the limit of G2. The plan of feat-5 is not changed.
