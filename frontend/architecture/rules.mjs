#!/usr/bin/env node
/**
 * The architecture rules of the frontend with ArchUniTS (feat-7-verification-architecture-tools,
 * Task 130.110, REQ-003; DEC 9edc1071-4fd0-48b6-a037-1a4cb2331f73: "ArchUniTS examines the layers
 * and the imports in the frontend"). The case that is successful (ACC-002): the run of this script
 * is green on the committed code, and the recipe architecture-frontend asserts it.
 *
 * Usage: node rules.mjs [<frontend dir>]
 *   <frontend dir>  the folder of the pnpm module (default: the parent of this script's folder)
 *
 * The units of the frontend (the rule of thumb of the task, documented in the plan): a unit is a
 * folder that contains TypeScript source - the top-level folders of frontend/src (today: test),
 * the folders of frontend/src/generated (today: types and zod), and the files that lie directly in
 * frontend/src (the unit root). The name of a unit is the identifier of its component in the model
 * (the rule of DEC 9edc1071).
 *
 * The rules (the successful case; the directions the code has):
 *   R1'  the module structure, the slice form of ArchUniTS: the unit generated has no dependency on
 *        the unit test (projectSlices, the pattern src/(**)). The part of the structure that is a
 *        closed set (exactly these units, no more, no less) is not possible with ArchUniTS (the
 *        examination of the maturity is in the plan, ACC-006): the model comparison of the recipe
 *        architecture-model checks it (the units are discovered from the files of the code, and a
 *        unit that is not in the model stops the comparison).
 *   R2'  the layer rule (the frontend counterpart of R2 of the backend): the layers of the
 *        generated code (types and zod) do not depend on the layer of the tests. The direction of
 *        the code is test -> generated (the tests import the generated code, and the generated
 *        code imports no file of the tests).
 *   R3'  the imports rule: the generated code does not import from the unit root (the files that
 *        lie directly in frontend/src). The imports of the generated code are inside the unit and
 *        to the external package zod, and not to a file of the module.
 *
 * A rule whose pattern has no file is not green (the option allowEmptyTests of the check is false
 * by default, and the check gives the violation No files found matching pattern(s)): a unit that
 * disappears stops the run.
 *
 * The violated rule (the case that is not successful, ACC-002) is the script rules.broken.mjs (the
 * recipe runs it separately and stops for it): the test unit must not depend on the generated unit
 * zod - the opposite direction of R2' - and the code violates it (the test files import the
 * generated Zod schemas, and the imports are named in the report).
 *
 * Exit code 0: the rules are green. Exit code 1: a rule has a violation (the violations are
 * printed, and the recipe asserts them). Exit code 2: an error of the run (the tsconfig, the
 * install).
 */

import { dirname, join, resolve } from 'node:path'
import { fileURLToPath } from 'node:url'
import { projectFiles, projectSlices } from 'archunit'

const here = dirname(fileURLToPath(import.meta.url))
const frontendDir = resolve(process.argv[2] ?? join(here, '..'))
const tsconfig = join(frontendDir, 'tsconfig.json')

const rules = [
  {
    name: "R1' the module structure (the slice form): the unit generated has no dependency on the unit test",
    checkable: projectSlices(tsconfig).definedBy('src/(**)').shouldNot().containDependency('generated', 'test'),
  },
  {
    name: "R2' the layer rule: the layers of the generated code (types and zod) do not depend on the layer of the tests",
    checkable: projectFiles(tsconfig).inFolder('src/generated/**').shouldNot().dependOnFiles().inFolder('src/test/**'),
  },
  {
    name: "R3' the imports rule: the generated code does not import from the unit root (the files that lie directly in src/)",
    checkable: projectFiles(tsconfig).inFolder('src/generated/**').shouldNot().dependOnFiles().inPath('src/*.ts'),
  },
]

try {
  process.chdir(frontendDir)
  let failed = false
  for (const rule of rules) {
    const violations = await rule.checkable.check()
    if (violations.length === 0) {
      console.log(`ok   ${rule.name}: no violation`)
    } else {
      failed = true
      console.error(`FAIL ${rule.name}: ${violations.length} violation(s)`)
      for (const violation of violations) {
        const dependency = violation.dependency ?? violation.projectedEdge
        if (dependency !== undefined) {
          console.error(`     | ${dependency.sourceLabel} -> ${dependency.targetLabel}`)
        } else {
          console.error(`     | ${violation.message ?? JSON.stringify(violation)}`)
        }
      }
    }
  }
  if (failed) {
    process.exit(1)
  }
  console.log(`PASS the architecture rules of the frontend are green (${rules.length} rule(s), ArchUniTS)`)
} catch (error) {
  console.error(`FAIL the run of the architecture rules stopped: ${error?.message ?? error}`)
  process.exit(2)
}
