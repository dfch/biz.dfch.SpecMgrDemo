#!/usr/bin/env node
// Task 140.100: take one screenshot with Playwright (the Chromium of the cache ~/.cache/ms-playwright).
// Usage: node 140-100-01-shot.mjs <playwright package dir> <url> <output png> [--lang de] [--full]
import { pathToFileURL } from 'node:url'
import { join } from 'node:path'

const [pkgDir, url, out, ...flags] = process.argv.slice(2)
const { chromium } = await import(pathToFileURL(join(pkgDir, "index.mjs")).href)
const opt = (name, fallback) => (flags.includes(name) ? flags[flags.indexOf(name) + 1] : fallback)
const lang = flags.includes('--lang') ? flags[flags.indexOf('--lang') + 1] : null
const browser = await chromium.launch()
const page = await browser.newPage({ viewport: { width: Number(opt('--width', 1280)), height: Number(opt('--height', 800)) } })
await page.goto(url, { waitUntil: 'networkidle', timeout: 30000 }).catch(() => {}) // fonts.googleapis.com may not load
if (lang) {
  await page.locator(`button[lang="${lang}"]`).click()
}
await page.waitForTimeout(1500)
// closes the help dialog of the Structurizr viewer (only the model site has it)
await page.getByRole('dialog').getByRole('button').first().click({ timeout: 1500 }).catch(() => {})
await page.waitForTimeout(1200)
await page.screenshot({ path: out, fullPage: flags.includes('--full') })
await browser.close()
console.log(`written ${out}`)
