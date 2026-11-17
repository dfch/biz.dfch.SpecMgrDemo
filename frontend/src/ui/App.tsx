import { useEffect } from 'react'
import { useTranslation } from 'react-i18next'
import type { ApiClient } from '../client/apiClient'
import { LanguageSwitcher } from './LanguageSwitcher'
import { LicenseNotice } from './LicenseNotice'
import { StatusPanel } from './StatusPanel'

// The user interface of the walking skeleton (feat-9-walking-skeleton, Phase 300, REQ-003): the state of
// GET /status, and the notice of the license of GET /info. The text is from the catalogs of the i18n (the
// provider I18nextProvider is above this component), and the data is from the client of the API.
export function App({ api }: { readonly api: ApiClient }) {
  const { t, i18n } = useTranslation()
  useEffect(() => {
    document.documentElement.lang = i18n.resolvedLanguage ?? 'en'
    document.title = t('app.title')
  }, [i18n.resolvedLanguage, t])
  return (
    <main>
      <header>
        <h1>{t('app.title')}</h1>
        <LanguageSwitcher />
      </header>
      <StatusPanel api={api} />
      <LicenseNotice api={api} />
    </main>
  )
}
