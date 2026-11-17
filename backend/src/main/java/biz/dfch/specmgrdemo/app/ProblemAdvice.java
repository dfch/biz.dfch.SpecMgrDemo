package biz.dfch.specmgrdemo.app;

import static org.springframework.http.HttpStatus.INTERNAL_SERVER_ERROR;
import static org.springframework.http.HttpStatus.SERVICE_UNAVAILABLE;

import biz.dfch.specmgrdemo.model.ErrorCode;
import biz.dfch.specmgrdemo.model.Problem;
import io.opentelemetry.api.trace.Span;
import io.opentelemetry.api.trace.SpanContext;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

/**
 * The handler of the error of the service (feat-9-walking-skeleton, Phase 200, Task 200.110): each error of the
 * operation is the response of the error of the contract (the media type application/problem+json, the schema
 * Problem, the extension x-specmgr-req is no part of the response). The rule of the contract (DEC
 * 51b00b5f-d1d8-49d8-9f40-28537ff69698, the linter tools/lint/ruleset.yaml): the body has no text in a
 * language that the client shows. The member code is the value of the list ErrorCode (the frontend shows the
 * text for each code from its catalog), and the member traceId is the trace identifier of OpenTelemetry of the
 * request (32 lower case hexadecimal characters, the W3C form, the pattern of the contract). The members title
 * and detail are English, for the log and the developer (the comment of the schema Problem of the contract),
 * and the client must not show them.
 *
 * <p>The mapping: the failure of the check of the state (StatusCheckException, the system cannot give its
 * state) is the code service_unavailable with the status 503, and each other failure of the operation is the
 * code internal_error with the status 500.
 */
@RestControllerAdvice
public class ProblemAdvice {

  /** The media type of the response of the error (the contract: each response 4xx and 5xx has it). */
  public static final MediaType PROBLEM_JSON = MediaType.parseMediaType("application/problem+json");

  /** The member type of RFC 9457 (a URI that names the type of the error). The service gives no catalog of URI. */
  public static final String PROBLEM_TYPE = "about:blank";

  /** The trace identifier that the response has if the request has no valid trace of OpenTelemetry (the pattern of the contract holds). */
  public static final String INVALID_TRACE_ID = "00000000000000000000000000000000";

  /**
   * The error of the check of the state: the system cannot give its state (REQ
   * 1ca335d7-969a-443e-9392-165fdeea99a0).
   *
   * @param exception the failure of the check
   * @param request the request of the operation
   * @return the response of the error (503, service_unavailable)
   */
  @ExceptionHandler(StatusCheckException.class)
  public ResponseEntity<Problem> statusCheck(StatusCheckException exception, HttpServletRequest request) {
    return problem(
        SERVICE_UNAVAILABLE,
        ErrorCode.SERVICE_UNAVAILABLE,
        "The system cannot give its state: " + exception.getMessage(),
        request);
  }

  /**
   * Each other error of the operation (the code internal_error, the status 500).
   *
   * @param exception the failure
   * @param request the request of the operation
   * @return the response of the error (500, internal_error)
   */
  @ExceptionHandler(Exception.class)
  public ResponseEntity<Problem> unexpected(Exception exception, HttpServletRequest request) {
    return problem(
        INTERNAL_SERVER_ERROR,
        ErrorCode.INTERNAL_ERROR,
        "An unexpected failure: " + exception,
        request);
  }

  /**
   * Make the response of the error.
   *
   * @param status the status of the response
   * @param code the value of the list ErrorCode
   * @param detail the note for the log and the developer (English, the client does not show it)
   * @param request the request of the operation
   * @return the response
   */
  private static ResponseEntity<Problem> problem(
      HttpStatus status, ErrorCode code, String detail, HttpServletRequest request) {
    Problem result = new Problem(code, traceId());
    result.setType(PROBLEM_TYPE);
    result.setTitle(status.getReasonPhrase());
    result.setStatus(status.value());
    result.setDetail(detail);
    result.setInstance(request.getRequestURI());
    return ResponseEntity.status(status).contentType(PROBLEM_JSON).body(result);
  }

  /**
   * The trace identifier of the request: the trace of the span that is current (the filter TraceFilter makes
   * the one server span per request, and the handler runs in it), in the W3C form (32 lower case hexadecimal
   * characters). A request that has no valid span gives the constant INVALID_TRACE_ID (the pattern of the
   * contract holds, and the value names the absence of the trace in the log).
   *
   * @return the trace identifier
   */
  static String traceId() {
    SpanContext context = Span.current().getSpanContext();
    if (context.isValid()) {
      return context.getTraceId();
    }
    return INVALID_TRACE_ID;
  }
}
