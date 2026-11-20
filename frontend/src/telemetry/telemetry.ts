import { SpanKind, SpanStatusCode, type Tracer } from '@opentelemetry/api'
import { OTLPTraceExporter } from '@opentelemetry/exporter-trace-otlp-http'
import { resourceFromAttributes } from '@opentelemetry/resources'
import {
  BatchSpanProcessor,
  NoopSpanProcessor,
  WebTracerProvider,
  type SpanExporter,
  type SpanProcessor,
} from '@opentelemetry/sdk-trace-web'
import type { TelemetryConfig } from './config'

// The OpenTelemetry of the browser (feat-9-walking-skeleton, Phase 300, Task 300.130, REQ-004, DEC
// e3eadec0-a6ea-4efe-8e6d-fd19287122fa): the Web SDK (@opentelemetry/sdk-trace-web) and the exporter OTLP/HTTP
// (@opentelemetry/exporter-trace-otlp-http). The feature gives no collector: with no address in the
// configuration, the processor of the spans does nothing (the NoopSpanProcessor), and the application runs
// the same. With an address, the spans go to the exporter OTLP/HTTP of that address (the BatchSpanProcessor).
//
// The module sets no global state (no provider is registered in @opentelemetry/api, no propagator, no context
// manager): the application holds the object that createTelemetry returns, and the tests make as many as they
// need. The spans have no data about persons (the name of the span and the attributes have the method of the
// HTTP, the path of the URL and the status code only, and not the query and not the body).

/** The function that makes a request (the same shape as the `Fetcher` of the client of the API). */
export type TracedFetch = (input: string, init?: RequestInit) => Promise<Response>

export interface Telemetry {
  /** The tracer of the application. */
  readonly tracer: Tracer
  /** Give a function that makes a request, and that makes one span of the kind CLIENT for each request. */
  traceFetch(fetcher: TracedFetch): TracedFetch
  /** Send the spans that are not sent yet to the exporter. */
  forceFlush(): Promise<void>
  /** Send the spans that are not sent yet, and stop the processor. */
  shutdown(): Promise<void>
}

export const tracerName = 'biz.dfch.specmgrdemo.frontend'

/**
 * Make the processor of the spans: the one that does nothing if there is no exporter, and the batch processor
 * of the exporter if there is one. The exporter is the argument `exporter` (the seam of the tests: an in-memory
 * exporter), or the exporter OTLP/HTTP of the address of the configuration.
 */
function createProcessor(config: TelemetryConfig, exporter: SpanExporter | undefined): SpanProcessor {
  const target = exporter ?? (config.endpoint === undefined ? undefined : new OTLPTraceExporter({ url: config.endpoint }))
  return target === undefined ? new NoopSpanProcessor() : new BatchSpanProcessor(target)
}

/** The path of the URL (no query, no fragment, no host: the span has no data about persons). */
function pathOf(url: string): string {
  return new URL(url, 'http://localhost').pathname
}

/**
 * Make the telemetry of the application.
 *
 * @param config the configuration (readTelemetryConfig)
 * @param exporter the exporter of the spans, instead of the exporter OTLP/HTTP of the configuration (the seam of
 *   the tests)
 */
export function createTelemetry(config: TelemetryConfig, exporter?: SpanExporter): Telemetry {
  const provider = new WebTracerProvider({
    resource: resourceFromAttributes({ 'service.name': config.serviceName }),
    spanProcessors: [createProcessor(config, exporter)],
  })
  const tracer = provider.getTracer(tracerName)
  return {
    tracer,
    traceFetch: (fetcher) => async (input, init) => {
      const method = init?.method ?? 'GET'
      const path = pathOf(input)
      const span = tracer.startSpan(`${method} ${path}`, {
        kind: SpanKind.CLIENT,
        attributes: { 'http.request.method': method, 'url.path': path },
      })
      try {
        const response = await fetcher(input, init)
        span.setAttribute('http.response.status_code', response.status)
        if (response.status >= 400) {
          span.setStatus({ code: SpanStatusCode.ERROR })
        }
        return response
      } catch (error) {
        span.setStatus({ code: SpanStatusCode.ERROR, message: error instanceof Error ? error.name : 'error' })
        throw error
      } finally {
        span.end()
      }
    },
    forceFlush: () => provider.forceFlush(),
    shutdown: () => provider.shutdown(),
  }
}
