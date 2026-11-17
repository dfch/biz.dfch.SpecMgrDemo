#!/usr/bin/env node
/**
 * Task 120.100 (REQ-003): make the architecture rules from the model (feat-0-demoprep).
 *
 * Usage: node 120-100-00-generate-rules.mjs [<exported workspace.json>] [<output dir>]
 *   default input:  build/json/workspace.json (made by 100-110-00-validate-model.sh)
 *   default output: generated/
 *
 * The rule (closed world): the model lists the allowed dependencies between the components of one container (the arrows).
 * Each ordered pair of components of the same container without an arrow is a forbidden dependency. The components are
 * mapped to the code by the properties `code.package` (Java) and `code.path` (TypeScript), and not by the name.
 *
 * Output:
 *   ModelRulesTest.java   ArchUnit, one @ArchTest rule for each forbidden pair of the backend
 *   rules.model.mjs       ArchUniTS, one rule for each forbidden pair of the frontend
 * The output has no time value, so two runs make the same files.
 */
import { readFileSync, mkdirSync, writeFileSync } from 'node:fs'
import { dirname, join, resolve } from 'node:path'
import { fileURLToPath } from 'node:url'

const here = dirname(fileURLToPath(import.meta.url))
const featDir = resolve(here, '..')
const input = resolve(process.argv[2] ?? join(featDir, 'build/json/workspace.json'))
const outDir = resolve(process.argv[3] ?? join(featDir, 'generated'))
const model = JSON.parse(readFileSync(input, 'utf8')).model

const byId = new Map()
const containers = []
for (const system of model.softwareSystems ?? []) {
  for (const container of system.containers ?? []) {
    const components = (container.components ?? []).map((c) => ({ ...c, container: container.name }))
    components.forEach((c) => byId.set(c.id, c))
    containers.push({ ...container, components })
  }
}

function forbiddenPairs(container) {
  const allowed = new Set()
  for (const c of container.components) {
    for (const r of c.relationships ?? []) allowed.add(`${c.id}>${r.destinationId}`)
  }
  const pairs = []
  for (const from of container.components) {
    for (const to of container.components) {
      if (from.id !== to.id && !allowed.has(`${from.id}>${to.id}`)) pairs.push({ from, to })
    }
  }
  return pairs
}

const constant = (s) => s.toUpperCase().replace(/[^A-Z0-9]+/g, '_')
const header = `Made by bin/120-100-00-generate-rules.mjs from the model (model/workspace.dsl, feat-0-demoprep). Do not change by hand.`
let java = null
let mjs = null

for (const container of containers) {
  const language = container.properties?.['code.language']
  const pairs = forbiddenPairs(container)
  const allowedCount = container.components.reduce((n, c) => n + (c.relationships?.length ?? 0), 0)
  const summary = `${container.name}: ${container.components.length} components, ${allowedCount} arrows, ${pairs.length} forbidden pairs`
  console.log(summary)

  if (language === 'java') {
    const rules = pairs.map(({ from, to }) => {
      const a = from.properties['code.package']
      const b = to.properties['code.package']
      return `  @ArchTest
  static final ArchRule ${constant(from.name)}_MUST_NOT_DEPEND_ON_${constant(to.name)} =
      noClasses()
          .that()
          .resideInAPackage("${a}..")
          .should()
          .dependOnClassesThat()
          .resideInAPackage("${b}..")
          .because("the model has no arrow from ${from.name} to ${to.name} (container ${container.name}, feat-0-demoprep)");
`
    })
    java = `package biz.dfch.specmgrdemo.architecture;

import static com.tngtech.archunit.lang.syntax.ArchRuleDefinition.noClasses;

import com.tngtech.archunit.junit.AnalyzeClasses;
import com.tngtech.archunit.junit.ArchTest;
import com.tngtech.archunit.lang.ArchRule;

/**
 * ${header}
 * ${summary}.
 */
@AnalyzeClasses(packages = "biz.dfch.specmgrdemo")
class ModelRulesTest {

${rules.join('\n')}}
`
  } else if (language === 'typescript') {
    const folder = (c) => c.properties['code.path'].replace(/^frontend\//, '')
    const isFile = (c) => c.properties['code.path'].includes('*')
    const select = (c) => (isFile(c) ? `.inPath('${folder(c)}')` : `.inFolder('${folder(c)}/**')`)
    const rules = pairs.map(({ from, to }) => `  {
    name: "the model has no arrow ${from.name} -> ${to.name}: the unit ${from.name} does not depend on the unit ${to.name}",
    checkable: projectFiles(tsconfig)${select(from)}.shouldNot().dependOnFiles()${select(to)},
  },`)
    mjs = `#!/usr/bin/env node
/**
 * ${header}
 * ${summary}.
 *
 * Usage: node rules.model.mjs [<frontend dir>]
 * Exit code 0: green. Exit code 1: a rule has a violation. Exit code 2: an error of the run.
 */
import { dirname, join, resolve } from 'node:path'
import { fileURLToPath } from 'node:url'
import { projectFiles } from 'archunit'

const here = dirname(fileURLToPath(import.meta.url))
const frontendDir = resolve(process.argv[2] ?? join(here, '..'))
const tsconfig = join(frontendDir, 'tsconfig.json')

const rules = [
${rules.join('\n')}
]

try {
  process.chdir(frontendDir)
  let failed = false
  for (const rule of rules) {
    const violations = await rule.checkable.check()
    if (violations.length === 0) {
      console.log(\`ok   \${rule.name}\`)
    } else {
      failed = true
      console.error(\`FAIL \${rule.name}: \${violations.length} violation(s)\`)
      for (const v of violations) {
        const d = v.dependency ?? v.projectedEdge
        console.error(\`     | \${d !== undefined ? \`\${d.sourceLabel} -> \${d.targetLabel}\` : (v.message ?? JSON.stringify(v))}\`)
      }
    }
  }
  if (failed) process.exit(1)
  console.log(\`PASS the rules of the model are green (\${rules.length} rule(s), ArchUniTS)\`)
} catch (error) {
  console.error(\`FAIL the run stopped: \${error?.message ?? error}\`)
  process.exit(2)
}
`
  }
}

mkdirSync(outDir, { recursive: true })
if (java) writeFileSync(join(outDir, 'ModelRulesTest.java'), java)
if (mjs) writeFileSync(join(outDir, 'rules.model.mjs'), mjs)
console.log(`Written to ${outDir}`)
