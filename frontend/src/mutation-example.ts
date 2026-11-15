/**
 * feat-7-verification-architecture-tools, Phase 120 (the mutation tests, Task 120.110).
 *
 * The example for the mutation tests, not product code: the module has no product code.
 * Stryker (the recipe mutation-frontend) mutates this file and the generated Zod schemas
 * (the scope is in stryker.config.json). The test src/test/mutation-example.test.ts
 * exercises countLetters weakly on purpose (one input), so that at least one mutant of
 * this file survives (ACC-002: the tool finds a problem, the recipe asserts it).
 */

/**
 * Count the lower case letters (a to z) of the text.
 */
export function countLetters(text: string): number {
  let count = 0
  for (const char of text) {
    if (char >= 'a' && char <= 'z') {
      count = count + 1
    }
  }
  return count
}

/**
 * The label of the state of the system (the values of the state are in the generated Zod
 * schema of the status: up and degraded).
 */
export function stateLabel(state: string): string {
  if (state === 'up') {
    return 'UP'
  }
  return 'OTHER'
}
