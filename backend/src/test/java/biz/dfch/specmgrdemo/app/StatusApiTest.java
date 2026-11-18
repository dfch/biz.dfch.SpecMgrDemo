package biz.dfch.specmgrdemo.app;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import biz.dfch.specmgrdemo.model.Status;
import biz.dfch.specmgrdemo.model.Status.StateEnum;
import io.opentelemetry.api.trace.Span;
import io.opentelemetry.api.trace.SpanContext;
import io.opentelemetry.api.trace.TraceFlags;
import java.time.OffsetDateTime;
import java.time.ZoneOffset;
import java.util.List;
import java.util.Set;
import java.util.TreeSet;
import java.util.concurrent.CopyOnWriteArrayList;
import org.apache.logging.log4j.Level;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.core.LogEvent;
import org.apache.logging.log4j.core.Logger;
import org.apache.logging.log4j.core.appender.AbstractAppender;
import org.apache.logging.log4j.core.config.Property;
import org.junit.jupiter.api.Test;
import org.springframework.http.MediaType;
import org.springframework.http.converter.json.JacksonJsonHttpMessageConverter;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import tools.jackson.databind.JsonNode;
import tools.jackson.databind.cfg.DateTimeFeature;
import tools.jackson.databind.json.JsonMapper;

/**
 * The unit test of the operation GET /status (feat-9-walking-skeleton, Phase 200, Task 200.110; REQ
 * 1ca335d7-969a-443e-9392-165fdeea99a0). The controller gives the state (the condition up or degraded, and
 * the time of the check) as the response 200. If the system cannot give its state, the check of the state
 * throws the failure StatusCheckException (the seam StateChecker), and the handler of the error
 * (ProblemAdvice) sends the error response: the media type application/problem+json, the code
 * service_unavailable, the status 503, and the trace identifier of the request (the span that is current, the
 * 32 lower case hexadecimal characters of the W3C form, the pattern of the contract). Each other failure of
 * the operation is the code internal_error with the status 500.
 */
class StatusApiTest {

  private static final String TRACE_ID_OF_THE_TEST = "0af7651916cd43dd8448eb211c80319c";

  private static final String SPAN_ID_OF_THE_TEST = "b7ad6b7169203331";

  @Test
  void theOperationGivesTheStateOfTheCheck() throws Exception {
    MockMvc mockMvc = setup(new UpStateChecker());
    mockMvc
        .perform(get("/status"))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.state").value("up"))
        .andExpect(jsonPath("$.checkedAt").isString());
  }

  @Test
  void theOperationGivesTheConditionDegradedOfTheCheck() throws Exception {
    MockMvc mockMvc = setup(checkThatGives(StateEnum.DEGRADED));
    mockMvc.perform(get("/status")).andExpect(status().isOk()).andExpect(jsonPath("$.state").value("degraded"));
  }

  @Test
  void theOperationSendsTheErrorResponseIfTheSystemCannotGiveItsState() throws Exception {
    MockMvc mockMvc = setup(new FailingStateChecker());
    // The span that is current (the mechanism of the filter TraceFilter in the service): the handler of the
    // error finds the trace identifier of the request, and the response has it in the member traceId.
    try (io.opentelemetry.context.Scope ignored = theSpanOfTheTest().makeCurrent()) {
      mockMvc
          .perform(get("/status"))
          .andExpect(status().isServiceUnavailable())
          .andExpect(jsonPath("$.code").value("service_unavailable"))
          .andExpect(jsonPath("$.status").value(503))
          .andExpect(jsonPath("$.traceId").value(TRACE_ID_OF_THE_TEST));
    }
  }

  @Test
  void theOperationSendsTheErrorResponseIfTheCheckFailsWithAnotherFailure() throws Exception {
    MockMvc mockMvc = setup(checkThatThrows(new IllegalStateException("the check of the state failed")));
    try (io.opentelemetry.context.Scope ignored = theSpanOfTheTest().makeCurrent()) {
      mockMvc
          .perform(get("/status"))
          .andExpect(status().isInternalServerError())
          .andExpect(jsonPath("$.code").value("internal_error"))
          .andExpect(jsonPath("$.status").value(500))
          .andExpect(jsonPath("$.traceId").value(TRACE_ID_OF_THE_TEST));
    }
  }

  /** The members that the response of the error may have: no member carries a text in a language. */
  private static final Set<String> MACHINE_MEMBERS = Set.of("type", "status", "instance", "code", "traceId");

  private static final JsonMapper JSON = JsonMapper.builder().build();

  @Test
  void anUnknownPathGivesTheErrorResponseNotFound() throws Exception {
    MockMvc mockMvc = setup(new UpStateChecker());
    try (io.opentelemetry.context.Scope ignored = theSpanOfTheTest().makeCurrent()) {
      MvcResult result =
          mockMvc
              .perform(get("/nope"))
              .andExpect(status().isNotFound())
              .andExpect(content().contentTypeCompatibleWith("application/problem+json"))
              .andExpect(jsonPath("$.code").value("not_found"))
              .andExpect(jsonPath("$.status").value(404))
              .andExpect(jsonPath("$.instance").value("/nope"))
              .andExpect(jsonPath("$.traceId").value(TRACE_ID_OF_THE_TEST))
              .andReturn();
      assertMachineMembersOnly(result);
    }
  }

  @Test
  void aWrongMethodGivesTheErrorResponseWithTheStatus405AndTheHeaderAllow() throws Exception {
    MockMvc mockMvc = setup(new UpStateChecker());
    try (io.opentelemetry.context.Scope ignored = theSpanOfTheTest().makeCurrent()) {
      MvcResult result =
          mockMvc
              .perform(post("/status"))
              .andExpect(status().isMethodNotAllowed())
              .andExpect(content().contentTypeCompatibleWith("application/problem+json"))
              .andExpect(
                  mvcResult ->
                      assertTrue(
                          String.valueOf(mvcResult.getResponse().getHeader("Allow")).contains("GET"),
                          "the header Allow of the status 405"))
              .andExpect(jsonPath("$.code").value("method_not_allowed"))
              .andExpect(jsonPath("$.status").value(405))
              .andExpect(jsonPath("$.traceId").value(TRACE_ID_OF_THE_TEST))
              .andReturn();
      assertMachineMembersOnly(result);
    }
  }

  @Test
  void aMediaTypeThatTheOperationCannotGiveGivesTheErrorResponseWithTheStatus406() throws Exception {
    MockMvc mockMvc = setup(new UpStateChecker());
    try (io.opentelemetry.context.Scope ignored = theSpanOfTheTest().makeCurrent()) {
      MvcResult result =
          mockMvc
              .perform(get("/status").accept(MediaType.TEXT_PLAIN))
              .andExpect(status().isNotAcceptable())
              .andExpect(content().contentTypeCompatibleWith("application/problem+json"))
              .andExpect(jsonPath("$.code").value("not_acceptable"))
              .andExpect(jsonPath("$.status").value(406))
              .andReturn();
      assertMachineMembersOnly(result);
    }
  }

  @Test
  void theCodeOfAnErrorOfSpringWebMvcIsAValueOfTheListErrorCode() {
    assertEquals("not_found", ProblemAdvice.codeOf(org.springframework.http.HttpStatus.NOT_FOUND).getValue());
    assertEquals("method_not_allowed", ProblemAdvice.codeOf(org.springframework.http.HttpStatus.METHOD_NOT_ALLOWED).getValue());
    assertEquals("not_acceptable", ProblemAdvice.codeOf(org.springframework.http.HttpStatus.NOT_ACCEPTABLE).getValue());
    assertEquals("rate_limited", ProblemAdvice.codeOf(org.springframework.http.HttpStatus.TOO_MANY_REQUESTS).getValue());
    assertEquals("service_unavailable", ProblemAdvice.codeOf(org.springframework.http.HttpStatus.SERVICE_UNAVAILABLE).getValue());
    assertEquals("internal_error", ProblemAdvice.codeOf(org.springframework.http.HttpStatus.BAD_GATEWAY).getValue());
    assertEquals("validation_failed", ProblemAdvice.codeOf(org.springframework.http.HttpStatus.BAD_REQUEST).getValue());
    assertEquals("validation_failed", ProblemAdvice.codeOf(org.springframework.http.HttpStatus.UNSUPPORTED_MEDIA_TYPE).getValue());
  }

  @Test
  void theResponseOfAnUnexpectedFailureHasNoTextOfTheFailureAndTheFailureIsInTheLog() throws Exception {
    String secret = "the-secret-text-of-the-failure";
    MockMvc mockMvc = setup(checkThatThrows(new IllegalStateException(secret)));
    List<LogEvent> events =
        withLog(
            () -> {
              MvcResult result =
                  mockMvc
                      .perform(get("/status"))
                      .andExpect(status().isInternalServerError())
                      .andExpect(jsonPath("$.code").value("internal_error"))
                      .andReturn();
              String body = result.getResponse().getContentAsString();
              assertFalse(body.contains(secret), "the response has no text of the failure: " + body);
              assertFalse(body.contains("IllegalStateException"), "the response has no name of the class of the failure: " + body);
              assertMachineMembersOnly(result);
            });
    assertEquals(1, events.size(), "the failure is in the log once: " + events);
    LogEvent event = events.get(0);
    assertEquals(Level.ERROR, event.getLevel());
    assertTrue(event.getMessage().getFormattedMessage().contains(TRACE_ID_OF_THE_TEST), "the entry of the log has the trace identifier");
    assertTrue(event.getThrown() != null && secret.equals(event.getThrown().getMessage()), "the entry of the log has the failure");
  }

  @Test
  void anErrorOfTheServerThatSpringGivesKeepsItsStatusAndIsInTheLogAsAnError() throws Exception {
    MockMvc mockMvc = setup(checkThatThrows(new org.springframework.web.ErrorResponseException(org.springframework.http.HttpStatus.BAD_GATEWAY)));
    List<LogEvent> events =
        withLog(
            () -> {
              MvcResult result =
                  mockMvc
                      .perform(get("/status"))
                      .andExpect(status().isBadGateway())
                      .andExpect(jsonPath("$.code").value("internal_error"))
                      .andExpect(jsonPath("$.status").value(502))
                      .andReturn();
              assertMachineMembersOnly(result);
            });
    assertEquals(1, events.size());
    assertEquals(Level.ERROR, events.get(0).getLevel());
  }

  @Test
  void aValueOfTheWrongTypeAndAnUnreadableRequestGiveTheCodeValidationFailed() throws Exception {
    for (RuntimeException failure :
        new RuntimeException[] {
          new org.springframework.beans.TypeMismatchException("the value", String.class),
          new org.springframework.http.converter.HttpMessageNotReadableException("the secret text", (org.springframework.http.HttpInputMessage) null)
        }) {
      MockMvc mockMvc = setup(checkThatThrows(failure));
      try (io.opentelemetry.context.Scope ignored = theSpanOfTheTest().makeCurrent()) {
        MvcResult result =
            mockMvc
                .perform(get("/status"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value("validation_failed"))
                .andExpect(jsonPath("$.status").value(400))
                .andReturn();
        assertMachineMembersOnly(result);
        assertFalse(result.getResponse().getContentAsString().contains("secret"), "the response has no text of the failure");
      }
    }
  }

  @Test
  void anErrorOfTheClientIsInTheLogAtTheLevelDebugOnly() throws Exception {
    MockMvc mockMvc = setup(new UpStateChecker());
    List<LogEvent> events = withLog(() -> mockMvc.perform(get("/nope")).andExpect(status().isNotFound()));
    assertEquals(1, events.size());
    assertEquals(Level.DEBUG, events.get(0).getLevel());
  }

  /** The action of a test that needs the log of the handler of the error. */
  @FunctionalInterface
  private interface LoggedAction {
    void run() throws Exception;
  }

  /**
   * Run the action with the span of the test, and return the events that the handler of the error
   * (ProblemAdvice) wrote to the log during the action (all levels from DEBUG).
   *
   * @param action the action
   * @return the events
   * @throws Exception if the action fails
   */
  private static List<LogEvent> withLog(LoggedAction action) throws Exception {
    Logger logger = (Logger) LogManager.getLogger(ProblemAdvice.class);
    LogCapture capture = new LogCapture();
    Level before = logger.getLevel();
    logger.addAppender(capture);
    logger.setLevel(Level.DEBUG);
    capture.start();
    try (io.opentelemetry.context.Scope ignored = theSpanOfTheTest().makeCurrent()) {
      action.run();
    } finally {
      capture.stop();
      logger.removeAppender(capture);
      logger.setLevel(before);
    }
    return capture.events;
  }

  /**
   * Assert that the response of the error has no member for a text in a language: the members are the machine
   * members only (the members title and detail of the schema Problem are not sent).
   *
   * @param result the result of the request
   * @throws Exception if the body cannot be read
   */
  private static void assertMachineMembersOnly(MvcResult result) throws Exception {
    JsonNode body = JSON.readTree(result.getResponse().getContentAsString());
    Set<String> members = new TreeSet<>();
    body.propertyNames().forEach(members::add);
    assertEquals(new TreeSet<>(MACHINE_MEMBERS), members, "the members of the response of the error");
  }

  /** The appender that keeps the events of the log (the test reads them). */
  private static final class LogCapture extends AbstractAppender {

    private final List<LogEvent> events = new CopyOnWriteArrayList<>();

    LogCapture() {
      super("capture", null, null, true, Property.EMPTY_ARRAY);
    }

    @Override
    public void append(LogEvent event) {
      events.add(event.toImmutable());
    }
  }

  /**
   * Make the MockMvc with the controller of the check and the handler of the error (the setup of the
   * standalone, and not a context of Spring Boot). The converter of the JSON is the one of the service (the
   * Jackson 3 of Spring Boot 4: the support of java.time is in the core, and write-dates-as-timestamps is off, so
   * the time of the check is the format date-time of the contract, and not a number).
   *
   * @param stateChecker the check of the state
   * @return the MockMvc
   */
  private static MockMvc setup(StateChecker stateChecker) {
    JacksonJsonHttpMessageConverter converter =
        new JacksonJsonHttpMessageConverter(
            JsonMapper.builder()
                .disable(DateTimeFeature.WRITE_DATES_AS_TIMESTAMPS)
                // The setting of src/main/resources/application.properties (spring.jackson.default-property-inclusion).
                .changeDefaultPropertyInclusion(value -> value.withValueInclusion(com.fasterxml.jackson.annotation.JsonInclude.Include.NON_NULL))
                .build());
    return MockMvcBuilders.standaloneSetup(new StatusController(stateChecker))
        .setControllerAdvice(new ProblemAdvice())
        .setMessageConverters(converter)
        .build();
  }

  /**
   * Make the check that gives the condition (up or degraded) and the time of the check.
   *
   * @param condition the condition
   * @return the check
   */
  private static StateChecker checkThatGives(StateEnum condition) {
    return () -> new Status().state(condition).checkedAt(OffsetDateTime.now(ZoneOffset.UTC));
  }

  /**
   * Make the check that throws the failure.
   *
   * @param failure the failure
   * @return the check
   */
  private static StateChecker checkThatThrows(RuntimeException failure) {
    return () -> {
      throw failure;
    };
  }

  /**
   * The span of the test (the trace identifier and the span identifier are fixed, so the assertion of the
   * response is deterministic).
   *
   * @return the span
   */
  private static Span theSpanOfTheTest() {
    SpanContext context =
        SpanContext.create(
            TRACE_ID_OF_THE_TEST, SPAN_ID_OF_THE_TEST, TraceFlags.getSampled(), io.opentelemetry.api.trace.TraceState.getDefault());
    return Span.wrap(context);
  }
}
