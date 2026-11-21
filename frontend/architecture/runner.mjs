#!/usr/bin/env node
/**
 * The runner of the rules the model gives, the frontend side (feat-50-structurizr-model-rules,
 * Task 130.120, REQ-004, ACC-005; the canonical form is the section "The rules the model gives" of
 * model/README.md; DEC e85e9685-0787-4dff-9ee5-9d46670e9ee4). This script replaces the hard-coded
 * rules R1', R2' and R3' of feat-7-verification-architecture-tools (the script rules.mjs, removed in
 * Task 130.140; the case that is not successful of the rules comes back in Phase 140, the Broken*
 * pattern, ACC-006).
 *
 * Usage: node runner.mjs [<frontend dir>] [<workspace file>]
 *   <frontend dir>    the folder of the pnpm module (default: the parent of this script's folder)
 *   <workspace file>  the file of the workspace (default: <frontend dir>/../model/workspace.json)
 *
 * The rules (derived from the model at run time, per the canonical section): for the container
 * frontend, one check per forbidden dependency (every ordered pair of distinct mapped components
 * that has no relation in the model; today: 41 pairs) and one cycle rule (no dependency cycle among
 * the mapped components, the viewpoint development of Rozanski & Woods): 42 derived rules today.
 * The reading of the workspace and the derivation are the shared module workspace.mjs (the
 * same rule set that the comparison compare.mjs uses, so the two cannot drift apart).
 *
 * The checks of ArchUniTS: the files of the source component (the pattern of the type RegExp of the
 * entries of code.path, the form of the spike of Phase 100: a folder entry with the folder suffix
 * matches the files of the folder at each depth, and a file entry matches the file) should not
 * depend on the files of the destination component. The cycle rule: the files of all the mapped
 * components (the union of the patterns) have no cycle (the construct haveNoCycles of ArchUniTS).
 * The project view the checks examine (the TypeScript program and the file graph of the module)
 * is built once for all the derived rules, and not once per rule (the construct extractGraph of
 * ArchUniTS, and the projection of the edges of the graph, perEdge for the forbidden pairs and
 * perInternalEdge for the cycle rule): the check of one rule is the narrowing of the rule on the
 * shared view (the gathers of the violations, the bodies of the constructs dependOnFiles and
 * haveNoCycles of ArchUniTS, with the same filters and the same options that the fluent API of
 * ArchUniTS gives), and the cost of one rule is the check itself.
 * A violation names the imports (the source file and the target file of each dependency, as the
 * rules.mjs of feat-7). A rule whose pattern has no file is not green (the option allowEmptyTests
 * of the check is false by default, and the check gives the violation No files found matching
 * pattern(s)): a unit that disappears stops the run.
 *
 * The limit of the parity (the section of model/README.md, and the language skew of DEC
 * e85e9685): ArchUniTS does not examine a closed set of units (a new unit that the code adds is
 * invisible to the rules; the comparison compare.mjs examines it, the files discovered from the
 * code), and the graph of ArchUniTS has no edge to the external packages (the folder node_modules
 * is excluded): the check of code.allowedExternal (group 4 of the canonical section) is in the
 * comparison, and not in the runner. The dynamic import() and the require() are invisible to
 * ArchUniTS (the table of the DEC); the comparison reads them (the fix of Task 130.130).
 *
 * Exit code 0: the rules are green. Exit code 1: a rule has a violation (the violations are
 * printed, and the recipe asserts them). Exit code 2: an error of the run (the workspace, the
 * tsconfig, the install).
 */

import { dirname, join, resolve } from 'node:path'
import { fileURLToPath } from 'node:url'
import { RegexFactory, extractGraph, gatherCycleViolations, gatherDependOnFileViolations, perEdge, perInternalEdge, projectEdges } from 'archunit'
import { allMappedRegExp, componentRegExp, deriveFrontend, forbiddenPairs, readWorkspace } from './workspace.mjs'

const here = dirname(fileURLToPath(import.meta.url))
const frontendDir = resolve(process.argv[2] ?? join(here, '..'))
const workspacePath = resolve(process.argv[3] ?? join(frontendDir, '..', 'model', 'workspace.json'))
const tsconfig = join(frontendDir, 'tsconfig.json')

// The rule set the model gives for the container frontend (the shared module workspace.mjs).
const derived = deriveFrontend(readWorkspace(workspacePath))
const pairs = forbiddenPairs(derived)

// The filters of one rule: the same pathMatcher filters that the fluent API of ArchUniTS makes
// for the construct inPath (the pattern of the type RegExp of the entries of code.path, the
// shared module workspace.mjs).
const pathFilter = (regExp) => RegexFactory.pathMatcher(regExp)

// The check of one rule is the narrowing of the rule on the shared project view (built once in
// the run below): the gathers are the bodies of the constructs of ArchUniTS, with the same
// arguments the fluent API gives for the check without options (the option isNegated true: the
// files of the source component should NOT depend on the files of the destination component, the
// option allowEmptyTests false: a rule whose pattern has no file is not green).
const rules = pairs.map(([source, destination]) => ({
  name: `the component ${source} must not depend on the component ${destination} (the model gives no relation ${source} -> ${destination})`,
  check: (view) =>
    gatherDependOnFileViolations(
      view.edges,
      [pathFilter(componentRegExp(derived.components.get(source).paths))],
      [pathFilter(componentRegExp(derived.components.get(destination).paths))],
      true,
      false,
    ),
}))
rules.push({
  name: 'the mapped components of the container frontend have no dependency cycle',
  check: (view) => gatherCycleViolations(view.internalEdges, [pathFilter(allMappedRegExp(derived))], undefined),
})

console.log(`ok   the model gives ${pairs.length} forbidden pair(s) and 1 cycle rule for the container frontend (${rules.length} rule(s))`)

try {
  process.chdir(frontendDir)
  // The shared project view, built once for all the derived rules (and not once per rule): the
  // graph of the TypeScript program and the file graph of the module (the construct extractGraph
  // of ArchUniTS), and the projection of the edges the rules examine (perEdge, the edges of the
  // graph, for the forbidden pairs; perInternalEdge, the internal edges, for the cycle rule).
  // The check of one rule is the narrowing of the rule on the view (the gather in the check of
  // the rule), and the cost of one rule is the check itself.
  const graph = await extractGraph(tsconfig)
  const view = {
    edges: projectEdges(graph, perEdge()),
    internalEdges: projectEdges(graph, perInternalEdge()),
  }
  let failed = false
  for (const rule of rules) {
    const violations = rule.check(view)
    if (violations.length === 0) {
      console.log(`ok   ${rule.name}: no violation`)
    } else {
      failed = true
      console.error(`FAIL ${rule.name}: ${violations.length} violation(s)`)
      for (const violation of violations) {
        const dependency = violation.dependency ?? violation.projectedEdge
        if (dependency !== undefined) {
          console.error(`     | ${dependency.sourceLabel} -> ${dependency.targetLabel}`)
        } else if (violation.cycle !== undefined) {
          for (const edge of violation.cycle) {
            console.error(`     | ${edge.sourceLabel} -> ${edge.targetLabel}`)
          }
        } else {
          console.error(`     | ${violation.message ?? JSON.stringify(violation)}`)
        }
      }
    }
  }
  if (failed) {
    process.exit(1)
  }
  console.log(`PASS the rules the model gives (the container frontend) are green (${rules.length} rule(s), ArchUniTS)`)
} catch (error) {
  console.error(`FAIL the run of the rules stopped: ${error?.message ?? error}`)
  process.exit(2)
}
