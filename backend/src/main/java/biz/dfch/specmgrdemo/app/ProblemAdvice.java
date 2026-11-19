package biz.dfch.specmgrdemo.app;

import biz.dfch.specmgrdemo.model.ErrorCode;
import biz.dfch.specmgrdemo.model.Problem;
import io.opentelemetry.api.trace.Span;
import io.opentelemetry.api.trace.SpanContext;
import jakarta.servlet.http.HttpServletRequest;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.TypeMismatchException;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatusCode;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.web.ErrorResponse;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

/**
 * The handler of the error of the service (feat-9-walking-skeleton, Phase 200, Task 200.110): each error of the
 * service is the response of the error of the contract (the media type application/problem+json, the schema
 * Problem, the extension x-specmgr-req is no part of the response). The rule of the contract (DEC
 * 51b00b5f-d1d8-49d8-9f40-28537ff69698, REQ 1ca335d7-969a-443e-9392-165fdeea99a0, the linter
 * tools/lint/ruleset.yaml): the body has no text in a language. So the body has the machine values only: the
 * member code is the value of the list ErrorCode (the frontend shows the text for each code from its catalog),
 * the member status is the status of the response, the member type is the constant about:blank, the member
 * instance is the path of the request, and the member traceId is the trace identifier of OpenTelemetry of the
 * request (32 lower case hexadecimal characters, the W3C form, the pattern of the contract). The members title
 * and detail of the schema are optional, and the service sends none of them (they are English text, and the
 * detail of a failure is text of the server that a client must not get, CWE-209). The text of the failure is in
 * the log of the service, with the trace identifier.
 *
 * <p>The mapping (the list ErrorCode of the contract is the only list of codes, and the contract documents
 * the responses 404, 405 and 406 of the operations with the shared response ProblemResponse, so the code of
 * each of these statuses is its own value of the list):
 *
 * <ul>
 *   <li>the failure of the check of the state (StatusCheckException, the system cannot give its state): the code
 *       service_unavailable with the status 503;
 *   <li>an error that Spring Web MVC itself gives for the request (the interface ErrorResponse: no resource of
 *       the path 404, a method that the path does not support 405, a media type that cannot be given 406, a media
 *       type that is not supported 415, a missing or a wrong parameter 400, and so on): the status of the error
 *       itself, with the headers that it gives (for example Allow), and the code not_found for 404,
 *       method_not_allowed for 405, not_acceptable for 406, rate_limited for 429, service_unavailable for 503,
 *       internal_error for another status 5xx, and validation_failed for each other status 4xx;
 *   <li>a request that cannot be read or has a value of the wrong type (the failure of the conversion): the code
 *       validation_failed with the status 400;
 *   <li>each other failure: the code internal_error with the status 500, and a log entry of the failure.
 * </ul>
 */
@RestControllerAdvice
public class ProblemAdvice {

  private static final Logger LOG = LoggerFactory.getLogger(ProblemAdvice.class);

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
    String traceId = traceId();
    LOG.warn("The system cannot give its state (traceId={}, path={})", traceId, request.getRequestURI(), exception);
    return problem(HttpStatusCode.valueOf(503), ErrorCode.SERVICE_UNAVAILABLE, HttpHeaders.EMPTY, traceId, request);
  }

  /**
   * Each other error of the service: the error that Spring Web MVC gives itself (ErrorResponse) and the failure of
   * the conversion of the request are errors of the client (the class Javadoc), and each other failure is the
   * code internal_error with the status 500. One method for all of them: the handler of the class Exception would
   * be the handler of the errors of Spring Web MVC too (the depth of the class is lower than the depth of the
   * interface ErrorResponse), so the method decides by the type.
   *
   * @param exception the failure
   * @param request the request of the operation
   * @return the response of the error
   */
  @ExceptionHandler(Exception.class)
  public ResponseEntity<Problem> other(Exception exception, HttpServletRequest request) {
    String traceId = traceId();
    if (exception instanceof ErrorResponse errorResponse) {
      HttpStatusCode status = errorResponse.getStatusCode();
      if (status.is5xxServerError()) {
        LOG.error("The request failed (traceId={}, path={}, status={})", traceId, request.getRequestURI(), status.value(), exception);
      } else {
        LOG.debug("The request is an error of the client (traceId={}, path={}, status={})", traceId, request.getRequestURI(), status.value(), exception);
      }
      return problem(status, codeOf(status), errorResponse.getHeaders(), traceId, request);
    }
    if (exception instanceof TypeMismatchException || exception instanceof HttpMessageNotReadableException) {
      LOG.debug("The request cannot be read (traceId={}, path={})", traceId, request.getRequestURI(), exception);
      return problem(HttpStatusCode.valueOf(400), ErrorCode.VALIDATION_FAILED, HttpHeaders.EMPTY, traceId, request);
    }
    LOG.error("The request failed with an unexpected failure (traceId={}, path={})", traceId, request.getRequestURI(), exception);
    return problem(HttpStatusCode.valueOf(500), ErrorCode.INTERNAL_ERROR, HttpHeaders.EMPTY, traceId, request);
  }

  /**
   * The code of the list ErrorCode for the status of an error of Spring Web MVC (the class Javadoc).
   *
   * @param status the status
   * @return the code
   */
  static ErrorCode codeOf(HttpStatusCode status) {
    return switch (status.value()) {
      case 404 -> ErrorCode.NOT_FOUND;
      case 405 -> ErrorCode.METHOD_NOT_ALLOWED;
      case 406 -> ErrorCode.NOT_ACCEPTABLE;
      case 429 -> ErrorCode.RATE_LIMITED;
      case 503 -> ErrorCode.SERVICE_UNAVAILABLE;
      default -> status.is4xxClientError() ? ErrorCode.VALIDATION_FAILED : ErrorCode.INTERNAL_ERROR;
    };
  }

  /**
   * Make the response of the error (the machine values only, the class Javadoc).
   *
   * @param status the status of the response
   * @param code the value of the list ErrorCode
   * @param headers the headers of the error itself (for example Allow of the status 405)
   * @param traceId the trace identifier of the request
   * @param request the request of the operation
   * @return the response
   */
  private static ResponseEntity<Problem> problem(
      HttpStatusCode status, ErrorCode code, HttpHeaders headers, String traceId, HttpServletRequest request) {
    Problem result = new Problem(code, traceId);
    result.setType(PROBLEM_TYPE);
    result.setStatus(status.value());
    result.setInstance(request.getRequestURI());
    HttpHeaders responseHeaders = new HttpHeaders();
    responseHeaders.putAll(headers);
    return ResponseEntity.status(status).headers(responseHeaders).contentType(PROBLEM_JSON).body(result);
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
