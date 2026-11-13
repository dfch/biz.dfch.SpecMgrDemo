import { defineConfig } from 'vitest/config'

// The cases that are not successful (feat-7-verification-architecture-tools, ACC-002): the files with the
// part `broken` in the name (the wrong assertion of Vitest and the wrong property of fast-check). The normal
// run (vitest.config.ts) skips them, and the recipes test-unit-frontend and test-random-frontend start this
// config (with a file argument for one of the two files) and stop for it.
export default defineConfig({
  test: {
    environment: 'node',
    include: ['src/test/**/*.broken.test.ts'],
    exclude: ['**/node_modules/**'],
  },
})
