#!/usr/bin/env bash
# Task 130.110: stop the processes of 130-100-00-run-demo.sh, 130-120-00-serve-api-docs.sh and 130-130-00-serve-model-site.sh.
# Usage: 130-110-00-stop-demo.sh
source "$(dirname "${BASH_SOURCE[0]}")/_common.sh"
RUN="${BUILD}/run"
for name in backend frontend api-docs model-site; do
    pidfile="${RUN}/${name}.pid"
    [[ -f "${pidfile}" ]] || continue
    pid="$(cat "${pidfile}")"
    if kill -0 "${pid}" 2>/dev/null; then
        kill -- "-${pid}" 2>/dev/null || kill "${pid}" 2>/dev/null || true   # the process group (setsid)
        log "Stopped ${name} (${pid})"
    fi
    rm -f "${pidfile}"
done
