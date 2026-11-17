#!/usr/bin/env node
/**
 * Made by bin/120-100-00-generate-rules.mjs from the model (model/workspace.dsl, feat-0-demoprep). Do not change by hand.
 * frontend: 8 components, 15 arrows, 41 forbidden pairs.
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
  {
    name: "the model has no arrow types -> zod: the unit types does not depend on the unit zod",
    checkable: projectFiles(tsconfig).inFolder('src/generated/types/**').shouldNot().dependOnFiles().inFolder('src/generated/zod/**'),
  },
  {
    name: "the model has no arrow types -> client: the unit types does not depend on the unit client",
    checkable: projectFiles(tsconfig).inFolder('src/generated/types/**').shouldNot().dependOnFiles().inFolder('src/client/**'),
  },
  {
    name: "the model has no arrow types -> i18n: the unit types does not depend on the unit i18n",
    checkable: projectFiles(tsconfig).inFolder('src/generated/types/**').shouldNot().dependOnFiles().inFolder('src/i18n/**'),
  },
  {
    name: "the model has no arrow types -> telemetry: the unit types does not depend on the unit telemetry",
    checkable: projectFiles(tsconfig).inFolder('src/generated/types/**').shouldNot().dependOnFiles().inFolder('src/telemetry/**'),
  },
  {
    name: "the model has no arrow types -> ui: the unit types does not depend on the unit ui",
    checkable: projectFiles(tsconfig).inFolder('src/generated/types/**').shouldNot().dependOnFiles().inFolder('src/ui/**'),
  },
  {
    name: "the model has no arrow types -> root: the unit types does not depend on the unit root",
    checkable: projectFiles(tsconfig).inFolder('src/generated/types/**').shouldNot().dependOnFiles().inPath('src/*.ts*'),
  },
  {
    name: "the model has no arrow types -> test: the unit types does not depend on the unit test",
    checkable: projectFiles(tsconfig).inFolder('src/generated/types/**').shouldNot().dependOnFiles().inFolder('src/test/**'),
  },
  {
    name: "the model has no arrow zod -> types: the unit zod does not depend on the unit types",
    checkable: projectFiles(tsconfig).inFolder('src/generated/zod/**').shouldNot().dependOnFiles().inFolder('src/generated/types/**'),
  },
  {
    name: "the model has no arrow zod -> client: the unit zod does not depend on the unit client",
    checkable: projectFiles(tsconfig).inFolder('src/generated/zod/**').shouldNot().dependOnFiles().inFolder('src/client/**'),
  },
  {
    name: "the model has no arrow zod -> i18n: the unit zod does not depend on the unit i18n",
    checkable: projectFiles(tsconfig).inFolder('src/generated/zod/**').shouldNot().dependOnFiles().inFolder('src/i18n/**'),
  },
  {
    name: "the model has no arrow zod -> telemetry: the unit zod does not depend on the unit telemetry",
    checkable: projectFiles(tsconfig).inFolder('src/generated/zod/**').shouldNot().dependOnFiles().inFolder('src/telemetry/**'),
  },
  {
    name: "the model has no arrow zod -> ui: the unit zod does not depend on the unit ui",
    checkable: projectFiles(tsconfig).inFolder('src/generated/zod/**').shouldNot().dependOnFiles().inFolder('src/ui/**'),
  },
  {
    name: "the model has no arrow zod -> root: the unit zod does not depend on the unit root",
    checkable: projectFiles(tsconfig).inFolder('src/generated/zod/**').shouldNot().dependOnFiles().inPath('src/*.ts*'),
  },
  {
    name: "the model has no arrow zod -> test: the unit zod does not depend on the unit test",
    checkable: projectFiles(tsconfig).inFolder('src/generated/zod/**').shouldNot().dependOnFiles().inFolder('src/test/**'),
  },
  {
    name: "the model has no arrow client -> i18n: the unit client does not depend on the unit i18n",
    checkable: projectFiles(tsconfig).inFolder('src/client/**').shouldNot().dependOnFiles().inFolder('src/i18n/**'),
  },
  {
    name: "the model has no arrow client -> telemetry: the unit client does not depend on the unit telemetry",
    checkable: projectFiles(tsconfig).inFolder('src/client/**').shouldNot().dependOnFiles().inFolder('src/telemetry/**'),
  },
  {
    name: "the model has no arrow client -> ui: the unit client does not depend on the unit ui",
    checkable: projectFiles(tsconfig).inFolder('src/client/**').shouldNot().dependOnFiles().inFolder('src/ui/**'),
  },
  {
    name: "the model has no arrow client -> root: the unit client does not depend on the unit root",
    checkable: projectFiles(tsconfig).inFolder('src/client/**').shouldNot().dependOnFiles().inPath('src/*.ts*'),
  },
  {
    name: "the model has no arrow client -> test: the unit client does not depend on the unit test",
    checkable: projectFiles(tsconfig).inFolder('src/client/**').shouldNot().dependOnFiles().inFolder('src/test/**'),
  },
  {
    name: "the model has no arrow i18n -> types: the unit i18n does not depend on the unit types",
    checkable: projectFiles(tsconfig).inFolder('src/i18n/**').shouldNot().dependOnFiles().inFolder('src/generated/types/**'),
  },
  {
    name: "the model has no arrow i18n -> zod: the unit i18n does not depend on the unit zod",
    checkable: projectFiles(tsconfig).inFolder('src/i18n/**').shouldNot().dependOnFiles().inFolder('src/generated/zod/**'),
  },
  {
    name: "the model has no arrow i18n -> client: the unit i18n does not depend on the unit client",
    checkable: projectFiles(tsconfig).inFolder('src/i18n/**').shouldNot().dependOnFiles().inFolder('src/client/**'),
  },
  {
    name: "the model has no arrow i18n -> telemetry: the unit i18n does not depend on the unit telemetry",
    checkable: projectFiles(tsconfig).inFolder('src/i18n/**').shouldNot().dependOnFiles().inFolder('src/telemetry/**'),
  },
  {
    name: "the model has no arrow i18n -> ui: the unit i18n does not depend on the unit ui",
    checkable: projectFiles(tsconfig).inFolder('src/i18n/**').shouldNot().dependOnFiles().inFolder('src/ui/**'),
  },
  {
    name: "the model has no arrow i18n -> root: the unit i18n does not depend on the unit root",
    checkable: projectFiles(tsconfig).inFolder('src/i18n/**').shouldNot().dependOnFiles().inPath('src/*.ts*'),
  },
  {
    name: "the model has no arrow i18n -> test: the unit i18n does not depend on the unit test",
    checkable: projectFiles(tsconfig).inFolder('src/i18n/**').shouldNot().dependOnFiles().inFolder('src/test/**'),
  },
  {
    name: "the model has no arrow telemetry -> types: the unit telemetry does not depend on the unit types",
    checkable: projectFiles(tsconfig).inFolder('src/telemetry/**').shouldNot().dependOnFiles().inFolder('src/generated/types/**'),
  },
  {
    name: "the model has no arrow telemetry -> zod: the unit telemetry does not depend on the unit zod",
    checkable: projectFiles(tsconfig).inFolder('src/telemetry/**').shouldNot().dependOnFiles().inFolder('src/generated/zod/**'),
  },
  {
    name: "the model has no arrow telemetry -> client: the unit telemetry does not depend on the unit client",
    checkable: projectFiles(tsconfig).inFolder('src/telemetry/**').shouldNot().dependOnFiles().inFolder('src/client/**'),
  },
  {
    name: "the model has no arrow telemetry -> i18n: the unit telemetry does not depend on the unit i18n",
    checkable: projectFiles(tsconfig).inFolder('src/telemetry/**').shouldNot().dependOnFiles().inFolder('src/i18n/**'),
  },
  {
    name: "the model has no arrow telemetry -> ui: the unit telemetry does not depend on the unit ui",
    checkable: projectFiles(tsconfig).inFolder('src/telemetry/**').shouldNot().dependOnFiles().inFolder('src/ui/**'),
  },
  {
    name: "the model has no arrow telemetry -> root: the unit telemetry does not depend on the unit root",
    checkable: projectFiles(tsconfig).inFolder('src/telemetry/**').shouldNot().dependOnFiles().inPath('src/*.ts*'),
  },
  {
    name: "the model has no arrow telemetry -> test: the unit telemetry does not depend on the unit test",
    checkable: projectFiles(tsconfig).inFolder('src/telemetry/**').shouldNot().dependOnFiles().inFolder('src/test/**'),
  },
  {
    name: "the model has no arrow ui -> types: the unit ui does not depend on the unit types",
    checkable: projectFiles(tsconfig).inFolder('src/ui/**').shouldNot().dependOnFiles().inFolder('src/generated/types/**'),
  },
  {
    name: "the model has no arrow ui -> zod: the unit ui does not depend on the unit zod",
    checkable: projectFiles(tsconfig).inFolder('src/ui/**').shouldNot().dependOnFiles().inFolder('src/generated/zod/**'),
  },
  {
    name: "the model has no arrow ui -> telemetry: the unit ui does not depend on the unit telemetry",
    checkable: projectFiles(tsconfig).inFolder('src/ui/**').shouldNot().dependOnFiles().inFolder('src/telemetry/**'),
  },
  {
    name: "the model has no arrow ui -> root: the unit ui does not depend on the unit root",
    checkable: projectFiles(tsconfig).inFolder('src/ui/**').shouldNot().dependOnFiles().inPath('src/*.ts*'),
  },
  {
    name: "the model has no arrow ui -> test: the unit ui does not depend on the unit test",
    checkable: projectFiles(tsconfig).inFolder('src/ui/**').shouldNot().dependOnFiles().inFolder('src/test/**'),
  },
  {
    name: "the model has no arrow root -> types: the unit root does not depend on the unit types",
    checkable: projectFiles(tsconfig).inPath('src/*.ts*').shouldNot().dependOnFiles().inFolder('src/generated/types/**'),
  },
  {
    name: "the model has no arrow root -> zod: the unit root does not depend on the unit zod",
    checkable: projectFiles(tsconfig).inPath('src/*.ts*').shouldNot().dependOnFiles().inFolder('src/generated/zod/**'),
  },
  {
    name: "the model has no arrow root -> test: the unit root does not depend on the unit test",
    checkable: projectFiles(tsconfig).inPath('src/*.ts*').shouldNot().dependOnFiles().inFolder('src/test/**'),
  },
]

try {
  process.chdir(frontendDir)
  let failed = false
  for (const rule of rules) {
    const violations = await rule.checkable.check()
    if (violations.length === 0) {
      console.log(`ok   ${rule.name}`)
    } else {
      failed = true
      console.error(`FAIL ${rule.name}: ${violations.length} violation(s)`)
      for (const v of violations) {
        const d = v.dependency ?? v.projectedEdge
        console.error(`     | ${d !== undefined ? `${d.sourceLabel} -> ${d.targetLabel}` : (v.message ?? JSON.stringify(v))}`)
      }
    }
  }
  if (failed) process.exit(1)
  console.log(`PASS the rules of the model are green (${rules.length} rule(s), ArchUniTS)`)
} catch (error) {
  console.error(`FAIL the run stopped: ${error?.message ?? error}`)
  process.exit(2)
}
