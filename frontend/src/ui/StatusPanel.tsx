import { useTranslation } from 'react-i18next'
import type { ApiClient } from '../client/apiClient'
import { ErrorMessage } from './ErrorMessage'
import { useRemote } from './useRemote'

/**
 * The time of the check for the language: the format of the `Intl` of the platform (DEC
 * 51b00b5f-d1d8-49d8-9f40-28537ff69698), in UTC with the name of the zone (the backend gives UTC).
 */
export function formatTime(iso: string, language: string): string {
  return new Intl.DateTimeFormat(language, { dateStyle: 'medium', timeStyle: 'long', timeZone: 'UTC' }).format(new Date(iso))
}

// The page that shows the state of the operation GET /status (feat-9-walking-skeleton, Phase 300, Task 300.100,
// REQ-003): the state (up or degraded) and the time of the check, or the error with the text of its code.
export function StatusPanel({ api }: { readonly api: ApiClient }) {
  const { t, i18n } = useTranslation()
  const remote = useRemote(() => api.getStatus(), [api])
  return (
    <section aria-labelledby="status-heading">
      <h2 id="status-heading">{t('status.heading')}</h2>
      {remote.phase === 'loading' ? <p role="status">{t('status.loading')}</p> : null}
      {remote.phase === 'ready' ? (
        <>
          <p role="status" data-state={remote.value.state}>
            {t(`status.${remote.value.state}`)}
          </p>
          <p>{t('status.checkedAt', { time: formatTime(remote.value.checkedAt, i18n.language) })}</p>
        </>
      ) : null}
      {remote.phase === 'failed' ? <ErrorMessage error={remote.error} /> : null}
    </section>
  )
}
