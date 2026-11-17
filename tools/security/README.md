# tools/security: the security gates (Gate 9) and the pins of the tools

This folder is the home of the security gates of `feat-8-traceability-security-gates` (GitHub issue #8, Phase 120, Gate 9
of DEC 361678a6-f941-473b-a058-1ba2bacf7d3d). It has the vendor files of the pins of OSV-Scanner and gitleaks, the
allowlist of gitleaks, and, since `feat-9-walking-skeleton` (Phase 500), the baseline file of each tool. The scripts of the
gates are in `tools/gates/` (see the section "The security gates" in `tools/gates/README.md`).

The security tools were **reports with no threshold** in feat-8 (REQ-005). Since `feat-9-walking-skeleton` (Phase 500, the
decision of the owner of 2026-11-15, REQ-006) they are **blocking gates with a level gate**: a finding that is Critical or
High stops the job in each case, a finding that is not in the baseline file stops the job, and a line of the baseline that has
no finding any more is a warning. The baseline is the state of the feature (see "The threshold and the baseline file").

## The recipes

| Recipe | Script | Tool | What it examines | Network |
|---|---|---|---|---|
| `just vuln-scan` | `tools/gates/vuln-scan.sh` | OSV-Scanner (`OSV_SCANNER_VERSION`, a binary in `build/tools/`) | The known vulnerabilities of the dependencies. The input is the SBOM files `build/sbom/*.cdx.json` (the recipe has `sbom` as a prerequisite). The baseline is `osv-baseline.txt` | Yes: api.osv.dev (the install needs GitHub for the first run) |
| `just secret-scan` | `tools/gates/secret-scan.sh` | gitleaks (`GITLEAKS_VERSION`, a binary in `build/tools/`) | Secrets in the files (a copy of the files that git knows) and in the history of the pull request (`<base>..HEAD`). The baseline is `gitleaks-baseline.txt` | No (the install needs GitHub for the first run) |
| `just workflow-scan` | `tools/gates/workflow-scan.sh` | zizmor (`ZIZMOR_VERSION`, installed from `tools/python/zizmor.lock`) | The workflow files in `.github/workflows`. The baseline is `zizmor-baseline.txt` | No (`--offline`; the install needs the package index for the first run) |
| `just test-security-gates` | `tools/gates/test-security-gates.sh` | all three, and stubs | The self-test of the three recipes, of the function that separates a finding from a failure of the tool (feat-8 ACC-005) and of the level gate with the baseline files (feat-9 ACC-007) | The install of the real tools |

CodeQL is the fourth security tool. It is the hosted default setup of GitHub and has no recipe and no file in the
repository (see the plan of feat-8, Phase 130, and the deviation in DEC 93a6d588-e002-4daf-9a47-45e2d77786e9). Its native
check is the rule `code_scanning` of the ruleset (see "CodeQL" below).

The CI jobs have the names of the recipes (`vuln-scan`, `secret-scan`, `workflow-scan`, and `traceability` for Gate 2). The
job `vuln-scan` uses the network and has the timeout of 30 minutes. CodeQL has no job (no workflow file). The owner adds the
check names to the rulesets (`branch-protection.md` in the folder of feat-5-foundation-monorepo-ci).

## A finding and a failure of the tool

A report with no finding and a tool that did not run look the same to a reader, so the recipes keep the two cases apart.
One function does it for all three recipes (`security_classify` and `run_security_tool` in `tools/gates/_security.sh`).

| Case | Exit code of the recipe | What happens |
|---|---|---|
| The tool ran and has no finding | 0 | The line "no finding" and the summary |
| The tool ran and has findings | 0 or 1 | The tool prints its report, and the recipe prints "FINDINGS". The level gate decides next (see "The threshold and the baseline file"): exit code 0 if each finding is in the baseline and none is Critical or High, and exit code 1 for a new finding or for a finding that is Critical or High |
| The tool did not run to the end (no network, a file that cannot be read, a wrong configuration, a missing binary, a download with another checksum, a base that does not exist) | 1 | The recipe prints "FAILURE OF THE TOOL" with the exit code, and stops. The level gate does not run, and there is no summary line |

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

The report is the output of the tool, the findings of the level gate, and the lines of the script. The lines are in the log of
the job and nowhere else (the scripts write no file in the repository; the JSON report of the tool is in a temporary folder).

```
<the output of the tool>
[vuln-scan.sh] OSV-Scanner: FINDINGS (exit code 1). The output above is the report. The level gate decides next (tools/security/README.md).
SUMMARY: OSV-Scanner: 5 finding(s) (0 Critical, 0 High, 5 Medium, 0 Low, 0 Informational, 0 Unknown); baseline osv-baseline.txt: 5 line(s)
  Medium        baseline GHSA-4mjr-xmp4-gh2g qs@6.15.1 (CVSS 6.3)
  ...
RESULT: PASS. 5 finding(s), all in the baseline, none Critical or High; 0 old baseline line(s).
[vuln-scan.sh] OSV-Scanner: THRESHOLD PASS. No new finding and no finding that is Critical or High (the baseline is tools/security/osv-baseline.txt).
```

| Recipe | The report of the tool (the log) | What the level gate names for each finding |
|---|---|---|
| `vuln-scan` | The progress of OSV-Scanner (the report is JSON in a temporary file, so there is no table of the tool) | The level, the state (`baseline` or `NEW`), the OSV identifier, the package with the version, and the CVSS score |
| `secret-scan` | The verbose output of gitleaks (redacted), and `REPORT: files: N finding(s); history <base>..HEAD: M finding(s)` | The level (Unrated), the state, the fingerprint and the rule. The secret is redacted (`--redact`) and never in the report |
| `workflow-scan` | The text report of zizmor (the source lines, the confidence and the documentation link), and the summary line of zizmor | The level (the severity), the state, the audit, the file and the place in the file, and the confidence |

## The data of OSV and the conditions of the deviation

OSV-Scanner sends package names, versions, ecosystems and file hashes (no source code) to api.osv.dev. The data of OSV.dev has
the licenses of its sources (for the packages of this project mainly the GitHub Advisory Database, CC-BY 4.0), and the owner
accepted a deviation for the use (DEC 93a6d588-e002-4daf-9a47-45e2d77786e9, the section of the OSV data, 2026-11-15). The
conditions apply to `vuln-scan`:

- The use is a report of known vulnerabilities. Since feat-9 the recipe also has a level gate: the finding identifier and the
  level of the finding (the CVSS score) decide whether the job stops. The gate keeps and shows no text of a record. (The
  deviation DEC says "a report with no threshold" for feat-8. The use of the identifier and of the score for a stop of the job
  is not a copy or a redistribution of a record, but the owner should confirm that this is inside the deviation: see the plan
  of feat-9, Decisions Made. The DEC is not changed.)
- The repository keeps counts and finding identifiers only (the baseline file `osv-baseline.txt`: the OSV identifier and the
  package with the version, one line for each finding). It keeps no copy of the records, no advisory text and no description.
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

Each scan also writes its report as JSON (`--report-format json --report-path`, in a temporary folder) for the level gate. The
options are `--redact` (the log of a public repository must not show a secret), `--exit-code 2`,
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
audits the other files). The persona is the default (regular). The script runs zizmor twice: the first run is the text report of the
log, and the second run (`--format json-v1`) gives the findings to the level gate (both runs must have the same exit code). The
gates `check-workflows`, `check-pins` and `check-sudo`
already fix the trigger, the permissions, the form of the `run:` step and the pins, so the report of zizmor is a second
opinion (see the plan).

## The threshold and the baseline file

The mechanism (`feat-9-walking-skeleton`, Phase 500, Tasks 500.110 and 500.120, REQ-006). The pattern is the ignore file of
`tools/breaking/breaking-changes-ignore.txt` and the baseline of the coverage.

**The baseline files.** Each tool has one file in this folder (CODEOWNERS covers `/tools/`, so the owner reviews each change).
The file must exist, also if it has no line: a recipe stops (exit code 1) if the file is missing. A line is the identifier of
one finding of the state of the feature. Empty lines and lines that start with `#` are comments. The file has counts and
identifiers only (the condition of the OSV deviation): no report text, no advisory text, no description.

| File | The line | The state of the feature (2026-11-17) |
|---|---|---|
| `osv-baseline.txt` | `<OSV identifier> <package>@<version>` (`GHSA-4mjr-xmp4-gh2g qs@6.15.1`). A new version of the package is another line | 5 lines, all Medium (CVSS 6.9 and 6.3), all of the frontend: `minimatch@10.2.6` (1) and `qs@6.15.1` (4). 0 Critical, 0 High |
| `gitleaks-baseline.txt` | The fingerprint of gitleaks: `<file>:<rule>:<line>` (the files), `<commit>:<file>:<rule>:<line>` (the history) | No line (0 findings in the files and in the history) |
| `zizmor-baseline.txt` | `<audit> <file> <place>` (`artipacked .github/workflows/ci.yml jobs/lint/steps/0`). The place is the path of the keys and the indexes of the YAML, so a change of the line numbers of the file does not change the line | 11 lines, all `artipacked` (Medium, confidence Low) of the checkouts of the jobs of feat-7. 0 High |

**The level gate.** After the tool, the script starts `security_threshold.py` (`security_level_gate` in `tools/gates/_security.sh`)
with the baseline file and the report of the tool in a machine-readable form (OSV-Scanner `--format json`, gitleaks
`--report-format json`, zizmor `--format json-v1`). The rules:

| Case | Exit code of the recipe |
|---|---|
| No finding, or each finding is in the baseline and none is Critical or High | 0 |
| A finding of the baseline that is not Critical or High | 0 (it passes) |
| A line of the baseline that has no finding any more | 0, with a **warning** (the baseline can be made smaller: delete the line) |
| A finding that is **not in the baseline** (a new finding) | 1 |
| A finding that is **Critical or High** | 1, in each case |
| A finding that is Critical or High **and has a line in the baseline** | 1: the baseline must have no line of these levels, so the message says "ERROR OF THE FEATURE" |
| The tool did not run to the end (`run_security_tool`, a failure of the tool) | 1 |
| The baseline or the report cannot be used (a file that is missing or not JSON, a line with a wrong form, a line twice, a report with another form) | 1 (it is a failure, and not a pass) |

**The level of a finding** (the mapping, the same text is at the top of `tools/gates/security_threshold.py`):

| Tool | The level |
|---|---|
| OSV-Scanner | The CVSS score of the group of the finding (`max_severity`, the value that the table of OSV-Scanner shows): 9.0 or more is Critical, 7.0 to 8.9 is High, 4.0 to 6.9 is Medium, below 4.0 is Low. If the record has no score, the label of the database is used (CRITICAL, HIGH, MODERATE, LOW). If both are there, the higher level is used. A finding with neither is Unknown (it is no stop by its level, and a new one stops as a new finding) |
| zizmor | The severity of the audit: High, Medium, Low, Informational. zizmor has no level Critical. High stops in each case. A finding that zizmor suppresses (its own `ignored` mark) is no finding |
| gitleaks | None: gitleaks gives no severity. The level is Unrated, and the baseline is the only rule (a secret that is not in the baseline stops). The allowlist of `gitleaks.toml` is the place for a false positive, and the baseline file is expected to stay empty. The decision is in the plan of feat-9 (Decisions Made); the constant `GITLEAKS_LEVEL` in `security_threshold.py` is the one place to change it (with the value Critical, each secret would stop in each case, and the baseline of gitleaks could have no line) |

**How to change a baseline.** A new finding of a dependency or of a workflow is a defect of the pull request: fix it (a version
without the finding, or a change of the workflow). A finding that the owner accepts for a reason that the plan names goes into
the baseline in the same pull request, with the identifier only, and the owner reviews it (CODEOWNERS). A line that the gate
reports as old is deleted in the next pull request. A finding that is Critical or High is never a baseline line: it stops in
each case, so it is fixed or the dependency is chosen again (REQ-008 of feat-9, DEC 84c37f7d-08cb-457d-8ab3-1db37dba9bc9).

`run_security_tool` stays the same: a failure of the tool stops the recipe in each case, with or without a baseline. Only the
handling of a finding changed. `just test-security-gates` shows each case of the table for each tool (ACC-007).

## CodeQL

CodeQL is the hosted default setup of GitHub (no recipe, no job, no file). Its native check for a **new finding that is Critical
or High** (the option B of the plan of feat-9, REQ-007) is the rule `code_scanning` of the rulesets of `dev` and `main`: the tool
`CodeQL`, `security_alerts_threshold: high_or_higher` and `alerts_threshold: none` (the other levels of CodeQL are out of
scope). The setting is the work of the owner (the exact steps are in `branch-protection.md` in the folder of
feat-5-foundation-monorepo-ci). The agent checked the mechanism with read calls only (`gh api` GET, 2026-11-17): the default
setup is `configured`, the analyses of the tool `CodeQL` exist for `refs/heads/dev` and for `refs/pull/<n>/head` with 0
results, there is no open alert, and the rulesets of `dev` and `main` have no rule `code_scanning` yet. The rule becomes active
when the owner applies the steps.

## Files

| File | Content |
|---|---|
| `osv-scanner-checksums.txt` | The file `osv-scanner_SHA256SUMS` of the release of OSV-Scanner, without a change. The file of the pin is the line for `osv-scanner_linux_amd64`. This file is the binary (it is not an archive) |
| `gitleaks-checksums.txt` | The file `gitleaks_<version>_checksums.txt` of the release of gitleaks, without a change. The file of the pin is the line for `gitleaks_<version>_linux_x64.tar.gz` |
| `gitleaks.toml` | The configuration of gitleaks: the default rules and the allowlist (no entry at this time). CODEOWNERS covers it |
| `osv-baseline.txt`, `gitleaks-baseline.txt`, `zizmor-baseline.txt` | The baseline file of each tool: the identifiers of the findings of the state of the feature (see "The threshold and the baseline file"). The files that the level gate reads. CODEOWNERS covers `/tools/` |
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
