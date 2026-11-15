#!/usr/bin/env node
/**
 * The case that is not successful of the architecture rules of the frontend with ArchUniTS
 * (feat-7-verification-architecture-tools, Task 130.110, ACC-002; the successful rules are in
 * rules.mjs). The recipe architecture-frontend runs this script separately and stops for it: the
 * run of the script gives exit code 1 (the rule has a violation), and the recipe gives exit code 0.
 *
 * Usage: node rules.broken.mjs [<frontend dir>]
 *   <frontend dir>  the folder of the pnpm module (default: the parent of this script's folder)
 *
 * The rule: the unit test must not depend on the generated unit zod - the opposite direction of R2'
 * (the layer rule: the generated code does not depend on the tests, and the direction of the code
 * is test -> generated). The code violates the rule deterministically: the test files of
 * frontend/src/test import the generated Zod schemas (property.test.ts imports statusSchema.ts,
 * and status-schema.test.ts imports errorCodeSchema.ts, problemSchema.ts and statusSchema.ts).
 * ArchUniTS names the violating imports in the report of the check (the source file and the
 * target file of each dependency).
 *
 * The script stops (exit code 1) also if the rule has no violation (the violated rule must be
 * violated, and a rule that passes silently would hide a change of the code). Exit code 2: an
 * error of the run.
 */

import { dirname, join, resolve } from 'node:path'
import { fileURLToPath } from 'node:url'
import { projectFiles } from 'archunit'

const here = dirname(fileURLToPath(import.meta.url))
const frontendDir = resolve(process.argv[2] ?? join(here, '..'))
const tsconfig = join(frontendDir, 'tsconfig.json')

try {
  process.chdir(frontendDir)
  const rule = projectFiles(tsconfig)
    .inFolder('src/test/**')
    .shouldNot()
    .dependOnFiles()
    .inFolder('src/generated/zod/**')
  const violations = await rule.check()
  if (violations.length === 0) {
    console.error('FAIL the violated rule has no violation (the code does not import the generated Zod schemas any more). The rule must be violated for the demonstration of the case that is not successful (ACC-002)')
    process.exit(1)
  }
  console.log(`ok   the violated rule has ${violations.length} violation(s): the unit test depends on the generated unit zod (the direction the code has)`)
  for (const violation of violations) {
    const dependency = violation.dependency
    if (dependency !== undefined) {
      console.log(`     | ${dependency.sourceLabel} -> ${dependency.targetLabel}`)
    }
  }
  // The exit code 1 is the result the recipe expects for the violated rule (the tool reports the
  // violations, and the recipe stops for them).
  process.exit(1)
} catch (error) {
  console.error(`FAIL the run of the violated rule stopped: ${error?.message ?? error}`)
  process.exit(2)
}
