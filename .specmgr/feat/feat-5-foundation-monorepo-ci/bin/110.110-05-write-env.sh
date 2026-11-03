#!/usr/bin/env bash
# feat-5-foundation-monorepo-ci, Task 110.110
#
# Writes the environment file that puts the pinned tools first in the PATH
# and sets JAVA_HOME (so the JDK 21 wins over the JDK of the system), and
# adds one line to the shell profile that reads this file.
#
#   ~/.config/biz.dfch.SpecMgrDemo/env.sh   written (replaced if it changed)
#   ~/.bashrc                               one line added, only if it is not there
#
# Options:
#   --no-profile   write the environment file, but do not change the profile
#
# Environment: PROFILE_FILE (default ~/.bashrc), ENV_FILE, TOOLS_HOME.
#
# Can be run again with no change. To remove the setup, delete the two lines
# with the text "biz.dfch.SpecMgrDemo" from the profile, and delete the
# environment file.

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/_common.sh"

PROFILE_FILE="${PROFILE_FILE:-${HOME}/.bashrc}"
change_profile=1
for arg in "$@"; do
    case "${arg}" in
        --no-profile) change_profile=0 ;;
        *) die "Unknown option: ${arg}" ;;
    esac
done

refuse_root
load_versions
require_var JDK_VERSION MAVEN_VERSION NODE_VERSION PNPM_VERSION JUST_VERSION

jdk="${TOOLS_HOME}/jdk-${JDK_VERSION/+/_}"
for dir in "${jdk}" "${TOOLS_HOME}/maven-${MAVEN_VERSION}" "${TOOLS_HOME}/node-${NODE_VERSION}" \
           "${TOOLS_HOME}/pnpm-${PNPM_VERSION}" "${TOOLS_HOME}/just-${JUST_VERSION}"; do
    [[ -d "${dir}" ]] || die "Not installed: ${dir}. Run the install scripts first."
done

# 1. The environment file.
mkdir -p "$(dirname "${ENV_FILE}")"
new_env="$(mktemp "${ENV_FILE}.XXXXXX")"
_CLEANUP_DIRS+=("${new_env}")
cat > "${new_env}" <<ENVEOF
# Written by 110.110-05-write-env.sh (feat-5-foundation-monorepo-ci). Do not edit.
# The versions come from tools/versions.env. Run the script again after a change.
export JAVA_HOME="${jdk}"
case ":\${PATH}:" in
    *":${jdk}/bin:"*) ;;
    *) export PATH="${jdk}/bin:${TOOLS_HOME}/maven-${MAVEN_VERSION}/bin:${TOOLS_HOME}/node-${NODE_VERSION}/bin:${TOOLS_HOME}/pnpm-${PNPM_VERSION}:${TOOLS_HOME}/just-${JUST_VERSION}:\${PATH}" ;;
esac
ENVEOF

if [[ -f "${ENV_FILE}" ]] && cmp -s "${new_env}" "${ENV_FILE}"; then
    log "${ENV_FILE} is already correct."
else
    mv "${new_env}" "${ENV_FILE}"
    log "Wrote ${ENV_FILE}"
fi

# 2. The profile line, only if it is not there.
marker="biz.dfch.SpecMgrDemo"
if (( change_profile )); then
    if [[ -f "${PROFILE_FILE}" ]] && grep -qF "${marker}" "${PROFILE_FILE}"; then
        log "${PROFILE_FILE} already reads the environment file."
    else
        {
            echo ""
            echo "# ${marker} toolchain (feat-5-foundation-monorepo-ci, Task 110.110)"
            echo "[ -f \"${ENV_FILE}\" ] && . \"${ENV_FILE}\""
        } >> "${PROFILE_FILE}"
        log "Added two lines to ${PROFILE_FILE}. Open a new shell to use the tools."
    fi
else
    log "Profile not changed (--no-profile). Use: source ${ENV_FILE}"
fi
