// @vitest-environment happy-dom
import { act } from 'react'
import { createRoot, type Root } from 'react-dom/client'
import { I18nextProvider } from 'react-i18next'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import { ApiError, type ApiClient } from '../client/apiClient'
import type { Info } from '../generated/types/Info'
import type { Status } from '../generated/types/Status'
import { createI18n, type Language } from '../i18n/i18n'
import { App } from '../ui/App'
import { formatTime } from '../ui/StatusPanel'

// Unit tests of the user interface (feat-9-walking-skeleton, Phase 300, Task 300.100, Task 300.110 and Task
// 300.120, REQ-003, ACC-004, ACC-010): the page shows the state of GET /status and the notice of the license
// of GET /info, and the test shows the text of the second language (DE). The client of the API is a fake
// object with the answers of the contract (the end-to-end test of the phase 400 uses the real service). The
// DOM is the one of happy-dom.

const traceId = 'b'.repeat(32)
const status: Status = { state: 'up', checkedAt: '2026-11-17T04:30:00Z' }
const info: Info = {
  version: '0.1.0',
  commit: '0123456789abcdef0123456789abcdef01234567',
  copyright: 'Copyright 2026 Ronald Rink',
  repository: 'https://github.com/dfch/biz.dfch.SpecMgrDemo',
  license: 'AGPL-3.0-only',
}
const englishNotice = 'Copyright 2026 Ronald Rink, https://github.com/dfch/biz.dfch.SpecMgrDemo. Licensed under AGPL-3.0-only.'
const germanNotice = 'Copyright 2026 Ronald Rink, https://github.com/dfch/biz.dfch.SpecMgrDemo. Lizenziert unter AGPL-3.0-only.'

let container: HTMLElement
let root: Root

beforeEach(() => {
  // React 19 needs this flag to accept the updates of act() in a test.
  ;(globalThis as { IS_REACT_ACT_ENVIRONMENT?: boolean }).IS_REACT_ACT_ENVIRONMENT = true
  container = document.createElement('div')
  document.body.append(container)
  root = createRoot(container)
})

afterEach(async () => {
  await act(async () => root.unmount())
  container.remove()
})

function fakeApi(overrides: Partial<ApiClient> = {}): ApiClient {
  return {
    getStatus: vi.fn(async () => status),
    getInfo: vi.fn(async () => info),
    ...overrides,
  }
}

async function show(api: ApiClient, language: Language): Promise<void> {
  const i18n = createI18n(language)
  await act(async () => {
    root.render(
      <I18nextProvider i18n={i18n}>
        <App api={api} />
      </I18nextProvider>,
    )
  })
}

const text = (selector: string): string | undefined => container.querySelector(selector)?.textContent ?? undefined

describe('the user interface', () => {
  it('has the landmarks header, main and footer as siblings (none is inside main)', async () => {
    await show(fakeApi(), 'en')
    const page = container.querySelector('.page')
    expect(page).not.toBeNull()
    expect(Array.from(page?.children ?? []).map((element) => element.tagName)).toEqual(['HEADER', 'MAIN', 'FOOTER'])
    expect(container.querySelectorAll('main').length).toBe(1)
    expect(container.querySelector('main header, main footer')).toBeNull()
    expect(container.querySelector('main h2')?.textContent).toBe('System status')
    expect(container.querySelector('header h1')?.textContent).toBe('SpecMgr Demo')
  })

  it('shows the loading text before the answers arrive', async () => {
    const never = new Promise<never>(() => undefined)
    await show(fakeApi({ getStatus: () => never, getInfo: () => never }), 'en')
    expect(container.textContent).toContain('The status is loading.')
    expect(container.textContent).toContain('The information of the service is loading.')
    expect(container.querySelector('footer p:first-child')?.textContent).not.toContain('Copyright')
  })

  it('shows the state of GET /status and the time of the check', async () => {
    await show(fakeApi(), 'en')
    expect(text('h2')).toBe('System status')
    expect(text('[data-state="up"]')).toBe('The system is up.')
    expect(container.textContent).toContain(`Checked at ${formatTime(status.checkedAt, 'en')}`)
    expect(formatTime(status.checkedAt, 'en')).toContain('2026')
  })

  it('shows the state degraded', async () => {
    await show(fakeApi({ getStatus: async () => ({ ...status, state: 'degraded' }) }), 'en')
    expect(text('[data-state="degraded"]')).toBe('The system is degraded.')
  })

  it('shows the notice of the license of GET /info, exactly as the DEC has it', async () => {
    await show(fakeApi(), 'en')
    const notice = container.querySelector('footer p')
    expect(notice?.textContent).toBe(englishNotice)
    expect(container.querySelector('footer')?.textContent).toContain(`Version ${info.version}, commit ${info.commit}`)
  })

  it('shows the text of the second language DE: the state, the time, the notice and the version', async () => {
    await show(fakeApi(), 'de')
    expect(text('h2')).toBe('Systemstatus')
    expect(text('[data-state="up"]')).toBe('Das System läuft.')
    expect(container.textContent).toContain(`Geprüft am ${formatTime(status.checkedAt, 'de')}`)
    expect(container.querySelector('footer p')?.textContent).toBe(germanNotice)
    expect(container.querySelector('footer')?.textContent).toContain(`Version ${info.version}, Commit ${info.commit}`)
    expect(container.textContent).not.toContain('The system is up.')
  })

  it('changes the language with the button, and sets the language of the page', async () => {
    await show(fakeApi(), 'en')
    expect(document.documentElement.lang).toBe('en')
    expect(document.title).toBe('SpecMgr Demo')
    const [english, german] = Array.from(container.querySelectorAll<HTMLButtonElement>('nav button'))
    expect(english?.getAttribute('aria-pressed')).toBe('true')
    expect(german?.getAttribute('aria-pressed')).toBe('false')

    await act(async () => german?.click())

    expect(document.documentElement.lang).toBe('de')
    expect(text('h2')).toBe('Systemstatus')
    expect(container.querySelector('footer p')?.textContent).toBe(germanNotice)
    expect(german?.getAttribute('aria-pressed')).toBe('true')
    expect(container.querySelector('nav')?.getAttribute('aria-label')).toBe('Sprache')
  })

  it('shows the text of the error code, and the trace identifier, if GET /status gives an error', async () => {
    const error = new ApiError('problem', 'service_unavailable', { code: 'service_unavailable', traceId, status: 503 })
    await show(fakeApi({ getStatus: async () => Promise.reject(error) }), 'en')
    const alert = container.querySelector('[role="alert"]')
    expect(alert?.textContent).toContain('The information is not available.')
    expect(alert?.textContent).toContain('The service is not available.')
    expect(alert?.textContent).toContain(`Trace identifier: ${traceId}`)
    expect(container.querySelector('footer p')?.textContent).toBe(englishNotice)
  })

  it('shows the text of the error code in the second language DE', async () => {
    const error = new ApiError('problem', 'service_unavailable', { code: 'service_unavailable', traceId, status: 503 })
    await show(fakeApi({ getStatus: async () => Promise.reject(error) }), 'de')
    const alert = container.querySelector('[role="alert"]')
    expect(alert?.textContent).toContain('Der Dienst ist nicht verfügbar.')
    expect(alert?.textContent).toContain(`Trace-Kennung: ${traceId}`)
  })

  it('shows the text for a service that cannot be reached, and for an answer that is not valid', async () => {
    await show(
      fakeApi({
        getStatus: async () => Promise.reject(new ApiError('network', 'no connection')),
        getInfo: async () => Promise.reject(new ApiError('invalid', 'no contract')),
      }),
      'en',
    )
    const alerts = Array.from(container.querySelectorAll('[role="alert"]')).map((alert) => alert.textContent)
    expect(alerts[0]).toContain('The service cannot be reached.')
    expect(alerts[1]).toContain('The service gave an answer that the application does not understand.')
    expect(container.textContent).not.toContain('Trace identifier')
  })

  it('shows the text for a request that has no answer in time, in EN and in DE', async () => {
    const timeout = () => Promise.reject(new ApiError('timeout', 'no answer in time'))
    await show(fakeApi({ getStatus: timeout }), 'en')
    expect(container.querySelector('[role="alert"]')?.textContent).toContain('The service did not answer in time.')
    expect(container.textContent).not.toContain('The service cannot be reached.')

    await act(async () => root.render(<div />))
    await show(fakeApi({ getStatus: timeout }), 'de')
    expect(container.querySelector('[role="alert"]')?.textContent).toContain('Der Dienst hat nicht rechtzeitig geantwortet.')
  })

  it('shows no notice of the license, and an error text, if GET /info gives an error', async () => {
    const error = new ApiError('problem', 'internal_error', { code: 'internal_error', traceId, status: 500 })
    await show(fakeApi({ getInfo: async () => Promise.reject(error) }), 'en')
    expect(container.querySelector('footer')?.textContent).toContain('The service has an internal error.')
    expect(container.textContent).not.toContain('Licensed under')
  })

  it('asks each operation once', async () => {
    const api = fakeApi()
    await show(api, 'en')
    expect(api.getStatus).toHaveBeenCalledTimes(1)
    expect(api.getInfo).toHaveBeenCalledTimes(1)
  })
})
