import { useTranslation } from 'react-i18next'
import { ApiError } from '../client/apiClient'

// The text of an error of the client for the user (DEC 51b00b5f-d1d8-49d8-9f40-28537ff69698: the backend sends
// the error code, and the frontend shows the text for the code from its catalog; the members `title` and
// `detail` of the problem are for developers and are never shown). The trace identifier of the backend is
// shown, so a user can give it to the support (DEC e3eadec0-a6ea-4efe-8e6d-fd19287122fa).
export function ErrorMessage({ error }: { readonly error: unknown }) {
  const { t } = useTranslation()
  let text: string
  let traceId: string | undefined
  if (error instanceof ApiError && error.kind === 'problem' && error.code !== undefined) {
    text = t(`error.code.${error.code}`)
    traceId = error.traceId
  } else if (error instanceof ApiError && error.kind === 'network') {
    text = t('error.network')
  } else {
    text = t('error.invalid')
  }
  return (
    <div role="alert">
      <p>{t('error.heading')}</p>
      <p>{text}</p>
      {traceId === undefined ? null : <p>{t('error.traceId', { traceId })}</p>}
    </div>
  )
}
