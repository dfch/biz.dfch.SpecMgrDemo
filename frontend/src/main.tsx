import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import { I18nextProvider } from 'react-i18next'
import { createApiClient } from './client/apiClient'
import { createI18n, detectLanguage } from './i18n/i18n'
import { readTelemetryConfig } from './telemetry/config'
import { flushOnPageHide } from './telemetry/flush'
import { createTelemetry } from './telemetry/telemetry'
import { App } from './ui/App'

// The entry point of the frontend (feat-9-walking-skeleton, Phase 300). It builds the parts and starts the user
// interface. The configuration is the build-time configuration of Vite (the variables VITE_*, `import.meta.env`):
//
// - VITE_API_BASE_URL: the base address of the backend. The default is the empty text: relative URLs (the same
//   origin). In the development (`pnpm exec vite`), the server of Vite sends /status and /info to the backend
//   (vite.config.ts).
// - VITE_OTEL_*: the OpenTelemetry (telemetry/config.ts). No address means no collector, and the processor of
//   the spans does nothing.
const env = import.meta.env
const telemetry = createTelemetry(readTelemetryConfig(env))
// The spans that are not sent yet are sent when the page is hidden or closed (the batch processor has a delay).
flushOnPageHide(telemetry, window)
const api = createApiClient(env.VITE_API_BASE_URL ?? '', telemetry.traceFetch((input, init) => fetch(input, init)))
const i18n = createI18n(detectLanguage(navigator.languages))

const container = document.getElementById('root')
if (container === null) {
  throw new Error('The page has no element with the identifier root')
}
createRoot(container).render(
  <StrictMode>
    <I18nextProvider i18n={i18n}>
      <App api={api} />
    </I18nextProvider>
  </StrictMode>,
)
