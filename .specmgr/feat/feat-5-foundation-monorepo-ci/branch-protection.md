# Instructions for the Branch Protection

This document is for the owner of the repository (dfch). It tells you how to set the branch
protection on GitHub so that the gates of feat-5-foundation-monorepo-ci stop each pull request that
does not obey them (REQ-013, ACC-012). The agent cannot do these steps. They need the rights of an
administrator of the repository.

Sources: DEC a56f231b-d063-4bef-bbc8-3deb4daff76e ("Branch protection must have all gates and one
review"), DEC 361678a6-f941-473b-a058-1ba2bacf7d3d (the list of gates), REQ-007 (CODEOWNERS).

## What to set

Set the rules for the branch `dev` (the branch that pull requests go to, and the default branch). The
rules for `main` are in the section "Ruleset for `main`" below.

| Setting | Value |
|---|---|
| Require a pull request before merging | On |
| Required approvals | 1 |
| Require review from Code Owners | On (the file is `.github/CODEOWNERS`) |
| Dismiss stale pull request approvals when new commits are pushed | On (suggestion) |
| Require status checks to pass before merging | On, with the checks in the next table |
| Require branches to be up to date before merging | On (suggestion) |
| Allowed merge methods | Squash only (a pull request into `dev` is a squash merge, see DEC d778d444-6227-4070-ae6e-b1083c78c58b) |
| Bypass list | Only the role `maintain` (the owner chose this for `dev`). Use the mode `pull_request` and not `always` (see "Bypass mode") |
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

#### Jobs that feat-6-contracts-openapi-pipeline added (required)

These five jobs are in `.github/workflows/ci.yml` since phase 130 of feat-6 (the workflow runs them for each pull request to `dev` and `main`), and `tools/gates/required-setup.txt` has a line for each. They are set as required checks in the rulesets: on 2026-11-07 (phase 135 of feat-6, task 135.100), the owner added them to the `required_status_checks` of the rulesets of `dev` (id 26472506) and of `main` (id 26481206). The column "Set" of this table now says Yes for each row. `test-gates` (set above) now also runs the tests of these gates, so its run takes longer (about 8 minutes on the machine of the author, with warm caches).

| Check (job) | Recipe | What it stops | Gate in DEC 361678a6 | Set in the rulesets of `dev` and `main` |
|---|---|---|---|---|
| `lint` | `just lint` | An OpenAPI file that breaks a rule of `tools/lint/ruleset.yaml` (Problem Details, `x-specmgr-req`, and the rules of Spectral). A warning is a failure | 3 | Yes (2026-11-07, task 135.100) |
| `breaking-changes` | `just breaking-changes` | A breaking change of `contracts/openapi.yaml` against the merge base of the base branch, with no entry in `tools/breaking/breaking-changes-ignore.txt` or with no higher `info.version` | 3 | Yes (2026-11-07, task 135.100) |
| `check-generated` | `just check-generated` | Generated code in `backend/src/generated` or `frontend/src/generated` that is not the code that `just generate` makes now: a file that is changed, deleted, extra, not tracked or ignored, or a missing mark | 4 | Yes (2026-11-07, task 135.100) |
| `compile` | `just compile` | A Maven module or a pnpm module that does not compile with the generated code | (feat-6, ACC-005) | Yes (2026-11-07, task 135.100) |
| `api-docs` | `just api-docs` | An OpenAPI file for which the generator `html2` makes no documentation. The job keeps `build/api-docs/` as the artifact `api-docs` | (feat-6, REQ-015) | Yes (2026-11-07, task 135.100) (it is an artifact job) |

When the owner sets the jobs: add the five names to the `contexts` of the call above, and to the `required_status_checks` of the ruleset JSON for `main` and of the real ruleset of `dev` (id 26472506). GitHub shows a check in the list only after it ran once in the last 7 days, so open a pull request first (the throwaway pull request of task 130.120 of feat-6 does this).

`compile` and `check-generated` must be added as required checks **together**: `compile` alone does not stop a broken committed generated Java file, because the Maven build makes the Java code again (from `contracts/openapi.yaml`) before it compiles it, and `check-generated` stops the same file (it compares the committed code with a new generation, before and after the build).

#### Jobs that feat-7-verification-architecture-tools added (not set yet)

These eleven jobs are in `.github/workflows/ci.yml` since phase 140 of feat-7 (Task 140.100, 2026-11-12), and
`tools/gates/required-setup.txt` has a line for each. They run the verification tools of feat-7 (unit and
integration tests, end-to-end tests with the accessibility check, mutation tests, property tests with random
data, architecture tests, and the comparison of the Structurizr workspace with the code). The tools operate as
a report without a threshold (the DEC 361678a6: no gate must stop a pull request before the walking skeleton
obeys it; the walking skeleton sets each threshold - the coverage and the mutation score - from the baseline
measured in the plan of feat-7): a red test or a failed run stops the job, but a low coverage or a low mutation
score does not. They are not set as required checks in the rulesets yet: the column "Set" of this table says No
for each row, and the owner sets them (as in phase 135 of feat-6) when the first run of the jobs is green. The
first real run of the jobs is with the push of feat-7 (the agent cannot run GitHub CI from the machine; the
static checks `just check-workflows` and `just check-pins` pass - an open item of the plan of feat-7).

| Check (job) | Recipe | What it stops | Gate in DEC 361678a6 | Set in the rulesets of `dev` and `main` |
|---|---|---|---|---|
| `test-unit-backend` | `just test-unit-backend` | A unit test of the Maven module that is red (JUnit, the property tests of jqwik and the architecture tests are in the normal run of surefire) | 6 (the tests part; the threshold for the coverage is the walking skeleton) | No (the owner sets it, an open item of feat-7) |
| `test-integration-backend` | `just test-integration-backend` | An integration test of the Maven module that is red (Testcontainers, one container postgres:16-alpine; the runner has Docker) | 6 (the tests part) | No (the owner sets it, an open item of feat-7) |
| `test-unit-frontend` | `just test-unit-frontend` | A unit test of the pnpm module that is red (Vitest) | 6 (the tests part) | No (the owner sets it, an open item of feat-7) |
| `test-e2e` | `just test-e2e` | An end-to-end test that is red, or a violation of the accessibility check (Playwright with the chromium browser, and axe-core; the recipe downloads the browser on the fresh runner) | 8 | No (the owner sets it, an open item of feat-7) |
| `test-random-backend` | `just test-random-backend` | A property test of the Maven module that is red (jqwik, the engine of the JUnit Platform) | 6 (the tests part) | No (the owner sets it, an open item of feat-7) |
| `test-random-frontend` | `just test-random-frontend` | A property test of the pnpm module that is red (fast-check) | 6 (the tests part) | No (the owner sets it, an open item of feat-7) |
| `mutation-backend` | `just mutation-backend` | A run of the mutation tool PIT that fails (the report is a console report and in target/pit-reports; a surviving mutant does not stop the job - no threshold for the mutation score, that is the walking skeleton) | 7 (the tool part; the threshold is the walking skeleton) | No (the owner sets it, an open item of feat-7) |
| `mutation-frontend` | `just mutation-frontend` | A run of the mutation tool Stryker that fails (the report is a console report and in mutation-report/; a surviving mutant does not stop the job - no threshold for the mutation score, that is the walking skeleton) | 7 (the tool part; the threshold is the walking skeleton) | No (the owner sets it, an open item of feat-7) |
| `architecture-backend` | `just architecture-backend` | An architecture rule of the Maven module that is violated (Spring Modulith: the module structure; ArchUnit: the layer rule) | 5 | No (the owner sets it, an open item of feat-7) |
| `architecture-frontend` | `just architecture-frontend` | An architecture rule of the pnpm module that is violated (ArchUniTS: the module structure in the slice form, the layers, and the imports) | 5 | No (the owner sets it, an open item of feat-7) |
| `architecture-model` | `just architecture-model` | A comparison of the Structurizr workspace with the code that is not successful (a package or a unit without a component in the model, or a dependency that is not in the model) | 5 (the comparison of the model) | No (the owner sets it, an open item of feat-7) |

When the owner sets the jobs: add the eleven names to the `contexts` of the call above, and to the
`required_status_checks` of the ruleset JSON for `main` and of the real ruleset of `dev` (id 26472506). GitHub
shows a check in the list only after it ran once in the last 7 days, so open a pull request first - the first
real run of these jobs is with the push of the feature (an open item of the plan of feat-7).

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
the names of the jobs. Note: this call sets the classic branch protection. The owner made a ruleset for
`dev` instead (id 26472506), so do not run this call in addition to the ruleset.

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

## Ruleset for `main`

The workflow runs for pull requests to `dev` and to `main`, so `main` can have the same protection as
`dev`. The rules below have the same shape as the real ruleset of `dev` (id 26472506, read with
`gh api repos/dfch/biz.dfch.SpecMgrDemo/rulesets/26472506` on 2026-11-03): deletion blocked,
force push blocked, a pull request with 1 approval, review of a code owner and stale approvals dismissed,
and the seven required checks (integration id 15368 is GitHub Actions) with the strict policy. There
are two differences:

- The target is `refs/heads/main` (the ruleset of `dev` has the default branch).
- Only the merge method "merge commit" is allowed (see "Release case" below). The ruleset of `dev`
  allows only the merge method "squash". This is on purpose: `dev` has one conventional commit for
  each pull request, and `main` must keep the commits of `dev` (see "Release case" below).

The bypass mode is `pull_request` in both rulesets (see "Bypass mode" below).

The agent did not make this ruleset. You apply it, and the order is important.

### The order

1. Merge PR #9 (it has the change of the trigger) into `dev`.
2. Bring the workflow and the gate files to `main` (the first release, see "Release case"). A pull request
   to `main` runs the checks only if its merge commit has the workflow file with the trigger for `main`.
   GitHub runs the workflow of a `pull_request` for the merge commit of the pull request (`GITHUB_SHA`).
   A pull request from `dev` has the file after step 1. A pull request from a branch that has the old
   `main` as its base has not.
3. Apply the ruleset for `main` last. If you apply it before step 2, each pull request to `main` waits
   for checks that never run.

### Steps in the web page

1. Open the repository on GitHub. Go to Settings, Rules, Rulesets, New ruleset, New branch ruleset.
2. Name: `main`. Enforcement status: Active.
3. Bypass list: add the role `maintain` with the mode "For pull requests only".
4. Target branches: Add target, Include by pattern, `main`.
5. Rules: turn on "Restrict deletions", "Block force pushes", "Require a pull request before merging" (1
   required approval, dismiss stale approvals, require review from Code Owners, allowed merge
   methods: Merge only) and "Require status checks to pass" (turn on "Require branches to be up to
   date before merging", and add the seven checks of the table above with the source GitHub Actions).
   The names of the checks are in the list because they ran on the pull requests to `dev`.
6. Click Create.

### Steps with the `gh` command

```bash
gh api --method POST repos/dfch/biz.dfch.SpecMgrDemo/rulesets --input - <<'JSON'
{
  "name": "main",
  "target": "branch",
  "enforcement": "active",
  "conditions": {
    "ref_name": { "include": ["refs/heads/main"], "exclude": [] }
  },
  "bypass_actors": [
    { "actor_id": 2, "actor_type": "RepositoryRole", "bypass_mode": "pull_request" }
  ],
  "rules": [
    { "type": "deletion" },
    { "type": "non_fast_forward" },
    {
      "type": "pull_request",
      "parameters": {
        "required_approving_review_count": 1,
        "dismiss_stale_reviews_on_push": true,
        "required_reviewers": [],
        "require_code_owner_review": true,
        "require_last_push_approval": false,
        "required_review_thread_resolution": false,
        "require_extra_approval_for_unattributed_changes": true,
        "allowed_merge_methods": ["merge"]
      }
    },
    {
      "type": "required_status_checks",
      "parameters": {
        "strict_required_status_checks_policy": true,
        "do_not_enforce_on_create": false,
        "required_status_checks": [
          { "context": "validate", "integration_id": 15368 },
          { "context": "commit-check", "integration_id": 15368 },
          { "context": "license-check", "integration_id": 15368 },
          { "context": "check-workflows", "integration_id": 15368 },
          { "context": "check-pins", "integration_id": 15368 },
          { "context": "check-sudo", "integration_id": 15368 },
          { "context": "test-gates", "integration_id": 15368 }
        ]
      }
    }
  ]
}
JSON
```

The `actor_id` 2 is the role `maintain`, the same value as in the ruleset of `dev`. To see the result, and to
compare it with `dev`: `gh api repos/dfch/biz.dfch.SpecMgrDemo/rulesets --jq '.[] | {id, name}'`, and
then `gh api repos/dfch/biz.dfch.SpecMgrDemo/rulesets/<id>`.

### Bypass mode: `pull_request` is better than `always`

The role `maintain` can bypass a ruleset. The mode decides how:

- `always`: the bypass works for a pull request and for a direct push. The owner can push to the branch
  with no pull request, no review and no check. The gates do not run for such a push, so a change
  can get into the branch with no trace of a check.
- `pull_request`: the bypass works only on a pull request. The owner must open a pull request, the
  checks run and are visible, and the owner can then merge it although the approval is missing (the
  author cannot approve the own pull request). A direct push is not possible.

Both rulesets, `dev` and `main`, use `pull_request` (checked with `gh api` on 2026-11-04).

### Release case: the commits of `dev` that are not in `main`

For a pull request from `dev` to `main`, `just commit-check` checks the range `origin/main..HEAD`. That is
each commit of `dev` that is not in `main`, also old commits from before the gates existed. The gate
does not skip a commit. On 2026-11-03, `origin/main` is the "Initial commit" only, and the range has 43
commits of `dev`. Four of them fail the commit check, because their scope is `dec` and not `feat-N`
(`bc2742a`, `42ad0e8`, `64cc6f5`, `c677418`, all `docs(dec): ...`). `just validate` passes for the
same range (40 documents linted, none failed). `dev` cannot be changed to fix the four messages
(the ruleset blocks a force push). The options for the first release (the owner decides):

- **Option A (the agent proposes it):** make `main` the same as `dev` with a fast-forward push, while `main`
  has no ruleset: `git push origin origin/dev:refs/heads/main`. `main` is only "Initial commit", which is
  an ancestor of `dev`, so this is a fast-forward. No pull request and no old commit is checked. Do it
  after PR #9 is merged into `dev`, and before you apply the ruleset. Each later release has only new commits.
- **Option B:** open the release pull request, let `commit-check` fail for the four commits, and merge
  with the bypass of the owner (the mode `pull_request` allows it). It is a one-time exception, and the
  failed check stays visible in the history of the pull request.
- **Option C:** change the gate so that it skips these four commits (a list of commit hashes in `tools/gates/`,
  which a code owner reviews). The agent did not do this, because it weakens the gate.

Two points are important for every later release:

- Merge a release pull request with a merge commit (so the ruleset above allows this method only).
  A squash or a rebase makes new commits that are not in `dev`, so the range of the next release has all
  commits of `dev` again, with the four old commits.
- A merge commit on `main` is not in `dev`. With the strict policy ("up to date before merging"),
  GitHub then shows the next release pull request as not up to date. Merge `main` into `dev` with a pull
  request to `dev` first. The commit check does not check merge commits.

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
  code owner" blocks each pull request. The owner chose a bypass for the role `maintain` in the
  ruleset of `dev`. A bypass lowers the value of the gates, because the owner can then merge with failed
  or missing checks. The mode `always` is the weaker one: it also allows a direct push with no pull
  request. The mode `pull_request` needs a pull request for each change. See "Bypass mode" above. The
  choice of the mode is a decision of the owner.
- **The workflow runs for pull requests to `dev` and to `main`.** The `justfile` compares with the branch that
  the pull request goes to (`origin/` and the variable `GITHUB_BASE_REF` of the runner, `origin/dev` if
  the variable is not set). So a pull request from `dev` to `main` (a release) has the seven checks, as
  soon as the ruleset for `main` exists (see "Ruleset for `main`"). Read "Release case" for the old
  commits of `dev` in the first release.
- **Gates that other features give later.** Add each new job to the list of required checks when its
  feature is merged. Use the table below. The names of the jobs are not fixed yet for the gates
  that have no feature.

| Gate in DEC 361678a6 | Feature | Status |
|---|---|---|
| 2. Traceability check | None. GitHub issue #8 is for it | No feature yet. The owner makes a FEAT later |
| 3. Linter and check for breaking changes of the OpenAPI file | feat-6-contracts-openapi-pipeline | Jobs `lint` and `breaking-changes` exist in `ci.yml` (phase 130). They are required checks in the rulesets of `dev` and `main` (2026-11-07, task 135.100) |
| 4. The generated code is the same as the code in the repository | feat-6-contracts-openapi-pipeline | Job `check-generated` exists in `ci.yml` (phase 130). It is a required check in the rulesets of `dev` and `main` (2026-11-07, task 135.100) |
| 5. Architecture tests | feat-7-verification-architecture-tools (expected) | Not started |
| 6. Unit tests and integration tests with a threshold for coverage | feat-7 (tools) and the walking skeleton (thresholds) (expected) | Not started |
| 7. Threshold for the mutation score | feat-7 (tools) and the walking skeleton (thresholds) (expected) | Not started |
| 8. End-to-end tests with an accessibility check | feat-7 (tools) and the walking skeleton (expected) | Not started |
| 9. Security checks (the SBOM part is in `license-check`) | None. GitHub issue #8 is for it | No feature yet. The owner makes a FEAT later |

  Gates 2 and 9 have no feature. The branch protection of this version cannot have them. Until a
  feature gives them, a pull request can merge with no traceability check and no security check.

- **After a change of the workflow.** A change to a job name changes the name of the check. Change the
  list of required checks in the same step, or each pull request waits for a check that never runs.
