#!/usr/bin/env bash
# Task 130.100 (ACC-004): start the backend (port 8180) and the frontend (Vite, port 5273) in the background.
# The code runs from a copy in build/work. The logs and the PIDs are in build/run. Stop with 130-110-00-stop-demo.sh.
# Usage: 130-100-00-run-demo.sh [--fail]   --fail: the backend gives the error response (503 service_unavailable with a trace id)
source "$(dirname "${BASH_SOURCE[0]}")/_common.sh"
need java; need node; need pnpm; need rsync; need curl

RUN="${BUILD}/run"
"${BIN_DIR}/130-110-00-stop-demo.sh" >/dev/null 2>&1 || true
mkdir -p "${RUN}"
mode="up"; extra=()
if [[ "${1:-}" == "--fail" ]]; then mode="fail"; extra=("--app.state-checker=fail"); fi

prepare_work
log "Compile the backend and make the class path (Maven, no new plug-in)"
(cd "${WORK}/backend" && ./mvnw --batch-mode --no-transfer-progress -q compile -Dcodegen.skip=true "-Dbuild.info.commit=$(git -C "${REPO}" rev-parse HEAD)" \
    && ./mvnw --batch-mode --no-transfer-progress -q dependency:build-classpath -Dmdep.outputFile="${RUN}/classpath.txt") \
    >"${RUN}/maven.log" 2>&1 || { tail -30 "${RUN}/maven.log"; die "Maven failed (${RUN}/maven.log)."; }

log "Start the backend on :${BACKEND_PORT} (state checker: ${mode})"
(cd "${WORK}/backend" && exec setsid java -cp "target/classes:$(cat "${RUN}/classpath.txt")" \
    biz.dfch.specmgrdemo.app.SpecMgrDemoApplication --server.port="${BACKEND_PORT}" \
    --OTEL_EXPORTER_OTLP_ENDPOINT= --OTEL_EXPORTER_OTLP_TRACES_ENDPOINT= --OTEL_EXPORTER_OTLP_HEADERS= --OTEL_EXPORTER_OTLP_TRACES_HEADERS= \
    "${extra[@]}") >"${RUN}/backend.log" 2>&1 &
echo $! >"${RUN}/backend.pid"
wait_for_url "http://127.0.0.1:${BACKEND_PORT}/info" 60 || { tail -30 "${RUN}/backend.log"; die "The backend did not start (${RUN}/backend.log)."; }

log "Start the frontend on :${FRONTEND_PORT} (Vite)"
(cd "${WORK}/frontend" && SPECMGRDEMO_BACKEND_URL="http://127.0.0.1:${BACKEND_PORT}" exec setsid node_modules/.bin/vite --host 127.0.0.1 --port "${FRONTEND_PORT}" --strictPort) \
    >"${RUN}/frontend.log" 2>&1 &
echo $! >"${RUN}/frontend.pid"
wait_for_url "http://127.0.0.1:${FRONTEND_PORT}/" 60 || { tail -30 "${RUN}/frontend.log"; die "Vite did not start (${RUN}/frontend.log)."; }

log "PASS  open http://127.0.0.1:${FRONTEND_PORT}   (backend: http://127.0.0.1:${BACKEND_PORT}/status and /info)"
log "      stop: ${BIN_DIR}/130-110-00-stop-demo.sh"
