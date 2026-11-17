import { expect, test } from '@playwright/test'

// The end-to-end tests of the walking skeleton (feat-9-walking-skeleton, Phase 400, Task 400.110, REQ-003,
// REQ-005, ACC-004, ACC-010). The tests open the page of the real service: the backend of the build and the
// development server of Vite of the frontend (the second webServer of playwright.config.ts, e2e/service.mjs; the
// ports are random, and the address of the frontend is in the environment variable E2E_SERVICE_URL). The
// browser sees one origin: the development server sends /status and /info to the backend. The telemetry of the
// browser and of the backend has no endpoint (no collector, REQ-004), so the run is deterministic.
//
// The first test has the identifier of its verification case record in its title, as the convention of DEC
// f21920d2-4da5-4cf7-bd94-2e9bcba77342 says (the text vcr:<uuid> and the name that the record states): the
// verification case record eb8a7f16-880d-42b7-9852-37c96175d344, the criterion AC-002 (the user interface shows
// the notice of the license, and its values are the values of the response of GET /info). The two other tests
// show the state of GET /status, and the notice in the second language of the i18n (the criterion ACC-004 of
// the plan; the unit tests of the user interface show the same cases with a simulated client).
const serviceUrl = process.env.E2E_SERVICE_URL

interface Info {
  version: string
  commit: string
  copyright: string
  repository: string
  license: string
}

/** The address of the frontend of the real service (the stop of the run for a missing value: fail closed). */
function baseUrl(): string {
  if (serviceUrl === undefined || serviceUrl === '') {
    throw new Error('E2E_SERVICE_URL is not set: the webServer e2e/service.mjs of playwright.config.ts gives it')
  }
  return serviceUrl
}

// The language of the page is the locale of the browser: en-US for the tests of the English catalog.
test.use({ locale: 'en-US' })

test('vcr:eb8a7f16-880d-42b7-9852-37c96175d344 the user interface shows the notice of the license', async ({ page, request }) => {
  // The values of GET /info, from the backend (through the proxy of the development server).
  const response = await request.get(`${baseUrl()}/info`)
  expect(response.status()).toBe(200)
  const info = (await response.json()) as Info
  expect(info.copyright).not.toBe('')
  expect(info.repository).not.toBe('')
  expect(info.license).toBe('AGPL-3.0-only')

  // The page shows the copyright holder, the address of the repository and the license, and the values of
  // the page are the values of the response: the sentence of the catalog with the values of GET /info.
  await page.goto(baseUrl())
  const notice = page.locator('footer p').first()
  await expect(notice).toHaveText(`${info.copyright}, ${info.repository}. Licensed under ${info.license}.`)
  // The exact notice of DEC 5ddd8d7a-5e7d-4a9b-860f-7d0b1f05579c (the response of the service is the one of the contract).
  await expect(notice).toHaveText(
    'Copyright 2026 Ronald Rink, https://github.com/dfch/biz.dfch.SpecMgrDemo. Licensed under AGPL-3.0-only.',
  )
  // The version and the commit of the build, so a user can get the exact source (the same response).
  await expect(page.locator('footer p').nth(1)).toHaveText(`Version ${info.version}, commit ${info.commit}`)
})

test('the user interface shows the state of the system', async ({ page, request }) => {
  const response = await request.get(`${baseUrl()}/status`)
  expect(response.status()).toBe(200)
  expect(((await response.json()) as { state: string }).state).toBe('up')

  await page.goto(baseUrl())
  await expect(page.getByRole('heading', { name: 'System status' })).toBeVisible()
  const state = page.locator('[data-state]')
  await expect(state).toHaveAttribute('data-state', 'up')
  await expect(state).toHaveText('The system is up.')
  await expect(page.getByText(/^Checked at /)).toBeVisible()
})

test.describe('the page in German', () => {
  test.use({ locale: 'de-DE' })

  test('the user interface shows the notice of the license and the state in the second language', async ({ page, request }) => {
    const response = await request.get(`${baseUrl()}/info`)
    expect(response.status()).toBe(200)
    const info = (await response.json()) as Info

    await page.goto(baseUrl())
    await expect(page.locator('html')).toHaveAttribute('lang', 'de')
    await expect(page.getByRole('heading', { name: 'Systemstatus' })).toBeVisible()
    await expect(page.locator('[data-state]')).toHaveText('Das System läuft.')
    await expect(page.locator('footer p').first()).toHaveText(
      `${info.copyright}, ${info.repository}. Lizenziert unter ${info.license}.`,
    )
    await expect(page.locator('footer p').nth(1)).toHaveText(`Version ${info.version}, Commit ${info.commit}`)

    // The button of the language switches the page to English again (the same values, the English catalog).
    await page.getByRole('button', { name: 'English' }).click()
    await expect(page.locator('[data-state]')).toHaveText('The system is up.')
    await expect(page.locator('footer p').first()).toHaveText(
      `${info.copyright}, ${info.repository}. Licensed under ${info.license}.`,
    )
  })
})
