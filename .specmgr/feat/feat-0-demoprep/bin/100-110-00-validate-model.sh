#!/usr/bin/env bash
# Task 100.110 (ACC-001): validate model/workspace.dsl, export the JSON, compare it with model/workspace.json of the repository.
# Usage: 100-110-00-validate-model.sh
source "$(dirname "${BASH_SOURCE[0]}")/_common.sh"
need docker; need python3

log "Validate ${MODEL_DIR}/workspace.dsl"
structurizr validate -w /w/workspace.dsl
log "Export the JSON"
rm -rf "${BUILD}/json"
structurizr export -w /w/workspace.dsl -f json -o /o/json >/dev/null
[[ -s "${BUILD}/json/workspace.json" ]] || die "No JSON was exported."
log "Compare with ${REPO}/model/workspace.json"
python3 "${BIN_DIR}/100-110-01-compare-model.py" "${BUILD}/json/workspace.json" "${REPO}/model/workspace.json"
