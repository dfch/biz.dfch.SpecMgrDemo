# tools/python: the lock files of the Python tools of the gates

This folder has one lock file for each Python tool that the gates install. A lock file has the exact
version and the sha256 of each file of each package, and also of the dependencies. The gates install from it
with `uv pip install --require-hashes --only-binary :all:` (`make_python_env` in `tools/gates/_lib.sh`). uv
stops if a file has another hash, if a package has no hash, or if a package is missing in the lock file.

The tools do not go to users (rule A of DEC 84c37f7d-08cb-457d-8ab3-1db37dba9bc9), so the licenses of the
packages in the lock files are not checked.

Plan: FEAT feat-22-python-tools-lockfile (GitHub issue #22). The plan has the facts and the decisions. It
closes the part of finding G2 (the review of feat-5-foundation-monorepo-ci) that is about the Python tools.

## Files

| File | Tool | Used by |
|---|---|---|
| `specmgr.lock` | specmgr with the extra `mcp` (`SPECMGR_VERSION`), 44 packages | `validate-docs.sh` (`just validate`) |
| `pyyaml.lock` | PyYAML (`PYYAML_VERSION`), 1 package | `check-workflows.sh`, `check-pins.sh` |
| `license-expression.lock` | `license-expression` (`LICENSE_EXPRESSION_VERSION`) and `boolean.py`, 2 packages | `license-check.sh` (`just license-check`) |
| `make-locks.sh` | The script that writes the three lock files | You, to change a version |

The lock files are for Python 3.13 (`PYTHON_VERSION` of `tools/versions.env`) and for all platforms
(`--universal`: the entries have markers, so an entry for Windows is in the file but is not installed on Linux).
All entries are wheels (`--only-binary :all:`). No gate builds a source archive.

Do not edit a lock file by hand. A file in this folder that is not in the table is not allowed in the lock
files: `just check-pins` stops for a URL, a path, a VCS source, an editable entry or an index option.

## The two places and the check

The version of a tool is in two places. `tools/versions.env` is the source. The lock file is a copy:

| Place | What it has |
|---|---|
| `tools/versions.env` | `SPECMGR_VERSION`, `PYYAML_VERSION`, `LICENSE_EXPRESSION_VERSION` and `PYTHON_VERSION` |
| `tools/python/<tool>.lock` | the entry `<tool>==<version>` and the hashes of all packages |

`just check-pins` (it runs in CI for each pull request) stops if the version of a tool in its lock file is not the
version in `tools/versions.env`, so a change of only one place does not pass. It also stops if a package has no
hash or no exact version, and for a source that is not allowed. The check reads the lock files as text. It
does not start uv, so the result does not depend on the version of uv.

## Procedure: change the version of a tool

Do all steps in one commit.

1. Change the version (for example `SPECMGR_VERSION`) in `tools/versions.env`.
2. Run `tools/python/make-locks.sh`. It needs uv and network access. The script keeps the versions of all
   dependencies that the lock files have now, and changes only what the new version needs.
3. Run `git diff tools/python/` and read it. A new dependency is a new package in the tool: check its license
   file if the tool goes to users (it does not at this time).
4. Run `just check-pins`, and then the gate of the tool (`just validate`, `just license-check` or
   `just check-workflows`).

To take the newest version of all dependencies (a security update, for example), run
`tools/python/make-locks.sh --upgrade` without a change in `tools/versions.env`.

To change `PYTHON_VERSION` to another minor version, change it in `tools/versions.env` and run
`tools/python/make-locks.sh --upgrade`, because the dependencies can need other wheels.

## Limits that stay

- The hash shows that a file is the file that the lock file has. It does not show that the file is safe.
- uv itself (`UV_VERSION` has no checksum, the action `astral-sh/setup-uv` downloads it), the GitHub Actions
  (pinned by a commit SHA only) and the Python build that uv downloads are not checked by a hash of this
  project.
- The lock files can be out of date. A person must run `make-locks.sh --upgrade`.
