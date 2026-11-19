// The check of the patterns of lines.mjs (feat-9-walking-skeleton, Phase 400, CI run 44296180544). It runs with
// `node --test e2e/lines.check.mjs` (the recipe test-e2e does it, tools/gates/test-e2e.sh), and it is not a test of
// Playwright (the name has no part `.spec.` or `.test.`, so Playwright does not start it).
// Every text is fed in every possible cut: all the chunks of the text, cut at all the places, must not give the
// address until the line break has arrived, and never an address that is shorter than the real one.
import assert from 'node:assert/strict'
import { test } from 'node:test'
import { backendUrl, serviceUrlWait } from './lines.mjs'

const lineBreaks = ['\n', '\r\n']

// The text that a reader has collected when the chunks that have arrived end at the place `index` (every place of
// the text, so also the places inside a number and between the two characters of a line break).
function* collected(text) {
  for (let index = 0; index <= text.length; index += 1) {
    yield text.slice(0, index)
  }
}

for (const lineBreak of lineBreaks) {
  const label = JSON.stringify(lineBreak)

  test(`the backend line is accepted only when it is complete (${label})`, () => {
    const prefix = '[INFO] Running the test\nsome output\n'
    const line = `E2E_BACKEND_URL=http://127.0.0.1:35127${lineBreak}`
    const text = `${prefix}${line}[INFO] more output\n`
    const lineEnd = prefix.length + line.length
    for (const seen of collected(text)) {
      const url = backendUrl(seen)
      if (seen.length < lineEnd) {
        assert.equal(url, undefined, `no address before the line break has arrived: ${JSON.stringify(seen.slice(prefix.length))}`)
      } else {
        assert.equal(url, 'http://127.0.0.1:35127')
      }
    }
  })

  test(`the service line of Playwright is accepted only when it is complete (${label})`, () => {
    const prefix = 'some output\n'
    const line = `E2E_SERVICE_URL=http://127.0.0.1:4173${lineBreak}`
    const lineEnd = prefix.length + line.length
    const text = `${prefix}${line}`
    for (const seen of collected(text)) {
      const match = serviceUrlWait.exec(seen)
      if (seen.length < lineEnd) {
        assert.equal(match, null, `no match before the line break has arrived: ${JSON.stringify(seen.slice(prefix.length))}`)
      } else {
        assert.equal(match?.groups?.E2E_SERVICE_URL, 'http://127.0.0.1:4173')
      }
    }
  })
}

test('a line that does not start at the beginning of a line is no backend line', () => {
  assert.equal(backendUrl('text E2E_BACKEND_URL=http://127.0.0.1:1234\n'), undefined)
})

test('another host is no backend line', () => {
  assert.equal(backendUrl('E2E_BACKEND_URL=http://10.0.0.1:1234\n'), undefined)
})
