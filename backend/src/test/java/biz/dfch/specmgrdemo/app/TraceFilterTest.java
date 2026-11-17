package biz.dfch.specmgrdemo.app;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

import io.opentelemetry.api.trace.SpanKind;
import io.opentelemetry.api.trace.StatusCode;
import io.opentelemetry.sdk.testing.exporter.InMemorySpanExporter;
import io.opentelemetry.sdk.trace.SdkTracerProvider;
import io.opentelemetry.sdk.trace.data.SpanData;
import io.opentelemetry.sdk.trace.export.SimpleSpanProcessor;
import jakarta.servlet.ServletRequest;
import jakarta.servlet.ServletResponse;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.lang.reflect.Proxy;
import org.junit.jupiter.api.Test;
import org.springframework.mock.web.MockFilterChain;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;

/**
 * The unit test of the filter that gives the one server span per request (feat-9-walking-skeleton, Phase 200,
 * Task 200.110; DEC e3eadec0-a6ea-4efe-8e6d-fd19287122fa). The filter runs on the provider of the test (the
 * in-memory exporter of opentelemetry-sdk-testing, the processor simple), and the test sees the span that the
 * filter made: the kind SERVER, the name is the method and the URI of the request, and the status is ERROR if
 * the status of the response is 5xx.
 */
class TraceFilterTest {

  @Test
  void theFilterMakesOneServerSpanPerRequest() throws IOException, ServletException {
    InMemorySpanExporter exporter = InMemorySpanExporter.create();
    SdkTracerProvider provider =
        SdkTracerProvider.builder().addSpanProcessor(SimpleSpanProcessor.create(exporter)).build();
    TraceFilter filter = new TraceFilter(provider.get(TraceFilterTest.class.getName()));

    MockHttpServletRequest request = new MockHttpServletRequest("GET", "/status");
    MockHttpServletResponse response = new MockHttpServletResponse();
    filter.doFilter(request, response, new MockFilterChain());

    assertEquals(1, exporter.getFinishedSpanItems().size(), "the filter makes the one span of the request");
    SpanData span = exporter.getFinishedSpanItems().get(0);
    assertEquals(SpanKind.SERVER, span.getKind());
    assertEquals("GET /status", span.getName());
    assertEquals(StatusCode.UNSET, span.getStatus().getStatusCode());
    assertTrue(span.getSpanContext().isValid(), "the span has a real trace identifier");
  }

  @Test
  void theFilterSetsTheStatusErrorForA5xxResponse() throws IOException, ServletException {
    InMemorySpanExporter exporter = InMemorySpanExporter.create();
    SdkTracerProvider provider =
        SdkTracerProvider.builder().addSpanProcessor(SimpleSpanProcessor.create(exporter)).build();
    TraceFilter filter = new TraceFilter(provider.get(TraceFilterTest.class.getName()));

    MockHttpServletRequest request = new MockHttpServletRequest("GET", "/info");
    MockHttpServletResponse response = new MockHttpServletResponse();
    MockFilterChain chain =
        new MockFilterChain() {
          @Override
          public void doFilter(ServletRequest servletRequest, ServletResponse servletResponse) {
            ((HttpServletResponse) servletResponse).setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
          }
        };
    filter.doFilter(request, response, chain);

    assertEquals(1, exporter.getFinishedSpanItems().size());
    SpanData span = exporter.getFinishedSpanItems().get(0);
    assertEquals(StatusCode.ERROR, span.getStatus().getStatusCode());
    assertEquals("GET /info", span.getName());
  }

  @Test
  void theFilterPassesAResponseThatIsNotHttpWithoutASpan() throws IOException, ServletException {
    InMemorySpanExporter exporter = InMemorySpanExporter.create();
    SdkTracerProvider provider =
        SdkTracerProvider.builder().addSpanProcessor(SimpleSpanProcessor.create(exporter)).build();
    TraceFilter filter = new TraceFilter(provider.get(TraceFilterTest.class.getName()));

    // A request that is not an HttpServletRequest (the proxy answers no method; the filter passes it
    // to the chain without a span).
    ServletRequest request = proxyOf(ServletRequest.class);
    ServletResponse response = proxyOf(ServletResponse.class);
    final boolean[] called = {false};
    MockFilterChain chain =
        new MockFilterChain() {
          @Override
          public void doFilter(ServletRequest servletRequest, ServletResponse servletResponse) {
            called[0] = true;
          }
        };
    filter.doFilter(request, response, chain);

    assertTrue(called[0], "the chain runs");
    assertEquals(0, exporter.getFinishedSpanItems().size(), "no span for a request that is not HTTP");
  }

  /**
   * Make the proxy of the interface (the methods of the proxy answer the default of the type, and no method
   * of the proxy is called in the test).
   *
   * @param interfaceType the interface
   * @return the proxy
   */
  @SuppressWarnings("unchecked")
  private static <T> T proxyOf(Class<T> interfaceType) {
    return (T)
        Proxy.newProxyInstance(
            TraceFilterTest.class.getClassLoader(),
            new Class<?>[] {interfaceType},
            (proxy, method, args) -> {
              if (method.getReturnType() == boolean.class) {
                return false;
              }
              if (method.getReturnType() == int.class) {
                return 0;
              }
              return null;
            });
  }
}
