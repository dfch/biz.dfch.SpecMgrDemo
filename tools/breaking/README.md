# tools/breaking: the gate for breaking changes of the OpenAPI file

This folder has the files of the gate for breaking changes (`just breaking-changes`). The policy is DEC
93594b2b-be54-4f60-9f53-ec2ce6c84be4. The scripts are in `tools/gates/` (`breaking-changes.sh`,
`breaking_changes.py`, and the test `test-breaking-changes-gate.sh`).

Plan: FEAT `feat-6-contracts-openapi-pipeline` (GitHub issue #6), Tasks 115.100 to 115.130 (REQ-003, REQ-009, REQ-012).

## Files

| File | Content |
|---|---|
| `breaking-changes-ignore.txt` | The ignore file. The owner accepts a breaking change with one entry in this file (the format is in the file and below). CODEOWNERS covers `/tools/`. The owner examines each new entry |
| `oasdiff-checksums.txt` | The file `checksums.txt` of the release of oasdiff, without a change. It is the second file of the pin of oasdiff. `just check-pins` compares it with `tools/versions.env` |
| `oasdiff-severity-levels.txt` | The severity levels of the gate (below). It sets the level `err` for the removal of a response property (required or optional). It sets the level `err` for the removal of a response. It sets the level `err` for the removal of an enum value of a response property. All other levels are the values of oasdiff without the file |
| `README.md` | This file |

`just check-pins` does not stop for a file in this folder that is not one of the files in the table. The folder is not a pnpm project. The gate reads the ignore file and the severity levels file. `check-pins` does not read them.

## The form of the decision of the gate

`just breaking-changes` starts `tools/gates/breaking-changes.sh <base> contracts/openapi.yaml tools/breaking/breaking-changes-ignore.txt`. The `<base>` is the value `base` of the `justfile`: `origin/dev`, or `origin/<GITHUB_BASE_REF>` in a pull request.

1. The gate finds the merge base of `<base>` and `HEAD` (`git merge-base`). The gate compares a pull request to `dev` with the merge base of the pull request and `dev`. It compares a release pull request to `main` with `main`.
2. It reads `contracts/openapi.yaml` at the merge base (`git show`). If the merge base has no such file, there is no file to compare. The gate **gives exit code 0**. This is the pull request that adds the file for the first time. If the merge base has the file and the pull request deletes it, the gate **stops**.
3. It installs oasdiff (a download from GitHub with a sha256 check, see below). It starts oasdiff with `oasdiff breaking <base file> <file> --fail-on ERR --severity-levels tools/breaking/oasdiff-severity-levels.txt`. A breaking change is a change of the level `error` (the levels are in "The severity levels" below).
4. A change of the level `error` that no entry of the ignore file ignores **stops** the gate. The message has the line that the owner can add to the ignore file.
5. If an entry is **in use** (it ignores a change that oasdiff found), `info.version` of the file must be higher than `info.version` at the merge base, in the form of rule 5 of the DEC, or the gate **stops**:
   - the version must be higher by the sequence of Semantic Versioning 2.0.0 (a version before the release is lower than the release, and the build metadata has no sequence);
   - if the first number of the version at the merge base is 0, the second number must go up (`0.1.0` to `0.2.0` or to `1.0.0` is correct, `0.1.0` to `0.1.1` is not);
   - if the first number is not 0, the first number must go up (`1.4.2` to `2.0.0` is correct, `1.4.2` to `1.5.0` is not).
6. If no change of the level `error` is left, the gate **gives exit code 0**, with entries or without. An entry that matches no change is not a failure: the gate writes a `WARNING`, and the owner removes the entry (rule 6 of the DEC).

How the gate knows which entry is in use: it starts oasdiff one time with no ignore file. It starts oasdiff one time for each entry with that entry only. The changes that go away are the changes that the entry ignores. The result of an entry is the result of oasdiff. The script has no copy of the rule. A last start with all entries must agree with this result. If not, the gate stops with exit code 2.

oasdiff reads a configuration file `.oasdiff.*` or `oasdiff.*` in the folder where it operates. It also reads the value of `OASDIFF_CONFIG`. Such a file can set `err-ignore` and switch off the check. The gate starts oasdiff in a new empty folder. It does not set the values `OASDIFF_*`. The test has cases for this.

## The severity levels

oasdiff gives each category of change a level (`err`, `warn`, `info`). Without the file, the removal of an optional property of a response is only `info`. The removal of a response is only `info`. The removal of an enum value of a response property is only `info`. The gate (it stops for the level `error`) does not see them. The criterion ACC-003 of `feat-6-contracts-openapi-pipeline` has this text. The text is: "a change of the OpenAPI file that removes a property of a response causes a failure of the gate". The file `oasdiff-severity-levels.txt` sets these categories of change to the level `err`. The gate starts oasdiff with `--severity-levels` and this file (the value `SEVERITY_LEVELS_FILE` names a different file, for the tests). All other levels are the values of oasdiff without the file. The file changes only the lines below. It has no comment and no line with no text (oasdiff stops for a line that is not `<check id> <level>`).

| Check `id` of oasdiff 1.35.0 | Change | Level in the file |
|---|---|---|
| `response-required-property-removed` | the removal of a required property of a response (the value is `err` without the file; the line names it) | `err` |
| `response-optional-property-removed` | the removal of an optional property of a response | `err` |
| `response-required-write-only-property-removed` | the removal of a required `write-only` property of a response | `err` |
| `response-optional-write-only-property-removed` | the removal of an optional `write-only` property of a response | `err` |
| `response-success-status-removed` | the removal of a response with a status 2xx (the value is `err` without the file; the line names it) | `err` |
| `response-non-success-status-removed` | the removal of a response with a status 4xx or 5xx | `err` |
| `response-property-enum-value-removed` | the removal of an enum value of a property of a response | `err` |
| `response-mediatype-enum-value-removed` | the removal of an enum value of the schema of a response media type | `err` |

The check `id` is the value of the member `id` in the JSON output of `oasdiff breaking` (the format `json`). To find the `id` of a change: `oasdiff breaking <base> <revision> -f json` (with the file that makes the change). A change of the oasdiff version can change the `id`. The gate stops then with a message that names the `id`. oasdiff stops for an `id` that it does not know. The gate gives exit code 2. The removal of a property of a request has the values of oasdiff without the file. The other changes of a request have these values too. The criterion is for a response.

## The format of an entry

Lines with no text and lines that start with `#` are not read. One entry is one line with four items (rule 4 of the DEC). The items have ` | ` between them (a space, a vertical bar and a space):

```
<METHOD> <path> <the change as oasdiff names it> | <cause> | #<issue or pull request> | <release>
```

For example (the `Entries:` part of the ignore file):

```
GET /status removed the required property `checkedAt` from the response with the `200` status | The member moves to `time` | #123 | 0.2.0
```

1. The change: `<METHOD> <path>` and the text of the change. When the gate stops for a breaking change, its message has this item. Each status of a response is a change. Each status has a line. The text is the line for the option `--err-ignore` of oasdiff (oasdiff compares the lower case text).
2. The cause, one line of text.
3. The number of the issue or of the pull request, with `#`.
4. The release after which the entry ends: a version in the form of Semantic Versioning 2.0.0. After this release, `main` has the change, and the owner removes the entry.

The gate gives oasdiff only the first item of each entry. oasdiff (and not the gate) reads a line that starts with `#` as a normal entry. It ignores a change if the text of the change is in a position of the line. A comment, or a cause that has the text of a different change, cannot ignore a change for this cause. An entry with a form that is not correct **stops** the gate. The form has not four items. Item 3 is not `#<number>`. Item 4 is not a version. The same change is two times.

A coding agent adds an entry only if the owner tells it to do it (rule 3 of the DEC).

## The pin of oasdiff

oasdiff is a Go binary with no tool that installs packages. `tools/versions.env` has `OASDIFF_VERSION` and `OASDIFF_SHA256` (the sha256 of `oasdiff_<version>_linux_amd64.tar.gz`). `install_oasdiff` in `tools/gates/_lib.sh` gets the file from the release of GitHub. It compares its sha256 with `OASDIFF_SHA256` **before** it opens the file. It puts the files `oasdiff` and `LICENSE` in `build/tools/oasdiff-<version>/` (the folder `build/` is in `.gitignore`). It stops if the version of the binary is not `OASDIFF_VERSION`. It does not get the file again if the folder has the binary of the same version and the same pin. The install has the network (GitHub) for the first start as necessary. It has no Node and no Java.

The pin is for Linux x86_64 only, as the install scripts for just and Node. The gates operate on a runner of GitHub (Ubuntu). They operate on the machine of the author. The script stops on a platform that is not Linux x86_64. A new platform has a checksum and a change of `install_oasdiff` and of `check_pins.py`.

`just check-pins` compares `OASDIFF_VERSION` and `OASDIFF_SHA256` with `oasdiff-checksums.txt`: the file must have the line for `oasdiff_<OASDIFF_VERSION>_linux_amd64.tar.gz` with the value of `OASDIFF_SHA256`. A change of only one of the two files stops the check.

To change the version (one commit):

1. Read the release page of oasdiff. Get `checksums.txt` of the release, and get the file `oasdiff_<version>_linux_amd64.tar.gz`. Compare `sha256sum` of the file with the line of `checksums.txt` and with the sha256 value that GitHub shows for the file. All three values must be the same.
2. Replace `oasdiff-checksums.txt` with the new `checksums.txt` (no change in the file).
3. Change `OASDIFF_VERSION` and `OASDIFF_SHA256` in `tools/versions.env`.
4. Read the license file of the new release again (DEC 84c37f7d-08cb-457d-8ab3-1db37dba9bc9). Change the license table in the plan of the feature if the license changes.
5. Start `just check-pins` and `just test-breaking-changes-gate`.

## Limits

- The gate compares one file, `contracts/openapi.yaml`, with one file at the merge base. A relative `$ref` to a different file does not work for the file at the merge base (it is a copy in a temporary folder). The gate stops with exit code 2 if oasdiff cannot read a file. A file with a `$ref` to a different file has a change of the gate as necessary.
- oasdiff 1.35.0 reads OpenAPI 3.0 and 3.1.
- The check of the version number is the rule of the DEC. It does not examine that the release in item 4 of an entry is higher than or equal to the new version. It does not remove an entry (that is a task of the owner).
