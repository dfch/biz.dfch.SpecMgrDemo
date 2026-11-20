import type { Telemetry } from './telemetry'

// The flush of the spans when the page is hidden or closed (feat-9-walking-skeleton, review N8, REQ-004). The
// BatchSpanProcessor sends the spans in batches after a delay, so a span of the last request would be lost if the
// user closes the tab or goes to another page before the delay ends. The events `pagehide` (the page is
// unloaded or goes to the cache of the history) and `visibilitychange` to the state `hidden` (the only event that
// is sure on a mobile browser) send the spans that are not sent yet.
//
// The function calls `forceFlush`, and not `shutdown`: a page that goes to the back/forward cache can come back,
// and then the telemetry must still work. With no endpoint the processor is the NoopSpanProcessor, and
// `forceFlush` does nothing, so the behavior without a collector is not changed. A failed flush is no error of
// the page (the telemetry never breaks the application), so the failure is swallowed.

/** The two things of the page that the function needs (the `window` and its `document` in the product). */
export interface PageLifecycle {
  addEventListener(type: 'pagehide' | 'visibilitychange', listener: () => void): void
  removeEventListener(type: 'pagehide' | 'visibilitychange', listener: () => void): void
  readonly document: { readonly visibilityState: DocumentVisibilityState }
}

/**
 * Send the spans that are not sent yet when the page is hidden or closed.
 *
 * @param telemetry the telemetry of the application
 * @param page the `window` of the page (the seam of the tests)
 * @returns the function that removes the two listeners
 */
export function flushOnPageHide(telemetry: Pick<Telemetry, 'forceFlush'>, page: PageLifecycle): () => void {
  const flush = (): void => {
    void telemetry.forceFlush().catch(() => undefined)
  }
  const onVisibilityChange = (): void => {
    if (page.document.visibilityState === 'hidden') {
      flush()
    }
  }
  page.addEventListener('pagehide', flush)
  page.addEventListener('visibilitychange', onVisibilityChange)
  return () => {
    page.removeEventListener('pagehide', flush)
    page.removeEventListener('visibilitychange', onVisibilityChange)
  }
}
