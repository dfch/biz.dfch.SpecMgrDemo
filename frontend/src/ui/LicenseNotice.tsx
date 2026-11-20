import { useTranslation } from 'react-i18next'
import type { ApiClient } from '../client/apiClient'
import { ErrorMessage } from './ErrorMessage'
import { useRemote } from './useRemote'

// The notice of the license in the user interface (feat-9-walking-skeleton, Phase 300, Task 300.110, REQ-003,
// DEC 5ddd8d7a-5e7d-4a9b-860f-7d0b1f05579c): the copyright holder, the address of the repository and the
// license of GET /info, in the sentence of the catalog (the template `info.notice`; the values are data and not
// text). With the EN catalog the sentence is: "Copyright 2026 Ronald Rink,
// https://github.com/dfch/biz.dfch.SpecMgrDemo. Licensed under AGPL-3.0-only." The version and the commit of the
// build are shown too, so a user can get the exact source of the build from the repository.
export function LicenseNotice({ api }: { readonly api: ApiClient }) {
  const { t } = useTranslation()
  const remote = useRemote(() => api.getInfo(), [api])
  return (
    <footer>
      {remote.phase === 'loading' ? <p role="status">{t('info.loading')}</p> : null}
      {remote.phase === 'ready' ? (
        <>
          <p>
            {t('info.notice', {
              copyright: remote.value.copyright,
              repository: remote.value.repository,
              license: remote.value.license,
            })}
          </p>
          <p>{t('info.version', { version: remote.value.version, commit: remote.value.commit })}</p>
        </>
      ) : null}
      {remote.phase === 'failed' ? <ErrorMessage error={remote.error} /> : null}
    </footer>
  )
}
