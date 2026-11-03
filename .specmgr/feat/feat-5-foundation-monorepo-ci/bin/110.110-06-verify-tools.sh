#!/usr/bin/env bash
# feat-5-foundation-monorepo-ci, Task 110.120
#
# Checks that each tool in the PATH (after the environment file is read) is
# the version in tools/versions.env, and that it comes from TOOLS_HOME and
# not from the system. Exit code 0 only if all checks pass (ACC-004).
#
# Does not change anything.

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/_common.sh"

load_versions
require_var JDK_VERSION MAVEN_VERSION NODE_VERSION PNPM_VERSION JUST_VERSION
[[ -f "${ENV_FILE}" ]] || die "Environment file not found: ${ENV_FILE}. Run 110.110-05-write-env.sh first."
# shellcheck disable=SC1090
source "${ENV_FILE}"

failures=0
# check <label> <command-name> <expected-substring> <version-command...>
check() {
    local label="$1" cmd="$2" expected="$3"
    shift 3
    local path actual
    path="$(command -v "${cmd}" || true)"
    if [[ -z "${path}" ]]; then
        echo "FAIL ${label}: '${cmd}' is not in the PATH"; failures=$((failures + 1)); return
    fi
    if [[ "${path}" != "${TOOLS_HOME}"/* ]]; then
        echo "FAIL ${label}: '${cmd}' is ${path}, not in ${TOOLS_HOME}"; failures=$((failures + 1)); return
    fi
    actual="$("$@" 2>&1 | head -n 3 | tr '\n' ' ')"
    if [[ "${actual}" != *"${expected}"* ]]; then
        echo "FAIL ${label}: expected '${expected}' in: ${actual}"; failures=$((failures + 1)); return
    fi
    echo "ok   ${label}: ${expected} (${path})"
}

check "JDK"   java  "Temurin-${JDK_VERSION}"  java -version
check "Maven" mvn   "Apache Maven ${MAVEN_VERSION}" mvn --version
check "Node"  node  "v${NODE_VERSION}"        node --version
check "pnpm"  pnpm  "${PNPM_VERSION}"         pnpm --version
check "just"  just  "just ${JUST_VERSION}"    just --version

(( failures == 0 )) || die "${failures} check(s) failed."
log "All tools have the pinned versions."
