#!/usr/bin/env bash
# feat-5-foundation-monorepo-ci, Tasks 130.110 to 130.145 (the tests of the gates)
#
# Self-test of the gates: each gate runs with good input (it must pass) and with bad input (it
# must stop with the exit code and the message that the test expects). The license gate has its
# own test with fixtures (test-license-gate.sh).
#
# Usage: selftest.sh
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

# ---------------------------------------------------------------------------------------------
section "check-workflows.sh (Task 130.140)"
wf() {
    # wf <folder> <steps>: write a workflow with the steps (the text of the steps starts with 6 spaces)
    mkdir -p "$1"
    cat >"$1/ci.yml" <<YAML
name: T
on: pull_request
jobs:
  j:
    runs-on: ubuntu-latest
    steps:
$2
YAML
}
run_wf() { "${GATES_DIR}/check-workflows.sh" "${real_justfile}" "$1"; }

mkdir -p "${work}/wf-real" && cp "${real_workflow}" "${work}/wf-real/ci.yml"
expect 0 "RESULT: PASS" "the real workflow" run_wf "${work}/wf-real"
wf "${work}/wf-good" "      - run: just validate
      - run: |
          just commit-check"
expect 0 "RESULT: PASS" "just <recipe>, and a block scalar with one line" run_wf "${work}/wf-good"

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
printf 'PYYAML_VERSION=6.0.3\nthis is not a version line\n' >"${work}/pin-env/bad.env"
expect 2 "the form is not KEY=value" "tools/versions.env has a line that is not KEY=value" \
    "${GATES_DIR}/check-pins.sh" "${work}/pin-env/bad.env" "${work}/wf-real" "${real_allowed}"

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
section "sbom.sh and license-check.sh with stubs for mvn and pnpm (Task 130.130)"
stubs="${work}/stubs"
mkdir -p "${stubs}"
cat >"${stubs}/mvn" <<'STUB'
#!/usr/bin/env bash
# Stub of mvn for the test: writes target/bom.json, like cyclonedx-maven-plugin.
echo "stub mvn $*"
[[ "${STUB_MVN_FAIL:-}" == "1" ]] && exit 0
mkdir -p target
cat >target/bom.json <<'JSON'
{"bomFormat":"CycloneDX","specVersion":"1.6","version":1,"components":[{"type":"library","name":"lib","version":"1","licenses":[{"license":{"id":"Apache-2.0"}}]}]}
JSON
STUB
cat >"${stubs}/pnpm" <<'STUB'
#!/usr/bin/env bash
# Stub of pnpm for the test: writes the file of the argument --output, like cdxgen.
echo "stub pnpm $*"
while [[ $# -gt 0 ]]; do
    if [[ "$1" == "--output" ]]; then
        echo '{"bomFormat":"CycloneDX","specVersion":"1.6","version":1,"components":[{"type":"library","name":"npmlib","version":"1","licenses":[{"license":{"name":"The MIT License (MIT)"}}]}]}' >"$2"
    fi
    shift
done
STUB
chmod +x "${stubs}/mvn" "${stubs}/pnpm"
project="${work}/project"
mkdir -p "${project}/frontend" "${project}/build/sbom"
: >"${project}/pom.xml"
echo '{}' >"${project}/frontend/package.json"
echo '{}' >"${project}/build/sbom/old.json"
expect 0 "Wrote" "sbom.sh with pom.xml and frontend/package.json" \
    env PATH="${stubs}:${PATH}" SBOM_PROJECT_ROOT="${project}" "${GATES_DIR}/sbom.sh" "${project}/build/sbom"
if [[ -f "${project}/build/sbom/backend.cdx.json" && -f "${project}/build/sbom/frontend.cdx.json" && ! -f "${project}/build/sbom/old.json" ]]; then
    echo "ok   sbom.sh wrote backend.cdx.json and frontend.cdx.json, and removed the old file"
    passed=$((passed + 1))
else
    echo "FAIL sbom.sh: files in the SBOM folder are not the expected ones"
    ls "${project}/build/sbom"
    failed=$((failed + 1))
fi
expect 0 "RESULT: PASS. 2 component(s)" "license-check.sh with the SBOM files of the stubs" \
    "${GATES_DIR}/license-check.sh" "${project}/build/sbom" "${REPO_ROOT}/tools/license/permitted-licenses.txt"
expect 1 "did not make" "sbom.sh when Maven makes no file" \
    env PATH="${stubs}:${PATH}" STUB_MVN_FAIL=1 SBOM_PROJECT_ROOT="${project}" "${GATES_DIR}/sbom.sh" "${project}/build/sbom2"
mkdir -p "${work}/empty-project"
expect 0 "Nothing to scan" "sbom.sh with no manifest" \
    env SBOM_PROJECT_ROOT="${work}/empty-project" "${GATES_DIR}/sbom.sh" "${work}/empty-project/build/sbom"
expect 2 "no SBOM file" "license-check.sh with an empty SBOM folder" \
    "${GATES_DIR}/license-check.sh" "${work}/empty-project/no-sbom" "${REPO_ROOT}/tools/license/permitted-licenses.txt"

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

dgit switch -q -c invalid valid
mkdir -p "${docs}/docs/dec"
printf '# Not a decision\n' >"${docs}/${bad_name}"
dgit add -A && dgit commit -q -m "an invalid document"
expect 1 "failed=1" "an invalid document in a commit" run_docs base

dgit switch -q valid
printf '# Not a decision\n' >"${docs}/docs/dec/$(basename "${valid_doc}")"
expect 1 "failed=1" "a document that is invalid in the working tree only" run_docs base
dgit checkout -q -- .

dgit switch -q -c deleted with-bad-base
dgit rm -q "${bad_name}"
dgit commit -q -m "delete the bad document"
expect 0 "Nothing to validate" "a deleted document is skipped" run_docs with-bad-base
expect 1 "does not exist" "a base that does not exist" run_docs no-such-base

echo
echo "gates self-test: ${passed} ok, ${failed} failed"
[[ ${failed} -eq 0 ]]
