// The configuration of the OpenTelemetry of the browser (feat-9-walking-skeleton, Phase 300, Task 300.130, DEC
// e3eadec0-a6ea-4efe-8e6d-fd19287122fa). The names follow the standard variables OTEL_* of OpenTelemetry (as the
// backend does, the class OpenTelemetryConfiguration), with the prefix VITE_ that Vite needs to put a variable
// in the bundle (the build-time configuration; the value is public, so it holds no secret: the configuration
// has no variable for the headers of the exporter, because a header with a token would be in the bundle):
//
// - VITE_OTEL_EXPORTER_OTLP_TRACES_ENDPOINT: the full address of the exporter of the traces.
// - VITE_OTEL_EXPORTER_OTLP_ENDPOINT: the base address that the path /v1/traces completes (OTLP/HTTP).
// - VITE_OTEL_SERVICE_NAME: the name of the service (the default is specmgrdemo-frontend).
//
// No address (the missing variable and the empty variable are the same) means: no collector, and the
// processor of the spans does nothing (the feature gives no collector, REQ-004).

export interface TelemetryConfig {
  /** The full address of the exporter OTLP/HTTP of the traces, or `undefined` (no collector). */
  readonly endpoint: string | undefined
  /** The name of the service in the resource of the spans. */
  readonly serviceName: string
}

export const defaultServiceName = 'specmgrdemo-frontend'

const tracesPath = '/v1/traces'

function clean(value: string | undefined): string | undefined {
  const trimmed = value?.trim()
  return trimmed === undefined || trimmed === '' ? undefined : trimmed
}

/** Read the configuration from the variables of the environment (the `import.meta.env` of Vite in the product). */
export function readTelemetryConfig(env: Readonly<Record<string, string | undefined>>): TelemetryConfig {
  const tracesEndpoint = clean(env.VITE_OTEL_EXPORTER_OTLP_TRACES_ENDPOINT)
  const baseEndpoint = clean(env.VITE_OTEL_EXPORTER_OTLP_ENDPOINT)
  const endpoint = tracesEndpoint ?? (baseEndpoint === undefined ? undefined : baseEndpoint.replace(/\/+$/, '') + tracesPath)
  return { endpoint, serviceName: clean(env.VITE_OTEL_SERVICE_NAME) ?? defaultServiceName }
}
