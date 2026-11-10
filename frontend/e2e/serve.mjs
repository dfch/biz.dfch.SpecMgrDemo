// A tiny static server for the e2e fixtures (feat-7-verification-architecture-tools, Task 110.120).
// Playwright starts it (the webServer of the playwright configs), waits for the port, and stops it
// after the run. It serves the folder e2e/fixtures/ on 127.0.0.1 only (a loopback address, so no
// other process of the machine gets the pages). No server of the recipe is necessary: the browser
// tests of the recipe run headless against this address.
import { createServer } from 'node:http'
import { readFile } from 'node:fs/promises'

const root = process.argv[2]
const port = Number(process.argv[3])

const server = createServer((request, response) => {
  const name = new URL(request.url ?? '/', 'http://localhost').pathname
  if (name === '/') {
    response.writeHead(404).end('no index')
    return
  }
  readFile(`${root}${name}`).then(
    data => {
      response.writeHead(200, { 'content-type': 'text/html' }).end(data)
    },
    () => {
      response.writeHead(404).end('no file')
    },
  )
})

server.listen(port, '127.0.0.1', () => {
  console.log(`serving ${root} on http://127.0.0.1:${port}`)
})
