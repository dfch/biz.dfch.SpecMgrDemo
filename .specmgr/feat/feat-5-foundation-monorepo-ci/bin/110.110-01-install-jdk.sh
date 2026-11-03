#!/usr/bin/env bash
# feat-5-foundation-monorepo-ci, Task 110.110
#
# Installs Eclipse Temurin (an OpenJDK build, LTS) in the home directory.
# The version and the checksum are in tools/versions.env. No special rights
# are necessary. The JDK of the system is not changed.
#
# Can be run again: it does nothing if this version is already installed.

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/_common.sh"

refuse_root
require_cmd curl
require_cmd tar
load_versions
require_var JDK_VERSION JDK_SHA256

# JDK_VERSION has the form 21.0.13+9. The release tag has "%2B", and the
# file name has "_", in place of the "+".
major="${JDK_VERSION%%.*}"
tag="jdk-${JDK_VERSION/+/%2B}"
file="OpenJDK${major}U-jdk_x64_linux_hotspot_${JDK_VERSION/+/_}.tar.gz"

install_archive jdk "${JDK_VERSION/+/_}" \
    "https://github.com/adoptium/temurin${major}-binaries/releases/download/${tag}/${file}" \
    256 "${JDK_SHA256}" 1 \
    ./bin/java -version

actual="$("${TOOLS_HOME}/jdk-${JDK_VERSION/+/_}/bin/java" -version 2>&1)"
[[ "${actual}" == *"Temurin-${JDK_VERSION}"* ]] || die "The JDK does not report Temurin-${JDK_VERSION}: ${actual}"
log "JDK Temurin-${JDK_VERSION} is ready."
