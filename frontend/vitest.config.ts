import { defineConfig } from 'vitest/config'

// The unit tests of the pnpm module (feat-7-verification-architecture-tools, Task 110.110). The tests
// run in the node environment (no DOM is necessary: they exercise the generated Zod schemas). The files
// with the part `broken` in the name are the cases that are not successful (ACC-002): the normal run skips
// them, and the recipe test-unit-frontend starts them with vitest.config.negative.ts and stops for them.
export default defineConfig({
  test: {
    environment: 'node',
    include: ['src/test/**/*.test.ts'],
    exclude: ['src/test/**/broken*.test.ts', '**/node_modules/**'],
  },
})
