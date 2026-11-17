package biz.dfch.specmgrdemo.app;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;
import java.util.regex.Pattern;
import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.server.LocalServerPort;

/**
 * The integration test of the error response of the operation GET /status (feat-9-walking-skeleton, Phase 200,
 * Task 200.110; REQ 1ca335d7-969a-443e-9392-165fdeea99a0: "If the system cannot give its state, it sends an
 * error response"). The service starts with the property app.state-checker fail (the seam of the
 * StatusConfiguration, the check FailingStateChecker), and the operation gives the error response: the media
 * type application/problem+json, the code service_unavailable of the list ErrorCode of the contract, the status
 * 503, and the trace identifier of the request in the member traceId (the one server span per request of the
 * filter TraceFilter, the 32 lower case hexadecimal characters of the W3C form, the pattern of the contract).
 * The operation GET /info is no part of the failure of the check, and it gives its response 200. The OTEL_*
 * variables have the empty value (the test is deterministic, and the feature gives no collector).
 */
@SpringBootTest(
    webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT,
    properties = {
      "app.state-checker=fail",
      "OTEL_EXPORTER_OTLP_ENDPOINT=",
      "OTEL_EXPORTER_OTLP_TRACES_ENDPOINT=",
      "OTEL_EXPORTER_OTLP_HEADERS=",
      "OTEL_EXPORTER_OTLP_TRACES_HEADERS="
    })
class StatusErrorIT {

  private static final Pattern TRACE_ID = Pattern.compile("^[0-9a-f]{32}$");

  @LocalServerPort
  private int port;

  @Test
  void theOperationSendsTheErrorResponseIfTheSystemCannotGiveItsState() throws Exception {
    HttpResponse<String> response = get("/status");
    assertEquals(503, response.statusCode(), "the status 503 of the error response");
    assertTrue(
        response.headers().firstValue("Content-Type").orElse("").startsWith("application/problem+json"),
        "the media type application/problem+json");
    assertTrue(response.body().contains("\"code\":\"service_unavailable\""), "the code of the list ErrorCode: " + response.body());
    assertTrue(response.body().contains("\"status\":503"), "the status of the member of the schema Problem: " + response.body());
    var matcher = Pattern.compile("\"traceId\":\"([0-9a-f]{32})\"").matcher(response.body());
    assertTrue(matcher.find(), "the response has the member traceId: " + response.body());
    String found = matcher.group(1);
    assertTrue(TRACE_ID.matcher(found).matches());
    assertTrue(!"00000000000000000000000000000000".equals(found), "the trace identifier is the real value of the request");
  }

  @Test
  void theOperationInfoIsNotPartOfTheFailureOfTheCheck() throws Exception {
    HttpResponse<String> response = get("/info");
    assertEquals(200, response.statusCode(), "the response 200 of the operation GET /info");
    assertTrue(response.body().contains("\"version\":\"0.1.0\""), "the version of the build: " + response.body());
  }

  /**
   * Make the request GET of the path.
   *
   * @param path the path of the operation
   * @return the response
   * @throws Exception if the request fails
   */
  private HttpResponse<String> get(String path) throws Exception {
    HttpClient client = HttpClient.newBuilder().connectTimeout(Duration.ofSeconds(5)).build();
    HttpRequest request = HttpRequest.newBuilder(URI.create("http://127.0.0.1:" + port + path)).GET().build();
    return client.send(request, HttpResponse.BodyHandlers.ofString());
  }
}
