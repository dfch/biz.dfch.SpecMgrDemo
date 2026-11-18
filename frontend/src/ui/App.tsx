import { useEffect } from 'react'
import { useTranslation } from 'react-i18next'
import type { ApiClient } from '../client/apiClient'
import { LanguageSwitcher } from './LanguageSwitcher'
import { LicenseNotice } from './LicenseNotice'
import { StatusPanel } from './StatusPanel'

// The user interface of the walking skeleton (feat-9-walking-skeleton, Phase 300, REQ-003): the state of
// GET /status, and the notice of the license of GET /info. The text is from the catalogs of the i18n (the
// provider I18nextProvider is above this component), and the data is from the client of the API.
//
// The landmarks are siblings (review N8 of feat-9): `header` (banner), `main` and `footer` (contentinfo, the
// footer of LicenseNotice) are children of the `div` of the page, and none of them is inside `main`. A `header` or
// a `footer` inside `main` is no landmark, so the user of a screen reader would not find the title and the notice
// of the license by the landmarks.
export function App({ api }: { readonly api: ApiClient }) {
  const { t, i18n } = useTranslation()
  useEffect(() => {
    document.documentElement.lang = i18n.resolvedLanguage ?? 'en'
    document.title = t('app.title')
  }, [i18n.resolvedLanguage, t])
  return (
    <div className="page">
      <header>
        <h1>{t('app.title')}</h1>
        <LanguageSwitcher />
      </header>
      <main>
        <StatusPanel api={api} />
      </main>
      <LicenseNotice api={api} />
    </div>
  )
}
