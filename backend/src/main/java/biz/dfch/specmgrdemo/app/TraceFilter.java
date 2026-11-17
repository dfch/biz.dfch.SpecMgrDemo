package biz.dfch.specmgrdemo.app;

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
import org.springframework.stereotype.Component;

/**
 * The filter that gives the one server span per request (feat-9-walking-skeleton, Phase 200, Task 200.110; DEC
 * e3eadec0-a6ea-4efe-8e6d-fd19287122fa). The filter is the manual instrumentation of the specification (and not
 * a javaagent): for each request of the HTTP, it makes the span of the kind SERVER, the name is the method and
 * the URI of the request (the form GET /status), it puts the span in the context that is current (so the
 * handler of the error of the request, the ProblemAdvice, finds the trace identifier of the request in the
 * member traceId of the response), and it ends the span after the response (the status of the span is ERROR if
 * the status of the response is 5xx).
 *
 * <p>The bean is registered by the service for each URL (the auto-configuration of Spring Boot for a bean
 * Filter), and the filter runs before the handler of the operation, in each case (the response 200 and the
 * response of the error).
 */
@Component
public class TraceFilter implements Filter {

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
    Span span =
        tracer
            .spanBuilder(spanName(httpRequest))
            .setSpanKind(SpanKind.SERVER)
            .setAttribute("http.request.method", httpRequest.getMethod())
            .startSpan();
    try (io.opentelemetry.context.Scope ignored = span.makeCurrent()) {
      chain.doFilter(request, response);
      span.setAttribute("http.response.status_code", (long) httpResponse.getStatus());
      if (httpResponse.getStatus() >= 500) {
        span.setStatus(StatusCode.ERROR);
      }
    } finally {
      span.end();
    }
  }

  /**
   * The name of the span (the method and the URI of the request, the class Javadoc).
   *
   * @param request the request
   * @return the name
   */
  static String spanName(HttpServletRequest request) {
    return request.getMethod() + " " + request.getRequestURI();
  }
}
