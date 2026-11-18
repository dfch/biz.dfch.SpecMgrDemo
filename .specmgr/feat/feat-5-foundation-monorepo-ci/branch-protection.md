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

#### Jobs that feat-7-verification-architecture-tools added (required)

These eleven jobs are in `.github/workflows/ci.yml` since phase 140 of feat-7 (Task 140.100, 2026-11-12), and
`tools/gates/required-setup.txt` has a line for each. They run the verification tools of feat-7 (unit and
integration tests, end-to-end tests with the accessibility check, mutation tests, property tests with random
data, architecture tests, and the comparison of the Structurizr workspace with the code). The tools operate as
a report without a threshold (the DEC 361678a6: no gate must stop a pull request before the walking skeleton
obeys it; the walking skeleton sets each threshold - the coverage and the mutation score - from the baseline
measured in the plan of feat-7): a red test or a failed run stops the job, but a low coverage or a low mutation
score does not. They are set as required checks in the rulesets: on 2026-11-15, the owner added them to the required checks of
the rulesets of `dev` (id 26472506) and of `main` (id 26481206). The column "Set" of this table now says Yes for
each row.

| Check (job) | Recipe | What it stops | Gate in DEC 361678a6 | Set in the rulesets of `dev` and `main` |
|---|---|---|---|---|
| `test-unit-backend` | `just test-unit-backend` | A unit test of the Maven module that is red (JUnit, the property tests of jqwik and the architecture tests are in the normal run of surefire) | 6 (the tests part; the threshold for the coverage is the walking skeleton) | Yes (2026-11-15) |
| `test-integration-backend` | `just test-integration-backend` | An integration test of the Maven module that is red (Testcontainers, one container postgres:16-alpine; the runner has Docker) | 6 (the tests part) | Yes (2026-11-15) |
| `test-unit-frontend` | `just test-unit-frontend` | A unit test of the pnpm module that is red (Vitest) | 6 (the tests part) | Yes (2026-11-15) |
| `test-e2e` | `just test-e2e` | An end-to-end test that is red, or a violation of the accessibility check (Playwright with the chromium browser, and axe-core; the recipe downloads the browser on the fresh runner) | 8 | Yes (2026-11-15) |
| `test-random-backend` | `just test-random-backend` | A property test of the Maven module that is red (jqwik, the engine of the JUnit Platform) | 6 (the tests part) | Yes (2026-11-15) |
| `test-random-frontend` | `just test-random-frontend` | A property test of the pnpm module that is red (fast-check) | 6 (the tests part) | Yes (2026-11-15) |
| `mutation-backend` | `just mutation-backend` | A run of the mutation tool PIT that fails (the report is a console report and in target/pit-reports; a surviving mutant does not stop the job - no threshold for the mutation score, that is the walking skeleton) | 7 (the tool part; the threshold is the walking skeleton) | Yes (2026-11-15) |
| `mutation-frontend` | `just mutation-frontend` | A run of the mutation tool Stryker that fails (the report is a console report and in mutation-report/; a surviving mutant does not stop the job - no threshold for the mutation score, that is the walking skeleton) | 7 (the tool part; the threshold is the walking skeleton) | Yes (2026-11-15) |
| `architecture-backend` | `just architecture-backend` | An architecture rule of the Maven module that is violated (Spring Modulith: the module structure; ArchUnit: the layer rule) | 5 | Yes (2026-11-15) |
| `architecture-frontend` | `just architecture-frontend` | An architecture rule of the pnpm module that is violated (ArchUniTS: the module structure in the slice form, the layers, and the imports) | 5 | Yes (2026-11-15) |
| `architecture-model` | `just architecture-model` | A comparison of the Structurizr workspace with the code that is not successful (a package or a unit without a component in the model, or a dependency that is not in the model) | 5 (the comparison of the model) | Yes (2026-11-15) |

When the owner sets the jobs: add the eleven names to the `contexts` of the call above, and to the
`required_status_checks` of the ruleset JSON for `main` and of the real ruleset of `dev` (id 26472506). GitHub
shows a check in the list only after it ran once in the last 7 days, so open a pull request first - the first
real run of these jobs is with the push of the feature (an open item of the plan of feat-7).

#### Jobs that feat-8-traceability-security-gates added (set on `dev` on 2026-11-16, not set on `main` yet; the state of 2026-11-17 is in the column "Set")

These four jobs are in `.github/workflows/ci.yml` since phase 140 of feat-8 (Task 140.100, 2026-11-15), and
`tools/gates/required-setup.txt` has a line for each. They are gate 2 and the three scans of gate 9 of DEC
361678a6-f941-473b-a058-1ba2bacf7d3d (GitHub issue #8). The workflow still has `on: pull_request` and
`permissions: contents: read` only. The agent cannot change the rulesets. The steps in "Steps for the owner for the gates of
feat-8" below were done on the decision of the owner: on 2026-11-16, the owner chose Option 2, and the agent ran the commands
and applied it to the ruleset of `dev`. The column "Set" says Yes (`dev` only) for `traceability`, `secret-scan` and
`workflow-scan`, and No for `vuln-scan` (not a required check, by the decision of the owner). The ruleset of `main` is not
changed yet (see "The result of the steps for the owner" below). The three scans were reports in feat-8 and are blocking
gates since feat-9: the section "The threshold of feat-9" below has the change and the steps for the owner. The agent read
the state again on 2026-11-17 (GET only), and it is the same as the state of 2026-11-16: the owner set `traceability`,
`secret-scan` and `workflow-scan` on `dev` (26 required checks), the owner did not set `vuln-scan`, and `main` has none of
the four.

| Check (job) | Recipe | What it stops | Gate in DEC 361678a6 | Set in the rulesets of `dev` and `main` |
|---|---|---|---|---|
| `traceability` | `just traceability` | A reference in the documents of `docs/` and `.specmgr/` that has no target; an `x-specmgr-req` in `contracts/openapi.yaml` that is not the identifier of a REQ; an identifier in `specmgr-req` of `model/workspace.json` or `vcr:<uuid>` in the name of a test that has no document; an approved REQ (the status `accepted` or `implemented`) with no VCR. A warning (no stop) for an approved REQ with no element in the model, or whose VCR is not in the name of a test | 2 (DEC f21920d2-4da5-4cf7-bd94-2e9bcba77342) | Yes on `dev` (2026-11-16, read again on 2026-11-17), no on `main` |
| `vuln-scan` | `just vuln-scan` | feat-8: a **failure of the tool** only (OSV-Scanner that does not run: no network, no answer of `api.osv.dev`, a SBOM file that cannot be read, a download with another sha256). **Since feat-9 (2026-11-17) it also stops for a finding that is Critical or High, and for a finding that is not in `tools/security/osv-baseline.txt`** (see "The threshold of feat-9" below) | 9 (the vulnerability part) | No on `dev` (not a required check, by the decision of the owner on 2026-11-16, read again on 2026-11-17), no on `main` (see "The threshold of feat-9") |
| `secret-scan` | `just secret-scan` | feat-8: a **failure of the tool** only (gitleaks that does not run: a wrong configuration, a base that does not exist, a shallow clone with no merge base, a download with another sha256). **Since feat-9 it also stops for a secret that is not in `tools/security/gitleaks-baseline.txt`** (gitleaks gives no severity) | 9 (the secret part) | Yes on `dev` (2026-11-16, read again on 2026-11-17), no on `main` |
| `workflow-scan` | `just workflow-scan` | feat-8: a **failure of the tool** only (zizmor that does not run: a file that cannot be read, no input). **Since feat-9 it also stops for a finding with the severity High, and for a finding that is not in `tools/security/zizmor-baseline.txt`** | 9 (the workflow part) | Yes on `dev` (2026-11-16, read again on 2026-11-17), no on `main` |

**CodeQL is the exception: it has no recipe and no job.** CodeQL is the fourth tool of gate 9. It runs as the hosted
default setup of GitHub (the workflow `CodeQL Setup`, which GitHub manages, and not a file of this repository), so no
recipe of the `justfile` starts it, `ci.yml` has no job for it, and `required-setup.txt` has no line for it. It is an
exception to the rule "each gate is a `just` recipe that a CI job starts" and to the wish that each gate runs on the
machine of a developer (REQ-002 and REQ-009 of feat-5-foundation-monorepo-ci). The deviation is recorded in DEC
93a6d588-e002-4daf-9a47-45e2d77786e9 (the section of CodeQL), and the setting is a report with no threshold since feat-8 (REQ-006 of
feat-8). The scan is not a check of the table above. If the owner wants CodeQL to stop a pull request, that is the
rule `code_scanning` of the ruleset (alert thresholds of the tool `CodeQL`) and not a job: the steps for it are in "The
threshold of feat-9" below (step 2), and the owner decides. CodeQL is active (default setup), but the blocking rule
`code_scanning` (alerts threshold: high_or_higher) is not in the rulesets yet (read on 2026-11-17).
The state on 2026-11-15: the default setup is `configured` and the first scan of `dev` has 0 alerts (the plan of feat-8,
the subsection Baseline).

### Steps for the owner for the gates of feat-8

The agent did not run any of these commands (all of them change a setting of the repository). They need the rights of an
administrator. The state that the agent read (GET only) on 2026-11-15 is in each step, so you can see what changes.

**The order.** Add the four checks to a ruleset only after the workflow with the four jobs is in the base branch of the
pull requests: for `dev` after the pull request of feat-8 is merged into `dev`, and for `main` after the first release that
brings `ci.yml` with the four jobs to `main`. Before that, each other pull request waits for a check that never runs (see
"After a change of the workflow"). GitHub shows a check in the web page only after it ran once in the last 7 days. The
pull request of feat-8 runs the four jobs, so that condition is met.

**Step 1: decide which of the four jobs are required checks.** A job that is a report is red for a failure of the tool (see
the column "What it stops" above). A required check that is red stops every pull request. `vuln-scan` uses the network
(the download of OSV-Scanner from GitHub and the query to `api.osv.dev`), so it has the highest risk of a red run that is
not about the pull request. The options:

- **Option 1: all four are required.** The gates of DEC 361678a6 are blocking, and a failure of a tool (also the network
  failure of `vuln-scan`) stops the pull request. It is the strongest and the most expensive choice: a time without service
  of `api.osv.dev` or of GitHub stops each merge until a re-run is green. The owner can use the bypass `pull_request`.
- **Option 2: `traceability`, `secret-scan` and `workflow-scan` are required, and `vuln-scan` is not.** `traceability` and
  `workflow-scan` need no network for the scan itself (only for the install of their tools), and `secret-scan` needs GitHub
  for the download of gitleaks on a fresh runner, which is the same risk as the other jobs. The report of `vuln-scan` is
  visible in the pull request, and a red run is a signal and not a block. The agent suggests this option as the middle way,
  but it is not a decision.
- **Option 3: only `traceability` is required (a gate that stops for an error), and the three reports are not.** The reports
  are visible in each pull request, and nothing in them can stop a merge.

The agent does not choose. A check that is not required still runs and shows its result in the pull request. You can change
the choice later with the same call (the list of names in `ADD`, see step 2).

**Step 2: add the chosen names to the `required_status_checks` of the rulesets of `dev` (id 26472506) and `main` (id
26481206).** The state on 2026-11-15: both rulesets are `active` and have 23 required checks (the integration id of GitHub
Actions is 15368). The ruleset of `dev` has `strict_required_status_checks_policy: true`, and the ruleset of `main` has
`false` (the text above says `true` for both: this is a difference that you may want to remove, and these steps do not
change it). `PUT` replaces the whole ruleset, so the commands read the ruleset, add the names (the filter removes a
name that is there twice, so you can run it again), write the body to a file that you can look at, and then send it. Set
`ADD` to the names of your choice from step 1 (the example has all four).

```bash
REPO=dfch/biz.dfch.SpecMgrDemo
ADD='["traceability","vuln-scan","secret-scan","workflow-scan"]'

for ID in 26472506 26481206; do
  gh api "repos/${REPO}/rulesets/${ID}" \
    | jq --argjson add "${ADD}" '{name, target, enforcement, conditions, bypass_actors,
        rules: (.rules | map(if .type == "required_status_checks"
          then .parameters.required_status_checks |= ((. + ($add | map({context: ., integration_id: 15368}))) | unique_by(.context))
          else . end))}' > "ruleset-${ID}.json"
done

# Look at both files first (27 required checks for the example), and then send them:
jq '.rules[] | select(.type == "required_status_checks") | .parameters.required_status_checks | map(.context)' ruleset-26472506.json ruleset-26481206.json
gh api --method PUT "repos/${REPO}/rulesets/26472506" --input ruleset-26472506.json
gh api --method PUT "repos/${REPO}/rulesets/26481206" --input ruleset-26481206.json
```

To check the result: `gh api repos/dfch/biz.dfch.SpecMgrDemo/rulesets/26472506 --jq '.rules[] | select(.type == "required_status_checks") | .parameters.required_status_checks | map(.context)'`
(and the same for `26481206` after the later step). The same in the web page: Settings, Rules, Rulesets, `dev` (and `main`), the rule "Require
status checks to pass", "Add checks", and search for each name. Then change the column "Set" of the table above to Yes with the
date (the agent can do this after you tell it the result).

**Step 3: turn on the Dependabot alerts.** The state on 2026-11-15: they are off (`GET repos/dfch/biz.dfch.SpecMgrDemo/vulnerability-alerts`
answers 404), and Dependabot security updates are `disabled`. The alerts need no file in the repository (they read the
dependency graph and the lock files). The command, and the check (the answer 204 means on, 404 means off):

```bash
gh api --method PUT repos/dfch/biz.dfch.SpecMgrDemo/vulnerability-alerts
gh api repos/dfch/biz.dfch.SpecMgrDemo/vulnerability-alerts --include | head -n 1
```

The page: Settings, Advanced Security (the page can be called Code security), the section Dependabot, the switch "Dependabot
alerts". The switch "Dependabot security updates" is a different setting and stays off (the pull requests that it opens
change the lock files and are not in the scope of feat-8).

**Step 4: turn on the secret scanning for the patterns that are not of a provider.** The state on 2026-11-15:
`secret_scanning` is `enabled`, `secret_scanning_push_protection` is `enabled`, and `secret_scanning_non_provider_patterns`
is `disabled` (it finds generic secrets such as a password in a connection string or a private key, and not the tokens of a
provider). The command, and the check:

```bash
gh api --method PATCH repos/dfch/biz.dfch.SpecMgrDemo --input - <<'JSON'
{ "security_and_analysis": { "secret_scanning_non_provider_patterns": { "status": "enabled" } } }
JSON
gh api repos/dfch/biz.dfch.SpecMgrDemo --jq '.security_and_analysis.secret_scanning_non_provider_patterns'
```

The page: Settings, Advanced Security (Code security), the section Secret Protection (Secret scanning), the switch for
"non-provider patterns" (the text can be "Scan for generic passwords"). This setting is separate from the job `secret-scan`
(gitleaks): GitHub scans the repository on its servers, and gitleaks scans the files and the range of the pull request in
CI. Both stay on.

**Step 5 (a check, no change): CodeQL.** `gh api repos/dfch/biz.dfch.SpecMgrDemo/code-scanning/default-setup --jq '.state'` must
answer `configured`. Nothing else is to do for CodeQL.

**The result of the steps for the owner (2026-11-16).** The steps above are the procedure, and their text keeps the state
of 2026-11-15. This is the state after the work of 2026-11-16. The agent ran the commands, and the owner made the decisions.

- **Step 1 and step 2, `dev`: done.** The owner chose Option 2, and the agent applied it to the ruleset of `dev` (id 26472506).
  `traceability`, `secret-scan` and `workflow-scan` are required checks. `vuln-scan` is not a required check: it stays a
  report that you can see in the pull request. The ruleset has 26 required checks now (23 and 3). The check of step 2 showed the result.
- **Step 2, `main`: not done yet.** The ruleset of `main` (id 26481206) is not changed. The decision of the owner is that all four
  jobs (`traceability`, `vuln-scan`, `secret-scan` and `workflow-scan`) become required checks on `main`. This happens
  after the first release that brings `ci.yml` with the four jobs to `main` (see "The order"). Then change the column
  "Set" of the table above for `main`.
- **Step 3: done.** The Dependabot alerts are on (the check answers 204). The Dependabot security updates stay off.
- **Step 4: not possible.** The REST call `PATCH repos/dfch/biz.dfch.SpecMgrDemo` answers 200, but it ignores the field
  `security_and_analysis`. A test with a control field (`secret_scanning_validity_checks`) and with the API version
  `2026-03-10` gave the same result. The owner found no page for the secret scanning and no switch for the non-provider
  patterns ("Scan for generic passwords") in the settings. The only item under Security and Quality, Secrets and
  variables, Secret Protection is "Push protection", and it is on. The state: the secret scanning is on, the push
  protection is on, and the CI job `secret-scan` (gitleaks) is a required check on `dev`. The non-provider patterns are
  off, and the owner cannot get to the setting.
- **Step 5: checked.** The state of CodeQL is `configured`.

## The threshold of feat-9 (the security jobs are blocking, and the CodeQL rule)

This section is for the owner (feat-9-walking-skeleton, Task 500.140, ACC-011). The agent changed no setting: it made the
three security jobs blocking gates (the files `tools/gates/*-scan.sh`, `tools/gates/security_threshold.py`, and the baseline
files `tools/security/*-baseline.txt`), and it read the state of the repository with `gh api` GET calls only (2026-11-17).

### What changed in the jobs

The names of the jobs and of the checks do not change (`vuln-scan`, `secret-scan`, `workflow-scan`), so each ruleset that
has a name keeps working. The job `secret-scan` has the new action `astral-sh/setup-uv` (the Python environment of the level
gate). The jobs stop (a red check) for these cases:

| Check | Red for | Green for |
|---|---|---|
| `vuln-scan` | A finding of OSV-Scanner that is Critical or High (CVSS 7.0 or more, in each case, also if the baseline has a line for it); a finding that is not in `tools/security/osv-baseline.txt`; a failure of the tool (no network, no answer of `api.osv.dev`, a download with another sha256, a SBOM that cannot be read) | No finding, or each finding is in the baseline and none is Critical or High (the state of the feature: the 5 findings of level Medium in the frontend, `minimatch@10.2.6` and `qs@6.15.1`). A line of the baseline that has no finding any more is a warning in the log (the job is green) |
| `secret-scan` | A secret that is not in `tools/security/gitleaks-baseline.txt` (gitleaks gives no severity, so the baseline is the only rule); a failure of the tool | No finding (the state of the feature: no line in the baseline) |
| `workflow-scan` | A finding of zizmor with the severity High; a finding that is not in `tools/security/zizmor-baseline.txt`; a failure of the tool | Each finding is in the baseline and none has the severity High (the state of the feature: 11 findings `artipacked`, Medium) |

A change of a baseline file needs the review of the code owner (CODEOWNERS covers `/tools/`). The rules and the way to change
a baseline are in `tools/security/README.md`.

### The state that the agent read on 2026-11-17 (GET only)

| What | State |
|---|---|
| Ruleset `dev` (id 26472506) | `active`, 26 required checks. The four checks of feat-8 are: `traceability` yes, `secret-scan` yes, `workflow-scan` yes, `vuln-scan` **no**. No rule `code_scanning` |
| Ruleset `main` (id 26481206) | `active`, 23 required checks (the checks of feat-5, feat-6 and feat-7). None of the four checks of feat-8. No rule `code_scanning` |
| CodeQL | `gh api repos/dfch/biz.dfch.SpecMgrDemo/code-scanning/default-setup`: `state` is `configured` (languages actions, java-kotlin, javascript-typescript, python, query suite `default`). The analyses of the tool `CodeQL` exist for `refs/heads/dev` and for `refs/pull/<n>/head` (0 results each). The repository is public, and it has 0 code scanning alerts (all states) |

### Step 1: add `vuln-scan` to the required checks of `dev` now (the four checks of `main` come with the first release)

The jobs are blocking gates now, so the question of the feat-8 steps ("Step 1: decide which of the four jobs are required
checks") is answered for three of them on `dev`. What is open: `vuln-scan` on `dev` (it uses the network: the download of
OSV-Scanner from GitHub and the query to `api.osv.dev`, so a time without service of these makes the check red until a re-run is
green, as the feat-8 steps say), and the four checks on `main`. The agent suggests: add `vuln-scan` to `dev` (the gate has a
baseline now, so a red check is a real finding or a real failure), and add all four checks to `main` **only when the first
release is made**, because that release brings `ci.yml` with the four jobs to `main` (the order of "Steps for the owner for the
gates of feat-8" applies: before that, each pull request to `main` waits for a check that never runs). So the commands below
are for `dev` now, and the part for `main` is the later step, in the same block, and it is turned off. It is a decision of the
owner. Note on `vuln-scan` on `dev`: the gate reads an online database, so a new advisory for a package of the baseline or for
another package turns the check red without a change of the code (see `tools/security/README.md`); this is probably why
`vuln-scan` is not a required check on `dev` now.

```bash
REPO=dfch/biz.dfch.SpecMgrDemo
# ruleset id and the names to add (the filter removes a name that is there twice, so you can run it again)
ADD_DEV='["vuln-scan"]'
ADD_MAIN='["traceability","vuln-scan","secret-scan","workflow-scan"]'

# NOW: the ruleset of dev only.
PAIRS=("26472506:${ADD_DEV}")
# LATER, WHEN THE FIRST RELEASE IS MADE (not now): the owner turns the next line on, and the ruleset of main gets the four checks.
# PAIRS+=("26481206:${ADD_MAIN}")

for PAIR in "${PAIRS[@]}"; do
  ID="${PAIR%%:*}"; ADD="${PAIR#*:}"
  gh api "repos/${REPO}/rulesets/${ID}" \
    | jq --argjson add "${ADD}" '{name, target, enforcement, conditions, bypass_actors,
        rules: (.rules | map(if .type == "required_status_checks"
          then .parameters.required_status_checks |= ((. + ($add | map({context: ., integration_id: 15368}))) | unique_by(.context))
          else . end))}' > "ruleset-${ID}.json"
done

# Look at the file first (27 required checks for dev; with the later step 27 for main too), and then send it:
jq '.rules[] | select(.type == "required_status_checks") | .parameters.required_status_checks | map(.context)' ruleset-26472506.json
gh api --method PUT "repos/${REPO}/rulesets/26472506" --input ruleset-26472506.json
# LATER, WITH THE FIRST RELEASE (the same for main):
# jq '.rules[] | select(.type == "required_status_checks") | .parameters.required_status_checks | map(.context)' ruleset-26481206.json
# gh api --method PUT "repos/${REPO}/rulesets/26481206" --input ruleset-26481206.json
```

To check the result: `gh api repos/dfch/biz.dfch.SpecMgrDemo/rulesets/26472506 --jq '.rules[] | select(.type == "required_status_checks") | .parameters.required_status_checks | map(.context)'`
(and the same for `26481206`). The same in the web page: Settings, Rules, Rulesets, `dev` (and `main`), the rule "Require
status checks to pass", "Add checks", and search for the name. `PUT` replaces the whole ruleset, as in the feat-8 steps.

### Step 2: the rule `code_scanning` (CodeQL stops a pull request for a new finding that is Critical or High)

This is the native check of GitHub for the option B of the plan of feat-9 (REQ-007, ACC-008). CodeQL runs as the hosted default
setup, so a job and a recipe are not possible, and the ruleset is the place of the check. The rule `code_scanning` of a
ruleset (the API: `rules[].type` is `code_scanning`, the parameter `code_scanning_tools` has `tool`, `security_alerts_threshold`
and `alerts_threshold`) blocks a pull request when the code scanning of the tool `CodeQL` has a **new** alert at or above the
threshold. The values:

- `tool`: `CodeQL` (the name that the analyses of the default setup have: `gh api repos/dfch/biz.dfch.SpecMgrDemo/code-scanning/analyses --jq '.[].tool.name' | sort -u`).
- `security_alerts_threshold`: `high_or_higher` (the security alerts with the security severity Critical or High; the other values are `none`, `critical`, `medium_or_higher` and `all`).
- `alerts_threshold`: `none` (the alerts with no security severity, for example the quality alerts, do not block; the other levels of CodeQL are out of scope of feat-9; the other values are `errors`, `errors_and_warnings` and `all`).

The rule needs code scanning results for the commit and for the reference that GitHub updates (the text of the API: "code
scanning must be enabled and have results for both the commit and the reference being updated"). The default setup runs the
analysis for the pull requests (the analyses of `refs/pull/52/head` show it), so the rule waits for the analysis and then
decides. Set it on `dev` (id 26472506) and on `main` (id 26481206). The commands read the ruleset, remove an old rule
`code_scanning` (so you can run them again), add the new one, write the body to a file that you can look at, and then send it:

```bash
REPO=dfch/biz.dfch.SpecMgrDemo

for ID in 26472506 26481206; do
  gh api "repos/${REPO}/rulesets/${ID}" \
    | jq '{name, target, enforcement, conditions, bypass_actors,
        rules: ((.rules | map(select(.type != "code_scanning"))) + [{
          type: "code_scanning",
          parameters: { code_scanning_tools: [ {
            tool: "CodeQL",
            security_alerts_threshold: "high_or_higher",
            alerts_threshold: "none" } ] } }])}' > "ruleset-${ID}.json"
done

# Look at both files first (the rule code_scanning is the last rule), and then send them:
jq '.rules[] | select(.type == "code_scanning")' ruleset-26472506.json ruleset-26481206.json
gh api --method PUT "repos/${REPO}/rulesets/26472506" --input ruleset-26472506.json
gh api --method PUT "repos/${REPO}/rulesets/26481206" --input ruleset-26481206.json
```

To check the result (a rule `code_scanning` for the branch): `gh api repos/dfch/biz.dfch.SpecMgrDemo/rules/branches/dev --jq '.[] | select(.type == "code_scanning")'`
(and `main`). The same in the web page: Settings, Rules, Rulesets, `dev` (and `main`), the rule "Require code scanning results",
"Add tool", the tool `CodeQL`, "Security alerts": "High or higher", "Alerts": "None", Save. Then open a pull request and look at
the merge box: it shows the result of the rule for code scanning. The first pull request after the change is the real test
of the setting. If the rule blocks a pull request for which the default setup made no analysis (for example a
pull request that changes only Markdown), the way back is the same call without the rule: remove the rule in the web page, or
send the file of the ruleset with the rule `code_scanning` removed. The agent cannot test this without changing the setting.

### Step 3: the column "Set"

When the owner has done the steps, tell the agent the result, and the agent changes the column "Set" of the tables above (the
date and the ruleset) and the table at the end of this document. The plan of feat-9 records the decision for CodeQL (ACC-008)
in the task 500.130: the native mechanism exists (read on 2026-11-17). CodeQL is active (default setup), but the blocking rule
`code_scanning` (alerts threshold: high_or_higher) is not in the rulesets yet; it is there only after step 2.

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
  feature is merged. Use the table below. The names of the jobs are the names of the recipes.

| Gate in DEC 361678a6 | Feature | Status |
|---|---|---|
| 2. Traceability check | feat-8-traceability-security-gates (GitHub issue #8) | Job `traceability` exists in `ci.yml` (phase 140 of feat-8). It is a required check in the ruleset of `dev` (2026-11-16). It becomes a required check on `main` after the first release that brings `ci.yml` with the four jobs to `main` (see "Steps for the owner for the gates of feat-8") |
| 3. Linter and check for breaking changes of the OpenAPI file | feat-6-contracts-openapi-pipeline | Jobs `lint` and `breaking-changes` exist in `ci.yml` (phase 130). They are required checks in the rulesets of `dev` and `main` (2026-11-07, task 135.100) |
| 4. The generated code is the same as the code in the repository | feat-6-contracts-openapi-pipeline | Job `check-generated` exists in `ci.yml` (phase 130). It is a required check in the rulesets of `dev` and `main` (2026-11-07, task 135.100) |
| 5. Architecture tests | feat-7-verification-architecture-tools | Jobs `architecture-backend`, `architecture-frontend` and `architecture-model` exist in `ci.yml` (phase 140 of feat-7, as reports without a threshold). They are required checks in the rulesets of `dev` and `main` (2026-11-15) |
| 6. Unit tests and integration tests with a threshold for coverage | feat-7 (tools) and the walking skeleton (thresholds; the feature is not yet created) | Jobs `test-unit-backend` and `test-integration-backend` exist in `ci.yml` (phase 140 of feat-7, as reports without a threshold; the threshold for the coverage is the walking skeleton). They are required checks in the rulesets of `dev` and `main` (2026-11-15) |
| 7. Threshold for the mutation score | feat-7 (tools) and the walking skeleton (thresholds; the feature is not yet created) | Jobs `mutation-backend` and `mutation-frontend` exist in `ci.yml` (phase 140 of feat-7, as reports without a threshold; the threshold for the mutation score is the walking skeleton). They are required checks in the rulesets of `dev` and `main` (2026-11-15) |
| 8. End-to-end tests with an accessibility check | feat-7 (tools) and the walking skeleton (the feature is not yet created) | Job `test-e2e` (with the accessibility check of axe-core) exists in `ci.yml` (phase 140 of feat-7, as a report without a threshold). It is a required check in the rulesets of `dev` and `main` (2026-11-15) |
| 9. Security checks (the SBOM part is in `license-check`) | feat-8-traceability-security-gates (GitHub issue #8), feat-9-walking-skeleton (the threshold) | Jobs `vuln-scan`, `secret-scan` and `workflow-scan` exist in `ci.yml` (phase 140 of feat-8). They are blocking gates since feat-9 (a finding that is Critical or High, a finding that is not in the baseline, and a failure of the tool stop a job). `secret-scan` and `workflow-scan` are required checks in the ruleset of `dev` (2026-11-16, read again on 2026-11-17). `vuln-scan` is not a required check on `dev` (it was a report, by the decision of the owner; the owner decides again, see "The threshold of feat-9"). On `main`, all four jobs become required checks after the first release that brings `ci.yml` with the four jobs to `main`. CodeQL is the hosted default setup of GitHub: it has no recipe and no job (the exception is stated above); its native check is the rule `code_scanning` of the ruleset ("The threshold of feat-9", step 2) |

  Gates 2 and 9 have the feature feat-8-traceability-security-gates (the jobs `traceability`, `vuln-scan`,
  `secret-scan` and `workflow-scan`, and CodeQL as the hosted default setup). Since 2026-11-16, the names
  `traceability`, `secret-scan` and `workflow-scan` are in the `required_status_checks` of the ruleset of `dev`. The
  ruleset of `main` does not have the four names yet (the steps for the owner above). Until the owner adds them, these
  jobs run for each pull request to `main`, but they do not stop a merge there (and `vuln-scan` does not stop a merge on
  `dev`). The three scans were reports with no threshold in feat-8. The threshold is set by
  feat-9-walking-skeleton (Phase 500): the baseline files are in `tools/security/`, and the steps for the owner are in
  "The threshold of feat-9" above.

- **After a change of the workflow.** A change to a job name changes the name of the check. Change the
  list of required checks in the same step, or each pull request waits for a check that never runs.
