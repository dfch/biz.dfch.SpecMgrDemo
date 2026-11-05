#!/usr/bin/env bash
# feat-6-contracts-openapi-pipeline, Task 120.130 (REQ-015, ACC-018)
#
# Makes the API documentation (HTML) from contracts/openapi.yaml with the generator `html2` of openapi-generator-maven-plugin:
# the second execution (`api-docs`) of the plugin that is already pinned. It needs no new tool and no new pin.
#
# Usage: api-docs.sh <backend dir> <output dir>
#   <backend dir>  the Maven module with mvnw, for example backend
#   <output dir>   the folder for the HTML, for example build/api-docs. The script deletes it first. The folder is not in git
#                  (/build/ is in .gitignore), and the gate for generated code does not check it.
#
# The result is index.html (one file with the CSS and the scripts in it) and the marker files of the generator
# (.openapi-generator/ and .openapi-generator-ignore). Two runs one after the other make the same files (REQ-015): html2 writes
# no time (the option hideGenerationTimestamp=true is set in backend/pom.xml all the same), and just test-generate-gate
# compares two runs with `diff -r`.
#
# The sha256 of the jar of the plugin must be the value of OPENAPI_GENERATOR_MAVEN_PLUGIN_SHA256 first
# (verify_generator_plugin in _lib.sh). The CI job `api-docs` starts this script and keeps the HTML as an artifact (task 130.110).
# Note for a person who opens the HTML: the template of html2 has a font from fonts.googleapis.com
# (`@import url(...)`), so a browser makes a network request when it shows the page (finding F2 of the license checks).
# Needs JDK 21 and the network for the first run (Maven Central).

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/_lib.sh"

[[ $# -eq 2 ]] || die "Usage: api-docs.sh <backend dir> <output dir>"
backend="$1"
output="$2"
[[ -f "${backend}/pom.xml" ]] || die "${backend}/pom.xml does not exist."
backend="$(cd "${backend}" && pwd)"
mkdir -p "$(dirname "${output}")"
output="$(cd "$(dirname "${output}")" && pwd)/$(basename "${output}")"
plugin_version="$(version_of OPENAPI_GENERATOR_MAVEN_PLUGIN_VERSION)"
repo_local="${GENERATOR_MAVEN_REPO_LOCAL:-${HOME}/.m2/repository}"

verify_generator_plugin "${backend}"
log "Delete ${output}"
rm -rf "${output}"
log "Make the API documentation (execution api-docs, generator html2) in ${output}"
(
    cd "${backend}" && ./mvnw --batch-mode --no-transfer-progress --file pom.xml "-Dmaven.repo.local=${repo_local}" \
        "-Dapi-docs.dir=${output}" "org.openapitools:openapi-generator-maven-plugin:${plugin_version}:generate@api-docs"
) || die "Maven did not make the API documentation (see above)."
[[ -s "${output}/index.html" ]] || die "The generator made no ${output}/index.html."
log "PASS. ${output}/index.html ($(wc -c <"${output}/index.html") bytes)"
