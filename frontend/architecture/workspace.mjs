#!/usr/bin/env node
/**
 * The shared module of the frontend side of the rules the model gives (feat-50-structurizr-model-rules,
 * Task 130.100, 130.120 and 130.130; the canonical form is the section "The rules the model gives" of
 * model/README.md; DEC e85e9685-0787-4dff-9ee5-9d46670e9ee4). The runner (runner.mjs: the forbidden
 * dependencies and the cycle rule, derived from the model) and the comparison (compare.mjs: the closed
 * set and the exceptions, the same derivation) both read the workspace through this module, and they
 * derive the same rule set, so the two cannot drift apart (the backend side has the shared class
 * ModelRules, the same design).
 *
 * The workspace file is read strictly: the form is the one that the exporter of the pinned
 * container structurizr/structurizr makes from model/workspace.dsl (DEC b6e8808f-86b4-41a4-92f2-33d38869beed;
 * see model/README.md). The keys that the exporter adds to the form of the hand-maintained file are
 * accepted here (feat-50-structurizr-model-rules, Phase 110): the top-level key `properties` (a map of
 * texts, Task 110.100), the element key `perspectives` (an array of the objects with the text keys
 * name, description and value, Task 110.130), and the model key `deploymentNodes` (an array of the
 * deployment nodes, Task 110.130). The content of the top-level key `views` is not inspected (the
 * rules are derived from the elements of the model, and not from the views; the reader of the backend
 * validates the references of the views, the record of Phase 110). Each other key that this module
 * does not understand stops the run (exit code 2).
 */

import { readFileSync } from 'node:fs'

/** Stop with the message and the exit code 2 (an error of the input, and not a drift). */
export function stop(message) {
  console.error(`FAIL ${message}`)
  console.error('     the script stops for the input it does not understand (exit code 2)')
  process.exit(2)
}

/** The list form of the DEC: the entries that the character comma separates (a space after the comma is allowed). */
export function parseList(value) {
  if (typeof value !== 'string' || value.trim() === '') {
    return []
  }
  return value
    .split(',')
    .map((entry) => entry.trim())
    .filter((entry) => entry !== '')
}

/**
 * Read the workspace file strictly (the form is the one of the writer of structurizr-java, see the
 * header). Return the object of the workspace. A file that the reader does not understand stops the
 * run (exit code 2).
 */
export function readWorkspace(workspacePath) {
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

  const knownTopLevelKeys = new Set(['configuration', 'description', 'documentation', 'id', 'model', 'name', 'properties', 'views'])
  if (typeof workspace !== 'object' || workspace === null || Array.isArray(workspace)) {
    stop('the workspace is not an object')
  }
  for (const key of Object.keys(workspace)) {
    if (!knownTopLevelKeys.has(key)) {
      stop(`the workspace has the top-level key ${key}, which the comparison does not understand. Add the key to the plan and to the script`)
    }
  }
  // The top-level `properties` (the exporter writes the base64 text of the source DSL under the key
  // `structurizr.dsl`, and the counts of the inspection under the keys `structurizr.inspection.*`,
  // feat-50-structurizr-model-rules, Task 110.100): a map of texts, like the `properties` of an element.
  if (Object.hasOwn(workspace, 'properties')) {
    const topProperties = workspace.properties
    if (
      typeof topProperties !== 'object' ||
      topProperties === null ||
      Array.isArray(topProperties) ||
      !Object.values(topProperties).every((value) => typeof value === 'string')
    ) {
      stop('the workspace has the top-level key properties, and its value is not a map of texts')
    }
  }
  if (typeof workspace.name !== 'string') {
    stop('the workspace has no name (a string)')
  }
  if (typeof workspace.model !== 'object' || workspace.model === null) {
    stop('the workspace has no model (an object)')
  }
  for (const key of Object.keys(workspace.model)) {
    if (key !== 'softwareSystems' && key !== 'deploymentNodes') {
      stop(
        `the model of the workspace has the key ${key}, which the comparison does not understand (it has the software systems and the deployment nodes only)`,
      )
    }
  }
  const systems = workspace.model.softwareSystems
  if (!Array.isArray(systems) || systems.length !== 1) {
    stop(`the model of the workspace has ${Array.isArray(systems) ? systems.length : 'no'} software system(s). The comparison has one`)
  }
  // The model key `deploymentNodes` (the deployment unit of the model for the view of the deployment
  // viewpoint, feat-50-structurizr-model-rules, Task 110.130): an array of the deployment nodes. The
  // exporter writes the node, and not the containment of the node, so the comparison does not
  // examine the containment (it is no relationship of the model, and it is not visible in the code).
  if (Object.hasOwn(workspace.model, 'deploymentNodes')) {
    const knownDeploymentNodeKeys = new Set(['description', 'environment', 'id', 'instances', 'name', 'properties', 'tags', 'technology'])
    const deploymentNodes = workspace.model.deploymentNodes
    if (!Array.isArray(deploymentNodes)) {
      stop('the model of the workspace has the key deploymentNodes, and its value is not an array')
    }
    for (const node of deploymentNodes) {
      checkKeys(node, knownDeploymentNodeKeys, 'the deployment node of the workspace')
      if (
        typeof node.name !== 'string' ||
        typeof node.id !== 'string' ||
        typeof node.environment !== 'string' ||
        typeof node.instances !== 'string'
      ) {
        stop(`the deployment node of the workspace has no name, no id, no environment or no instances (a string): ${JSON.stringify(node)}`)
      }
    }
  }

  // The key `properties` of an element is the Structurizr map of text values. The traceability check
  // (tools/gates/traceability.py, feat-8-traceability-security-gates) reads the property `specmgr-req` of it. This
  // comparison does not use the values: it accepts the key, and stops if the value is not a map of texts.
  // The key `perspectives` of an element is the native block of the Rozanski & Woods perspectives
  // (documentation only, feat-50-structurizr-model-rules, Task 110.130): an array of the objects with
  // the text keys name, description and value. This comparison does not use the values: it accepts
  // the key, and stops if the value is not an array of objects of that form.
  const knownSystemKeys = new Set(['containers', 'description', 'documentation', 'id', 'name', 'perspectives', 'properties', 'tags'])
  const knownContainerKeys = new Set(['components', 'description', 'documentation', 'id', 'name', 'perspectives', 'properties', 'relationships', 'tags', 'technology'])
  const knownComponentKeys = new Set(['description', 'documentation', 'id', 'name', 'perspectives', 'properties', 'relationships', 'tags', 'technology'])
  const knownRelationshipKeys = new Set(['description', 'destinationId', 'id', 'sourceId', 'tags'])
  const knownPerspectiveKeys = new Set(['name', 'description', 'value'])

  function checkKeys(element, knownKeys, where) {
    for (const key of Object.keys(element)) {
      if (!knownKeys.has(key)) {
        stop(`${where} has the key ${key}, which the comparison does not understand. Add the key to the plan and to the script`)
      }
    }
    if (Object.hasOwn(element, 'properties')) {
      const properties = element.properties
      const isMapOfTexts =
        typeof properties === 'object' &&
        properties !== null &&
        !Array.isArray(properties) &&
        Object.values(properties).every((value) => typeof value === 'string')
      if (!isMapOfTexts) {
        stop(`${where} has the key properties, and its value is not a map of texts`)
      }
    }
    if (Object.hasOwn(element, 'perspectives')) {
      const perspectives = element.perspectives
      if (!Array.isArray(perspectives)) {
        stop(`${where} has the key perspectives, and its value is not an array`)
      }
      perspectives.forEach((perspective, index) => {
        checkKeys(perspective, knownPerspectiveKeys, `the perspective ${index} of ${where}`)
        if (
          typeof perspective.name !== 'string' ||
          typeof perspective.description !== 'string' ||
          typeof perspective.value !== 'string'
        ) {
          stop(`the perspective ${index} of ${where} has the keys name, description and value, and they are not all texts`)
        }
      })
    }
  }

  const system = systems[0]
  checkKeys(system, knownSystemKeys, `the software system ${system.name ?? '<no name>'} of the workspace`)
  if (!Array.isArray(system.containers)) {
    stop('the software system of the workspace has no containers (an array)')
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
  return workspace
}

/**
 * Derive the rule set the model gives for the container frontend (the canonical section of
 * model/README.md): the mapped components (the components that have code.language typescript and
 * code.path, with their entries of code.path and their entries of code.allowedExternal), and the
 * relations between them (the relationships of the model whose both sides are mapped components of
 * the container). An element without a mapping is not compared with the code (the first limit of the
 * closed world, DEC e85e9685).
 */
export function deriveFrontend(workspace) {
  const system = workspace.model.softwareSystems[0]
  const container = system.containers.find((c) => c.name === 'frontend')
  if (container === undefined) {
    stop('the workspace has no container frontend (the container of the pnpm module)')
  }
  if (!Array.isArray(container.components)) {
    stop('the container frontend of the workspace has no components (an array)')
  }
  const components = new Map()
  for (const component of container.components) {
    if (typeof component.name !== 'string' || typeof component.id !== 'string') {
      stop(`the component of the container frontend of the workspace has no name or no id: ${JSON.stringify(component)}`)
    }
    if (components.has(component.name)) {
      stop(`the container frontend of the workspace has the component ${component.name} two times`)
    }
    const properties = component.properties ?? {}
    // An element without a mapping is not compared with the code (the first limit of the closed world).
    if (properties['code.language'] !== 'typescript' || typeof properties['code.path'] !== 'string') {
      continue
    }
    components.set(component.name, {
      paths: parseList(properties['code.path']),
      allowedExternal: parseList(properties['code.allowedExternal']),
    })
  }
  if (components.size === 0) {
    stop('the container frontend of the workspace has no mapped component (code.language typescript and code.path)')
  }
  const idToName = new Map(container.components.map((component) => [component.id, component.name]))
  const relations = new Set()
  const relationshipList = [
    ...(container.relationships ?? []),
    ...container.components.flatMap((component) => component.relationships ?? []),
  ]
  for (const relationship of relationshipList) {
    if (typeof relationship.sourceId !== 'string' || typeof relationship.destinationId !== 'string') {
      stop(`the relationship of the container frontend of the workspace has no sourceId or no destinationId: ${JSON.stringify(relationship)}`)
    }
    const source = idToName.get(relationship.sourceId)
    const destination = idToName.get(relationship.destinationId)
    // A relationship that has one side outside the container frontend (for example the dependency of
    // the container frontend on the container backend) is no unit dependency (the container-level
    // relations are not compared with the code, the first limit of the closed world).
    if (source !== undefined && destination !== undefined && components.has(source) && components.has(destination)) {
      relations.add(`${source} -> ${destination}`)
    }
  }
  return { components, relations }
}

/**
 * The forbidden dependencies (group 1 of the canonical section): every ordered pair of distinct
 * mapped components that has no relation in the model (the closed world between the mapped
 * elements), in the sorted order of the names.
 */
export function forbiddenPairs(derived) {
  const names = [...derived.components.keys()].sort()
  const result = []
  for (const source of names) {
    for (const destination of names) {
      if (source !== destination && !derived.relations.has(`${source} -> ${destination}`)) {
        result.push([source, destination])
      }
    }
  }
  return result
}

const escapeRegExp = (text) => text.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')

/**
 * The part of the pattern of one entry of code.path (the form of the DEC: a folder is the path with
 * the folder suffix, the two characters star and the slash, the files of the folder at each depth; a
 * file is the path without the suffix). The ArchUniTS filter is a pattern of the type RegExp (the
 * spike of Phase 100: the text glob of the form (a|b) is not supported), and it matches the path of
 * the file relative to the folder of the tsconfig (the label of the file of the graph of ArchUniTS).
 */
export function entryPattern(entry) {
  if (entry.endsWith('/**')) {
    return `${escapeRegExp(entry.slice(0, -3))}/.+`
  }
  return escapeRegExp(entry)
}

/** The RegExp of the entries of code.path of one component (self-anchored, the union of the entries). */
export function componentRegExp(entries) {
  return new RegExp(`^(?:${entries.map(entryPattern).join('|')})$`)
}

/** The RegExp of the entries of code.path of all the mapped components (for the cycle rule). */
export function allMappedRegExp(derived) {
  const entries = [...derived.components.values()].flatMap((component) => component.paths)
  return componentRegExp(entries)
}

/**
 * The mapped components that own the file (the most specific entry: the file entry that is the file
 * itself, or the folder entry with the longest prefix). The empty list is no owner; a list of two is
 * the ambiguous mapping (the exactly one of group 3 of the canonical section).
 */
export function ownersOf(derived, file) {
  const matches = []
  for (const [name, component] of derived.components) {
    let best = -1
    for (const entry of component.paths) {
      if (entry.endsWith('/**')) {
        const dir = entry.slice(0, -3)
        if (file.startsWith(`${dir}/`)) {
          best = Math.max(best, dir.length + 1)
        }
      } else if (file === entry) {
        best = Math.max(best, entry.length)
      }
    }
    if (best >= 0) {
      matches.push({ name, score: best })
    }
  }
  if (matches.length === 0) {
    return []
  }
  const top = Math.max(...matches.map((match) => match.score))
  return matches.filter((match) => match.score === top).map((match) => match.name)
}

/**
 * The form of the DEC: the external import whose name is the entry, or that starts with the entry and
 * the character /, is allowed.
 */
export function allowedExternalMatch(entries, packageName) {
  return entries.some((entry) => packageName === entry || packageName.startsWith(`${entry}/`))
}
