import { defineConfig } from 'vitest/config'

// The coverage run of the pnpm module (feat-7-verification-architecture-tools, Task 140.110). The test
// set is the normal one (the include and the exclude of vitest.config.ts, the files with the part
// `broken` are the cases that are not successful and are not in the run), and the coverage provider
// is @vitest/coverage-v8 (the pinned version, the same line as vitest). The coverage is over the
// SOURCE files of the module (REQ-006): the generated code (the folders src/generated/types and
// src/generated/zod), the example file src/mutation-example.ts, and the product code of the walking skeleton
// that has no DOM and no React: the folders src/client, src/i18n and src/telemetry (feat-9-walking-skeleton, review
// N7; the folder src/ui and the entry point src/main.tsx are not in the set, as in stryker.config.json). The test files (src/test/) are
// not source files of the module, so they are excluded (the default excludes of vitest keep them
// out of the test run, and the include set below names the source files explicitly). The config has
// no thresholds: the recipe makes the report and prints the numbers, and no failure comes from a
// coverage percentage (REQ-006, the walking skeleton sets the threshold from the measured baseline).
export default defineConfig({
  test: {
    environment: 'node',
    include: ['src/test/**/*.test.{ts,tsx}'],
    exclude: ['src/test/**/broken*.test.ts', '**/node_modules/**'],
    coverage: {
      provider: 'v8',
      include: [
        'src/generated/**/*.ts',
        'src/mutation-example.ts',
        'src/client/**/*.ts',
        'src/i18n/**/*.ts',
        'src/telemetry/**/*.ts',
      ],
      exclude: ['src/test/**'],
      reporters: ['text', 'html'],
    },
  },
})
