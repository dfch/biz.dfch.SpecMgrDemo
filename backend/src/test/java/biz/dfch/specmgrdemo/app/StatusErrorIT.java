package biz.dfch.specmgrdemo.app;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;
import java.util.List;
import java.util.Set;
import java.util.TreeSet;
import java.util.regex.Pattern;
import org.junit.jupiter.api.AfterAll;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import tools.jackson.databind.JsonNode;
import tools.jackson.databind.json.JsonMapper;

/**
 * The integration test of the error response of the operation GET /status (feat-9-walking-skeleton, Phase 200,
 * Task 200.110; REQ 1ca335d7-969a-443e-9392-165fdeea99a0: "If the system cannot give its state, it sends an
 * error response"). The service starts with the property app.state-checker fail (the class RunningService, the seam of the
 * StatusConfiguration, the check FailingStateChecker), and the operation gives the error response: the media
 * type application/problem+json, the code service_unavailable of the list ErrorCode of the contract, the status
 * 503, and the trace identifier of the request in the member traceId (the one server span per request of the
 * filter TraceFilter, the 32 lower case hexadecimal characters of the W3C form, the pattern of the contract).
 * The operation GET /info is no part of the failure of the check, and it gives its response 200. The OTEL_*
 * variables have the empty value (the test is deterministic, and the feature gives no collector).
 *
 * <p>The test of the phase 400 (the task 400.100) has the identifier of its verification case record in the
 * display name (the text vcr:&lt;uuid&gt;, DEC f21920d2-4da5-4cf7-bd94-2e9bcba77342): the verification case record
 * 4f98618c-4291-4d60-995f-1fd8a60b9bfd, the criterion AC-002 (the test makes the check of the state fail).
 */
class StatusErrorIT {

  private static final Pattern TRACE_ID = Pattern.compile("^[0-9a-f]{32}$");

  /** The value of the list ErrorCode of the contract: the lower case words that the character underscore joins. */
  private static final Pattern CODE_VALUE = Pattern.compile("^[a-z]+(_[a-z]+)*$");

  /**
   * The members that the response of the error has, and no other: the machine values of the schema Problem of the
   * contract. The members title and detail of the schema are optional English text for the log (the rule
   * problem-members of the linter), and the service does not send them (REQ 1ca335d7-969a-443e-9392-165fdeea99a0:
   * the response has no text in a language).
   */
  private static final Set<String> MACHINE_MEMBERS = Set.of("type", "status", "instance", "code", "traceId");

  private static final JsonMapper JSON = JsonMapper.builder().build();

  private static RunningService service;

  private static int port;

  @BeforeAll
  static void startTheService() {
    service = RunningService.start("--app.state-checker=fail");
    port = service.port();
  }

  @AfterAll
  static void stopTheService() {
    service.close();
  }

  @Test
  @DisplayName("vcr:4f98618c-4291-4d60-995f-1fd8a60b9bfd the operation gives the error response")
  void theOperationGivesTheErrorResponse() throws Exception {
    // The steps of the criterion AC-002 of the verification case record: the test makes the check of the state
    // fail (the class starts the service with the property app.state-checker fail), the client sends the request
    // GET /status, the response has the media type application/problem+json, an error code and a trace
    // identifier, and the response has no text in a language.
    HttpResponse<String> response = get("/status");
    assertEquals(503, response.statusCode(), "the status 503 of the error response");
    assertTrue(
        response.headers().firstValue("Content-Type").orElse("").startsWith("application/problem+json"),
        "the media type application/problem+json");
    JsonNode body = JSON.readTree(response.body());
    assertEquals("service_unavailable", body.path("code").asString(), "the code of the list ErrorCode: " + response.body());
    assertEquals(503, body.path("status").asInt(), "the status of the member of the schema Problem: " + response.body());
    String found = body.path("traceId").asString();
    assertTrue(TRACE_ID.matcher(found).matches(), "the response has the member traceId: " + response.body());
    assertNotEquals("00000000000000000000000000000000", found, "the trace identifier is the real value of the request");

    // No text in a language: the members of the response are exactly the machine members (the member code is the
    // value of the list ErrorCode, and the frontend has the text of each code in its catalog), and no member has
    // the English text of the schema Problem (title, detail) or another text (message and the like).
    Set<String> members = new TreeSet<>();
    body.propertyNames().forEach(members::add);
    assertEquals(new TreeSet<>(MACHINE_MEMBERS), members, "the members of the response of the error: " + response.body());
    for (String text : List.of("title", "detail", "message", "localizedMessage", "text", "userMessage")) {
      assertFalse(members.contains(text), "the response has no member for a text in a language: " + members);
    }
    for (String member : members) {
      assertFalse(body.path(member).isNull(), "the member " + member + " has a value: " + response.body());
      // A value of prose has spaces: the machine values (a code, a number, an identifier, a path) have none.
      assertFalse(body.path(member).isString() && body.path(member).asString().matches(".*\\s.*"), "the member " + member + " is no sentence: " + response.body());
    }
    assertTrue(CODE_VALUE.matcher(body.path("code").asString()).matches(), "the code is a machine value and no sentence: " + response.body());
  }

  @Test
  void theOperationInfoIsNotPartOfTheFailureOfTheCheck() throws Exception {
    HttpResponse<String> response = get("/info");
    assertEquals(200, response.statusCode(), "the response 200 of the operation GET /info");
    assertTrue(response.body().contains("\"version\":\"0.2.0\""), "the version of the build: " + response.body());
  }

  /**
   * Make the request GET of the path.
   *
   * @param path the path of the operation
   * @return the response
   * @throws Exception if the request fails
   */
  private static HttpResponse<String> get(String path) throws Exception {
    HttpClient client = HttpClient.newBuilder().connectTimeout(Duration.ofSeconds(5)).build();
    HttpRequest request = HttpRequest.newBuilder(URI.create("http://127.0.0.1:" + port + path)).GET().build();
    return client.send(request, HttpResponse.BodyHandlers.ofString());
  }
}
