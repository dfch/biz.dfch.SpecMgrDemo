import { defineConfig } from '@playwright/test'

// The end-to-end tests with the accessibility check of axe-core (feat-7-verification-architecture-tools,
// Task 110.120, REQ-007). The tests run headless (no display, also in CI) against the HTML fixtures in
// e2e/fixtures/. The recipe test-e2e (tools/gates/test-e2e.sh) serves the fixtures on a local static
// server and gives the address in E2E_BASE_URL. The folder e2e/negative/ has the case that is not
// successful (ACC-002): the normal run skips it, and the recipe starts it with
// playwright.config.negative.ts and stops for it.
export default defineConfig({
  testDir: 'e2e',
  testIgnore: ['**/negative/**'],
  fullyParallel: false,
  workers: 1,
  retries: 0,
  use: {
    headless: true,
  },
  // The fixtures on a local static server (the loopback address only). Playwright starts the server,
  // waits for the port, and stops it after the run. The recipe test-e2e needs no server of its own.
  webServer: {
    command: 'node e2e/serve.mjs e2e/fixtures 8377',
    url: 'http://127.0.0.1:8377/good.html',
    reuseExistingServer: true,
    timeout: 30000,
  },
})
