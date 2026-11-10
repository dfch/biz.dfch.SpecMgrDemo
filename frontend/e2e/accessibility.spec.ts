import { expect, test, type Page } from '@playwright/test'
import { readFileSync } from 'node:fs'
import { fileURLToPath } from 'node:url'

// The accessibility check of the end-to-end test (feat-7-verification-architecture-tools, Task 110.120,
// REQ-007, ACC-002: the case that is successful). The check uses the package axe-core directly: the source
// of axe.min.js is read from node_modules (not a wrapper package, the license table names axe-core), it is
// injected into the page, and axe.run reports the violations. The page is the fixture that the recipe
// test-e2e serves on E2E_BASE_URL.
const axeSource = readFileSync(fileURLToPath(new URL('../node_modules/axe-core/axe.min.js', import.meta.url)), 'utf8')
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

test('the good page has no violations', async ({ page }) => {
  await page.goto(`${baseUrl}/good.html`)
  const result = await runAxe(page)
  expect(result.violations).toEqual([])
})

test('the bad page reports the violations', async ({ page }) => {
  await page.goto(`${baseUrl}/bad.html`)
  const result = await runAxe(page)
  const ids = result.violations.map(violation => violation.id)
  expect(ids).toContain('image-alt')
  expect(ids).toContain('color-contrast')
})
