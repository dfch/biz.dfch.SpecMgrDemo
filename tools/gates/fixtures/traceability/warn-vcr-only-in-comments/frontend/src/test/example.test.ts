import { describe, expect, it } from 'vitest'

/* A block comment over some lines.
   The lines do not start with a star, and one has a quote ".
   vcr:33333333-3333-4333-8333-333333333333
*/
describe('the status schema', () => { // vcr:33333333-3333-4333-8333-333333333333
  it('parses a status', () => {
    expect(true).toBe(true) // "vcr:33333333-3333-4333-8333-333333333333"
  })
})
