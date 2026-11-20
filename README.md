# biz.dfch.SpecMgrDemo
This project demonstrates the use of SpecMgr

## Git Hooks

The git hooks give the fast local signal that CI gives only after the round trip of a pull request. They are local and opt-in: CI remains the enforcement. The three hooks are shell scripts in `tools/hooks/` that call the `just` recipes only. `pre-commit` runs the six fast gates (`commit-check`, `validate`, `lint`, `check-pins`, `check-workflows`, `check-sudo`) before a commit and stops the commit on the first failing gate. `commit-msg` checks the subject of the commit in progress with the Conventional Commits feature-scope rule. `pre-push` re-runs the six gates against the base before a push; it is the backstop for a commit made with the bypass.

Install the hooks with `just install-hooks` (opt-in, idempotent). Uninstall with `git config --unset core.hooksPath`.

Bypass the hooks with `git commit --no-verify` or `git push --no-verify` (for a person). For the bulk commits of a coding agent, the environment marker `SKIP_HOOKS_FOR_BULK`, set and non-empty, makes all three hooks skip every gate. Within the limits of DEC cc4449cd-78fb-452a-904f-7efda89cf004, an agent must not use the marker for a normal commit.

The details of the hooks are in `tools/hooks/README.md`.
