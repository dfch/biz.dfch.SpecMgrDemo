#!/usr/bin/env bash
# Task 170.100 (ACC-009, REQ-007): the head-less Playwright test, no agent.
# It starts the demo, reads the version from the page, compares it with GET /info, and stops the demo.
# The exit code is 0 only if the version on the page is the version of GET /info.
# Usage: 170-100-00-playwright-headless.sh
source "$(dirname "${BASH_SOURCE[0]}")/_common.sh"
need node; need curl
trap '"${BIN_DIR}/130-110-00-stop-demo.sh" >/dev/null 2>&1 || true' EXIT

"${BIN_DIR}/130-100-00-run-demo.sh"
PW="${WORK}/frontend/node_modules/@playwright/test"
[[ -d "${PW}" ]] || die "No @playwright/test in the copy."
rc=0
node "${BIN_DIR}/170-100-00-playwright-headless.mjs" "${PW}" "http://127.0.0.1:${FRONTEND_PORT}/" "http://127.0.0.1:${BACKEND_PORT}/info" || rc=$?

"${BIN_DIR}/130-110-00-stop-demo.sh"
trap - EXIT
sleep 1
for port in "${BACKEND_PORT}" "${FRONTEND_PORT}"; do
    if curl -fsS -o /dev/null "http://127.0.0.1:${port}/" 2>/dev/null; then die "Port ${port} is still in use after the stop."; fi
done
if [[ "${rc}" -eq 0 ]]; then log "PASS the demo was stopped"; else log "FAIL exit code ${rc}"; fi
exit "${rc}"
