# Suggestion for a skill: names of scripts in a feature (`TTT.MMM-NN-name.sh`)

This document is the result of Task 140.100 of `feat-5-foundation-monorepo-ci` (REQ-014).

## What this is

This is a suggestion for a skill. The skill tells an agent how to name and write a script that belongs to a task of a FEAT plan. It uses the name format `TTT.MMM-NN-name.sh`.

## Why

Feature 5 has seven install scripts in `.specmgr/feat/feat-5-foundation-monorepo-ci/bin/`. Their names show the task and the step in the task. A reader can find the task in the plan from the name of the script. Without a rule, the next feature can use other names. The skill keeps the names, the headers and the style the same.

The style comes from the scripts of the sibling repository `biz.dfch.LlmOps` (folder `feat-0-screen-record/bin/`). The rules in this document come from the scripts in this repository, so the skill does not need the sibling repository.

## Who decides where the skill goes

The owner decides. This document does not install the skill. The agent did not copy it to `~/.config/opencode/skills/` or to another folder. If the owner wants the skill, copy the text between the markers below to a file `SKILL.md` in a folder with the name `script-names`. The owner can also change the text first.

Open points for the owner:

- Where does the skill live: for all projects (`~/.config/opencode/skills/script-names/`) or only for this project?
- Can the skill refer to the skill `feat-numbering`? The draft does. If the owner puts the skill in a place where `feat-numbering` is not available, remove that line.

## Draft of the skill

Copy everything between the two marker lines. The outer fence has four backticks, because the draft has fences of its own.

<!-- BEGIN SKILL.md -->

````markdown
---
name: script-names
description: Use when writing, naming or reviewing a script in the `bin` folder of a specmgr FEAT (`.specmgr/feat/<id>/bin/`) -- defines the name format `TTT.MMM-NN-name.sh`, the rules for the header and the style of such a script, and how it differs from a gate script in `tools/gates/`.
---

# Names of scripts in a feature: `TTT.MMM-NN-name.sh`

A script that belongs to a task of a FEAT plan has a name that shows the task and the step.
The reader of the name can find the task in the plan.

## The name format

```
TTT.MMM-NN-name.sh
```

| Part | Meaning | Rule |
|---|---|---|
| `TTT.MMM` | The number of the task in the plan (`Task TTT.MMM`) | Three digits, a dot, three digits. Copy it from the task list. See the skill `feat-numbering` for the numbers |
| `NN` | The number of the step in this task | Two digits. Start at `01`. Count up by one, in the order in which the scripts run |
| `name` | What the script does | Short, in kebab-case (lowercase letters, digits and `-`). Start with a verb: `install-jdk`, `write-env`, `verify-tools` |
| `.sh` | The type of the file | Use the extension of the language. A Python script has `.py` (see `feat-3-process-policy-baseline/bin/500.120-01-ste-word-check.py`) |

A task with one script has one step: `110.105-01-install-node.sh`.
A task with many scripts has many steps with the same `TTT.MMM`: `110.110-01` to `110.110-06`.

A script that runs the checks of a step is one more step, and it comes last
(`110.110-06-verify-tools.sh`).

A number never changes after you assign it (see `feat-numbering`).
If the task in the plan has a new number, make a note in the plan and do not rename silently.

## Where the scripts go

- The folder is `bin` in the folder of the feature: `.specmgr/feat/<id>/bin/`.
- The folder has a `README.md` with the sequence of the scripts (see below).
- The folder has a file `_common.sh` with the shared functions. It starts with `_`, so that the
  sequence of the names does not show it. Nobody runs it directly. Each script reads it with `source`.

## Rules for each script

1. Line 1 is `#!/usr/bin/env bash`.
2. Line 2 is the header: the feature and the task. Example: `# feat-5-foundation-monorepo-ci, Task 110.110`.
3. A short comment tells what the script does, what it changes, and which options it has.
4. Then comes `set -euo pipefail`, and then `source "$(dirname "${BASH_SOURCE[0]}")/_common.sh"`.
5. The script can be run again. The second run does nothing if the work is done, and it makes no error.
6. The script needs no sudo. It writes only to the home directory of the user (and to the repository).
   It stops if the user is root (`refuse_root` in `_common.sh`).
7. The script uses the functions of `_common.sh` and does not copy them (`log`, `die`, `require_cmd`,
   `load_versions`, `require_var`, `check_sum`, `install_archive`).
8. The script reads versions and checksums from one file (`tools/versions.env`). It does not have its own copy of them.
9. The script checks each download against a pinned checksum. It deletes a temporary file also after an error.
10. The script is executable (`chmod +x`).

## The README of the `bin` folder

The README has at least:

- A table of the scripts in the order of the run, with a short purpose for each.
- The commands to run them.
- A table of what the scripts change (paths and files) and how to undo it.

Add a script to the table in the same commit that adds the script.

## Not the same: gate scripts in `tools/gates/`

A gate script is not named in this way. The folders and names are different on purpose:

| | Script of a task (`bin`) | Gate script (`tools/gates/`) |
|---|---|---|
| Place | `.specmgr/feat/<id>/bin/` | `tools/gates/` (at the root of the repository) |
| Name | `TTT.MMM-NN-name.sh`: shows task and step | The function, with no number: `check-pins.sh`, `commit-check.sh`, `sbom.sh` |
| Use | One time, by a person, in a sequence | Each time, by CI and by a person |
| Start | `./110.110-01-install-jdk.sh` | A recipe in the `justfile` (`just check-pins`). CI starts only the recipe |
| Task number | In the name and in the header | Only in the header (`# feat-5-foundation-monorepo-ci, Task 130.120`) |
| Helper file | `_common.sh` | `_lib.sh` (and `_workflow.py`) |

A gate belongs to the project and stays after the feature is done. A change in `tools/gates/` needs the
review of a code owner. For this reason a gate has a name for its function and not for its place in a sequence.

Both kinds of script have the same header form (feature, task), `set -euo pipefail`, and no sudo.

## Examples from this repository

| File | Task | Why this name |
|---|---|---|
| `110.105-01-install-node.sh` | 110.105 | First (and only) step of Task 110.105 |
| `110.110-01-install-jdk.sh` | 110.110 | Step 1 of Task 110.110 |
| `110.110-02-install-maven.sh` | 110.110 | Step 2 |
| `110.110-03-install-pnpm.sh` | 110.110 | Step 3 |
| `110.110-04-install-just.sh` | 110.110 | Step 4 |
| `110.110-05-write-env.sh` | 110.110 | Step 5: writes the environment file (no install) |
| `110.110-06-verify-tools.sh` | 110.110 | Step 6: checks the result, changes nothing |
| `_common.sh` | - | Shared functions, no number |

All of these are in `.specmgr/feat/feat-5-foundation-monorepo-ci/bin/`.

## Check list

- [ ] The name matches `TTT.MMM-NN-name.sh`, and `TTT.MMM` is a task in the plan.
- [ ] `NN` starts at `01` and follows the order of the run.
- [ ] `name` is kebab-case and starts with a verb.
- [ ] Line 2 has the feature and the task.
- [ ] `set -euo pipefail` is in the script.
- [ ] A second run makes no error and no change.
- [ ] The script has no sudo and stops for root.
- [ ] The script uses `_common.sh` and `tools/versions.env`.
- [ ] The script is executable.
- [ ] The README of the `bin` folder has the script in the table.
- [ ] A gate script is in `tools/gates/` with a name for its function (not in `bin`).

## Common mistakes

| Mistake | Correction |
|---|---|
| `install_jdk.sh` or `InstallJDK.sh` | Use `110.110-01-install-jdk.sh`: number first, kebab-case |
| `110.110-1-install-jdk.sh` | `NN` has two digits: `-01-` |
| `110-110-01-install-jdk.sh` | The task number has a dot: `110.110` |
| `110.110-01-jdk.sh` | The name starts with a verb: `install-jdk` |
| A task number that is not in the plan | Add the task to the plan first, then name the script |
| The same step number in two scripts of one task | Count up: `-01`, `-02`, ... |
| A new number for a task after the scripts exist | A number is permanent. Do not renumber |
| A gate named `130.120-01-commit-check.sh` | Put the gate in `tools/gates/` as `commit-check.sh` and add a `just` recipe |
| Shared code copied to each script | Put it in `_common.sh` |
| A version or checksum in the script | Put it in `tools/versions.env` |
| The script is missing in the README | Add a row to the table in the same commit |
| A script that needs sudo | Install into the home directory. Do not use sudo |

## A quick check of the names (optional)

This command lists the files in a `bin` folder that do not match the format.
It is a help for the author. It is not a gate.

```sh
ls .specmgr/feat/<id>/bin | grep -vP '^([0-9]{3}\.[0-9]{3}-[0-9]{2}-[a-z0-9]+(-[a-z0-9]+)*\.(sh|py)|_common\.sh|README\.md)$'
```

No output means that all names are correct.
````

<!-- END SKILL.md -->

## Facts that the draft uses

The agent checked each fact in this repository on 2026-11-03.

| Fact | Where |
|---|---|
| Seven scripts and `_common.sh` and `README.md` are in `bin`; the seven names match the regex in the draft | `.specmgr/feat/feat-5-foundation-monorepo-ci/bin/` |
| Line 2 of each script is `# feat-5-foundation-monorepo-ci, Task 110.105` or `Task 110.110` | the same folder |
| Each of the seven scripts has `set -euo pipefail`; `_common.sh` has not (it is not run) | the same folder |
| `_common.sh` has `log`, `die`, `refuse_root`, `require_cmd`, `load_versions`, `require_var`, `check_sum`, `install_archive` | `bin/_common.sh` |
| Gate scripts have names for the function, are in `tools/gates/`, start from a recipe in the `justfile`, and have the task in the header only | `tools/gates/`, `justfile`, `tools/gates/README.md` |
| `feat-3-process-policy-baseline` has scripts with the same format and the extension `.py` | `.specmgr/feat/feat-3-process-policy-baseline/bin/` |
| A change in `tools/gates/` needs the review of a code owner | `tools/gates/README.md`, `.github/CODEOWNERS` |
