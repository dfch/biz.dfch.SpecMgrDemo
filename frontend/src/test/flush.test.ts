// @vitest-environment happy-dom
import { InMemorySpanExporter } from '@opentelemetry/sdk-trace-web'
import { afterEach, describe, expect, it, vi } from 'vitest'
import { flushOnPageHide } from '../telemetry/flush'
import { createTelemetry } from '../telemetry/telemetry'

// Unit tests of the flush of the spans when the page is hidden or closed (feat-9-walking-skeleton, review N8,
// REQ-004). The page is the `window` of happy-dom (the type of the argument is the one that main.tsx passes), and
// the telemetry is the real one with an in-memory exporter, so a test shows that a span that the batch processor
// holds is exported by the event, and not after the delay of the processor.

afterEach(() => {
  vi.restoreAllMocks()
})

const hide = (state: DocumentVisibilityState): void => {
  vi.spyOn(document, 'visibilityState', 'get').mockReturnValue(state)
  document.dispatchEvent(new Event('visibilitychange', { bubbles: true })) // the event bubbles from the document to the window
}

const okFetcher = async () => new Response('{}', { status: 200 })

describe('the flush of the spans when the page is hidden', () => {
  it('registers the two listeners, and removes them', () => {
    const page = { addEventListener: vi.fn(), removeEventListener: vi.fn(), document }
    const remove = flushOnPageHide({ forceFlush: async () => undefined }, page)
    expect(page.addEventListener.mock.calls.map(([type]) => type)).toEqual(['pagehide', 'visibilitychange'])
    expect(page.removeEventListener).not.toHaveBeenCalled()
    remove()
    expect(page.removeEventListener.mock.calls.map(([type]) => type)).toEqual(['pagehide', 'visibilitychange'])
    expect(page.removeEventListener.mock.calls.map(([, listener]) => listener)).toEqual(
      page.addEventListener.mock.calls.map(([, listener]) => listener),
    )
  })

  it('exports the span that the batch processor holds, on pagehide', async () => {
    const exporter = new InMemorySpanExporter()
    const telemetry = createTelemetry({ endpoint: undefined, serviceName: 'test' }, exporter)
    const remove = flushOnPageHide(telemetry, window)
    await telemetry.traceFetch(okFetcher)('/status')
    expect(exporter.getFinishedSpans()).toHaveLength(0) // the batch processor waits for its delay

    window.dispatchEvent(new Event('pagehide'))
    await vi.waitFor(() => expect(exporter.getFinishedSpans()).toHaveLength(1))
    remove()
    await telemetry.shutdown()
  })

  it('exports the span when the page becomes hidden, and not when it becomes visible', async () => {
    const exporter = new InMemorySpanExporter()
    const telemetry = createTelemetry({ endpoint: undefined, serviceName: 'test' }, exporter)
    const remove = flushOnPageHide(telemetry, window)
    await telemetry.traceFetch(okFetcher)('/status')

    hide('visible')
    await new Promise((resolve) => setTimeout(resolve, 20))
    expect(exporter.getFinishedSpans()).toHaveLength(0)

    hide('hidden')
    await vi.waitFor(() => expect(exporter.getFinishedSpans()).toHaveLength(1))
    remove()
    await telemetry.shutdown()
  })

  it('sends nothing after the listeners are removed', async () => {
    const forceFlush = vi.fn(async () => undefined)
    const remove = flushOnPageHide({ forceFlush }, window)
    remove()
    window.dispatchEvent(new Event('pagehide'))
    hide('hidden')
    expect(forceFlush).not.toHaveBeenCalled()
  })

  it('does nothing without an endpoint (no collector) and keeps the telemetry working', async () => {
    const telemetry = createTelemetry({ endpoint: undefined, serviceName: 'test' })
    const remove = flushOnPageHide(telemetry, window)
    window.dispatchEvent(new Event('pagehide'))
    hide('hidden')
    const response = await telemetry.traceFetch(okFetcher)('/status')
    expect(response.status).toBe(200)
    remove()
    await telemetry.shutdown()
  })

  it('swallows the failure of a flush (the telemetry never breaks the page)', async () => {
    const forceFlush = vi.fn(async () => {
      throw new Error('the exporter failed')
    })
    const remove = flushOnPageHide({ forceFlush }, window)
    window.dispatchEvent(new Event('pagehide'))
    await vi.waitFor(() => expect(forceFlush).toHaveBeenCalledTimes(1))
    await new Promise((resolve) => setTimeout(resolve, 10)) // an unhandled rejection would fail the run
    remove()
  })
})
