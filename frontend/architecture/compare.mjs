#!/usr/bin/env node
/**
 * The frontend side of the test that compares the Structurizr workspace with the modules and the
 * packages of the code (feat-7-verification-architecture-tools, Task 130.120, REQ-004, ACC-003;
 * DEC 9edc1071-4fd0-48b6-a037-1a4cb2331f73: "A test reads the workspace and compares the components
 * with the modules and the packages"). The backend side is the JUnit class
 * biz.dfch.specmgrdemo.architecture.ModelComparisonTest (the recipe architecture-model).
 *
 * Usage: node compare.mjs [<frontend dir>] [<workspace file>]
 *   <frontend dir>    the folder of the pnpm module (default: the parent of this script's folder)
 *   <workspace file>  the file of the workspace (default: <frontend dir>/../model/workspace.json)
 *
 * The units of the frontend (the rule of thumb of Task 130.110, the same for the recipe
 * architecture-frontend): a unit is a folder that contains TypeScript source - the top-level
 * folders of frontend/src (today: test), the folders of frontend/src/generated that contain
 * TypeScript source (today: types and zod; the generator makes two independent artifacts, so the
 * folders of the generated code are the units and not the folder generated), and the TypeScript
 * files that lie directly in frontend/src form the unit root (today: mutation-example.ts). The
 * name of a unit is the identifier of its component in the model (the rule of DEC 9edc1071).
 *
 * The imports of each file are read with the compiler of the pinned package typescript (the devDependency
 * of the module): the import declarations and the export-from declarations. A specifier that starts
 * with ./ or ../ is internal (it resolves to a file of the units), and the other specifiers are
 * external (a package, for example zod, vitest and fast-check; they are no unit dependencies). A
 * construct that this script does not understand (a syntax error, a dynamic import(), a require(),
 * an import=, an internal specifier that resolves to no file) stops the script (exit code 2), and
 * a file that the rule of thumb has no unit for stops the script too.
 *
 * The workspace file is read strictly: the form is the one that the writer of the library
 * structurizr-java makes (the file is machine-generated-shaped and hand-maintained, see
 * model/README.md). A key or an element type that this script does not understand stops the script
 * (exit code 2).
 *
 * The assertions (the two conditions of ACC-003, and the other direction, recorded in the plan):
 *   - every unit has a component in the model (the components of the container frontend);
 *   - every unit dependency is in the model (the dependencies between the components of the
 *     container frontend; the dependency of the container frontend on the container backend is no
 *     unit dependency, and this side does not compare it);
 *   - the other direction: no component in the model without a unit, and no dependency in the
 *     model without the unit dependency of the code.
 *
 * Exit code 0: the workspace matches the code (the committed run is green). Exit code 1: the
 * comparison is not successful (the message names the unit or the dependency). Exit code 2: an
 * error of the input (a file that the script cannot read or understand).
 */

import { existsSync, readFileSync, readdirSync, statSync } from 'node:fs'
import { dirname, join, relative, resolve, sep } from 'node:path'
import { fileURLToPath } from 'node:url'
import ts from 'typescript'

const here = dirname(fileURLToPath(import.meta.url))
const frontendDir = resolve(process.argv[2] ?? join(here, '..'))
const workspacePath = resolve(process.argv[3] ?? join(frontendDir, '..', 'model', 'workspace.json'))
const srcDir = join(frontendDir, 'src')

const toPosix = (path) => path.split(sep).join('/')

/** Stop with the message and the exit code 2 (an error of the input, and not a drift). */
function stop(message) {
  console.error(`FAIL ${message}`)
  console.error('     the script stops for the input of the comparison (exit code 2)')
  process.exit(2)
}

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
 * Discover the units of the frontend (the rule of thumb, see the header). Return the map of the
 * units (the name of the unit to the files of the unit, relative to the frontend folder).
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
 * Read the imports of the files (the import declarations and the export-from declarations, with
 * the compiler of the pinned package typescript). Return the internal dependencies (the source
 * file to the target file, both relative to the frontend folder). A construct that the script
 * does not understand stops the script.
 */
function readImports(units) {
  const files = []
  for (const fileSet of units.values()) {
    files.push(...fileSet)
  }
  const absFiles = files.map((file) => resolve(frontendDir, file))

  const program = ts.createProgram(absFiles, { noEmit: true, allowJs: false, skipLibCheck: true })
  const dependencies = []

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
        const specifier = node.moduleSpecifier.text
        if (specifier.startsWith('./') || specifier.startsWith('../')) {
          dependencies.push([fromFile, resolveInternal(fromFile, specifier)])
        }
      } else if (ts.isExportDeclaration(node) && node.moduleSpecifier !== undefined) {
        if (!ts.isStringLiteral(node.moduleSpecifier)) {
          stop(`the export-from of the file ${fromFile} has a specifier that is not a string. The comparison does not understand it`)
        }
        const specifier = node.moduleSpecifier.text
        if (specifier.startsWith('./') || specifier.startsWith('../')) {
          dependencies.push([fromFile, resolveInternal(fromFile, specifier)])
        }
      } else if (
        ts.isCallExpression(node) &&
        ts.isIdentifier(node.expression) &&
        (node.expression.text === 'import' || node.expression.text === 'require')
      ) {
        stop(`the file ${fromFile} uses a dynamic import() or require(). The comparison does not understand it. Add the construct to the plan and to the script`)
      } else if (ts.isImportEqualsDeclaration(node)) {
        stop(`the file ${fromFile} uses an import= declaration. The comparison does not understand it. Add the construct to the plan and to the script`)
      }
      ts.forEachChild(node, visit)
    }
    visit(sourceFile)
  }
  return dependencies
}

/** The unit of the file (the map of the units), or stop if the file is not in a unit. */
function unitOfFile(units, file) {
  for (const [unit, fileSet] of units) {
    if (fileSet.includes(file)) {
      return unit
    }
  }
  stop(`the file ${file} is not in a unit of the frontend (the rule of thumb)`)
}

// Read the workspace strictly (the form is the one of the writer of structurizr-java).
let workspaceText
try {
  workspaceText = readFileSync(workspacePath, 'utf8')
} catch (error) {
  stop(`the workspace does not exist or cannot be read: ${workspacePath} (${error.message})`)
}
let workspace
try {
  workspace = JSON.parse(workspaceText)
} catch (error) {
  stop(`the workspace is not JSON: ${workspacePath} (${error.message})`)
}

const knownTopLevelKeys = new Set(['configuration', 'description', 'documentation', 'id', 'model', 'name', 'views'])
if (typeof workspace !== 'object' || workspace === null || Array.isArray(workspace)) {
  stop('the workspace is not an object')
}
for (const key of Object.keys(workspace)) {
  if (!knownTopLevelKeys.has(key)) {
    stop(`the workspace has the top-level key ${key}, which the comparison does not understand. Add the key to the plan and to the script`)
  }
}
if (typeof workspace.name !== 'string') {
  stop('the workspace has no name (a string)')
}
if (typeof workspace.model !== 'object' || workspace.model === null) {
  stop('the workspace has no model (an object)')
}
for (const key of Object.keys(workspace.model)) {
  if (key !== 'softwareSystems') {
    stop(`the model of the workspace has the key ${key}, which the comparison does not understand (it has the software systems only)`)
  }
}
const systems = workspace.model.softwareSystems
if (!Array.isArray(systems) || systems.length !== 1) {
  stop(`the model of the workspace has ${Array.isArray(systems) ? systems.length : 'no'} software system(s). The comparison has one`)
}

const knownSystemKeys = new Set(['containers', 'description', 'documentation', 'id', 'name', 'tags'])
const knownContainerKeys = new Set(['components', 'description', 'documentation', 'id', 'name', 'relationships', 'tags', 'technology'])
const knownComponentKeys = new Set(['description', 'documentation', 'id', 'name', 'relationships', 'tags', 'technology'])
const knownRelationshipKeys = new Set(['description', 'destinationId', 'id', 'sourceId', 'tags'])

function checkKeys(element, knownKeys, where) {
  for (const key of Object.keys(element)) {
    if (!knownKeys.has(key)) {
      stop(`${where} has the key ${key}, which the comparison does not understand. Add the key to the plan and to the script`)
    }
  }
}

const system = systems[0]
checkKeys(system, knownSystemKeys, `the software system ${system.name ?? '<no name>'} of the workspace`)
if (!Array.isArray(system.containers)) {
  stop('the software system of the workspace has no containers (an array)')
}
const frontend = system.containers.find((container) => container.name === 'frontend')
if (frontend === undefined) {
  stop('the workspace has no container frontend (the container of the pnpm module)')
}
for (const container of system.containers) {
  checkKeys(container, knownContainerKeys, `the container ${container.name ?? '<no name>'} of the workspace`)
  if (Array.isArray(container.components)) {
    for (const component of container.components) {
      checkKeys(component, knownComponentKeys, `the component ${component.name ?? '<no name>'} of the container ${container.name} of the workspace`)
      for (const relationship of component.relationships ?? []) {
        checkKeys(relationship, knownRelationshipKeys, `the relationship of the component ${component.name} of the workspace`)
      }
    }
  }
  for (const relationship of container.relationships ?? []) {
    checkKeys(relationship, knownRelationshipKeys, `the relationship of the container ${container.name} of the workspace`)
  }
}

// The components of the container frontend, and the dependencies between them (the ids of the
// relationships resolve to the components of the container).
const modelComponents = new Map()
if (!Array.isArray(frontend.components)) {
  stop('the container frontend of the workspace has no components (an array)')
}
for (const component of frontend.components) {
  if (typeof component.name !== 'string' || typeof component.id !== 'string') {
    stop(`the component of the container frontend of the workspace has no name or no id: ${JSON.stringify(component)}`)
  }
  if (modelComponents.has(component.name)) {
    stop(`the container frontend of the workspace has the component ${component.name} two times`)
  }
  modelComponents.set(component.name, component.id)
}
const idToUnit = new Map([...modelComponents].map(([name, id]) => [id, name]))
const modelDependencies = new Set()
for (const relationship of [...(frontend.relationships ?? []), ...frontend.components.flatMap((component) => component.relationships ?? [])]) {
  if (typeof relationship.sourceId !== 'string' || typeof relationship.destinationId !== 'string') {
    stop(`the relationship of the container frontend of the workspace has no sourceId or no destinationId: ${JSON.stringify(relationship)}`)
  }
  const source = idToUnit.get(relationship.sourceId)
  const destination = idToUnit.get(relationship.destinationId)
  if (source !== undefined && destination !== undefined) {
    modelDependencies.add(`${source} -> ${destination}`)
  }
  // A relationship that has one side outside the container frontend (for example the dependency
  // of the container frontend on the container backend) is no unit dependency.
}

// The code: the units of the frontend, and their dependencies (the internal imports between the units).
const units = discoverUnits()
const imports = readImports(units)
const codeUnits = [...units.keys()].sort()
const codeDependencies = new Set()
for (const [source, target] of imports) {
  const sourceUnit = unitOfFile(units, source)
  const targetUnit = unitOfFile(units, target)
  if (sourceUnit !== targetUnit) {
    codeDependencies.add(`${sourceUnit} -> ${targetUnit}`)
  }
}

// The assertions.
let failed = false
for (const unit of codeUnits) {
  if (!modelComponents.has(unit)) {
    console.error(`FAIL the unit ${unit} of the frontend has no component in the model (the workspace ${workspacePath})`)
    failed = true
  }
}
for (const dependency of [...codeDependencies].sort()) {
  if (!modelDependencies.has(dependency)) {
    console.error(`FAIL the dependency ${dependency} of the frontend is not in the model (the workspace ${workspacePath})`)
    failed = true
  }
}
for (const unit of [...modelComponents.keys()].sort()) {
  if (!codeUnits.includes(unit)) {
    console.error(`FAIL the component ${unit} of the model (the container frontend) has no unit in the code`)
    failed = true
  }
}
for (const dependency of [...modelDependencies].sort()) {
  if (!codeDependencies.has(dependency)) {
    console.error(`FAIL the dependency ${dependency} of the model (the container frontend) is not in the code`)
    failed = true
  }
}

if (failed) {
  process.exit(1)
}
console.log(`ok   the units of the frontend are in the model: ${codeUnits.join(', ')}`)
console.log(
  `ok   the dependencies of the units of the frontend are in the model: ${[...codeDependencies].sort().join(', ') || '(no unit dependency)'}`,
)
console.log(`ok   the model (the container frontend) has no component or no dependency without the code`)
console.log(`PASS the workspace ${workspacePath} matches the code of the frontend (${codeUnits.length} unit(s), ${codeDependencies.size} unit dependency(ies))`)
