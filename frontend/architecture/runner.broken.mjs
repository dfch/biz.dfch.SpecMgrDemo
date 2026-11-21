#!/usr/bin/env node
/**
 * The case that is not successful of the forbidden dependencies (the rule category of group 1 of
 * the canonical section; feat-50-structurizr-model-rules, Task 140.110, REQ-007, ACC-006; the
 * canonical form is the section "The rules the model gives" of model/README.md; DEC
 * e85e9685-0787-4dff-9ee5-9d46670e9ee4). The recipe architecture-frontend runs this script
 * separately and stops for it: the run of the script gives exit code 1 (the rules have
 * violations), and the recipe gives exit code 0.
 *
 * Usage: node runner.broken.mjs [<frontend dir>] [<workspace file>]
 *   <frontend dir>    the folder of the pnpm module (default: the parent of this script's folder)
 *   <workspace file>  the file of the workspace (default: <frontend dir>/../model/workspace.json)
 *
 * The checks are derived, and not hard-coded (the same reading and the same derivation as the
 * runner runner.mjs, the shared module workspace.mjs): the script reads the workspace, takes the
 * relations of the model between the mapped components of the container frontend (today: the 15
 * modelled relations, for example test -> zod and test -> root), and builds for each of them the
 * check of ArchUniTS that FORBIDS it (for example the component test must not depend on the
 * component zod, and the component test must not depend on the component root). The code has the
 * direction of each modelled relation (the other direction of the closed world of the comparison
 * compare.mjs: a relation of the model without the dependency of the code stops the run), so each
 * check is violated deterministically, and ArchUniTS names the violating imports in the report
 * (the source file and the target file of each dependency, as the script rules.broken.mjs of
 * feat-7 demonstrated for the relation test -> zod: the four imports of the test files to the
 * generated Zod schemas, and the one import of the test file to the file of the unit root).
 *
 * The script stops (exit code 1) also if a modelled relation has no violation in the code (the
 * case that is not successful that passes silently would hide a change of the code, the form of
 * the old script rules.broken.mjs), and if the model has no relation between the mapped
 * components (the case cannot be demonstrated; no silent pass). The checks that the model gives
 * for the pairs that have no relation (the runner runner.mjs) stay green on the committed code,
 * and the case that is not successful of the cycle rule (group 2 of the canonical section) is the
 * temporary copy of the recipe architecture-frontend (the part 3; the committed code has no
 * cycle, and the scratch files of the copy make it).
 *
 * Exit code 1: the violated rules have a violation (the expected result of this script, the
 * violations are printed, and the recipe asserts them), or the case cannot be demonstrated (the
 * message names it). Exit code 2: an error of the run (the workspace, the tsconfig, the install).
 */

import { dirname, join, resolve } from 'node:path'
import { fileURLToPath } from 'node:url'
import { projectFiles } from 'archunit'
import { componentRegExp, deriveFrontend, readWorkspace } from './workspace.mjs'

const here = dirname(fileURLToPath(import.meta.url))
const frontendDir = resolve(process.argv[2] ?? join(here, '..'))
const workspacePath = resolve(process.argv[3] ?? join(frontendDir, '..', 'model', 'workspace.json'))
const tsconfig = join(frontendDir, 'tsconfig.json')

// The rule set the model gives for the container frontend (the shared module workspace.mjs).
const derived = deriveFrontend(readWorkspace(workspacePath))
// The relations of the model between the mapped components of the container frontend (the
// strings "source -> destination", the sorted order for the deterministic report).
const modelled = [...derived.relations].sort()
if (modelled.length === 0) {
  console.error('FAIL the container frontend has no relation between the mapped components (the model gives no direction that the code has). The case that is not successful cannot be demonstrated (exit code 1)')
  process.exit(1)
}

try {
  process.chdir(frontendDir)
  for (const relation of modelled) {
    const [source, destination] = relation.split(' -> ')
    const checkable = projectFiles(tsconfig)
      .inPath(componentRegExp(derived.components.get(source).paths))
      .shouldNot()
      .dependOnFiles()
      .inPath(componentRegExp(derived.components.get(destination).paths))
    const violations = await checkable.check()
    if (violations.length === 0) {
      console.error(`FAIL the modelled relation ${source} -> ${destination} has no violation in the code (the case that is not successful would pass silently, and a change of the code or of the model would hide). The violated rule must be violated (exit code 1)`)
      process.exit(1)
    }
    console.log(`ok   the violated rule has ${violations.length} violation(s): the component ${source} depends on the component ${destination} (the direction the code has)`)
    for (const violation of violations) {
      const dependency = violation.dependency
      if (dependency !== undefined) {
        console.log(`     | ${dependency.sourceLabel} -> ${dependency.targetLabel}`)
      }
    }
  }
  // The exit code 1 is the result the recipe expects for the violated rules (the tool reports
  // the violations, and the recipe stops for them).
  process.exit(1)
} catch (error) {
  console.error(`FAIL the run of the violated rules stopped: ${error?.message ?? error}`)
  process.exit(2)
}
