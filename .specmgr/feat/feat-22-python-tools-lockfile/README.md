---
classification: null
created: '2026-11-04T06:22:50.630+01:00'
id: feat-22-python-tools-lockfile
status: done
type: feat
updated: '2026-11-04T07:16:58.614+01:00'
version: 1.0.0
---

# Feature: Hash-Locked Install of the Python Tools of the Gates

## Plan

### Overview

The gates install three Python tools: specmgr, PyYAML and `license-expression`. Today the install checks the sha256 of the direct artifact of each tool only. The 40 dependencies of specmgr, and the build tools for the PyYAML source archive, are not checked. A changed dependency could make a gate report PASS when it must stop. This is the accepted limit G2 of the review of feat-5-foundation-monorepo-ci. The cdxgen part of G2 was closed by feat-16-cdxgen-lockfile.

This feature adds one lock file for each tool in `tools/python/`. A lock file has the exact version and the sha256 of each file of each package, with the dependencies. The gates install from it with `uv pip install --require-hashes --only-binary :all:`, in a virtual environment of the pinned Python 3.13. `tools/versions.env` stays the source of the versions, and `just check-pins` ties the lock files to it. The checksum keys of the Python tools are removed from `tools/versions.env`, because the lock files have them. GitHub issue #22 is for this feature. The implementation is written and tested on the branch `feat-22-python-tools-lockfile`. It is not committed and not pushed, and no pull request exists yet (see Progress).

### Requirements

- REQ-001: The folder `tools/python/` must have one lock file for each Python tool of the gates: `specmgr.lock`, `pyyaml.lock` and `license-expression.lock`. Each lock file must pin each package, with the dependencies, to an exact version and at least one `--hash=sha256:` value. A lock file must have no URL, no path, no VCS source, no editable entry and no index option.

- REQ-002: The function `make_python_env` in `tools/gates/_lib.sh` must install from one lock file only, with `--require-hashes` and `--only-binary :all:`. It must use the Python of `PYTHON_VERSION` in `tools/versions.env` (3.13). It must not build a source archive. The mode `verify` must not exist.

- REQ-003: The file `tools/versions.env` must stay the one source of truth for the version of each tool: `SPECMGR_VERSION`, `PYYAML_VERSION`, `LICENSE_EXPRESSION_VERSION` and the new `PYTHON_VERSION`. The keys `SPECMGR_SHA256`, `PYYAML_SHA256`, `LICENSE_EXPRESSION_SHA256`, `BOOLEAN_PY_VERSION` and `BOOLEAN_PY_SHA256` must be removed (DEC 2468257f-cb4e-4f30-a8df-6fc1d86759ce).

- REQ-004: `just check-pins` must stop if a lock file is missing, if the version of a tool in its lock file is not the version in `tools/versions.env`, or if a package has no hash, no exact version (`==`) or a source that is not allowed (REQ-001).

- REQ-005: `tools/python/` must have a script that makes the lock files from `tools/versions.env` (`uv pip compile --generate-hashes --universal --only-binary :all:`), and a README with the procedure to change a version. A change of only one of the two places must stop `just check-pins`.

- REQ-006: The feature must not add a GitHub Action, must not change `.github/workflows/ci.yml` and must not change `.github/CODEOWNERS`. The line `/tools/` must cover `tools/python/`.

- REQ-007: Python is a tool of the gates (rule A of DEC 84c37f7d-08cb-457d-8ab3-1db37dba9bc9). The license of Python 3.13 must be read from the license file of the build, and must be in the class Permitted before the project uses Python 3.13 (REQ-010 of feat-5-foundation-monorepo-ci). The owner decides the class.

### Acceptance Criteria

- [x] ACC-001: `tools/python/` has the three lock files, the script and the README. In a new virtual environment of Python 3.13, `uv pip install --require-hashes --only-binary :all: -r <lock file>` returns exit code 0 for each lock file, and specmgr can be imported (REQ-001, REQ-002).

- [x] ACC-002: `make_python_env` has no mode `verify` and no `--verify-hashes`. `just validate`, `just license-check`, `just check-workflows` and `just check-pins` return exit code 0 on the branch (REQ-002).

- [x] ACC-003: Each of these cases stops the gate with exit code 1 in `just test-gates`: a wrong hash of a dependency of specmgr; a dependency of specmgr with no hash; a dependency that is missing in the lock file; a wrong hash of PyYAML; a wrong hash of `boolean.py` (REQ-001, REQ-002).

- [x] ACC-004: `just check-pins` returns exit code 0 now. It returns exit code 1 for each of these cases in `just test-gates`: no lock file; another version of the tool in the lock file; another version in `tools/versions.env`; a package with no hash; a package with no exact version; a package with a URL or a VCS source; an index option (REQ-003, REQ-004).

- [x] ACC-005: The procedure of `tools/python/README.md` ran once in a copy of the repository. The new lock files are the same as the lock files in the repository, or the README explains each difference. A change of one version in `tools/versions.env` only stops `just check-pins` (REQ-005).

- [x] ACC-006: `tools/versions.env`, `tools/gates/README.md` and `tools/README.md` state the new facts and the limits that stay. No text says that the dependencies of specmgr are not checked (REQ-003).

- [x] ACC-007: `PSF-2.0` is in the class Permitted of DEC 84c37f7d-08cb-457d-8ab3-1db37dba9bc9 and in `tools/license/permitted-licenses.txt`. The license table of this plan has the row of Python 3.13. `just test-license-gate` has a fixture for `PSF-2.0` (REQ-007).

- [x] ACC-008: These recipes return exit code 0 on the branch: `just test-gates`, `just test-license-gate`, `just check-pins`, `just check-workflows`, `just check-sudo`, `just validate`, `just commit-check`, `just license-check` and `just --fmt --unstable --check`. The pull request has all seven checks green (REQ-006).

- [x] ACC-009: A throwaway test pull request (closed, not merged) that changes one hash of a dependency in `tools/python/specmgr.lock` fails the job `validate` in real CI, with the message of uv about the hash. The same CI run with the real lock file passes (REQ-002).

### Scope

#### Included

- The three lock files, the script and the README in `tools/python/`.

- The change of `make_python_env` and of the four gate scripts that call it (`validate-docs.sh`, `license-check.sh`, `check-workflows.sh`, `check-pins.sh`).

- The check of the lock files in `tools/gates/check_pins.py`.

- The tests in `tools/gates/selftest.sh`, the fixture for `PSF-2.0`, and the texts in `tools/versions.env`, `tools/README.md` and `tools/gates/README.md`.

- The license of Python 3.13 (`PSF-2.0`) in DEC 84c37f7d-08cb-457d-8ab3-1db37dba9bc9, with a permission of the owner for this one change.

#### Explicitly Out Of Scope

- The dependencies of `cyclonedx-maven-plugin` (GitHub issue #23, after feat-6-contracts-openapi-pipeline has a `pom.xml`).

- `uv` itself (`UV_VERSION` has no checksum; the action `astral-sh/setup-uv` downloads it) and the GitHub Actions (pinned to a commit SHA).

- A check of the download of the Python build that `uv` makes. This feature does not add a checksum for it.

- The scripts that use only the standard library of Python (`sbom_check.py`). They start with `uv run --no-project` and need no package.

- A license check of the packages in the lock files (rule A: the tools do not go to users).

- An automatic update of the lock files (for example a bot).

### Dependencies

#### Depends On

- FEAT feat-5-foundation-monorepo-ci (done): it has the gates, `tools/versions.env` and the CI jobs.

- GitHub issue #22: the issue for this feature.

#### Blocks

- None.

### Design Notes

**Facts that the agent checked on 2026-11-04** (uv 0.12.5, in a temporary folder, not in the repository):

- `uv pip compile --generate-hashes --universal --python-version 3.13 --only-binary :all:` works for each of the three tools. specmgr with the extra `mcp` gives 44 packages with 598 hashes (the lock has markers, for example for `colorama` on Windows). PyYAML gives 1 package with 73 hashes. `license-expression` gives 2 packages (with `boolean.py`) with 4 hashes. Each package has a wheel, so `--only-binary :all:` costs nothing and the source build of PyYAML is not necessary.

- A new virtual environment of Python 3.13.13 installs the specmgr lock with `--require-hashes --only-binary :all:` with exit code 0, and `biz.dfch.specmgr` can be imported. 41 packages are installed on linux-x64 (the markers remove 3 packages).

- specmgr 0.38.0 has `requires-python >=3.11`. The machine of the author has Python 3.10.12 as `python3` and a uv-managed Python 3.13.13. The runner of CI has its own Python. So the gates must name the Python: `uv venv --python 3.13`. uv downloads a managed Python if no 3.13 exists.

**The solution.** A lock file is the same method as in feat-16: the installer compares each file with a hash that is in the repository, and a pin check ties the lock file to `tools/versions.env`. `--require-hashes` makes uv stop for each package that has no hash, also for a dependency. `--only-binary :all:` stops the build of a source archive, so the build tools of PyYAML are no longer part of the install.

**One lock file for each tool.** A gate installs only the packages that it needs. The job `check-workflows` and the job `check-pins` need PyYAML only, and they do not download the 41 packages of specmgr.

**Single source of truth** (DEC 2468257f-cb4e-4f30-a8df-6fc1d86759ce). `tools/versions.env` keeps the direct version of each tool and `PYTHON_VERSION`. The lock file is a copy that a check compares. The script in `tools/python/` writes a temporary input file from `tools/versions.env`, so no second input file with the same version is in the repository. The version of `boolean.py` has its place in the lock file only, and `tools/versions.env` does not have it any more. The checksum of the direct artifact has its place in the lock file only.

**Check of the lock files.** `check_pins.py` reads each lock file as text. It does not start uv and does not make the lock file again, so the result does not depend on the version of uv. It checks: (1) each lock file exists; (2) each entry has the form `name==version`, with an optional marker, and at least one `--hash=sha256:` value of 64 hexadecimal characters; (3) the line has no URL, no path, no `git+`, no `-e` and no index option (`--index-url`, `--extra-index-url`, `--find-links`, `--no-binary`); (4) the entry of the tool, after the normalization of the name, has the version of `tools/versions.env`. A comment line and a `# via` line are allowed.

**Python.** `PYTHON_VERSION=3.13` is the minor version, because the lock files are valid for each 3.13 release. The license of CPython is read from the file `lib/python3.13/LICENSE.txt` of the build `cpython-3.13.13-linux-x86_64-gnu`. Its main license is the Python Software Foundation License Version 2 (`PSF-2.0`). The file also has the older agreements of BeOpen, CNRI and CWI, and a zero-clause BSD text. Under rule A only the main license is checked. The class Permitted had no entry for it. On 2026-11-04 the owner gave a permission for one time to add `PSF-2.0` to the class Permitted of DEC 84c37f7d-08cb-457d-8ab3-1db37dba9bc9, and the agent did it (see the update of that time). The project that builds the Python distributions, `python-build-standalone`, is not read in this feature. The build has no license file of its own, and the agent does not guess its license.

License table (the agent filled it from the license file of the build and not from memory. The other tools of this feature are specmgr, PyYAML and `license-expression` with `boolean.py`. They keep the versions and the rows of the license table of feat-5-foundation-monorepo-ci, and this feature does not change them):

| Tool | Use | License | Result |
|---|---|---|---|
| Python 3.13 (CPython 3.13.13, uv-managed build `cpython-3.13.13-linux-x86_64-gnu`) | runs the Python tools of the gates | PSF-2.0 (main license). Source: `lib/python3.13/LICENSE.txt` of the build, sha256 `78b12c3a81360b357002334f0e70ea0e92eebf7a9b358805c03c48484945f3bb`. The file also has the BeOpen, CNRI and CWI agreements and a zero-clause BSD text for code in the documentation | Permitted since 2026-11-04 05:20 (the owner gave a permission for one time to add `PSF-2.0` to the DEC). Under rule A the other texts in the file are not checked, because Python does not go to users |

**Limits that stay.** The lock files do not check `uv`, the GitHub Actions, the Python build that uv downloads, and the dependencies of the Maven plugin. A lock file does not check the content of a package on PyPI that has the same hash: the hash proves that the file is the file of the lock file, not that the file is safe. The lock files can be out of date. A person must run the script of REQ-005 to update them.

### Related Decisions

- DEC 84c37f7d-08cb-457d-8ab3-1db37dba9bc9: Use Only Open Source Libraries That Are Compatible With AGPL-3.0-only (rule A for tools, `PSF-2.0`)

- DEC 361678a6-f941-473b-a058-1ba2bacf7d3d: Use a Test Pyramid and Blocking Gates for Verification

- DEC a56f231b-d063-4bef-bbc8-3deb4daff76e: Use Conventional Commits, Feature Branches and a Definition of Done

- DEC 2468257f-cb4e-4f30-a8df-6fc1d86759ce: Keep One Source of Truth for Each Type of Fact

- DEC cc4449cd-78fb-452a-904f-7efda89cf004: Set Limits for Coding Agents (CODEOWNERS covers `tools/`)

- DEC eb6e66ca-4ceb-46b5-9865-47e20a44674a: Write Documents in ASD-STE100 English

### Task List

#### Phase 100: License of Python

- [x] Task 100.100: Read the license file of the Python 3.13 build. With the permission of the owner, add `PSF-2.0` to the class Permitted of DEC 84c37f7d-08cb-457d-8ab3-1db37dba9bc9 and to `tools/license/permitted-licenses.txt`. Add a fixture and run `just test-license-gate` (ACC-007)

#### Phase 110: Lock Files and the Install

- [x] Task 110.100: Write the script and the README in `tools/python/`, add `PYTHON_VERSION` to `tools/versions.env`, and make the three lock files (ACC-001, ACC-005)

- [x] Task 110.110: Change `make_python_env` (one lock file, `--require-hashes`, `--only-binary :all:`, `--python`), the four gate scripts, and remove the checksum keys from `tools/versions.env` (ACC-002)

#### Phase 120: Pin Check and Tests

- [x] Task 120.100: Add the check of the lock files to `tools/gates/check_pins.py` (ACC-004)

- [x] Task 120.110: Change the G2 cases of `tools/gates/selftest.sh`, remove the cases for the removed keys, and add the cases of ACC-003 and ACC-004 (ACC-003, ACC-004)

#### Phase 130: Documents, Gate and Pull Request

- [x] Task 130.100: Change the texts in `tools/versions.env`, `tools/README.md` and `tools/gates/README.md` (G2 table and the open limits) (ACC-006)

- [x] Task 130.110: Run the procedure of `tools/python/README.md` in a copy of the repository, and run all recipes of ACC-008 (ACC-005, ACC-008)

- [x] Task 130.120: Open the pull request to `dev` and wait for the seven checks. Make the throwaway test pull request of ACC-009, close it and delete its branch (ACC-008, ACC-009)

## Progress

### Current Status

**As of 2026-11-04 06:16**: Done. All tasks and all acceptance criteria (ACC-001 to ACC-009) are checked, pull request #27 is merged into `dev`, and the status is `done` (set in the pull request of the close-out, see SOP 766e4c27-31e3-495f-9f37-307c5f3ee0e8). The owner reviewed the `PSF-2.0` entry.

### Blockers

- None.

- Resolved on 2026-11-04 (statement of the owner; DEC 84c37f7d-08cb-457d-8ab3-1db37dba9bc9 has an entry of 05:59:43): the owner reviewed the `PSF-2.0` entry. Open item for the owner (not a blocker): no person with legal competence is named as a reviewer.

### Updates

<!-- Newest entry first -- prepend new entries directly below this comment. -->

#### 2026-11-04 06:16:10.000Z - Handover at the end of the session

State: feat-22 is merged and `done`. Run the SOP 289efe7a-2478-49b8-86b0-2d6983749832 first (`git fetch --prune`, `git switch dev`, `git pull`), and make new branches from `origin/dev`. Source `~/.config/biz.dfch.SpecMgrDemo/env.sh` for the tools.

Open, in the order that the agent suggests (the owner decides):
1. GitHub issue #31 for the cost of pull requests (SOP 766e4c27-31e3-495f-9f37-307c5f3ee0e8 is step A; the options B and C are in the issue). The SOP has the status `draft`: the owner activates it.
2. Release of `dev` to `main` with a merge commit. The old feature branches can go after it.
3. feat-6-contracts-openapi-pipeline (empty license table, adds `mvnw`), then issue #23 (Maven plugin dependencies).
4. Small items: the cdxgen `NODE_PATH` warning, NOTICE has no copyright line, the local branch `backup/dev-pre-squash` (9 commits not in `dev`).

Do not push to a branch after its pull request is merged (the old branch `feat-22-python-tools-lockfile` has a duplicate commit 0f40987, do not push it).

#### 2026-11-04 05:56:00.000Z - Pull request #27 and throwaway pull request #29 (ACC-008, ACC-009 done)

The owner said "go ahead" to commit and push. The agent made four commits (scope `feat-22`) on the branch, pushed it, and opened pull request #27 to `dev`.

1. `just commit-check` (GITHUB_BASE_REF=dev) returned exit code 0 for the three first commits.
2. First CI run of #27: 6 of 7 checks passed, and `test-gates` had 2 failed cases (454 ok). The reason: for a dependency that is missing from a lock file, uv 0.13.7 in CI says "Hash-checking is required, but no trusted hash was provided", and uv 0.12.5 on the machine of the author says "must be pinned upfront with `==`". The gate stopped with exit code 1 in both cases. The agent changed the two cases to expect the text of the gate ("uv did not install") and not the wording of uv (commit f9744e0). `just test-gates` shows 456 ok, 0 failed locally.
3. Second CI run of #27 at f9744e0: all seven checks are green (`validate`, `commit-check`, `license-check`, `check-workflows`, `check-pins`, `check-sudo`, `test-gates`).
4. ACC-009. The throwaway pull request #28 had the feature branch as its base, so the workflow (trigger `dev` and `main`) did not run. The agent closed it and opened #29 to `dev`. #29 changed the first hash of `attrs` in `specmgr.lock`. Result in real CI: `validate` failed with `cause: Hash mismatch for \`attrs==26.1.0\`` and `uv did not install specmgr from .../tools/python/specmgr.lock`. `test-gates` failed too (as expected: its case "a valid document" installs specmgr from the real lock file). `license-check`, `check-pins`, `check-workflows`, `commit-check` and `check-sudo` passed. #28 and #29 are closed and not merged, and the branch `test/feat-22-pr-bad-hash` is deleted (local and remote).
5. State: #27 is BLOCKED and REVIEW_REQUIRED. The owner reviews and merges it. The branch `feat-22-python-tools-lockfile` stays until the release.

Finding for the owner. The messages of uv change between versions, so a test that matches the text of uv can fail when `UV_VERSION` changes. The tests of this feature now match the text of the gate where the case is a missing dependency. Cases with "Hash mismatch" and "must have a hash" passed with both versions.

#### 2026-11-04 05:33:00.000Z - Phases 110 to 120 and Task 130.100 done, ACC-001 to ACC-007 checked

The agent changed the gates, the lock files and the texts. Nothing is committed or pushed. The agent checked these facts on 2026-11-04 (uv 0.12.5, Python 3.13.13 from uv):

1. Lock files. `tools/python/make-locks.sh` writes `specmgr.lock` (44 entries, 598 hashes), `pyyaml.lock` (1 entry, 73 hashes) and `license-expression.lock` (2 entries, 4 hashes) from `tools/versions.env`. A second run gives identical files. The `# via` lines had the path of a temporary file, so the script writes a fixed text instead.
2. ACC-001. In a new virtual environment of Python 3.13.13, `uv pip install --require-hashes --only-binary :all: -r <lock file>` returns exit code 0 for each lock file. It installs 41, 1 and 2 packages (the markers remove 3 packages of specmgr on Linux), and `import biz.dfch.specmgr`, `import yaml` and `import license_expression, boolean` work.
3. ACC-002. `make_python_env <lock-name>` has no mode argument and no `--verify-hashes`. `just validate`, `just license-check`, `just check-workflows` and `just check-pins` return exit code 0.
4. ACC-003 and ACC-004. `just test-gates` shows 456 ok and 0 failed. The new cases cover: a wrong hash of specmgr, of a dependency of specmgr (`attrs`), of PyYAML, of `license-expression` and of `boolean.py`; a dependency with no hash; a dependency that is not in the lock file; a lock file with the hash of the PyYAML source archive only (uv stops, so no source build); no lock file; no `PYTHON_VERSION`; another version in the lock file and in `versions.env`; a range; a URL, a path, a VCS source, an editable entry, and the options `--index-url`, `--extra-index-url`, `--find-links` and `--no-binary`; a hash that is not sha256 or not 64 characters; a marker with a URL; a lock file with no package, with no entry of the tool or with two versions of it, and one that ends after a backslash; and an extra file in `tools/python/`.
5. ACC-005. In a copy of the repository, `make-locks.sh` gives lock files that are the same as the ones in the repository. A change of `PYYAML_VERSION` alone stops `just check-pins`. After `make-locks.sh`, only `pyyaml.lock` has changed (6.0.2), and `just check-pins` returns exit code 0. `--upgrade` found no newer dependency of specmgr on this day.
6. ACC-006 and ACC-007. The texts of `tools/versions.env`, `tools/README.md` and `tools/gates/README.md` are changed, and a search finds no text that says that the dependencies of specmgr are not checked (the old feat plans keep their history). `PSF-2.0` is in the DEC, in the list, and in the fixture `47-psf2.cdx.json` (`just test-license-gate`: 47 ok).
7. Local recipes of ACC-008 that ran with exit code 0: `just test-gates`, `just test-license-gate`, `just check-pins`, `just check-workflows`, `just check-sudo`, `just validate`, `just license-check` and `just --fmt --unstable --check`. `just commit-check` and the seven checks of the pull request are open.

Finding. A change of `pyyaml.lock` stops the install of PyYAML before `check-pins` can read the file, because `check-pins.sh` and `check-workflows.sh` install PyYAML from it. This is correct (the gate fails closed), but the test cases for the pin check must change the lock files of specmgr and `license-expression`. The cases for a changed `pyyaml.lock` test the install.

#### 2026-11-04 05:22:07.000Z - Plan written, license of Python added (Phase 100)

The owner chose issue #22 as the next work and decided: one lock file for each tool, the checksum keys of the Python tools are removed from `tools/versions.env`, and the lock files are for Python 3.13. Python 3.13 had no license class. The owner gave a permission for one time to add it, and the agent read `lib/python3.13/LICENSE.txt` of the build (main license `PSF-2.0`), changed one row of DEC 84c37f7d-08cb-457d-8ab3-1db37dba9bc9 (entry of 05:20:47), added `PSF-2.0` to `tools/license/permitted-licenses.txt`, and added the fixture `47-psf2.cdx.json`. `just test-license-gate` shows 47 ok and 0 failed.

### Decisions Made

<!-- Newest entry first -- prepend new entries directly below this comment. -->

#### 2026-11-04 05:33:00.000Z - Choices of the implementation (the owner can change them)

1. `make_python_env <lock-name>` has one argument. The folder of the lock files is `tools/python/`, and the variable `PYTHON_LOCK_DIR` sets another folder (the self-tests use it, in the same way as `SBOM_TOOL_DIR`).
2. `PYTHON_VERSION=3.13` is the minor version, and the gates start `uv venv --python 3.13`. The agent did not add `--python-preference only-managed`, so uv can use a 3.13 of the system.
3. `tools/python/` may have only the three lock files, `README.md` and `make-locks.sh`. A file such as `pip.conf` could change the index, so `just check-pins` stops for it.
4. `make-locks.sh` keeps the versions of the dependencies of the lock files that exist, and `--upgrade` takes the newest versions. A version change of a tool in `tools/versions.env` changes only what the new version needs.
5. `check_pins.py` shows the first 5 problems of a lock file and the number of the others, because one broken entry gives a problem for each of its hash lines.
6. `uv pip install` has no `--no-deps`: with `--require-hashes`, uv stops for a dependency that is not in the lock file, which is the check that the plan wants.

#### 2026-11-04 05:22:07.000Z - Choices of the plan (the owner can change them)

The owner decided: one lock file for each tool (A), remove the checksum keys of the Python tools (B), Python 3.13 (C), and the agent may make the FEAT and the branch (D). The agent chose the rest: the locks are `--universal` (valid for each platform, and not only for linux-x64) and `--only-binary :all:` (no source build). The script writes the input file from `tools/versions.env` in a temporary folder, so the repository has no second copy of the version. `check_pins.py` reads the lock files as text and does not start uv.

### Related PRs / Commits

- GitHub issue #22.

- Pull request #27 (open, `Closes #22`): `feat-22-python-tools-lockfile` to `dev`.

- Pull requests #28 and #29 (throwaway, closed, not merged).
