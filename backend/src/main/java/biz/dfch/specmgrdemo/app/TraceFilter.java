package biz.dfch.specmgrdemo.app;

import io.opentelemetry.api.common.AttributeKey;
import io.opentelemetry.api.trace.Span;
import io.opentelemetry.api.trace.SpanKind;
import io.opentelemetry.api.trace.StatusCode;
import io.opentelemetry.api.trace.Tracer;
import jakarta.servlet.Filter;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.ServletRequest;
import jakarta.servlet.ServletResponse;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.util.Set;
import org.springframework.stereotype.Component;
import org.springframework.web.servlet.HandlerMapping;

/**
 * The filter that gives the one server span per request (feat-9-walking-skeleton, Phase 200, Task 200.110; DEC
 * e3eadec0-a6ea-4efe-8e6d-fd19287122fa). The filter is the manual instrumentation of the specification (and not
 * a javaagent): for each request of the HTTP, it makes the span of the kind SERVER, it puts the span in the
 * context that is current (so the handler of the error of the request, the ProblemAdvice, finds the trace
 * identifier of the request in the member traceId of the response), and it ends the span after the response.
 *
 * <p>The name of the span has a bounded set of values (the semantic conventions of OpenTelemetry for the HTTP
 * server): the method and the route that the handler matched (the pattern of the mapping, for example
 * GET /status, and not the URI of the request: a client could send any number of other paths), and only the
 * method if no route matched. A method that is not one of the known methods of the HTTP is _OTHER. The span
 * has the attributes http.request.method, http.route (if a route matched) and http.response.status_code. The
 * status of the span is ERROR if the status of the response is 5xx, and for a failure that the chain throws
 * (the span records the exception, the status code is 500, and the filter throws the failure again).
 *
 * <p>The bean is registered by the service for each URL (the auto-configuration of Spring Boot for a bean
 * Filter), and the filter runs before the handler of the operation, in each case (the response 200 and the
 * response of the error).
 */
@Component
public class TraceFilter implements Filter {

  /** The methods of the HTTP that the span names as they are (RFC 9110 and PATCH of RFC 5789). */
  private static final Set<String> KNOWN_METHODS =
      Set.of("GET", "HEAD", "POST", "PUT", "DELETE", "CONNECT", "OPTIONS", "TRACE", "PATCH");

  private static final AttributeKey<String> HTTP_REQUEST_METHOD = AttributeKey.stringKey("http.request.method");

  private static final AttributeKey<String> HTTP_ROUTE = AttributeKey.stringKey("http.route");

  private static final AttributeKey<Long> HTTP_RESPONSE_STATUS_CODE = AttributeKey.longKey("http.response.status_code");

  /** The value of the method that is no known method (the semantic conventions). */
  static final String OTHER_METHOD = "_OTHER";

  private final Tracer tracer;

  /**
   * Make the filter with the tracer of the service (the bean of the OpenTelemetryConfiguration).
   *
   * @param tracer the tracer
   */
  public TraceFilter(Tracer tracer) {
    this.tracer = tracer;
  }

  @Override
  public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
      throws IOException, ServletException {
    if (!(request instanceof HttpServletRequest httpRequest) || !(response instanceof HttpServletResponse httpResponse)) {
      chain.doFilter(request, response);
      return;
    }
    String method = methodOf(httpRequest);
    Span span =
        tracer
            .spanBuilder(method)
            .setSpanKind(SpanKind.SERVER)
            .setAttribute(HTTP_REQUEST_METHOD, method)
            .startSpan();
    long status = HttpServletResponse.SC_INTERNAL_SERVER_ERROR;
    try (io.opentelemetry.context.Scope ignored = span.makeCurrent()) {
      try {
        chain.doFilter(request, response);
        status = httpResponse.getStatus();
      } catch (IOException | ServletException | RuntimeException | Error e) {
        // The container answers a failure that nobody handled with the status 500.
        span.recordException(e);
        throw e;
      }
    } finally {
      String route = routeOf(httpRequest);
      span.updateName(route == null ? method : method + " " + route);
      if (route != null) {
        span.setAttribute(HTTP_ROUTE, route);
      }
      span.setAttribute(HTTP_RESPONSE_STATUS_CODE, status);
      if (status >= 500) {
        span.setStatus(StatusCode.ERROR);
      }
      span.end();
    }
  }

  /**
   * The method of the request for the span: the method itself, or _OTHER for a method that is not known.
   *
   * @param request the request
   * @return the method
   */
  static String methodOf(HttpServletRequest request) {
    String method = request.getMethod();
    return method != null && KNOWN_METHODS.contains(method) ? method : OTHER_METHOD;
  }

  /**
   * The route that the handler matched (the pattern of the mapping), or null if no handler matched. The request
   * attribute is set by the mapping of Spring Web MVC, so it is known after the chain.
   *
   * @param request the request
   * @return the route, or null
   */
  static String routeOf(HttpServletRequest request) {
    Object route = request.getAttribute(HandlerMapping.BEST_MATCHING_PATTERN_ATTRIBUTE);
    return route instanceof String text && !text.isBlank() ? text : null;
  }
}
