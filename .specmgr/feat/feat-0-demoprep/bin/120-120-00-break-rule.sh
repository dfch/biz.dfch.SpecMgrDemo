#!/usr/bin/env bash
# Task 120.120 (ACC-003): show that a rule of the model fails. The script adds two forbidden dependencies to the COPY in
# build/work (one in the backend, one in the frontend), runs the generated rules and shows the violations.
# The code folders of the repository are not changed.
# Usage: 120-120-00-break-rule.sh
source "$(dirname "${BASH_SOURCE[0]}")/_common.sh"
need node; need pnpm; need rsync
[[ -s "${FEAT_DIR}/generated/ModelRulesTest.java" ]] || die "No generated rules. Run 120-110-00-run-rules.sh --generate first."

prepare_work   # a fresh copy of the sources: no earlier violation is left
install_rules
cat > "${WORK}/backend/src/generated/java/biz/dfch/specmgrdemo/model/DemoViolation.java" <<'J'
package biz.dfch.specmgrdemo.model;

/** Demo only (feat-0-demoprep): the model must not depend on the api. */
final class DemoViolation {
  Class<?> forbidden = biz.dfch.specmgrdemo.api.StatusApi.class;
}
J
cat > "${WORK}/frontend/src/client/demoViolation.ts" <<'T'
// Demo only (feat-0-demoprep): the client must not depend on the ui.
import { App } from '../ui/App'
export const forbidden = App
T

log "Added to the copy: backend model -> api, frontend client -> ui (both are not in the model)"
log "Backend (the rule must fail):"
out="$(run_backend_rules)" && code=0 || code=$?
echo "${out}" | grep -E "Architecture Violation|MUST_NOT|was violated|DemoViolation" | head -6 || true
[[ ${code} -ne 0 ]] || die "The backend rule did NOT fail. The demo is wrong."
log "Frontend (the rule must fail):"
out="$(run_frontend_rules)" && code=0 || code=$?
echo "${out}" | grep -E "FAIL|\|" | head -6 || true
[[ ${code} -ne 0 ]] || die "The frontend rule did NOT fail. The demo is wrong."
log "PASS both rules failed as expected."
