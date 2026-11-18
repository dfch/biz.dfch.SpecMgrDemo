#!/usr/bin/env bash
# feat-6-contracts-openapi-pipeline, Task 120.120 (REQ-004, ACC-005)
#
# Compiles the two modules with the generated code:
#   - the Maven module: `./mvnw compile`. The execution `spring-interfaces` of the generator plugin is bound to the phase
#     generate-sources, so the build makes the Java code again (the same bytes as `just generate`) and adds
#     backend/src/generated/java as a compile source root;
#   - the pnpm module: `pnpm exec tsc --noEmit --strict` with the committed code in frontend/src/generated (the install is
#     `pnpm install --frozen-lockfile --ignore-scripts`), and then the build of the browser bundle: `pnpm run build` (the
#     script `build` of frontend/package.json, `vite build`) into a temporary folder that the script removes, so a bundle that
#     does not build (a missing import in index.html or in the code that tsc does not read, a plugin or a config error) stops
#     the gate (feat-9-walking-skeleton, review N6a). The build is offline (the lock file is installed already) and it writes
#     nothing into the repository.
#
# Usage: compile.sh <backend dir> <frontend dir>
#
# The sha256 of the jar of the generator plugin must be the value of OPENAPI_GENERATOR_MAVEN_PLUGIN_SHA256 first
# (verify_generator_plugin in _lib.sh). The CI job `compile` starts this recipe (task 130.105). Needs JDK 21, Node, pnpm and the
# network for the first run. The Maven build writes <backend dir>/target (in .gitignore).

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/_lib.sh"

[[ $# -eq 2 ]] || die "Usage: compile.sh <backend dir> <frontend dir>"
backend="$1"
frontend="$2"
[[ -f "${backend}/pom.xml" ]] || die "${backend}/pom.xml does not exist."
[[ -f "${frontend}/tsconfig.json" ]] || die "${frontend}/tsconfig.json does not exist."
backend="$(cd "${backend}" && pwd)"
frontend="$(cd "${frontend}" && pwd)"
repo_local="${GENERATOR_MAVEN_REPO_LOCAL:-${HOME}/.m2/repository}"

verify_generator_plugin "${backend}"
backend_maven_args "${backend}" # the property build.info.commit (the value of the build, Task 200.120)
log "Compile the Maven module: ./mvnw compile"
(cd "${backend}" && ./mvnw --batch-mode --no-transfer-progress --file pom.xml "-Dmaven.repo.local=${repo_local}" \
    "${MAVEN_BUILD_ARGS[@]}" compile) \
    || die "./mvnw compile failed in ${backend} (see above)."

install_frontend "${frontend}"
log "Compile the pnpm module: pnpm exec tsc --noEmit --strict"
(cd "${frontend}" && pnpm exec tsc --noEmit --strict) || die "tsc failed in ${frontend} (see above)."
bundle_dir="$(mktemp -d)"
trap 'rm -rf "${bundle_dir}"' EXIT
log "Build the bundle of the pnpm module: pnpm run build (vite build) into a temporary folder"
(cd "${frontend}" && pnpm run build --outDir "${bundle_dir}" --emptyOutDir) \
    || die "vite build failed in ${frontend} (see above)."
[[ -s "${bundle_dir}/index.html" ]] || die "vite build made no index.html in the output folder."
log "PASS. The Maven module and the pnpm module compile with the generated code, and the bundle builds."
