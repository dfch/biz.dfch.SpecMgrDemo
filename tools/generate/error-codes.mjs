// feat-6-contracts-openapi-pipeline, Task 120.120 (REQ-006, ACC-008).
//
// Prints the list of error codes of the generated Zod schemas as JSON: the export `errorCodeSchema` (a Zod enum, so
// `.options` is the list in the order of the OpenAPI file), and the list of `Problem.code` (`problemSchema.shape.code`).
// tools/gates/test-generate-gate.sh starts it with Node (Node 26 removes the types of a .ts file itself):
//
//   node tools/generate/error-codes.mjs frontend/src/generated/zod
//
// Kubb writes imports with no file extension (`from './errorCodeSchema'`), and the ESM loader of Node needs one. The
// hook below tries `.ts` for a relative import with no extension. It is only for this script: the code that Kubb makes
// is for a bundler or for tsc (moduleResolution Bundler), and `pnpm exec tsc --noEmit --strict` compiles it.
import { registerHooks } from 'node:module'
import { resolve } from 'node:path'
import { pathToFileURL } from 'node:url'

registerHooks({
  resolve(specifier, context, nextResolve) {
    try {
      return nextResolve(specifier, context)
    } catch (error) {
      if (specifier.startsWith('.') && !/\.[a-z]+$/.test(specifier)) return nextResolve(`${specifier}.ts`, context)
      throw error
    }
  },
})

const directory = process.argv[2]
if (!directory) {
  console.error('Usage: node error-codes.mjs <the folder frontend/src/generated/zod>')
  process.exit(2)
}
const { errorCodeSchema } = await import(pathToFileURL(resolve(directory, 'errorCodeSchema.ts')).href)
const { problemSchema } = await import(pathToFileURL(resolve(directory, 'problemSchema.ts')).href)
console.log(JSON.stringify({ errorCodeSchema: errorCodeSchema.options, problemCode: problemSchema.shape.code.options }))
