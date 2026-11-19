import { describe, expect, it, vi } from 'vitest'
import { ApiError, createApiClient, defaultTimeoutMs, type Fetcher } from '../client/apiClient'

// Unit tests of the client of the API (feat-9-walking-skeleton, Phase 300, Task 300.100 and Task 300.110): the
// client validates each response with the generated Zod schemas, and it maps an error response of the contract
// (RFC 9457) to the error code and the trace identifier. The fetch function is the seam: no network is used.
const traceId = 'a'.repeat(32)
const status = { state: 'up', checkedAt: '2026-11-17T04:30:00Z' }
const info = {
  version: '0.1.0',
  commit: 'abc123',
  copyright: 'Copyright 2026 Ronald Rink',
  repository: 'https://github.com/dfch/biz.dfch.SpecMgrDemo',
  license: 'AGPL-3.0-only',
}

const jsonHeaders = { 'Content-Type': 'application/json' }
const problemHeaders = { 'Content-Type': 'application/problem+json' }

/** The fetcher that answers with the JSON body. The default is a success response of the media type application/json. */
function respond(body: unknown, init: ResponseInit = { status: 200, headers: jsonHeaders }): Fetcher {
  return vi.fn(async () => new Response(JSON.stringify(body), init))
}

/** The fetcher of a service that never answers: it ends with the reason of the signal, as the `fetch` of the platform does. */
const silentFetcher: Fetcher = (_input, init) =>
  new Promise((_resolve, reject) => {
    init?.signal?.addEventListener('abort', () => reject(init.signal?.reason))
  })

async function failure(promise: Promise<unknown>): Promise<ApiError> {
  try {
    await promise
  } catch (error) {
    expect(error).toBeInstanceOf(ApiError)
    return error as ApiError
  }
  throw new Error('The promise has no failure')
}

describe('the client of the API', () => {
  it('gets the status from GET /status', async () => {
    const fetcher = respond(status)
    await expect(createApiClient('', fetcher).getStatus()).resolves.toEqual(status)
    expect(fetcher).toHaveBeenCalledWith('/status', {
      headers: { Accept: 'application/json, application/problem+json' },
      signal: expect.any(AbortSignal),
    })
  })

  it('gets the information from GET /info', async () => {
    const fetcher = respond(info)
    await expect(createApiClient('', fetcher).getInfo()).resolves.toEqual(info)
    expect(fetcher).toHaveBeenCalledWith('/info', expect.anything())
  })

  it('puts the base address in front of the path, and removes the slashes at its end', async () => {
    const fetcher = respond(info)
    await createApiClient('https://example.invalid/api//', fetcher).getInfo()
    expect(fetcher).toHaveBeenCalledWith('https://example.invalid/api/info', expect.anything())
  })

  it('maps an error response of the contract to the code, the trace identifier and the status', async () => {
    const problem = { type: 'about:blank', status: 503, code: 'service_unavailable', traceId }
    const error = await failure(
      createApiClient('', respond(problem, { status: 503, headers: problemHeaders })).getStatus(),
    )
    expect(error).toMatchObject({ kind: 'problem', code: 'service_unavailable', traceId, status: 503 })
    expect(error.message).toBe('The service answered /status with the error service_unavailable')
    expect(error.name).toBe('ApiError')
  })

  it('does not accept a response that does not obey the schema', async () => {
    const error = await failure(createApiClient('', respond({ state: 'down', checkedAt: status.checkedAt })).getStatus())
    expect(error).toMatchObject({ kind: 'invalid', status: 200 })
    expect(error.message).toBe('The response of /status does not obey the contract')
  })

  it('does not accept a response that is no JSON', async () => {
    const fetcher: Fetcher = async () => new Response('<html>', { status: 200, headers: jsonHeaders })
    expect(await failure(createApiClient('', fetcher).getInfo())).toMatchObject({ kind: 'invalid' })
  })

  it('does not accept an error response that is no problem of the contract', async () => {
    const error = await failure(createApiClient('', respond({ code: 'unknown_code', traceId }, { status: 500, headers: problemHeaders })).getInfo())
    expect(error).toMatchObject({ kind: 'invalid', status: 500 })
    expect(error.message).toBe('The error response of /info (status 500) is no problem of the contract')
    expect(error.code).toBeUndefined()
  })

  it('accepts the parameter of the media type of a success response (charset), its case and the spaces', async () => {
    for (const value of ['Application/JSON; charset=utf-8', ' application/json ; charset=utf-8', '  application/json  ']) {
      const headers = { 'Content-Type': value }
      await expect(createApiClient('', respond(info, { status: 200, headers })).getInfo(), value).resolves.toEqual(info)
    }
  })

  it('does not accept a success response that has not the media type application/json', async () => {
    const cases: Array<Record<string, string>> = [{ 'Content-Type': 'text/plain' }, { 'Content-Type': 'application/problem+json' }, {}]
    for (const headers of cases) {
      const error = await failure(createApiClient('', respond(info, { status: 200, headers })).getInfo())
      expect(error, JSON.stringify(headers)).toMatchObject({ kind: 'invalid', status: 200 })
      expect(error.message).toContain('The response of /info has the media type')
      expect(error.message).toContain('not application/json')
    }
  })

  it('accepts the parameter of the media type of an error response (charset) and its case', async () => {
    const problem = { code: 'rate_limited', traceId }
    const headers = { 'Content-Type': 'Application/Problem+JSON; charset=utf-8' }
    const error = await failure(createApiClient('', respond(problem, { status: 429, headers })).getStatus())
    expect(error).toMatchObject({ kind: 'problem', code: 'rate_limited', traceId, status: 429 })
  })

  it('does not accept an error response that has not the media type application/problem+json', async () => {
    const problem = { type: 'about:blank', status: 503, code: 'service_unavailable', traceId }
    const cases: Array<Record<string, string>> = [{ 'Content-Type': 'application/json' }, { 'Content-Type': 'text/html' }, {}]
    for (const headers of cases) {
      const error = await failure(createApiClient('', respond(problem, { status: 503, headers })).getStatus())
      expect(error, JSON.stringify(headers)).toMatchObject({ kind: 'invalid', status: 503 })
      expect(error.code).toBeUndefined()
      expect(error.message).toContain('The error response of /status (status 503) has the media type')
      expect(error.message).toContain('not application/problem+json')
    }
  })

  it('maps a request that has no answer in the time limit to the error of the kind timeout', async () => {
    const error = await failure(createApiClient('', silentFetcher, 20).getStatus())
    expect(error).toMatchObject({ kind: 'timeout', code: undefined, status: undefined })
    expect(error.message).toBe('The request to /status had no complete answer in 20 ms')
  })

  it('maps a body that is not complete in the time limit to the error of the kind timeout', async () => {
    // The headers come at once, and the body never ends: the read of the body ends with the signal of the request.
    const fetcher: Fetcher = async (_input, init) => {
      const body = new ReadableStream({
        start(controller) {
          init?.signal?.addEventListener('abort', () => controller.error(init.signal?.reason))
        },
      })
      return new Response(body, { status: 200, headers: jsonHeaders })
    }
    expect(await failure(createApiClient('', fetcher, 20).getInfo())).toMatchObject({ kind: 'timeout' })
  })

  it('does not give the kind timeout to an answer that comes in the time limit', async () => {
    await expect(createApiClient('', respond(info), 5_000).getInfo()).resolves.toEqual(info)
  })

  it('has the time limit of ten seconds by default, and passes a signal that ends at the limit', async () => {
    expect(defaultTimeoutMs).toBe(10_000)
    const timeout = vi.spyOn(AbortSignal, 'timeout')
    try {
      await createApiClient('', respond(info)).getInfo()
      expect(timeout).toHaveBeenLastCalledWith(10_000)
      await createApiClient('', respond(info), 1_234).getInfo()
      expect(timeout).toHaveBeenLastCalledWith(1_234)
    } finally {
      timeout.mockRestore()
    }
  })

  it('does not map the end of the request by the caller to the kind timeout', async () => {
    const fetcher: Fetcher = async () => {
      throw new DOMException('The operation was aborted.', 'AbortError')
    }
    expect(await failure(createApiClient('', fetcher).getStatus())).toMatchObject({ kind: 'network' })
  })

  it('maps a request that does not finish to the error of the kind network', async () => {
    const fetcher: Fetcher = async () => {
      throw new TypeError('Failed to fetch')
    }
    const error = await failure(createApiClient('', fetcher).getStatus())
    expect(error).toMatchObject({ kind: 'network', code: undefined, status: undefined })
    expect(error.message).toBe('The request to /status did not finish: TypeError: Failed to fetch')
  })
})
