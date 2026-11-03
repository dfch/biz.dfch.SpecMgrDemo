#!/usr/bin/env bash
# feat-5-foundation-monorepo-ci, Task 110.110
#
# Installs just (the task runner) in the home directory. The version and the
# checksum are in tools/versions.env. No special rights are necessary.
#
# Can be run again: it does nothing if this version is already installed.

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/_common.sh"

refuse_root
require_cmd curl
require_cmd tar
load_versions
require_var JUST_VERSION JUST_SHA256

# The archive has no top folder, so nothing is removed from the paths.
install_archive just "${JUST_VERSION}" \
    "https://github.com/casey/just/releases/download/${JUST_VERSION}/just-${JUST_VERSION}-x86_64-unknown-linux-musl.tar.gz" \
    256 "${JUST_SHA256}" 0 \
    ./just --version

actual="$("${TOOLS_HOME}/just-${JUST_VERSION}/just" --version)"
[[ "${actual}" == "just ${JUST_VERSION}" ]] || die "just reports '${actual}', expected 'just ${JUST_VERSION}'"
log "${actual} is ready."
