# hooks

The git hooks of `feat-48-pre-commit-hooks`. `just install-hooks` sets `core.hooksPath` to this folder, so that git runs the hooks of the folder before a commit and before a push. The install is opt-in (CI does not install the hooks) and idempotent (a second run changes nothing). Uninstall: `git config --unset core.hooksPath`.

Each hook is a shell script that calls the existing `just` recipes only (the one entry point). The hook scripts arrive in Phase 110 (`pre-commit`, `commit-msg`) and Phase 120 (`pre-push`) of the feature; Phase 100 delivers the folder and this README.

| Hook | Content |
|---|---|
| `pre-commit` (Phase 110) | Runs the six fast gates before a commit, as `just` recipes: `commit-check`, `validate`, `lint`, `check-pins`, `check-workflows`, `check-sudo`. It stops the commit on the first failing gate |
| `commit-msg` (Phase 110) | Checks the message of the commit in progress with the same rule as the `commit-check` gate: Conventional Commits with the feature scope (DEC a56f231b-d063-4bef-bbc8-3deb4daff76e: `type(feat-N): subject`) |
| `pre-push` (Phase 120) | Re-runs the six fast gates against the base before a push, as `just` recipes: `commit-check`, `validate`, `lint`, `check-pins`, `check-workflows`, `check-sudo` |

The hooks are bypassed with `git commit --no-verify` (details are documented in Phase 130).

A code owner reviews a change in this folder (see `.github/CODEOWNERS`).
