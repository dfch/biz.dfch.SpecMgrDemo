import fc from 'fast-check'
import { it } from 'vitest'

// The case that is not successful for fast-check (feat-7-verification-architecture-tools, Task 110.130,
// ACC-002): a property that is wrong on purpose. The name has the part `broken`, so the normal run of
// vitest (vitest.config.ts) does not start it, and the committed run of the tests is green. The recipe
// test-random-frontend (tools/gates/test-random-frontend.sh) runs this file with the config
// vitest.config.negative.ts and stops for it: fast-check finds a counterexample of the property and
// reports it.
it('the property is wrong', () => {
  fc.assert(
    fc.property(fc.integer(), fc.integer(), (left, right) => {
      return left + right === 3
    }),
  )
})
