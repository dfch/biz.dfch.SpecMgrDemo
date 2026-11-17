#!/usr/bin/env bash
# Task 120.110 (ACC-003): run the rules that come from the model against the code. The run is in a copy (build/work).
# Usage: 120-110-00-run-rules.sh [--generate]   --generate: validate the model and make the rules again first
source "$(dirname "${BASH_SOURCE[0]}")/_common.sh"
need node; need pnpm; need rsync

if [[ "${1:-}" == "--generate" ]]; then
    "${BIN_DIR}/100-110-00-validate-model.sh"
    node "${BIN_DIR}/120-100-00-generate-rules.mjs"
fi
[[ -s "${FEAT_DIR}/generated/ModelRulesTest.java" ]] || die "No generated rules. Run with --generate."
prepare_work
install_rules

log "Backend: ArchUnit, rules from the model"
out="$(run_backend_rules)" && code=0 || code=$?
echo "${out}" | grep -E "Tests run:|BUILD|ERROR" | tail -5
[[ ${code} -eq 0 ]] || { echo "${out}" | tail -40; die "The backend rules failed."; }

log "Frontend: ArchUniTS, rules from the model"
out="$(run_frontend_rules)" && code=0 || code=$?
echo "${out}" | tail -4
[[ ${code} -eq 0 ]] || { echo "${out}" | grep -E "FAIL|\|" | head -20; die "The frontend rules failed."; }
log "PASS the code obeys the rules of the model"
