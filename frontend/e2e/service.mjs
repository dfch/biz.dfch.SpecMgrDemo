// The service for the end-to-end test of the walking skeleton (feat-9-walking-skeleton, Phase 400, Task 400.110).
// Playwright starts it (the second webServer of playwright.config.ts), waits for the line that it prints on its
// standard output, and stops it after the run (the whole process group).
//
// The service is the real one: the backend of the build and the development server of Vite of the frontend.
//
// 1. The backend. The script starts `./mvnw test -Dtest=ServiceForE2e` in the folder backend/ (the class
//    ServiceForE2e of the tests of the backend starts the app with the class RunningService: the embedded Tomcat
//    on a random port, the four variables OTEL_* at the empty value, so the service gives no collector, and the
//    default check of the state, the condition `up`). The module has no executable jar and no plug-in that starts
//    a class, and the phase 400 adds no new tool, so the run of the test runner gives the class path of the
//    module. The class prints the line `E2E_BACKEND_URL=http://127.0.0.1:<port>`, and the script waits for it.
//    The extra arguments of Maven are in the variable E2E_MAVEN_ARGS (the recipe test-e2e gives the property
//    build.info.commit with the sha of HEAD, the function backend_maven_args of tools/gates/_lib.sh, so the
//    commit of GET /info is the commit of the work tree).
// 2. The frontend. The script starts the development server of Vite (the API of the package vite, the
//    vite.config.ts of the module) on a random port of the loopback address. The configuration sends /status and
//    /info to the backend (the variable SPECMGRDEMO_BACKEND_URL, which the script sets from the line of step 1), so the
//    browser sees one origin and the page uses relative URLs. The variables VITE_* of the telemetry of the browser
//    are empty (no endpoint of the exporter: the processor of the spans does nothing, no collector).
//
// The ports are random (no fixed port, so no run can meet a process that holds the port), and the script prints
// `E2E_SERVICE_URL=http://127.0.0.1:<port>` of the frontend when both parts run. The config of Playwright reads the
// line (the option `wait.stdout`), and the tests read the address from the environment variable E2E_SERVICE_URL.
//
// The stop: Playwright stops the process group of the script (the child processes of Maven stay in it, so they
// stop with it), and the script stops its two parts on SIGINT and SIGTERM too. If Maven ends before the line is
// there, the script prints the output of Maven and ends with the exit code 1.
import { spawn } from 'node:child_process'
import { createServer as createNetServer } from 'node:net'
import { resolve } from 'node:path'
import { createServer } from 'vite'

const frontendDir = resolve(import.meta.dirname, '..')
const backendDir = resolve(frontendDir, '..', 'backend')
const extraArguments = (process.env.E2E_MAVEN_ARGS ?? '').split(/\s+/).filter(argument => argument !== '')

// A free port of the loopback address: the operating system gives one (the port 0), and the script closes the
// socket and gives the port to Vite (with `strictPort`, so Vite stops if another process took the port in the
// meantime, and does not use another one in silence). Vite reads the option `port` 0 as no port (the default 5173).
function freePort() {
  return new Promise((resolvePort, rejectPort) => {
    const socket = createNetServer()
    socket.on('error', rejectPort)
    socket.listen(0, '127.0.0.1', () => {
      const { port } = socket.address()
      socket.close(() => resolvePort(port))
    })
  })
}

const maven = spawn(
  './mvnw',
  ['--batch-mode', '--no-transfer-progress', 'test', '-Dcodegen.skip=true', '-Dtest=ServiceForE2e', ...extraArguments],
  { cwd: backendDir, stdio: ['ignore', 'pipe', 'pipe'] },
)

let viteServer
let stopping = false

async function stop(code) {
  if (stopping) {
    return
  }
  stopping = true
  maven.kill('SIGTERM')
  await viteServer?.close()
  process.exit(code)
}

process.on('SIGINT', () => void stop(0))
process.on('SIGTERM', () => void stop(0))

// The output of Maven (the standard output and the error output) is kept, and it is printed if the start fails.
let output = ''
const backendUrl = new Promise((resolveUrl, rejectUrl) => {
  const read = chunk => {
    output += chunk.toString()
    const match = /^E2E_BACKEND_URL=(http:\/\/127\.0\.0\.1:\d+)\s*$/m.exec(output)
    if (match) {
      resolveUrl(match[1])
    }
  }
  maven.stdout.on('data', read)
  maven.stderr.on('data', read)
  maven.on('error', rejectUrl)
  maven.on('exit', code => rejectUrl(new Error(`Maven ended with the exit code ${code} before the backend was ready`)))
})

try {
  process.env.SPECMGRDEMO_BACKEND_URL = await backendUrl
  // No endpoint of the exporter of the telemetry of the browser (the empty value is the same as the missing value).
  for (const name of [
    'VITE_API_BASE_URL',
    'VITE_OTEL_EXPORTER_OTLP_ENDPOINT',
    'VITE_OTEL_EXPORTER_OTLP_TRACES_ENDPOINT',
  ]) {
    process.env[name] = ''
  }
  viteServer = await createServer({
    root: frontendDir,
    logLevel: 'warn',
    server: { host: '127.0.0.1', port: await freePort(), strictPort: true },
  })
  await viteServer.listen()
  const address = viteServer.httpServer?.address()
  if (address === null || address === undefined || typeof address === 'string') {
    throw new Error('The development server of Vite has no port')
  }
  console.log(`E2E_SERVICE_URL=http://127.0.0.1:${address.port}`)
} catch (error) {
  console.error(output)
  console.error(error)
  await stop(1)
}
