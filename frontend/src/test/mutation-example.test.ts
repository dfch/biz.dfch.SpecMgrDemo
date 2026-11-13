import { describe, expect, it } from 'vitest'

import { countLetters, stateLabel } from '../mutation-example'

/**
 * feat-7-verification-architecture-tools, Phase 120 (the mutation tests, Task 120.110,
 * ACC-002).
 *
 * The test of the example for the mutation tests (src/mutation-example.ts, not product
 * code). The test is green and runs in the normal run (just test-unit-frontend). It
 * exercises countLetters weakly on purpose (one input, one state), so that at least one
 * mutant of the example survives for the recipe mutation-frontend: the mutant of the
 * logical operator in the condition of countLetters (and to or) keeps the result for the
 * input of the test.
 */
describe('the example for the mutation tests (feat-7, Phase 120)', () => {
  it('counts the lower case letters of one text', () => {
    expect(countLetters('ab')).toBe(2)
  })

  it('labels the state up', () => {
    expect(stateLabel('up')).toBe('UP')
  })
})
