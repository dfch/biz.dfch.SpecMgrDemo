# feat-5-foundation-monorepo-ci: install scripts

These scripts install the tools of the toolchain on the machine of the author. CI does not use them. They put the tools in the home directory, they need no special rights, and they stop if the user is root.

The versions and the checksums are in `tools/versions.env`. A script compares the download with the checksum in this file. A change of a version needs a new checksum in the same commit.

Run the scripts in this order. Each script can be run again, and does nothing if the tool is already installed.

| Script | Purpose |
|---|---|
| `110.105-01-install-node.sh` | Node (LTS) |
| `110.110-01-install-jdk.sh` | Eclipse Temurin JDK |
| `110.110-02-install-maven.sh` | Apache Maven |
| `110.110-03-install-pnpm.sh` | pnpm (standalone release, no corepack: Node 26 has none) |
| `110.110-04-install-just.sh` | just |
| `110.110-05-write-env.sh` | Writes the environment file and adds a line to `~/.bashrc` |
| `110.110-06-verify-tools.sh` | Checks that each tool is the pinned version, from the home directory. Does not change anything |
| `_common.sh` | Shared functions (not run directly) |

```sh
cd .specmgr/feat/feat-5-foundation-monorepo-ci/bin
for s in 110.105-01-install-node.sh 110.110-0[1-5]-*.sh; do ./"$s"; done
./110.110-06-verify-tools.sh
```

## What the scripts change

| Where | What |
|---|---|
| `~/.local/opt/biz.dfch.SpecMgrDemo/` | One folder for each tool and version (for example `jdk-21.0.13_9`). Set `TOOLS_HOME` to use another place |
| `~/.config/biz.dfch.SpecMgrDemo/env.sh` | Sets `JAVA_HOME` and puts the tools first in the `PATH`, so the JDK 21 is used and not the JDK of the system |
| `~/.bashrc` | Two lines at the end (a comment and a line that reads `env.sh`). Added only if they are not there. Use `--no-profile` with `110.110-05-write-env.sh` to skip this and use `source ~/.config/biz.dfch.SpecMgrDemo/env.sh` |

The system is not changed. The JDK and the Node of the system stay as they are.

The line in `~/.bashrc` works in a new interactive shell. A script or a tool that starts a shell that is not interactive does not read `~/.bashrc`. In this case use `source ~/.config/biz.dfch.SpecMgrDemo/env.sh`.

## Update a tool

1. Change the version and the checksum in `tools/versions.env`. Copy the checksum from the file that the vendor publishes, and read the license file of the new release (see the license table in the plan).
2. Run the install script of the tool, then `110.110-05-write-env.sh` and `110.110-06-verify-tools.sh`.
3. Change the version in the CI workflow. A `just` recipe checks that both are the same.

## Remove

Delete the folder `~/.local/opt/biz.dfch.SpecMgrDemo/`, delete `~/.config/biz.dfch.SpecMgrDemo/`, and delete the two lines with the text `biz.dfch.SpecMgrDemo` from `~/.bashrc`.
