#!/usr/bin/env bash
# feat-5-foundation-monorepo-ci, Task 110.105
#
# Installs Node (LTS) in the home directory. The version and the checksum
# are in tools/versions.env. No special rights are necessary.
#
# Can be run again: it does nothing if this version is already installed.
# The Node of the system is not used and not changed.

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/_common.sh"

refuse_root
require_cmd curl
require_cmd tar
require_cmd xz
load_versions
require_var NODE_VERSION NODE_SHA256

install_archive node "${NODE_VERSION}" \
    "https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-x64.tar.xz" \
    256 "${NODE_SHA256}" 1 \
    ./bin/node --version

actual="$("${TOOLS_HOME}/node-${NODE_VERSION}/bin/node" --version)"
[[ "${actual}" == "v${NODE_VERSION}" ]] || die "Node reports ${actual}, expected v${NODE_VERSION}"
log "Node ${actual} is ready."
