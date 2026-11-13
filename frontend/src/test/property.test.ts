import fc from 'fast-check'
import { describe, expect, it } from 'vitest'
import { statusSchema } from '../generated/zod/statusSchema'

// Property tests of the generated Zod schemas with fast-check (feat-7-verification-architecture-tools,
// Task 110.130, ACC-002: the case that is successful).

// A time in the ISO form, from its parts: a year with four digits (the ISO profile of the schema,
// z.iso.datetime, has four digits for the year), a day that is in every month (1 to 28), and the parts
// of the hour. The date is made with Date.UTC, so it is valid for each value.
const isoDateTime = fc
  .tuple(
    fc.integer({ min: 1970, max: 2999 }),
    fc.integer({ min: 1, max: 12 }),
    fc.integer({ min: 1, max: 28 }),
    fc.integer({ min: 0, max: 23 }),
    fc.integer({ min: 0, max: 59 }),
    fc.integer({ min: 0, max: 59 }),
  )
  .map(
    ([year, month, day, hour, minute, second]) =>
      new Date(Date.UTC(year, month - 1, day, hour, minute, second)).toISOString(),
  )

// A status that the generator gives: a state of the list and a time in the ISO form.
const validStatus = fc.record({
  state: fc.constantFrom('up', 'degraded'),
  checkedAt: isoDateTime,
})

// A small function of the test: it keeps only the lower case letters.
const onlyLowerLetters = (text: string): string => text.replace(/[^a-z]/g, '')

describe('properties of the generated schemas', () => {
  it('parses each status the generator gives', () => {
    fc.assert(
      fc.property(validStatus, value => {
        expect(statusSchema.safeParse(value).success).toBe(true)
      }),
    )
  })

  it('rejects a state that is not up or degraded', () => {
    fc.assert(
      fc.property(fc.string(), bad => {
        fc.pre(bad !== 'up' && bad !== 'degraded')
        expect(statusSchema.safeParse({ state: bad, checkedAt: '2026-11-09T12:00:00Z' }).success).toBe(false)
      }),
    )
  })

  it('keeps only the lower case letters, and does it once', () => {
    fc.assert(
      fc.property(fc.string(), text => {
        const once = onlyLowerLetters(text)
        expect(/^[a-z]*$/.test(once)).toBe(true)
        expect(onlyLowerLetters(once)).toBe(once)
      }),
    )
  })
})
