package biz.dfch.specmgrdemo.app;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertSame;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import io.opentelemetry.api.common.AttributeKey;
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
import org.springframework.web.servlet.HandlerMapping;

/**
 * The unit test of the filter that gives the one server span per request (feat-9-walking-skeleton, Phase 200,
 * Task 200.110; DEC e3eadec0-a6ea-4efe-8e6d-fd19287122fa). The filter runs on the provider of the test (the
 * in-memory exporter of opentelemetry-sdk-testing, the processor simple), and the test sees the span that the
 * filter made: the kind SERVER, the name is the method and the route that the handler matched (a bounded name,
 * and never the URI of the request), the attributes of the method, the route and the status code, and the status
 * is ERROR if the status of the response is 5xx or if the chain throws a failure (the span records it).
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
    filter.doFilter(request, response, chainThatMatches("/status"));

    assertEquals(1, exporter.getFinishedSpanItems().size(), "the filter makes the one span of the request");
    SpanData span = exporter.getFinishedSpanItems().get(0);
    assertEquals(SpanKind.SERVER, span.getKind());
    assertEquals("GET /status", span.getName());
    assertEquals("/status", span.getAttributes().get(AttributeKey.stringKey("http.route")));
    assertEquals("GET", span.getAttributes().get(AttributeKey.stringKey("http.request.method")));
    assertEquals(200L, span.getAttributes().get(AttributeKey.longKey("http.response.status_code")));
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
            servletRequest.setAttribute(HandlerMapping.BEST_MATCHING_PATTERN_ATTRIBUTE, "/info");
            ((HttpServletResponse) servletResponse).setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
          }
        };
    filter.doFilter(request, response, chain);

    assertEquals(1, exporter.getFinishedSpanItems().size());
    SpanData span = exporter.getFinishedSpanItems().get(0);
    assertEquals(StatusCode.ERROR, span.getStatus().getStatusCode());
    assertEquals("GET /info", span.getName());
    assertEquals(500L, span.getAttributes().get(AttributeKey.longKey("http.response.status_code")));
  }

  @Test
  void theNameOfTheSpanIsBoundedForAPathThatNoRouteMatched() throws IOException, ServletException {
    InMemorySpanExporter exporter = InMemorySpanExporter.create();
    TraceFilter filter = filterOf(exporter);

    // Two paths that no handler matched: the name is the method only, and the span has no path of the client.
    for (String path : new String[] {"/nope", "/another/path/42"}) {
      MockHttpServletRequest request = new MockHttpServletRequest("GET", path);
      MockHttpServletResponse response = new MockHttpServletResponse();
      filter.doFilter(request, response, new MockFilterChain());
    }

    assertEquals(2, exporter.getFinishedSpanItems().size());
    for (SpanData span : exporter.getFinishedSpanItems()) {
      assertEquals("GET", span.getName(), "the name has no path of the client");
      assertNull(span.getAttributes().get(AttributeKey.stringKey("http.route")), "the span has no route");
      assertNull(span.getAttributes().get(AttributeKey.stringKey("url.path")), "the span has no path of the client");
    }
  }

  @Test
  void theNameOfTheSpanHasTheRouteOfTheMappingAndNotTheUriOfTheRequest() throws IOException, ServletException {
    InMemorySpanExporter exporter = InMemorySpanExporter.create();
    TraceFilter filter = filterOf(exporter);

    MockHttpServletRequest request = new MockHttpServletRequest("GET", "/item/12345");
    filter.doFilter(request, new MockHttpServletResponse(), chainThatMatches("/item/{id}"));

    SpanData span = exporter.getFinishedSpanItems().get(0);
    assertEquals("GET /item/{id}", span.getName());
  }

  @Test
  void aMethodThatIsNotKnownIsOther() throws IOException, ServletException {
    InMemorySpanExporter exporter = InMemorySpanExporter.create();
    TraceFilter filter = filterOf(exporter);

    filter.doFilter(new MockHttpServletRequest("FOOBAR", "/status"), new MockHttpServletResponse(), new MockFilterChain());

    SpanData span = exporter.getFinishedSpanItems().get(0);
    assertEquals("_OTHER", span.getName());
    assertEquals("_OTHER", span.getAttributes().get(AttributeKey.stringKey("http.request.method")));
  }

  @Test
  void theKnownMethodsAreNamedAsTheyAre() {
    for (String method : new String[] {"GET", "HEAD", "POST", "PUT", "DELETE", "CONNECT", "OPTIONS", "TRACE", "PATCH"}) {
      assertEquals(method, TraceFilter.methodOf(new MockHttpServletRequest(method, "/")));
    }
    assertEquals("_OTHER", TraceFilter.methodOf(new MockHttpServletRequest("get", "/")), "the method is case sensitive");
  }

  @Test
  void aFailureThatTheChainThrowsIsRecordedAndTheSpanEndsWithTheStatusError() {
    InMemorySpanExporter exporter = InMemorySpanExporter.create();
    TraceFilter filter = filterOf(exporter);
    IllegalStateException failure = new IllegalStateException("the chain failed");
    MockFilterChain chain =
        new MockFilterChain() {
          @Override
          public void doFilter(ServletRequest servletRequest, ServletResponse servletResponse) {
            servletRequest.setAttribute(HandlerMapping.BEST_MATCHING_PATTERN_ATTRIBUTE, "/status");
            throw failure;
          }
        };

    IllegalStateException thrown =
        assertThrows(
            IllegalStateException.class,
            () -> filter.doFilter(new MockHttpServletRequest("GET", "/status"), new MockHttpServletResponse(), chain));

    assertSame(failure, thrown, "the filter throws the failure again");
    assertEquals(1, exporter.getFinishedSpanItems().size(), "the span ends");
    SpanData span = exporter.getFinishedSpanItems().get(0);
    assertEquals(StatusCode.ERROR, span.getStatus().getStatusCode());
    assertEquals(500L, span.getAttributes().get(AttributeKey.longKey("http.response.status_code")));
    assertEquals("GET /status", span.getName());
    assertEquals(1, span.getEvents().size(), "the span records the exception");
    assertEquals("exception", span.getEvents().get(0).getName());
    assertEquals(
        "java.lang.IllegalStateException",
        span.getEvents().get(0).getAttributes().get(AttributeKey.stringKey("exception.type")));
  }

  @Test
  void aServletExceptionOfTheChainIsRecordedToo() {
    InMemorySpanExporter exporter = InMemorySpanExporter.create();
    TraceFilter filter = filterOf(exporter);
    MockFilterChain chain =
        new MockFilterChain() {
          @Override
          public void doFilter(ServletRequest servletRequest, ServletResponse servletResponse) throws ServletException {
            throw new ServletException("the servlet failed");
          }
        };

    assertThrows(
        ServletException.class,
        () -> filter.doFilter(new MockHttpServletRequest("GET", "/status"), new MockHttpServletResponse(), chain));

    SpanData span = exporter.getFinishedSpanItems().get(0);
    assertEquals(StatusCode.ERROR, span.getStatus().getStatusCode());
    assertEquals(1, span.getEvents().size());
  }

  @Test
  void aResponseOfAClientErrorLeavesTheStatusOfTheSpanUnsetAndHasTheStatusCode() throws IOException, ServletException {
    InMemorySpanExporter exporter = InMemorySpanExporter.create();
    TraceFilter filter = filterOf(exporter);
    MockFilterChain chain =
        new MockFilterChain() {
          @Override
          public void doFilter(ServletRequest servletRequest, ServletResponse servletResponse) {
            ((HttpServletResponse) servletResponse).setStatus(HttpServletResponse.SC_NOT_FOUND);
          }
        };

    filter.doFilter(new MockHttpServletRequest("GET", "/nope"), new MockHttpServletResponse(), chain);

    SpanData span = exporter.getFinishedSpanItems().get(0);
    assertEquals(StatusCode.UNSET, span.getStatus().getStatusCode());
    assertEquals(404L, span.getAttributes().get(AttributeKey.longKey("http.response.status_code")));
  }

  @Test
  void theResponseWithTheStatus499IsNoServerError() throws IOException, ServletException {
    InMemorySpanExporter exporter = InMemorySpanExporter.create();
    TraceFilter filter = filterOf(exporter);
    MockFilterChain chain =
        new MockFilterChain() {
          @Override
          public void doFilter(ServletRequest servletRequest, ServletResponse servletResponse) {
            ((HttpServletResponse) servletResponse).setStatus(499);
          }
        };
    filter.doFilter(new MockHttpServletRequest("GET", "/x"), new MockHttpServletResponse(), chain);
    assertEquals(StatusCode.UNSET, exporter.getFinishedSpanItems().get(0).getStatus().getStatusCode());

    // The status 500 is the first status of an error of the server (the boundary of the check).
    InMemorySpanExporter exporter500 = InMemorySpanExporter.create();
    MockFilterChain chain500 =
        new MockFilterChain() {
          @Override
          public void doFilter(ServletRequest servletRequest, ServletResponse servletResponse) {
            ((HttpServletResponse) servletResponse).setStatus(500);
          }
        };
    filterOf(exporter500).doFilter(new MockHttpServletRequest("GET", "/x"), new MockHttpServletResponse(), chain500);
    assertEquals(StatusCode.ERROR, exporter500.getFinishedSpanItems().get(0).getStatus().getStatusCode());
  }

  /**
   * Make the filter on the provider of the test (the in-memory exporter, the processor simple).
   *
   * @param exporter the exporter
   * @return the filter
   */
  private static TraceFilter filterOf(InMemorySpanExporter exporter) {
    SdkTracerProvider provider =
        SdkTracerProvider.builder().addSpanProcessor(SimpleSpanProcessor.create(exporter)).build();
    return new TraceFilter(provider.get(TraceFilterTest.class.getName()));
  }

  /**
   * Make the chain that sets the route that the handler matched (the attribute of Spring Web MVC).
   *
   * @param route the route
   * @return the chain
   */
  private static MockFilterChain chainThatMatches(String route) {
    return new MockFilterChain() {
      @Override
      public void doFilter(ServletRequest servletRequest, ServletResponse servletResponse) {
        servletRequest.setAttribute(HandlerMapping.BEST_MATCHING_PATTERN_ATTRIBUTE, route);
      }
    };
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
