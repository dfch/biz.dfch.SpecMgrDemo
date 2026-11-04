# tools

The tools of the toolchain (feat-5-foundation-monorepo-ci).

| Path | Content |
|---|---|
| `versions.env` | The versions of the tools, and the checksums of the tools that the install scripts download. One source of truth (REQ-003) |
| `gates/` | The scripts of the gates, with a README and the self-tests. The `justfile` starts them. `just check-pins` also checks `sbom/` and `python/` against `versions.env` |
| `sbom/` | A small pnpm project with a lock file for the SBOM tool cdxgen (feat-16-cdxgen-lockfile). `sbom.sh` installs cdxgen from it. The README has the procedure to change the version |
| `python/` | The lock files with hashes of the Python tools of the gates (specmgr, PyYAML, `license-expression`), and the script that makes them (feat-22-python-tools-lockfile). The gates install the tools from them. The README has the procedure to change a version |
| `license/` | The list of permitted licenses, the table of names, the list of allowed actions and the fixtures for the test of the license gate |

The install scripts for the machine of the author are not in this folder. They are in `.specmgr/feat/feat-5-foundation-monorepo-ci/bin/`, with a README. CI does not use them.

A change in this folder needs the review of a code owner (see `.github/CODEOWNERS`).
