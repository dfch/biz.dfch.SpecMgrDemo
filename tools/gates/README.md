# tools/gates

The scripts of the gates (feat-5-foundation-monorepo-ci). Each script has a recipe in the `justfile`, and CI starts only the recipe (`.github/workflows/ci.yml`). Run `just --list` to see the recipes.

| Recipe | Script | Task | What it does |
|---|---|---|---|
| `just validate` | `validate-docs.sh <base>` | 130.110 | Runs `specmgr lint` for the Markdown files under `docs/` and `.specmgr/` that changed since the merge base of `<base>` (with the working tree). Skips deleted files. Passes if no document changed |
| `just commit-check` | `commit-check.sh <base>` | 130.120 | Each commit in `<base>..HEAD` (without merge commits) must have the subject `type(feat-N): subject`. `commit-check.sh --message "<subject>"` checks one subject |
| `just sbom` | `sbom.sh <dir>` | 130.130 | Writes the CycloneDX files of the backend (Maven) and the frontend (pnpm) to `<dir>`. If no manifest exists, it writes an SBOM with no component. It stops for a manifest outside the scanned set, for a Maven project with no `mvnw`, for an SBOM with no component when the manifests declare dependencies, and for a checksum of a tool that is not the pinned one (see "Rules of the findings") |
| `just license-check` | `license-check.sh <sbom-dir> <list>` | 130.130 | Compares the licenses in the SBOM files with `tools/license/permitted-licenses.txt` (with `license_check.py` and the library `license-expression`). Stops for a license that is not permitted or not known |
| `just check-workflows` | `check-workflows.sh <justfile> <dir> [<required-setup>]` | 130.140 | Each `run:` step in a workflow is exactly `just <recipe>` with a recipe in the `justfile`. The trigger, the permissions, the keys, `if:` and the setup actions of each job are as the gate wants them (see "Rules of the findings") |
| `just check-pins` | `check-pins.sh <versions.env> <dir> [<actions>]` | 130.142, feat-16 110.100, feat-22 120.100 | Each `uses:` has a full SHA and a comment with the name and the tag, is in `tools/license/allowed-actions.txt`, and the versions of the setup actions are the same as in `tools/versions.env`. A Maven Wrapper must have the pinned Maven version and a `distributionSha256Sum`, and a project with a `pom.xml` must have a wrapper. `tools/sbom/package.json` and `tools/sbom/pnpm-lock.yaml` must have the `CDXGEN_VERSION` and the `CDXGEN_INTEGRITY` of `versions.env`, one dependency only, and an integrity value for each package (see G2). The lock files in `tools/python/` must have exact pins with sha256 hashes only, and the version of each tool must be the one of `versions.env` (see G2) |
| `just check-sudo` | `check-sudo.sh <path>...` | 130.145 | No script, `justfile` or workflow has `sudo` as a command |
| `just test-license-gate` | `test-license-gate.sh` | 130.135 | Tests the license gate with the fixtures in `tools/license/fixtures/` |
| `just test-gates` | `selftest.sh` | 130.100 to 130.145 | Tests all gates with good and bad input. It also runs `test-license-gate` |

## The base of the comparison

`just validate` and `just commit-check` compare with the branch that the pull request goes to. The variable `base` at the top of the `justfile` gives it: `origin/` and the value of `GITHUB_BASE_REF` if that variable is set and not empty, and `origin/dev` if not. In GitHub Actions, `GITHUB_BASE_REF` is a default variable of the runner (the target branch of the pull request), so the workflow needs no `env:` (the gate `check-workflows` does not allow it). `actions/checkout` with `fetch-depth: 0` fetches all branches, so `origin/dev` and `origin/main` are in the clone. On your machine, `GITHUB_BASE_REF=main just commit-check` compares with `origin/main`. Check the value with `just --evaluate base`.

Release case: for a pull request from `dev` to `main`, the range `origin/main..HEAD` has each commit of `dev` that is not in `main`, also old commits. The gate does not skip a commit that is not correct. Merge a release with a merge commit (not squash and not rebase), so that the next release range has only the new commits. See `branch-protection.md` in the folder of feat-5 and the plan.

Each script returns the exit code 0 if the gate passes. It returns another code if the gate stops. The scripts that read a workflow or an SBOM return 2 if a file is wrong and the gate cannot decide.

## Tools

The gates need `git`, `bash`, `uv` and `just`. `uv` starts the Python tools of a gate. The versions of the tools are in `tools/versions.env`, and the scripts read them from there. The Python tools are installed from the lock files in `tools/python/` (see `tools/python/README.md`), with Python `PYTHON_VERSION`:

| Gate | Tool | Key in `versions.env` (version) | Lock file in `tools/python/` |
|---|---|---|---|
| `validate` | specmgr (PyPI package `biz-dfch-specmgr`, extra `mcp`), installed in a temporary virtual environment | `SPECMGR_VERSION` | `specmgr.lock` |
| `license-check` | `license-expression` and `boolean.py`, installed in a temporary virtual environment | `LICENSE_EXPRESSION_VERSION` | `license-expression.lock` |
| `check-workflows`, `check-pins` | PyYAML, installed in a temporary virtual environment | `PYYAML_VERSION` | `pyyaml.lock` |
| `sbom` | `cyclonedx-maven-plugin` with `mvnw` (if a `pom.xml` exists), `@cyclonedx/cdxgen` from `tools/sbom/` (if `frontend/` has a manifest) | `CYCLONEDX_MAVEN_PLUGIN_VERSION`, `CYCLONEDX_MAVEN_PLUGIN_SHA256` (the jar), `CDXGEN_VERSION`, `CDXGEN_INTEGRITY` (the npm package) | `tools/sbom/pnpm-lock.yaml` for cdxgen (feat-16-cdxgen-lockfile) |

## Rules of the findings of the review

These rules come from the post-implementation review of feat-5 (findings E1, E2, G1 and G2). Each rule has negative tests in `selftest.sh`.

### E1: a manifest that no gate scans (`sbom.sh`)

Before the change, `sbom.sh` scanned only `pom.xml`, `backend/pom.xml`, `frontend/package.json` and `frontend/pnpm-lock.yaml`. A manifest in another place gave an empty SBOM, and the license gate said PASS with 0 components. Now:

- **Part a.** The script stops (exit code 1) and gives the path if one of `pom.xml`, `package.json`, `pnpm-lock.yaml` or `pnpm-workspace.yaml` is in the repository outside the scanned set:
  - Maven: `pom.xml` in the root, or `backend/pom.xml` if there is no root `pom.xml`. Each `pom.xml` below `backend/` is a module that the aggregate BOM covers. A `pom.xml` in `model/`, in `frontend/` or in `backend/` with no `backend/pom.xml` (and no root `pom.xml`) stops the script.
  - Node: `frontend/package.json`, `frontend/pnpm-lock.yaml` and `frontend/pnpm-workspace.yaml`. A `package.json` below `frontend/` is covered only if `frontend/pnpm-workspace.yaml` and `frontend/pnpm-lock.yaml` both exist (a test with cdxgen 12.9.0 showed that it reads the packages of a workspace from the lock file, and that it does not read a nested `package.json` with no workspace). A `package.json` in the root or in `contracts/` stops the script.
  - The script does not enter `.git`, `node_modules`, `build` and `target` (at each level), and, from the root only, `.specmgr` (the folders of the features keep prototypes that are not part of the layout), `tools/license/fixtures` and `tools/gates/fixtures`.
  - Exclusion (feat-16-cdxgen-lockfile): the two files `tools/sbom/package.json` and `tools/sbom/pnpm-lock.yaml` are not manifests of the project. They are the lock file of the SBOM tool cdxgen (rule A: cdxgen does not go to users), so `sbom.sh` does not scan them and does not stop for them. `manifest_files` in `_lib.sh` skips these two paths, and not the folder. So `tools/sbom/pnpm-workspace.yaml`, a `package.json` in a sub-folder of `tools/sbom/`, each manifest in another folder of `tools/` (for example `tools/other/package.json`) and a `package.json` in the root still stop the script.
  - Limit: the script does not read the `<modules>` list of a `pom.xml` or the `packages` list of a workspace. It assumes that a `pom.xml` below `backend/` is a module of the scanned one, and that a `package.json` below `frontend/` is in the workspace.
- **Part b.** `sbom_check.py` (standard library only) stops the script if a scanned `package.json` has an entry in `dependencies`, `devDependencies`, `optionalDependencies` or `peerDependencies`, or a scanned `pom.xml` has a `<dependency>` in the `<dependencies>` of the project or of a profile (not in `<dependencyManagement>` and not in a plugin), and the SBOM has no component (the `components` list, nested ones included).

### E2: the rest of the workflow (`check-workflows.sh`)

Before the change the gate read only the `run:` text, so a job with `if: false`, an `env:` with `PATH=...`, another trigger or `permissions: write-all` passed. Now `check_workflows.py` stops for each of these. The data is at the top of the script (`ALLOWED_TRIGGERS`, `ALLOWED_PERMISSIONS`, `WORKFLOW_KEYS`, `JOB_KEYS`, `RUN_STEP_KEYS`, `USES_STEP_KEYS`, `ALLOWED_IF`) and in `required-setup.txt`:

- The trigger is not exactly `pull_request` with the branches `dev` and `main` (in this order) and no other key (`paths`, `types`, `branches-ignore`). To change the branches, change the list in `ALLOWED_TRIGGERS` (one line). The `justfile` takes the base from `GITHUB_BASE_REF`, so it needs no change.
- `permissions:` of the workflow is not exactly `contents: read`, or a job has other `permissions:`.
- A key that is not allowed: `env`, `defaults`, `concurrency` (workflow); `if`, `continue-on-error`, `container`, `services`, `strategy`, `needs`, `env`, `outputs`, `defaults` (job); `shell`, `env`, `working-directory`, `continue-on-error`, `if` (step). The only `if:` is `${{ !cancelled() }}` on `actions/upload-artifact` in the job `license-check`.
- The `name:` of a job is not its identifier, a job has not exactly one `run:` step, or the identifier is not the recipe of that step (the jobs are the required status checks of the rulesets on `dev` and `main`).
- `required-setup.txt` (a data file, covered by CODEOWNERS through `/tools/`) lists each job of each workflow file and the actions (by name) that the job must have. A missing job, a job or a workflow file that is not in the file, and a job that lacks an action or has an extra one stop the gate. To add a job or an action, change this file first.

### G1: Maven in CI (`sbom.sh`, `check-pins.sh`)

REQ-003 wants the same Maven version in CI as in `tools/versions.env`. No Maven setup action is in the license table, so the Maven Wrapper (`mvnw`) pins Maven in the repository:

- `sbom.sh` starts the `mvnw` next to the scanned `pom.xml`. If there is no `mvnw`, it stops. It never starts the `mvn` of the runner.
- `check-pins.sh` looks for `.mvn/wrapper/maven-wrapper.properties` (not in the excluded folders). Its `distributionUrl` must have `apache-maven-<MAVEN_VERSION>-bin.zip` (or `.tar.gz`), and it must have a `distributionSha256Sum` (64 hexadecimal characters; the gate cannot compare it with `versions.env`, which has the sha512 of the tar.gz, so it checks that the value is there). A `pom.xml` with no wrapper stops the gate. With no `pom.xml` and no wrapper the gate passes and says "no Maven project".
- So `just check-pins` and `just sbom` fail on purpose when a `pom.xml` exists and the wrapper does not. feat-6-contracts-openapi-pipeline (Phase 105) added `backend/pom.xml`, `backend/mvnw` (Maven Wrapper 3.3.4, type `only-script`, no jar) and `backend/.mvn/wrapper/maven-wrapper.properties` with the pinned Maven version and the sha256 of the Maven download. The sha256 of `apache-maven-3.10.0-bin.zip` is `1f6d9909266510f039f59aa0e13dcd2c66da85f043e56276e41f2918f8bddaff`. Maven Central and Apache have no `.sha256` file for it, only a `.sha512` file. On 2026-11-04, the agent got the zip and its `.sha512` file from `repo.maven.apache.org`, from `archive.apache.org` and (the `.sha512` file) from `dlcdn.apache.org`. The three `.sha512` files are the same, the `sha512sum` of both zip files is that value, and the sha256 is the value above. The agent also checked the `.tar.gz` of the same release against `MAVEN_SHA512` of `tools/versions.env` (the same value). The person that changes the Maven version must do this again (see "Maven Wrapper" below).
- The Maven Wrapper checks the sha256 only for the zip. If `unzip` is not on the machine, `mvnw` 3.3.4 downloads the `.tar.gz` and compares it with the sha256 of the zip. It then stops with "Failed to validate Maven distribution SHA-256" (the agent ran this on 2026-11-04 with a PATH that has no `unzip`). So the check fails closed, but a machine with no `unzip` cannot use `mvnw`. The runners of GitHub and the machine of the author have `unzip`.

### G2: the checksums of the tools that the gates install

The versions are pinned, and the gates check the checksums at run time. For the Python tools, lock files in `tools/python/` check each package, with the dependencies (feat-22-python-tools-lockfile closes the Python part of this finding). For `@cyclonedx/cdxgen`, a lock file checks the direct package and all its dependencies (feat-16-cdxgen-lockfile closes the cdxgen part of this finding). For the Maven plugin, only the direct artifact is checked, and its dependencies are not checked (GitHub issue #23).

| Tool | How | What is not checked |
|---|---|---|
| specmgr, PyYAML, `license-expression` with `boolean.py` | `uv venv --python <PYTHON_VERSION>` and `uv pip install --require-hashes --only-binary :all: -r tools/python/<tool>.lock` in a temporary virtual environment (`make_python_env` in `_lib.sh`). The lock file has the exact version and the sha256 of each file of each package, with the dependencies (44 packages for specmgr, 1 for PyYAML, 2 for `license-expression`). uv stops for a wrong hash, for a package with no hash, and for a package that is not in the lock file. uv does not build a source archive. `just check-pins` compares the version of each tool in its lock file with `versions.env`, and stops for an entry that is not an exact pin with hashes (feat-22-python-tools-lockfile) | The hash shows that a file is the file in the lock file, not that it is safe. A lock file can be out of date. `uv`, the GitHub Actions and the Python build that uv downloads (see below) |
| `@cyclonedx/cdxgen` | `sbom.sh` installs it from the lock file `tools/sbom/pnpm-lock.yaml` with `pnpm install --frozen-lockfile --ignore-scripts`. pnpm checks the integrity value of cdxgen and of all its dependencies against the lock file, and `sbom.sh` stops if the installed version is not `CDXGEN_VERSION` (feat-16-cdxgen-lockfile) | An optional dependency of cdxgen (it has 21) that has a wrong integrity value in the lock file: pnpm logs `ERR_PNPM_TARBALL_INTEGRITY` and `optional dependency that could not be fetched`, does not install that package, and returns exit code 0. The package does not run, so no code of it is trusted. A required package with a wrong value stops the install. `just check-pins` cannot see this case |
| `cyclonedx-maven-plugin` (jar) | The script starts the plugin with `-Dcyclonedx.skip=true` (the plugin loads and does nothing), and compares the sha256 of the jar in the local repository with `CYCLONEDX_MAVEN_PLUGIN_SHA256`. Then it starts the real goal | The dependencies of the plugin |

**The pin check of the cdxgen project** (`check_pins.py`, function `check_sbom_tool`; `just check-pins` runs it for each pull request and needs no Node or pnpm, it reads the files with PyYAML). `tools/versions.env` is the one source of the version and the integrity value (`CDXGEN_VERSION`, `CDXGEN_INTEGRITY`). The check is always on, also if `frontend/` does not exist, and it fails closed. It stops (exit code 1) for each of these:

- The folder `tools/sbom/`, `package.json` or `pnpm-lock.yaml` does not exist, or the folder has a file that is not `package.json`, `pnpm-lock.yaml`, `README.md` or `node_modules` (a `.npmrc`, a `pnpm-workspace.yaml` or a `.pnpmfile.cjs` could change where pnpm gets the packages).
- `versions.env` has no `CDXGEN_VERSION` or `CDXGEN_INTEGRITY`, the version is not an exact version, or the integrity value is not a `sha512-...` value of npm.
- `package.json`: another version than `CDXGEN_VERSION`, a range or a tag (`^`, `~`, `>=`, `x`, `latest`, `next`, a URL), another or a second dependency, or a key that is not `name`, `private`, `description` or `dependencies` (this stops `devDependencies`, `optionalDependencies`, `peerDependencies`, `overrides`, `resolutions`, `pnpm`, `packageManager` and `scripts`). A key two times, a file that is not JSON and a file that is not an object also stop it.
- `pnpm-lock.yaml`: not exactly one YAML document with no key two times (a `packageManager` field makes a second document); a `lockfileVersion` that is not a text that starts with `9.`; a top-level key other than `lockfileVersion`, `settings`, `importers`, `packages` and `snapshots` (for example `overrides`); not exactly one importer `.` with exactly one direct dependency `@cyclonedx/cdxgen` whose `specifier` and `version` are `CDXGEN_VERSION`; not exactly one `@cyclonedx/cdxgen` in `packages`, or another integrity value for it than `CDXGEN_INTEGRITY`; a package with no integrity value, with an integrity value that is not sha256, sha384 or sha512, with a `resolution` that has a key other than `integrity` (`tarball`, `commit`, `repo`, `directory`: a package from another place than the registry), or with a key that is not `<name>@<exact version>`; a `snapshots` entry for a package that is not in `packages`. Anything that PyYAML cannot read stops it too.

A change of only one of the three places (`versions.env`, `package.json`, the lock file) stops the check (REQ-005). The self-test has a case for each of the places alone, for each rule above, and a positive case with all three places changed to the same value. The procedure to change the version is in `tools/sbom/README.md`. The real check of each tarball is the frozen install in `sbom.sh`: the pin check ties the lock file to `versions.env`, and the frozen install ties the install to the lock file.

`UV_VERSION` has no checksum (the action `astral-sh/setup-uv` downloads uv), and the GitHub Actions are pinned to a commit SHA. The files of the JDK, Maven, Node, pnpm and just on the machine of the author have checksums in the install scripts.

## Maven Wrapper

The wrapper is in `backend/` (feat-6-contracts-openapi-pipeline, Phase 105). It has no jar (`distributionType=only-script`, and `*.jar` is in `.gitignore`), and it has no `mvnw.cmd` (the project has no Windows build; the recipes need `bash`). To change the Maven version:

1. Change `MAVEN_VERSION` and `MAVEN_SHA512` in `tools/versions.env` (the sha512 of the `.tar.gz`, from the `.sha512` file of the release).
2. Make the files again with the wrapper plugin: in an empty folder, run `mvn org.apache.maven.plugins:maven-wrapper-plugin:3.3.4:wrapper -Dtype=only-script -Dmaven=<MAVEN_VERSION>`, and copy `mvnw` and `.mvn/wrapper/maven-wrapper.properties` to `backend/`. The plugin writes no `distributionSha256Sum`, so add the line by hand.
3. Get `apache-maven-<version>-bin.zip` and its `.sha512` file from Maven Central and from `archive.apache.org`. The two `.sha512` files must be the same, and `sha512sum` of the zip must give that value. Then `sha256sum` of the zip is the `distributionSha256Sum`. Do not copy the value from another place (not from the old properties file and not from this README).
4. `backend/mvnw` has the git mode 100755 (`git update-index --chmod=+x backend/mvnw`).
5. Run `just check-pins`, `just sbom` and `just license-check`.

## Files

- `_lib.sh`: shared shell functions (read a version from `tools/versions.env`, install a Python tool with checksums, list the manifests of the project).
- `_workflow.py`, `check_workflows.py`, `check_pins.py`, `license_check.py`, `sbom_check.py`: the Python code of the gates. The `.sh` file with the same name starts it.
- `../sbom/`: the pnpm project with the lock file of cdxgen (`package.json`, `pnpm-lock.yaml`, `README.md` with the procedure to change the version). It is not a script of a gate, but `sbom.sh` installs from it and `check_pins.py` checks it.
- `required-setup.txt`: the jobs of the workflows and the actions of each job (`check-workflows.sh` reads it).
- `fixtures/`: input for the self-test of `check-sudo.sh`. The files have the extension `.fixture`, so that no gate reads them as a script.

A change in this folder needs the review of a code owner (see `.github/CODEOWNERS`). The scripts do not use `sudo` (REQ-008).

## Limits

- The check for `sudo` is a check of the text. It does not see a word that a script builds from parts.
- The commit check does not accept the messages that git makes (`Revert "..."`, `fixup! ...`). Write `revert(feat-N): ...`, and squash the fixup commits.
- `sbom.sh` is not tested in `just test-gates` with real Maven and pnpm manifests. The test uses stubs. The first real run with the real `backend/pom.xml` and the real `backend/mvnw` is done (feat-6-contracts-openapi-pipeline, Task 105.110, 2026-11-04): `just check-pins`, `just sbom` and `just license-check` return exit code 0 on this repository. The `pom.xml` has no dependency, so the SBOM has 0 components, and this run did not check a license of a library. The real plugin writes an SBOM with no `components` key for a project with no dependency, and `license_check.py` stops for such a file. Now `sbom_check.py` writes `"components": []` to the file in the SBOM folder in this case (a `pom.xml` with no dependency only; the case has tests with stubs). A project with a dependency has not been run with `sbom.sh` in the repository yet. The phase 120 adds the dependencies of the generated code and runs the gate again. The real `frontend/` (pnpm) is not run either: the repository has no `frontend/package.json` yet. The agent ran `sbom.sh` once by hand with a real `pnpm` workspace (see the plan of feat-5), and the phase 100 of feat-6 ran it on a scratch module with libraries and a scratch `frontend/` (see the plan of feat-6).
- The first real run did not check these items: the dependencies of `cyclonedx-maven-plugin` and of the other Maven plugins (GitHub issue #23), the Maven distribution (`mvnw` checks only its sha256, the contents of `apache-maven-3.10.0-bin.zip` are not in the SBOM), and the other plugins that Maven 3.10.0 starts for `clean`, `compile`, `test` and `package` (the SBOM gate starts only the plugin `cyclonedx-maven-plugin`).
- The gates do not check the inputs of a `uses:` step other than the versions of the setup actions (for example `with:` of `actions/checkout`), the value of `runs-on`, and the `<modules>` of a `pom.xml`.
- The Python tools are checked with all their dependencies (see G2 above). `uv` itself (`UV_VERSION` has no checksum, the action `astral-sh/setup-uv` downloads it), the GitHub Actions (pinned by a commit SHA only) and the Python build that `uv` downloads (a managed Python 3.13, when the machine or the runner has none) are not checked by a hash of this project. The dependencies of the Maven plugin are not checked (GitHub issue #23). The dependencies of cdxgen are checked by its lock file, with one exception: a wrong integrity value of an optional dependency does not stop the install (pnpm does not install that package). The lock file does not check pnpm itself: pnpm is pinned by `PNPM_VERSION` (the install script and `pnpm/action-setup`).
