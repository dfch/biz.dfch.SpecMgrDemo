#!/usr/bin/env bash
# Task 140.100 (ACC-006): make the images in images/ (committed): the screenshots of the user interface (state up, German, error),
# of the API documentation and of the model site, and the SVG of the views (Structurizr).
# It starts and stops the demo itself. Needs the Chromium of Playwright in ~/.cache/ms-playwright (the frontend of the copy has the package).
# Usage: 140-100-00-take-screenshots.sh
source "$(dirname "${BASH_SOURCE[0]}")/_common.sh"
need node; need pnpm
IMG="${FEAT_DIR}/images"; mkdir -p "${IMG}"
trap '"${BIN_DIR}/130-110-00-stop-demo.sh" >/dev/null 2>&1 || true' EXIT

# the model: site, SVG
"${BIN_DIR}/110-100-00-export-model.sh"
cp "${BUILD}"/svg/*.svg "${IMG}/" && for f in "${IMG}"/*-key.svg; do mv "$f" "${IMG}/key-$(basename "${f%-key.svg}").svg"; done
for v in Context Containers Backend Frontend; do mv -f "${IMG}/${v}.svg" "${IMG}/model-${v}.svg"; done

"${BIN_DIR}/130-100-00-run-demo.sh"
PW="${WORK}/frontend/node_modules/@playwright/test"
[[ -d "${PW}" ]] || die "No @playwright/test in the copy."
shot() { node "${BIN_DIR}/140-100-01-shot.mjs" "${PW}" "$@"; }
shot "http://127.0.0.1:${FRONTEND_PORT}/" "${IMG}/ui-up-en.png" --width 820 --height 330
shot "http://127.0.0.1:${FRONTEND_PORT}/" "${IMG}/ui-up-de.png" --lang de --width 820 --height 330
"${BIN_DIR}/130-100-00-run-demo.sh" --fail
shot "http://127.0.0.1:${FRONTEND_PORT}/" "${IMG}/ui-error-en.png" --width 820 --height 330
"${BIN_DIR}/130-110-00-stop-demo.sh"

"${BIN_DIR}/130-120-00-serve-api-docs.sh"
shot "http://127.0.0.1:${API_DOCS_PORT}/index.html" "${IMG}/api-docs.png" --height 560
"${BIN_DIR}/130-130-00-serve-model-site.sh"
shot "http://127.0.0.1:${MODEL_SITE_PORT}/index.html" "${IMG}/model-site.png"
log "PASS $(ls "${IMG}" | wc -l) file(s) in ${IMG}"
