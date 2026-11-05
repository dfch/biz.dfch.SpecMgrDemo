#!/usr/bin/env bash
# feat-6-contracts-openapi-pipeline, Task 115.130 (REQ-003, REQ-012, ACC-003, ACC-011, ACC-015)
#
# Test of the gate for breaking changes (breaking-changes.sh, breaking_changes.py) with the real oasdiff.
#
# Usage: test-breaking-changes-gate.sh
#
# Each case makes a temporary git repository with a branch `dev` (the base commit), the reference
# refs/remotes/origin/dev, and a branch `feature` with the change. The test does not use the history of the real
# repository. The gate runs with GATE_WORK_ROOT on that repository, as in `just breaking-changes`.
#
# The four cases of ACC-003 (DEC 93594b2b-be54-4f60-9f53-ec2ce6c84be4, "Confirmation"), marked "ACC-003 (1)" to
# "ACC-003 (4)" below:
#   (1) a change that removes a property of a response stops the gate;
#   (2) the same change with an entry in the ignore file and a higher version does not stop the gate;
#   (3) the same change with an entry and the same version stops the gate;
#   (4) a pull request that adds the OpenAPI file for the first time goes on.
# More cases: a lower version, a version that goes up in a way that rule 5 does not accept, a change that is not
# breaking (the default levels of oasdiff), a stale entry (a WARNING, no failure), an entry that is not correct, a
# comment that has the text of a change, the merge base (the base branch moves on), a deleted OpenAPI file, a
# configuration file of oasdiff in the repository, a file that oasdiff cannot read, the install of oasdiff with a
# checksum, and a table of versions for the comparison of the version numbers (SemVer 2.0.0).
#
# oasdiff comes from the install of the gate (install_oasdiff in _lib.sh: build/tools/, a download with a sha256 value
# of tools/versions.env). The first run needs the network (GitHub). The tests of the install use a small file that
# the test makes (file:// URL), and need no network. The script needs git, uv and the network for the first install.
# It does not change the repository.

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/_lib.sh"

require_cmd git
require_cmd uv

gate="${GATES_DIR}/breaking-changes.sh"
script="${GATES_DIR}/breaking_changes.py"
real_ignore="${REPO_ROOT}/tools/breaking/breaking-changes-ignore.txt"
real_openapi="${REPO_ROOT}/contracts/openapi.yaml"
[[ -f "${real_ignore}" ]] || die "No file ${real_ignore}"

# The Python of the gate (PyYAML from the lock file), for the tests of the version numbers. make_python_env sets
# the trap for its folder, so this script sets the trap again for both folders.
make_python_env pyyaml
work="$(mktemp -d)"
trap 'rm -rf "${work}" "${GATE_ENV_DIR}"' EXIT
install_oasdiff

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

# expect_not <exit code> <text that must NOT be in the output> <description> <command...>
expect_not() {
    local want_code="$1" bad_text="$2" description="$3"
    shift 3
    local output code
    set +e
    output="$("$@" 2>&1)"
    code=$?
    set -e
    if [[ ${code} -eq ${want_code} && "${output}" != *"${bad_text}"* ]]; then
        echo "ok   ${description}"
        passed=$((passed + 1))
    else
        echo "FAIL ${description}: expected exit code ${want_code} and no '${bad_text}', got exit code ${code}"
        echo "${output}" | sed -e 's/^/     | /'
        failed=$((failed + 1))
    fi
}

section() { echo; echo "== $*"; }

# --- The OpenAPI files of the cases --------------------------------------------------------------------------

# openapi_yaml <version> <checkedAt: yes|no> <enum values of state, separated by a comma> <extra: yes|no>
# A small OpenAPI 3.1 file with GET /status. The response 200 has the required members `state` and `checkedAt`
# (and, with extra=yes, the required member `extra`).
openapi_yaml() {
    local version="$1" checked="$2" values="$3" extra="$4" required="state" value
    [[ "${checked}" == "yes" ]] && required+=", checkedAt"
    [[ "${extra}" == "yes" ]] && required+=", extra"
    cat <<YAML
openapi: 3.1.0
info:
  title: Test API
  version: ${version}
paths:
  /status:
    get:
      operationId: getStatus
      responses:
        "200":
          description: The status.
          content:
            application/json:
              schema:
                \$ref: "#/components/schemas/Status"
components:
  schemas:
    Status:
      type: object
      required: [${required}]
      properties:
        state:
          type: string
          enum:
YAML
    IFS=',' read -r -a list <<<"${values}"
    for value in "${list[@]}"; do echo "            - ${value}"; done
    if [[ "${checked}" == "yes" ]]; then
        printf '        checkedAt:\n          type: string\n'
    fi
    if [[ "${extra}" == "yes" ]]; then
        printf '        extra:\n          type: string\n'
    fi
}

E_CHECKED='GET /status removed the required property `checkedAt` from the response with the `200` status'
E_EXTRA='GET /status removed the required property `extra` from the response with the `200` status'
E_ENUM='GET /status added the new `down` enum value to the `state` response property for the response status `200`'
entry() { echo "$1 | $2 | #7 | 0.2.0"; }

# --- The repositories of the cases --------------------------------------------------------------------------

git_in() { local repo="$1"; shift; git -C "${repo}" -c user.name=test -c user.email=test@example.invalid -c commit.gpgsign=false "$@"; }

# new_repo <name> [<base version> [<base values> [<extra in the base>]]]: a repository with the base commit on `dev`
# (contracts/openapi.yaml with the version, the member checkedAt, and the values up and degraded; the ignore file of
# the project, which has no entry), the reference origin/dev, and the branch `feature` (no change yet). Prints the path.
new_repo() {
    local repo="${work}/$1"
    git init -q -b dev "${repo}"
    mkdir -p "${repo}/contracts" "${repo}/tools/breaking"
    openapi_yaml "${2:-0.1.0}" yes "${3:-up,degraded}" "${4:-no}" >"${repo}/contracts/openapi.yaml"
    cp "${real_ignore}" "${repo}/tools/breaking/breaking-changes-ignore.txt"
    git_in "${repo}" add -A
    git_in "${repo}" commit -q -m "base"
    git_in "${repo}" update-ref refs/remotes/origin/dev dev
    git_in "${repo}" switch -q -c feature
    echo "${repo}"
}

# change <repo> <version> <checkedAt> <values> <extra> [<entry>...]: the change of the pull request (committed). The
# entries are added to the ignore file.
change() {
    local repo="$1" version="$2" checked="$3" values="$4" extra="$5"
    shift 5
    openapi_yaml "${version}" "${checked}" "${values}" "${extra}" >"${repo}/contracts/openapi.yaml"
    local line
    for line in "$@"; do echo "${line}" >>"${repo}/tools/breaking/breaking-changes-ignore.txt"; done
    git_in "${repo}" add -A
    git_in "${repo}" commit -q -m "change"
}

run_gate() { env GATE_WORK_ROOT="$1" "${gate}" "${2:-origin/dev}" contracts/openapi.yaml tools/breaking/breaking-changes-ignore.txt; }

# ============================================================================================================
section "The real files"
# The real ignore file of the project has no entry (the owner adds entries). It must be readable.
if grep -qvE '^[[:space:]]*(#|$)' "${real_ignore}"; then
    echo "FAIL ${real_ignore} has an entry. The file of the phase 115 has none."
    failed=$((failed + 1))
else
    echo "ok   tools/breaking/breaking-changes-ignore.txt has no entry"
    passed=$((passed + 1))
fi
repo="$(new_repo real-unchanged)"
cp "${real_openapi}" "${repo}/contracts/openapi.yaml"
git_in "${repo}" add -A && git_in "${repo}" commit -q -m "the real file"
git_in "${repo}" switch -q dev && cp "${real_openapi}" "${repo}/contracts/openapi.yaml" && git_in "${repo}" add -A && git_in "${repo}" commit -q -m "the real file on dev"
git_in "${repo}" update-ref refs/remotes/origin/dev dev && git_in "${repo}" switch -q -c feature2
expect 0 "RESULT: PASS. No breaking change." "contracts/openapi.yaml and the same file at the base: no breaking change" run_gate "${repo}"

# ============================================================================================================
section "ACC-003: the four cases of DEC 93594b2b-be54-4f60-9f53-ec2ce6c84be4"
repo="$(new_repo acc3-1)"
change "${repo}" 0.1.0 no "up,degraded" no
expect 1 "STOP breaking change that no entry ignores: ${E_CHECKED}" "ACC-003 (1): the change removes a property of a response: the gate stops" run_gate "${repo}"
expect 1 "adds one line to the ignore file" "ACC-003 (1): the message tells how the owner accepts the change" run_gate "${repo}"
expect 1 "${E_CHECKED} | <cause> | #<issue or pull request> | <release>" "ACC-003 (1): the message has the line for the entry" run_gate "${repo}"

repo="$(new_repo acc3-2)"
change "${repo}" 0.2.0 no "up,degraded" no "$(entry "${E_CHECKED}" "The member moves")"
expect 0 "RESULT: PASS. 1 breaking change(s) are ignored by 1 entry(ies), and the version goes up." "ACC-003 (2): the same change, an entry and a higher version: the gate passes" run_gate "${repo}"

repo="$(new_repo acc3-3)"
change "${repo}" 0.1.0 no "up,degraded" no "$(entry "${E_CHECKED}" "The member moves")"
expect 1 "RESULT: STOP. 1 breaking change(s) are ignored, but the version does not go up." "ACC-003 (3): the same change, an entry and the same version: the gate stops" run_gate "${repo}"
expect 1 "the new version is not higher than the version of the base" "ACC-003 (3): the message tells the cause" run_gate "${repo}"

repo="${work}/acc3-4"
git init -q -b dev "${repo}"
mkdir -p "${repo}/tools/breaking"
cp "${real_ignore}" "${repo}/tools/breaking/breaking-changes-ignore.txt"
git_in "${repo}" add -A && git_in "${repo}" commit -q -m "base: no OpenAPI file"
git_in "${repo}" update-ref refs/remotes/origin/dev dev && git_in "${repo}" switch -q -c feature
mkdir -p "${repo}/contracts"
openapi_yaml 0.1.0 yes "up,degraded" no >"${repo}/contracts/openapi.yaml"
git_in "${repo}" add -A && git_in "${repo}" commit -q -m "add the OpenAPI file"
expect 0 "The base has no contracts/openapi.yaml, so there is nothing to compare" "ACC-003 (4): the pull request adds the OpenAPI file for the first time: the gate goes on" run_gate "${repo}"
# the first-time case also passes with a new file that has an entry (nothing to compare, nothing used)
echo "$(entry "${E_CHECKED}" "x")" >>"${repo}/tools/breaking/breaking-changes-ignore.txt"
expect 0 "nothing to compare" "ACC-003 (4): the first-time pull request with an entry in the ignore file: the gate goes on" run_gate "${repo}"

# ============================================================================================================
section "No change, and the changes that are not breaking (the default levels of oasdiff)"
repo="$(new_repo nochange)"
expect 0 "RESULT: PASS. No breaking change." "no change: the gate passes" run_gate "${repo}"
repo="$(new_repo versiononly)"
change "${repo}" 0.2.0 yes "up,degraded" no
expect 0 "RESULT: PASS. No breaking change." "only the version goes up: the gate passes" run_gate "${repo}"
repo="$(new_repo enumremoved)"
change "${repo}" 0.1.0 yes "up" no
expect 0 "RESULT: PASS. No breaking change." "a value of an enum of a response is removed (info): the gate passes with no entry" run_gate "${repo}"
repo="$(new_repo enumadded)"
change "${repo}" 0.1.0 yes "up,degraded,down" no
expect 1 "STOP breaking change that no entry ignores: ${E_ENUM}" "a value of an enum of a response is added (error): the gate stops" run_gate "${repo}"
repo="$(new_repo enumaddedentry)"
change "${repo}" 0.2.0 yes "up,degraded,down" no "$(entry "${E_ENUM}" "The new state")"
expect 0 "RESULT: PASS. 1 breaking change(s) are ignored" "a value of an enum is added, with an entry and a higher version: the gate passes" run_gate "${repo}"

# ============================================================================================================
section "The version number (rule 5 of the DEC), with an entry that is used"
version_case() {
    # version_case <name> <base version> <new version> <exit code> <text> <description>
    local repo
    repo="$(new_repo "ver-$1" "$2")"
    change "${repo}" "$3" no "up,degraded" no "$(entry "${E_CHECKED}" "The member moves")"
    expect "$4" "$5" "$6" run_gate "${repo}"
}
version_case lower 0.1.0 0.0.9 1 "the new version is not higher than the version of the base" "the entry is used and the version is lower (0.1.0 to 0.0.9): the gate stops"
version_case patch 0.1.0 0.1.1 1 "the second number must go up" "the entry is used and only the third number goes up (0.1.0 to 0.1.1): the gate stops"
version_case minor 0.1.0 0.2.0 0 "the first number of the base is 0 and the second number goes up" "0.1.0 to 0.2.0: the gate passes"
version_case tenth 0.9.0 0.10.0 0 "RESULT: PASS" "0.9.0 to 0.10.0 (not a text comparison): the gate passes"
version_case major 0.1.0 1.0.0 0 "RESULT: PASS" "0.1.0 to 1.0.0: the gate passes"
version_case prerelease 0.1.0 0.2.0-rc.1 0 "RESULT: PASS" "0.1.0 to the pre-release 0.2.0-rc.1: the gate passes"
version_case sameline 0.2.0-rc.1 0.2.0 1 "the second number must go up" "the base is the pre-release 0.2.0-rc.1 and the new version is 0.2.0 (the same line): the gate stops"
version_case stable-minor 1.4.2 1.5.0 1 "the first number must go up" "1.4.2 to 1.5.0: the gate stops (the first number is not 0)"
version_case stable-major 1.4.2 2.0.0 0 "the first number goes up" "1.4.2 to 2.0.0: the gate passes"
version_case stable-lower 1.4.2 0.9.0 1 "the new version is not higher" "1.4.2 to 0.9.0: the gate stops"
version_case build 0.1.0 0.1.0+build.5 1 "the new version is not higher" "only the build metadata is new (0.1.0 to 0.1.0+build.5): the gate stops"
# A version that is not a text, or not SemVer
repo="$(new_repo ver-notsemver)"
change "${repo}" 0.2 no "up,degraded" no "$(entry "${E_CHECKED}" "x")"
expect 2 "cannot unmarshal number into field Info.version of type string" "the new version is 0.2 (YAML reads a number, oasdiff cannot read the file): exit code 2, the gate does not pass" run_gate "${repo}"
repo="$(new_repo ver-notsemver2)"
change "${repo}" "v0.2.0" no "up,degraded" no "$(entry "${E_CHECKED}" "x")"
expect 1 "which is not a version of Semantic Versioning 2.0.0" "the new version is v0.2.0: the gate stops" run_gate "${repo}"
# The version of the base is the version at the MERGE BASE
repo="$(new_repo ver-mergebase)"
git_in "${repo}" switch -q dev
openapi_yaml 0.3.0 yes "up,degraded" no >"${repo}/contracts/openapi.yaml"
git_in "${repo}" commit -q -am "dev has a new version"
git_in "${repo}" update-ref refs/remotes/origin/dev dev
git_in "${repo}" switch -q feature
change "${repo}" 0.2.0 no "up,degraded" no "$(entry "${E_CHECKED}" "x")"
expect 0 "\`info.version\` goes from 0.1.0 to 0.2.0" "dev moved on to 0.3.0: the version is compared with the merge base (0.1.0), and not with the tip of dev" run_gate "${repo}"

# ============================================================================================================
section "The ignore file: entries that are used, not used, or not correct"
repo="$(new_repo stale-nochange)"
change "${repo}" 0.1.0 yes "up,degraded" no "$(entry "${E_CHECKED}" "x")"
expect 0 "WARNING" "an entry and no breaking change (it matches nothing): the gate passes with a WARNING" run_gate "${repo}"
expect 0 "matches no breaking change" "the WARNING says that the entry matches no change" run_gate "${repo}"
expect 0 "RESULT: PASS. No breaking change." "an entry that matches nothing is not used, so the version does not matter" run_gate "${repo}"
repo="$(new_repo stale-other)"
change "${repo}" 0.2.0 no "up,degraded" no "$(entry "${E_EXTRA}" "x")"
expect 1 "STOP breaking change that no entry ignores: ${E_CHECKED}" "an entry for another change does not ignore this change: the gate stops" run_gate "${repo}"
expect 1 "WARNING" "the entry for the other change gets a WARNING" run_gate "${repo}"
repo="$(new_repo stale-and-used)"
change "${repo}" 0.2.0 no "up,degraded" no "$(entry "${E_EXTRA}" "x")" "$(entry "${E_CHECKED}" "x")"
expect 0 "RESULT: PASS. 1 breaking change(s) are ignored by 1 entry(ies)" "one entry is used and one matches nothing: the gate passes" run_gate "${repo}"
expect 0 "WARNING" "the entry that matches nothing gets a WARNING" run_gate "${repo}"
repo="$(new_repo twochanges)"
git_in "${repo}" switch -q dev
openapi_yaml 0.1.0 yes "up,degraded" yes >"${repo}/contracts/openapi.yaml"
git_in "${repo}" commit -q -am "base with extra"
git_in "${repo}" update-ref refs/remotes/origin/dev dev && git_in "${repo}" switch -q feature
git_in "${repo}" reset -q --hard dev
change "${repo}" 0.2.0 no "up,degraded" no "$(entry "${E_CHECKED}" "x")"
expect 1 "STOP breaking change that no entry ignores: ${E_EXTRA}" "two breaking changes and an entry for one: the gate stops for the other" run_gate "${repo}"
expect_not 1 "STOP breaking change that no entry ignores: ${E_CHECKED}" "the change that has an entry is not in the list of the changes that stop" run_gate "${repo}"
repo="$(new_repo twochanges-both)"
git_in "${repo}" switch -q dev
openapi_yaml 0.1.0 yes "up,degraded" yes >"${repo}/contracts/openapi.yaml"
git_in "${repo}" commit -q -am "base with extra"
git_in "${repo}" update-ref refs/remotes/origin/dev dev && git_in "${repo}" switch -q feature
git_in "${repo}" reset -q --hard dev
change "${repo}" 0.2.0 no "up,degraded" no "$(entry "${E_CHECKED}" "x")" "$(entry "${E_EXTRA}" "x")"
expect 0 "RESULT: PASS. 2 breaking change(s) are ignored by 2 entry(ies)" "two breaking changes and two entries: the gate passes" run_gate "${repo}"

# A line that starts with # is a comment for the gate. oasdiff itself would read it as an entry.
repo="$(new_repo comment)"
change "${repo}" 0.2.0 no "up,degraded" no "# ${E_CHECKED} | x | #7 | 0.2.0" "#${E_CHECKED}"
expect 1 "STOP breaking change that no entry ignores" "a comment line with the text of the change does not ignore the change" run_gate "${repo}"
# The gate gives oasdiff only the first item of an entry. The text of the cause is not the line of another entry: a
# cause that has the text of the change does not ignore it (oasdiff alone ignores a change if its text is anywhere in a line).
repo="$(new_repo cause-text)"
change "${repo}" 0.2.0 no "up,degraded" no "$(entry "${E_EXTRA}" "${E_CHECKED}")"
expect 1 "STOP breaking change that no entry ignores: ${E_CHECKED}" "the cause of an entry for another change has the text of this change: this change is not ignored" run_gate "${repo}"

bad_entry_case() {
    # bad_entry_case <name> <line> <text> <description>
    local repo
    repo="$(new_repo "bad-$1")"
    change "${repo}" 0.2.0 no "up,degraded" no "$2"
    expect 1 "$3" "$4" run_gate "${repo}"
}
bad_entry_case onlychange "${E_CHECKED}" "an entry has four items" "an entry with the first item only (as oasdiff reads it): the gate stops"
bad_entry_case threeitems "${E_CHECKED} | cause | #7" "an entry has four items" "an entry with three items: the gate stops"
bad_entry_case emptycause "${E_CHECKED} |  | #7 | 0.2.0" "an entry has four items" "an entry with an empty cause: the gate stops"
bad_entry_case noissue "${E_CHECKED} | cause | 7 | 0.2.0" "is not the number of an issue or a pull request" "the issue is 7 and not #7: the gate stops"
bad_entry_case norelease "${E_CHECKED} | cause | #7 | next" "is not a release version" "the release is not a version: the gate stops"
bad_entry_case nomethod "/status removed the required property | cause | #7 | 0.2.0" "is not \`<METHOD> <path>" "the first item has no method: the gate stops"
bad_entry_case nopath "GET status removed the required property | cause | #7 | 0.2.0" "is not \`<METHOD> <path>" "the first item has no path: the gate stops"
repo="$(new_repo bad-duplicate)"
change "${repo}" 0.2.0 no "up,degraded" no "$(entry "${E_CHECKED}" "x")" "$(entry "${E_CHECKED}" "y")"
expect 1 "the change is already in line" "the same change two times: the gate stops" run_gate "${repo}"
repo="$(new_repo bad-separator)"
change "${repo}" 0.2.0 no "up,degraded" no "${E_CHECKED}|cause|#7|0.2.0"
expect 1 "an entry has four items" "the items are not separated by a space, a bar and a space: the gate stops" run_gate "${repo}"
repo="$(new_repo bad-noignorefile)"
change "${repo}" 0.2.0 yes "up,degraded" no
git_in "${repo}" rm -q tools/breaking/breaking-changes-ignore.txt && git_in "${repo}" commit -q -m "no ignore file"
expect 1 "The ignore file does not exist" "no ignore file: the gate stops" run_gate "${repo}"

# ============================================================================================================
section "The base: merge base, a base that does not exist, a deleted file"
# The base branch moves on: dev gets a new required member in the response, and the feature does not have it. The
# feature has no change of its own. The merge base is the old commit of dev, so there is no change. The tip of dev
# would make a breaking change (the feature "removes" the member `extra`).
repo="$(new_repo mergebase)"
git_in "${repo}" switch -q dev
openapi_yaml 0.1.0 yes "up,degraded" yes >"${repo}/contracts/openapi.yaml"
git_in "${repo}" commit -q -am "dev moves on: a new required member"
git_in "${repo}" update-ref refs/remotes/origin/dev dev
git_in "${repo}" switch -q feature
echo "a change that is not in the OpenAPI file" >"${repo}/other.txt" && git_in "${repo}" add -A && git_in "${repo}" commit -q -m "other"
expect 0 "RESULT: PASS. No breaking change." "dev moved on and the feature did not change the file: the gate uses the merge base, so no change" run_gate "${repo}"
# Control: oasdiff alone, with the file at the tip of dev and the file of the feature, finds a breaking change. So
# the merge base is the cause that the gate passes.
git_in "${repo}" show dev:contracts/openapi.yaml >"${work}/tip-openapi.yaml"
expect 1 "removed the required property \`extra\` from the response with the \`200\` status" "control: oasdiff with the tip of dev and the file of the feature finds a breaking change" \
    "${OASDIFF_BIN}" breaking "${work}/tip-openapi.yaml" "${repo}/contracts/openapi.yaml" --fail-on ERR
repo="$(new_repo mergebase-tip)"
git_in "${repo}" switch -q dev
openapi_yaml 0.1.0 yes "up,degraded" yes >"${repo}/contracts/openapi.yaml"
git_in "${repo}" commit -q -am "dev moves on"
git_in "${repo}" update-ref refs/remotes/origin/dev dev
git_in "${repo}" switch -q feature
git_in "${repo}" merge -q --no-edit dev
expect 0 "RESULT: PASS. No breaking change." "the feature has merged dev: the merge base is the tip of dev, so no change" run_gate "${repo}"
# A release pull request: the base is origin/main. The OpenAPI file in main is the old one.
repo="$(new_repo release)"
git_in "${repo}" update-ref refs/remotes/origin/main dev
git_in "${repo}" switch -q dev
openapi_yaml 0.2.0 no "up,degraded" no >"${repo}/contracts/openapi.yaml"
git_in "${repo}" commit -q -am "dev has an accepted change"
echo "$(entry "${E_CHECKED}" "x")" >>"${repo}/tools/breaking/breaking-changes-ignore.txt"
git_in "${repo}" commit -q -am "and the entry"
git_in "${repo}" update-ref refs/remotes/origin/dev dev
expect 0 "RESULT: PASS. 1 breaking change(s) are ignored" "a release pull request to main: the base origin/main has the old file, and the accepted change has its entry and its version" run_gate "${repo}" origin/main
expect 0 "RESULT: PASS. No breaking change." "a pull request to dev with the base origin/dev (the same commit): no change" run_gate "${repo}" origin/dev
expect 1 "does not exist" "a base that does not exist: the gate stops" run_gate "${repo}" origin/no-such-branch
repo="$(new_repo deleted)"
git_in "${repo}" rm -q contracts/openapi.yaml && git_in "${repo}" commit -q -m "delete the OpenAPI file"
expect 1 "A deleted OpenAPI file is a breaking change of the whole interface" "the pull request deletes the OpenAPI file: the gate stops" run_gate "${repo}"
repo="$(new_repo neither)"
git_in "${repo}" switch -q dev && git_in "${repo}" rm -q contracts/openapi.yaml && git_in "${repo}" commit -q -m "no file on dev"
git_in "${repo}" update-ref refs/remotes/origin/dev dev && git_in "${repo}" switch -q feature && git_in "${repo}" reset -q --hard dev
expect 0 "nothing to compare" "neither the base nor the pull request has the file: the gate goes on" run_gate "${repo}"
expect 1 "Usage: breaking-changes.sh" "no argument" "${gate}"

# ============================================================================================================
section "oasdiff cannot be switched off from the repository, and its errors stop the gate"
# A configuration file of oasdiff in the repository could set err-ignore. The gate starts oasdiff in another folder.
repo="$(new_repo config)"
change "${repo}" 0.1.0 no "up,degraded" no
printf '%s\n' "${E_CHECKED}" >"${repo}/ignore-all.txt"
printf 'err-ignore: ignore-all.txt\n' >"${repo}/.oasdiff.yaml"
printf 'err-ignore: ignore-all.txt\n' >"${repo}/oasdiff.yaml"
git_in "${repo}" show dev:contracts/openapi.yaml >"${work}/config-base.yaml"
expect 0 "No breaking changes to report" "control: oasdiff alone in the folder of the repository reads .oasdiff.yaml, and it ignores the change" \
    bash -c 'cd "$1" && "$2" breaking "$3" contracts/openapi.yaml --fail-on ERR' _ "${repo}" "${OASDIFF_BIN}" "${work}/config-base.yaml"
expect 1 "STOP breaking change that no entry ignores: ${E_CHECKED}" "a .oasdiff.yaml and an oasdiff.yaml with err-ignore in the repository do not switch off the check" run_gate "${repo}"
printf 'err-ignore: %s\n' "${repo}/ignore-all.txt" >"${work}/oasdiff-config.yaml"
expect 1 "STOP breaking change that no entry ignores: ${E_CHECKED}" "the variable OASDIFF_CONFIG does not switch off the check" \
    env OASDIFF_CONFIG="${work}/oasdiff-config.yaml" GATE_WORK_ROOT="${repo}" "${gate}" origin/dev contracts/openapi.yaml tools/breaking/breaking-changes-ignore.txt
repo="$(new_repo broken)"
printf 'openapi: 3.1.0\ninfo: [\n' >"${repo}/contracts/openapi.yaml"
git_in "${repo}" add -A && git_in "${repo}" commit -q -m "broken file"
expect 2 "could not decide" "a file that oasdiff cannot read: exit code 2" run_gate "${repo}"
repo="$(new_repo notopenapi)"
printf 'a: b\n' >"${repo}/contracts/openapi.yaml"
git_in "${repo}" add -A && git_in "${repo}" commit -q -m "not an OpenAPI file"
expect 1 "api path removed without deprecation" "a file with no path (oasdiff reads it as an interface with no path): the paths are removed, and the gate stops" run_gate "${repo}"

# ============================================================================================================
section "The version numbers: Semantic Versioning 2.0.0 (breaking_changes.py semver)"
semver_case() {
    # semver_case <left> <right> <result>: the output must be exactly the result
    local output
    output="$("${GATE_PYTHON}" "${script}" semver "$1" "$2" 2>&1)" || true
    if [[ "${output}" == "$3" ]]; then
        echo "ok   semver: ${1} compared with ${2} gives ${3}"
        passed=$((passed + 1))
    else
        echo "FAIL semver: ${1} compared with ${2}: expected ${3}, got '${output}'"
        failed=$((failed + 1))
    fi
}
semver_case 1.9.0 1.10.0 -1
semver_case 1.10.0 1.9.0 1
semver_case 1.0.0 1.0.0 0
semver_case 0.2.0 0.10.0 -1
semver_case 2.0.0 1.99.99 1
# The order of point 11 of SemVer 2.0.0
semver_case 1.0.0-alpha 1.0.0-alpha.1 -1
semver_case 1.0.0-alpha.1 1.0.0-alpha.beta -1
semver_case 1.0.0-alpha.beta 1.0.0-beta -1
semver_case 1.0.0-beta 1.0.0-beta.2 -1
semver_case 1.0.0-beta.2 1.0.0-beta.11 -1
semver_case 1.0.0-beta.11 1.0.0-rc.1 -1
semver_case 1.0.0-rc.1 1.0.0 -1
semver_case 1.0.0 1.0.0-rc.1 1
semver_case 1.0.0-2 1.0.0-10 -1
semver_case 1.0.0-alpha 1.0.0-Alpha 1
semver_case 1.0.0-1 1.0.0-a -1
semver_case 1.0.0+build.1 1.0.0+build.2 0
semver_case 1.0.0-rc.1+a 1.0.0-rc.1+b 0
for wrong in "1.0" "01.0.0" "1.0.0-" "v1.0.0" "" "1.0.0.0" "1.0.0 " "1.0.0-01" "1.0.0-a..b" "1.0.0+" "latest" "1.x.0"; do
    expect 2 "is not a version of Semantic Versioning 2.0.0" "semver: '${wrong}' is not a version" "${GATE_PYTHON}" "${script}" semver "${wrong}" "1.0.0"
    expect 2 "is not a version of Semantic Versioning 2.0.0" "semver: '${wrong}' is not a version (right side)" "${GATE_PYTHON}" "${script}" semver "1.0.0" "${wrong}"
done
rule_case() {
    # rule_case <base> <new> <0: met | 1: not met> <text>
    expect "$3" "$4" "rule 5: ${1} to ${2} is $([[ $3 -eq 0 ]] && echo met || echo not met)" "${GATE_PYTHON}" "${script}" rule "$1" "$2"
}
rule_case 0.1.0 0.2.0 0 "second number goes up"
rule_case 0.1.0 0.10.0 0 "second number goes up"
rule_case 0.9.0 0.10.0 0 "second number goes up"
rule_case 0.1.0 1.0.0 0 "second number goes up"
rule_case 0.1.0 0.2.0-rc.1 0 "second number goes up"
rule_case 0.1.0 0.1.1 1 "the second number must go up"
rule_case 0.1.0 0.1.0 1 "not higher"
rule_case 0.1.0 0.0.9 1 "not higher"
rule_case 0.1.0+a 0.1.0+b 1 "not higher"
rule_case 0.2.0-rc.1 0.2.0 1 "the second number must go up"
rule_case 0.0.1 0.0.2 1 "the second number must go up"
rule_case 0.0.1 0.1.0 0 "second number goes up"
rule_case 1.4.2 1.5.0 1 "the first number must go up"
rule_case 1.4.2 1.4.3 1 "the first number must go up"
rule_case 1.4.2 1.4.2 1 "not higher"
rule_case 1.4.2 1.4.1 1 "not higher"
rule_case 1.4.2 0.9.0 1 "not higher"
rule_case 1.4.2 2.0.0 0 "the first number goes up"
rule_case 1.0.0 2.0.0-rc.1 0 "the first number goes up"
rule_case 1.0.0-rc.1 2.0.0 0 "the first number goes up"
rule_case 1.0.0-rc.1 1.0.0 1 "the first number must go up"
expect 2 "Usage:" "breaking_changes.py: no argument" "${GATE_PYTHON}" "${script}"
expect 2 "Usage:" "breaking_changes.py: check with too few arguments" "${GATE_PYTHON}" "${script}" check a b

# ============================================================================================================
section "The install of oasdiff: a checksum before the unpack (install_oasdiff in _lib.sh)"
# A small file that the test makes in the form of the release file: `oasdiff` (a script) and `LICENSE`.
fake_version="$(version_of OASDIFF_VERSION)"
fake_dir="${work}/fake-release"
mkdir -p "${fake_dir}"
printf '#!/usr/bin/env bash\necho "oasdiff version %s"\n' "${fake_version}" >"${fake_dir}/oasdiff"
chmod +x "${fake_dir}/oasdiff"
echo "fake license" >"${fake_dir}/LICENSE"
tar -czf "${work}/fake-oasdiff.tar.gz" -C "${fake_dir}" oasdiff LICENSE
fake_sha="$(sha256sum "${work}/fake-oasdiff.tar.gz" | cut -d' ' -f1)"
printf '#!/usr/bin/env bash\necho "oasdiff version 0.0.1"\n' >"${fake_dir}/oasdiff"
tar -czf "${work}/fake-oasdiff-version.tar.gz" -C "${fake_dir}" oasdiff LICENSE
fake_version_sha="$(sha256sum "${work}/fake-oasdiff-version.tar.gz" | cut -d' ' -f1)"
echo "not a tar file" >"${work}/fake-oasdiff-broken.tar.gz"
fake_broken_sha="$(sha256sum "${work}/fake-oasdiff-broken.tar.gz" | cut -d' ' -f1)"

# versions.env of the case: the real file with another OASDIFF_SHA256
install_env() {
    sed -e "s#^OASDIFF_SHA256=.*#OASDIFF_SHA256=$1#" "${REPO_ROOT}/tools/versions.env" >"${work}/install-versions.env"
}
run_install() {
    # run_install <home> <url>
    env VERSIONS_FILE="${work}/install-versions.env" OASDIFF_HOME="$1" OASDIFF_URL="$2" \
        bash -c 'source "$1/_lib.sh"; install_oasdiff; echo "BIN=${OASDIFF_BIN}"' _ "${GATES_DIR}"
}
install_env "${fake_sha}"
expect 0 "sha256 is correct for the oasdiff download" "a download with the pinned sha256 is installed" run_install "${work}/home1" "file://${work}/fake-oasdiff.tar.gz"
expect 0 "BIN=${work}/home1/oasdiff-${fake_version}/oasdiff" "install_oasdiff sets OASDIFF_BIN" run_install "${work}/home1" "file://${work}/no-such-file.tar.gz"
expect 0 "is already installed in ${work}/home1/oasdiff-${fake_version}" "a second run does not download again (the URL does not exist, and the run passes)" run_install "${work}/home1" "file://${work}/no-such-file.tar.gz"
expect 0 "oasdiff version ${fake_version}" "the installed binary is the one of the file" "${work}/home1/oasdiff-${fake_version}/oasdiff" --version
[[ -f "${work}/home1/oasdiff-${fake_version}/LICENSE" ]] && { echo "ok   the license file is installed"; passed=$((passed + 1)); } || { echo "FAIL no LICENSE in the install"; failed=$((failed + 1)); }
# The pin changes at the same version: the old install is not used, and the new download is compared with the new pin.
install_env "$(printf '0%.0s' {1..64})"
expect 1 "is ${fake_sha}, but OASDIFF_SHA256 in ${work}/install-versions.env is $(printf '0%.0s' {1..64}). The download is deleted. oasdiff did not start." \
    "another OASDIFF_SHA256 at the same version: a new download, and the checksum stops it (the old install is not used)" \
    run_install "${work}/home1" "file://${work}/fake-oasdiff.tar.gz"
install_env "${fake_sha}"
expect 1 "but OASDIFF_SHA256 in ${work}/install-versions.env is ${fake_sha}. The download is deleted. oasdiff did not start." "a download with another sha256 than the pin: the gate stops" \
    run_install "${work}/home2" "file://${work}/fake-oasdiff-version.tar.gz"
[[ ! -e "${work}/home2/oasdiff-${fake_version}" ]] && { echo "ok   after a wrong checksum nothing is installed"; passed=$((passed + 1)); } || { echo "FAIL a wrong checksum left an install"; failed=$((failed + 1)); }
shopt -s nullglob dotglob
leftover=("${work}"/home2/.oasdiff.*)
shopt -u nullglob dotglob
[[ ${#leftover[@]} -eq 0 ]] && { echo "ok   after a wrong checksum no download is left"; passed=$((passed + 1)); } || { echo "FAIL a wrong checksum left the download: ${leftover[*]}"; failed=$((failed + 1)); }
expect 1 "Download failed" "a URL that does not exist: the gate stops" run_install "${work}/home3" "file://${work}/no-such-file.tar.gz"
install_env "${fake_version_sha}"
expect 1 "says 'oasdiff version 0.0.1', but OASDIFF_VERSION" "a binary with another version than OASDIFF_VERSION: the gate stops" run_install "${work}/home4" "file://${work}/fake-oasdiff-version.tar.gz"
install_env "${fake_broken_sha}"
expect 1 "has not the files oasdiff and LICENSE" "a file that is not a tar file (with the right checksum): the gate stops" run_install "${work}/home5" "file://${work}/fake-oasdiff-broken.tar.gz"
# versions.env
sed -e "s#^OASDIFF_SHA256=.*#OASDIFF_SHA256=abc#" "${REPO_ROOT}/tools/versions.env" >"${work}/install-versions.env"
expect 1 "OASDIFF_SHA256 is not a sha256 value" "OASDIFF_SHA256 is not a sha256 value: the gate stops" run_install "${work}/home6" "file://${work}/fake-oasdiff.tar.gz"
sed -e "s#^OASDIFF_VERSION=.*#OASDIFF_VERSION=latest#" "${REPO_ROOT}/tools/versions.env" >"${work}/install-versions.env"
expect 1 "OASDIFF_VERSION is not an exact version" "OASDIFF_VERSION is not an exact version: the gate stops" run_install "${work}/home7" "file://${work}/fake-oasdiff.tar.gz"
grep -v '^OASDIFF_SHA256=' "${REPO_ROOT}/tools/versions.env" >"${work}/install-versions.env"
expect 1 "OASDIFF_SHA256 is not set" "versions.env has no OASDIFF_SHA256: the gate stops" run_install "${work}/home8" "file://${work}/fake-oasdiff.tar.gz"
grep -v '^OASDIFF_VERSION=' "${REPO_ROOT}/tools/versions.env" >"${work}/install-versions.env"
expect 1 "OASDIFF_VERSION is not set" "versions.env has no OASDIFF_VERSION: the gate stops" run_install "${work}/home9" "file://${work}/fake-oasdiff.tar.gz"
# The real binary, from the real install of this test
expect 0 "oasdiff version $(version_of OASDIFF_VERSION)" "the real oasdiff of build/tools has the pinned version" "${OASDIFF_BIN}" --version

echo
echo "gate for breaking changes: ${passed} ok, ${failed} failed"
[[ ${failed} -eq 0 ]]
