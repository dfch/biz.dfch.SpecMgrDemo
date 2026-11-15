# tools/security: the pins of the security tools

This folder has the vendor files of the releases of OSV-Scanner and gitleaks. They are the second place of the
pin of each tool. The tools are binaries that the security gates will download. The recipes and the install scripts
come in Phase 120 of `feat-8-traceability-security-gates`. This folder has the pins only.

Plan: FEAT `feat-8-traceability-security-gates` (GitHub issue #8), Task 100.150 (REQ-004, ACC-006).

zizmor is the third security tool. It is a Python package, so it has a lock file in `tools/python/zizmor.lock`
(see `tools/python/README.md`) and not a file in this folder.

## Files

| File | Content |
|---|---|
| `osv-scanner-checksums.txt` | The file `osv-scanner_SHA256SUMS` of the release of OSV-Scanner, without a change. The file of the pin is the line for `osv-scanner_linux_amd64`. This file is the binary (it is not an archive) |
| `gitleaks-checksums.txt` | The file `gitleaks_<version>_checksums.txt` of the release of gitleaks, without a change. The file of the pin is the line for `gitleaks_<version>_linux_x64.tar.gz` |
| `README.md` | This file |

## The two places and the check

| Place | What it has |
|---|---|
| `tools/versions.env` | `OSV_SCANNER_VERSION`, `OSV_SCANNER_SHA256`, `GITLEAKS_VERSION`, `GITLEAKS_SHA256` |
| `tools/security/*-checksums.txt` | the vendor line for the release file, with the sha256 |

`just check-pins` stops if the sha256 of the release file in `tools/versions.env` is not the sha256 in the vendor file.
It stops if the vendor file has no line, or more than one line, for the release file. For gitleaks the file name has
the version, so a change of only `GITLEAKS_VERSION` stops the check too. The name of the OSV-Scanner file has no
version. For OSV-Scanner, the sha256 is the tie between the version and the file. A change of only one place stops the
check. The check does not download a file. The real check of the download is in the install scripts of Phase 120
(the sha256 of the file against `tools/versions.env`, before the file is opened or started).

The pins are for Linux x86_64 only (a runner of GitHub, and the machine of the author), as the pin of oasdiff.
A new platform needs a new checksum and a change of `check_pins.py`.

## Procedure: change the version of a tool

Do all steps in one commit.

1. Read the release page of the tool. Get the vendor file of the checksums, and get the release file for Linux
   x86_64 (`osv-scanner_linux_amd64`, or `gitleaks_<version>_linux_x64.tar.gz`). Compare `sha256sum` of the file with the
   line of the vendor file and with the sha256 value that GitHub shows for the file (`gh api
   repos/<owner>/<repo>/releases/tags/<tag> --jq '.assets[] | {name, digest}'`). All three values must be the same.
2. Replace the vendor file in this folder with the new file (no change in the file).
3. Change the version and the sha256 of the tool in `tools/versions.env`.
4. Read the license file of the new release again (DEC 84c37f7d-08cb-457d-8ab3-1db37dba9bc9). Change the license table in
   the plan of the feature if the license changes.
5. Run `just check-pins`.

## What is pinned and what is not

- The sha256 shows that the file is the file of the release that the project read. It does not show that the file is safe.
- The vendor file is on the same server as the download. The value is as good as the release. The value of the digest of
  GitHub is a second source. Both agree for the pinned releases.
- OSV-Scanner and gitleaks have Go dependencies inside the binary. The project does not check them (rule A of
  DEC 84c37f7d-08cb-457d-8ab3-1db37dba9bc9: the tool does not go to users).
- The data that OSV-Scanner queries (the OSV database on the network) has no pin. See the license table of the plan.
