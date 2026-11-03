#!/usr/bin/env bash
# feat-5-foundation-monorepo-ci, Task 130.130 (REQ-006, ACC-010)
#
# Makes the SBOM files (CycloneDX, JSON) of the project.
#
# Usage: sbom.sh <dir>
#   <dir>  the folder for the SBOM files, for example build/sbom. The script deletes the
#          *.json files in it first, so that no old file stays.
#
# What the script makes:
#   backend   if pom.xml (or backend/pom.xml) exists: Maven with the plugin
#             org.cyclonedx:cyclonedx-maven-plugin (goal makeAggregateBom). The file is
#             <dir>/backend.cdx.json. The version is CYCLONEDX_MAVEN_PLUGIN_VERSION.
#   frontend  if frontend/package.json or frontend/pnpm-lock.yaml exists: `pnpm dlx` with
#             @cyclonedx/cdxgen. The file is <dir>/frontend.cdx.json. The version is
#             CDXGEN_VERSION.
#   none      if no manifest exists (this is the case until feat-6-contracts-openapi-pipeline adds
#             them): a valid SBOM with `components: []`, in <dir>/project.cdx.json. The script says so.
#
# The versions are in tools/versions.env. The script does not change the system. The test with
# real dependencies is open until feat-6 gives the manifests. The environment variable
# SBOM_PROJECT_ROOT sets another root of the project (it is for the tests).

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/_lib.sh"

[[ $# -eq 1 ]] || die "Usage: sbom.sh <dir>"
out_dir="$1"
project_root="${SBOM_PROJECT_ROOT:-${REPO_ROOT}}"

cd "${project_root}"
mkdir -p "${out_dir}"
out_dir="$(cd "${out_dir}" && pwd)"
rm -f "${out_dir}"/*.json

made=0

# Backend (Maven)
pom=""
if [[ -f pom.xml ]]; then
    pom="pom.xml"
elif [[ -f backend/pom.xml ]]; then
    pom="backend/pom.xml"
fi
if [[ -n "${pom}" ]]; then
    plugin_version="$(version_of CYCLONEDX_MAVEN_PLUGIN_VERSION)"
    maven="mvn"
    [[ -x "$(dirname "${pom}")/mvnw" ]] && maven="$(cd "$(dirname "${pom}")" && pwd)/mvnw"
    [[ "${maven}" == "mvn" ]] && require_cmd mvn
    pom_dir="$(cd "$(dirname "${pom}")" && pwd)"
    log "Backend: ${pom}, cyclonedx-maven-plugin ${plugin_version}"
    rm -f "${pom_dir}/target/bom.json" # no old file can pass for the new one
    (
        cd "${pom_dir}"
        "${maven}" --batch-mode --file pom.xml \
            "org.cyclonedx:cyclonedx-maven-plugin:${plugin_version}:makeAggregateBom" \
            -DoutputFormat=json -DoutputName=bom -DschemaVersion=1.6
    )
    [[ -f "${pom_dir}/target/bom.json" ]] || die "Maven did not make ${pom_dir}/target/bom.json"
    cp "${pom_dir}/target/bom.json" "${out_dir}/backend.cdx.json"
    log "Wrote ${out_dir}/backend.cdx.json"
    made=$((made + 1))
fi

# Frontend (pnpm)
if [[ -f frontend/package.json || -f frontend/pnpm-lock.yaml ]]; then
    cdxgen_version="$(version_of CDXGEN_VERSION)"
    require_cmd pnpm
    log "Frontend: frontend/, @cyclonedx/cdxgen ${cdxgen_version}"
    pnpm dlx "@cyclonedx/cdxgen@${cdxgen_version}" \
        --type js --spec-version 1.6 --profile license-compliance --fail-on-error \
        --output "${out_dir}/frontend.cdx.json" frontend
    [[ -f "${out_dir}/frontend.cdx.json" ]] || die "cdxgen did not make ${out_dir}/frontend.cdx.json"
    log "Wrote ${out_dir}/frontend.cdx.json"
    made=$((made + 1))
fi

# No manifest: a valid SBOM with no component.
if [[ ${made} -eq 0 ]]; then
    log "No pom.xml, no frontend/package.json and no frontend/pnpm-lock.yaml. Nothing to scan."
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
