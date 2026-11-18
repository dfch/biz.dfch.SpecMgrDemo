import type { Catalog } from './en'

// The DE catalog of the user interface (feat-9-walking-skeleton, Phase 300, Task 300.120, DEC
// 51b00b5f-d1d8-49d8-9f40-28537ff69698). The type `Catalog` of the EN catalog makes the compiler stop for a key
// that is missing or extra. The layout must operate with the long German texts.
export const de: Catalog = {
  app: {
    title: 'SpecMgr Demo',
  },
  language: {
    label: 'Sprache',
    en: 'English',
    de: 'Deutsch',
  },
  status: {
    heading: 'Systemstatus',
    loading: 'Der Status wird geladen.',
    up: 'Das System läuft.',
    degraded: 'Das System ist eingeschränkt.',
    checkedAt: 'Geprüft am {{time}}',
  },
  error: {
    heading: 'Die Information ist nicht verfügbar.',
    traceId: 'Trace-Kennung: {{traceId}}',
    network: 'Der Dienst ist nicht erreichbar.',
    timeout: 'Der Dienst hat nicht rechtzeitig geantwortet.',
    invalid: 'Der Dienst hat eine Antwort gegeben, die die Anwendung nicht versteht.',
    code: {
      not_found: 'Die Information wurde nicht gefunden.',
      method_not_allowed: 'Die Methode der Anfrage ist nicht erlaubt.',
      not_acceptable: 'Das Format der Antwort ist nicht akzeptabel.',
      validation_failed: 'Die Anfrage ist nicht gültig.',
      rate_limited: 'Es gibt zu viele Anfragen. Versuchen Sie es später noch einmal.',
      internal_error: 'Der Dienst hat einen internen Fehler.',
      service_unavailable: 'Der Dienst ist nicht verfügbar.',
    },
  },
  info: {
    loading: 'Die Information des Dienstes wird geladen.',
    version: 'Version {{version}}, Commit {{commit}}',
    notice: '{{copyright}}, {{repository}}. Lizenziert unter {{license}}.',
  },
}
