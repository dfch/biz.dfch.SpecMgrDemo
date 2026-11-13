import { describe, expect, it } from 'vitest'
import { errorCodeSchema } from '../generated/zod/errorCodeSchema'
import { problemSchema } from '../generated/zod/problemSchema'
import { statusSchema } from '../generated/zod/statusSchema'

// Unit tests of the generated Zod schemas with Vitest (feat-7-verification-architecture-tools, Task 110.110,
// ACC-002: the case that is successful). The module has no product code, so the tests exercise the
// generated code.
describe('the generated Zod schemas', () => {
  it('parses a valid status', () => {
    const parsed = statusSchema.safeParse({ state: 'up', checkedAt: '2026-11-09T12:00:00Z' })
    expect(parsed.success).toBe(true)
  })

  it('parses a status with the state degraded', () => {
    const parsed = statusSchema.safeParse({ state: 'degraded', checkedAt: '2026-11-09T12:00:00Z' })
    expect(parsed.success).toBe(true)
  })

  it('rejects a state that is not in the list', () => {
    const parsed = statusSchema.safeParse({ state: 'down', checkedAt: '2026-11-09T12:00:00Z' })
    expect(parsed.success).toBe(false)
  })

  it('has the five error codes of the contract', () => {
    expect([...errorCodeSchema.options].sort()).toEqual([
      'internal_error',
      'not_found',
      'rate_limited',
      'service_unavailable',
      'validation_failed',
    ])
  })

  it('parses a valid problem with a trace id', () => {
    const parsed = problemSchema.safeParse({
      type: 'https://example.invalid/not-found',
      title: 'Not found',
      status: 404,
      code: 'not_found',
      traceId: 'a'.repeat(32),
    })
    expect(parsed.success).toBe(true)
  })

  it('rejects a problem with a code that is not in the list', () => {
    const parsed = problemSchema.safeParse({ code: 'nope', traceId: 'a'.repeat(32) })
    expect(parsed.success).toBe(false)
  })
})
