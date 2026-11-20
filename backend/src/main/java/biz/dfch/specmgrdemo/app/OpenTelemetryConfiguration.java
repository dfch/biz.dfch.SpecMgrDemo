package biz.dfch.specmgrdemo.app;

import io.opentelemetry.api.OpenTelemetry;
import io.opentelemetry.api.common.AttributeKey;
import io.opentelemetry.api.trace.Tracer;
import io.opentelemetry.exporter.otlp.http.trace.OtlpHttpSpanExporter;
import io.opentelemetry.exporter.otlp.http.trace.OtlpHttpSpanExporterBuilder;
import io.opentelemetry.sdk.OpenTelemetrySdk;
import io.opentelemetry.sdk.resources.Resource;
import io.opentelemetry.context.Context;
import io.opentelemetry.sdk.trace.ReadWriteSpan;
import io.opentelemetry.sdk.trace.ReadableSpan;
import io.opentelemetry.sdk.trace.SdkTracerProvider;
import io.opentelemetry.sdk.trace.SdkTracerProviderBuilder;
import io.opentelemetry.sdk.trace.SpanProcessor;
import io.opentelemetry.sdk.trace.export.BatchSpanProcessor;
import java.util.LinkedHashMap;
import java.util.Map;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.env.Environment;

/**
 * The OpenTelemetry configuration of the service (feat-9-walking-skeleton, Phase 200, Task 200.110; DEC
 * e3eadec0-a6ea-4efe-8e6d-fd19287122fa: the service runs OpenTelemetry, and the feature gives no collector).
 *
 * <p>The signal is the trace, and the instrumentation is manual (the filter TraceFilter makes the one server
 * span per request, and not a javaagent). The provider is the SDK (SdkTracerProvider), and the SDK gives a real
 * trace identifier for each request in each case:
 *
 * <ul>
 *   <li>with an endpoint (the environment variable OTEL_EXPORTER_OTLP_ENDPOINT, or
 *       OTEL_EXPORTER_OTLP_TRACES_ENDPOINT): the processor is the batch processor of the exporter OTLP/HTTP (the
 *       artifact opentelemetry-exporter-otlp, the sender okhttp), and the span of the request goes to the
 *       collector of the endpoint;
 *   <li>with no endpoint: the processor is a processor that does nothing (the span of the request is real, and
 *       is not exported; the app still starts and serves, for the local run and for the test of CI). The
 *       processor is necessary: the SdkTracerProvider of the SDK 1.6x gives a tracer that is no-op for a
 *       provider with no processor at all (the trace identifier of each request is invalid in this case, and the
 *       response of the error has no real trace identifier).
 * </ul>
 *
 * <p>The configuration is the standard OTEL_* environment variables of the specification: the endpoint (the
 * variable OTEL_EXPORTER_OTLP_TRACES_ENDPOINT is the full address, and the variable OTEL_EXPORTER_OTLP_ENDPOINT
 * is the base address that the path /v1/traces completes), the headers (the variable
 * OTEL_EXPORTER_OTLP_TRACES_HEADERS, or OTEL_EXPORTER_OTLP_HEADERS: a list of the form key=value that the comma
 * separates), and the service name (the variable OTEL_SERVICE_NAME, the default specmgrdemo-backend). The read
 * is through the Spring environment (the bean Environment), so the test names the value with a property of the
 * test (the property has priority over the environment variable), and a blank value is the same as a missing
 * value.
 */
@Configuration
public class OpenTelemetryConfiguration {

  /** The name of the tracer of the service (the scope of the span). */
  public static final String TRACER_NAME = "biz.dfch.specmgrdemo";

  /** The default service name (the member service.name of the OpenTelemetry resource). */
  public static final String DEFAULT_SERVICE_NAME = "specmgrdemo-backend";

  /** The variable of the base endpoint of the OTLP exporter (the specification appends the path /v1/traces). */
  public static final String ENV_OTEL_EXPORTER_OTLP_ENDPOINT = "OTEL_EXPORTER_OTLP_ENDPOINT";

  /** The variable of the full endpoint of the OTLP exporter of the trace signal. */
  public static final String ENV_OTEL_EXPORTER_OTLP_TRACES_ENDPOINT = "OTEL_EXPORTER_OTLP_TRACES_ENDPOINT";

  /** The variable of the headers of the OTLP exporter (the list of key=value that the comma separates). */
  public static final String ENV_OTEL_EXPORTER_OTLP_HEADERS = "OTEL_EXPORTER_OTLP_HEADERS";

  /** The variable of the headers of the OTLP exporter of the trace signal. */
  public static final String ENV_OTEL_EXPORTER_OTLP_TRACES_HEADERS = "OTEL_EXPORTER_OTLP_TRACES_HEADERS";

  /** The variable of the service name (the OpenTelemetry resource specification). */
  public static final String ENV_OTEL_SERVICE_NAME = "OTEL_SERVICE_NAME";

  /** The path of the trace signal that the specification appends to the base endpoint. */
  public static final String OTLP_TRACES_PATH = "/v1/traces";

  /**
   * The OpenTelemetry of the service (the SDK, with or without the exporter OTLP/HTTP - the class Javadoc).
   *
   * @param environment the environment of the service (the properties and the environment variables)
   * @return the OpenTelemetry
   */
  @Bean
  public OpenTelemetry openTelemetry(Environment environment) {
    SdkTracerProvider tracerProvider = tracerProvider(environment);
    return OpenTelemetrySdk.builder().setTracerProvider(tracerProvider).build();
  }

  /**
   * The tracer of the service (the scope of the span of the filter).
   *
   * @param openTelemetry the OpenTelemetry
   * @return the tracer
   */
  @Bean
  public Tracer tracer(OpenTelemetry openTelemetry) {
    return openTelemetry.getTracer(TRACER_NAME);
  }

  /**
   * Make the trace provider of the SDK (the resource with the service name, and the batch processor with the
   * exporter OTLP/HTTP if the configuration has an endpoint - the class Javadoc).
   *
   * @param environment the environment of the service
   * @return the trace provider of the SDK
   */
  static SdkTracerProvider tracerProvider(Environment environment) {
    SdkTracerProviderBuilder builder = SdkTracerProvider.builder().setResource(resource(environment));
    OtlpHttpSpanExporter exporter = exporter(environment);
    if (exporter != null) {
      builder.addSpanProcessor(BatchSpanProcessor.create(exporter));
    } else {
      // The processor that does nothing (the class Javadoc): the provider has always a processor, so the SDK
      // gives a real tracer for the service, and the trace identifier of each request is a real value.
      builder.addSpanProcessor(NO_OP_PROCESSOR);
    }
    return builder.build();
  }

  /**
   * The processor that does nothing: it records no span, and it exports no span. The instance is the one for
   * each provider that has no endpoint of the exporter (the class Javadoc).
   */
  private static final SpanProcessor NO_OP_PROCESSOR =
      new SpanProcessor() {
        @Override
        public void onStart(Context parentContext, ReadWriteSpan span) {
          // No action: the span is not recorded, and not exported.
        }

        @Override
        public boolean isStartRequired() {
          return false;
        }

        @Override
        public void onEnd(ReadableSpan span) {
          // No action: the span is not recorded, and not exported.
        }

        @Override
        public boolean isEndRequired() {
          return false;
        }
      };

  /**
   * Make the resource of the provider (the member service.name: the variable OTEL_SERVICE_NAME, or the
   * default).
   *
   * @param environment the environment of the service
   * @return the resource
   */
  static Resource resource(Environment environment) {
    return Resource.builder().put(AttributeKey.stringKey("service.name"), serviceName(environment)).build();
  }

  /**
   * The service name (the class Javadoc).
   *
   * @param environment the environment of the service
   * @return the name
   */
  static String serviceName(Environment environment) {
    String name = environment.getProperty(ENV_OTEL_SERVICE_NAME);
    if (name == null || name.isBlank()) {
      return DEFAULT_SERVICE_NAME;
    }
    return name;
  }

  /**
   * Make the exporter OTLP/HTTP of the trace signal, or null if the configuration has no endpoint (the class
   * Javadoc).
   *
   * @param environment the environment of the service
   * @return the exporter, or null
   */
  static OtlpHttpSpanExporter exporter(Environment environment) {
    String endpoint = endpointOf(environment);
    if (endpoint == null) {
      return null;
    }
    OtlpHttpSpanExporterBuilder builder = OtlpHttpSpanExporter.builder().setEndpoint(endpoint);
    String variable = ENV_OTEL_EXPORTER_OTLP_TRACES_HEADERS;
    String headers = environment.getProperty(variable);
    if (headers == null || headers.isBlank()) {
      variable = ENV_OTEL_EXPORTER_OTLP_HEADERS;
      headers = environment.getProperty(variable);
    }
    if (headers != null && !headers.isBlank()) {
      // The read is at the start of the service (and not at the first export): a list that is not valid stops the
      // start with a message that has no value of the list.
      Map<String, String> values = readHeaders(variable, headers);
      builder.setHeaders(() -> values);
    }
    return builder.build();
  }

  /**
   * The endpoint of the exporter of the trace signal (the class Javadoc): the address complete of the variable
   * OTEL_EXPORTER_OTLP_TRACES_ENDPOINT, or the address of base of the variable OTEL_EXPORTER_OTLP_ENDPOINT that
   * the path /v1/traces completes, or null if the configuration has no endpoint. A blank value is the same as
   * a missing value.
   *
   * @param environment the environment of the service
   * @return the endpoint, or null
   */
  static String endpointOf(Environment environment) {
    String endpoint = environment.getProperty(ENV_OTEL_EXPORTER_OTLP_TRACES_ENDPOINT);
    if (endpoint != null && !endpoint.isBlank()) {
      return endpoint;
    }
    String base = environment.getProperty(ENV_OTEL_EXPORTER_OTLP_ENDPOINT);
    if (base != null && !base.isBlank()) {
      return base.endsWith("/") ? base + OTLP_TRACES_PATH.substring(1) : base + OTLP_TRACES_PATH;
    }
    return null;
  }

  /**
   * Read the headers (the list of the form key=value that the comma separates - the class Javadoc). The list can
   * have a secret (for example a token), so the message of a failure names the variable and the position of the
   * entry (the first entry is 1), and never the text of the list.
   *
   * @param variable the name of the variable that has the list
   * @param value the list
   * @return the map of the headers
   * @throws IllegalStateException if an entry is not in the form key=value
   */
  static Map<String, String> readHeaders(String variable, String value) {
    Map<String, String> result = new LinkedHashMap<>();
    String[] entries = value.split(",");
    for (int index = 0; index < entries.length; index++) {
      String entry = entries[index];
      if (entry.isBlank()) {
        continue;
      }
      int separator = entry.indexOf('=');
      if (separator <= 0 || entry.substring(0, separator).isBlank()) {
        throw new IllegalStateException(
            "The entry " + (index + 1) + " of the list in the variable " + variable + " is not in the form key=value.");
      }
      result.put(entry.substring(0, separator).trim(), entry.substring(separator + 1).trim());
    }
    return result;
  }
}
