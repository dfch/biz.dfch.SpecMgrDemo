# Instructions for the Branch Protection

This document is for the owner of the repository (dfch). It tells you how to set the branch
protection on GitHub so that the gates of feat-5-foundation-monorepo-ci stop each pull request that
does not obey them (REQ-013, ACC-012). The agent cannot do these steps. They need the rights of an
administrator of the repository.

Sources: DEC a56f231b-d063-4bef-bbc8-3deb4daff76e ("Branch protection must have all gates and one
review"), DEC 361678a6-f941-473b-a058-1ba2bacf7d3d (the list of gates), REQ-007 (CODEOWNERS).

## What to set

Set the rules for the branch `dev` (the branch that pull requests go to, and the default branch).

| Setting | Value |
|---|---|
| Require a pull request before merging | On |
| Required approvals | 1 |
| Require review from Code Owners | On (the file is `.github/CODEOWNERS`) |
| Dismiss stale pull request approvals when new commits are pushed | On (suggestion) |
| Require status checks to pass before merging | On, with the checks in the next table |
| Require branches to be up to date before merging | On (suggestion) |
| Do not allow bypassing the above settings (also for administrators) | On |
| Allow force pushes | Off |
| Allow deletions | Off |

### Required status checks

The name of a check is the name of the job in `.github/workflows/ci.yml`. Each job starts one
`just` recipe. You can run the same recipe on your machine.

| Check (job) | Recipe | What it stops | Gate in DEC 361678a6 |
|---|---|---|---|
| `validate` | `just validate` | A changed document that is not valid for specmgr | 1 (the STE check is on hold) |
| `commit-check` | `just commit-check` | A commit message that is not `type(feat-N): subject` | 11 (DEC a56f231b) |
| `license-check` | `just license-check` | A dependency with a license that is not permitted or not known. The job also keeps the SBOM as an artifact | 10, and the SBOM part of 9 |
| `check-workflows` | `just check-workflows` | A `run:` step that is not `just <recipe>` with a recipe in the `justfile` | (feat-5, REQ-009) |
| `check-pins` | `just check-pins` | A `uses:` that is not a full SHA with a comment, an action that is not in the license table, a tool version that is not the same as in `tools/versions.env` | (feat-5, REQ-015) |
| `check-sudo` | `just check-sudo` | A script that uses `sudo` | (feat-5, REQ-008) |
| `test-gates` | `just test-gates` | A gate that does not stop for bad input (the tests of the gates, and the license gate with its fixtures) | (feat-5) |

## Steps in the web page

1. Open the repository on GitHub. Go to Settings, Branches (or Settings, Rules, Rulesets).
2. Add a rule for the branch `dev`.
3. Turn on the settings in the first table.
4. In "Require status checks", add each check of the second table. GitHub shows a check in the
   search field only after the check ran one time on the repository (in the last 7 days). Open
   one pull request first, wait for the run of the workflow, and then add the checks.
5. Save the rule.

## Steps with the `gh` command

You can set the same rule with one call. Run it as the owner (an administrator). The `contexts` are
the names of the jobs.

```bash
gh api --method PUT repos/dfch/biz.dfch.SpecMgrDemo/branches/dev/protection --input - <<'JSON'
{
  "required_status_checks": {
    "strict": true,
    "contexts": [
      "validate",
      "commit-check",
      "license-check",
      "check-workflows",
      "check-pins",
      "check-sudo",
      "test-gates"
    ]
  },
  "enforce_admins": true,
  "required_pull_request_reviews": {
    "required_approving_review_count": 1,
    "require_code_owner_reviews": true,
    "dismiss_stale_reviews": true
  },
  "restrictions": null,
  "allow_force_pushes": false,
  "allow_deletions": false
}
JSON
```

To see the result: `gh api repos/dfch/biz.dfch.SpecMgrDemo/branches/dev/protection`.

## Check CODEOWNERS

GitHub can check the file `.github/CODEOWNERS` only for the default branch, so do this after the
first merge into `dev`:

```bash
gh api repos/dfch/biz.dfch.SpecMgrDemo/codeowners/errors
```

The answer must have an empty list of errors. The file gives dfch as the owner of `/docs/dec/`,
`/.github/workflows/`, `/.github/CODEOWNERS`, `/justfile` and `/tools/`. A pull request that changes
one of these paths needs the review of dfch. This includes the gate scripts, the list of
permitted licenses (`tools/license/permitted-licenses.txt`), the table of names, the list of
allowed actions, and the version file.

## Points that need your attention

- **The author cannot approve the own pull request.** GitHub does not count the approval of the
  author. If dfch is the author and the only code owner, the rule "1 approval and the review of a
  code owner" blocks each pull request. You have three choices: a second account that is a code
  owner, a rule that lets you bypass (this lowers the value of the gates), or a team with a second
  person. This is a decision of the owner.
- **The workflow runs for pull requests to `dev` only.** A pull request from `dev` to `main` (a release)
  has no check in this version, because the gates compare with `origin/dev`. If `main` needs a
  protection, make a new decision first (which gates, and which base).
- **Gates that other features give later.** Add each new job to the list of required checks when its
  feature is merged. Use the table below. The names of the jobs are not fixed yet for the gates
  that have no feature.

| Gate in DEC 361678a6 | Feature | Status |
|---|---|---|
| 2. Traceability check | None. GitHub issue #8 is for it | No feature yet. The owner makes a FEAT later |
| 3. Linter and check for breaking changes of the OpenAPI file | feat-6-contracts-openapi-pipeline (expected) | Not started |
| 4. The generated code is the same as the code in the repository | feat-6-contracts-openapi-pipeline (expected) | Not started |
| 5. Architecture tests | feat-7-verification-architecture-tools (expected) | Not started |
| 6. Unit tests and integration tests with a threshold for coverage | feat-7 (tools) and the walking skeleton (thresholds) (expected) | Not started |
| 7. Threshold for the mutation score | feat-7 (tools) and the walking skeleton (thresholds) (expected) | Not started |
| 8. End-to-end tests with an accessibility check | feat-7 (tools) and the walking skeleton (expected) | Not started |
| 9. Security checks (the SBOM part is in `license-check`) | None. GitHub issue #8 is for it | No feature yet. The owner makes a FEAT later |

  Gates 2 and 9 have no feature. The branch protection of this version cannot have them. Until a
  feature gives them, a pull request can merge with no traceability check and no security check.

- **After a change of the workflow.** A change to a job name changes the name of the check. Change the
  list of required checks in the same step, or each pull request waits for a check that never runs.
