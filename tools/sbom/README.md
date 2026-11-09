# tools/sbom: the SBOM tool cdxgen with a lock file

This folder is a small pnpm project. It has one purpose: it installs the SBOM tool
`@cyclonedx/cdxgen` from a lock file. `tools/gates/sbom.sh` uses it to make the SBOM of `frontend/`.
It is a tool of the gates. It does not go to users (rule A of DEC 84c37f7d-08cb-457d-8ab3-1db37dba9bc9),
and `sbom.sh` does not scan it.

Plan: FEAT `feat-16-cdxgen-lockfile` (GitHub issue #16). The plan has the facts and the decisions.
It closes the part of finding G2 (the review of `feat-5-foundation-monorepo-ci`) that is about cdxgen: the
lock file pins cdxgen and each package that the project has as necessary.

## Files

| File | Content |
|---|---|
| `package.json` | One dependency: `@cyclonedx/cdxgen` in the one version value `CDXGEN_VERSION` of `tools/versions.env` (no range). It has no other key that changes the install. It has no other dependency, no `overrides`, no `pnpm` value and no `packageManager` field. The field `packageManager` changes the layout of the lock file. |
| `pnpm-lock.yaml` | The lock file (`lockfileVersion: '9.0'`) that the pinned pnpm (`PNPM_VERSION` of `tools/versions.env`) writes. It has one YAML document. Each package has a `resolution.integrity` value. No package comes from a position that is not the npm registry. |
| `cyclonedx-maven-plugin.sha256` | The second file of the pin of the jar of the SBOM plug-in (`feat-6-contracts-openapi-pipeline`, ACC-011). One line with the sha256 of `cyclonedx-maven-plugin-<CYCLONEDX_MAVEN_PLUGIN_VERSION>.jar` on Maven Central (the value of `CYCLONEDX_MAVEN_PLUGIN_SHA256` in `tools/versions.env`). |
| `README.md` | This file. |

No other file is in this folder (`node_modules/` is the install, and it is in `.gitignore`: do not
commit it). A file such as `.npmrc`, `pnpm-workspace.yaml` or `.pnpmfile.cjs` can change the position
from which pnpm gets the packages. `just check-pins` stops for such a file.

## The three files and the check

The version and the integrity value of cdxgen are in three files. `tools/versions.env` is the source. The
other two are copies. `just check-pins` (it operates in CI for each pull request) compares them with it:

| Position | Its content |
|---|---|
| `tools/versions.env` | `CDXGEN_VERSION` and `CDXGEN_INTEGRITY` (the value of `dist.integrity` of the npm package) |
| `tools/sbom/package.json` | `"@cyclonedx/cdxgen": "<CDXGEN_VERSION>"` as the only dependency |
| `tools/sbom/pnpm-lock.yaml` | one importer `.` with one direct dependency (cdxgen, `specifier` and `version` are `CDXGEN_VERSION`), the package `@cyclonedx/cdxgen@<CDXGEN_VERSION>` with the integrity value `CDXGEN_INTEGRITY`, and an integrity value for each other package |

`just check-pins` stops if one of the three files is not the same as the others. A change of only one
file stops the check. The gate also stops for a second dependency or a different key in `package.json`. It
stops for a package in the lock file that has no integrity value or that has a source that is not the
registry (a link to a package file, git, a folder). It stops for a file in this folder that is not one of the
files in the table above. See `tools/gates/README.md` (rule G2) for the full list.

## The jar of the SBOM plug-in (the second file of the pin)

The jar of `cyclonedx-maven-plugin` is pinned by `CYCLONEDX_MAVEN_PLUGIN_VERSION` and
`CYCLONEDX_MAVEN_PLUGIN_SHA256` in `tools/versions.env`. The file `cyclonedx-maven-plugin.sha256` in this
folder is the second file of the sha256 (`feat-6-contracts-openapi-pipeline`, ACC-011, the same form as
`oasdiff-checksums.txt` is the second file of the pin of oasdiff). `just check-pins` compares the file
with `tools/versions.env`. A change of only one of the two files stops the check. `sbom.sh` compares the
jar in the local Maven repository with `CYCLONEDX_MAVEN_PLUGIN_SHA256` before the plug-in makes the
SBOM. To change the version of the plug-in: change `CYCLONEDX_MAVEN_PLUGIN_VERSION` and
`CYCLONEDX_MAVEN_PLUGIN_SHA256` in `tools/versions.env` and the file in this folder in one commit (the
value is the sha256 of the jar on Maven Central, checked against the `.sha1` file of Maven Central).

## Install

`sbom.sh` starts this command in this folder when it scans a Node manifest:

```bash
pnpm install --frozen-lockfile --ignore-scripts
```

- `--frozen-lockfile`: pnpm stops if `package.json` and the lock file are not the same. pnpm compares the
  integrity value of each package file (cdxgen and all its dependencies) against the lock file.
- `--ignore-scripts`: no package starts an install script. No package of the install has one. cdxgen operates.

Then `sbom.sh` examines that the installed version of cdxgen is `CDXGEN_VERSION`. It starts
`node_modules/.bin/cdxgen`.

Limit: an optional dependency of cdxgen (cdxgen has 21) that has a different integrity value in the lock
file does not stop the install. pnpm logs `ERR_PNPM_TARBALL_INTEGRITY`, does not install that package,
and gives exit code 0. A package with a different value is not installed and does not operate. The
project has no code of it. A required package with a different value stops the install. The recipe
`just test-gates` has the tests of `sbom.sh` and the lock file, with the pnpm that the project uses,
for the two cases (see the plan).

## Change the version of cdxgen

Change all three files in **one commit**. `CDXGEN_VERSION` is `<v>` in this section.

1. **Read the license of the new version first.** Rule A of DEC 84c37f7d-08cb-457d-8ab3-1db37dba9bc9
   applies (cdxgen does not go to users. The check examines only the one license of the tool), with the
   rules of the plan of `feat-5-foundation-monorepo-ci`: read the license file of the release and not only the
   `license` field. For example: `npm pack @cyclonedx/cdxgen@<v>` in a temporary folder, then `tar -xzf
   cyclonedx-cdxgen-<v>.tgz package/LICENSE package/package.json` and read the two files. The license
   must be in the class Permitted in the DEC (at this time: Apache-2.0). If it is not, stop and tell
   the owner. Write the result in the plan of the feature that does the change.
2. **Use the pinned tools.** Start `source ~/.config/biz.dfch.SpecMgrDemo/env.sh`. Make sure that `pnpm
   --version` is `PNPM_VERSION` of `tools/versions.env`. The pinned pnpm must write the lock file (a
   different pnpm can write a different layout).
3. **Version and integrity value in `tools/versions.env`.** Read the integrity value from the registry,
   and write the two values:

   ```bash
   pnpm view @cyclonedx/cdxgen@<v> dist.integrity
   ```

   ```
   CDXGEN_VERSION=<v>
   CDXGEN_INTEGRITY=<the value of the command, it starts with sha512->
   ```

   The version is the one value (no `^`, no `~`, no tag). Compare the value of the command with the
   checksum on the page of the release if you can (the value comes from the registry; the lock file and
   the check keep it from here).
4. **Version in `tools/sbom/package.json`.** Write `<v>` as the version of the one dependency
   `@cyclonedx/cdxgen`. Do not add a different dependency or a different key.
5. **New lock file, written by the pinned pnpm.** In this folder:

   ```bash
   cd tools/sbom
   rm pnpm-lock.yaml
   pnpm install --lockfile-only
   cd ../..
```

   `--lockfile-only` writes the lock file and does not install. With the same version and the same pnpm,
   the new file is the same as the file from before. Look at `git diff tools/sbom/pnpm-lock.yaml`:
   it must have the new version of cdxgen and the packages that changed with it. It must have no
   `tarball`, `repo` or `directory` entry.
6. **Start the recipes:**

   ```bash
   just check-pins    # the three files have the same version and the same integrity value
   just test-gates    # the gates and the self-tests
```

   For a test of the install at the end, start the frozen install in a clean copy of the three files
   (`pnpm install --frozen-lockfile --ignore-scripts`, then `node_modules/.bin/cdxgen --version`).
7. **One commit** with the three changed files (`tools/versions.env`, `tools/sbom/package.json`,
   `tools/sbom/pnpm-lock.yaml`), for example `build(feat-N): update cdxgen to <v>`. Do not commit
   `node_modules/`. `CODEOWNERS` covers `tools/`. The owner must review the pull request.

If the version in `PNPM_VERSION` changes, write the lock file again with the new pnpm in the same commit.
`lockfileVersion` can change. `just check-pins` accepts `9.x` only. If pnpm writes a different main
version number, change the check in `tools/gates/check_pins.py` and its tests first.

The stops of `just check-pins` (if you do not do all steps):

| Step missing | Result of `just check-pins` |
|---|---|
| 3 (`versions.env`) | STOP: `package.json` has a different version than `CDXGEN_VERSION`, the lock file has a different cdxgen than `CDXGEN_VERSION` |
| 4 (package.json) | STOP: `package.json` has a different version than `CDXGEN_VERSION` |
| 5 (lock file) | STOP: the importer, the package entry or the integrity value of cdxgen in the lock file is not the one of `tools/versions.env` |
