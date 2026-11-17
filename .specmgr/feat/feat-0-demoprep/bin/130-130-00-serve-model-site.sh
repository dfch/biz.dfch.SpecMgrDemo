#!/usr/bin/env bash
# Task 130.130 (ACC-005): serve the static site of the model (build/model-site) on http://127.0.0.1:8092 (in the background).
# Make it first with 110-100-00-export-model.sh (this script does it if the site is missing).
# Usage: 130-130-00-serve-model-site.sh
source "$(dirname "${BASH_SOURCE[0]}")/_common.sh"
need python3; need curl
RUN="${BUILD}/run"; mkdir -p "${RUN}"
[[ -s "${BUILD}/model-site/index.html" ]] || "${BIN_DIR}/110-100-00-export-model.sh"
[[ -f "${RUN}/model-site.pid" ]] && kill -- "-$(cat "${RUN}/model-site.pid")" 2>/dev/null || true
(cd "${BUILD}/model-site" && exec setsid python3 -m http.server "${MODEL_SITE_PORT}" --bind 127.0.0.1) >"${RUN}/model-site-server.log" 2>&1 &
echo $! >"${RUN}/model-site.pid"
wait_for_url "http://127.0.0.1:${MODEL_SITE_PORT}/index.html" 15 || die "The server did not start."
log "PASS  open http://127.0.0.1:${MODEL_SITE_PORT}/index.html"
