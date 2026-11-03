#!/usr/bin/env bash
# feat-5-foundation-monorepo-ci, Task 110.110
#
# Installs Apache Maven in the home directory. The version and the checksum
# are in tools/versions.env. No special rights are necessary.
#
# Can be run again: it does nothing if this version is already installed.
# This script does not start Maven, because Maven needs the JDK from
# 110.110-01. 110.110-06-verify-tools.sh starts it.

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/_common.sh"

refuse_root
require_cmd curl
require_cmd tar
load_versions
require_var MAVEN_VERSION MAVEN_SHA512

install_archive maven "${MAVEN_VERSION}" \
    "https://archive.apache.org/dist/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz" \
    512 "${MAVEN_SHA512}" 1 \
    test -x ./bin/mvn

log "Maven ${MAVEN_VERSION} is installed."
