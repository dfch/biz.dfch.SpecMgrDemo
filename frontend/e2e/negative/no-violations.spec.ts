import { expect, test, type Page } from '@playwright/test'
import { readFileSync } from 'node:fs'
import { fileURLToPath } from 'node:url'

// The case that is not successful (feat-7-verification-architecture-tools, Task 110.120, ACC-002): the
// page has violations (an image without alt and a text with low contrast), and the test expects none.
// This spec is in the folder e2e/negative/, so the normal run (playwright.config.ts) does not start it,
// and the committed run of the tests is green. The recipe test-e2e (tools/gates/test-e2e.sh) starts this
// spec with playwright.config.negative.ts and stops for it: Playwright reports the failed test, and the
// output names the violations that axe-core found.
const axeSource = readFileSync(fileURLToPath(new URL('../../node_modules/axe-core/axe.min.js', import.meta.url)), 'utf8')
const baseUrl = process.env.E2E_BASE_URL ?? 'http://127.0.0.1:8377'

interface AxeViolation {
  id: string
  impact: string | null
}
interface AxeResult {
  violations: AxeViolation[]
}

async function runAxe(page: Page): Promise<AxeResult> {
  await page.addScriptTag({ content: axeSource })
  return page.evaluate(async () => {
    const axe = (window as unknown as { axe: { run: (context: object) => Promise<AxeResult> } }).axe
    return axe.run(document.body)
  })
}

test('the bad page has no violations', async ({ page }) => {
  await page.goto(`${baseUrl}/bad.html`)
  const result = await runAxe(page)
  expect(result.violations).toEqual([])
})
