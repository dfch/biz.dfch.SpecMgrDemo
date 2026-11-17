#!/usr/bin/env bash
# Task 160.100: make the SBOM with the gate of the repository (`just license-check`, it makes `just sbom` first) and show where
# the files are and what they have. The files are in build/sbom of the work tree (not in git). CI keeps them as the artifact `sbom`
# of the job `license-check` (90 days). Needs JDK 21, Node, pnpm, uv and the network for the first run.
# Usage: 160-100-00-show-sbom.sh
source "$(dirname "${BASH_SOURCE[0]}")/_common.sh"
need python3
mkdir -p "${BUILD}"
(cd "${REPO}" && just license-check) >"${BUILD}/license-check.log" 2>&1 && gate="PASS" || gate="STOP (see ${BUILD}/license-check.log)"
grep -E "RESULT|NOT KNOWN|NOT PERMITTED" "${BUILD}/license-check.log" | tail -4 || true
log "license-check: ${gate}"
python3 - "${REPO}/build/sbom" <<'P'
import json, sys, glob, os
for f in sorted(glob.glob(os.path.join(sys.argv[1], "*.cdx.json"))):
    d = json.load(open(f))
    print(f"{f}\n  {d['bomFormat']} {d['specVersion']}, {len(d.get('components', []))} component(s), {os.path.getsize(f)} bytes")
P
