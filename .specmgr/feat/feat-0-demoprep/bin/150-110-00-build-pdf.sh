#!/usr/bin/env bash
# Task 150.110 (ACC-007): make PRESENTATION.pdf from PRESENTATION.md with Marp (npx, needs the network for the first run; the
# tool is not a dependency of the repository). Chromium: the one of Playwright in ~/.cache/ms-playwright, or CHROME_PATH.
# Fallback without Marp: pandoc PRESENTATION.md -o PRESENTATION.pdf   (plain document, needs a LaTeX engine)
# Usage: 150-110-00-build-pdf.sh
source "$(dirname "${BASH_SOURCE[0]}")/_common.sh"
need npx
if [[ -z "${CHROME_PATH:-}" ]]; then
    CHROME_PATH="$(ls -d "${HOME}"/.cache/ms-playwright/chromium-*/chrome-linux*/chrome 2>/dev/null | tail -1 || true)"
fi
# Ubuntu 23.10+ (AppArmor) can forbid the sandbox of Chromium for a user (kernel.apparmor_restrict_unprivileged_userns=1),
# and Marp then stops with "No usable sandbox". Then use a wrapper with --no-sandbox (found on nxt). Local files only.
if [[ -n "${CHROME_PATH}" && "$(cat /proc/sys/kernel/apparmor_restrict_unprivileged_userns 2>/dev/null || echo 0)" == "1" && -z "${MARP_KEEP_SANDBOX:-}" ]]; then
    mkdir -p "${BUILD}"
    printf '#!/usr/bin/env bash\nexec "%s" --no-sandbox "$@"\n' "${CHROME_PATH}" >"${BUILD}/chrome-nosandbox"
    chmod +x "${BUILD}/chrome-nosandbox"
    log "AppArmor restricts user namespaces: Chromium runs with --no-sandbox (set MARP_KEEP_SANDBOX=1 to keep the sandbox)"
    CHROME_PATH="${BUILD}/chrome-nosandbox"
fi
[[ -n "${CHROME_PATH}" ]] && export CHROME_PATH
cd "${FEAT_DIR}"
npx --yes @marp-team/marp-cli PRESENTATION.md --pdf --allow-local-files --no-stdin -o PRESENTATION.pdf
if command -v pdfinfo >/dev/null; then log "PASS $(pdfinfo PRESENTATION.pdf | grep Pages)"; else log "PASS PRESENTATION.pdf"; fi
