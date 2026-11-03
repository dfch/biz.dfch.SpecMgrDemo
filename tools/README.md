# tools

The tools of the toolchain (feat-5-foundation-monorepo-ci).

| Path | Content |
|---|---|
| `versions.env` | The versions and checksums of the tools. One source of truth (REQ-003) |
| `gates/` | The scripts of the gates. The `justfile` starts them |
| `license/` | The list of permitted licenses and the fixtures for the test of the license gate |

The install scripts for the machine of the author are not in this folder. They are in `.specmgr/feat/feat-5-foundation-monorepo-ci/bin/`, with a README. CI does not use them.

A change in this folder needs the review of a code owner (see `.github/CODEOWNERS`).
