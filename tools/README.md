# tools

The tools of the toolchain (feat-5-foundation-monorepo-ci).

| Path | Content |
|---|---|
| `versions.env` | The versions of the tools, and the checksums of the tools that the install scripts download. One source of truth (REQ-003) |
| `gates/` | The scripts of the gates, with a README and the self-tests. The `justfile` starts them. `just check-pins` also checks `sbom/`, `spectral/`, `breaking/` and `python/` against `versions.env` |
| `sbom/` | A small pnpm project with a lock file for the SBOM tool cdxgen (feat-16-cdxgen-lockfile). `sbom.sh` installs cdxgen from it. The README has the procedure to change the version |
| `spectral/` | A small pnpm project with a lock file for the OpenAPI linter Spectral (feat-6-contracts-openapi-pipeline). `lint.sh` installs Spectral from it, and `just check-pins` checks it. It is not in the SBOM (rule A). The README has the procedure to change the version |
| `breaking/` | The ignore file for the gate for breaking changes (`breaking-changes-ignore.txt`, no entry now) and the file `checksums.txt` of the release of oasdiff (`oasdiff-checksums.txt`, the second place of the pin). `just breaking-changes` uses them, and `just check-pins` checks the pin. The README has the format of an entry, the rule for the version number and the procedure to change the version of oasdiff (feat-6-contracts-openapi-pipeline) |
| `lint/` | The rules of the linter (`ruleset.yaml`) and the bad OpenAPI files that test them (`fixtures/`). `just lint` uses the rules, and `just test-lint-gate` uses the fixtures |
| `python/` | The lock files with hashes of the Python tools of the gates (specmgr, PyYAML, `license-expression`), and the script that makes them (feat-22-python-tools-lockfile). The gates install the tools from them. The README has the procedure to change a version |
| `license/` | The list of permitted licenses, the table of names, the list of allowed actions and the fixtures for the test of the license gate |

The install scripts for the machine of the author are not in this folder. They are in `.specmgr/feat/feat-5-foundation-monorepo-ci/bin/`, with a README. CI does not use them.

A change in this folder needs the review of a code owner (see `.github/CODEOWNERS`).
