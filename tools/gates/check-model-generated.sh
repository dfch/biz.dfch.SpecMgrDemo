#!/usr/bin/env bash
# feat-50-structurizr-model-rules, Task 110.120 (REQ-003, ACC-004; DEC b6e8808f-86b4-41a4-92f2-33d38869beed)
#
# Gate: the JSON of the model is generated, and it is up to date with the DSL (like check-generated).
#
# Usage: check-model-generated.sh <model dir>
#   <model dir>   the folder with workspace.dsl and workspace.json, for example model
#
# What the script does:
#   1. The same pin check as generate-model.sh (docker on PATH, the digest of tools/versions.env, the
#      image of the digest local or pulled).
#   2. It stops (exit code 1) if the DSL does not parse: the container `validate -w workspace.dsl`
#      (the command exits with code 1, and the error names the line).
#   3. It makes the JSON again from the DSL in a temporary folder, twice (run 1 and run 2; the file of
#      the repository is never changed), and stops if the two runs are not the same (the idempotence of
#      the tool, ACC-004).
#   4. It stops (exit code 1) if the result differs from <model dir>/workspace.json (the committed
#      file). The message names the difference (the diff from the committed file to the new generation).
#   5. It stops (exit code 1) if the committed file carries another value for the top-level property
#      structurizr.inspection.error than the recorded value 29 (the stable consequence of the limit of
#      the pinned exporter for the deployment content and of the state of the model (the record is in
#      model/README.md and in the Updates entry of DEC b6e8808f-86b4-41a4-92f2-33d38869beed)). The
#      message names the expected and the found value.
#
# The flow on a developer machine is: change model/workspace.dsl, `just generate-model`, `git add`,
# `git commit`, `just check-model-generated`. A change of the model or of the tool that changes the
# count of the inspection is recorded in the same change in model/README.md and in the Updates entry
# of DEC b6e8808f-86b4-41a4-92f2-33d38869beed (the recorded value above stays in sync with both).
#
# Exit codes: 0 pass, 1 the gate stops (a DSL that does not parse, a JSON that is not up to date, two
# runs that differ, a count of the inspection that is not the recorded value, a pin that does not
# name an image, or docker that is missing).
# Needs docker (and the network for the first pull, if the image is not local). The script changes no
# file of the repository.

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/_lib.sh"

[[ $# -eq 1 ]] || die "Usage: check-model-generated.sh <model dir>"
model_dir="$1"
[[ -d "${model_dir}" ]] || die "The model folder does not exist: ${model_dir}"
model_dir="$(cd "${model_dir}" && pwd)"
[[ -f "${model_dir}/workspace.dsl" ]] || die "${model_dir}/workspace.dsl does not exist (the DSL is the source of the model)."
[[ -f "${model_dir}/workspace.json" ]] \
    || die "${model_dir}/workspace.json does not exist. The JSON is committed to git (run \`just generate-model\` and commit the file)."
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

stop() { echo "[$(basename "${0}")] STOP: $*" >&2; }

# --- 2. The DSL parses -------------------------------------------------------------------------------------
log "Validate the DSL (the container validate, the error names the line of a DSL that does not parse)"
if ! docker run --rm -v "${model_dir}:/src:ro" -w /src "${reference}" validate -w workspace.dsl; then
    stop "the DSL does not parse (the container validate stopped, the error above names the line). Fix model/workspace.dsl."
    echo "RESULT: STOP. The DSL of the model does not parse." >&2
    exit 1
fi

# --- 3. Two runs of the generation (the idempotence, ACC-004) ------------------------------------------------
work1="$(mktemp -d)"
work2="$(mktemp -d)"
mkdir -p "${work1}/out" "${work2}/out"
trap 'rm -rf "${work1}" "${work2}"' EXIT
log "Generate again (run 1, a temporary folder; the repository file is never changed)"
docker run --rm -v "${model_dir}:/src:ro" -v "${work1}/out:/out" -w /src "${reference}" export -w workspace.dsl -f json -o /out \
    || die "the export of the container failed (run 1; the error above is the message of the container)."
[[ -s "${work1}/out/workspace.json" ]] || die "the export made no file (run 1)."
log "Generate again (run 2, a temporary folder)"
docker run --rm -v "${model_dir}:/src:ro" -v "${work2}/out:/out" -w /src "${reference}" export -w workspace.dsl -f json -o /out \
    || die "the export of the container failed (run 2; the error above is the message of the container)."
[[ -s "${work2}/out/workspace.json" ]] || die "the export made no file (run 2)."
if ! cmp -s "${work1}/out/workspace.json" "${work2}/out/workspace.json"; then
    stop "two runs of the generation make a different JSON (the idempotence of the tool is broken, ACC-004)"
    echo "RESULT: STOP. Two runs of the generation are not the same." >&2
    exit 1
fi
log "Two runs of the generation are the same (the idempotence, ACC-004)"

# --- 4. The result is the committed file ----------------------------------------------------------------------
if ! cmp -s "${work1}/out/workspace.json" "${model_dir}/workspace.json"; then
    stop "the JSON of the model is not the JSON that the DSL makes now (the committed file differs from the new generation):"
    diff -u "${model_dir}/workspace.json" "${work1}/out/workspace.json" | sed -e 's/^/    | /' | head -n 40 >&2 || true
    echo "     Run \`just generate-model\` and commit the result. Do not change model/workspace.json by hand (the DSL is the source, DEC b6e8808f-86b4-41a4-92f2-33d38869beed)." >&2
    echo "RESULT: STOP. The JSON of the model is not up to date with the DSL." >&2
    exit 1
fi
log "PASS. model/workspace.json is the JSON that the pinned container makes from model/workspace.dsl now"

# --- 5. The committed file carries the recorded inspection state ----------------------------------------------
# The recorded value of the count of the inspection (the top-level property structurizr.inspection.error
# of the JSON): the stable consequence of the limit of the pinned exporter for the deployment content
# (the DSL names the two containments of the node host, and the exporter does not serialize them into
# the JSON) and of the state of the model (the components of the container backend and the node host
# are not on a view, and the relations of the model have no technology - the count of 29 is stable over
# two runs of the generation since the components of feat-9 joined the model in Task 120.110). The
# record is in model/README.md and in the Updates entry of DEC
# b6e8808f-86b4-41a4-92f2-33d38869beed. A changed count (a tool change or a model change that
# worsens or fixes the inspection) stops the gate, and the message names the expected and the found
# value (the form of the line is the stable two-space form that the pinned exporter writes).
expected_inspection_error='29'
found_inspection_error="$(sed -n -E 's/^[[:space:]]*"structurizr\.inspection\.error" : "([0-9]+)".*/\1/p' "${model_dir}/workspace.json" | head -n 1)"
if [[ -z "${found_inspection_error}" ]]; then
    stop "the committed file has no top-level property structurizr.inspection.error in the recorded form (the property is written by the pinned exporter; the recorded value is ${expected_inspection_error}): the record is in model/README.md and in the Updates entry of DEC b6e8808f-86b4-41a4-92f2-33d38869beed"
    echo "RESULT: STOP. The committed JSON has no recorded count of the inspection." >&2
    exit 1
fi
if [[ "${found_inspection_error}" != "${expected_inspection_error}" ]]; then
    stop "the committed file has the top-level property structurizr.inspection.error with the value ${found_inspection_error}, and the recorded value is ${expected_inspection_error}: the record of the count is in model/README.md and in the Updates entry of DEC b6e8808f-86b4-41a4-92f2-33d38869beed (the limit of the pinned exporter for the deployment content)"
    echo "     If a change of the model or of the tool changes the count, record the new count in model/README.md and in the DEC in the same change (and change the recorded value of this script)." >&2
    echo "RESULT: STOP. The committed JSON has another count of the inspection than the recorded value." >&2
    exit 1
fi
log "PASS. model/workspace.json carries the recorded inspection state (the property structurizr.inspection.error has the value ${expected_inspection_error})"
