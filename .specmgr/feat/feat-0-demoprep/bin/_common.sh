#!/usr/bin/env bash
# Shared helpers of the demo scripts (feat-0-demoprep). Source this file; do not run it.
# Naming of the scripts: <phase>-<task>-<nn>-<name>.sh (the form of feat-20 of biz.dfch.LlmOps).

set -euo pipefail

BIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FEAT_DIR="$(cd "${BIN_DIR}/.." && pwd)"
REPO="$(cd "${FEAT_DIR}/../../.." && pwd)"
BUILD="${FEAT_DIR}/build"           # not in git (see .gitignore of the feature folder)
MODEL_DIR="${FEAT_DIR}/model"
STRUCTURIZR_IMAGE="${STRUCTURIZR_IMAGE:-structurizr/structurizr:2026.10.26-noble}"
STRUCTURIZR_PLAYWRIGHT_IMAGE="${STRUCTURIZR_PLAYWRIGHT_IMAGE:-structurizr/structurizr:2026.10.26-playwright}"
# Fixed ports of the demo (loopback only).
BACKEND_PORT="${BACKEND_PORT:-8180}"
FRONTEND_PORT="${FRONTEND_PORT:-5273}"
API_DOCS_PORT="${API_DOCS_PORT:-8091}"
MODEL_SITE_PORT="${MODEL_SITE_PORT:-8092}"

# Rootless Docker maps the host user to root inside the container, so "-u <host uid>" would write as another user (found on nxt).
if [[ -z "${DOCKER_USER:-}" ]]; then
    if docker info --format '{{.SecurityOptions}}' 2>/dev/null | grep -q rootless; then DOCKER_USER="0:0"; else DOCKER_USER="$(id -u):$(id -g)"; fi
fi

log() { printf '[%s] %s\n' "$(basename "$0")" "$*" >&2; }
die() { log "ERROR: $*"; exit 1; }
need() { command -v "$1" >/dev/null 2>&1 || die "The command '$1' is not installed."; }

wait_for_url() { # <url> <seconds>
    local url="$1" n="${2:-60}" i
    for ((i = 0; i < n; i++)); do
        curl -fsS -o /dev/null "${url}" 2>/dev/null && return 0
        sleep 1
    done
    return 1
}

structurizr() { # structurizr <args>: the image runs as the current user, the model folder is /w, the build folder is /o
    mkdir -p "${BUILD}"
    docker run --rm -u "${DOCKER_USER}" -v "${MODEL_DIR}:/w:ro" -v "${BUILD}:/o" "${STRUCTURIZR_IMAGE}" "$@"
}

# The rules run in a COPY of backend/ and frontend/ in build/work, so no file of the code folders changes.
WORK="${BUILD}/work"
JAVA_TEST_DIR="${WORK}/backend/src/test/java/biz/dfch/specmgrdemo/architecture"

prepare_work() { # copy the code (not node_modules, target) and install the frontend dependencies once
    mkdir -p "${WORK}"
    rsync -a --delete --exclude node_modules --exclude target --exclude dist --exclude mutation-report --exclude test-results \
        "${REPO}/backend/" "${WORK}/backend/"
    rsync -a --delete --exclude node_modules --exclude dist --exclude mutation-report --exclude test-results \
        "${REPO}/frontend/" "${WORK}/frontend/"
    if [[ ! -d "${WORK}/frontend/node_modules/archunit" ]]; then
        log "Install the frontend dependencies in the copy (pnpm install --frozen-lockfile --ignore-scripts)"
        (cd "${WORK}/frontend" && pnpm install --frozen-lockfile --ignore-scripts) >&2
    fi
}
install_rules() {
    cp "${FEAT_DIR}/generated/ModelRulesTest.java" "${JAVA_TEST_DIR}/ModelRulesTest.java"
    cp "${FEAT_DIR}/generated/rules.model.mjs" "${WORK}/frontend/architecture/rules.model.mjs"
}
run_backend_rules() { (cd "${WORK}/backend" && ./mvnw --batch-mode --no-transfer-progress test -Dcodegen.skip=true -Dtest=ModelRulesTest 2>&1); }
run_frontend_rules() { (cd "${WORK}/frontend" && node architecture/rules.model.mjs "$(pwd)" 2>&1); }
