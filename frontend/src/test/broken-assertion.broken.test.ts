import { expect, it } from 'vitest'

// The case that is not successful for Vitest (feat-7-verification-architecture-tools, Task 110.110,
// ACC-002): an assertion that is wrong on purpose. The name has the part `broken`, so the normal run of
// vitest (vitest.config.ts) does not start it, and the committed run of the tests is green. The recipe
// test-unit-frontend (tools/gates/test-unit-frontend.sh) runs this file with the config
// vitest.config.negative.ts and stops for it: Vitest reports the failed assertion.
it('the assertion is wrong', () => {
  expect(1 + 1).toBe(3)
})
