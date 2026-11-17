package biz.dfch.specmgrdemo.app;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import org.junit.jupiter.api.Test;
import org.springframework.mock.env.MockEnvironment;

/**
 * The unit test of the OpenTelemetry configuration (feat-9-walking-skeleton, Phase 200, Task 200.110; DEC
 * e3eadec0-a6ea-4efe-8e6d-fd19287122fa). The configuration reads the standard OTEL_* variables of the
 * specification through the environment (the test names the value with a property of the MockEnvironment, and
 * a blank value is the same as a missing value): with the endpoint, the exporter OTLP/HTTP (the address
 * complete of the variable ..._TRACES_ENDPOINT, or the address of base of the variable ..._ENDPOINT that the
 * path /v1/traces completes, and the header of the form key=value that the comma separates); with no endpoint,
 * no exporter (the app still starts and serves).
 */
class OpenTelemetryConfigurationTest {

  @Test
  void theConfigurationHasNoEndpointAndNoExporterWithoutTheVariable() {
    MockEnvironment environment = new MockEnvironment();
    assertNull(OpenTelemetryConfiguration.endpointOf(environment));
    assertNull(OpenTelemetryConfiguration.exporter(environment));
  }

  @Test
  void theConfigurationTreatsABlankVariableAsAVariableThatIsNotSet() {
    MockEnvironment environment = new MockEnvironment();
    environment.setProperty(OpenTelemetryConfiguration.ENV_OTEL_EXPORTER_OTLP_ENDPOINT, " ");
    assertNull(OpenTelemetryConfiguration.endpointOf(environment));
  }

  @Test
  void theConfigurationUsesTheTracesEndpointAsIs() {
    MockEnvironment environment = new MockEnvironment();
    environment.setProperty(OpenTelemetryConfiguration.ENV_OTEL_EXPORTER_OTLP_TRACES_ENDPOINT, "http://collector:4318/custom");
    assertEquals("http://collector:4318/custom", OpenTelemetryConfiguration.endpointOf(environment));
    assertTrue(OpenTelemetryConfiguration.exporter(environment) != null, "the exporter is built from the address complete");
  }

  @Test
  void theConfigurationPrefersTheTracesEndpointOverTheBaseEndpoint() {
    MockEnvironment environment = new MockEnvironment();
    environment.setProperty(OpenTelemetryConfiguration.ENV_OTEL_EXPORTER_OTLP_TRACES_ENDPOINT, "http://collector:4318/custom");
    environment.setProperty(OpenTelemetryConfiguration.ENV_OTEL_EXPORTER_OTLP_ENDPOINT, "http://collector:4318");
    assertEquals("http://collector:4318/custom", OpenTelemetryConfiguration.endpointOf(environment));
  }

  @Test
  void theConfigurationAppendsTheTracesPathToTheBaseEndpoint() {
    MockEnvironment environment = new MockEnvironment();
    environment.setProperty(OpenTelemetryConfiguration.ENV_OTEL_EXPORTER_OTLP_ENDPOINT, "http://collector:4318");
    assertEquals("http://collector:4318/v1/traces", OpenTelemetryConfiguration.endpointOf(environment));
    assertTrue(OpenTelemetryConfiguration.exporter(environment) != null, "the exporter is built from the base endpoint");
  }

  @Test
  void theConfigurationAppendsTheTracesPathToABaseEndpointWithATrailingSlash() {
    MockEnvironment environment = new MockEnvironment();
    environment.setProperty(OpenTelemetryConfiguration.ENV_OTEL_EXPORTER_OTLP_ENDPOINT, "http://collector:4318/");
    assertEquals("http://collector:4318/v1/traces", OpenTelemetryConfiguration.endpointOf(environment));
  }

  @Test
  void theConfigurationReadsTheHeaders() {
    assertEquals(
        java.util.Map.of("authorization", "Bearer key", "x-scope", "org"),
        OpenTelemetryConfiguration.readHeaders("authorization=Bearer key, x-scope=org"));
  }

  @Test
  void theConfigurationStopsForAHeaderThatIsNotInTheForm() {
    IllegalStateException result = assertThrows(IllegalStateException.class, () -> OpenTelemetryConfiguration.readHeaders("a-header"));
    assertTrue(result.getMessage().contains("a-header"));
  }

  @Test
  void theConfigurationReadsTheServiceNameWithTheDefault() {
    assertEquals("specmgrdemo-backend", OpenTelemetryConfiguration.serviceName(new MockEnvironment()));
    MockEnvironment environment = new MockEnvironment();
    environment.setProperty(OpenTelemetryConfiguration.ENV_OTEL_SERVICE_NAME, "the-service");
    assertEquals("the-service", OpenTelemetryConfiguration.serviceName(environment));
  }

  @Test
  void theConfigurationMakesTheResourceWithTheServiceName() {
    MockEnvironment environment = new MockEnvironment();
    var resource = OpenTelemetryConfiguration.resource(environment);
    var key = io.opentelemetry.api.common.AttributeKey.stringKey("service.name");
    assertEquals("specmgrdemo-backend", resource.getAttributes().get(key));
  }
}
