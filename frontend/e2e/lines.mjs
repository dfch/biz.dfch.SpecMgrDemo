// The two patterns that read a printed line of a child process (feat-9-walking-skeleton, Phase 400, CI run
// 44296180544). A reader sees the output of a process in chunks, and a chunk can end in the middle of a number. A
// pattern that accepts the end of the text (`$`, or `\s*$`) as the end of the line then takes the part of the
// number that has arrived: `E2E_BACKEND_URL=http://127.0.0.1:3` instead of `...:35127`, and the proxy of the preview
// server gets ECONNREFUSED. So both patterns accept a line only when the line break after it has arrived (the
// lookahead or the consumed `\r?\n`). The programs that print the lines (the class ServiceForE2e and the script
// service.mjs) end each line with a line break, so a complete line is always followed by one.
// The check lines.check.mjs feeds both patterns with the text in chunks that are cut inside the number.

// The line of the backend (the output of Maven): the first group is the address of the backend.
export const backendUrlLine = /^E2E_BACKEND_URL=(http:\/\/127\.0\.0\.1:\d+)\r?\n/m

// The line of the script service.mjs that Playwright waits for (the option `wait.stdout` of playwright.config.ts,
// which Playwright matches on the whole output that it has collected until then, not line by line). The named
// group is stored in the environment variable E2E_SERVICE_URL.
export const serviceUrlWait = /E2E_SERVICE_URL=(?<E2E_SERVICE_URL>http:\/\/127\.0\.0\.1:\d+)(?=\r?\n)/

// The address of the backend in the text that has been read until now, or undefined if no complete line is there.
export function backendUrl(text) {
  return backendUrlLine.exec(text)?.[1]
}
