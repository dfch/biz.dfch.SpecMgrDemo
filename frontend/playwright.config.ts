import { defineConfig } from '@playwright/test'

// The end-to-end tests with the accessibility check of axe-core (feat-7-verification-architecture-tools,
// Task 110.120, REQ-007). The tests run headless (no display, also in CI) against the HTML fixtures in
// e2e/fixtures/. The webServer of this config serves the fixtures on a local static server (e2e/serve.mjs,
// the loopback address, the port 8377), waits for the port, and stops it after the run; the spec opens the
// pages on the default base URL of the config (http://127.0.0.1:8377, overridable with E2E_BASE_URL, which
// the recipe test-e2e (tools/gates/test-e2e.sh) never sets). The folder e2e/negative/ has the case that is
// not successful (ACC-002): the normal run skips it, and the recipe starts it with
// playwright.config.negative.ts and stops for it.
//
// The second webServer is the real service of the walking skeleton (feat-9-walking-skeleton, Phase 400, Task
// 400.110): the backend of the build and the development server of Vite (e2e/service.mjs). The ports are random.
// The script prints the line `E2E_SERVICE_URL=<address of the frontend>`, Playwright waits for the line (the option
// `wait.stdout`) and stores the named group in the environment variable E2E_SERVICE_URL, and the spec
// e2e/service.spec.ts reads the address from it. The start runs Maven (./mvnw of backend/, JDK 21), so the first
// start needs the time of a build (the timeout is the long one).
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
  webServer: [
    {
      command: 'node e2e/serve.mjs e2e/fixtures 8377',
      url: 'http://127.0.0.1:8377/good.html',
      reuseExistingServer: false,
      timeout: 30000,
    },
    {
      command: 'node e2e/service.mjs',
      wait: { stdout: /E2E_SERVICE_URL=(?<E2E_SERVICE_URL>http:\/\/127\.0\.0\.1:\d+)/ },
      reuseExistingServer: false,
      gracefulShutdown: { signal: 'SIGTERM', timeout: 10000 },
      timeout: 300000,
    },
  ],
})
