# tools/breaking: the gate for breaking changes of the OpenAPI file

This folder has the files of the gate for breaking changes (`just breaking-changes`). The policy is DEC
93594b2b-be54-4f60-9f53-ec2ce6c84be4. The scripts are in `tools/gates/` (`breaking-changes.sh`,
`breaking_changes.py`, and the test `test-breaking-changes-gate.sh`).

Plan: FEAT feat-6-contracts-openapi-pipeline (GitHub issue #6), Tasks 115.100 to 115.130 (REQ-003, REQ-009, REQ-012).

## Files

| File | Content |
|---|---|
| `breaking-changes-ignore.txt` | The ignore file. It has no entry now. The owner accepts a breaking change with one entry in this file (the format is in the file and below). CODEOWNERS covers `/tools/`, so the owner examines each new entry |
| `oasdiff-checksums.txt` | The file `checksums.txt` of the release of oasdiff, without a change. It is the second place of the pin of oasdiff, and `just check-pins` compares it with `tools/versions.env` |
| `README.md` | This file |

`just check-pins` does not stop for another file in this folder (it is not a pnpm project). The ignore file is read by the gate and not by `check-pins`.

## How the gate decides

`just breaking-changes` starts `tools/gates/breaking-changes.sh <base> contracts/openapi.yaml tools/breaking/breaking-changes-ignore.txt`. The `<base>` is the variable `base` of the `justfile`: `origin/dev`, or `origin/<GITHUB_BASE_REF>` in a pull request.

1. The gate finds the merge base of `<base>` and `HEAD` (`git merge-base`). A pull request to `dev` is compared with the merge base of the pull request and `dev`. A release pull request to `main` is compared with `main`.
2. It reads `contracts/openapi.yaml` at the merge base (`git show`). If the merge base has no such file, there is nothing to compare, and the gate **passes** (the pull request that adds the file for the first time). If the merge base has the file and the pull request deletes it, the gate **stops**.
3. It installs oasdiff (a download with a sha256 check, see below) and starts it with `oasdiff breaking <base file> <file> --fail-on ERR`. The default levels of oasdiff stay: a breaking change is a change of the level `error`. For example, a new value of an enum in a property of a response is an error, and the removal of a value is only `info`.
4. A change of the level `error` that no entry of the ignore file ignores **stops** the gate. The message has the line that the owner can add to the ignore file.
5. If an entry is **used** (it ignores a change that oasdiff found), `info.version` of the file must be higher than `info.version` at the merge base in the way of rule 5 of the DEC, or the gate **stops**:
   - the version must be higher by the order of Semantic Versioning 2.0.0 (a pre-release is lower than the release, and the build metadata has no order);
   - if the first number of the version at the merge base is 0, the second number must go up (`0.1.0` to `0.2.0` or to `1.0.0` is correct, `0.1.0` to `0.1.1` is not);
   - if the first number is not 0, the first number must go up (`1.4.2` to `2.0.0` is correct, `1.4.2` to `1.5.0` is not).
6. If no change of the level `error` is left, the gate **passes**, with entries or without. An entry that matches no change is not a failure: the gate writes a `WARNING`, and the owner removes the entry (rule 6 of the DEC).

How the gate knows which entry is used: it starts oasdiff once with no ignore file, and once for each entry with that entry only. The changes that go away are the changes that the entry ignores. So the matching is the matching of oasdiff, and the script has no copy of the rule. A last start with all entries must agree with this result, or the gate stops with exit code 2.

oasdiff reads a configuration file `.oasdiff.*` or `oasdiff.*` in its current folder and the variable `OASDIFF_CONFIG`. Such a file can set `err-ignore` and switch off the check. So the gate starts oasdiff in a new empty folder, and without the variables `OASDIFF_*`. The test has cases for this.

## The format of an entry

Blank lines and lines that start with `#` are not read. One entry is one line with four items (rule 4 of the DEC), separated by ` | ` (a space, a vertical bar and a space):

```
<METHOD> <path> <the change as oasdiff names it> | <cause> | #<issue or pull request> | <release>
```

For example (the `Entries:` part of the ignore file):

```
GET /status removed the required property `checkedAt` from the response with the `200` status | The member moves to `time` | #123 | 0.2.0
```

1. The change: `<METHOD> <path>` and the text of the change. When the gate stops for a breaking change, its message has this item. Each status of a response is its own change and needs its own line. The text is the line for the option `--err-ignore` of oasdiff (oasdiff compares the lower case text).
2. The cause: why the project accepts the change.
3. The number of the issue or of the pull request, with `#`.
4. The release after which the entry ends: a version in the form of Semantic Versioning 2.0.0. After this release, `main` has the change, and the owner removes the entry.

The gate gives oasdiff only the first item of each entry. oasdiff alone reads a line that starts with `#` as a normal entry, and it ignores a change if the text of the change is anywhere in a line. So a comment, or a cause that has the text of another change, cannot ignore a change by chance. An entry with a wrong form (not four items, a third item that is not `#<number>`, a fourth item that is not a version, the same change two times) **stops** the gate.

A coding agent adds an entry only if the owner tells it to do so (rule 3 of the DEC).

## The pin of oasdiff

oasdiff is a Go binary with no package manager. `tools/versions.env` has `OASDIFF_VERSION` and `OASDIFF_SHA256` (the sha256 of `oasdiff_<version>_linux_amd64.tar.gz`). `install_oasdiff` in `tools/gates/_lib.sh` downloads the file from the release of GitHub, compares its sha256 with `OASDIFF_SHA256` **before** it unpacks the file, and puts the files `oasdiff` and `LICENSE` in `build/tools/oasdiff-<version>/` (the folder `build/` is in `.gitignore`). It stops if the version of the binary is not `OASDIFF_VERSION`. It does not download again if the folder has the binary of the same version and the same pin. The install needs the network (GitHub) for the first run, and it needs no Node and no Java.

The pin is for Linux x86_64 only, as the install scripts for just and Node: the gates run on a runner of GitHub (Ubuntu) and on the machine of the author. The script stops on another platform. A new platform needs its own checksum and a change of `install_oasdiff` and of `check_pins.py`.

`just check-pins` compares `OASDIFF_VERSION` and `OASDIFF_SHA256` with `oasdiff-checksums.txt`: the file must have the line for `oasdiff_<OASDIFF_VERSION>_linux_amd64.tar.gz` with the value of `OASDIFF_SHA256`. A change of only one of the two places stops the check.

To change the version (one commit):

1. Read the release page of oasdiff. Get `checksums.txt` of the release, and get the file `oasdiff_<version>_linux_amd64.tar.gz`. Compare `sha256sum` of the file with the line of `checksums.txt` and with the digest that GitHub shows for the file. All three values must be the same.
2. Replace `oasdiff-checksums.txt` with the new `checksums.txt` (no change in the file).
3. Change `OASDIFF_VERSION` and `OASDIFF_SHA256` in `tools/versions.env`.
4. Read the license file of the new release again (DEC 84c37f7d-08cb-457d-8ab3-1db37dba9bc9), and change the license table in the plan of the feature if the license changes.
5. Run `just check-pins` and `just test-breaking-changes-gate`.

## Limits

- The gate compares one file, `contracts/openapi.yaml`, with one file at the merge base. A relative `$ref` to another file does not resolve for the file at the merge base (it is a copy in a temporary folder), and the gate stops with exit code 2 if oasdiff cannot read a file. A file with a `$ref` to another file needs a change of the gate.
- oasdiff 1.35.0 reads OpenAPI 3.0 and 3.1.
- The check of the version number is the rule of the DEC. It does not check that the release in the fourth item of an entry is higher than or equal to the new version, and it does not remove an entry (that is a task of the owner).
