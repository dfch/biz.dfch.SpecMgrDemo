#!/usr/bin/env bash
# feat-5-foundation-monorepo-ci, Task 110.110
#
# Installs pnpm in the home directory, from the standalone release on GitHub.
# Node 26 has no corepack, so this script does not use it. The version and
# the checksum are in tools/versions.env. No special rights are necessary.
#
# Can be run again: it does nothing if this version is already installed.

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/_common.sh"

refuse_root
require_cmd curl
require_cmd tar
load_versions
require_var PNPM_VERSION PNPM_SHA256

# The archive has no top folder, so nothing is removed from the paths.
install_archive pnpm "${PNPM_VERSION}" \
    "https://github.com/pnpm/pnpm/releases/download/v${PNPM_VERSION}/pnpm-linux-x64.tar.gz" \
    256 "${PNPM_SHA256}" 0 \
    ./pnpm --version

actual="$("${TOOLS_HOME}/pnpm-${PNPM_VERSION}/pnpm" --version)"
[[ "${actual}" == "${PNPM_VERSION}" ]] || die "pnpm reports ${actual}, expected ${PNPM_VERSION}"
log "pnpm ${actual} is ready."
