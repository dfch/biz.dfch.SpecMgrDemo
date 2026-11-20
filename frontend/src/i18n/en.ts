// The EN catalog of the user interface (feat-9-walking-skeleton, Phase 300, Task 300.120, DEC
// 51b00b5f-d1d8-49d8-9f40-28537ff69698). It is the catalog that defines the keys: the type `Catalog` is the
// shape of this object, and the DE catalog (de.ts) must have the same keys (the compiler and the unit test
// check it). The text has the values as data (`{{name}}`), and the code does not make a sentence from parts of
// texts. The error code of the backend has one text for each code (the keys `error.code.<code>`; the unit test
// checks that the catalog has a text for each code of the contract).
export const en = {
  app: {
    title: 'SpecMgr Demo',
  },
  language: {
    label: 'Language',
    en: 'English',
    de: 'Deutsch',
  },
  status: {
    heading: 'System status',
    loading: 'The status is loading.',
    up: 'The system is up.',
    degraded: 'The system is degraded.',
    checkedAt: 'Checked at {{time}}',
  },
  error: {
    heading: 'The information is not available.',
    traceId: 'Trace identifier: {{traceId}}',
    network: 'The service cannot be reached.',
    timeout: 'The service did not answer in time.',
    invalid: 'The service gave an answer that the application does not understand.',
    code: {
      not_found: 'The information was not found.',
      method_not_allowed: 'The method of the request is not allowed.',
      not_acceptable: 'The format of the answer is not acceptable.',
      validation_failed: 'The request is not valid.',
      rate_limited: 'There are too many requests. Try again later.',
      internal_error: 'The service has an internal error.',
      service_unavailable: 'The service is not available.',
    },
  },
  info: {
    loading: 'The information of the service is loading.',
    version: 'Version {{version}}, commit {{commit}}',
    // The notice of the license (DEC 5ddd8d7a-5e7d-4a9b-860f-7d0b1f05579c). The values come from GET /info:
    // `copyright` is the text "Copyright 2026 Ronald Rink", `repository` is the address of the repository, and
    // `license` is the SPDX identifier. The sentence is: "Copyright 2026 Ronald Rink,
    // https://github.com/dfch/biz.dfch.SpecMgrDemo. Licensed under AGPL-3.0-only."
    notice: '{{copyright}}, {{repository}}. Licensed under {{license}}.',
  },
}

export type Catalog = typeof en
