import { describe, expect, it, vi } from 'vitest'
import { ApiError, createApiClient, type Fetcher } from '../client/apiClient'

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

function respond(body: unknown, init: ResponseInit = { status: 200 }): Fetcher {
  return vi.fn(async () => new Response(JSON.stringify(body), init))
}

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
    expect(fetcher).toHaveBeenCalledWith('/status', { headers: { Accept: 'application/json, application/problem+json' } })
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
      createApiClient('', respond(problem, { status: 503, headers: { 'Content-Type': 'application/problem+json' } })).getStatus(),
    )
    expect(error).toMatchObject({ kind: 'problem', code: 'service_unavailable', traceId, status: 503 })
  })

  it('does not accept a response that does not obey the schema', async () => {
    const error = await failure(createApiClient('', respond({ state: 'down', checkedAt: status.checkedAt })).getStatus())
    expect(error).toMatchObject({ kind: 'invalid', status: 200 })
  })

  it('does not accept a response that is no JSON', async () => {
    const fetcher: Fetcher = async () => new Response('<html>', { status: 200 })
    expect(await failure(createApiClient('', fetcher).getInfo())).toMatchObject({ kind: 'invalid' })
  })

  it('does not accept an error response that is no problem of the contract', async () => {
    const error = await failure(createApiClient('', respond({ code: 'unknown_code', traceId }, { status: 500 })).getInfo())
    expect(error).toMatchObject({ kind: 'invalid', status: 500 })
    expect(error.code).toBeUndefined()
  })

  it('maps a request that does not finish to the error of the kind network', async () => {
    const fetcher: Fetcher = async () => {
      throw new TypeError('Failed to fetch')
    }
    expect(await failure(createApiClient('', fetcher).getStatus())).toMatchObject({ kind: 'network' })
  })
})
