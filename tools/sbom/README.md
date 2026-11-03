# tools/sbom: the SBOM tool cdxgen with a lock file

This folder is a small pnpm project. It has one purpose: it installs the SBOM tool
`@cyclonedx/cdxgen` from a lock file. `tools/gates/sbom.sh` uses it to make the SBOM of `frontend/`.
It is a tool of the gates. It does not go to users (rule A of DEC 84c37f7d-08cb-457d-8ab3-1db37dba9bc9),
and `sbom.sh` does not scan it.

Plan: FEAT feat-16-cdxgen-lockfile (GitHub issue #16). The plan has the facts and the decisions.

## Files

| File | Content |
|---|---|
| `package.json` | One dependency: `@cyclonedx/cdxgen` in the exact version `CDXGEN_VERSION` of `tools/versions.env` (no range). It has no `packageManager` field (this field changes the layout of the lock file). |
| `pnpm-lock.yaml` | The lock file (`lockfileVersion: '9.0'`) that the pinned pnpm (`PNPM_VERSION` of `tools/versions.env`) writes. Each package has a `resolution.integrity` value. |
| `README.md` | This file. |

`node_modules/` is in `.gitignore`. Do not commit it.

## Install

`sbom.sh` runs this command in this folder when it scans a Node manifest:

```bash
pnpm install --frozen-lockfile --ignore-scripts
```

- `--frozen-lockfile`: pnpm stops if `package.json` and the lock file are not the same. pnpm checks the
  integrity value of each tarball (cdxgen and all its dependencies) against the lock file.
- `--ignore-scripts`: no package runs an install script. No package of the install has one, so cdxgen runs.

Then `sbom.sh` checks that the installed version of cdxgen is `CDXGEN_VERSION`, and starts
`node_modules/.bin/cdxgen`.

## Change the version of cdxgen

The full procedure and its check (`just check-pins`) are added in Phase 110 of feat-16-cdxgen-lockfile.
In short, change all three places in one commit:

1. `CDXGEN_VERSION` and `CDXGEN_INTEGRITY` in `tools/versions.env`.
2. The version in `tools/sbom/package.json`.
3. A new lock file that the pinned pnpm writes (`source ~/.config/biz.dfch.SpecMgrDemo/env.sh`, check
   that `pnpm --version` is `PNPM_VERSION`, delete `pnpm-lock.yaml`, then run
   `pnpm install --lockfile-only` in this folder).
