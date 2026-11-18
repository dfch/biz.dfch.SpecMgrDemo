import { describe, expect, it } from 'vitest'
import { de } from '../i18n/de'
import { en } from '../i18n/en'
import { createI18n, detectLanguage, languages, type Language } from '../i18n/i18n'
import { errorCodeSchema } from '../generated/zod/errorCodeSchema'

// Unit tests of the i18n (feat-9-walking-skeleton, Phase 300, Task 300.120, ACC-004, DEC
// 51b00b5f-d1d8-49d8-9f40-28537ff69698): the two catalogs EN and DE have the same keys and a text for each
// error code of the contract, and the second language shows its own text.

/** The keys of a catalog as paths with dots (`status.up`). */
function keys(catalog: object, prefix = ''): string[] {
  return Object.entries(catalog).flatMap(([key, value]) =>
    typeof value === 'object' && value !== null ? keys(value, `${prefix}${key}.`) : [`${prefix}${key}`],
  )
}

const values = {
  copyright: 'Copyright 2026 Ronald Rink',
  repository: 'https://github.com/dfch/biz.dfch.SpecMgrDemo',
  license: 'AGPL-3.0-only',
}

describe('the catalogs of the i18n', () => {
  it('have the same keys in EN and DE', () => {
    expect(keys(de).sort()).toEqual(keys(en).sort())
  })

  it('have a text for each error code of the contract', () => {
    for (const code of errorCodeSchema.options) {
      for (const catalog of [en, de]) {
        expect(catalog.error.code[code], code).toBeTypeOf('string')
        expect(catalog.error.code[code].length, code).toBeGreaterThan(0)
      }
    }
    expect(Object.keys(en.error.code).sort()).toEqual([...errorCodeSchema.options].sort())
  })

  it('have no empty text, and a different text in DE for the texts that are not names', () => {
    for (const key of keys(en)) {
      const english = createI18n('en').t(key, { time: 't', traceId: 'i', version: 'v', commit: 'c', ...values })
      const german = createI18n('de').t(key, { time: 't', traceId: 'i', version: 'v', commit: 'c', ...values })
      expect(english.length, key).toBeGreaterThan(0)
      expect(german.length, key).toBeGreaterThan(0)
      if (!['app.title', 'language.en', 'language.de'].includes(key)) {
        expect(german, key).not.toBe(english)
      }
    }
  })

  it('give the notice of the license in EN, exactly as the DEC has it', () => {
    expect(createI18n('en').t('info.notice', values)).toBe(
      'Copyright 2026 Ronald Rink, https://github.com/dfch/biz.dfch.SpecMgrDemo. Licensed under AGPL-3.0-only.',
    )
  })

  it('give the notice of the license in the second language DE', () => {
    expect(createI18n('de').t('info.notice', values)).toBe(
      'Copyright 2026 Ronald Rink, https://github.com/dfch/biz.dfch.SpecMgrDemo. Lizenziert unter AGPL-3.0-only.',
    )
  })

  it('have the two languages EN and DE', () => {
    expect([...languages]).toEqual(['en', 'de'])
  })
})

describe('the instance of i18next', () => {
  it('does not escape the values (the address of the repository stays as it is)', () => {
    const raw = { copyright: 'A & B <c> "d"', repository: 'https://example.invalid/a?b=1&c=2', license: "it's" }
    expect(createI18n('en').t('info.notice', raw)).toBe(`${raw.copyright}, ${raw.repository}. Licensed under ${raw.license}.`)
  })

  it('has the text at once (the catalogs are in the bundle) and takes EN for a language that has no catalog', () => {
    const instance = createI18n('de')
    expect(instance.isInitialized).toBe(true)
    expect(instance.language).toBe('de')
    expect(createI18n('fr' as Language).t('status.up')).toBe('The system is up.')
  })

  it('makes an instance that has no state in common with another instance', () => {
    const english = createI18n('en')
    const german = createI18n('de')
    expect(english.t('status.up')).toBe('The system is up.')
    expect(german.t('status.up')).toBe('Das System läuft.')
    expect(english.t('status.up')).toBe('The system is up.')
  })
})

describe('the choice of the language', () => {
  it('takes the first language tag of the browser that has a catalog', () => {
    expect(detectLanguage(['de-CH', 'en-US'])).toBe('de')
    expect(detectLanguage(['fr-FR', 'DE'])).toBe('de')
    expect(detectLanguage(['en-GB'])).toBe('en')
  })

  it('takes EN if no tag has a catalog', () => {
    expect(detectLanguage(['fr-FR', 'it'])).toBe('en')
    expect(detectLanguage([])).toBe('en')
  })
})
