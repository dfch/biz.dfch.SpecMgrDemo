# tools/gates

The scripts of the gates (feat-5-foundation-monorepo-ci). Each script has a recipe in the `justfile`, and CI starts only the recipe (`.github/workflows/ci.yml`). Run `just --list` to see the recipes.

| Recipe | Script | Task | What it does |
|---|---|---|---|
| `just validate` | `validate-docs.sh <base>` | 130.110 | Runs `specmgr lint` for the Markdown files under `docs/` and `.specmgr/` that changed since the merge base of `<base>` (with the working tree). Skips deleted files. Passes if no document changed |
| `just commit-check` | `commit-check.sh <base>` | 130.120 | Each commit in `<base>..HEAD` (without merge commits) must have the subject `type(feat-N): subject`. `commit-check.sh --message "<subject>"` checks one subject |
| `just sbom` | `sbom.sh <dir>` | 130.130 | Writes the CycloneDX files of the backend (Maven) and the frontend (pnpm) to `<dir>`. If no manifest exists, it writes an SBOM with no component. It stops for a manifest outside the scanned set, for a Maven project with no `mvnw`, for an SBOM with no component when the manifests declare dependencies, and for a checksum of a tool that is not the pinned one (see "Rules of the findings") |
| `just license-check` | `license-check.sh <sbom-dir> <list>` | 130.130 | Compares the licenses in the SBOM files with `tools/license/permitted-licenses.txt` (with `license_check.py` and the library `license-expression`). Stops for a license that is not permitted or not known |
| `just check-workflows` | `check-workflows.sh <justfile> <dir> [<required-setup>]` | 130.140 | Each `run:` step in a workflow is exactly `just <recipe>` with a recipe in the `justfile`. The trigger, the permissions, the keys, `if:` and the setup actions of each job are as the gate wants them (see "Rules of the findings") |
| `just check-pins` | `check-pins.sh <versions.env> <dir> [<actions>]` | 130.142 | Each `uses:` has a full SHA and a comment with the name and the tag, is in `tools/license/allowed-actions.txt`, and the versions of the setup actions are the same as in `tools/versions.env`. A Maven Wrapper must have the pinned Maven version and a `distributionSha256Sum`, and a project with a `pom.xml` must have a wrapper |
| `just check-sudo` | `check-sudo.sh <path>...` | 130.145 | No script, `justfile` or workflow has `sudo` as a command |
| `just test-license-gate` | `test-license-gate.sh` | 130.135 | Tests the license gate with the fixtures in `tools/license/fixtures/` |
| `just test-gates` | `selftest.sh` | 130.100 to 130.145 | Tests all gates with good and bad input. It also runs `test-license-gate` |

## The base of the comparison

`just validate` and `just commit-check` compare with the branch that the pull request goes to. The variable `base` at the top of the `justfile` gives it: `origin/` and the value of `GITHUB_BASE_REF` if that variable is set and not empty, and `origin/dev` if not. In GitHub Actions, `GITHUB_BASE_REF` is a default variable of the runner (the target branch of the pull request), so the workflow needs no `env:` (the gate `check-workflows` does not allow it). `actions/checkout` with `fetch-depth: 0` fetches all branches, so `origin/dev` and `origin/main` are in the clone. On your machine, `GITHUB_BASE_REF=main just commit-check` compares with `origin/main`. Check the value with `just --evaluate base`.

Release case: for a pull request from `dev` to `main`, the range `origin/main..HEAD` has each commit of `dev` that is not in `main`, also old commits. The gate does not skip a commit that is not correct. Merge a release with a merge commit (not squash and not rebase), so that the next release range has only the new commits. See `branch-protection.md` in the folder of feat-5 and the plan.

Each script returns the exit code 0 if the gate passes. It returns another code if the gate stops. The scripts that read a workflow or an SBOM return 2 if a file is wrong and the gate cannot decide.

## Tools

The gates need `git`, `bash`, `uv` and `just`. `uv` starts the Python tools of a gate. The versions of the tools are in `tools/versions.env`, and the scripts read them from there:

| Gate | Tool | Keys in `versions.env` (version, checksum) |
|---|---|---|
| `validate` | specmgr (PyPI package `biz-dfch-specmgr`, extra `mcp`), installed in a temporary virtual environment | `SPECMGR_VERSION`, `SPECMGR_SHA256` (the wheel) |
| `license-check` | `license-expression` and `boolean.py`, installed in a temporary virtual environment | `LICENSE_EXPRESSION_VERSION`, `LICENSE_EXPRESSION_SHA256`, `BOOLEAN_PY_VERSION`, `BOOLEAN_PY_SHA256` (the wheels) |
| `check-workflows`, `check-pins` | PyYAML, installed in a temporary virtual environment | `PYYAML_VERSION`, `PYYAML_SHA256` (the source archive) |
| `sbom` | `cyclonedx-maven-plugin` with `mvnw` (if a `pom.xml` exists), `@cyclonedx/cdxgen` from `tools/sbom/` (if `frontend/` has a manifest) | `CYCLONEDX_MAVEN_PLUGIN_VERSION`, `CYCLONEDX_MAVEN_PLUGIN_SHA256` (the jar), `CDXGEN_VERSION`, `CDXGEN_INTEGRITY` (the npm package) |

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
- So `just check-pins` and `just sbom` fail on purpose when a `pom.xml` exists and the wrapper does not. feat-6-contracts-openapi-pipeline must add `mvnw` with the pinned Maven version and the sha256 of the Maven download. The sha256 of `apache-maven-3.10.0-bin.zip` is `1f6d9909266510f039f59aa0e13dcd2c66da85f043e56276e41f2918f8bddaff` (the agent computed it from a download whose sha512 is the one on Maven Central; Maven Central has no `.sha256` file for it). Maven Central has the sha512 only, so the person that adds the wrapper must check the value again.

### G2: the checksums of the tools that the gates install

The versions are pinned, and the keys in `tools/versions.env` have the checksums. The gates check them at run time. Only the direct artifact is checked. The dependencies of the direct artifact are not checked.

| Tool | How | What is not checked |
|---|---|---|
| `license-expression` and `boolean.py` (wheels) | `uv pip install --require-hashes` in a temporary virtual environment (`make_python_env` in `_lib.sh`) | Nothing: `boolean.py` is the only dependency, and it has a hash |
| PyYAML (source archive) | `uv pip install --require-hashes`. uv takes the file with the hash, so it builds the source archive | The build tools of that build (`setuptools` and others) |
| specmgr (wheel) | `uv pip install --verify-hashes`. uv checks the packages that have a hash | The 40 packages that specmgr needs |
| `@cyclonedx/cdxgen` | `sbom.sh` installs it from the lock file `tools/sbom/pnpm-lock.yaml` with `pnpm install --frozen-lockfile --ignore-scripts`. pnpm checks the integrity value of cdxgen and of all its dependencies against the lock file, and `sbom.sh` stops if the installed version is not `CDXGEN_VERSION` (feat-16-cdxgen-lockfile) | An optional dependency of cdxgen that has a wrong integrity value in the lock file: pnpm does not install it and does not stop |
| `cyclonedx-maven-plugin` (jar) | The script starts the plugin with `-Dcyclonedx.skip=true` (the plugin loads and does nothing), and compares the sha256 of the jar in the local repository with `CYCLONEDX_MAVEN_PLUGIN_SHA256`. Then it starts the real goal | The dependencies of the plugin |

`UV_VERSION` has no checksum (the action `astral-sh/setup-uv` downloads uv), and the GitHub Actions are pinned to a commit SHA. The files of the JDK, Maven, Node, pnpm and just on the machine of the author have checksums in the install scripts.

## Files

- `_lib.sh`: shared shell functions (read a version from `tools/versions.env`, install a Python tool with checksums, list the manifests of the project).
- `_workflow.py`, `check_workflows.py`, `check_pins.py`, `license_check.py`, `sbom_check.py`: the Python code of the gates. The `.sh` file with the same name starts it.
- `required-setup.txt`: the jobs of the workflows and the actions of each job (`check-workflows.sh` reads it).
- `fixtures/`: input for the self-test of `check-sudo.sh`. The files have the extension `.fixture`, so that no gate reads them as a script.

A change in this folder needs the review of a code owner (see `.github/CODEOWNERS`). The scripts do not use `sudo` (REQ-008).

## Limits

- The check for `sudo` is a check of the text. It does not see a word that a script builds from parts.
- The commit check does not accept the messages that git makes (`Revert "..."`, `fixup! ...`). Write `revert(feat-N): ...`, and squash the fixup commits.
- `sbom.sh` is not tested in `just test-gates` with real Maven and pnpm manifests. The test uses stubs. The agent ran it once by hand with a real Maven Wrapper and a real `pnpm` workspace (see the plan of feat-5). feat-6-contracts-openapi-pipeline gives the manifests and the real test.
- The gates do not check the inputs of a `uses:` step other than the versions of the setup actions (for example `with:` of `actions/checkout`), the value of `runs-on`, and the `<modules>` of a `pom.xml`.
- The checksums cover the direct artifact only (see G2 above). The PyYAML build and the dependencies of specmgr and the Maven plugin are not checked. The dependencies of cdxgen are checked by its lock file.
