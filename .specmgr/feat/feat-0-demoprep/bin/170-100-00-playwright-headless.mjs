#!/usr/bin/env node
// Task 170.100 (ACC-009, REQ-007): the head-less Playwright test, no agent.
// It opens the page of the app, reads the version from the notice at the bottom, prints it, and compares it with GET /info.
// Exit code 0 only if the version (and the commit) on the page are the values of GET /info.
// Usage: node 170-100-00-playwright-headless.mjs <playwright package dir> <page url> <info url>
import { pathToFileURL } from 'node:url'
import { join } from 'node:path'

const [pkgDir, pageUrl, infoUrl] = process.argv.slice(2)
if (!pkgDir || !pageUrl || !infoUrl) {
  console.error('Usage: node 170-100-00-playwright-headless.mjs <playwright package dir> <page url> <info url>')
  process.exit(2)
}

const { chromium } = await import(pathToFileURL(join(pkgDir, 'index.mjs')).href)
const browser = await chromium.launch()
let code = 1
try {
  // The locale is fixed to EN, so the text is "Version <v>, commit <sha>" (the DE text is "Version <v>, Commit <sha>").
  const context = await browser.newContext({ locale: 'en-US' })
  const page = await context.newPage()
  // The fonts of the page may not load without a network: do not wait for the idle network.
  await page.goto(pageUrl, { waitUntil: 'domcontentloaded', timeout: 30000 })
  const notice = page.locator('footer', { hasText: /Version\s+\S+,\s+commit\s+\S+/i })
  await notice.waitFor({ state: 'visible', timeout: 30000 })
  const text = (await notice.innerText()).replace(/\s+/g, ' ')
  const match = /Version\s+(\S+),\s+commit\s+(\S+?)\.?(?:\s|$)/i.exec(text)
  if (!match) throw new Error(`No version in the notice: "${text}"`)
  const [, version, commit] = match
  console.log(`Version on the page: ${version} (commit ${commit})`)

  const response = await fetch(infoUrl)
  if (!response.ok) throw new Error(`GET ${infoUrl} gave ${response.status}`)
  const info = await response.json()
  console.log(`Version of GET /info: ${info.version} (commit ${info.commit})`)

  if (version === info.version && commit === info.commit) {
    console.log('PASS the version on the page is the version of GET /info')
    code = 0
  } else {
    console.error('FAIL the page and GET /info differ')
  }
} catch (error) {
  console.error(`FAIL ${error instanceof Error ? error.message : String(error)}`)
} finally {
  await browser.close()
}
process.exit(code)
