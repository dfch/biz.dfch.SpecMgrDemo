#!/usr/bin/env bash
# feat-5-foundation-monorepo-ci, Task 130.130 (REQ-006, ACC-010) and the findings E1, G1 and G2 of the review
# feat-16-cdxgen-lockfile, Tasks 100.110 and 100.120 (REQ-002, REQ-004): cdxgen runs from a lock file
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
#             cdxgen (see rule G2) makes <dir>/frontend.cdx.json. A package.json below frontend/
#             is covered only if frontend/pnpm-workspace.yaml and frontend/pnpm-lock.yaml both exist
#             (cdxgen reads the workspace from the lock file; a nested package.json with no
#             workspace is not read).
#   none      if no manifest exists (this was the case until feat-6-contracts-openapi-pipeline added
#             them): a valid SBOM with `components: []`, in <dir>/project.cdx.json. The script says so.
#
# Rules (fail closed):
#   E1a  Any pom.xml, package.json, pnpm-lock.yaml or pnpm-workspace.yaml in the repository that is NOT in
#        the set above stops the script (exit code 1) with its path. For example a package.json in the
#        root or in contracts/, a pom.xml in model/ or in backend/ when no pom.xml scans backend. The
#        script does not enter .git, node_modules, build and target (at each level), and, from the
#        root only, .specmgr (the folders of the features keep prototypes that are not part of the
#        layout), tools/license/fixtures and tools/gates/fixtures.
#        Exclusion (feat-16-cdxgen-lockfile): the two files tools/sbom/package.json and
#        tools/sbom/pnpm-lock.yaml are NOT manifests of the project. They are the lock file of the tool
#        cdxgen (rule A: cdxgen does not go to users), and the script does not scan them. The exclusion is
#        for these two paths and not for the folder: tools/sbom/pnpm-workspace.yaml, a package.json in a
#        sub-folder of tools/sbom/, and each manifest in another folder of tools/ still stop the script.
#        The same is for the linter (feat-6-contracts-openapi-pipeline, Task 110.110): the two files
#        tools/spectral/package.json and tools/spectral/pnpm-lock.yaml are the lock file of Spectral (rule A),
#        and the script does not scan them. The tree of Spectral has packages with the license Unlicense, which
#        is not in the DEC, so it must not be in the SBOM. just check-pins checks the lock file.
#   E1b  If a scanned package.json has an entry in dependencies, devDependencies, optionalDependencies or
#        peerDependencies (or a scanned pom.xml has a <dependency> in <dependencies>) and the SBOM that the
#        tool made has no component, the script stops. sbom_check.py does this check (it reads
#        the manifests and counts the components of the SBOM file, with the Python of `uv run`).
#        One case is not an error (feat-6-contracts-openapi-pipeline, Task 105.110): for a pom.xml with no
#        <dependency>, cyclonedx-maven-plugin 2.9.3 writes an SBOM with no `components` key, and license_check.py
#        stops for that. Then sbom_check.py writes `"components": []` to <dir>/backend.cdx.json (the file in
#        target/ stays as the plugin made it). With a declared dependency, the same SBOM stops the script.
#   G1   A Maven project must have the Maven Wrapper (mvnw) next to the scanned pom.xml. The script
#        starts mvnw, and never the Maven of the machine or of the runner, so that Maven is the version that
#        the wrapper pins (check-pins.sh checks that this version is MAVEN_VERSION). No mvnw stops the script.
#   G2   Before the real run, the script starts the plugin with -Dcyclonedx.skip=true (it loads the plugin
#        and does nothing), and compares the sha256 of the plugin jar in the local Maven repository with
#        CYCLONEDX_MAVEN_PLUGIN_SHA256. The dependencies of the plugin are NOT checked.
#        For cdxgen (feat-16-cdxgen-lockfile), the script installs the tool from the lock file in
#        tools/sbom/ with `pnpm install --frozen-lockfile --ignore-scripts`, and starts
#        tools/sbom/node_modules/.bin/cdxgen (with absolute paths). pnpm compares the integrity value of
#        each package (cdxgen and all its dependencies) with the lock file. The script stops (exit code 1,
#        no SBOM file) if the install fails (for example if the lock file and package.json differ, or a
#        package has another integrity value), if the lock file or package.json is missing, or if the
#        installed cdxgen has another version than CDXGEN_VERSION. The script does not use the commands
#        dlx and view of pnpm. `just check-pins` ties package.json and the lock file to CDXGEN_VERSION and
#        CDXGEN_INTEGRITY of tools/versions.env (check_pins.py, check_sbom_tool). Limit: a wrong integrity
#        value of an OPTIONAL dependency of cdxgen does not stop the install: pnpm logs the error, does not
#        install that package (it does not run), and returns exit code 0. A required package stops it.
#        If no Node manifest is scanned, the script does not install (no network is necessary).
#   X1   The exclusion of axe-core from the FRONTEND SBOM only (feat-7-verification-architecture-tools,
#        Phase 110, Task 110.120): the accessibility check of the end-to-end test uses the package
#        axe-core (a devDependency of frontend/), and its license MPL-2.0 is not in
#        tools/license/permitted-licenses.txt. The owner approved the use of the tool with the deviation
#        DEC 93a6d588-e002-4daf-9a47-45e2d77786e9 (accepted 2026-11-09). The tool does not go to users
#        (rule A of DEC 84c37f7d-08cb-457d-8ab3-1db37dba9bc9), so its license is checked in the plan of
#        the feature (the license table) and the package must not reach the SBOM. cdxgen 12.9.0 has no
#        package filter for a pnpm lock file (its `--exclude` option is a file path pattern), so after
#        cdxgen made the file, the script starts sbom_exclude.py with the name `axe-core` and the version
#        of tools/versions.env (AXE_CORE_VERSION): the components of the pinned package are removed from
#        the SBOM, and a component with another version is NOT removed (fail closed: the license gate
#        stops for it). The removal is logged. See tools/sbom/README.md (the section The exclusion of
#        axe-core) and the plan of feat-7 (the Result of the Phase 110).
#
# The versions and the checksums are in tools/versions.env (VERSIONS_FILE sets another file, for the
# tests). The script does not change the system, except for the folder tools/sbom/node_modules (it is
# in .gitignore). The first run with the real backend/pom.xml (no dependency) is done (feat-6 Task 105.110). These
# environment variables are for the tests:
#   SBOM_PROJECT_ROOT       another root of the project
#   SBOM_TOOL_DIR           another folder for the cdxgen project (the default is tools/sbom of this
#                           repository, and not of SBOM_PROJECT_ROOT: the tool belongs to the gates)
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
    die "${#unscanned[@]} manifest(s) are outside the set that this script scans, so their licenses would not be checked. Scanned: pom.xml or backend/pom.xml (and the poms below backend/), frontend/package.json, frontend/pnpm-lock.yaml and frontend/pnpm-workspace.yaml (and, with a workspace and a lock file, the package.json files below frontend/). Move the manifest, or change this script (and its tests) first. Not scanned: tools/sbom/package.json and tools/sbom/pnpm-lock.yaml (the lock file of cdxgen), and tools/spectral/package.json and tools/spectral/pnpm-lock.yaml (the lock file of Spectral). Not entered: .git, node_modules, build, target, .specmgr, tools/license/fixtures, tools/gates/fixtures."
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
    require_cmd pnpm
    require_cmd uv
    tool_dir="${SBOM_TOOL_DIR:-${REPO_ROOT}/tools/sbom}"
    [[ -d "${tool_dir}" ]] || die "The folder of the cdxgen project does not exist: ${tool_dir}"
    tool_dir="$(cd "${tool_dir}" && pwd)"
    for tool_file in package.json pnpm-lock.yaml; do
        [[ -f "${tool_dir}/${tool_file}" ]] || die "${tool_dir}/${tool_file} does not exist. cdxgen must run from a lock file. cdxgen did not start."
    done
    log "Frontend: frontend/, @cyclonedx/cdxgen ${cdxgen_version}"
    # G2: install cdxgen from the lock file. pnpm checks the integrity value of each package against it,
    # and stops if the lock file and package.json are not the same. No script of a package runs.
    log "Install: pnpm install --frozen-lockfile --ignore-scripts in ${tool_dir}"
    (cd "${tool_dir}" && pnpm install --frozen-lockfile --ignore-scripts) \
        || die "pnpm install --frozen-lockfile --ignore-scripts failed in ${tool_dir} (see above). cdxgen did not start."
    cdxgen_bin="${tool_dir}/node_modules/.bin/cdxgen"
    [[ -x "${cdxgen_bin}" ]] || die "${cdxgen_bin} does not exist after the install. cdxgen did not start."
    # The lock file can have another version than the pin (just check-pins also finds this).
    cdxgen_installed="$(uv run --no-project --quiet python -c \
        'import json, sys; print(json.load(open(sys.argv[1], encoding="utf-8"))["version"])' \
        "${tool_dir}/node_modules/@cyclonedx/cdxgen/package.json")" \
        || die "Cannot read the version of the installed cdxgen in ${tool_dir}/node_modules/@cyclonedx/cdxgen/package.json"
    [[ "${cdxgen_installed}" == "${cdxgen_version}" ]] \
        || die "The installed @cyclonedx/cdxgen has the version '${cdxgen_installed}', but CDXGEN_VERSION in ${VERSIONS_FILE} is '${cdxgen_version}'. cdxgen did not start."
    log "The installed @cyclonedx/cdxgen has the version ${cdxgen_installed} (CDXGEN_VERSION)"
    # Absolute paths: the folder of the script is the root of the project, and cdxgen must not depend on it.
    "${cdxgen_bin}" \
        --type js --spec-version 1.6 --profile license-compliance --fail-on-error \
        --output "${out_dir}/frontend.cdx.json" "$(cd frontend && pwd)"
    [[ -f "${out_dir}/frontend.cdx.json" ]] || die "cdxgen did not make ${out_dir}/frontend.cdx.json"
    log "Wrote ${out_dir}/frontend.cdx.json"
    # X1: the exclusion of axe-core (the rule is in the header, the reason in tools/sbom/README.md).
    # cdxgen has no package filter for a pnpm lock file, so the gate removes the pinned package itself.
    axe_core_version="$(version_of AXE_CORE_VERSION)"
    uv run --no-project --quiet python "${GATES_DIR}/sbom_exclude.py" \
        "${out_dir}/frontend.cdx.json" "axe-core" "${axe_core_version}" \
        || die "The exclusion of axe-core ${axe_core_version} from the frontend SBOM did not run (see above)."
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
