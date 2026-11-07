// The runner of Kubb (feat-6-contracts-openapi-pipeline, Task 120.110, REQ-004, REQ-011).
//
// It makes the Zod schemas in src/generated with the configuration in kubb.config.mjs. It uses the programmatic
// interface (`createKubb` of @kubb/core) and not the command `kubb generate`: the command makes one network call
// at each start (a GET to registry.npmjs.org to find a new version), and this interface makes none. The recipe
// `just generate` also sets KUBB_DISABLE_TELEMETRY=1 and DO_NOT_TRACK=1, so Kubb sends no usage data.
//
// Start it with `node generate.mjs` in this folder, or through `just generate`. Exit code 0: the files are
// written. Exit code 1: Kubb reported an error (the diagnostics are on the standard error).
import { createKubb } from '@kubb/core'
import config from './kubb.config.mjs'

const result = await createKubb(config).generate()
if (!result.success) {
  console.error(result.diagnostics)
  process.exit(1)
}
console.log(`Kubb: ${result.files.length} files`)
