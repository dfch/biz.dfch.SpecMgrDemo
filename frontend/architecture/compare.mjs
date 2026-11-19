#!/usr/bin/env node
/**
 * The frontend side of the test that compares the Structurizr workspace with the code (feat-7-
 * verification-architecture-tools, Task 130.120, REQ-004, ACC-003; refactored onto the rule set the
 * model gives in feat-50-structurizr-model-rules, Task 130.130, REQ-005; the canonical form is the
 * section "The rules the model gives" of model/README.md; DEC e85e9685-0787-4dff-9ee5-9d46670e9ee4,
 * that replaces the name rule of DEC 9edc1071-4fd0-48b6-a037-1a4cb2331f73). The backend side is the
 * JUnit class biz.dfch.specmgrdemo.architecture.ModelComparisonTest (the recipe architecture-model).
 *
 * Usage: node compare.mjs [<frontend dir>] [<workspace file>]
 *   <frontend dir>    the folder of the pnpm module (default: the parent of this script's folder)
 *   <workspace file>  the file of the workspace (default: <frontend dir>/../model/workspace.json)
 *
 * The comparison is mapping-based (and not name-based): the components of the container frontend are
 * read by their entries of the property code.path (the list form of the DEC: a folder entry with the
 * folder suffix, the files of the folder at each depth; a file entry, the path without the suffix),
 * and the code is the source: the TypeScript files discovered from the files of the module (the rule
 * of thumb stays the discovery - it is the source of truth for what code exists; a file without a
 * component stops the comparison). The discovery: the top-level folders of frontend/src (today:
 * test), the folders of frontend/src/generated that contain TypeScript source (today: types and
 * zod; the generator makes two independent artifacts, so the folders of the generated code are the
 * units and not the folder generated), and the TypeScript files that lie directly in frontend/src
 * form the unit root (today: mutation-example.ts). The name of the rule of thumb (the unit) is in
 * the message that the recipe asserts. A file is owned by the component of the most specific entry
 * (the file entry that is the file itself, or the folder entry with the longest prefix).
 *
 * The imports of each file are read with the compiler of the pinned package typescript (the
 * devDependency of the module): the import declarations, the export-from declarations, and the
 * dynamic forms (the construct import() and the construct require(), the fix of Task 130.130 of
 * feat-50-structurizr-model-rules: with the pinned typescript 5.9.3, the construct import() was
 * silently ignored before the fix, and the header of the old script claimed that it stops the run -
 * the defect of the spike of Phase 100). A dynamic form is read with the same resolution as the
 * static forms: an internal specifier (./ or ../) resolves to a file of the units (the construct
 * that resolves to no file stops the script, exit code 2), and an external specifier is an import
 * to a package (the check of code.allowedExternal below). A specifier that this script does not
 * understand (a syntax error, an import=, a dynamic form with a specifier that is not a string)
 * stops the script (exit code 2).
 *
 * The workspace file is read strictly, and the rule set is derived, through the shared module
 * workspace.mjs (the same module that the runner runner.mjs uses, so the two cannot drift apart;
 * the backend side has the shared class ModelRules, the same design).
 *
 * The assertions (the groups 3 and 4 of the canonical section, the closed set and the exceptions):
 *   - every file of the code is owned by exactly one component (the file that no component owns
 *     stops the run, and the message names the unit of the rule of thumb; the file that two
 *     components own is the ambiguous mapping, and the message names the two components);
 *   - every internal dependency between owned files maps to a pair of components that has a
 *     relation in the model (the message names the dependency);
 *   - the other direction: no component in the model without a file in the code, and no relation in
 *     the model without the dependency of the code;
 *   - every import to an external package is allowed if and only if it matches an entry of the
 *     source component's code.allowedExternal (the form of the DEC: the name of the package is the
 *     entry, or starts with the entry and the character /; the message names the import and the
 *     missing entry). The container-level relations (for example frontend to backend) are not
 *     compared with the code (the first limit of the closed world, DEC e85e9685).
 *
 * Exit code 0: the workspace matches the code (the committed run is green). Exit code 1: the
 * comparison is not successful (the message names the file, the unit or the dependency). Exit code
 * 2: an error of the input (a file that the script cannot read or understand).
 */

import { existsSync, readdirSync, statSync } from 'node:fs'
import { dirname, join, relative, resolve, sep } from 'node:path'
import { fileURLToPath } from 'node:url'
import ts from 'typescript'
import { allowedExternalMatch, deriveFrontend, ownersOf, readWorkspace, stop } from './workspace.mjs'

const here = dirname(fileURLToPath(import.meta.url))
const frontendDir = resolve(process.argv[2] ?? join(here, '..'))
const workspacePath = resolve(process.argv[3] ?? join(frontendDir, '..', 'model', 'workspace.json'))
const srcDir = join(frontendDir, 'src')

const toPosix = (path) => path.split(sep).join('/')

/** The TypeScript files of the folder (recursively), as paths relative to the frontend folder. */
function listTsFiles(dir, base) {
  let result = []
  for (const entry of readdirSync(dir)) {
    const path = join(dir, entry)
    if (statSync(path).isDirectory()) {
      result = result.concat(listTsFiles(path, base))
    } else if (entry.endsWith('.ts') && !entry.endsWith('.d.ts')) {
      result.push(toPosix(relative(base, path)))
    }
  }
  return result
}

/**
 * Discover the files of the code and the units of the rule of thumb (see the header). Return the
 * map of the units (the name of the unit to the files of the unit, relative to the frontend folder).
 * The discovery stays file-based (the source of truth for what code exists); the mapping of the
 * model (the property code.path) gives the ownership, and the rule of thumb gives the name of the
 * unit in the message.
 */
function discoverUnits() {
  if (!existsSync(srcDir) || !statSync(srcDir).isDirectory()) {
    stop(`the folder of the source of the frontend does not exist: ${srcDir}`)
  }
  const units = new Map()
  const addFile = (unit, file) => {
    if (!units.has(unit)) {
      units.set(unit, [])
    }
    units.get(unit).push(file)
  }

  for (const entry of readdirSync(srcDir)) {
    const path = join(srcDir, entry)
    if (statSync(path).isFile() && entry.endsWith('.ts') && !entry.endsWith('.d.ts')) {
      addFile('root', toPosix(relative(frontendDir, path)))
    } else if (statSync(path).isDirectory()) {
      if (entry === 'generated') {
        for (const generatedEntry of readdirSync(path)) {
          const generatedPath = join(path, generatedEntry)
          if (statSync(generatedPath).isFile() && generatedEntry.endsWith('.ts') && !generatedEntry.endsWith('.d.ts')) {
            stop(`the file src/generated/${generatedEntry} is a TypeScript source that lies directly in the folder generated. The rule of thumb has no unit for it (the units are the folders of the generated code). Add the unit to the plan and to the model, or move the file`)
          }
          if (statSync(generatedPath).isDirectory()) {
            for (const file of listTsFiles(generatedPath, frontendDir)) {
              addFile(generatedEntry, file)
            }
          }
        }
      } else {
        for (const file of listTsFiles(path, frontendDir)) {
          addFile(entry, file)
        }
      }
    }
  }
  return units
}

/**
 * Read the imports of the files with the compiler of the pinned package typescript: the import
 * declarations, the export-from declarations, and the dynamic forms (import() and require(), the
 * same resolution as the static forms, the fix of Task 130.130). Return the object with the
 * internal dependencies (the source file to the target file, both relative to the frontend folder)
 * and the external imports (the file and the specifier of the package). A construct that the script
 * does not understand stops the script.
 */
function readImports(units) {
  const files = []
  for (const fileSet of units.values()) {
    files.push(...fileSet)
  }
  const absFiles = files.map((file) => resolve(frontendDir, file))

  const program = ts.createProgram(absFiles, { noEmit: true, allowJs: false, skipLibCheck: true })
  const internal = []
  const external = []

  const resolveInternal = (fromFile, specifier) => {
    // fromFile is relative to the frontend folder: the resolution is against the frontend folder,
    // and not against the working directory of the run.
    const candidate = resolve(frontendDir, dirname(fromFile), specifier)
    for (const suffix of ['', '.ts', join('index', 'ts')]) {
      const path = candidate + suffix
      if (existsSync(path) && statSync(path).isFile()) {
        const target = toPosix(relative(frontendDir, path))
        if (!files.includes(target)) {
          stop(`the internal import ${specifier} of the file ${fromFile} resolves to ${target}, which is not a file of the units of the frontend. The rule of thumb has no unit for it. Add the unit to the plan and to the model`)
        }
        return target
      }
    }
    stop(`the internal import ${specifier} of the file ${fromFile} does not resolve to a TypeScript source of the units of the frontend`)
  }

  const recordSpecifier = (fromFile, specifier) => {
    if (specifier.startsWith('./') || specifier.startsWith('../')) {
      internal.push([fromFile, resolveInternal(fromFile, specifier)])
    } else {
      external.push({ file: fromFile, specifier })
    }
  }

  for (const absolute of absFiles) {
    const sourceFile = program.getSourceFile(absolute)
    if (sourceFile === undefined) {
      stop(`the compiler of typescript has no source file for ${toPosix(relative(frontendDir, absolute))}`)
    }
    const fromFile = toPosix(relative(frontendDir, absolute))
    const diagnostics = program.getSyntacticDiagnostics(sourceFile)
    if (diagnostics.length > 0) {
      const message = ts.flattenDiagnosticMessageText(diagnostics[0].messageText, ' ')
      stop(`the file ${fromFile} has a syntax error that the comparison does not understand: ${message}`)
    }

    const visit = (node) => {
      if (ts.isImportDeclaration(node)) {
        if (!ts.isStringLiteral(node.moduleSpecifier)) {
          stop(`the import of the file ${fromFile} has a specifier that is not a string. The comparison does not understand it`)
        }
        recordSpecifier(fromFile, node.moduleSpecifier.text)
      } else if (ts.isExportDeclaration(node) && node.moduleSpecifier !== undefined) {
        if (!ts.isStringLiteral(node.moduleSpecifier)) {
          stop(`the export-from of the file ${fromFile} has a specifier that is not a string. The comparison does not understand it`)
        }
        recordSpecifier(fromFile, node.moduleSpecifier.text)
      } else if (
        ts.isCallExpression(node) &&
        ((ts.isIdentifier(node.expression) && node.expression.text === 'require') ||
          node.expression.kind === ts.SyntaxKind.ImportKeyword)
      ) {
        // The dynamic forms (import() and require()): the same resolution as the static forms
        // (the fix of Task 130.130 of feat-50-structurizr-model-rules, the defect of the spike of
        // Phase 100: with the pinned typescript 5.9.3, the construct import() is a token, and not
        // an identifier, and the old check tested for an identifier only).
        const argument = node.arguments[0]
        if (argument === undefined || !ts.isStringLiteral(argument)) {
          stop(`the dynamic import of the file ${fromFile} has a specifier that is not a string. The comparison does not understand it`)
        }
        recordSpecifier(fromFile, argument.text)
      } else if (ts.isImportEqualsDeclaration(node)) {
        stop(`the file ${fromFile} uses an import= declaration. The comparison does not understand it. Add the construct to the plan and to the script`)
      }
      ts.forEachChild(node, visit)
    }
    visit(sourceFile)
  }
  return { internal, external }
}

// The rule set the model gives for the container frontend (the shared module workspace.mjs, the
// same derivation that the runner runner.mjs uses).
const derived = deriveFrontend(readWorkspace(workspacePath))

// The code: the files of the module (the discovery from the files, the rule of thumb), and their
// imports (the internal dependencies and the external imports).
const units = discoverUnits()
const { internal, external } = readImports(units)
const fileToUnit = new Map()
for (const [unit, fileSet] of units) {
  for (const file of fileSet) {
    fileToUnit.set(file, unit)
  }
}
const codeFiles = [...fileToUnit.keys()].sort()

// The ownership of the files (the most specific entry of code.path, the shared module).
const ownersByFile = new Map(codeFiles.map((file) => [file, ownersOf(derived, file)]))
const codeDependencies = new Set()
for (const [source, target] of internal) {
  const sourceOwners = ownersByFile.get(source)
  const targetOwners = ownersByFile.get(target)
  if (sourceOwners.length === 1 && targetOwners.length === 1 && sourceOwners[0] !== targetOwners[0]) {
    codeDependencies.add(`${sourceOwners[0]} -> ${targetOwners[0]}`)
  }
}

// The assertions.
let failed = false
// Group 3 (a): the file that no component owns stops the run, and the message names the unit of
// the rule of thumb (the condition (a) of ACC-003). The file that two components own is the
// ambiguous mapping (the exactly one of the closed set).
const noComponent = new Set()
for (const file of codeFiles) {
  const owners = ownersByFile.get(file)
  if (owners.length === 0) {
    noComponent.add(fileToUnit.get(file))
  } else if (owners.length > 1) {
    console.error(`FAIL the file ${file} of the frontend has two components in the model: ${owners.join(' and ')} (the workspace ${workspacePath})`)
    failed = true
  }
}
for (const unit of [...noComponent].sort()) {
  console.error(`FAIL the unit ${unit} of the frontend has no component in the model (the workspace ${workspacePath})`)
  failed = true
}
// Group 3 (b): the internal dependency between mapped components that is not in the model stops
// the run, and the message names the dependency (the condition (b) of ACC-003).
for (const dependency of [...codeDependencies].sort()) {
  if (!derived.relations.has(dependency)) {
    console.error(`FAIL the dependency ${dependency} of the frontend is not in the model (the workspace ${workspacePath})`)
    failed = true
  }
}
// Group 3 (c): the other direction: the model has no component without a file in the code, and no
// relation without the dependency of the code.
for (const component of [...derived.components.keys()].sort()) {
  const inCode = [...ownersByFile.values()].some((owners) => owners.length === 1 && owners[0] === component)
  if (!inCode) {
    console.error(`FAIL the component ${component} of the model (the container frontend) has no unit in the code`)
    failed = true
  }
}
for (const relation of [...derived.relations].sort()) {
  if (!codeDependencies.has(relation)) {
    console.error(`FAIL the dependency ${relation} of the model (the container frontend) is not in the code`)
    failed = true
  }
}
// Group 4: the import to an external package is allowed if and only if it matches an entry of the
// source component's code.allowedExternal. The message names the import and the missing entry.
for (const { file, specifier } of external) {
  const owners = ownersByFile.get(file)
  if (owners.length !== 1) {
    continue // the file that no component owns (or two components own) is the condition (a) above.
  }
  const component = derived.components.get(owners[0])
  if (!allowedExternalMatch(component.allowedExternal, specifier)) {
    console.error(
      `FAIL the import ${specifier} of the file ${file} is not allowed: the component ${owners[0]} has no entry in code.allowedExternal for ${specifier} (the workspace ${workspacePath})`,
    )
    failed = true
  }
}

if (failed) {
  process.exit(1)
}
console.log(`ok   the files of the frontend are in the model: ${codeFiles.length} file(s) in the units ${[...units.keys()].sort().join(', ')}`)
console.log(`ok   the dependencies of the files of the frontend are in the model: ${[...codeDependencies].sort().join(', ') || '(no dependency between the mapped components)'}`)
console.log(`ok   the imports to the external packages are in code.allowedExternal of the model`)
console.log(`ok   the model (the container frontend) has no component or no relation without the code`)
console.log(
  `PASS the workspace ${workspacePath} matches the code of the frontend (${derived.components.size} mapped component(s), ${codeDependencies.size} dependency(ies) between the mapped components)`,
)
