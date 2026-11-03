# tools/gates

The scripts of the gates (feat-5-foundation-monorepo-ci). Each script has a recipe in the `justfile`, and CI starts only the recipe (`.github/workflows/ci.yml`). Run `just --list` to see the recipes.

| Recipe | Script | Task | What it does |
|---|---|---|---|
| `just validate` | `validate-docs.sh <base>` | 130.110 | Runs `specmgr lint` for the Markdown files under `docs/` and `.specmgr/` that changed since the merge base of `<base>` (with the working tree). Skips deleted files. Passes if no document changed |
| `just commit-check` | `commit-check.sh <base>` | 130.120 | Each commit in `<base>..HEAD` (without merge commits) must have the subject `type(feat-N): subject`. `commit-check.sh --message "<subject>"` checks one subject |
| `just sbom` | `sbom.sh <dir>` | 130.130 | Writes the CycloneDX files of the backend (Maven) and the frontend (pnpm) to `<dir>`. If no manifest exists, it writes an SBOM with no component |
| `just license-check` | `license-check.sh <sbom-dir> <list>` | 130.130 | Compares the licenses in the SBOM files with `tools/license/permitted-licenses.txt` (with `license_check.py` and the library `license-expression`). Stops for a license that is not permitted or not known |
| `just check-workflows` | `check-workflows.sh <justfile> <dir>` | 130.140 | Each `run:` step in a workflow is exactly `just <recipe>` with a recipe in the `justfile` |
| `just check-pins` | `check-pins.sh <versions.env> <dir> [<actions>]` | 130.142 | Each `uses:` has a full SHA and a comment with the name and the tag, is in `tools/license/allowed-actions.txt`, and the versions of the setup actions are the same as in `tools/versions.env` |
| `just check-sudo` | `check-sudo.sh <path>...` | 130.145 | No script, `justfile` or workflow has `sudo` as a command |
| `just test-license-gate` | `test-license-gate.sh` | 130.135 | Tests the license gate with the fixtures in `tools/license/fixtures/` |
| `just test-gates` | `selftest.sh` | 130.100 to 130.145 | Tests all gates with good and bad input. It also runs `test-license-gate` |

Each script returns the exit code 0 if the gate passes. It returns another code if the gate stops. The scripts that read a workflow or an SBOM return 2 if a file is wrong and the gate cannot decide.

## Tools

The gates need `git`, `bash`, `uv` and `just`. `uv` starts the Python tools of a gate. The versions of the tools are in `tools/versions.env`, and the scripts read them from there:

| Gate | Tool | Key in `versions.env` |
|---|---|---|
| `validate` | specmgr (PyPI package `biz-dfch-specmgr`, extra `mcp`), started with `uvx` | `SPECMGR_VERSION` |
| `license-check` | `license-expression` and `boolean.py`, started with `uv run --with` | `LICENSE_EXPRESSION_VERSION`, `BOOLEAN_PY_VERSION` |
| `check-workflows`, `check-pins` | PyYAML, started with `uv run --with` | `PYYAML_VERSION` |
| `sbom` | `cyclonedx-maven-plugin` (if a `pom.xml` exists), `@cyclonedx/cdxgen` with `pnpm dlx` (if `frontend/` has a manifest) | `CYCLONEDX_MAVEN_PLUGIN_VERSION`, `CDXGEN_VERSION` |

## Files

- `_lib.sh`: shared shell functions (read a version from `tools/versions.env`).
- `_workflow.py`, `check_workflows.py`, `check_pins.py`, `license_check.py`: the Python code of the gates. The `.sh` file with the same name starts it.
- `fixtures/`: input for the self-test of `check-sudo.sh`. The files have the extension `.fixture`, so that no gate reads them as a script.

A change in this folder needs the review of a code owner (see `.github/CODEOWNERS`). The scripts do not use `sudo` (REQ-008).

## Limits

- The check for `sudo` is a check of the text. It does not see a word that a script builds from parts.
- The commit check does not accept the messages that git makes (`Revert "..."`, `fixup! ...`). Write `revert(feat-N): ...`, and squash the fixup commits.
- `sbom.sh` is not tested with real Maven and pnpm manifests. The test uses stubs. feat-6-contracts-openapi-pipeline gives the manifests and the real test.
