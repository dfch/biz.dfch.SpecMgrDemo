import { defineConfig } from '@playwright/test'

// The end-to-end tests with the accessibility check of axe-core (feat-7-verification-architecture-tools,
// Task 110.120, REQ-007). The tests run headless (no display, also in CI) against the HTML fixtures in
// e2e/fixtures/. The webServer of this config serves the fixtures on a local static server (e2e/serve.mjs,
// the loopback address, the port 8377), waits for the port, and stops it after the run; the spec opens the
// pages on the default base URL of the config (http://127.0.0.1:8377, overridable with E2E_BASE_URL, which
// the recipe test-e2e (tools/gates/test-e2e.sh) never sets). The folder e2e/negative/ has the case that is
// not successful (ACC-002): the normal run skips it, and the recipe starts it with
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
  // The port 8377 is the fixture port of both configs (this and playwright.config.negative.ts): a
  // process that occupies it stops the run (reuseExistingServer is false, fail closed), and is not
  // adopted.
  webServer: {
    command: 'node e2e/serve.mjs e2e/fixtures 8377',
    url: 'http://127.0.0.1:8377/good.html',
    reuseExistingServer: false,
    timeout: 30000,
  },
})
