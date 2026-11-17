package biz.dfch.specmgrdemo.app;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import biz.dfch.specmgrdemo.model.Status;
import biz.dfch.specmgrdemo.model.Status.StateEnum;
import io.opentelemetry.api.trace.Span;
import io.opentelemetry.api.trace.SpanContext;
import io.opentelemetry.api.trace.TraceFlags;
import java.time.OffsetDateTime;
import java.time.ZoneOffset;
import org.junit.jupiter.api.Test;
import org.springframework.http.converter.json.JacksonJsonHttpMessageConverter;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
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
            JsonMapper.builder().disable(DateTimeFeature.WRITE_DATES_AS_TIMESTAMPS).build());
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
