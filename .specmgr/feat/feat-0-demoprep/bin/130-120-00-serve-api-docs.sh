#!/usr/bin/env bash
# Task 130.120 (ACC-005): make the HTML of the API specification (contracts/openapi.yaml, generator html2 of the pinned plug-in)
# and serve it on http://127.0.0.1:8091 (in the background). The page loads a font from fonts.googleapis.com (finding F2 of
# feat-6): without a network it shows in a fallback font.
# The recipe `just api-docs` of the repository makes the same page in build/api-docs of the repository root. This script makes it
# in the copy (build/work) so the folders of the repository do not change.
# Usage: 130-120-00-serve-api-docs.sh
source "$(dirname "${BASH_SOURCE[0]}")/_common.sh"
need python3; need rsync; need curl
RUN="${BUILD}/run"; mkdir -p "${RUN}"
mkdir -p "${WORK}"
rsync -a --delete --exclude target "${REPO}/backend/" "${WORK}/backend/"
rsync -a --delete "${REPO}/contracts/" "${WORK}/contracts/"
rsync -a --delete "${REPO}/tools/" "${WORK}/tools/" --exclude node_modules
cp "${REPO}/tools/versions.env" "${WORK}/tools/versions.env"

log "Make the API documentation (just api-docs form, in the copy)"
(cd "${WORK}" && git -C "${REPO}" rev-parse HEAD >/dev/null && bash tools/gates/api-docs.sh backend "${BUILD}/api-docs") >"${RUN}/api-docs.log" 2>&1 \
    || { tail -30 "${RUN}/api-docs.log"; die "api-docs failed (${RUN}/api-docs.log)."; }

[[ -f "${RUN}/api-docs.pid" ]] && kill -- "-$(cat "${RUN}/api-docs.pid")" 2>/dev/null || true
(cd "${BUILD}/api-docs" && exec setsid python3 -m http.server "${API_DOCS_PORT}" --bind 127.0.0.1) >"${RUN}/api-docs-server.log" 2>&1 &
echo $! >"${RUN}/api-docs.pid"
wait_for_url "http://127.0.0.1:${API_DOCS_PORT}/index.html" 15 || die "The server did not start."
log "PASS  open http://127.0.0.1:${API_DOCS_PORT}/index.html"
