# tools/spectral: the OpenAPI linter Spectral with a lock file

This folder is a small pnpm project. It has one purpose: it installs the OpenAPI linter
`@stoplight/spectral-cli` from a lock file. `tools/gates/lint.sh` (the recipe `just lint`) uses it.
It is a tool of the gates. It does not go to users (rule A of DEC 84c37f7d-08cb-457d-8ab3-1db37dba9bc9),
and `sbom.sh` does not scan it. The tree of Spectral has packages with the license `Unlicense`. The
DEC does not list this license. Rule A has the rule that the check examines only the one license of the tool
(Apache-2.0, Permitted). The rules of the linter are not in this folder. They are in `tools/lint/`.

Plan: FEAT `feat-6-contracts-openapi-pipeline` (GitHub issue #6), Task 110.110. The form is the one of
`tools/sbom/` (`feat-16-cdxgen-lockfile`): the lock file pins Spectral and each package that the project
has as necessary.

## Files

| File | Content |
|---|---|
| `package.json` | One dependency: `@stoplight/spectral-cli` in the one version value `SPECTRAL_VERSION` of `tools/versions.env` (no range). It has no other key that changes the install. It has no other dependency, no `overrides`, no `pnpm` value and no `packageManager` field. The field `packageManager` changes the layout of the lock file. |
| `pnpm-lock.yaml` | The lock file (`lockfileVersion: '9.0'`) that the pinned pnpm (`PNPM_VERSION` of `tools/versions.env`) writes. It has one YAML document. Each package has a `resolution.integrity` value. No package comes from a position that is not the npm registry. |
| `README.md` | This file. |

No other file is in this folder (`node_modules/` is the install, and it is in `.gitignore`: do not
commit it). A file such as `.npmrc`, `pnpm-workspace.yaml` or `.pnpmfile.cjs` can change the position
from which pnpm gets the packages. `just check-pins` stops for such a file. The ruleset is in
`tools/lint/` for this cause.

## The three files and the check

The version and the integrity value of Spectral are in three files. `tools/versions.env` is the source. The
other two are copies. `just check-pins` (it operates in CI for each pull request) compares them with it:

| Position | Its content |
|---|---|
| `tools/versions.env` | `SPECTRAL_VERSION` and `SPECTRAL_INTEGRITY` (the value of `dist.integrity` of the npm package) |
| `tools/spectral/package.json` | `"@stoplight/spectral-cli": "<SPECTRAL_VERSION>"` as the only dependency |
| `tools/spectral/pnpm-lock.yaml` | one importer `.` with one direct dependency (Spectral, `specifier` and `version` are `SPECTRAL_VERSION`), the package `@stoplight/spectral-cli@<SPECTRAL_VERSION>` with the integrity value `SPECTRAL_INTEGRITY`, and an integrity value for each other package |

`just check-pins` stops if one of the three files is not the same as the others. A change of only one
file stops the check. The gate also stops for a second dependency or a different key in `package.json`. It
stops for a package in the lock file that has no integrity value or that has a source that is not the
registry (a link to a package file, git, a folder). It stops for a file in this folder that is not one of the
files in the table above. The check is the same as for cdxgen (`check_pnpm_tool` in
`tools/gates/check_pins.py`, see `tools/gates/README.md`, rule G2).

## Install

`lint.sh` starts this command in this folder:

```bash
pnpm install --frozen-lockfile --ignore-scripts
```

- `--frozen-lockfile`: pnpm stops if `package.json` and the lock file are not the same. pnpm compares the
  integrity value of each package file (Spectral and all its dependencies) against the lock file.
- `--ignore-scripts`: no package starts an install script. The package `@scarf/scarf` (Apache-2.0, a
  dependency of Spectral) has a `postinstall` script that makes a report of the install. The files of
  Spectral do not use it. The script is not necessary. `--ignore-scripts` stops it.

Then `lint.sh` examines that the installed version of Spectral is `SPECTRAL_VERSION`. It starts
`node_modules/.bin/spectral`. Spectral has Node as necessary (`engines`: `^22.0 || >= 24.0`, the pinned
Node 26 is correct) and no Java.

Limit: as for cdxgen, a different integrity value of an OPTIONAL dependency does not stop the install
(pnpm logs the error, does not install that package, and gives exit code 0). A package with a different
value is not installed and does not operate. A required package with a different value stops the install.
The recipe `just test-lint-gate` has the test of the frozen install, with a lock file that does not fit
`package.json`.

## Change the version of Spectral

Change all three files in **one commit**. `SPECTRAL_VERSION` is `<v>` in this section.

1. **Read the license of the new version first.** Rule A applies (Spectral does not go to users. The
   check examines only the one license of the tool): read the license file of the release and not only the `license`
   field. For example: `npm pack @stoplight/spectral-cli@<v>` in a temporary folder, then `tar -xzf
   stoplight-spectral-cli-<v>.tgz package/LICENSE package/package.json` and read the two files. The
   license must be in the class Permitted in the DEC (at this time: Apache-2.0). If it is not, stop and
   tell the owner. Write the result in the plan of the feature that does the change.
2. **Use the pinned tools.** Start `source ~/.config/biz.dfch.SpecMgrDemo/env.sh`. Make sure that `pnpm
   --version` is `PNPM_VERSION` of `tools/versions.env`. The pinned pnpm must write the lock file.
3. **Version and integrity value in `tools/versions.env`.** Read the integrity value from the registry,
   and write the two values:

   ```bash
   pnpm view @stoplight/spectral-cli@<v> dist.integrity
```

```
   SPECTRAL_VERSION=<v>
   SPECTRAL_INTEGRITY=<the value of the command, it starts with sha512->
```

   The version is the one value (no `^`, no `~`, no tag). Compare the value with the sha512 of the
   package file if you can (`openssl dgst -sha512 -binary <file>.tgz | base64 -w0`).
4. **Version in `tools/spectral/package.json`.** Write `<v>` as the version of the one dependency
   `@stoplight/spectral-cli`. Do not add a different dependency or a different key.
5. **New lock file, written by the pinned pnpm.** In this folder:

   ```bash
   cd tools/spectral
   rm pnpm-lock.yaml
   pnpm install --lockfile-only
   cd ../..
```

   Look at `git diff tools/spectral/pnpm-lock.yaml`: it must have the new version of Spectral and the
   packages that changed with it. It must have no `tarball`, `repo` or `directory` entry.
6. **Start the recipes:**

   ```bash
   just check-pins        # the three files have the same version and the same integrity value
   just lint              # the file of the project gives exit code 0
   just test-lint-gate    # the rules stop each bad file (a new version can change a rule of spectral:oas)
   just test-gates
```
7. **One commit** with the three changed files (`tools/versions.env`, `tools/spectral/package.json`,
   `tools/spectral/pnpm-lock.yaml`), for example `build(feat-N): update Spectral to <v>`. Do not commit
   `node_modules/`. `CODEOWNERS` covers `tools/`. The owner must review the pull request.

If the version in `PNPM_VERSION` changes, write the lock file again with the new pnpm in the same commit.
`lockfileVersion` can change. `just check-pins` accepts `9.x` only. If pnpm writes a different main
version number, change the check in `tools/gates/check_pins.py` and its tests first.

The stops of `just check-pins` (if you do not do all steps):

| Step missing | Result of `just check-pins` |
|---|---|
| 3 (`versions.env`) | STOP: `package.json` has a different version than `SPECTRAL_VERSION`, the lock file has a different Spectral than `SPECTRAL_VERSION` |
| 4 (package.json) | STOP: `package.json` has a different version than `SPECTRAL_VERSION` |
| 5 (lock file) | STOP: the importer, the package entry or the integrity value of Spectral in the lock file is not the one of `tools/versions.env` |
