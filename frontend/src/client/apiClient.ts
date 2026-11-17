import type { ZodType, output } from 'zod'
import type { ErrorCodeKey } from '../generated/types/ErrorCode'
import type { Info } from '../generated/types/Info'
import type { Status } from '../generated/types/Status'
import { getInfoResponseSchema } from '../generated/zod/getInfoSchema'
import { getStatusResponseSchema } from '../generated/zod/getStatusSchema'
import { problemSchema } from '../generated/zod/problemSchema'

// The client of the two operations of the contract (feat-9-walking-skeleton, Phase 300, Task 300.100 and
// Task 300.110, DEC f92e35a1-77a2-4749-917f-bf9b644e8ddd: the layers validate). The types and the Zod
// schemas are the generated ones (src/generated). The client validates each response with the generated
// schema: an answer that does not obey the contract is an error of the kind `invalid`, and it never reaches
// the user interface as data. An error response of the backend (RFC 9457, the media type
// application/problem+json) is an error of the kind `problem` with the error code and the trace identifier
// (the user interface shows the text of the code from its catalog, DEC 51b00b5f-d1d8-49d8-9f40-28537ff69698).

/** The function that makes the request. The seam of the tests (the default is the `fetch` of the platform). */
export type Fetcher = (input: string, init?: RequestInit) => Promise<Response>

/**
 * The kind of an error of the client.
 * - `problem`: the backend gave an error response that obeys the contract (code, traceId and status are set).
 * - `network`: the request did not finish (the service cannot be reached).
 * - `invalid`: the answer does not obey the contract (the status, the media type or the body).
 */
export type ApiErrorKind = 'problem' | 'network' | 'invalid'

export class ApiError extends Error {
  readonly kind: ApiErrorKind
  readonly code: ErrorCodeKey | undefined
  readonly traceId: string | undefined
  readonly status: number | undefined

  constructor(
    kind: ApiErrorKind,
    message: string,
    details: { code?: ErrorCodeKey; traceId?: string; status?: number } = {},
  ) {
    super(message)
    this.name = 'ApiError'
    this.kind = kind
    this.code = details.code
    this.traceId = details.traceId
    this.status = details.status
  }
}

export interface ApiClient {
  /** `GET /status` (the operation `getStatus`). */
  getStatus(): Promise<Status>
  /** `GET /info` (the operation `getInfo`). */
  getInfo(): Promise<Info>
}

async function readJson(response: Response): Promise<unknown> {
  try {
    return await response.json()
  } catch {
    return undefined
  }
}

async function request<S extends ZodType>(fetcher: Fetcher, url: string, schema: S): Promise<output<S>> {
  let response: Response
  try {
    response = await fetcher(url, { headers: { Accept: 'application/json, application/problem+json' } })
  } catch (error) {
    throw new ApiError('network', `The request to ${url} did not finish: ${String(error)}`)
  }
  const body = await readJson(response)
  if (response.ok) {
    const parsed = schema.safeParse(body)
    if (!parsed.success) {
      throw new ApiError('invalid', `The response of ${url} does not obey the contract`, { status: response.status })
    }
    return parsed.data
  }
  const problem = problemSchema.safeParse(body)
  if (!problem.success) {
    throw new ApiError('invalid', `The error response of ${url} (status ${response.status}) is no problem of the contract`, {
      status: response.status,
    })
  }
  throw new ApiError('problem', `The service answered ${url} with the error ${problem.data.code}`, {
    code: problem.data.code,
    traceId: problem.data.traceId,
    status: response.status,
  })
}

/**
 * Make the client of the backend.
 *
 * @param baseUrl the base address of the backend. The empty text gives relative URLs (the same origin, and the
 *   proxy of the development server of Vite or the reverse proxy of the deployment reaches the backend).
 * @param fetcher the function that makes the request (the default is the `fetch` of the platform)
 */
export function createApiClient(baseUrl: string, fetcher: Fetcher = (input, init) => fetch(input, init)): ApiClient {
  const base = baseUrl.replace(/\/+$/, '')
  return {
    getStatus: () => request(fetcher, `${base}/status`, getStatusResponseSchema),
    getInfo: () => request(fetcher, `${base}/info`, getInfoResponseSchema),
  }
}
