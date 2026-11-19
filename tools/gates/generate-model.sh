#!/usr/bin/env bash
# feat-50-structurizr-model-rules, Task 110.110 (REQ-003, ACC-004; DEC b6e8808f-86b4-41a4-92f2-33d38869beed)
#
# Make model/workspace.json again from model/workspace.dsl with the pinned container structurizr/structurizr.
# The DSL is the one file a person edits, and the JSON is the interchange that the two readers of the
# comparison and the gate consume (the file is committed to git). The step names the digest of the
# image (STRUCTURIZR_IMAGE_DIGEST of tools/versions.env), and not the tag.
#
# Usage: generate-model.sh <model dir>
#   <model dir>   the folder with workspace.dsl and workspace.json, for example model
#
# What the script does:
#   1. It stops (exit code 1) if docker is not on PATH, or if <model dir>/workspace.dsl does not exist.
#   2. It reads STRUCTURIZR_IMAGE and STRUCTURIZR_IMAGE_DIGEST from tools/versions.env, and stops if the
#      digest is not a sha256 value (the pin is the source of truth for the tool, and not a tag).
#   3. It stops if the image of the digest is not local, and docker cannot pull it (the pull names the
#      digest, so a moved tag of the image gives no other content).
#   4. It runs the container `export -w workspace.dsl -f json -o <folder>` with the folder in a temporary
#      place (the output file is the input file name minus the part .dsl, in the folder), and stops if
#      the export fails, or writes no file.
#   5. It copies the result to <model dir>/workspace.json (the committed file), and logs PASS.
#
# Two runs of the script make no change (the idempotence, ACC-004): the exporter writes the base64 text
# of the source DSL, and the counts of the inspection, as the top-level properties of the JSON, and both
# are the same for the same DSL (verified in Phase 100).
#
# Needs docker (and the network for the first pull, if the image is not local). The script changes only
# <model dir>/workspace.json.

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/_lib.sh"

[[ $# -eq 1 ]] || die "Usage: generate-model.sh <model dir>"
model_dir="$1"
[[ -d "${model_dir}" ]] || die "The model folder does not exist: ${model_dir}"
model_dir="$(cd "${model_dir}" && pwd)"
[[ -f "${model_dir}/workspace.dsl" ]] \
    || die "${model_dir}/workspace.dsl does not exist (the DSL is the source of the model, DEC b6e8808f-86b4-41a4-92f2-33d38869beed)."
require_cmd docker

image="$(version_of STRUCTURIZR_IMAGE)"
digest="$(version_of STRUCTURIZR_IMAGE_DIGEST)"
[[ "${digest}" =~ ^sha256:[0-9a-f]{64}$ ]] || die "STRUCTURIZR_IMAGE_DIGEST is not a sha256 digest: '${digest}'"
reference="${image%%:*}@${digest}"
if ! docker image inspect "${reference}" >/dev/null 2>&1; then
    log "The image ${reference} is not local; pull it (the pull names the digest)"
    docker pull "${reference}" \
        || die "docker could not pull ${reference} (the digest does not name an image that the registry has, or the network is not available)."
fi

work="$(mktemp -d)"
out="${work}/out"
mkdir -p "${out}"
trap 'rm -rf "${work}"' EXIT
log "Make the JSON from the DSL (the container ${reference}, the command export -f json)"
docker run --rm -v "${model_dir}:/src:ro" -v "${out}:/out" -w /src "${reference}" export -w workspace.dsl -f json -o /out \
    || die "the export of the container failed (the DSL does not parse, or the export did not run; the error above is the message of the container)."
[[ -s "${out}/workspace.json" ]] || die "the export made no file in the output folder (the file workspace.json is missing)."
cp "${out}/workspace.json" "${model_dir}/workspace.json"
log "PASS. Wrote ${model_dir}/workspace.json from ${model_dir}/workspace.dsl (two runs make no change)"
