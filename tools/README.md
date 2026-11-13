# tools

The tools of the project (`feat-5-foundation-monorepo-ci`).

| Path | Content |
|---|---|
| `versions.env` | The versions of the tools, and the checksums of the tools that the install scripts download. One source of truth (REQ-003) |
| `gates/` | The scripts of the gates, with its `README.md` and the self-tests. The `justfile` starts the scripts, and the CI jobs start the recipes (`required-setup.txt` lists the jobs and their actions). `just check-generated` is the gate for generated code (`feat-6-contracts-openapi-pipeline`). `just check-pins` also examines `sbom/`, `spectral/`, `breaking/`, `python/`, the version of the generator plug-in in `backend/pom.xml`, the versions of the test tools of `feat-7-verification-architecture-tools` in `backend/pom.xml` and in `frontend/package.json`, and the module `frontend/`, against `versions.env` |
| `sbom/` | A small pnpm project with a lock file for the SBOM tool cdxgen (`feat-16-cdxgen-lockfile`). `sbom.sh` installs cdxgen from it. The file `cyclonedx-maven-plugin.sha256` is the second file of the pin of the jar of the SBOM plug-in (`feat-6-contracts-openapi-pipeline`, ACC-011). Its `README.md` has the procedure to change the version |
| `spectral/` | A small pnpm project with a lock file for the OpenAPI linter Spectral (`feat-6-contracts-openapi-pipeline`). `lint.sh` installs Spectral from it, and `just check-pins` examines it. The project is not in the SBOM (rule A). Its `README.md` has the procedure to change the version |
| `breaking/` | The ignore file for the gate for breaking changes (`breaking-changes-ignore.txt`, no entry at this time). The file `oasdiff-checksums.txt` is the file `checksums.txt` of the release of oasdiff (the second file of the pin). The file `oasdiff-severity-levels.txt` has the severity levels of the gate (the level `err` for the removals of ACC-003). `just breaking-changes` uses the files, and `just check-pins` examines the pin. oasdiff is installed for Linux x86_64 only. On a platform that is not Linux x86_64, `just breaking-changes` and `just test-gates` stop. Its `README.md` has the format of an entry, the severity levels, the rule for the version number and the procedure to change the version of oasdiff (`feat-6-contracts-openapi-pipeline`) |
| `lint/` | The rules of the linter (`ruleset.yaml`) and the bad OpenAPI files that are the test of the rules (`fixtures/`). `just lint` uses the rules, and `just test-lint-gate` uses the fixtures |
| `generate/` | The helper programs for the test of the generators (`just test-generate-gate`): the programs compare the lists of error codes (ACC-008). The file `openapi-generator-maven-plugin.sha256` is the second file of the pin of the jar of the generator plug-in (ACC-011). The generators are in `backend/pom.xml` (the plug-in `openapi-generator-maven-plugin`) and in `frontend/` (Kubb). The recipes are `generate`, `compile` and `api-docs` (`feat-6-contracts-openapi-pipeline`). Its `README.md` has the details |
| `python/` | The lock files with hashes of the Python tools of the gates (specmgr, PyYAML, `license-expression`), and the script that makes the lock files (`feat-22-python-tools-lockfile`). The gates install the tools from the lock files. Its `README.md` has the procedure to change a version |
| `license/` | The list of permitted licenses, the table of names, the list of actions that the gate has as correct (the file `allowed-actions.txt`) and the fixtures for the test of the license gate |

The install scripts for the machine of the author are not in this folder. The scripts are in `.specmgr/feat/feat-5-foundation-monorepo-ci/bin/`, with a `README.md`. CI does not use the scripts.

A code owner reviews a change in this folder (see `.github/CODEOWNERS`).
