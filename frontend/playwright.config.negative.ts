import { defineConfig } from '@playwright/test'

// The case that is not successful (feat-7-verification-architecture-tools, Task 110.120, ACC-002): a test
// that expects no violations on the page with violations. The normal run (playwright.config.ts) skips the
// folder e2e/negative/, and the recipe test-e2e (tools/gates/test-e2e.sh) starts this config and stops for
// it: Playwright reports the failed test, and the output names the violations of axe-core.
export default defineConfig({
  testDir: 'e2e/negative',
  fullyParallel: false,
  workers: 1,
  retries: 0,
  use: {
    headless: true,
  },
  // The same static server as the normal run (playwright.config.ts). Playwright starts the server,
  // waits for the port, and stops it after the run.
  webServer: {
    command: 'node e2e/serve.mjs e2e/fixtures 8377',
    url: 'http://127.0.0.1:8377/good.html',
    reuseExistingServer: true,
    timeout: 30000,
  },
})
