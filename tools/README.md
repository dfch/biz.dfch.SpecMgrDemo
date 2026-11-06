# tools

The tools of the toolchain (feat-5-foundation-monorepo-ci).

| Path | Content |
|---|---|
| `versions.env` | The versions of the tools, and the checksums of the tools that the install scripts download. One source of truth (REQ-003) |
| `gates/` | The scripts of the gates, with a README and the self-tests. The `justfile` starts them, and the CI jobs start the recipes (`required-setup.txt` lists the jobs and their actions). `just check-generated` is the gate for generated code (feat-6-contracts-openapi-pipeline). `just check-pins` also checks `sbom/`, `spectral/`, `breaking/`, `python/`, the version of the generator plugin in `backend/pom.xml` and the module `frontend/` against `versions.env` |
| `sbom/` | A small pnpm project with a lock file for the SBOM tool cdxgen (feat-16-cdxgen-lockfile). `sbom.sh` installs cdxgen from it. The file `cyclonedx-maven-plugin.sha256` is the second place of the pin of the jar of the SBOM plugin (feat-6-contracts-openapi-pipeline, ACC-011). The README has the procedure to change the version |
| `spectral/` | A small pnpm project with a lock file for the OpenAPI linter Spectral (feat-6-contracts-openapi-pipeline). `lint.sh` installs Spectral from it, and `just check-pins` checks it. It is not in the SBOM (rule A). The README has the procedure to change the version |
| `breaking/` | The ignore file for the gate for breaking changes (`breaking-changes-ignore.txt`, no entry now), the file `checksums.txt` of the release of oasdiff (`oasdiff-checksums.txt`, the second place of the pin) and the severity levels of the gate (`oasdiff-severity-levels.txt`, the level `err` for the removals of ACC-003). `just breaking-changes` uses them, and `just check-pins` checks the pin. oasdiff is installed for Linux x86_64 only: on another platform, `just breaking-changes` and `just test-gates` stop. The README has the format of an entry, the severity levels, the rule for the version number and the procedure to change the version of oasdiff (feat-6-contracts-openapi-pipeline) |
| `lint/` | The rules of the linter (`ruleset.yaml`) and the bad OpenAPI files that test them (`fixtures/`). `just lint` uses the rules, and `just test-lint-gate` uses the fixtures |
| `generate/` | The helper programs for the test of the generators (`just test-generate-gate`): the comparison of the lists of error codes (ACC-008). The file `openapi-generator-maven-plugin.sha256` is the second place of the pin of the jar of the generator plugin (ACC-011). The generators themselves are in `backend/pom.xml` (the plugin `openapi-generator-maven-plugin`) and in `frontend/` (Kubb), and the recipes are `generate`, `compile` and `api-docs` (feat-6-contracts-openapi-pipeline). The README has the details |
| `python/` | The lock files with hashes of the Python tools of the gates (specmgr, PyYAML, `license-expression`), and the script that makes them (feat-22-python-tools-lockfile). The gates install the tools from them. The README has the procedure to change a version |
| `license/` | The list of permitted licenses, the table of names, the list of allowed actions and the fixtures for the test of the license gate |

The install scripts for the machine of the author are not in this folder. They are in `.specmgr/feat/feat-5-foundation-monorepo-ci/bin/`, with a README. CI does not use them.

A change in this folder needs the review of a code owner (see `.github/CODEOWNERS`).
