#!/usr/bin/env bash
# feat-5-foundation-monorepo-ci, Tasks 130.110 to 130.145 (the tests of the gates)
#
# Self-test of the gates: each gate runs with good input (it must pass) and with bad input (it
# must stop with the exit code and the message that the test expects). The license gate has its
# own test with fixtures (test-license-gate.sh).
#
# Usage: selftest.sh
#
# The sections of the findings of the review of feat-5 (E1: manifests outside the scanned paths, E2: the
# rest of the workflow, G1: the Maven pin, G2: the checksums of the tools) have their own cases below.
#
# The bad input is made in a temporary folder. Only the fixtures for check-sudo.sh are files
# (tools/gates/fixtures/*.fixture). They have the extension .fixture, so that no gate reads
# them as a script. The script stops (exit code 1) if one case does not give the expected
# result. It does not change the repository.

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/_lib.sh"

require_cmd git
require_cmd uv
require_cmd just

work="$(mktemp -d)"
trap 'rm -rf "${work}"' EXIT

passed=0
failed=0

# expect <exit code> <text in the output> <description> <command...>
expect() {
    local want_code="$1" want_text="$2" description="$3"
    shift 3
    local output code
    set +e
    output="$("$@" 2>&1)"
    code=$?
    set -e
    if [[ ${code} -eq ${want_code} && "${output}" == *"${want_text}"* ]]; then
        echo "ok   ${description}"
        passed=$((passed + 1))
    else
        echo "FAIL ${description}: expected exit code ${want_code} and '${want_text}', got exit code ${code}"
        echo "${output}" | sed -e 's/^/     | /'
        failed=$((failed + 1))
    fi
}

section() { echo; echo "== $*"; }

real_workflow="${REPO_ROOT}/.github/workflows/ci.yml"
real_justfile="${REPO_ROOT}/justfile"
real_versions="${REPO_ROOT}/tools/versions.env"
real_allowed="${REPO_ROOT}/tools/license/allowed-actions.txt"

# ---------------------------------------------------------------------------------------------
section "commit-check.sh: subject lines (Task 130.120)"
for message in \
    "feat(feat-5): add the gates" \
    "fix(feat-12): stop the crash" \
    "docs(feat-1): record the answer" \
    "chore(feat-5)!: remove the old script" \
    "revert(feat-5): undo the change" \
    "ci(feat-123): add a job"; do
    expect 0 "OK:" "good: ${message}" "${GATES_DIR}/commit-check.sh" --message "${message}"
done
for message in \
    "add the gates" \
    "feat: add the gates" \
    "feat(5): add the gates" \
    "feat(feat-): add the gates" \
    "feat(feat-x): add the gates" \
    "feat(foo-5): add the gates" \
    "feat(feat-5) add the gates" \
    "feat(feat-5):add the gates" \
    "feat(feat-5):  add the gates" \
    "feat(feat-5): " \
    "Feat(feat-5): add the gates" \
    "feature(feat-5): add the gates" \
    "Merge branch 'dev' into feat-5" \
    "Revert \"feat(feat-5): add the gates\"" \
    "fixup! feat(feat-5): add the gates" \
    "feat(feat-5, feat-6): add the gates"; do
    expect 1 "NOT CORRECT" "bad: ${message}" "${GATES_DIR}/commit-check.sh" --message "${message}"
done

# ---------------------------------------------------------------------------------------------
section "commit-check.sh: a git repository (Task 130.120)"
repo="${work}/commits"
git init -q -b base "${repo}"
git_in() { git -C "${repo}" -c user.name=test -c user.email=test@example.invalid -c commit.gpgsign=false "$@"; }
git_in commit -q --allow-empty -m "chore(feat-5): start"
git_in switch -q -c good
git_in commit -q --allow-empty -m "feat(feat-5): one"
git_in commit -q --allow-empty -m "docs(feat-5): two"
expect 0 "2 commit message(s) correct" "two good commits" env GATE_WORK_ROOT="${repo}" "${GATES_DIR}/commit-check.sh" base
git_in switch -q -c bad
git_in commit -q --allow-empty -m "wrong message"
expect 1 "FAIL" "one bad commit among the commits" env GATE_WORK_ROOT="${repo}" "${GATES_DIR}/commit-check.sh" base
git_in switch -q -c merged good
git_in switch -q -c side base
git_in commit -q --allow-empty -m "feat(feat-5): on the side"
git_in switch -q merged
git_in merge -q --no-ff side -m "Merge side into merged"
expect 0 "correct" "a merge commit with a free message is not checked" env GATE_WORK_ROOT="${repo}" "${GATES_DIR}/commit-check.sh" base
git_in switch -q good
expect 0 "No commit in" "no commit after the base" env GATE_WORK_ROOT="${repo}" "${GATES_DIR}/commit-check.sh" good
expect 1 "does not exist" "a base that does not exist" env GATE_WORK_ROOT="${repo}" "${GATES_DIR}/commit-check.sh" no-such-base

# The base of a pull request to `main` is origin/main, and the base of a pull request to `dev` is origin/dev
# (the branches of the clone of actions/checkout). The release case: the range origin/main..HEAD has each
# commit of `dev` that is not in `main`, also the old ones. The gate does not hide an old commit that is not
# correct (feat-5, the follow-up change for the ruleset of main).
git_in update-ref refs/remotes/origin/main base
git_in update-ref refs/remotes/origin/dev base
git_in switch -q good
expect 0 "2 commit message(s) correct" "base origin/main: two good commits" env GATE_WORK_ROOT="${repo}" "${GATES_DIR}/commit-check.sh" origin/main
expect 0 "2 commit message(s) correct" "base origin/dev: two good commits" env GATE_WORK_ROOT="${repo}" "${GATES_DIR}/commit-check.sh" origin/dev
git_in switch -q bad
expect 1 "FAIL" "base origin/main: a bad commit stops the gate" env GATE_WORK_ROOT="${repo}" "${GATES_DIR}/commit-check.sh" origin/main
# release: origin/main is the older branch, `dev` has an old commit with another scope and a new commit after it
git_in switch -q -c release-dev base
git_in commit -q --allow-empty -m "docs(dec): an old commit with a scope that is not feat-N"
git_in commit -q --allow-empty -m "feat(feat-5): a new commit"
expect 1 "FAIL" "release case: an old commit in origin/main..HEAD with another scope stops the gate (it is not hidden)" \
    env GATE_WORK_ROOT="${repo}" "${GATES_DIR}/commit-check.sh" origin/main
expect 1 "1 of 2 commit message(s) not correct" "release case: the count of the commits of the range" \
    env GATE_WORK_ROOT="${repo}" "${GATES_DIR}/commit-check.sh" origin/main
git_in update-ref refs/remotes/origin/main release-dev~1
expect 0 "1 commit message(s) correct" "release case: when main has the old commit, only the new commit is in the range" \
    env GATE_WORK_ROOT="${repo}" "${GATES_DIR}/commit-check.sh" origin/main
git_in switch -q good

# ---------------------------------------------------------------------------------------------
section "justfile: the base of the gates follows GITHUB_BASE_REF"
# base_case <description> <expected base> <command...>: the output of `just --evaluate base` must be exactly the
# expected value. (The tests must not depend on the variable of the runner, so each case sets or removes it.)
base_case() {
    local description="$1" want="$2" got
    shift 2
    got="$("$@" 2>&1)" || true
    if [[ "${got}" == "${want}" ]]; then
        echo "ok   ${description}"
        passed=$((passed + 1))
    else
        echo "FAIL ${description}: expected '${want}', got '${got}'"
        failed=$((failed + 1))
    fi
}
base_case "base: GITHUB_BASE_REF is not set: origin/dev" "origin/dev" env -u GITHUB_BASE_REF just --justfile "${real_justfile}" --evaluate base
base_case "base: GITHUB_BASE_REF is empty (an event that is not a pull request): origin/dev" "origin/dev" \
    env GITHUB_BASE_REF= just --justfile "${real_justfile}" --evaluate base
base_case "base: GITHUB_BASE_REF=dev: origin/dev" "origin/dev" env GITHUB_BASE_REF=dev just --justfile "${real_justfile}" --evaluate base
base_case "base: GITHUB_BASE_REF=main: origin/main" "origin/main" env GITHUB_BASE_REF=main just --justfile "${real_justfile}" --evaluate base
base_case "base: GITHUB_BASE_REF=release/1: origin/release/1" "origin/release/1" \
    env GITHUB_BASE_REF=release/1 just --justfile "${real_justfile}" --evaluate base
# The recipes validate and commit-check give the base to their gate script (the dry run prints the command).
dry_run() { env "$1" just --justfile "${real_justfile}" --dry-run "$2"; }
expect 0 '130.120 "origin/main"' "commit-check with GITHUB_BASE_REF=main compares with origin/main" dry_run GITHUB_BASE_REF=main commit-check
expect 0 '130.110 "origin/main"' "validate with GITHUB_BASE_REF=main compares with origin/main" dry_run GITHUB_BASE_REF=main validate
expect 0 '130.120 "origin/dev"' "commit-check with GITHUB_BASE_REF=dev compares with origin/dev" dry_run GITHUB_BASE_REF=dev commit-check
expect 0 '130.110 "origin/dev"' "validate with GITHUB_BASE_REF=dev compares with origin/dev" dry_run GITHUB_BASE_REF=dev validate
expect 0 '130.120 "origin/dev"' "commit-check with no GITHUB_BASE_REF compares with origin/dev" dry_run -uGITHUB_BASE_REF commit-check
expect 0 '130.110 "origin/dev"' "validate with no GITHUB_BASE_REF compares with origin/dev" dry_run -uGITHUB_BASE_REF validate

# ---------------------------------------------------------------------------------------------
section "check-workflows.sh (Task 130.140)"
real_required="${GATES_DIR}/required-setup.txt"
wf() {
    # wf <folder> <steps>: write a workflow that has the trigger, the permissions and the job (validate) that
    # the policy wants, with the steps (the text of the steps starts with 6 spaces)
    mkdir -p "$1"
    cat >"$1/ci.yml" <<YAML
name: T
on:
  pull_request:
    branches:
      - dev
      - main
permissions:
  contents: read
jobs:
  validate:
    name: validate
    runs-on: ubuntu-latest
    steps:
$2
YAML
}
# a required-setup.txt for these workflows: the job validate with no action
printf 'ci.yml validate\n' >"${work}/required-test.txt"
run_wf() { "${GATES_DIR}/check-workflows.sh" "${real_justfile}" "$1" "${work}/required-test.txt"; }
run_real_wf() { "${GATES_DIR}/check-workflows.sh" "${real_justfile}" "$1" "${2:-${real_required}}"; }

mkdir -p "${work}/wf-real" && cp "${real_workflow}" "${work}/wf-real/ci.yml"
expect 0 "RESULT: PASS" "the real workflow" run_real_wf "${work}/wf-real"
wf "${work}/wf-good" "      - run: just validate"
expect 0 "RESULT: PASS" "just <recipe>" run_wf "${work}/wf-good"
wf "${work}/wf-good2" "      - run: |
          just validate"
expect 0 "RESULT: PASS" "a block scalar with one line" run_wf "${work}/wf-good2"

wf "${work}/wf-1" "      - run: curl https://example.invalid/install.sh | sh"
expect 1 "is not exactly" "run: a command that is not just" run_wf "${work}/wf-1"
wf "${work}/wf-2" "      - run: just no-such-recipe"
expect 1 "is not in the justfile" "run: a recipe that is not in the justfile" run_wf "${work}/wf-2"
wf "${work}/wf-3" "      - run: just validate && echo done"
expect 1 "is not exactly" "run: just with a second command" run_wf "${work}/wf-3"
wf "${work}/wf-4" "      - run: |
          just validate
          curl https://example.invalid/x"
expect 1 "is not exactly" "run: a block scalar with two lines" run_wf "${work}/wf-4"
wf "${work}/wf-5" "      - run: just _gate validate-docs.sh 130.110 origin/dev"
expect 1 "is not exactly" "run: a private recipe with the helper arguments" run_wf "${work}/wf-5"
wf "${work}/wf-6" "      - run: just validate extra-argument"
expect 1 "is not exactly" "run: just with an argument" run_wf "${work}/wf-6"
wf "${work}/wf-7" "      - run: just \${{ github.event.pull_request.title }}"
expect 1 "is not exactly" "run: just with an expression" run_wf "${work}/wf-7"
wf "${work}/wf-8" "      - run: just validate
        shell: python {0}"
expect 1 "shell" "a step with a shell key" run_wf "${work}/wf-8"
wf "${work}/wf-9" "      - run: just validate
        run: curl https://example.invalid/x"
expect 2 "twice" "a key that is twice in a step" run_wf "${work}/wf-9"
wf "${work}/wf-10" "      - name: nothing"
expect 1 "no \`run:\` and no \`uses:\`" "a step with no run and no uses" run_wf "${work}/wf-10"
mkdir -p "${work}/wf-11"
cat >"${work}/wf-11/ci.yml" <<'YAML'
name: T
on: pull_request
jobs:
  j:
    uses: example/repo/.github/workflows/x.yml@main
YAML
expect 2 "has no steps" "a job that calls a workflow" run_wf "${work}/wf-11"
mkdir -p "${work}/wf-12"
cat >"${work}/wf-12/ci.yml" <<'YAML'
name: T
on: pull_request
defaults:
  run:
    shell: python {0}
jobs:
  j:
    runs-on: ubuntu-latest
    steps:
      - run: just validate
YAML
expect 1 "defaults.run.shell" "a default shell for the workflow" run_wf "${work}/wf-12"
mkdir -p "${work}/wf-empty"
expect 2 "no workflow file" "a folder with no workflow" run_wf "${work}/wf-empty"
expect 2 "does not exist" "a folder that does not exist" run_wf "${work}/no-such-folder"
wf "${work}/wf-13" "      - run: just validate
      - run: just validate"
expect 1 "has 2 \`run:\` steps" "a job with two run steps" run_wf "${work}/wf-13"
wf "${work}/wf-14" "      - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # actions/checkout v7.0.1"
expect 1 "has 0 \`run:\` steps" "a job with no run step" run_wf "${work}/wf-14"

# ---------------------------------------------------------------------------------------------
section "check-workflows.sh: the rest of the workflow (finding E2)"
# wf_case <name> <exit code> <text> <description> <sed expression>: change the real workflow with sed. The
# gate must stop (the real workflow passes: see above). Each case is a change that passed the gate before E2.
wf_case() {
    local name="$1" code="$2" text="$3" description="$4" expression="$5"
    mkdir -p "${work}/wfc-${name}"
    sed -e "${expression}" "${real_workflow}" >"${work}/wfc-${name}/ci.yml"
    if cmp -s "${real_workflow}" "${work}/wfc-${name}/ci.yml"; then
        echo "FAIL ${description}: the sed expression did not change the workflow"
        failed=$((failed + 1))
        return
    fi
    expect "${code}" "${text}" "${description}" run_real_wf "${work}/wfc-${name}"
}
job_line='s|^    timeout-minutes: 15$|&\n'      # a line after the first job key (the job validate)
run_line='s|^      - run: just validate$|&\n'  # a line after the run step of the job validate
wf_case jobiffalse 1 "has the key \`if\`, which is not allowed" "job: if: false" "${job_line}    if: false|"
wf_case jobifexpr 1 "has the key \`if\`, which is not allowed" "job: if with an expression" "${job_line}    if: github.actor == 'dfch'|"
wf_case jobcoe 1 "has the key \`continue-on-error\`" "job: continue-on-error: true" "${job_line}    continue-on-error: true|"
wf_case jobifcoe 1 "has the key \`if\`" "job: if: false and continue-on-error: true" "${job_line}    if: false\n    continue-on-error: true|"
wf_case stepcoe 1 "has the key \`continue-on-error\`" "run step: continue-on-error: true" "${run_line}        continue-on-error: true|"
wf_case stepiffalse 1 "has the key \`if\`" "run step: if: false" "${run_line}        if: false|"
wf_case stepifcancelled 1 "has the key \`if\`" "run step: the allowed if (it is only for the artifact step)" '/^      - run: just commit-check$/s|$|\n        if: ${{ !cancelled() }}|'
wf_case workdir 1 "has the key \`working-directory\`" "run step: working-directory" "${run_line}        working-directory: tools|"
wf_case stepenvpath 1 "has the key \`env\`" "run step: env: PATH" "${run_line}        env:\n          PATH: /tmp/evil|"
wf_case stepenvjust 1 "has the key \`env\`" "run step: env: JUST_JUSTFILE" "${run_line}        env:\n          JUST_JUSTFILE: /tmp/evil/justfile|"
wf_case jobenv 1 "has the key \`env\`" "job: env" "${job_line}    env:\n      PATH: /tmp/evil|"
wf_case wfenv 1 "has the key \`env\`" "workflow: env" 's|^permissions:$|env:\n  JUST_JUSTFILE: /tmp/evil/justfile\npermissions:|'
wf_case wfdefaults 1 "has the key \`defaults\`" "workflow: defaults with a working directory" 's|^permissions:$|defaults:\n  run:\n    working-directory: tools\npermissions:|'
wf_case jobdefaults 1 "has the key \`defaults\`" "job: defaults with a working directory" "${job_line}    defaults:\n      run:\n        working-directory: tools|"
wf_case jobshell 1 "defaults.run.shell" "job: defaults with a shell" "${job_line}    defaults:\n      run:\n        shell: python {0}|"
wf_case stepshell 1 "shell" "run step: shell" "${run_line}        shell: bash|"
wf_case container 1 "has the key \`container\`" "job: container" "${job_line}    container: alpine:3.20|"
wf_case services 1 "has the key \`services\`" "job: services" "${job_line}    services:\n      db:\n        image: postgres|"
wf_case strategy 1 "has the key \`strategy\`" "job: strategy with a matrix and an exclusion" "${job_line}    strategy:\n      matrix:\n        os: [a, b]\n        exclude:\n          - os: a|"
wf_case jobneeds 1 "has the key \`needs\`" "job: needs" "${job_line}    needs: commit-check|"
wf_case workflowconcurrency 1 "has the key \`concurrency\`" "workflow: concurrency" 's|^permissions:$|concurrency: x\npermissions:|'
wf_case ifother 1 "\`if: \${{ always() }}\` is not allowed" "artifact step: another if" 's|^        if: ${{ !cancelled() }}$|        if: ${{ always() }}|'
wf_case ifremoved 0 "RESULT: PASS" "artifact step: no if (the gate does not need it)" '/^        if: ${{ !cancelled() }}$/d'
# the trigger
wf_case targettrigger 1 "\`on:\` is" "trigger: pull_request_target" 's|^  pull_request:$|  pull_request_target:|'
wf_case pushtrigger 1 "\`on:\` is" "trigger: push in addition" 's|^  pull_request:$|  push:\n    branches:\n      - dev\n  pull_request:|'
wf_case dispatch 1 "\`on:\` is" "trigger: workflow_dispatch in addition" 's|^  pull_request:$|  workflow_dispatch:\n  pull_request:|'
wf_case branchonlydev 1 "\`on:\` is" "trigger: the branches are dev only (main is missing)" '/^      - main$/d'
wf_case branchonlymain 1 "\`on:\` is" "trigger: the branches are main only (dev is missing)" '/^      - dev$/d'
wf_case branchmore 1 "\`on:\` is" "trigger: the branches are dev, main and another one" 's|^      - main$|&\n      - other|'
wf_case branchmaster 1 "\`on:\` is" "trigger: the branch master and not main" 's|^      - main$|      - master|'
wf_case branchorder 1 "\`on:\` is" "trigger: the branches main and dev (the list is compared exactly, in this order)" \
    's|^      - dev$|      - TMP|;s|^      - main$|      - dev|;s|^      - TMP$|      - main|'
wf_case branchpattern 1 "\`on:\` is" "trigger: a branch pattern (all branches)" 's|^      - main$|      - "**"|'
wf_case pathsignore 1 "\`on:\` is" "trigger: paths-ignore" 's|^      - main$|&\n    paths-ignore:\n      - "tools/**"|'
wf_case typesonly 1 "\`on:\` is" "trigger: types" 's|^      - main$|&\n    types: [labeled]|'
wf_case branchesignore 1 "\`on:\` is" "trigger: branches-ignore" 's|^      - main$|&\n    branches-ignore:\n      - feat-x|'
wf_case nobranches 1 "\`on:\` is" "trigger: pull_request with no branches (all branches)" '/^    branches:$/,/^      - main$/d'
wf_case plainon 1 "\`on:\` is" "trigger: on: pull_request (a text)" '/^on:$/,/^      - main$/c\on: pull_request'
wf_case liston 1 "\`on:\` is" "trigger: on: [pull_request] (a list)" '/^on:$/,/^      - main$/c\on: [pull_request]'
wf_case notrigger 1 "exactly one \`on:\` key" "trigger: no on key" '/^on:$/,/^      - main$/d'
# the permissions
wf_case writeall 1 "\`permissions:\` of the workflow is" "permissions: write-all" '/^permissions:$/,/^  contents: read$/c\permissions: write-all'
wf_case readall 1 "\`permissions:\` of the workflow is" "permissions: read-all" '/^permissions:$/,/^  contents: read$/c\permissions: read-all'
wf_case contentswrite 1 "\`permissions:\` of the workflow is" "permissions: contents: write" 's|^  contents: read$|  contents: write|'
wf_case extraperm 1 "\`permissions:\` of the workflow is" "permissions: an extra permission" 's|^  contents: read$|&\n  pull-requests: write|'
wf_case nopermissions 1 "\`permissions:\` of the workflow is None" "permissions: missing" '/^permissions:$/,/^  contents: read$/d'
wf_case jobwriteall 1 "\`permissions:\` is 'write-all'" "job: permissions: write-all" "${job_line}    permissions: write-all|"
wf_case jobperm 1 "\`permissions:\` is" "job: permissions: contents: write" "${job_line}    permissions:\n      contents: write|"
wf_case jobpermok 0 "RESULT: PASS" "job: permissions: contents: read (the same as the workflow)" "${job_line}    permissions:\n      contents: read|"
# the setup actions
wf_case nojava 1 "lacks the required action(s) actions/setup-java" "license-check: setup-java removed" '/actions\/setup-java@/,/java-version:/d'
wf_case nonode 1 "lacks the required action(s) actions/setup-node" "license-check: setup-node removed" '/actions\/setup-node@/,/node-version:/d'
wf_case nopnpm 1 "lacks the required action(s) pnpm/action-setup" "license-check: pnpm/action-setup removed" '/pnpm\/action-setup@/,/version: "12.16.1"/d'
wf_case noupload 1 "lacks the required action(s) actions/upload-artifact" "license-check: upload-artifact removed" '/actions\/upload-artifact@/,/if-no-files-found: error/d'
wf_case nojust 1 "lacks the required action(s) extractions/setup-just" "all jobs: setup-just removed" '/extractions\/setup-just@/,/just-version:/d'
wf_case nouv 1 "lacks the required action(s) astral-sh/setup-uv" "all jobs with uv: setup-uv removed" '/astral-sh\/setup-uv@/,/version: "0.13.7"/d'
wf_case nocheckout 1 "lacks the required action(s) actions/checkout" "all jobs: checkout removed" '/actions\/checkout@/,/persist-credentials: false/d'
wf_case extraaction 1 "has the action(s) actions/setup-node, which are not in required-setup.txt" "commit-check: an extra action" \
    's|^      - run: just commit-check$|      - uses: actions/setup-node@949feb2413d6458794dcd2491c4babbbce0c15c1 # actions/setup-node v7.1.0\n        with:\n          node-version: "26.13.0"\n&|'
wf_case twocheckout 1 "has the action(s) actions/checkout" "commit-check: the checkout twice" \
    's|^      - run: just commit-check$|      - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # actions/checkout v7.0.1\n&|'
# the jobs
wf_case nojobsudo 1 "the job 'check-sudo' of ci.yml is in required-setup.txt, but not in the workflows" "a job of the file is missing" \
    '/^  check-sudo:$/,/^      - run: just check-sudo$/d'
wf_case renamejob 1 "is not in required-setup.txt" "a job with another identifier than the recipe" 's|^  validate:$|  validate-x:|'
wf_case jobname 1 "\`name:\` is 'Validate'" "a job with another name than the identifier" 's|^    name: validate$|    name: Validate|'
wf_case jobnamegone 1 "\`name:\` is None" "a job with no name" '0,/^    name: validate$/{/^    name: validate$/d}'
wf_case recipe 1 "the recipe of the job is \`just validate\`, but it must be \`just commit-check\`" "a job that starts another recipe" \
    's|^      - run: just commit-check$|      - run: just validate|'
mkdir -p "${work}/wfc-extrajob"
cp "${real_workflow}" "${work}/wfc-extrajob/ci.yml"
cat >>"${work}/wfc-extrajob/ci.yml" <<'YAML'

  extra:
    name: extra
    runs-on: ubuntu-latest
    steps:
      - run: just validate
YAML
expect 1 "job 'extra' is not in required-setup.txt" "a job that is not in required-setup.txt" run_real_wf "${work}/wfc-extrajob"
mkdir -p "${work}/wfc-extrafile"
cp "${real_workflow}" "${work}/wfc-extrafile/ci.yml"
cp "${real_workflow}" "${work}/wfc-extrafile/other.yml"
expect 1 "other.yml: job 'validate' is not in required-setup.txt" "a second workflow file that is not in required-setup.txt" run_real_wf "${work}/wfc-extrafile"
mkdir -p "${work}/wfc-nofile"
cp "${real_workflow}" "${work}/wfc-nofile/renamed.yml"
expect 1 "is in required-setup.txt, but not in the workflows" "the workflow file of required-setup.txt is missing" run_real_wf "${work}/wfc-nofile"
# the file required-setup.txt itself
grep -v '^ci.yml commit-check ' "${real_required}" >"${work}/required-missing-line.txt"
expect 1 "job 'commit-check' is not in required-setup.txt" "required-setup.txt has no line for a job" run_real_wf "${work}/wf-real" "${work}/required-missing-line.txt"
sed -e 's#^ci.yml license-check actions/checkout#ci.yml license-check actions/checkout actions/cache#' "${real_required}" >"${work}/required-extra.txt"
expect 1 "lacks the required action(s) actions/cache" "required-setup.txt requires an action that the job has not" run_real_wf "${work}/wf-real" "${work}/required-extra.txt"
printf 'ci.yml validate not-an-action\n' >"${work}/required-bad-form.txt"
expect 2 "the form is not" "required-setup.txt has a wrong line" run_real_wf "${work}/wf-real" "${work}/required-bad-form.txt"
printf '# nothing\n' >"${work}/required-empty.txt"
expect 2 "has no job" "required-setup.txt has no job" run_real_wf "${work}/wf-real" "${work}/required-empty.txt"
printf 'ci.yml validate\nci.yml validate\n' >"${work}/required-twice.txt"
expect 2 "is twice in the file" "required-setup.txt has a job twice" run_real_wf "${work}/wf-real" "${work}/required-twice.txt"
expect 2 "cannot read" "required-setup.txt does not exist" run_real_wf "${work}/wf-real" "${work}/no-such-required.txt"
# the data file of the repository is the one that the workflow needs: each of the 7 jobs is in it
expect 0 "7 run step(s)" "required-setup.txt of the repository has the 7 gate jobs" run_real_wf "${work}/wf-real"

# ---------------------------------------------------------------------------------------------
section "check-pins.sh (Task 130.142)"
run_pins() { "${GATES_DIR}/check-pins.sh" "${real_versions}" "$1" "${real_allowed}"; }
# pin_case <name> <exit code> <text> <description> <sed expression>: change the real workflow with sed
pin_case() {
    local name="$1" code="$2" text="$3" description="$4" expression="$5"
    mkdir -p "${work}/pin-${name}"
    sed -e "${expression}" "${real_workflow}" >"${work}/pin-${name}/ci.yml"
    if cmp -s "${real_workflow}" "${work}/pin-${name}/ci.yml"; then
        echo "FAIL ${description}: the sed expression did not change the workflow"
        failed=$((failed + 1))
        return
    fi
    expect "${code}" "${text}" "${description}" run_pins "${work}/pin-${name}"
}
checkout_sha="3d3c42e5aac5ba805825da76410c181273ba90b1"
expect 0 "RESULT: PASS" "the real workflow" run_pins "${work}/wf-real"
pin_case tag 1 "is not \`<owner>/<name>@<40" "uses: a tag and not a SHA" "s#actions/checkout@${checkout_sha}#actions/checkout@v7.0.1#"
pin_case branch 1 "is not \`<owner>/<name>@<40" "uses: a branch and not a SHA" "s#actions/checkout@${checkout_sha}#actions/checkout@main#"
pin_case short 1 "is not \`<owner>/<name>@<40" "uses: a short SHA" "s#actions/checkout@${checkout_sha}#actions/checkout@3d3c42e#"
pin_case nocomment 1 "has no comment" "uses: no comment" "s# \# actions/checkout v7.0.1##"
pin_case wrongname 1 "must be \`# actions/checkout <tag>\`" "uses: the comment has another name" "s#\# actions/checkout v7.0.1#\# actions/checkout-x v7.0.1#"
pin_case notag 1 "must be \`# actions/checkout <tag>\`" "uses: the comment has no tag" "s#\# actions/checkout v7.0.1#\# actions/checkout#"
pin_case branchtag 1 "must be \`# actions/checkout <tag>\`" "uses: the comment has a branch and no release tag" "s#\# actions/checkout v7.0.1#\# actions/checkout main#"
pin_case othersha 1 "but the table has" "uses: another SHA than the table" "s#actions/checkout@${checkout_sha}#actions/checkout@0123456789abcdef0123456789abcdef01234567#"
pin_case othertag 1 "but the table has" "uses: another tag than the table" "s#\# actions/checkout v7.0.1#\# actions/checkout v7.0.2#"
pin_case unknown 1 "is not in the table of allowed actions" "uses: an action that is not in the table" "s#actions/checkout@${checkout_sha} \# actions/checkout v7.0.1#example/tool@0123456789abcdef0123456789abcdef01234567 \# example/tool v1.0.0#"
pin_case local 1 "is not \`<owner>/<name>@<40" "uses: a local action" "s#actions/checkout@${checkout_sha} \# actions/checkout v7.0.1#./local-action#"
pin_case docker 1 "is not \`<owner>/<name>@<40" "uses: a Docker image" "s#actions/checkout@${checkout_sha} \# actions/checkout v7.0.1#docker://alpine:3.20#"
pin_case quoted 1 "not the same" "uses: a value in quotes (not read by the text check)" "s#uses: actions/checkout@${checkout_sha}#uses: \"actions/checkout@${checkout_sha}\"#"
pin_case justver 1 "just-version" "version: just is not the version in versions.env" "s#just-version: \"1.59.0\"#just-version: \"1.58.0\"#"
pin_case uvver 1 "\`version\` is 0.13.6" "version: uv is not the version in versions.env" "s#version: \"0.13.7\"#version: \"0.13.6\"#"
pin_case latest 1 "\`version\` is latest" "version: latest" "s#version: \"0.13.7\"#version: \"latest\"#"
pin_case float 1 "must be a text in quotes" "version: a number and not a text" "s#version: \"0.13.7\"#version: 0.13#"
pin_case noinput 1 "has no input \`just-version\`" "version: the input is missing" "/just-version:/d"
pin_case extraver 1 "has a version that the gate cannot check" "version: an input with a version that has no mapping" "s#persist-credentials: false#persist-credentials: false\n          tool-version: \"1\"#"
# The setup actions of the license-check job of the real workflow (Java, Node and pnpm for the SBOM tools)
pin_case javamiss 1 "has no input \`java-version\`" "license-check job: the Java version is missing" "/java-version:/d"
pin_case javaver 1 "\`java-version\` is 21," "license-check job: the Java version is not the one of versions.env" "s#java-version: \"$(version_of JDK_VERSION)\"#java-version: \"21\"#"
pin_case javadist 1 "must be temurin" "license-check job: the Java distribution is not temurin" "s#distribution: temurin#distribution: zulu#"
pin_case nodemiss 1 "has no input \`node-version\`" "license-check job: the Node version is missing" "/node-version:/d"
pin_case nodever 1 "\`node-version\` is 24.0.0" "license-check job: the Node version is not the one of versions.env" "s#node-version: \"$(version_of NODE_VERSION)\"#node-version: \"24.0.0\"#"
pin_case pnpmmiss 1 "pnpm/action-setup has no input \`version\`" "license-check job: the pnpm version is missing" "/version: \"$(version_of PNPM_VERSION)\"/d"
pin_case pnpmver 1 "PNPM_VERSION in tools/versions.env" "license-check job: the pnpm version is not the one of versions.env" "s#version: \"$(version_of PNPM_VERSION)\"#version: \"10.0.0\"#"

# A workflow with each setup action, with the versions of versions.env, and with changes
all_setup="${work}/pin-all"
mkdir -p "${all_setup}"
cat >"${all_setup}/ci.yml" <<YAML
name: T
on: pull_request
jobs:
  j:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/setup-java@b843ebf9b913146b38da2eaa7aeddf76074ae1ad # actions/setup-java v6.1.0
        with:
          distribution: temurin
          java-version: "$(version_of JDK_VERSION)"
      - uses: actions/setup-node@949feb2413d6458794dcd2491c4babbbce0c15c1 # actions/setup-node v7.1.0
        with:
          node-version: "$(version_of NODE_VERSION)"
      - uses: pnpm/action-setup@ea17c68df8912ef543352723c149a84f56e3d413 # pnpm/action-setup v6.1.0
        with:
          version: "$(version_of PNPM_VERSION)"
      - uses: astral-sh/setup-uv@68559e99cc807c1eb7e9238fd43a15bba460eec2 # astral-sh/setup-uv v10.3.3
        with:
          version: "$(version_of UV_VERSION)"
      - uses: extractions/setup-just@53165ef7e734c5c07cb06b3c8e7b647c5aa16db3 # extractions/setup-just v4.0.0
        with:
          just-version: "$(version_of JUST_VERSION)"
      - uses: actions/upload-artifact@cf430e030ddbb5b0abf93d22962f4752f3646cd9 # actions/upload-artifact v7.0.2
        with:
          name: x
          path: build/
YAML
expect 0 "RESULT: PASS" "all setup actions, with the versions of versions.env" run_pins "${all_setup}"
pin_all_case() {
    # pin_all_case <name> <text> <description> <sed expression>: change the workflow with all setup actions
    local name="$1" text="$2" description="$3" expression="$4"
    mkdir -p "${work}/pin-all-${name}"
    sed -e "${expression}" "${all_setup}/ci.yml" >"${work}/pin-all-${name}/ci.yml"
    expect 1 "${text}" "${description}" run_pins "${work}/pin-all-${name}"
}
pin_all_case java "java-version" "setup-java: the JDK version is not the one of versions.env" \
    "s#java-version: \"$(version_of JDK_VERSION)\"#java-version: \"21\"#"
pin_all_case dist "distribution" "setup-java: the distribution is not temurin" "s#distribution: temurin#distribution: zulu#"
pin_all_case node "node-version" "setup-node: the Node version is not the one of versions.env" \
    "s#node-version: \"$(version_of NODE_VERSION)\"#node-version: \"24.0.0\"#"
pin_all_case pnpm "PNPM_VERSION" "pnpm/action-setup: the version is not the one of versions.env" \
    "s#version: \"$(version_of PNPM_VERSION)\"#version: \"10.0.0\"#"
pin_all_case nodefile "cannot check" "setup-node: a version file that the gate cannot check" \
    "s#node-version:#node-version-file: .nvmrc\n          x:#"

# The versions.env and the table of actions can be wrong too
mkdir -p "${work}/pin-env"
sed -e 's#^JUST_VERSION=.*#JUST_VERSION=1.60.0#' "${real_versions}" >"${work}/pin-env/versions.env"
expect 1 "JUST_VERSION in tools/versions.env is 1.60.0" "tools/versions.env has another version than the workflow" \
    "${GATES_DIR}/check-pins.sh" "${work}/pin-env/versions.env" "${work}/wf-real" "${real_allowed}"
sed -e 's#^actions/checkout v7.0.1 #actions/checkout v7.0.2 #' "${real_allowed}" >"${work}/pin-env/allowed.txt"
expect 1 "but the table has" "the table of actions has another tag than the workflow" \
    "${GATES_DIR}/check-pins.sh" "${real_versions}" "${work}/wf-real" "${work}/pin-env/allowed.txt"
{ grep -E '^(PYTHON|PYYAML)_VERSION=' "${real_versions}"; echo 'this is not a version line'; } >"${work}/pin-env/bad.env"
expect 2 "the form is not KEY=value" "tools/versions.env has a line that is not KEY=value" \
    "${GATES_DIR}/check-pins.sh" "${work}/pin-env/bad.env" "${work}/wf-real" "${real_allowed}"

# ---------------------------------------------------------------------------------------------
section "check-pins.sh: the Maven pin (finding G1)"
run_maven() { env GATE_WORK_ROOT="$1" "${GATES_DIR}/check-pins.sh" "${real_versions}" "${work}/wf-real" "${real_allowed}"; }
maven_version="$(version_of MAVEN_VERSION)"
good_sha="0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef"
good_url="https://repo.maven.apache.org/maven2/org/apache/maven/apache-maven/${maven_version}/apache-maven-${maven_version}-bin.zip"
# wrapper <root> <folder> <properties text>: write <folder>/.mvn/wrapper/maven-wrapper.properties
wrapper() {
    mkdir -p "$1/$2/.mvn/wrapper"
    printf '%s\n' "$3" >"$1/$2/.mvn/wrapper/maven-wrapper.properties"
}
pom_xml='<project xmlns="http://maven.apache.org/POM/4.0.0"><modelVersion>4.0.0</modelVersion></project>'
good_props="# Maven Wrapper
wrapperVersion=3.3.2
distributionType=only-script
distributionUrl=${good_url}
distributionSha256Sum=${good_sha}"

expect 0 "Maven Wrapper: 1 file(s), Maven $(version_of MAVEN_VERSION)" "backend/pom.xml and the wrapper with the pinned Maven version and a sha256 (the real repository, feat-6 Task 105.100)" "${GATES_DIR}/check-pins.sh" "${real_versions}" "${work}/wf-real" "${real_allowed}"
mkdir -p "${work}/mv-none"
expect 0 "no Maven project" "no pom.xml and no wrapper (an empty tree)" run_maven "${work}/mv-none"
mkdir -p "${work}/mv-pom" && echo "${pom_xml}" >"${work}/mv-pom/pom.xml"
expect 1 "exists, but no .mvn/wrapper/maven-wrapper.properties" "a pom.xml and no wrapper" run_maven "${work}/mv-pom"
mkdir -p "${work}/mv-backend/backend" && echo "${pom_xml}" >"${work}/mv-backend/backend/pom.xml"
expect 1 "backend/pom.xml exists, but no" "backend/pom.xml and no wrapper" run_maven "${work}/mv-backend"
mkdir -p "${work}/mv-ok" && echo "${pom_xml}" >"${work}/mv-ok/pom.xml"
wrapper "${work}/mv-ok" . "${good_props}"
expect 0 "Maven Wrapper: 1 file(s), Maven ${maven_version}" "a pom.xml and a wrapper with the pinned version and a sha256" run_maven "${work}/mv-ok"
mkdir -p "${work}/mv-ok-backend/backend" && echo "${pom_xml}" >"${work}/mv-ok-backend/backend/pom.xml"
wrapper "${work}/mv-ok-backend" backend "${good_props}"
expect 0 "Maven Wrapper: 1 file(s)" "a wrapper in backend/" run_maven "${work}/mv-ok-backend"
mkdir -p "${work}/mv-escaped"
wrapper "${work}/mv-escaped" . "distributionUrl=https\\://repo.maven.apache.org/maven2/org/apache/maven/apache-maven/${maven_version}/apache-maven-${maven_version}-bin.tar.gz
distributionSha256Sum=${good_sha}"
expect 0 "Maven Wrapper: 1 file(s)" "a wrapper with an escaped colon and a tar.gz" run_maven "${work}/mv-escaped"
mkdir -p "${work}/mv-only-wrapper"
wrapper "${work}/mv-only-wrapper" . "${good_props}"
expect 0 "Maven Wrapper: 1 file(s)" "a wrapper and no pom.xml (the checks of the wrapper run)" run_maven "${work}/mv-only-wrapper"
mkdir -p "${work}/mv-wrongver"
wrapper "${work}/mv-wrongver" . "distributionUrl=https://repo.maven.apache.org/maven2/org/apache/maven/apache-maven/3.9.9/apache-maven-3.9.9-bin.zip
distributionSha256Sum=${good_sha}"
expect 1 "MAVEN_VERSION in tools/versions.env is ${maven_version}" "a wrapper with another Maven version" run_maven "${work}/mv-wrongver"
mkdir -p "${work}/mv-prefixver"
wrapper "${work}/mv-prefixver" . "distributionUrl=https://example.invalid/apache-maven-${maven_version}1-bin.zip
distributionSha256Sum=${good_sha}"
expect 1 "MAVEN_VERSION in tools/versions.env is ${maven_version}" "a wrapper with a version that only starts with the pinned one" run_maven "${work}/mv-prefixver"
mkdir -p "${work}/mv-mvnd"
wrapper "${work}/mv-mvnd" . "distributionUrl=https://example.invalid/maven-mvnd-${maven_version}-linux-amd64.zip
distributionSha256Sum=${good_sha}"
expect 1 "must have apache-maven-${maven_version}-bin.zip" "a wrapper for another distribution" run_maven "${work}/mv-mvnd"
mkdir -p "${work}/mv-nosha"
wrapper "${work}/mv-nosha" . "distributionUrl=${good_url}"
expect 1 "has no \`distributionSha256Sum\`" "a wrapper with no distributionSha256Sum" run_maven "${work}/mv-nosha"
mkdir -p "${work}/mv-badsha"
wrapper "${work}/mv-badsha" . "distributionUrl=${good_url}
distributionSha256Sum=abc123"
expect 1 "is not a sha256 value" "a wrapper with a distributionSha256Sum that is not a sha256 value" run_maven "${work}/mv-badsha"
mkdir -p "${work}/mv-nourl"
wrapper "${work}/mv-nourl" . "distributionSha256Sum=${good_sha}"
expect 1 "has no \`distributionUrl\`" "a wrapper with no distributionUrl" run_maven "${work}/mv-nourl"
mkdir -p "${work}/mv-comment"
wrapper "${work}/mv-comment" . "#distributionUrl=${good_url}
distributionSha256Sum=${good_sha}"
expect 1 "has no \`distributionUrl\`" "a distributionUrl in a comment only" run_maven "${work}/mv-comment"
mkdir -p "${work}/mv-second"
echo "${pom_xml}" >"${work}/mv-second/pom.xml"
wrapper "${work}/mv-second" . "${good_props}"
wrapper "${work}/mv-second" model "distributionUrl=${good_url}"
expect 1 "model/.mvn/wrapper/maven-wrapper.properties has no \`distributionSha256Sum\`" "a second wrapper that is not correct" run_maven "${work}/mv-second"
# the excluded folders are not searched
mkdir -p "${work}/mv-excluded"
for folder in .git/x node_modules/x target build/x .specmgr/feat/x/prototype tools/license/fixtures tools/gates/fixtures; do
    mkdir -p "${work}/mv-excluded/${folder}"
    echo "${pom_xml}" >"${work}/mv-excluded/${folder}/pom.xml"
    wrapper "${work}/mv-excluded" "${folder}" "distributionUrl=https://example.invalid/wrong.zip"
done
expect 0 "no Maven project" "pom.xml and wrappers in the excluded folders are not searched" run_maven "${work}/mv-excluded"
mkdir -p "${work}/mv-notroot/docs/.specmgr"
echo "${pom_xml}" >"${work}/mv-notroot/docs/.specmgr/pom.xml"
expect 1 "docs/.specmgr/pom.xml exists, but no" ".specmgr is excluded at the root only" run_maven "${work}/mv-notroot"
# the key of versions.env
grep -v '^MAVEN_VERSION=' "${real_versions}" >"${work}/versions-nomaven.env"
expect 1 "MAVEN_VERSION is not in tools/versions.env" "versions.env has no MAVEN_VERSION" \
    env GATE_WORK_ROOT="${work}/mv-ok" "${GATES_DIR}/check-pins.sh" "${work}/versions-nomaven.env" "${work}/wf-real" "${real_allowed}"

# ---------------------------------------------------------------------------------------------
section "check-pins.sh: the lock file of cdxgen in tools/sbom/ (finding G2, feat-16-cdxgen-lockfile, REQ-003, REQ-005)"
real_tool="${REPO_ROOT}/tools/sbom"
cdxgen_version="$(version_of CDXGEN_VERSION)"
cdxgen_integrity="$(version_of CDXGEN_INTEGRITY)"
other_version="0.0.1"
other_integrity="sha512-$(printf 'A%.0s' {1..86})=="
# run_sbom_pins <tool dir> [<versions.env>]: check-pins.sh with another folder for the cdxgen project
run_sbom_pins() { env SBOM_TOOL_DIR="$1" "${GATES_DIR}/check-pins.sh" "${2:-${real_versions}}" "${work}/wf-real" "${real_allowed}"; }
# mk_tool <name>: a copy of package.json and pnpm-lock.yaml of the repository in a new folder (the folder is printed)
mk_tool() {
    local dir="${work}/sbomtool-$1"
    rm -rf "${dir}" && mkdir -p "${dir}"
    cp "${real_tool}/package.json" "${real_tool}/pnpm-lock.yaml" "${dir}/"
    echo "${dir}"
}
# sbom_pin_case <name> <file> <text> <description> <sed expression>: change <file> in a copy with sed (exit code 1)
sbom_pin_case() {
    local name="$1" file="$2" text="$3" description="$4" expression="$5" dir
    dir="$(mk_tool "${name}")"
    sed -i -e "${expression}" "${dir}/${file}"
    if cmp -s "${real_tool}/${file}" "${dir}/${file}"; then
        echo "FAIL ${description}: the sed expression did not change ${file}"
        failed=$((failed + 1))
        return
    fi
    expect 1 "${text}" "${description}" run_sbom_pins "${dir}"
}
# sbom_pin_append_case <name> <file> <text> <description> <text to append>: add text at the end of <file> in a copy
sbom_pin_append_case() {
    local name="$1" file="$2" text="$3" description="$4" dir
    dir="$(mk_tool "${name}")"
    printf '%b' "$5" >>"${dir}/${file}"
    expect 1 "${text}" "${description}" run_sbom_pins "${dir}"
}
# versions_case <name> <text> <description> <sed expression>: change a copy of versions.env with sed (exit code 1)
versions_case() {
    local name="$1" text="$2" description="$3" expression="$4"
    sed -e "${expression}" "${real_versions}" >"${work}/sbomver-${name}.env"
    if cmp -s "${real_versions}" "${work}/sbomver-${name}.env"; then
        echo "FAIL ${description}: the sed expression did not change versions.env"
        failed=$((failed + 1))
        return
    fi
    expect 1 "${text}" "${description}" run_sbom_pins "${real_tool}" "${work}/sbomver-${name}.env"
}
first_package="/^packages:/,/resolution:/"

expect 0 "SBOM tool pin: SBOM tool: ${real_tool}: @cyclonedx/cdxgen ${cdxgen_version}" "the real tools/sbom/ is the one of versions.env" run_sbom_pins "${real_tool}"
expect 0 "RESULT: PASS" "the real tools/sbom/ passes (the default folder of check-pins.sh)" \
    "${GATES_DIR}/check-pins.sh" "${real_versions}" "${work}/wf-real" "${real_allowed}"

# The three places, each alone (REQ-005): a change of one place stops the check
versions_case onlyversions "CDXGEN_VERSION in tools/versions.env is ${other_version}" "one place only: versions.env has another CDXGEN_VERSION" \
    "s#^CDXGEN_VERSION=.*#CDXGEN_VERSION=${other_version}#"
versions_case onlyintegrity "but CDXGEN_INTEGRITY in tools/versions.env is ${other_integrity}" "one place only: versions.env has another CDXGEN_INTEGRITY" \
    "s#^CDXGEN_INTEGRITY=.*#CDXGEN_INTEGRITY=${other_integrity}#"
sbom_pin_case onlypackage package.json "but CDXGEN_VERSION in tools/versions.env is ${cdxgen_version}" "one place only: package.json has another version" \
    "s#\"@cyclonedx/cdxgen\": \"${cdxgen_version}\"#\"@cyclonedx/cdxgen\": \"${other_version}\"#"
sbom_pin_case onlylock pnpm-lock.yaml "the importer has @cyclonedx/cdxgen \`version\` '${other_version}'" "one place only: the lock file has another version of cdxgen (importer)" \
    "s#^\\(        version: \\)${cdxgen_version}\$#\\1${other_version}#"
sbom_pin_case onlylockpackages pnpm-lock.yaml "\`packages\` must have exactly one @cyclonedx/cdxgen" "one place only: the lock file has another version of cdxgen (packages)" \
    "0,/^  '@cyclonedx\\/cdxgen@${cdxgen_version}':/s##  '@cyclonedx/cdxgen@${other_version}':#"
sbom_pin_case onlylockintegrity pnpm-lock.yaml "but CDXGEN_INTEGRITY in tools/versions.env is ${cdxgen_integrity}" "one place only: the lock file has another integrity value of cdxgen" \
    "s#${cdxgen_integrity}#${other_integrity}#"
# All three places with the same new value pass (this is the update procedure of tools/sbom/README.md; the lock file here is a copy with the value changed by sed)
dir="$(mk_tool allthree)"
sed -i -e "s#\"@cyclonedx/cdxgen\": \"${cdxgen_version}\"#\"@cyclonedx/cdxgen\": \"${other_version}\"#" "${dir}/package.json"
sed -i -e "s#@cyclonedx/cdxgen@${cdxgen_version}#@cyclonedx/cdxgen@${other_version}#" \
    -e "s#^\\(        \\(specifier\\|version\\): \\)${cdxgen_version}\$#\\1${other_version}#" \
    -e "s#${cdxgen_integrity}#${other_integrity}#" "${dir}/pnpm-lock.yaml"
sed -e "s#^CDXGEN_VERSION=.*#CDXGEN_VERSION=${other_version}#" -e "s#^CDXGEN_INTEGRITY=.*#CDXGEN_INTEGRITY=${other_integrity}#" \
    "${real_versions}" >"${work}/sbomver-allthree.env"
expect 0 "RESULT: PASS" "all three places have the same new version and integrity value" run_sbom_pins "${dir}" "${work}/sbomver-allthree.env"

# package.json: ranges and tags
for range in "^${cdxgen_version}" "~${cdxgen_version}" ">=${cdxgen_version}" "${cdxgen_version}.x" "12.x" "*" "latest" "next" "${cdxgen_version} || 0.0.1" "npm:@cyclonedx/cdxgen@${cdxgen_version}" "file:../x" "git+https://example.invalid/x.git"; do
    sbom_pin_case "range-${range//[^A-Za-z0-9]/_}" package.json "but CDXGEN_VERSION in tools/versions.env is ${cdxgen_version}" "package.json: the version is a range or a tag (${range})" \
        "s#\"@cyclonedx/cdxgen\": \"${cdxgen_version}\"#\"@cyclonedx/cdxgen\": \"${range}\"#"
done
# package.json: other dependencies and other keys
sbom_pin_case extradep package.json "has the dependency left-pad" "package.json: one more dependency" \
    "s#\"@cyclonedx/cdxgen\": \"${cdxgen_version}\"#\"@cyclonedx/cdxgen\": \"${cdxgen_version}\",\n    \"left-pad\": \"1.3.0\"#"
sbom_pin_case otherdep package.json "has the dependency left-pad" "package.json: another dependency and not cdxgen" \
    "s#\"@cyclonedx/cdxgen\": \"${cdxgen_version}\"#\"left-pad\": \"1.3.0\"#"
sbom_pin_case nodep package.json "has no dependency @cyclonedx/cdxgen" "package.json: no dependency" \
    "s#\"@cyclonedx/cdxgen\": \"${cdxgen_version}\"##"
sbom_pin_case nodeps package.json "has no \`dependencies\` object" "package.json: no dependencies key" \
    "s#\"dependencies\"#\"x-dependencies\"#"
for key in devDependencies optionalDependencies peerDependencies; do
    sbom_pin_case "key-${key}" package.json "has the key \`${key}\`" "package.json: ${key}" \
        "s#\"private\": true,#\"private\": true,\n  \"${key}\": {\"left-pad\": \"1.3.0\"},#"
    sbom_pin_case "keyempty-${key}" package.json "has the key \`${key}\`" "package.json: an empty ${key}" \
        "s#\"private\": true,#\"private\": true,\n  \"${key}\": {},#"
done
sbom_pin_case overrides package.json "has the key \`overrides\`" "package.json: overrides" \
    "s#\"private\": true,#\"private\": true,\n  \"overrides\": {\"yargs\": \"1.0.0\"},#"
sbom_pin_case pnpmoverrides package.json "has the key \`pnpm\`" "package.json: pnpm settings with overrides" \
    "s#\"private\": true,#\"private\": true,\n  \"pnpm\": {\"overrides\": {\"yargs\": \"1.0.0\"}},#"
sbom_pin_case resolutions package.json "has the key \`resolutions\`" "package.json: resolutions" \
    "s#\"private\": true,#\"private\": true,\n  \"resolutions\": {\"yargs\": \"1.0.0\"},#"
sbom_pin_case packagemanager package.json "has the key \`packageManager\`" "package.json: a packageManager field" \
    "s#\"private\": true,#\"private\": true,\n  \"packageManager\": \"pnpm@${cdxgen_version}\",#"
sbom_pin_case scripts package.json "has the key \`scripts\`" "package.json: scripts (a preinstall script of the project)" \
    "s#\"private\": true,#\"private\": true,\n  \"scripts\": {\"preinstall\": \"true\"},#"
sbom_pin_case dupkey package.json "there two times" "package.json: a key two times" \
    "s#\"private\": true,#\"private\": true,\n  \"private\": false,#"
sbom_pin_append_case jsonbad package.json "cannot be read as JSON" "package.json: not JSON" "{"
dir="$(mk_tool jsonarray)" && echo '[]' >"${dir}/package.json"
expect 1 "is not a JSON object" "package.json: a JSON array" run_sbom_pins "${dir}"

# The lock file: the importer
sbom_pin_case lockextradep pnpm-lock.yaml "must have exactly one dependency, @cyclonedx/cdxgen" "lock file: a second direct dependency of the importer" \
    "s#^\\(        version: ${cdxgen_version}\\)\$#\\1\n      left-pad:\n        specifier: 1.3.0\n        version: 1.3.0#"
sbom_pin_case lockdevdep pnpm-lock.yaml "must have \`dependencies\` and nothing else" "lock file: devDependencies in the importer" \
    "s#^\\(        version: ${cdxgen_version}\\)\$#\\1\n    devDependencies:\n      left-pad:\n        specifier: 1.3.0\n        version: 1.3.0#"
sbom_pin_case lockotherimporter pnpm-lock.yaml "must have exactly one importer \`.\`" "lock file: a second importer" \
    "s#^packages:#  other:\n    dependencies: {}\n\npackages:#"
sbom_pin_case lockspecifier pnpm-lock.yaml "the importer has @cyclonedx/cdxgen \`specifier\` '^${cdxgen_version}'" "lock file: the specifier is a range" \
    "s#^\\(        specifier: \\)${cdxgen_version}\$#\\1^${cdxgen_version}#"
sbom_pin_case lockversionimporter pnpm-lock.yaml "must be a text that starts with \`9.\`" "lock file: lockfileVersion 8.0" \
    "s#^lockfileVersion: '9.0'#lockfileVersion: '8.0'#"
sbom_pin_case lockversionfloat pnpm-lock.yaml "must be a text that starts with \`9.\`" "lock file: lockfileVersion 9.0 is a number and not a text" \
    "s#^lockfileVersion: '9.0'#lockfileVersion: 9.0#"
# The lock file: the packages
sbom_pin_case lockwrongversion pnpm-lock.yaml "has an integrity value that is not sha256, sha384 or sha512" "lock file: a package with an integrity value of sha1" \
    "${first_package}s#integrity: [^}]*}#integrity: sha1-AAAAAAAAAAAAAAAAAAAAAAAAAAA=}#"
sbom_pin_case locknoint pnpm-lock.yaml "has no integrity value" "lock file: a package with no integrity value" \
    "${first_package}s#resolution: {[^}]*}#resolution: {}#"
sbom_pin_case locknores pnpm-lock.yaml "has no \`resolution\`" "lock file: a package with no resolution" \
    "${first_package}s#^    resolution: .*#    deprecated: x#"
sbom_pin_case locktarball pnpm-lock.yaml "has no integrity value" "lock file: a package with a tarball URL and no integrity value" \
    "${first_package}s#resolution: {[^}]*}#resolution: {tarball: https://example.invalid/x.tgz}#"
sbom_pin_case locktarballint pnpm-lock.yaml "has the \`resolution\` keys ['tarball']" "lock file: a package with an integrity value and a tarball URL" \
    "${first_package}s#resolution: {\\([^}]*\\)}#resolution: {\\1, tarball: https://example.invalid/x.tgz}#"
sbom_pin_case lockgit pnpm-lock.yaml "has no integrity value" "lock file: a package from git" \
    "${first_package}s#resolution: {[^}]*}#resolution: {commit: 0123456789abcdef0123456789abcdef01234567, repo: https://example.invalid/x.git, type: git}#"
sbom_pin_case lockdir pnpm-lock.yaml "has no integrity value" "lock file: a package from a folder" \
    "${first_package}s#resolution: {[^}]*}#resolution: {directory: ../x, type: directory}#"
sbom_pin_case lockurlkey pnpm-lock.yaml "is not \`<name>@<exact version>\`" "lock file: a package with a URL and no version in the key" \
    "${first_package}s#^  '\\([^']*\\)@[0-9][^']*':\$#  '\\1@https://example.invalid/x.tgz':#"
sbom_pin_case lockrangekey pnpm-lock.yaml "is not \`<name>@<exact version>\`" "lock file: a package with a range in the key" \
    "${first_package}s#^  '\\([^']*\\)@[0-9][^']*':\$#  '\\1@^1.0.0':#"
sbom_pin_case locknopackages pnpm-lock.yaml "has no \`packages\`" "lock file: no packages" "/^packages:/,\$d"
sbom_pin_case locksnapshot pnpm-lock.yaml "which is not in \`packages\`" "lock file: a snapshot of a package that is not in packages" \
    "s#^snapshots:#&\n  'left-pad@1.3.0': {}#"
# The lock file: other keys and the form of the file
sbom_pin_append_case lockoverrides pnpm-lock.yaml "has the top-level key \`overrides\`" "lock file: overrides" "\noverrides:\n  yargs: 1.0.0\n"
sbom_pin_append_case lockpatched pnpm-lock.yaml "has the top-level key \`patchedDependencies\`" "lock file: patchedDependencies" "\npatchedDependencies: {}\n"
sbom_pin_append_case locksecond pnpm-lock.yaml "has 2 YAML documents" "lock file: a second YAML document (a packageManager field makes one)" "\n---\nlockfileVersion: '9.0'\n"
sbom_pin_append_case lockduplicate pnpm-lock.yaml "there two times" "lock file: a key two times" "\nsnapshots: {}\n"
sbom_pin_append_case lockbroken pnpm-lock.yaml "cannot be read as YAML" "lock file: not YAML" "\n  bad: [\n"
sbom_pin_case locklist pnpm-lock.yaml "is not a YAML mapping" "lock file: a YAML list" "1s#.*#- a#;2,\$d"
dir="$(mk_tool lockempty)" && : >"${dir}/pnpm-lock.yaml"
expect 1 "has 0 YAML documents" "lock file: an empty file" run_sbom_pins "${dir}"

# The folder
expect 1 "the folder ${work}/no-such-sbom-tool (the lock file of cdxgen) does not exist" "no folder tools/sbom/" run_sbom_pins "${work}/no-such-sbom-tool"
mkdir -p "${work}/sbomtool-empty"
expect 1 "sbomtool-empty/package.json does not exist" "an empty folder: no package.json" run_sbom_pins "${work}/sbomtool-empty"
expect 1 "sbomtool-empty/pnpm-lock.yaml does not exist" "an empty folder: no lock file" run_sbom_pins "${work}/sbomtool-empty"
dir="$(mk_tool nopackage)" && rm "${dir}/package.json"
expect 1 "sbomtool-nopackage/package.json does not exist" "no package.json (the lock file is there)" run_sbom_pins "${dir}"
dir="$(mk_tool nolock)" && rm "${dir}/pnpm-lock.yaml"
expect 1 "sbomtool-nolock/pnpm-lock.yaml does not exist" "no lock file (package.json is there)" run_sbom_pins "${dir}"
for extra in .npmrc pnpm-workspace.yaml .pnpmfile.cjs pnpmfile.cjs yarn.lock package-lock.json .gitignore; do
    dir="$(mk_tool "extra-${extra//./_}")" && echo "x" >"${dir}/${extra}"
    expect 1 "/${extra} is not allowed" "the folder has the file ${extra}" run_sbom_pins "${dir}"
done
dir="$(mk_tool extradir)" && mkdir -p "${dir}/sub"
expect 1 "/sub is not allowed" "the folder has a sub-folder" run_sbom_pins "${dir}"
dir="$(mk_tool readme)" && echo "# x" >"${dir}/README.md" && mkdir -p "${dir}/node_modules/x"
expect 0 "RESULT: PASS" "README.md and node_modules are allowed in the folder" run_sbom_pins "${dir}"

# versions.env
sed -e "s#^CDXGEN_INTEGRITY=.*#CDXGEN_INTEGRITY=sha512-abc#" "${real_versions}" >"${work}/sbomver-integrityform.env"
expect 1 "it must be a sha512 integrity value of npm" "versions.env: the form of CDXGEN_INTEGRITY is checked" run_sbom_pins "${real_tool}" "${work}/sbomver-integrityform.env"
for range in "^${cdxgen_version}" "latest" "12"; do
    sed -e "s#^CDXGEN_VERSION=.*#CDXGEN_VERSION=${range}#" "${real_versions}" >"${work}/sbomver-range.env"
    expect 1 "it must be an exact version (no range, no tag)" "versions.env: CDXGEN_VERSION is not an exact version (${range})" run_sbom_pins "${real_tool}" "${work}/sbomver-range.env"
done
grep -v '^CDXGEN_VERSION=' "${real_versions}" >"${work}/sbomver-nover.env"
expect 1 "CDXGEN_VERSION is not in tools/versions.env" "versions.env has no CDXGEN_VERSION" run_sbom_pins "${real_tool}" "${work}/sbomver-nover.env"
grep -v '^CDXGEN_INTEGRITY=' "${real_versions}" >"${work}/sbomver-noint.env"
expect 1 "CDXGEN_INTEGRITY is not in tools/versions.env" "versions.env has no CDXGEN_INTEGRITY" run_sbom_pins "${real_tool}" "${work}/sbomver-noint.env"

# ---------------------------------------------------------------------------------------------
section "check-pins.sh: the lock file of Spectral in tools/spectral/ (feat-6-contracts-openapi-pipeline, Task 110.110, REQ-009)"
# The same check as for cdxgen (check_pnpm_tool), with SPECTRAL_VERSION, SPECTRAL_INTEGRITY and the package
# @stoplight/spectral-cli. The messages start with `Lint tool:`.
real_lint="${REPO_ROOT}/tools/spectral"
spectral_version="$(version_of SPECTRAL_VERSION)"
spectral_integrity="$(version_of SPECTRAL_INTEGRITY)"
# run_lint_pins <tool dir> [<versions.env>]: check-pins.sh with another folder for the Spectral project
run_lint_pins() { env LINT_TOOL_DIR="$1" "${GATES_DIR}/check-pins.sh" "${2:-${real_versions}}" "${work}/wf-real" "${real_allowed}"; }
# mk_lint_tool <name>: a copy of package.json and pnpm-lock.yaml of the repository in a new folder (the folder is printed)
mk_lint_tool() {
    local dir="${work}/linttool-$1"
    rm -rf "${dir}" && mkdir -p "${dir}"
    cp "${real_lint}/package.json" "${real_lint}/pnpm-lock.yaml" "${dir}/"
    echo "${dir}"
}
# lint_pin_case <name> <file> <text> <description> <sed expression>: change <file> in a copy with sed (exit code 1)
lint_pin_case() {
    local name="$1" file="$2" text="$3" description="$4" expression="$5" dir
    dir="$(mk_lint_tool "${name}")"
    sed -i -e "${expression}" "${dir}/${file}"
    if cmp -s "${real_lint}/${file}" "${dir}/${file}"; then
        echo "FAIL ${description}: the sed expression did not change ${file}"
        failed=$((failed + 1))
        return
    fi
    expect 1 "${text}" "${description}" run_lint_pins "${dir}"
}
# lint_pin_append_case <name> <file> <text> <description> <text to append>: add text at the end of <file> in a copy
lint_pin_append_case() {
    local name="$1" file="$2" text="$3" description="$4" dir
    dir="$(mk_lint_tool "${name}")"
    printf '%b' "$5" >>"${dir}/${file}"
    expect 1 "${text}" "${description}" run_lint_pins "${dir}"
}
# lint_versions_case <name> <text> <description> <sed expression>: change a copy of versions.env with sed (exit code 1)
lint_versions_case() {
    local name="$1" text="$2" description="$3" expression="$4"
    sed -e "${expression}" "${real_versions}" >"${work}/lintver-${name}.env"
    if cmp -s "${real_versions}" "${work}/lintver-${name}.env"; then
        echo "FAIL ${description}: the sed expression did not change versions.env"
        failed=$((failed + 1))
        return
    fi
    expect 1 "${text}" "${description}" run_lint_pins "${real_lint}" "${work}/lintver-${name}.env"
}
spectral_package="@stoplight/spectral-cli"

expect 0 "Lint tool pin: Lint tool: ${real_lint}: ${spectral_package} ${spectral_version}" "the real tools/spectral/ is the one of versions.env" run_lint_pins "${real_lint}"
expect 0 "RESULT: PASS" "the real tools/spectral/ passes (the default folder of check-pins.sh)" \
    "${GATES_DIR}/check-pins.sh" "${real_versions}" "${work}/wf-real" "${real_allowed}"

# The three places, each alone: a change of one place stops the check
lint_versions_case onlyversions "SPECTRAL_VERSION in tools/versions.env is ${other_version}" "Spectral, one place only: versions.env has another SPECTRAL_VERSION" \
    "s#^SPECTRAL_VERSION=.*#SPECTRAL_VERSION=${other_version}#"
lint_versions_case onlyintegrity "but SPECTRAL_INTEGRITY in tools/versions.env is ${other_integrity}" "Spectral, one place only: versions.env has another SPECTRAL_INTEGRITY" \
    "s#^SPECTRAL_INTEGRITY=.*#SPECTRAL_INTEGRITY=${other_integrity}#"
lint_pin_case onlypackage package.json "but SPECTRAL_VERSION in tools/versions.env is ${spectral_version}" "Spectral, one place only: package.json has another version" \
    "s#\"${spectral_package}\": \"${spectral_version}\"#\"${spectral_package}\": \"${other_version}\"#"
lint_pin_case onlylock pnpm-lock.yaml "the importer has ${spectral_package} \`version\` '${other_version}'" "Spectral, one place only: the lock file has another version (importer)" \
    "s#^\\(        version: \\)${spectral_version}\$#\\1${other_version}#"
lint_pin_case onlylockpackages pnpm-lock.yaml "\`packages\` must have exactly one ${spectral_package}" "Spectral, one place only: the lock file has another version (packages)" \
    "0,/^  '@stoplight\\/spectral-cli@${spectral_version}':/s##  '${spectral_package}@${other_version}':#"
lint_pin_case onlylockintegrity pnpm-lock.yaml "but SPECTRAL_INTEGRITY in tools/versions.env is ${spectral_integrity}" "Spectral, one place only: the lock file has another integrity value" \
    "s#${spectral_integrity}#${other_integrity}#"
# All three places with the same new value pass (the procedure of tools/spectral/README.md)
dir="$(mk_lint_tool allthree)"
sed -i -e "s#\"${spectral_package}\": \"${spectral_version}\"#\"${spectral_package}\": \"${other_version}\"#" "${dir}/package.json"
sed -i -e "s#${spectral_package}@${spectral_version}#${spectral_package}@${other_version}#" \
    -e "s#^\\(        \\(specifier\\|version\\): \\)${spectral_version}\$#\\1${other_version}#" \
    -e "s#${spectral_integrity}#${other_integrity}#" "${dir}/pnpm-lock.yaml"
sed -e "s#^SPECTRAL_VERSION=.*#SPECTRAL_VERSION=${other_version}#" -e "s#^SPECTRAL_INTEGRITY=.*#SPECTRAL_INTEGRITY=${other_integrity}#" \
    "${real_versions}" >"${work}/lintver-allthree.env"
expect 0 "RESULT: PASS" "Spectral: all three places have the same new version and integrity value" run_lint_pins "${dir}" "${work}/lintver-allthree.env"

# package.json: ranges and tags
for range in "^${spectral_version}" "~${spectral_version}" ">=${spectral_version}" "${spectral_version}.x" "6.x" "*" "latest" "next" "npm:${spectral_package}@${spectral_version}" "file:../x" "git+https://example.invalid/x.git"; do
    lint_pin_case "range-${range//[^A-Za-z0-9]/_}" package.json "but SPECTRAL_VERSION in tools/versions.env is ${spectral_version}" "Spectral, package.json: the version is a range or a tag (${range})" \
        "s#\"${spectral_package}\": \"${spectral_version}\"#\"${spectral_package}\": \"${range}\"#"
done
# package.json: other dependencies and other keys
lint_pin_case extradep package.json "has the dependency left-pad" "Spectral, package.json: one more dependency" \
    "s#\"${spectral_package}\": \"${spectral_version}\"#\"${spectral_package}\": \"${spectral_version}\",\n    \"left-pad\": \"1.3.0\"#"
lint_pin_case otherdep package.json "has the dependency @cyclonedx/cdxgen" "Spectral, package.json: another dependency (the one of cdxgen) and not Spectral" \
    "s#\"${spectral_package}\"#\"@cyclonedx/cdxgen\"#"
lint_pin_case nodeps package.json "has no \`dependencies\` object" "Spectral, package.json: no dependencies key" \
    "s#\"dependencies\"#\"x-dependencies\"#"
for key in devDependencies optionalDependencies peerDependencies overrides resolutions pnpm packageManager scripts; do
    lint_pin_case "key-${key}" package.json "has the key \`${key}\`" "Spectral, package.json: ${key}" \
        "s#\"private\": true,#\"private\": true,\n  \"${key}\": {},#"
done
lint_pin_case dupkey package.json "there two times" "Spectral, package.json: a key two times" \
    "s#\"private\": true,#\"private\": true,\n  \"private\": false,#"
lint_pin_append_case jsonbad package.json "cannot be read as JSON" "Spectral, package.json: not JSON" "{"

# The lock file
lint_pin_case lockextradep pnpm-lock.yaml "must have exactly one dependency, ${spectral_package}" "Spectral, lock file: a second direct dependency of the importer" \
    "s#^\\(        version: ${spectral_version}\\)\$#\\1\n      left-pad:\n        specifier: 1.3.0\n        version: 1.3.0#"
lint_pin_case lockdevdep pnpm-lock.yaml "must have \`dependencies\` and nothing else" "Spectral, lock file: devDependencies in the importer" \
    "s#^\\(        version: ${spectral_version}\\)\$#\\1\n    devDependencies:\n      left-pad:\n        specifier: 1.3.0\n        version: 1.3.0#"
lint_pin_case lockspecifier pnpm-lock.yaml "the importer has ${spectral_package} \`specifier\` '^${spectral_version}'" "Spectral, lock file: the specifier is a range" \
    "s#^\\(        specifier: \\)${spectral_version}\$#\\1^${spectral_version}#"
lint_pin_case lockversion pnpm-lock.yaml "must be a text that starts with \`9.\`" "Spectral, lock file: lockfileVersion 8.0" \
    "s#^lockfileVersion: '9.0'#lockfileVersion: '8.0'#"
lint_pin_case locknoint pnpm-lock.yaml "has no integrity value" "Spectral, lock file: a package with no integrity value" \
    "${first_package}s#resolution: {[^}]*}#resolution: {}#"
lint_pin_case locksha1 pnpm-lock.yaml "has an integrity value that is not sha256, sha384 or sha512" "Spectral, lock file: a package with an integrity value of sha1" \
    "${first_package}s#integrity: [^}]*}#integrity: sha1-AAAAAAAAAAAAAAAAAAAAAAAAAAA=}#"
lint_pin_case locktarball pnpm-lock.yaml "has no integrity value" "Spectral, lock file: a package with a tarball URL and no integrity value" \
    "${first_package}s#resolution: {[^}]*}#resolution: {tarball: https://example.invalid/x.tgz}#"
lint_pin_case locktarballint pnpm-lock.yaml "has the \`resolution\` keys ['tarball']" "Spectral, lock file: a package with an integrity value and a tarball URL" \
    "${first_package}s#resolution: {\\([^}]*\\)}#resolution: {\\1, tarball: https://example.invalid/x.tgz}#"
lint_pin_case lockgit pnpm-lock.yaml "has no integrity value" "Spectral, lock file: a package from git" \
    "${first_package}s#resolution: {[^}]*}#resolution: {commit: 0123456789abcdef0123456789abcdef01234567, repo: https://example.invalid/x.git, type: git}#"
lint_pin_case lockurlkey pnpm-lock.yaml "is not \`<name>@<exact version>\`" "Spectral, lock file: a package with a URL and no version in the key" \
    "${first_package}s#^  '\\([^']*\\)@[0-9][^']*':\$#  '\\1@https://example.invalid/x.tgz':#"
lint_pin_case locksnapshot pnpm-lock.yaml "which is not in \`packages\`" "Spectral, lock file: a snapshot of a package that is not in packages" \
    "s#^snapshots:#&\n  'left-pad@1.3.0': {}#"
lint_pin_append_case lockoverrides pnpm-lock.yaml "has the top-level key \`overrides\`" "Spectral, lock file: overrides" "\noverrides:\n  yargs: 1.0.0\n"
lint_pin_append_case locksecond pnpm-lock.yaml "has 2 YAML documents" "Spectral, lock file: a second YAML document (a packageManager field makes one)" "\n---\nlockfileVersion: '9.0'\n"
lint_pin_append_case lockbroken pnpm-lock.yaml "cannot be read as YAML" "Spectral, lock file: not YAML" "\n  bad: [\n"

# The folder
expect 1 "the folder ${work}/no-such-lint-tool (the lock file of Spectral) does not exist" "no folder tools/spectral/" run_lint_pins "${work}/no-such-lint-tool"
mkdir -p "${work}/linttool-empty"
expect 1 "linttool-empty/package.json does not exist" "Spectral, an empty folder: no package.json" run_lint_pins "${work}/linttool-empty"
dir="$(mk_lint_tool nolock)" && rm "${dir}/pnpm-lock.yaml"
expect 1 "linttool-nolock/pnpm-lock.yaml does not exist" "Spectral: no lock file (package.json is there)" run_lint_pins "${dir}"
for extra in .npmrc pnpm-workspace.yaml .pnpmfile.cjs yarn.lock package-lock.json ruleset.yaml; do
    dir="$(mk_lint_tool "extra-${extra//./_}")" && echo "x" >"${dir}/${extra}"
    expect 1 "/${extra} is not allowed" "Spectral: the folder has the file ${extra}" run_lint_pins "${dir}"
done
dir="$(mk_lint_tool readme)" && echo "# x" >"${dir}/README.md" && mkdir -p "${dir}/node_modules/x"
expect 0 "RESULT: PASS" "Spectral: README.md and node_modules are allowed in the folder" run_lint_pins "${dir}"

# versions.env
sed -e "s#^SPECTRAL_INTEGRITY=.*#SPECTRAL_INTEGRITY=sha512-abc#" "${real_versions}" >"${work}/lintver-integrityform.env"
expect 1 "it must be a sha512 integrity value of npm" "Spectral, versions.env: the form of SPECTRAL_INTEGRITY is checked" run_lint_pins "${real_lint}" "${work}/lintver-integrityform.env"
for range in "^${spectral_version}" "latest" "6"; do
    sed -e "s#^SPECTRAL_VERSION=.*#SPECTRAL_VERSION=${range}#" "${real_versions}" >"${work}/lintver-range.env"
    expect 1 "it must be an exact version (no range, no tag)" "Spectral, versions.env: SPECTRAL_VERSION is not an exact version (${range})" run_lint_pins "${real_lint}" "${work}/lintver-range.env"
done
grep -v '^SPECTRAL_VERSION=' "${real_versions}" >"${work}/lintver-nover.env"
expect 1 "SPECTRAL_VERSION is not in tools/versions.env" "Spectral, versions.env has no SPECTRAL_VERSION" run_lint_pins "${real_lint}" "${work}/lintver-nover.env"
grep -v '^SPECTRAL_INTEGRITY=' "${real_versions}" >"${work}/lintver-noint.env"
expect 1 "SPECTRAL_INTEGRITY is not in tools/versions.env" "Spectral, versions.env has no SPECTRAL_INTEGRITY" run_lint_pins "${real_lint}" "${work}/lintver-noint.env"
# The two checks are separate: a bad lock file of Spectral does not make the check of cdxgen stop, and the other way round
dir="$(mk_lint_tool separate)"
sed -i -e "s#\"${spectral_package}\": \"${spectral_version}\"#\"${spectral_package}\": \"${other_version}\"#" "${dir}/package.json"
expect 1 "SBOM tool pin: SBOM tool: ${real_tool}: @cyclonedx/cdxgen ${cdxgen_version}" "a bad lock file of Spectral: the check of cdxgen still passes (and says so)" run_lint_pins "${dir}"
expect 1 "Lint tool pin: Lint tool: ${real_lint}: ${spectral_package} ${spectral_version}" "a bad lock file of cdxgen: the check of Spectral still passes (and says so)" \
    env SBOM_TOOL_DIR="${work}/no-such-sbom-tool" LINT_TOOL_DIR="${real_lint}" "${GATES_DIR}/check-pins.sh" "${real_versions}" "${work}/wf-real" "${real_allowed}"

# ---------------------------------------------------------------------------------------------
section "check-sudo.sh (Task 130.145)"
fix="${GATES_DIR}/fixtures"
sudo_case() {
    # sudo_case <fixture file> <name in the test folder> <exit code> <text> <description>
    local dir="${work}/sudo-$2-$3"
    mkdir -p "${dir}"
    cp "${fix}/$1" "${dir}/$2"
    expect "$3" "$4" "$5" "${GATES_DIR}/check-sudo.sh" "${dir}"
}
sudo_case sudo-command.sh.fixture install.sh 1 "STOP" "a script with the command"
sudo_case sudo-pipe.sh.fixture install.sh 1 "STOP" "a script with the command in a pipe"
sudo_case sudo-path.sh.fixture install.sh 1 "STOP" "a script with the command and a path"
sudo_case sudo-justfile.fixture justfile 1 "STOP" "a justfile with the command"
sudo_case sudo-workflow.yml.fixture ci.yml 1 "STOP" "a workflow with the command"
sudo_case sudo-comment-only.sh.fixture install.sh 0 "PASS" "a script with the word in comments only, and a name with a hyphen"
sudo_case sudo-ok-justfile.fixture justfile 0 "PASS" "a justfile with the word in a comment only"
expect 0 "PASS" "the real scripts of the project" "${GATES_DIR}/check-sudo.sh" "${real_justfile}" "${REPO_ROOT}/tools" "${REPO_ROOT}/.specmgr/feat" "${REPO_ROOT}/.github"
mkdir -p "${work}/sudo-empty"
expect 2 "no file to check" "a folder with no script" "${GATES_DIR}/check-sudo.sh" "${work}/sudo-empty"
expect 2 "does not exist" "a path that does not exist" "${GATES_DIR}/check-sudo.sh" "${work}/no-such-path"

# ---------------------------------------------------------------------------------------------
section "sbom.sh and license-check.sh with stubs for mvnw and pnpm (Task 130.130)"
stubs="${work}/stubs"
mkdir -p "${stubs}"
# The stub of Maven (it is copied to the file mvnw of a test project): like the Maven Wrapper with the
# plugin, it writes the jar of the plugin in the local repository, and target/bom.json for the real run.
cat >"${stubs}/mvnw-stub" <<'STUB'
#!/usr/bin/env bash
echo "stub mvnw $*"
repo="" skip=0
for argument in "$@"; do
    case "${argument}" in
        -Dmaven.repo.local=*) repo="${argument#*=}" ;;
        -Dcyclonedx.skip=true) skip=1 ;;
    esac
done
if [[ -n "${repo}" ]]; then
    jar="${repo}/org/cyclonedx/cyclonedx-maven-plugin/${STUB_PLUGIN_VERSION}"
    mkdir -p "${jar}"
    printf '%s' "${STUB_JAR_CONTENT:-stub-plugin-jar}" >"${jar}/cyclonedx-maven-plugin-${STUB_PLUGIN_VERSION}.jar"
fi
[[ ${skip} -eq 1 ]] && exit 0
[[ "${STUB_MVN_FAIL:-}" == "1" ]] && exit 0
mkdir -p target
if [[ "${STUB_NO_COMPONENTS:-}" == "1" ]]; then
    # like cyclonedx-maven-plugin 2.9.3 for a project with no dependency: no `components` key (first real run, feat-6)
    echo '{"bomFormat":"CycloneDX","specVersion":"1.6","version":1,"metadata":{"component":{"type":"library","name":"backend"}}}' >target/bom.json
elif [[ "${STUB_EMPTY:-}" == "1" ]]; then
    echo '{"bomFormat":"CycloneDX","specVersion":"1.6","version":1,"components":[]}' >target/bom.json
else
    cat >target/bom.json <<'JSON'
{"bomFormat":"CycloneDX","specVersion":"1.6","version":1,"components":[{"type":"library","name":"lib","version":"1","licenses":[{"license":{"id":"Apache-2.0"}}]}]}
JSON
fi
STUB
# A mvn in the PATH is a fault of the script: it must start mvnw and never mvn.
cat >"${stubs}/mvn" <<STUB
#!/usr/bin/env bash
echo "mvn of the PATH was started" >>"${work}/mvn-of-the-path-was-started"
exit 1
STUB
cat >"${stubs}/pnpm" <<'STUB'
#!/usr/bin/env bash
# Stub of pnpm for the test (feat-16-cdxgen-lockfile): only `pnpm install` exists, like the real call of sbom.sh. It
# writes the install of the stub cdxgen in the current folder (the folder of the cdxgen project): the package.json of
# @cyclonedx/cdxgen with the version STUB_CDXGEN_VERSION, and node_modules/.bin/cdxgen. Each other command (dlx, view)
# stops with exit code 64, so a script that uses it fails. The stub writes each call (folder and arguments) to
# STUB_PNPM_LOG.
echo "stub pnpm $*" >&2
echo "${PWD} $*" >>"${STUB_PNPM_LOG}"
if [[ "$1" != "install" ]]; then
    echo "stub pnpm: the command '$1' is not allowed" >&2
    exit 64
fi
if [[ "${STUB_PNPM_INSTALL_FAIL:-}" == "1" ]]; then
    echo "stub pnpm: ERR_PNPM_LOCKFILE_CONFIG_MISMATCH (the stub install failed)" >&2
    exit 1
fi
mkdir -p node_modules/.bin node_modules/@cyclonedx/cdxgen
printf '{"name":"@cyclonedx/cdxgen","version":"%s"}\n' "${STUB_CDXGEN_VERSION}" >node_modules/@cyclonedx/cdxgen/package.json
cat >node_modules/.bin/cdxgen <<'CDX'
#!/usr/bin/env bash
# Stub of cdxgen: writes the file of the argument --output, like cdxgen.
echo "stub cdxgen $*" >&2
while [[ $# -gt 0 ]]; do
    if [[ "$1" == "--output" ]]; then
        if [[ "${STUB_EMPTY:-}" == "1" ]]; then
            echo '{"bomFormat":"CycloneDX","specVersion":"1.6","version":1,"components":[]}' >"$2"
        else
            echo '{"bomFormat":"CycloneDX","specVersion":"1.6","version":1,"components":[{"type":"library","name":"npmlib","version":"1","licenses":[{"license":{"name":"The MIT License (MIT)"}}]}]}' >"$2"
        fi
    fi
    shift
done
CDX
chmod +x node_modules/.bin/cdxgen
STUB
chmod +x "${stubs}/mvnw-stub" "${stubs}/mvn" "${stubs}/pnpm"

# A versions.env for these tests: the checksum of the plugin jar is the one of the stub. (CDXGEN_INTEGRITY stays: the
# integrity values of cdxgen are in its lock file, and pnpm checks them. The stub pnpm does not.)
stub_jar_sha="$(printf 'stub-plugin-jar' | sha256sum | cut -d' ' -f1)"
stub_versions="${work}/versions-stubs.env"
sed -e "s#^CYCLONEDX_MAVEN_PLUGIN_SHA256=.*#CYCLONEDX_MAVEN_PLUGIN_SHA256=${stub_jar_sha}#" "${real_versions}" >"${stub_versions}"
STUB_PLUGIN_VERSION="$(version_of CYCLONEDX_MAVEN_PLUGIN_VERSION)"
export STUB_PLUGIN_VERSION

# put <root> <path> <content>: write a file (and its folders)
put() {
    mkdir -p "$(dirname "$1/$2")"
    printf '%s\n' "$3" >"$1/$2"
}
# put_mvnw <root> <folder>: the stub as the file mvnw
put_mvnw() {
    mkdir -p "$1/$2"
    cp "${stubs}/mvnw-stub" "$1/$2/mvnw"
    chmod +x "$1/$2/mvnw"
}
pom_deps='<project xmlns="http://maven.apache.org/POM/4.0.0"><modelVersion>4.0.0</modelVersion><dependencies><dependency><groupId>g</groupId><artifactId>a</artifactId><version>1</version></dependency></dependencies></project>'
# The cdxgen project for the tests (SBOM_TOOL_DIR): a package.json and a lock file with no content that the stub reads.
tool_dir="${work}/tool-sbom"
mkdir -p "${tool_dir}"
echo '{"name":"sbom-tool","private":true,"dependencies":{"@cyclonedx/cdxgen":"'"$(version_of CDXGEN_VERSION)"'"}}' >"${tool_dir}/package.json"
echo "lockfileVersion: '9.0'" >"${tool_dir}/pnpm-lock.yaml"
pnpm_log="${work}/pnpm-calls.log"
# sbom_run <root> [<VAR=value>...]: sbom.sh for a project tree, with the stubs. Each run starts with no install of cdxgen
# and an empty log of the calls of pnpm.
sbom_run() {
    local root="$1"
    shift
    rm -rf "${tool_dir}/node_modules"
    : >"${pnpm_log}"
    env PATH="${stubs}:${PATH}" SBOM_PROJECT_ROOT="${root}" SBOM_MAVEN_REPO_LOCAL="${root}/m2" VERSIONS_FILE="${stub_versions}" \
        SBOM_TOOL_DIR="${tool_dir}" STUB_PNPM_LOG="${pnpm_log}" STUB_CDXGEN_VERSION="$(version_of CDXGEN_VERSION)" \
        "$@" "${GATES_DIR}/sbom.sh" "${root}/build/sbom"
}
# new_tree <name>: an empty project tree (the function prints its path)
new_tree() {
    rm -rf "${work:?}/tree-$1"
    mkdir -p "${work}/tree-$1"
    echo "${work}/tree-$1"
}
# file_exists <path> <description>: a check of a file
file_exists() {
    if [[ -f "$1" ]]; then
        echo "ok   $2"
        passed=$((passed + 1))
    else
        echo "FAIL $2: no file $1"
        failed=$((failed + 1))
    fi
}

project="$(new_tree main)"
put "${project}" pom.xml "${pom_xml}"
put_mvnw "${project}" .
put "${project}" frontend/package.json '{}'
mkdir -p "${project}/build/sbom"
echo '{}' >"${project}/build/sbom/old.json"
expect 0 "Wrote" "sbom.sh with pom.xml, mvnw and frontend/package.json" sbom_run "${project}"
if [[ -f "${project}/build/sbom/backend.cdx.json" && -f "${project}/build/sbom/frontend.cdx.json" && ! -f "${project}/build/sbom/old.json" ]]; then
    echo "ok   sbom.sh wrote backend.cdx.json and frontend.cdx.json, and removed the old file"
    passed=$((passed + 1))
else
    echo "FAIL sbom.sh: files in the SBOM folder are not the expected ones"
    ls "${project}/build/sbom"
    failed=$((failed + 1))
fi
if [[ ! -e "${work}/mvn-of-the-path-was-started" ]]; then
    echo "ok   sbom.sh did not start the mvn of the PATH (it starts mvnw)"
    passed=$((passed + 1))
else
    echo "FAIL sbom.sh started the mvn of the PATH"
    failed=$((failed + 1))
fi
expect 0 "RESULT: PASS. 2 component(s)" "license-check.sh with the SBOM files of the stubs" \
    "${GATES_DIR}/license-check.sh" "${project}/build/sbom" "${REPO_ROOT}/tools/license/permitted-licenses.txt"
expect 1 "did not make" "sbom.sh when Maven makes no file" sbom_run "${project}" STUB_MVN_FAIL=1
mkdir -p "${work}/empty-project"
expect 0 "Nothing to scan" "sbom.sh with no manifest" \
    env SBOM_PROJECT_ROOT="${work}/empty-project" "${GATES_DIR}/sbom.sh" "${work}/empty-project/build/sbom"
expect 2 "no SBOM file" "license-check.sh with an empty SBOM folder" \
    "${GATES_DIR}/license-check.sh" "${work}/empty-project/no-sbom" "${REPO_ROOT}/tools/license/permitted-licenses.txt"
expect 0 "RESULT: PASS. 0 component(s)" "license-check.sh passes the empty SBOM (this is why sbom.sh must not make an empty SBOM for a project with manifests: E1)" \
    "${GATES_DIR}/license-check.sh" "${work}/empty-project/build/sbom" "${REPO_ROOT}/tools/license/permitted-licenses.txt"

section "sbom.sh: a manifest outside the scanned set stops the script (finding E1, part a)"
# unscanned_case <name> <path> <content> [<other file as path:content, or mvnw:folder>...]: a tree with a manifest
# outside the set, and the other files
unscanned_case() {
    local name="$1" path="$2" content="$3" root extra
    root="$(new_tree "u-${name}")"
    shift 3
    for extra in "$@"; do
        case "${extra}" in
            mvnw:*) put_mvnw "${root}" "${extra#mvnw:}" ;;
            *) put "${root}" "${extra%%:*}" "${extra#*:}" ;;
        esac
    done
    put "${root}" "${path}" "${content}"
    expect 1 "${path} is not scanned by sbom.sh" "a manifest outside the set: ${path}${*:+ (with ${*%%:*}...)}" sbom_run "${root}"
}
unscanned_case rootpackage package.json '{}'
unscanned_case contractspackage contracts/package.json '{}'
unscanned_case modelpom model/pom.xml "${pom_xml}"
unscanned_case backendsvc backend/svc/pom.xml "${pom_xml}"
unscanned_case rootlock pnpm-lock.yaml 'lockfileVersion: 9'
unscanned_case rootworkspace pnpm-workspace.yaml 'packages: []'
unscanned_case frontendpom frontend/pom.xml "${pom_xml}"
unscanned_case backendpackage backend/package.json '{}'
unscanned_case modelpackage model/package.json '{}'
unscanned_case terminologypom terminology/pom.xml "${pom_xml}"
unscanned_case docshidden docs/.specmgr/package.json '{}'
unscanned_case toolspackage tools/package.json '{}'
unscanned_case nestedwithoutworkspace frontend/sub/package.json '{}' frontend/package.json:'{}'
unscanned_case nestedwithoutlock frontend/sub/package.json '{}' frontend/package.json:'{}' frontend/pnpm-workspace.yaml:'packages: [sub]'
unscanned_case nestedlock frontend/sub/pnpm-lock.yaml 'lockfileVersion: 9' frontend/package.json:'{}' frontend/pnpm-workspace.yaml:'packages: [sub]' frontend/pnpm-lock.yaml:'lockfileVersion: 9'
unscanned_case workspacealone frontend/pnpm-workspace.yaml 'packages: []'
unscanned_case modelwithbackend model/pom.xml "${pom_xml}" backend/pom.xml:"${pom_xml}" mvnw:backend
unscanned_case modelwithroot model/pom.xml "${pom_xml}" pom.xml:"${pom_xml}" mvnw:.
unscanned_case contractswithfrontend contracts/package.json '{}' frontend/package.json:'{}'
root="$(new_tree two-unscanned)"
put "${root}" package.json '{}'
put "${root}" model/pom.xml "${pom_xml}"
expect 1 "model/pom.xml is not scanned by sbom.sh" "two manifests outside the set: both are in the message (model/pom.xml)" sbom_run "${root}"
expect 1 "package.json is not scanned by sbom.sh" "two manifests outside the set: both are in the message (package.json)" sbom_run "${root}"
expect 1 "2 manifest(s) are outside the set" "two manifests outside the set: the count" sbom_run "${root}"
root="$(new_tree stop-before-work)"
put "${root}" package.json '{}'
mkdir -p "${root}/build/sbom" && echo '{}' >"${root}/build/sbom/old.json"
sbom_run "${root}" >/dev/null 2>&1 || true
if [[ -f "${root}/build/sbom/old.json" && ! -f "${root}/build/sbom/project.cdx.json" ]]; then
    echo "ok   sbom.sh stops before it writes an SBOM (no empty SBOM stays)"
    passed=$((passed + 1))
else
    echo "FAIL sbom.sh wrote an SBOM although a manifest is outside the set"
    failed=$((failed + 1))
fi
# positive cases: nothing outside, or only in the folders that the script does not enter
root="$(new_tree excluded)"
for folder in .git/x node_modules/x build/x target .specmgr/feat/x/prototype tools/license/fixtures tools/gates/fixtures; do
    put "${root}" "${folder}/package.json" '{"dependencies":{"a":"1"}}'
    put "${root}" "${folder}/pom.xml" "${pom_deps}"
    put "${root}" "${folder}/pnpm-lock.yaml" 'lockfileVersion: 9'
    put "${root}" "${folder}/pnpm-workspace.yaml" 'packages: []'
done
expect 0 "Nothing to scan" "manifests in .git, node_modules, build, target, .specmgr and the fixtures are not entered" sbom_run "${root}"
root="$(new_tree nested-excluded)"
put "${root}" frontend/package.json '{}'
put "${root}" frontend/node_modules/a/package.json '{"dependencies":{"a":"1"}}'
put "${root}" frontend/build/package.json '{}'
put "${root}" backend/pom.xml "${pom_xml}"
put_mvnw "${root}" backend
put "${root}" backend/target/pom.xml "${pom_xml}"
put "${root}" backend/node_modules/a/package.json '{}'
expect 0 "Wrote" "node_modules, build and target at a deeper level are not entered" sbom_run "${root}"
root="$(new_tree backend-only)"
put "${root}" backend/pom.xml "${pom_xml}"
put_mvnw "${root}" backend
expect 0 "Backend: backend/pom.xml" "backend/pom.xml alone is scanned" sbom_run "${root}"
file_exists "${root}/build/sbom/backend.cdx.json" "backend/pom.xml: backend.cdx.json exists"
root="$(new_tree backend-modules)"
put "${root}" backend/pom.xml "${pom_xml}"
put_mvnw "${root}" backend
put "${root}" backend/svc/pom.xml "${pom_xml}"
put "${root}" backend/svc/api/pom.xml "${pom_xml}"
expect 0 "Backend: backend/pom.xml" "poms below backend/ are covered by the aggregate BOM of backend/pom.xml" sbom_run "${root}"
root="$(new_tree root-and-backend)"
put "${root}" pom.xml "${pom_xml}"
put_mvnw "${root}" .
put "${root}" backend/pom.xml "${pom_xml}"
expect 0 "Backend: pom.xml with" "pom.xml in the root and backend/pom.xml (a module of the root pom.xml)" sbom_run "${root}"
root="$(new_tree frontend-only)"
put "${root}" frontend/package.json '{}'
expect 0 "Frontend: frontend/" "frontend/package.json alone is scanned" sbom_run "${root}"
file_exists "${root}/build/sbom/frontend.cdx.json" "frontend/package.json: frontend.cdx.json exists"
root="$(new_tree lock-only)"
put "${root}" frontend/pnpm-lock.yaml 'lockfileVersion: 9'
expect 0 "Frontend: frontend/" "frontend/pnpm-lock.yaml alone is scanned" sbom_run "${root}"
root="$(new_tree workspace)"
put "${root}" frontend/package.json '{}'
put "${root}" frontend/pnpm-lock.yaml 'lockfileVersion: 9'
put "${root}" frontend/pnpm-workspace.yaml 'packages: [sub]'
put "${root}" frontend/sub/package.json '{}'
put "${root}" frontend/sub/deeper/package.json '{}'
expect 0 "Frontend: frontend/" "a workspace with a lock file covers the package.json files below frontend/" sbom_run "${root}"

section "sbom.sh: Maven needs the Maven Wrapper (finding G1)"
root="$(new_tree nomvnw)"
put "${root}" pom.xml "${pom_xml}"
expect 1 "mvnw does not" "pom.xml and no mvnw: the script does not use the Maven of the PATH" sbom_run "${root}"
root="$(new_tree nomvnw-backend)"
put "${root}" backend/pom.xml "${pom_xml}"
expect 1 "backend/mvnw does not" "backend/pom.xml and no backend/mvnw" sbom_run "${root}"
root="$(new_tree mvnw-elsewhere)"
put "${root}" backend/pom.xml "${pom_xml}"
put_mvnw "${root}" .
expect 1 "backend/mvnw does not" "a mvnw in the root is not the mvnw next to backend/pom.xml" sbom_run "${root}"
root="$(new_tree mvnw-not-executable)"
put "${root}" pom.xml "${pom_xml}"
put_mvnw "${root}" .
chmod -x "${root}/mvnw"
expect 1 "is not executable" "mvnw that is not executable" sbom_run "${root}"
if [[ ! -e "${work}/mvn-of-the-path-was-started" ]]; then
    echo "ok   no case started the mvn of the PATH"
    passed=$((passed + 1))
else
    echo "FAIL a case started the mvn of the PATH"
    failed=$((failed + 1))
fi

section "sbom.sh: an SBOM with no component and declared dependencies stops the script (finding E1, part b)"
# empty_case <name> <exit code> <text> <description> <pom|node> <manifest content>: the SBOM of the stub has no component
empty_case() {
    local name="$1" code="$2" text="$3" description="$4" kind="$5" content="$6" root
    root="$(new_tree "e-${name}")"
    if [[ "${kind}" == "pom" ]]; then
        put "${root}" backend/pom.xml "${content}"
        put_mvnw "${root}" backend
    else
        put "${root}" frontend/package.json "${content}"
    fi
    expect "${code}" "${text}" "${description}" sbom_run "${root}" STUB_EMPTY=1
}
empty_case nodedeps 1 "has no component" "package.json with dependencies, and an SBOM with no component" node '{"dependencies":{"a":"1"}}'
empty_case nodedev 1 "has no component" "package.json with devDependencies, and an SBOM with no component" node '{"devDependencies":{"a":"1"}}'
empty_case nodeopt 1 "has no component" "package.json with optionalDependencies, and an SBOM with no component" node '{"optionalDependencies":{"a":"1"}}'
empty_case nodepeer 1 "has no component" "package.json with peerDependencies, and an SBOM with no component" node '{"peerDependencies":{"a":"1"}}'
empty_case nodeempty 0 "Wrote" "package.json with empty dependency objects, and an SBOM with no component" node '{"dependencies":{},"devDependencies":{}}'
empty_case nodenone 0 "Wrote" "package.json with no dependency, and an SBOM with no component" node '{"name":"x","scripts":{"a":"b"}}'
empty_case pomdeps 1 "has no component" "pom.xml with a dependency, and an SBOM with no component" pom "${pom_deps}"
empty_case pomnone 0 "Wrote" "pom.xml with no dependency, and an SBOM with no component" pom "${pom_xml}"
empty_case pommanagement 0 "Wrote" "pom.xml with dependencyManagement only (no dependency of the project)" pom \
    '<project xmlns="http://maven.apache.org/POM/4.0.0"><dependencyManagement><dependencies><dependency><groupId>g</groupId><artifactId>a</artifactId><version>1</version></dependency></dependencies></dependencyManagement></project>'
empty_case pomplugin 0 "Wrote" "pom.xml with a dependency of a plugin only" pom \
    '<project xmlns="http://maven.apache.org/POM/4.0.0"><build><plugins><plugin><dependencies><dependency><groupId>g</groupId><artifactId>a</artifactId><version>1</version></dependency></dependencies></plugin></plugins></build></project>'
empty_case pomprofile 1 "has no component" "pom.xml with a dependency in a profile, and an SBOM with no component" pom \
    '<project xmlns="http://maven.apache.org/POM/4.0.0"><profiles><profile><id>p</id><dependencies><dependency><groupId>g</groupId><artifactId>a</artifactId><version>1</version></dependency></dependencies></profile></profiles></project>'
empty_case pombroken 1 "cannot read" "a pom.xml that is not XML" pom 'this is not xml'
empty_case nodebroken 1 "cannot read" "a package.json that is not JSON" node 'this is not json'
empty_case nodebadkey 1 "is not an object" "a package.json with dependencies that is not an object" node '{"dependencies":["a"]}'
# The real plugin writes no `components` key for a project with no dependency (the first real run, feat-6 Task 105.110).
root="$(new_tree no-components-key)"
put "${root}" backend/pom.xml "${pom_xml}"
put_mvnw "${root}" backend
expect 0 'wrote `components: []`' "pom.xml with no dependency, and an SBOM with no components key: the script writes the empty list" \
    sbom_run "${root}" STUB_NO_COMPONENTS=1
expect 0 "RESULT: PASS. 0 component(s)" "license-check.sh reads the SBOM that has the empty list" \
    "${GATES_DIR}/license-check.sh" "${root}/build/sbom" "${REPO_ROOT}/tools/license/permitted-licenses.txt"
if grep -q '"components"' "${root}/build/sbom/backend.cdx.json" && ! grep -q '"components"' "${root}/backend/target/bom.json"; then
    echo "ok   the SBOM in the SBOM folder has the list, and the file of the plugin in target/ is not changed"
    passed=$((passed + 1))
else
    echo "FAIL the SBOM folder has no components list, or the file of the plugin was changed"
    failed=$((failed + 1))
fi
root="$(new_tree no-components-key-deps)"
put "${root}" backend/pom.xml "${pom_deps}"
put_mvnw "${root}" backend
expect 1 "has no component" "pom.xml with a dependency, and an SBOM with no components key: the script stops" \
    sbom_run "${root}" STUB_NO_COMPONENTS=1
root="$(new_tree no-components-key-module-deps)"
put "${root}" backend/pom.xml "${pom_xml}"
put_mvnw "${root}" backend
put "${root}" backend/svc/pom.xml "${pom_deps}"
expect 1 "backend/svc/pom.xml: 1 declared dependency" "a dependency in a module pom.xml, and an SBOM with no components key: the script stops" \
    sbom_run "${root}" STUB_NO_COMPONENTS=1
root="$(new_tree nested-deps)"
put "${root}" frontend/package.json '{}'
put "${root}" frontend/pnpm-lock.yaml 'lockfileVersion: 9'
put "${root}" frontend/pnpm-workspace.yaml 'packages: [sub]'
put "${root}" frontend/sub/package.json '{"dependencies":{"a":"1"}}'
expect 1 "frontend/sub/package.json: 1 declared dependency" "a dependency in a package.json of the workspace counts" sbom_run "${root}" STUB_EMPTY=1
root="$(new_tree module-deps)"
put "${root}" backend/pom.xml "${pom_xml}"
put_mvnw "${root}" backend
put "${root}" backend/svc/pom.xml "${pom_deps}"
expect 1 "backend/svc/pom.xml: 1 declared dependency" "a dependency in a module pom.xml counts" sbom_run "${root}" STUB_EMPTY=1
root="$(new_tree deps-with-components)"
put "${root}" frontend/package.json '{"dependencies":{"a":"1"}}'
put "${root}" backend/pom.xml "${pom_deps}"
put_mvnw "${root}" backend
expect 0 "1 declared dependency" "dependencies and an SBOM with components" sbom_run "${root}"

section "sbom.sh: the checksums of the SBOM tools (finding G2)"
root="$(new_tree g2-good)"
put "${root}" backend/pom.xml "${pom_xml}"
put_mvnw "${root}" backend
put "${root}" frontend/package.json '{}'
expect 0 "sha256 of the plugin jar is the value of CYCLONEDX_MAVEN_PLUGIN_SHA256" "the plugin jar has the pinned sha256" sbom_run "${root}"
expect 0 "The installed @cyclonedx/cdxgen has the version $(version_of CDXGEN_VERSION) (CDXGEN_VERSION)" "the installed cdxgen has the pinned version" sbom_run "${root}"
root="$(new_tree g2-jar)"
put "${root}" backend/pom.xml "${pom_xml}"
put_mvnw "${root}" backend
expect 1 "The plugin did not make the SBOM" "a plugin jar with another sha256 than the pin" sbom_run "${root}" STUB_JAR_CONTENT=other-jar
if [[ ! -f "${root}/build/sbom/backend.cdx.json" && ! -f "${root}/backend/target/bom.json" ]]; then
    echo "ok   a wrong plugin sha256: the plugin did not make the SBOM (the real goal did not start)"
    passed=$((passed + 1))
else
    echo "FAIL a wrong plugin sha256: the real goal started"
    failed=$((failed + 1))
fi
sed -e "s#^CYCLONEDX_MAVEN_PLUGIN_SHA256=.*#CYCLONEDX_MAVEN_PLUGIN_SHA256=0000000000000000000000000000000000000000000000000000000000000000#" \
    "${stub_versions}" >"${work}/versions-badjar.env"
expect 1 "CYCLONEDX_MAVEN_PLUGIN_SHA256 in ${work}/versions-badjar.env is 0000" "versions.env has another plugin sha256 than the jar" \
    sbom_run "${root}" VERSIONS_FILE="${work}/versions-badjar.env"
sed -e "s#^CYCLONEDX_MAVEN_PLUGIN_SHA256=.*#CYCLONEDX_MAVEN_PLUGIN_SHA256=abc#" "${stub_versions}" >"${work}/versions-shortjar.env"
expect 1 "is not a sha256 value" "versions.env has a plugin sha256 that is not a sha256 value" sbom_run "${root}" VERSIONS_FILE="${work}/versions-shortjar.env"
section "sbom.sh: cdxgen runs from the lock file (finding G2, feat-16-cdxgen-lockfile)"
# no_frontend_sbom <root> <description>: no SBOM file of the frontend (the script stopped before cdxgen made it)
no_frontend_sbom() {
    if [[ ! -f "$1/build/sbom/frontend.cdx.json" ]]; then
        echo "ok   $2: no frontend.cdx.json"
        passed=$((passed + 1))
    else
        echo "FAIL $2: frontend.cdx.json exists"
        failed=$((failed + 1))
    fi
}
# pnpm_calls <count> <description>: the log of the calls of the stub pnpm has this number of lines
pnpm_calls() {
    local lines
    lines="$(wc -l <"${pnpm_log}")"
    if [[ ${lines} -eq $1 ]]; then
        echo "ok   $2: ${lines} call(s) of pnpm"
        passed=$((passed + 1))
    else
        echo "FAIL $2: expected $1 call(s) of pnpm, got ${lines}"
        sed -e 's/^/     | /' "${pnpm_log}"
        failed=$((failed + 1))
    fi
}
root="$(new_tree g2-npm)"
put "${root}" frontend/package.json '{}'
expect 0 "Install: pnpm install --frozen-lockfile --ignore-scripts in ${tool_dir}" "the log shows the install in the folder of the cdxgen project" sbom_run "${root}"
expect 0 "stub pnpm install --frozen-lockfile --ignore-scripts" "pnpm gets install --frozen-lockfile --ignore-scripts" sbom_run "${root}"
pnpm_calls 1 "one pnpm call for the frontend (no dlx and no view)"
if [[ "$(cat "${pnpm_log}")" == "${tool_dir} install --frozen-lockfile --ignore-scripts" ]]; then
    echo "ok   the install runs in the folder of the cdxgen project, and not in the project"
    passed=$((passed + 1))
else
    echo "FAIL the install does not run in the folder of the cdxgen project: $(cat "${pnpm_log}")"
    failed=$((failed + 1))
fi
expect 0 "stub cdxgen --type js --spec-version 1.6 --profile license-compliance --fail-on-error --output ${root}/build/sbom/frontend.cdx.json ${root}/frontend" \
    "the cdxgen of the install gets the options and absolute paths" sbom_run "${root}"
expect 0 "The installed @cyclonedx/cdxgen has the version $(version_of CDXGEN_VERSION)" "the log shows the version of the installed cdxgen" sbom_run "${root}"
file_exists "${root}/build/sbom/frontend.cdx.json" "the frozen install: frontend.cdx.json exists"
if grep -Eq 'pnpm +(dlx|view)' "${GATES_DIR}/sbom.sh"; then
    echo "FAIL sbom.sh has a pnpm dlx or pnpm view command"
    failed=$((failed + 1))
else
    echo "ok   sbom.sh has no pnpm dlx command and no pnpm view command"
    passed=$((passed + 1))
fi
root="$(new_tree g2-nonode)"
put "${root}" backend/pom.xml "${pom_xml}"
put_mvnw "${root}" backend
expect 0 "Backend: backend/pom.xml" "a project with no Node manifest" sbom_run "${root}"
pnpm_calls 0 "no Node manifest: the script does not install"

root="$(new_tree g2-fail)"
put "${root}" frontend/package.json '{}'
expect 1 "cdxgen did not start" "pnpm install fails (for example a lock file that is not the one of package.json, or a wrong integrity value)" \
    sbom_run "${root}" STUB_PNPM_INSTALL_FAIL=1
expect 1 "pnpm install --frozen-lockfile --ignore-scripts failed in ${tool_dir}" "the message names the install and the folder" sbom_run "${root}" STUB_PNPM_INSTALL_FAIL=1
no_frontend_sbom "${root}" "a failed install"
if [[ ! -e "${tool_dir}/node_modules/.bin/cdxgen" ]]; then
    echo "ok   a failed install: cdxgen did not start (no cdxgen in the install)"
    passed=$((passed + 1))
else
    echo "FAIL a failed install: the install has cdxgen"
    failed=$((failed + 1))
fi
# 0.0.1 and 0.0.2 are no real versions of cdxgen, so a new CDXGEN_VERSION in versions.env never makes these cases pass by chance
expect 1 "has the version '0.0.1', but CDXGEN_VERSION in ${stub_versions} is '$(version_of CDXGEN_VERSION)'" \
    "the installed cdxgen has another version than CDXGEN_VERSION (lock file with another version)" sbom_run "${root}" STUB_CDXGEN_VERSION=0.0.1
expect 1 "cdxgen did not start" "another version of cdxgen: it does not start" sbom_run "${root}" STUB_CDXGEN_VERSION=0.0.1
no_frontend_sbom "${root}" "another version of cdxgen"
sed -e "s#^CDXGEN_VERSION=.*#CDXGEN_VERSION=0.0.2#" "${stub_versions}" >"${work}/versions-badnpm.env"
expect 1 "has the version '$(version_of CDXGEN_VERSION)', but CDXGEN_VERSION in ${work}/versions-badnpm.env is '0.0.2'" \
    "versions.env has another CDXGEN_VERSION than the install" sbom_run "${root}" VERSIONS_FILE="${work}/versions-badnpm.env"
no_frontend_sbom "${root}" "another CDXGEN_VERSION in versions.env"
mkdir -p "${root}/build/sbom" && echo '{}' >"${root}/build/sbom/frontend.cdx.json"
sbom_run "${root}" STUB_PNPM_INSTALL_FAIL=1 >/dev/null 2>&1 || true
no_frontend_sbom "${root}" "a failed install after an old SBOM (the old file is deleted)"
other_tool="${work}/tool-sbom-other"
rm -rf "${other_tool}" && mkdir -p "${other_tool}"
expect 1 "${other_tool}/package.json does not exist" "no package.json in the folder of the cdxgen project" sbom_run "${root}" SBOM_TOOL_DIR="${other_tool}"
echo "lockfileVersion: '9.0'" >"${other_tool}/pnpm-lock.yaml"
expect 1 "${other_tool}/package.json does not exist" "a lock file and no package.json" sbom_run "${root}" SBOM_TOOL_DIR="${other_tool}"
rm "${other_tool}/pnpm-lock.yaml" && echo '{}' >"${other_tool}/package.json"
expect 1 "${other_tool}/pnpm-lock.yaml does not exist" "a package.json and no lock file: cdxgen does not start" sbom_run "${root}" SBOM_TOOL_DIR="${other_tool}"
pnpm_calls 0 "no lock file: pnpm did not start"
expect 1 "The folder of the cdxgen project does not exist" "no folder for the cdxgen project" sbom_run "${root}" SBOM_TOOL_DIR="${work}/no-such-tool-dir"
expect 64 "stub pnpm: the command 'dlx' is not allowed" "the stub stops a dlx call (the test of the stub)" \
    env PATH="${stubs}:${PATH}" STUB_PNPM_LOG="${pnpm_log}" pnpm dlx x
expect 64 "stub pnpm: the command 'view' is not allowed" "the stub stops a view call (the test of the stub)" \
    env PATH="${stubs}:${PATH}" STUB_PNPM_LOG="${pnpm_log}" pnpm view x

section "sbom.sh: the lock file of cdxgen in tools/sbom/ is not an unscanned manifest (finding E1, feat-16-cdxgen-lockfile, REQ-004)"
tools_lock='lockfileVersion: 9'
root="$(new_tree e1-tools-sbom)"
put "${root}" frontend/package.json '{}'
put "${root}" tools/sbom/package.json '{"dependencies":{"@cyclonedx/cdxgen":"1.0.0"}}'
put "${root}" tools/sbom/pnpm-lock.yaml "${tools_lock}"
expect 0 "Wrote ${root}/build/sbom/frontend.cdx.json" "tools/sbom/package.json and tools/sbom/pnpm-lock.yaml with frontend/package.json do not stop the script" sbom_run "${root}"
expect 0 "PASS" "the two files of tools/sbom/: the script passes" sbom_run "${root}"
root="$(new_tree e1-tools-sbom-alone)"
put "${root}" tools/sbom/package.json '{"dependencies":{"@cyclonedx/cdxgen":"1.0.0"}}'
put "${root}" tools/sbom/pnpm-lock.yaml "${tools_lock}"
expect 0 "Nothing to scan" "the two files of tools/sbom/ alone: nothing to scan, and no stop" sbom_run "${root}"
pnpm_calls 0 "the two files of tools/sbom/ alone: no install"
root="$(new_tree e1-tools-sbom-modules)"
put "${root}" frontend/package.json '{}'
put "${root}" tools/sbom/package.json '{}'
put "${root}" tools/sbom/pnpm-lock.yaml "${tools_lock}"
put "${root}" tools/sbom/node_modules/pkg/package.json '{}'
expect 0 "Wrote" "node_modules in tools/sbom/ is not entered" sbom_run "${root}"
tools_sbom_files=(tools/sbom/package.json:'{}' tools/sbom/pnpm-lock.yaml:"${tools_lock}" frontend/package.json:'{}')
unscanned_case toolsother tools/other/package.json '{}' "${tools_sbom_files[@]}"
unscanned_case toolssbomworkspace tools/sbom/pnpm-workspace.yaml 'packages: []' "${tools_sbom_files[@]}"
unscanned_case toolssbomsub tools/sbom/sub/package.json '{}' "${tools_sbom_files[@]}"
unscanned_case toolssbomsublock tools/sbom/sub/pnpm-lock.yaml "${tools_lock}" "${tools_sbom_files[@]}"
unscanned_case toolssbompom tools/sbom/pom.xml "${pom_xml}" "${tools_sbom_files[@]}"
unscanned_case toolsotherlock tools/other/pnpm-lock.yaml "${tools_lock}" "${tools_sbom_files[@]}"
unscanned_case toolsotherworkspace tools/other/pnpm-workspace.yaml 'packages: []' "${tools_sbom_files[@]}"
unscanned_case rootwithtoolssbom package.json '{}' "${tools_sbom_files[@]}"
unscanned_case rootlockwithtoolssbom pnpm-lock.yaml "${tools_lock}" "${tools_sbom_files[@]}"
unscanned_case toolsotherwithoutfrontend tools/other/package.json '{}' tools/sbom/package.json:'{}' tools/sbom/pnpm-lock.yaml:"${tools_lock}"
unscanned_case toolssbomnestedpackage tools/sbom/nested/deep/package.json '{}' "${tools_sbom_files[@]}"
root="$(new_tree e1-tools-sbom-stops)"
put "${root}" frontend/package.json '{}'
put "${root}" tools/sbom/package.json '{}'
put "${root}" tools/sbom/sub/package.json '{}'
sbom_run "${root}" >/dev/null 2>&1 || true
no_frontend_sbom "${root}" "a package.json in tools/sbom/sub/ stops the script before cdxgen"
pnpm_calls 0 "a manifest outside the set: the script stops before the install"


section "sbom.sh: the lock file of Spectral in tools/spectral/ is not an unscanned manifest (finding E1, feat-6-contracts-openapi-pipeline, Task 110.110)"
root="$(new_tree e1-tools-spectral)"
put "${root}" frontend/package.json '{}'
put "${root}" tools/spectral/package.json '{"dependencies":{"@stoplight/spectral-cli":"1.0.0"}}'
put "${root}" tools/spectral/pnpm-lock.yaml "${tools_lock}"
expect 0 "Wrote ${root}/build/sbom/frontend.cdx.json" "tools/spectral/package.json and tools/spectral/pnpm-lock.yaml with frontend/package.json do not stop the script" sbom_run "${root}"
expect 0 "PASS" "the two files of tools/spectral/: the script passes" sbom_run "${root}"
root="$(new_tree e1-tools-spectral-alone)"
put "${root}" tools/spectral/package.json '{"dependencies":{"@stoplight/spectral-cli":"1.0.0"}}'
put "${root}" tools/spectral/pnpm-lock.yaml "${tools_lock}"
expect 0 "Nothing to scan" "the two files of tools/spectral/ alone: nothing to scan, and no stop" sbom_run "${root}"
pnpm_calls 0 "the two files of tools/spectral/ alone: no install"
root="$(new_tree e1-tools-spectral-modules)"
put "${root}" frontend/package.json '{}'
put "${root}" tools/spectral/package.json '{}'
put "${root}" tools/spectral/pnpm-lock.yaml "${tools_lock}"
put "${root}" tools/spectral/node_modules/pkg/package.json '{}'
expect 0 "Wrote" "node_modules in tools/spectral/ is not entered" sbom_run "${root}"
tools_spectral_files=(tools/spectral/package.json:'{}' tools/spectral/pnpm-lock.yaml:"${tools_lock}" frontend/package.json:'{}')
unscanned_case toolsspectralworkspace tools/spectral/pnpm-workspace.yaml 'packages: []' "${tools_spectral_files[@]}"
unscanned_case toolsspectralsub tools/spectral/sub/package.json '{}' "${tools_spectral_files[@]}"
unscanned_case toolsspectralsublock tools/spectral/sub/pnpm-lock.yaml "${tools_lock}" "${tools_spectral_files[@]}"
unscanned_case toolsspectralpom tools/spectral/pom.xml "${pom_xml}" "${tools_spectral_files[@]}"
unscanned_case toolslint tools/lint/package.json '{}' "${tools_spectral_files[@]}"
unscanned_case toolslintlock tools/lint/pnpm-lock.yaml "${tools_lock}" "${tools_spectral_files[@]}"
unscanned_case toolsspectralnested tools/spectral/nested/deep/package.json '{}' "${tools_spectral_files[@]}"
unscanned_case rootwithtoolsspectral package.json '{}' "${tools_spectral_files[@]}"
unscanned_case contractswithtoolsspectral contracts/package.json '{}' "${tools_spectral_files[@]}"

# ---------------------------------------------------------------------------------------------
section "validate-docs.sh (Task 130.110)"
docs="${work}/docs-repo"
git init -q -b base "${docs}"
dgit() { git -C "${docs}" -c user.name=test -c user.email=test@example.invalid -c commit.gpgsign=false "$@"; }
run_docs() { env GATE_WORK_ROOT="${docs}" "${GATES_DIR}/validate-docs.sh" "$1"; }
valid_doc="$(ls "${REPO_ROOT}"/docs/dec/dec-a56f231b-*.md)"
bad_name="docs/dec/dec-00000000-0000-4000-8000-000000000000-bad.md"
mkdir -p "${docs}/docs/dec"
echo "x" >"${docs}/README.md"
dgit add -A && dgit commit -q -m "base"
dgit switch -q -c with-bad-base
printf '# Not a decision\n' >"${docs}/${bad_name}"
dgit add -A && dgit commit -q -m "a bad document in the base"
dgit switch -q -c only-code base
echo "y" >"${docs}/script.sh"
dgit add -A && dgit commit -q -m "no document"
expect 0 "Nothing to validate" "no document changed" run_docs base

dgit switch -q -c valid base
mkdir -p "${docs}/docs/dec"
cp "${valid_doc}" "${docs}/docs/dec/"
dgit add -A && dgit commit -q -m "a valid document"
expect 0 "linted=1 failed=0" "a valid document" run_docs base
dgit update-ref refs/remotes/origin/main base
dgit update-ref refs/remotes/origin/dev base
expect 0 "linted=1 failed=0" "a valid document, base origin/main" run_docs origin/main
expect 0 "linted=1 failed=0" "a valid document, base origin/dev" run_docs origin/dev

dgit switch -q -c invalid valid
mkdir -p "${docs}/docs/dec"
printf '# Not a decision\n' >"${docs}/${bad_name}"
dgit add -A && dgit commit -q -m "an invalid document"
expect 1 "failed=1" "an invalid document in a commit" run_docs base
expect 1 "failed=1" "an invalid document in a commit, base origin/main" run_docs origin/main

dgit switch -q valid
printf '# Not a decision\n' >"${docs}/docs/dec/$(basename "${valid_doc}")"
expect 1 "failed=1" "a document that is invalid in the working tree only" run_docs base
dgit checkout -q -- .

dgit switch -q -c deleted with-bad-base
dgit rm -q "${bad_name}"
dgit commit -q -m "delete the bad document"
expect 0 "Nothing to validate" "a deleted document is skipped" run_docs with-bad-base
expect 1 "does not exist" "a base that does not exist" run_docs no-such-base

# ---------------------------------------------------------------------------------------------
section "the lock files of the Python tools: install with hashes (finding G2, feat-22-python-tools-lockfile)"
real_locks="${REPO_ROOT}/tools/python"
# lock_copy <name>: a copy of tools/python/ in ${work}/locks-<name>. Print the folder.
lock_copy() {
    rm -rf "${work:?}/locks-$1"
    cp -r "${real_locks}" "${work}/locks-$1"
    echo "${work}/locks-$1"
}
# The next three functions write a changed lock file to stdout. <file> is a lock file, <package> a name in it.
# break_hashes: each hash of the package has another first character, so no file of it has the hash.
break_hashes() {
    awk -v pkg="$2" '/^[^ #]/ {inb = (index($0, pkg "==") == 1)} inb && /--hash=sha256:/ {
        i = index($0, "sha256:") + 7; c = substr($0, i, 1); n = (c == "0") ? "1" : "0"; $0 = substr($0, 1, i - 1) n substr($0, i + 1)
    } {print}' "$1"
}
# drop_package: the entry of the package (its line, its hashes and its `# via` lines) is not in the file.
drop_package() { awk -v pkg="$2" '/^[^ #]/ {inb = (index($0, pkg "==") == 1)} !inb {print}' "$1"; }
# no_hash: the package has its line, but no hash.
no_hash() {
    awk -v pkg="$2" '/^[^ #]/ {inb = (index($0, pkg "==") == 1); if (inb) {sub(/ \\$/, ""); print; next}} inb && /--hash=/ {next} {print}' "$1"
}
# changed_lock <name> <file> <function> <package>: a copy of the folder in which <file> is the output of <function>.
# The function runs in a command substitution, so it cannot count a failure. If the file did not change, it prints a
# folder that does not exist, and the case that uses it fails (its text is not the text of a stop that it expects).
changed_lock() {
    local dir
    dir="$(lock_copy "$1")"
    "$3" "${real_locks}/$2" "$4" >"${dir}/$2"
    if cmp -s "${real_locks}/$2" "${dir}/$2"; then
        echo "${work}/changed_lock-did-not-change-$1"
    else
        echo "${dir}"
    fi
}
sbom_empty="${work}/empty-project/build/sbom"
permitted_list="${REPO_ROOT}/tools/license/permitted-licenses.txt"
run_license() { env PYTHON_LOCK_DIR="$1" VERSIONS_FILE="${2:-${real_versions}}" "${GATES_DIR}/license-check.sh" "${sbom_empty}" "${permitted_list}"; }
run_workflows() { env PYTHON_LOCK_DIR="$1" "${GATES_DIR}/check-workflows.sh" "${real_justfile}" "${work}/wf-real" "${real_required}"; }
run_pins_locks() { env PYTHON_LOCK_DIR="$1" "${GATES_DIR}/check-pins.sh" "${2:-${real_versions}}" "${work}/wf-real" "${real_allowed}"; }

expect 0 "all packages are checked with the lock file" "license-check.sh installs license-expression and boolean.py from the lock file" run_license "${real_locks}"
expect 1 "Hash mismatch for \`license-expression" "license-check.sh: a wrong hash of license-expression" \
    run_license "$(changed_lock le-hash license-expression.lock break_hashes license-expression)"
expect 1 "Hash mismatch for \`boolean-py" "license-check.sh: a wrong hash of boolean.py (a dependency)" \
    run_license "$(changed_lock bool-hash license-expression.lock break_hashes boolean-py)"
expect 1 "uv did not install" "license-check.sh: boolean.py is not in the lock file (a dependency that is missing)" \
    run_license "$(changed_lock bool-drop license-expression.lock drop_package boolean-py)"
expect 1 "must have a hash" "license-check.sh: boolean.py has no hash (a dependency with no hash)" \
    run_license "$(changed_lock bool-nohash license-expression.lock no_hash boolean-py)"
no_lock_dir="$(lock_copy no-lock)"
rm "${no_lock_dir}/license-expression.lock"
expect 1 "Lock file not found" "license-check.sh: the lock file does not exist" run_license "${no_lock_dir}"

# PyYAML. The lock file has wheels only, so a hash of the source archive is not a hash that uv can use.
expect 0 "RESULT: PASS" "check-workflows.sh installs PyYAML from the lock file" run_workflows "${real_locks}"
expect 1 "Hash mismatch for \`pyyaml" "check-workflows.sh: a wrong hash of PyYAML" \
    run_workflows "$(changed_lock yaml-hash pyyaml.lock break_hashes pyyaml)"
expect 1 "Hash mismatch for \`pyyaml" "check-pins.sh: a wrong hash of PyYAML" \
    run_pins_locks "$(changed_lock yaml-hash2 pyyaml.lock break_hashes pyyaml)"
yaml_sdist_dir="$(lock_copy yaml-sdist)"
{
    sed -n '/^#/p' "${real_locks}/pyyaml.lock"
    echo "pyyaml==$(version_of PYYAML_VERSION) \\"
    echo "    --hash=sha256:d76623373421df22fb4cf8817020cbb7ef15c725b9d5e45f17e189bfc384190f"
} >"${yaml_sdist_dir}/pyyaml.lock"
expect 1 "Hash mismatch for \`pyyaml" "check-workflows.sh: only the hash of the source archive of PyYAML (no source build)" run_workflows "${yaml_sdist_dir}"

# make_python_env itself
expect 1 "usage: make_python_env" "make_python_env: no lock name" bash -c 'source "$1/_lib.sh"; make_python_env' _ "${GATES_DIR}"
expect 1 "usage: make_python_env" "make_python_env: a lock name with a slash" bash -c 'source "$1/_lib.sh"; make_python_env ../x' _ "${GATES_DIR}"
expect 1 "usage: make_python_env" "make_python_env: the old mode argument" bash -c 'source "$1/_lib.sh"; make_python_env require pyyaml' _ "${GATES_DIR}"
grep -v '^PYTHON_VERSION=' "${real_versions}" >"${work}/g2-nopython.env"
expect 1 "PYTHON_VERSION is not set" "license-check.sh: no PYTHON_VERSION in versions.env" run_license "${real_locks}" "${work}/g2-nopython.env"
sed -e 's#^PYTHON_VERSION=.*#PYTHON_VERSION=3.13.1#' "${real_versions}" >"${work}/g2-python-patch.env"
expect 1 "is not a minor version" "license-check.sh: PYTHON_VERSION is not a minor version" run_license "${real_locks}" "${work}/g2-python-patch.env"
expect 0 "" "make_python_env: no --verify-hashes and no mode in _lib.sh" bash -c '! grep -n -e "--verify-hashes" -e "<require|verify>" "$1/_lib.sh"' _ "${GATES_DIR}"
expect 0 "" "versions.env has no checksum of the Python tools and no boolean.py" \
    bash -c '! grep -n -E "^(SPECMGR|PYYAML|LICENSE_EXPRESSION|BOOLEAN_PY)_SHA256=|^BOOLEAN_PY_VERSION=" "$1"' _ "${real_versions}"

# specmgr: the dependencies are checked too
dgit switch -q valid
run_docs_locks() { env PYTHON_LOCK_DIR="$1" GATE_WORK_ROOT="${docs}" "${GATES_DIR}/validate-docs.sh" base; }
expect 0 "linted=1 failed=0" "validate-docs.sh: installs specmgr from the lock file" run_docs_locks "${real_locks}"
expect 1 "Hash mismatch for \`biz-dfch-specmgr" "validate-docs.sh: a wrong hash of specmgr" \
    run_docs_locks "$(changed_lock sm-hash specmgr.lock break_hashes biz-dfch-specmgr)"
expect 1 "Hash mismatch for \`attrs" "validate-docs.sh: a wrong hash of a dependency of specmgr (attrs)" \
    run_docs_locks "$(changed_lock sm-dep-hash specmgr.lock break_hashes attrs)"
expect 1 "must have a hash" "validate-docs.sh: a dependency of specmgr (attrs) has no hash" \
    run_docs_locks "$(changed_lock sm-dep-nohash specmgr.lock no_hash attrs)"
expect 1 "uv did not install" "validate-docs.sh: a dependency of specmgr (attrs) is not in the lock file" \
    run_docs_locks "$(changed_lock sm-dep-drop specmgr.lock drop_package attrs)"
sed -e 's#^SPECMGR_VERSION=.*#SPECMGR_VERSION=0.38.1#' "${real_versions}" >"${work}/g2-specmgr-version.env"
expect 0 "linted=1 failed=0" "validate-docs.sh: the install is from the lock file, so another SPECMGR_VERSION in versions.env does not change it (check-pins stops it)" \
    env PYTHON_LOCK_DIR="${real_locks}" VERSIONS_FILE="${work}/g2-specmgr-version.env" GATE_WORK_ROOT="${docs}" "${GATES_DIR}/validate-docs.sh" base

# ---------------------------------------------------------------------------------------------
section "check-pins.sh: the lock files of the Python tools (feat-22-python-tools-lockfile, REQ-003, REQ-004)"
expect 0 "Python locks:" "the real lock files are exact pins with hashes, and have the versions of versions.env" run_pins_locks "${real_locks}"
# lock_case <name> <exit code> <text> <description> <file> <sed expression>: change a lock file of specmgr or license-expression
# with sed. (A change of pyyaml.lock stops the install of PyYAML before the check, see the cases above.)
lock_case() {
    local name="$1" code="$2" text="$3" description="$4" file="$5" expression="$6" dir
    dir="$(lock_copy "pin-${name}")"
    sed -e "${expression}" "${real_locks}/${file}" >"${dir}/${file}"
    if cmp -s "${real_locks}/${file}" "${dir}/${file}"; then
        echo "FAIL ${description}: the sed expression did not change the lock file"
        failed=$((failed + 1))
        return
    fi
    expect "${code}" "${text}" "${description}" run_pins_locks "${dir}"
}
no_spec_dir="$(lock_copy pin-nospec)"
rm "${no_spec_dir}/specmgr.lock"
expect 1 "specmgr.lock does not exist" "no lock file of specmgr" run_pins_locks "${no_spec_dir}"
expect 1 "Lock file not found" "no folder of the lock files (the install of PyYAML stops first)" run_pins_locks "${work}/no-such-lock-dir"
lock_case version 1 "has license-expression 30.4.3, but LICENSE_EXPRESSION_VERSION in tools/versions.env is 30.4.4" \
    "another version of the tool in the lock file" license-expression.lock 's#^license-expression==30.4.4#license-expression==30.4.3#'
sed -e 's#^SPECMGR_VERSION=.*#SPECMGR_VERSION=0.38.1#' "${real_versions}" >"${work}/pin-env/specmgr-version.env"
expect 1 "SPECMGR_VERSION in tools/versions.env is 0.38.1" "another version of the tool in versions.env" run_pins_locks "${real_locks}" "${work}/pin-env/specmgr-version.env"
grep -v '^SPECMGR_VERSION=' "${real_versions}" >"${work}/pin-env/no-specmgr-version.env"
expect 1 "SPECMGR_VERSION is not in tools/versions.env" "no version of the tool in versions.env" run_pins_locks "${real_locks}" "${work}/pin-env/no-specmgr-version.env"
sed -e 's#^SPECMGR_VERSION=.*#SPECMGR_VERSION=^0.38#' "${real_versions}" >"${work}/pin-env/range-specmgr-version.env"
expect 1 "must be an exact version" "a version range in versions.env" run_pins_locks "${real_locks}" "${work}/pin-env/range-specmgr-version.env"
lock_case nohash 1 "is not an exact pin" "a package with no hash" specmgr.lock '/^attrs==/{s/ \\$//;n;d}'
lock_case range 1 "is not an exact pin" "a package with a range and not an exact version" specmgr.lock 's#^anyio==4.16.0#anyio>=4.16.0#'
lock_case url 1 "is not an exact pin" "a package with a URL" specmgr.lock '1i foo @ https://example.invalid/foo-1.0-py3-none-any.whl'
lock_case urlhash 1 "is not an exact pin" "a URL after a package with hashes" specmgr.lock 's#^attrs==26.1.0 \\$#attrs @ https://example.invalid/attrs.whl \\#'
lock_case vcs 1 "is not an exact pin" "a package from a VCS source" specmgr.lock '1i git+https://example.invalid/foo.git'
lock_case editable 1 "is not an exact pin" "an editable entry" license-expression.lock '1i -e .'
lock_case path 1 "is not an exact pin" "a package from a path" license-expression.lock '1i ./local/foo.whl'
lock_case index 1 "is not an exact pin" "an index option" license-expression.lock '1i --index-url https://example.invalid/simple'
lock_case extraindex 1 "is not an exact pin" "an extra index option" license-expression.lock '1i --extra-index-url https://example.invalid/simple'
lock_case findlinks 1 "is not an exact pin" "a find-links option" license-expression.lock '1i --find-links https://example.invalid/'
lock_case nobinary 1 "is not an exact pin" "a no-binary option" license-expression.lock '1i --no-binary :all:'
lock_case shorthash 1 "is not an exact pin" "a hash that is not 64 hexadecimal characters" license-expression.lock '0,/--hash=sha256:[0-9a-f]\{64\}/s//--hash=sha256:abc123/'
lock_case sha512 1 "is not an exact pin" "a hash that is not a sha256 value" license-expression.lock '0,/--hash=sha256:/s//--hash=sha512:/'
lock_case markerurl 1 "is not an exact pin" "a marker that has a URL" specmgr.lock "s#^click==8.5.0 ; sys_platform != 'emscripten'#click==8.5.0 ; sys_platform @ https://example.invalid#"
lock_case notool 1 "has no entry of biz-dfch-specmgr" "no entry of the tool in its lock file" specmgr.lock '/^biz-dfch-specmgr==/,/^    # via/d'
two_dir="$(lock_copy pin-two)"
{
    cat "${real_locks}/license-expression.lock"
    printf 'license-expression==30.4.3 ; python_version < "3" \\\n    --hash=sha256:%064d\n' 0
} >"${two_dir}/license-expression.lock"
expect 1 "has license-expression 30.4.3, 30.4.4" "two entries of the tool with other versions" run_pins_locks "${two_dir}"
backslash_dir="$(lock_copy pin-backslash)"
{
    cat "${real_locks}/license-expression.lock"
    printf 'license-expression==30.4.4 \\\n'
} >"${backslash_dir}/license-expression.lock"
expect 1 "ends after a backslash" "a file that ends after a backslash" run_pins_locks "${backslash_dir}"
lock_case blankpkg 1 "has no package" "a lock file with no package" license-expression.lock '/^[a-z]/d;/^    /d'
extra_dir="$(lock_copy pin-extra)"
echo "foo==1.0 \\" >"${extra_dir}/extra.lock"
expect 1 "extra.lock is not allowed" "a fourth lock file in the folder" run_pins_locks "${extra_dir}"
echo "[pip]" >"${extra_dir}/pip.conf"
rm "${extra_dir}/extra.lock"
expect 1 "pip.conf is not allowed" "a pip.conf in the folder (it could change the index)" run_pins_locks "${extra_dir}"
expect 0 "Python lock pin: Python locks:" "check-pins.sh says that it checked the Python locks" run_pins_locks "${real_locks}"

echo
echo "gates self-test: ${passed} ok, ${failed} failed"
[[ ${failed} -eq 0 ]]
