#!/usr/bin/env bash
# Task 110.100 (ACC-002): export the model as a static site (index.html), as SVG images of the views, and as PlantUML.
# Output (not in git): build/model-site/ (index.html), build/svg/*.svg, build/plantuml/*.puml
# The SVG export of Structurizr needs a running page: the script starts `structurizr local` (the playwright image) for the
# export and stops it at the end. If the SVG export fails, the PlantUML files are the fallback (see the message).
# Usage: 110-100-00-export-model.sh
source "$(dirname "${BASH_SOURCE[0]}")/_common.sh"
need docker; need curl

NAME="demoprep-structurizr-local"
PORT="${STRUCTURIZR_LOCAL_PORT:-9799}"
cleanup() { docker rm -f "${NAME}" >/dev/null 2>&1 || true; }
trap cleanup EXIT

rm -rf "${BUILD}/model-site" "${BUILD}/svg" "${BUILD}/plantuml" "${BUILD}/local"
mkdir -p "${BUILD}/local"

log "Static site -> ${BUILD}/model-site"
structurizr export -w /w/workspace.dsl -f static -o /o/model-site >/dev/null
[[ -s "${BUILD}/model-site/index.html" ]] || die "No index.html was exported."

log "PlantUML -> ${BUILD}/plantuml"
structurizr export -w /w/workspace.dsl -f plantuml -o /o/plantuml >/dev/null

log "SVG -> ${BUILD}/svg (starts structurizr local on 127.0.0.1:${PORT})"
cp "${MODEL_DIR}/workspace.dsl" "${BUILD}/local/workspace.dsl"
cleanup
docker run -d --rm --name "${NAME}" -u "${DOCKER_USER}" -p "127.0.0.1:${PORT}:8080" \
    -v "${BUILD}/local:/usr/local/structurizr" "${STRUCTURIZR_PLAYWRIGHT_IMAGE}" local >/dev/null
wait_for_url "http://127.0.0.1:${PORT}/workspace/1/diagrams" 90 || die "structurizr local did not start (docker logs ${NAME})."
mkdir -p "${BUILD}/svg"
if docker run --rm --network host -u "${DOCKER_USER}" -v "${BUILD}/svg:/o" "${STRUCTURIZR_PLAYWRIGHT_IMAGE}" \
    export -f svg -url "http://127.0.0.1:${PORT}/workspace/1/diagrams" -o /o >"${BUILD}/svg-export.log" 2>&1 \
    && ls "${BUILD}"/svg/*.svg >/dev/null 2>&1; then
    log "PASS $(ls "${BUILD}"/svg/*.svg | wc -l) SVG file(s) in ${BUILD}/svg"
else
    log "WARNING: the SVG export failed (see ${BUILD}/svg-export.log). Fallback: the PlantUML files in ${BUILD}/plantuml"
    log "         (render them with a PlantUML server, for example the one on port 9898 of /home/user/docker/structurizr)."
    exit 1
fi
log "PASS static site: ${BUILD}/model-site/index.html"
