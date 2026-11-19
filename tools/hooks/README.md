# hooks

The git hooks of `feat-48-pre-commit-hooks`. `just install-hooks` sets `core.hooksPath` to this folder, so that git runs the hooks of the folder before a commit and before a push. The install is opt-in (CI does not install the hooks) and idempotent (a second run changes nothing). Uninstall: `git config --unset core.hooksPath`.

Each hook is a shell script that calls the existing `just` recipes only (the one entry point). The three hooks `pre-commit`, `commit-msg` and `pre-push` exist in this folder.

| Hook | Content |
|---|---|
| `pre-commit` | Runs the six fast gates before a commit, as `just` recipes: `commit-check`, `validate`, `lint`, `check-pins`, `check-workflows`, `check-sudo`. It stops the commit on the first failing gate |
| `commit-msg` | Checks the subject line of the commit in progress with the `just` recipe `commit-message-check`, which applies the same rule as the `commit-check` gate: Conventional Commits with the feature scope (DEC a56f231b-d063-4bef-bbc8-3deb4daff76e: `type(feat-N): subject`) |
| `pre-push` | Re-runs the six fast gates against the base before a push, as `just` recipes: `commit-check`, `validate`, `lint`, `check-pins`, `check-workflows`, `check-sudo`. The range is the one of the checked-out `HEAD` (the `base` of the `justfile`), not the ref that is pushed: a branch that is not checked out, or a push from a detached `HEAD`, is not covered by the local backstop (CI remains the enforcement). It stops the push on the first failing gate |

## Opt-out

The hooks are bypassed with `git commit --no-verify` (the `pre-commit` and `commit-msg` hooks) and with `git push --no-verify` (the `pre-push` hook). The environment marker `SKIP_HOOKS_FOR_BULK`, when set and non-empty, makes all three hooks skip every gate and exit 0 with a notice. The marker is documented for the bulk commits of the coding agent, within the limits of DEC cc4449cd-78fb-452a-904f-7efda89cf004: an agent must not use it for a normal commit, and the `pre-push` hook is the backstop that re-checks the commits against the base.

A code owner reviews a change in this folder (see `.github/CODEOWNERS`).
