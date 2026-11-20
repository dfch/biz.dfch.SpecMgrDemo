import { createServer, type IncomingMessage } from 'node:http'
import type { AddressInfo } from 'node:net'
import { SpanStatusCode } from '@opentelemetry/api'
import { InMemorySpanExporter, type ReadableSpan, type SpanExporter } from '@opentelemetry/sdk-trace-web'
import { afterEach, describe, expect, it, vi } from 'vitest'
import { defaultServiceName, readTelemetryConfig } from '../telemetry/config'
import { createTelemetry } from '../telemetry/telemetry'

// Unit tests of the OpenTelemetry of the browser (feat-9-walking-skeleton, Phase 300, Task 300.130, ACC-005,
// DEC e3eadec0-a6ea-4efe-8e6d-fd19287122fa): the check of the feature shows the export of the signal. Two
// proofs: a span reaches the exporter of the pipeline (the in-memory exporter), and a span reaches the address
// that the configuration names (the real exporter OTLP/HTTP posts the span to a server of the test on the
// loopback address). No endpoint means no collector: the processor does nothing and nothing is sent.

afterEach(() => {
  vi.unstubAllGlobals()
})

const okFetcher = async () => new Response('{}', { status: 200 })

describe('the configuration of the OpenTelemetry', () => {
  it('has the name specmgrdemo-frontend by default', () => {
    expect(defaultServiceName).toBe('specmgrdemo-frontend')
  })

  it('has no endpoint and the default name of the service if the environment has no variable', () => {
    expect(readTelemetryConfig({})).toEqual({ endpoint: undefined, serviceName: defaultServiceName })
  })

  it('treats an empty variable (and a variable of spaces) as a missing variable', () => {
    const env = {
      VITE_OTEL_EXPORTER_OTLP_ENDPOINT: '',
      VITE_OTEL_EXPORTER_OTLP_TRACES_ENDPOINT: '  ',
      VITE_OTEL_SERVICE_NAME: '',
    }
    expect(readTelemetryConfig(env)).toEqual({ endpoint: undefined, serviceName: defaultServiceName })
  })

  it('completes the base address with the path of the traces', () => {
    expect(readTelemetryConfig({ VITE_OTEL_EXPORTER_OTLP_ENDPOINT: 'http://collector.invalid:4318' }).endpoint).toBe(
      'http://collector.invalid:4318/v1/traces',
    )
    expect(readTelemetryConfig({ VITE_OTEL_EXPORTER_OTLP_ENDPOINT: 'http://collector.invalid:4318//' }).endpoint).toBe(
      'http://collector.invalid:4318/v1/traces',
    )
  })

  it('takes the full address of the traces before the base address', () => {
    const env = {
      VITE_OTEL_EXPORTER_OTLP_ENDPOINT: 'http://base.invalid',
      VITE_OTEL_EXPORTER_OTLP_TRACES_ENDPOINT: 'http://traces.invalid/own/path',
    }
    expect(readTelemetryConfig(env).endpoint).toBe('http://traces.invalid/own/path')
  })

  it('takes the name of the service of the variable', () => {
    expect(readTelemetryConfig({ VITE_OTEL_SERVICE_NAME: 'my-frontend' }).serviceName).toBe('my-frontend')
  })
})

describe('the export of the spans', () => {
  it('exports the span of a request to the exporter of the pipeline', async () => {
    const exporter = new InMemorySpanExporter()
    const telemetry = createTelemetry({ endpoint: undefined, serviceName: 'test-frontend' }, exporter)

    const response = await telemetry.traceFetch(okFetcher)('/status?secret=1#fragment', { method: 'GET' })
    await telemetry.forceFlush()

    expect(response.status).toBe(200)
    const spans = exporter.getFinishedSpans()
    expect(spans).toHaveLength(1)
    const [span] = spans
    expect(span?.name).toBe('GET /status')
    expect(span?.attributes).toEqual({
      'http.request.method': 'GET',
      'url.path': '/status',
      'http.response.status_code': 200,
    })
    expect(span?.resource.attributes['service.name']).toBe('test-frontend')
    expect(span?.spanContext().traceId).toMatch(/^[0-9a-f]{32}$/)
    expect(span?.status.code).toBe(SpanStatusCode.UNSET)
  })

  it('marks the span of an error response and of a request that does not finish with the status ERROR', async () => {
    const exporter = new InMemorySpanExporter()
    const telemetry = createTelemetry({ endpoint: undefined, serviceName: 'test-frontend' }, exporter)

    await telemetry.traceFetch(async () => new Response('{}', { status: 503 }))('/status')
    await expect(
      telemetry.traceFetch(async () => {
        throw new TypeError('Failed to fetch')
      })('/info'),
    ).rejects.toThrow(TypeError)
    await telemetry.forceFlush()

    const [first, second] = exporter.getFinishedSpans()
    expect(first?.status.code).toBe(SpanStatusCode.ERROR)
    expect(first?.attributes['http.response.status_code']).toBe(503)
    expect(second?.status.code).toBe(SpanStatusCode.ERROR)
    expect(second?.status.message).toBe('TypeError')
  })

  it('marks a response with the status 400 as an error, and a response with the status 399 not', async () => {
    const exporter = new InMemorySpanExporter()
    const telemetry = createTelemetry({ endpoint: undefined, serviceName: 'test-frontend' }, exporter)
    await telemetry.traceFetch(async () => new Response('{}', { status: 400 }))('/status')
    await telemetry.traceFetch(async () => new Response(null, { status: 304 }))('/status')
    await telemetry.forceFlush()
    const [bad, notModified] = exporter.getFinishedSpans()
    expect(bad?.status.code).toBe(SpanStatusCode.ERROR)
    expect(notModified?.status.code).toBe(SpanStatusCode.UNSET)
  })

  it('names the tracer, and the shutdown sends the spans that are not sent yet', async () => {
    // The in-memory exporter clears its spans when it is shut down, so this exporter keeps what it gets.
    const exported: ReadableSpan[] = []
    const exporter: SpanExporter = {
      export: (spans, done) => {
        exported.push(...spans)
        done({ code: 0 }) // 0 is ExportResultCode.SUCCESS (the package @opentelemetry/core is no direct dependency)
      },
      shutdown: async () => undefined,
    }
    const telemetry = createTelemetry({ endpoint: undefined, serviceName: 'test-frontend' }, exporter)
    await telemetry.traceFetch(okFetcher)('/status')
    expect(exported).toHaveLength(0) // the batch processor waits for its delay

    await telemetry.shutdown()

    expect(exported.map((span) => span.instrumentationScope.name)).toEqual(['biz.dfch.specmgrdemo.frontend'])
  })

  it('posts the span to the address of the configuration with the exporter OTLP/HTTP', async () => {
    const received: { url: string | undefined; contentType: string | undefined; body: string }[] = []
    const server = createServer((request: IncomingMessage, response) => {
      const chunks: Buffer[] = []
      request.on('data', (chunk: Buffer) => chunks.push(chunk))
      request.on('end', () => {
        received.push({
          url: request.url,
          contentType: request.headers['content-type'],
          body: Buffer.concat(chunks).toString('utf8'),
        })
        response.writeHead(200, { 'Content-Type': 'application/json' }).end('{}')
      })
    })
    await new Promise<void>((resolve) => server.listen(0, '127.0.0.1', resolve))
    try {
      const { port } = server.address() as AddressInfo
      const config = readTelemetryConfig({ VITE_OTEL_EXPORTER_OTLP_ENDPOINT: `http://127.0.0.1:${port}` })
      const telemetry = createTelemetry({ ...config, serviceName: 'test-frontend' })

      await telemetry.traceFetch(okFetcher)('/info')
      await telemetry.forceFlush()
      await telemetry.shutdown()

      expect(received).toHaveLength(1)
      expect(received[0]?.url).toBe('/v1/traces')
      expect(received[0]?.contentType).toBe('application/json')
      const payload = JSON.parse(received[0]?.body ?? '') as {
        resourceSpans: { resource: { attributes: { key: string; value: { stringValue: string } }[] }; scopeSpans: { spans: { name: string }[] }[] }[]
      }
      expect(payload.resourceSpans[0]?.scopeSpans[0]?.spans.map((span) => span.name)).toEqual(['GET /info'])
      expect(payload.resourceSpans[0]?.resource.attributes).toContainEqual({
        key: 'service.name',
        value: { stringValue: 'test-frontend' },
      })
    } finally {
      await new Promise((resolve) => server.close(resolve))
    }
  })

  it('does nothing and sends nothing if the configuration has no endpoint (no collector)', async () => {
    const fetchStub = vi.fn(okFetcher)
    vi.stubGlobal('fetch', fetchStub)
    const telemetry = createTelemetry(readTelemetryConfig({}))

    const span = telemetry.tracer.startSpan('probe')
    span.end()
    const response = await telemetry.traceFetch(okFetcher)('/status')
    await telemetry.forceFlush()
    await telemetry.shutdown()

    expect(response.status).toBe(200)
    expect(span.spanContext().traceId).toMatch(/^[0-9a-f]{32}$/)
    expect(fetchStub).not.toHaveBeenCalled()
  })
})
