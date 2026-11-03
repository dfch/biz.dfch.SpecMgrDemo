#!/usr/bin/env bash
# feat-5-foundation-monorepo-ci, Task 130.130 (REQ-006, ACC-010) and the findings E1, G1 and G2 of the review
#
# Makes the SBOM files (CycloneDX, JSON) of the project.
#
# Usage: sbom.sh <dir>
#   <dir>  the folder for the SBOM files, for example build/sbom. The script deletes the
#          *.json files in it first, so that no old file stays.
#
# What the script scans (the set of manifests):
#   Maven     pom.xml (the root), or backend/pom.xml if there is no root pom.xml. The script makes the
#             aggregate BOM (goal makeAggregateBom), so each pom.xml below backend/ is a module that the
#             BOM covers. The file is <dir>/backend.cdx.json. The script does not read the <modules>
#             list: it assumes that a pom.xml below backend/ is a module of the scanned pom.xml.
#   Node      frontend/package.json or frontend/pnpm-lock.yaml (and frontend/pnpm-workspace.yaml).
#             `pnpm dlx @cyclonedx/cdxgen` makes <dir>/frontend.cdx.json. A package.json below frontend/
#             is covered only if frontend/pnpm-workspace.yaml and frontend/pnpm-lock.yaml both exist
#             (cdxgen reads the workspace from the lock file; a nested package.json with no
#             workspace is not read).
#   none      if no manifest exists (this is the case until feat-6-contracts-openapi-pipeline adds
#             them): a valid SBOM with `components: []`, in <dir>/project.cdx.json. The script says so.
#
# Rules (fail closed):
#   E1a  Any pom.xml, package.json, pnpm-lock.yaml or pnpm-workspace.yaml in the repository that is NOT in
#        the set above stops the script (exit code 1) with its path. For example a package.json in the
#        root or in contracts/, a pom.xml in model/ or in backend/ when no pom.xml scans backend. The
#        script does not enter .git, node_modules, build and target (at each level), and, from the
#        root only, .specmgr (the folders of the features keep prototypes that are not part of the
#        layout), tools/license/fixtures and tools/gates/fixtures.
#   E1b  If a scanned package.json has an entry in dependencies, devDependencies, optionalDependencies or
#        peerDependencies (or a scanned pom.xml has a <dependency> in <dependencies>) and the SBOM that the
#        tool made has no component, the script stops. sbom_check.py does this check (it reads
#        the manifests and counts the components of the SBOM file, with the Python of `uv run`).
#   G1   A Maven project must have the Maven Wrapper (mvnw) next to the scanned pom.xml. The script
#        starts mvnw, and never the Maven of the machine or of the runner, so that Maven is the version that
#        the wrapper pins (check-pins.sh checks that this version is MAVEN_VERSION). No mvnw stops the script.
#   G2   Before the real run, the script starts the plugin with -Dcyclonedx.skip=true (it loads the plugin
#        and does nothing), and compares the sha256 of the plugin jar in the local Maven repository with
#        CYCLONEDX_MAVEN_PLUGIN_SHA256. For cdxgen, the script compares `pnpm view
#        @cyclonedx/cdxgen@<version> dist.integrity` with CDXGEN_INTEGRITY before `pnpm dlx`. A value
#        that is not the same stops the script. The dependencies of the plugin and of cdxgen are NOT checked.
#
# The versions and the checksums are in tools/versions.env (VERSIONS_FILE sets another file, for the
# tests). The script does not change the system. The test with real dependencies is open until feat-6
# gives the manifests. These environment variables are for the tests:
#   SBOM_PROJECT_ROOT       another root of the project
#   SBOM_MAVEN_REPO_LOCAL   the local Maven repository (the default is ~/.m2/repository). The script gives it
#                           to Maven with -Dmaven.repo.local, so it knows where the plugin jar is.

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/_lib.sh"

[[ $# -eq 1 ]] || die "Usage: sbom.sh <dir>"
out_dir="$1"
project_root="${SBOM_PROJECT_ROOT:-${REPO_ROOT}}"

cd "${project_root}"

# The set of manifests that the script scans.
maven_root=""
if [[ -f pom.xml ]]; then
    maven_root="."
elif [[ -f backend/pom.xml ]]; then
    maven_root="backend"
fi
node_scanned=0
[[ -f frontend/package.json || -f frontend/pnpm-lock.yaml ]] && node_scanned=1
node_workspace=0
[[ -f frontend/pnpm-workspace.yaml && -f frontend/pnpm-lock.yaml ]] && node_workspace=1

# is_covered <path> -- true if the scan of the set above covers the manifest (path relative to the root).
is_covered() {
    case "$1" in
        pom.xml) [[ "${maven_root}" == "." ]] ;;
        backend/pom.xml | backend/*/pom.xml) [[ -n "${maven_root}" ]] ;;
        frontend/package.json | frontend/pnpm-lock.yaml | frontend/pnpm-workspace.yaml) [[ ${node_scanned} -eq 1 ]] ;;
        frontend/*/package.json) [[ ${node_scanned} -eq 1 && ${node_workspace} -eq 1 ]] ;;
        *) return 1 ;;
    esac
}

# E1a: each manifest outside the set stops the script.
unscanned=()
maven_manifests=()
node_manifests=()
while IFS= read -r path; do
    path="${path#./}"
    if is_covered "${path}"; then
        case "${path}" in
            *pom.xml) maven_manifests+=("${path}") ;;
            *package.json) node_manifests+=("${path}") ;;
        esac
    else
        unscanned+=("${path}")
    fi
done < <(manifest_files .)
if [[ ${#unscanned[@]} -gt 0 ]]; then
    printf '[sbom.sh] STOP: %s is not scanned by sbom.sh\n' "${unscanned[@]}" >&2
    die "${#unscanned[@]} manifest(s) are outside the set that this script scans, so their licenses would not be checked. Scanned: pom.xml or backend/pom.xml (and the poms below backend/), frontend/package.json, frontend/pnpm-lock.yaml and frontend/pnpm-workspace.yaml (and, with a workspace and a lock file, the package.json files below frontend/). Move the manifest, or change this script (and its tests) first. Not entered: .git, node_modules, build, target, .specmgr, tools/license/fixtures, tools/gates/fixtures."
fi

mkdir -p "${out_dir}"
out_dir="$(cd "${out_dir}" && pwd)"
rm -f "${out_dir}"/*.json

# sbom_plausible <node|maven> <sbom file> <manifest>... -- E1b: the SBOM has components if the manifests declare dependencies.
sbom_plausible() {
    require_cmd uv
    uv run --no-project --quiet python "${GATES_DIR}/sbom_check.py" "$@" \
        || die "The SBOM $2 does not fit the manifests (see above)."
}

made=0

# Backend (Maven)
if [[ -n "${maven_root}" ]]; then
    pom_dir="$(cd "${maven_root}" && pwd)"
    pom_file="pom.xml" mvnw_file="mvnw"
    if [[ "${maven_root}" != "." ]]; then
        pom_file="${maven_root}/pom.xml" mvnw_file="${maven_root}/mvnw"
    fi
    [[ -f "${pom_dir}/mvnw" ]] \
        || die "${pom_file} exists, but ${mvnw_file} does not. CI has no Maven setup action, and the script must not use the Maven of the runner. Add the Maven Wrapper (mvnw and .mvn/wrapper/maven-wrapper.properties) for Maven $(version_of MAVEN_VERSION) with distributionSha256Sum. check-pins.sh checks it."
    [[ -x "${pom_dir}/mvnw" ]] || die "${pom_dir}/mvnw is not executable (chmod +x, and git update-index --chmod=+x)."
    plugin_version="$(version_of CYCLONEDX_MAVEN_PLUGIN_VERSION)"
    plugin_sha="$(version_of CYCLONEDX_MAVEN_PLUGIN_SHA256)"
    [[ "${plugin_sha}" =~ ^[0-9a-f]{64}$ ]] || die "CYCLONEDX_MAVEN_PLUGIN_SHA256 is not a sha256 value: '${plugin_sha}'"
    require_cmd sha256sum
    repo_local="${SBOM_MAVEN_REPO_LOCAL:-${HOME}/.m2/repository}"
    plugin_jar="${repo_local}/org/cyclonedx/cyclonedx-maven-plugin/${plugin_version}/cyclonedx-maven-plugin-${plugin_version}.jar"
    goal="org.cyclonedx:cyclonedx-maven-plugin:${plugin_version}:makeAggregateBom"
    log "Backend: ${pom_file} with ${mvnw_file}, cyclonedx-maven-plugin ${plugin_version}"
    rm -f "${pom_dir}/target/bom.json" # no old file can pass for the new one
    # G2: load the plugin (skip), then compare the jar with the checksum, then make the SBOM.
    (cd "${pom_dir}" && ./mvnw --batch-mode --file pom.xml "-Dmaven.repo.local=${repo_local}" "${goal}" -Dcyclonedx.skip=true)
    [[ -f "${plugin_jar}" ]] || die "The plugin jar is not at ${plugin_jar} after Maven loaded it."
    actual_sha="$(sha256sum "${plugin_jar}" | cut -d' ' -f1)"
    [[ "${actual_sha}" == "${plugin_sha}" ]] \
        || die "sha256 of ${plugin_jar} is ${actual_sha}, but CYCLONEDX_MAVEN_PLUGIN_SHA256 in ${VERSIONS_FILE} is ${plugin_sha}. The plugin did not make the SBOM."
    log "sha256 of the plugin jar is the value of CYCLONEDX_MAVEN_PLUGIN_SHA256"
    (
        cd "${pom_dir}"
        ./mvnw --batch-mode --file pom.xml "-Dmaven.repo.local=${repo_local}" "${goal}" \
            -DoutputFormat=json -DoutputName=bom -DschemaVersion=1.6
    )
    [[ -f "${pom_dir}/target/bom.json" ]] || die "Maven did not make ${pom_dir}/target/bom.json"
    cp "${pom_dir}/target/bom.json" "${out_dir}/backend.cdx.json"
    log "Wrote ${out_dir}/backend.cdx.json"
    sbom_plausible maven "${out_dir}/backend.cdx.json" "${maven_manifests[@]}"
    made=$((made + 1))
fi

# Frontend (pnpm)
if [[ ${node_scanned} -eq 1 ]]; then
    cdxgen_version="$(version_of CDXGEN_VERSION)"
    cdxgen_integrity="$(version_of CDXGEN_INTEGRITY)"
    require_cmd pnpm
    log "Frontend: frontend/, @cyclonedx/cdxgen ${cdxgen_version}"
    # G2: the integrity value of the npm package must be the pinned one before pnpm dlx starts it.
    registry_integrity="$(pnpm view "@cyclonedx/cdxgen@${cdxgen_version}" dist.integrity | tail -n 1 | tr -d '[:space:]')" \
        || die "pnpm view could not read the integrity value of @cyclonedx/cdxgen@${cdxgen_version}"
    [[ "${registry_integrity}" == "${cdxgen_integrity}" ]] \
        || die "The integrity value of @cyclonedx/cdxgen@${cdxgen_version} is '${registry_integrity}', but CDXGEN_INTEGRITY in ${VERSIONS_FILE} is '${cdxgen_integrity}'. cdxgen did not start."
    log "integrity of @cyclonedx/cdxgen@${cdxgen_version} is the value of CDXGEN_INTEGRITY"
    pnpm dlx "@cyclonedx/cdxgen@${cdxgen_version}" \
        --type js --spec-version 1.6 --profile license-compliance --fail-on-error \
        --output "${out_dir}/frontend.cdx.json" frontend
    [[ -f "${out_dir}/frontend.cdx.json" ]] || die "cdxgen did not make ${out_dir}/frontend.cdx.json"
    log "Wrote ${out_dir}/frontend.cdx.json"
    if [[ ${#node_manifests[@]} -gt 0 ]]; then # a lock file with no package.json declares nothing
        sbom_plausible node "${out_dir}/frontend.cdx.json" "${node_manifests[@]}"
    fi
    made=$((made + 1))
fi

# No manifest: a valid SBOM with no component.
if [[ ${made} -eq 0 ]]; then
    log "No pom.xml, no frontend/package.json and no frontend/pnpm-lock.yaml. Nothing to scan (and no manifest outside the scanned set)."
    log "Write an SBOM with no component (feat-6-contracts-openapi-pipeline adds the manifests)."
    serial="$(cat /proc/sys/kernel/random/uuid 2>/dev/null || echo 00000000-0000-4000-8000-000000000000)"
    timestamp="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    cat >"${out_dir}/project.cdx.json" <<JSON
{
  "bomFormat": "CycloneDX",
  "specVersion": "1.6",
  "serialNumber": "urn:uuid:${serial}",
  "version": 1,
  "metadata": {
    "timestamp": "${timestamp}",
    "component": {
      "type": "application",
      "name": "biz.dfch.SpecMgrDemo"
    }
  },
  "components": []
}
JSON
    log "Wrote ${out_dir}/project.cdx.json"
fi
log "PASS"
