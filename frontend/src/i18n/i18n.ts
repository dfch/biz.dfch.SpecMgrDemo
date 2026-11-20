import { createInstance, type i18n } from 'i18next'
import { initReactI18next } from 'react-i18next'
import { de } from './de'
import { en } from './en'

// The i18n of the user interface (feat-9-walking-skeleton, Phase 300, Task 300.120, DEC
// 51b00b5f-d1d8-49d8-9f40-28537ff69698): i18next with react-i18next, and the two catalogs EN and DE (one file
// for each language). EN is the default and the fallback. Each call of createI18n makes its own instance (no
// global state), so a test can show the text of the second language next to the first.

/** The languages that have a full catalog. */
export const languages = ['en', 'de'] as const
export type Language = (typeof languages)[number]

/** The language for a language tag of the browser (for example `de-CH`): the first tag that has a catalog, or EN. */
export function detectLanguage(tags: readonly string[]): Language {
  for (const tag of tags) {
    const primary = tag.toLowerCase().split('-')[0]
    const found = languages.find((language) => language === primary)
    if (found !== undefined) {
      return found
    }
  }
  return 'en'
}

/**
 * Make an instance of i18next that is initialized (synchronously: the catalogs are in the bundle) with the
 * language.
 *
 * `escapeValue` is off because React escapes the text it shows. The values (for example the address of the
 * repository) must stay as they are.
 */
export function createI18n(language: Language): i18n {
  const instance = createInstance()
  void instance.use(initReactI18next).init({
    resources: { en: { translation: en }, de: { translation: de } },
    lng: language,
    fallbackLng: 'en',
    supportedLngs: [...languages],
    interpolation: { escapeValue: false },
    initAsync: false,
  })
  return instance
}
