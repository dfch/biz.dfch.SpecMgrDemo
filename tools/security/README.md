# tools/security: the security gates (Gate 9) and the pins of the tools

This folder is the home of the security gates of `feat-8-traceability-security-gates` (GitHub issue #8, Phase 120, Gate 9
of DEC 361678a6-f941-473b-a058-1ba2bacf7d3d). It has the vendor files of the pins of OSV-Scanner and gitleaks, and the
allowlist of gitleaks. The scripts of the gates are in `tools/gates/` (see the section "The security gates" in
`tools/gates/README.md`).

The security tools run as **reports with no threshold** (REQ-005). The owner turns on a threshold later, from the baseline
(Phase 130). The feature sets no threshold and writes no baseline file.

## The recipes

| Recipe | Script | Tool | What it examines | Network |
|---|---|---|---|---|
| `just vuln-scan` | `tools/gates/vuln-scan.sh` | OSV-Scanner (`OSV_SCANNER_VERSION`, a binary in `build/tools/`) | The known vulnerabilities of the dependencies. The input is the SBOM files `build/sbom/*.cdx.json` (the recipe has `sbom` as a prerequisite) | Yes: api.osv.dev (the install needs GitHub for the first run) |
| `just secret-scan` | `tools/gates/secret-scan.sh` | gitleaks (`GITLEAKS_VERSION`, a binary in `build/tools/`) | Secrets in the files (a copy of the files that git knows) and in the history of the pull request (`<base>..HEAD`) | No (the install needs GitHub for the first run) |
| `just workflow-scan` | `tools/gates/workflow-scan.sh` | zizmor (`ZIZMOR_VERSION`, installed from `tools/python/zizmor.lock`) | The workflow files in `.github/workflows` | No (`--offline`; the install needs the package index for the first run) |
| `just test-security-gates` | `tools/gates/test-security-gates.sh` | all three, and stubs | The self-test of the three recipes and of the function that separates a finding from a failure of the tool (ACC-005) | The install of the real tools |

CodeQL is the fourth security tool. It is the hosted default setup of GitHub and has no recipe and no file in the
repository (see the plan, Phase 130, and the deviation in DEC 93a6d588-e002-4daf-9a47-45e2d77786e9).

The CI jobs have the names of the recipes (`vuln-scan`, `secret-scan`, `workflow-scan`, and `traceability` for Gate 2). The
job `vuln-scan` uses the network and has the timeout of 30 minutes. CodeQL has no job (no workflow file). The owner adds the
check names to the rulesets (`branch-protection.md` in the folder of feat-5-foundation-monorepo-ci).

## A finding and a failure of the tool

A report with no finding and a tool that did not run look the same to a reader, so the recipes keep the two cases apart.
One function does it for all three recipes (`security_classify` and `run_security_tool` in `tools/gates/_security.sh`).

| Case | Exit code of the recipe | What happens |
|---|---|---|
| The tool ran and has no finding | 0 | The line "no finding" and the summary |
| The tool ran and has findings | 0 | The tool prints its report, and the recipe prints "FINDINGS" and the summary. The recipe does not stop (no threshold) |
| The tool did not run to the end (no network, a file that cannot be read, a wrong configuration, a missing binary, a download with another checksum, a base that does not exist) | 1 | The recipe prints "FAILURE OF THE TOOL" with the exit code, and stops. There is no summary line |

The exit codes of the tools (checked for the pinned releases on 2026-11-15; the finding codes are the only codes that mean
"findings", each other non-zero code is a failure):

| Tool | Clean | Finding | Failure |
|---|---|---|---|
| OSV-Scanner 2.7.1 | 0 | 1 | 127 (a general error: no network, a file that cannot be read, a wrong flag), 128 (no packages found, for example an SBOM with no component), and each other code. Source: the page "Output" of the documentation, "Return Codes". The run without network prints a table with 0 packages and ends with 127 |
| gitleaks 8.30.1 | 0 | 2 (the script starts it with `--exit-code 2`) | 1 (a fatal error: a wrong config, a path that does not exist), 126 (a wrong flag), and each other code. The default exit code for "leaks found" is 1, which is also the code of a fatal error, so the default cannot separate the two |
| zizmor 1.32.0 | 0 | 11, 12, 13, 14 (the highest finding is informational, low, medium or high) | 1 (an error of the audit, for example a file that cannot be read), 2 (a wrong argument), 3 (no inputs collected), and each other code. Source: the page "Usage" of the documentation, "Exit codes" |

Two more checks make the separation safe:

- A finding code is accepted only if the output of the tool has the text of a finding, for gitleaks ("leaks found"). A crash
  of a Go program has the exit code 2, which is the finding code of gitleaks.
- An output with an `ERR` or `FTL` line is a failure, also with the exit code 0 or the finding code. gitleaks ends with exit
  code 0 and an `ERR` line if git cannot read the range of commits (`--log-opts`), and then it scans 0 commits.

A recipe with no input stops. It does not pass. A folder with no `*.cdx.json` file, a path that does not exist and a
workflow folder with no workflow (zizmor exit code 3) are failures. The same is true for an SBOM with no package (OSV-Scanner
exit code 128): the project then has no dependency, and the owner can change this rule when it happens.

## The form of the report

The report is the output of the tool and two lines of the script. The lines are in the log of the job and nowhere else (the
scripts write no file in the repository).

```
<the output of the tool>
[vuln-scan.sh] OSV-Scanner: FINDINGS (exit code 1). The output above is the report. The gate does not stop for a finding (no threshold).
[vuln-scan.sh] REPORT: Total 2 packages affected by 5 known vulnerabilities (0 Critical, 0 High, 5 Medium, 0 Low, 0 Unknown) from 1 ecosystem.
```

| Recipe | The summary line (`REPORT:`) | What the report names for each finding |
|---|---|---|
| `vuln-scan` | The `Total ... known vulnerabilities` line of OSV-Scanner (the packages, the vulnerabilities and the levels) | The OSV URL (the identifier), the CVSS value, the ecosystem, the package, the version, the fixed version and the SBOM file |
| `secret-scan` | `files: N finding(s); history <base>..HEAD: M finding(s)` | The rule, the file (relative to the repository), the line, the commit (history scan) and the fingerprint. The secret is redacted (`--redact`) |
| `workflow-scan` | The summary line of zizmor (`N findings (... ): X informational, Y low, Z medium, W high`) | The audit, the file with the line, the confidence and the documentation link |

## The data of OSV and the conditions of the deviation

OSV-Scanner sends package names, versions, ecosystems and file hashes (no source code) to api.osv.dev. The data of OSV.dev has
the licenses of its sources (for the packages of this project mainly the GitHub Advisory Database, CC-BY 4.0), and the owner
accepted a deviation for the use (DEC 93a6d588-e002-4daf-9a47-45e2d77786e9, the section of the OSV data, 2026-11-15). The
conditions apply to `vuln-scan`:

- The use is a report only. The recipe has no threshold and no automatic action.
- The repository keeps counts and finding identifiers only (the plan, the baseline). It keeps no copy of the records.
- The attribution is kept: the script prints the source (OSV.dev, https://osv.dev) and the license of the main source after
  the report, and this README names it.
- The script does not use the option `--licenses` of OSV-Scanner (the self-test examines the script for the option).
- If the condition ends, the recipe `vuln-scan` and its CI job are switched off until the owner decides again.

## gitleaks: what is scanned

`secret-scan.sh <base> <config>` runs two scans and decides after both:

1. The files. A copy of the files that git knows or that `.gitignore` does not ignore (`git ls-files --cached --others
   --exclude-standard`) goes to a temporary folder, and `gitleaks dir .` runs in it. A file that is not committed yet is
   scanned. `node_modules`, `target` and `build` are not in git, so they are not scanned.
2. The history of the pull request. `gitleaks git --log-opts <base>..HEAD` scans the commits that are in `HEAD` and not in
   the base. The base is the variable `base` of the `justfile` (`origin/dev`, or `origin/<GITHUB_BASE_REF>` in a pull
   request). The commits of the base are not scanned again.

A shallow clone has no history of the range. The script stops (exit code 1) if the base does not exist, or if there is no
merge base of the base and `HEAD` (a shallow clone). It does not scan the few commits that a shallow clone has: such a scan
would pass for a range that it did not see. The CI job needs `fetch-depth: 0` in `actions/checkout` (as `commit-check` and
`breaking-changes`). The case of a pull request that has no new commit (the range is empty) is a scan of 0 commits.

The options are `--redact` (the log of a public repository must not show a secret), `--exit-code 2`,
`--ignore-gitleaks-allow` (a comment `gitleaks:allow` in a file does not hide a finding) and `--gitleaks-ignore-path` with an
empty folder (a `.gitleaksignore` file does not hide a finding). The history scan runs on the git folder of the repository,
and not on the work tree, because gitleaks reads a `.gitleaksignore` file of the source folder of a scan and does not
honor the option there. So the allowlist is the one place that hides a finding.

### The allowlist

`gitleaks.toml` has the default rules (`useDefault = true`) and the allowlist. CODEOWNERS covers the file (the line for the
file, and the folder `/tools/`). Each entry of the allowlist is one false positive. It has a `description` with the reason
(what the value is and why it is no secret), and it hides as little as it can (one value or one file). The first run on the
repository (2026-11-15: the files and all 158 commits of the history) had no finding, so the allowlist has no entry. The
fixtures of the gates have no value that looks like a secret: the self-test makes its fake secrets while it runs. The
self-test shows that an entry hides a finding, and that an entry needs a `description`.

## zizmor

`workflow-scan.sh` runs `zizmor --offline --no-progress --color never --strict-collection .github/workflows`. `--offline`
is on purpose: the workflow has no token, and the online audits need one. A token in the environment does not change it.
`--strict-collection` makes a workflow file that zizmor cannot read an error (without it, zizmor writes a warning and
audits the other files). The persona is the default (regular). The gates `check-workflows`, `check-pins` and `check-sudo`
already fix the trigger, the permissions, the form of the `run:` step and the pins, so the report of zizmor is a second
opinion (see the plan).

## A threshold later, and the baseline file

The feature sets no threshold and writes no baseline file. The way for the owner, when the walking skeleton decides it (the
pattern of `tools/breaking/breaking-changes-ignore.txt` and of the baseline of the coverage):

1. A baseline file in the repository (for example `tools/security/<tool>-baseline.txt`, CODEOWNERS covers `/tools/`) has one
   line for each finding that exists at the time, with its identifier: the OSV identifier and the package for
   OSV-Scanner (`GHSA-...`, `qs@6.15.1`), the fingerprint for gitleaks (`<file>:<rule>:<line>`, or with the commit for
   the history), and the audit with the file for zizmor (`artipacked .github/workflows/ci.yml`). The file has counts and
   identifiers only, so the condition of the OSV deviation holds.
2. The script reads the findings of the tool in a machine-readable form (OSV-Scanner `--format json`, gitleaks
   `--report-format json`, zizmor `--format json`), removes the findings that the baseline has, and stops (exit code 1) for
   each **new** finding, above a level that the owner sets. A finding that is not in the baseline is new. A line of the
   baseline that has no finding any more is a warning (the baseline can be made smaller), as the stale entry of the ignore
   file of `breaking-changes`.
3. The function `run_security_tool` stays the same: a failure of the tool stops the recipe in each case, with or without a
   threshold. Only the handling of a finding changes.

The numbers of the baseline (Phase 130 of the plan) are the input for the level.

## Files

| File | Content |
|---|---|
| `osv-scanner-checksums.txt` | The file `osv-scanner_SHA256SUMS` of the release of OSV-Scanner, without a change. The file of the pin is the line for `osv-scanner_linux_amd64`. This file is the binary (it is not an archive) |
| `gitleaks-checksums.txt` | The file `gitleaks_<version>_checksums.txt` of the release of gitleaks, without a change. The file of the pin is the line for `gitleaks_<version>_linux_x64.tar.gz` |
| `gitleaks.toml` | The configuration of gitleaks: the default rules and the allowlist (no entry at this time). CODEOWNERS covers it |
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
check. The check does not download a file. The real check of the download is in the install functions `install_osv_scanner` and
`install_gitleaks` (`tools/gates/_security.sh`): they compare the sha256 of the file against `tools/versions.env` before
the file is opened or started, and they delete the download for another value. The self-test shows this with a small file
(a `file://` URL, no network). A binary in the cache `build/tools/<tool>-<version>/` is verified again at each start, and no
marker file is trusted: OSV-Scanner computes the sha256 of the cached binary (it is the pin), and gitleaks keeps the archive
(`archive.tar.gz`, its sha256 is the pin) and compares the binary with the file `gitleaks` inside the archive. A cache that
does not match (a changed binary, a changed or missing archive, an older pin) is not started: the install downloads again with
the sha256 check and replaces it (as `install_oasdiff` does for a cache that does not match), and it stops if the download
does not work. The self-test has a case for each.

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
