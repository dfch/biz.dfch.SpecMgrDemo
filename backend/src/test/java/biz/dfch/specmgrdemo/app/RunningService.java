package biz.dfch.specmgrdemo.app;

import org.springframework.boot.SpringApplication;
import org.springframework.context.ConfigurableApplicationContext;

/**
 * The service that runs for an integration test (feat-9-walking-skeleton, Phase 200, Task 200.110; the rework of
 * the Spring Boot 4 line). The class starts the app of the walking skeleton on a random port (the embedded Tomcat,
 * the property server.port with the value 0), and the test reads the port that the server took.
 *
 * <p>The class is the start of the service that the annotation @SpringBootTest does in the Spring Boot 3 line. The
 * annotation is not used since the Spring Boot 4 line: the extension of JUnit of the Spring Framework 7
 * (SpringExtension) calls the method computeIfAbsent of the store of JUnit Jupiter 6, and the module has JUnit
 * Jupiter 5.14.4 (the version that jqwik 1.10.2 needs, the pin JUNIT_VERSION of tools/versions.env). The start with
 * SpringApplication has no extension of JUnit, and it runs the same app with the same configuration of the
 * service (the arguments of the command line have the highest priority, as the property of the annotation).
 */
final class RunningService implements AutoCloseable {

  /** The four variables OTEL_* with the empty value (the service runs with no endpoint of the exporter). */
  private static final String[] NO_EXPORTER = {
    "--OTEL_EXPORTER_OTLP_ENDPOINT=",
    "--OTEL_EXPORTER_OTLP_TRACES_ENDPOINT=",
    "--OTEL_EXPORTER_OTLP_HEADERS=",
    "--OTEL_EXPORTER_OTLP_TRACES_HEADERS="
  };

  private final ConfigurableApplicationContext context;

  private RunningService(ConfigurableApplicationContext context) {
    this.context = context;
  }

  /**
   * Start the service on a random port with the four variables OTEL_* at the empty value.
   *
   * @param properties the properties of the service in the form of the command line, for example
   *     --app.state-checker=fail
   * @return the service that runs
   */
  static RunningService start(String... properties) {
    String[] arguments = new String[NO_EXPORTER.length + properties.length + 1];
    arguments[0] = "--server.port=0";
    System.arraycopy(NO_EXPORTER, 0, arguments, 1, NO_EXPORTER.length);
    System.arraycopy(properties, 0, arguments, 1 + NO_EXPORTER.length, properties.length);
    return new RunningService(SpringApplication.run(SpecMgrDemoApplication.class, arguments));
  }

  /**
   * The port of the embedded server.
   *
   * @return the port
   */
  int port() {
    String result = context.getEnvironment().getProperty("local.server.port");
    if (result == null) {
      throw new IllegalStateException("The service has no property local.server.port (the server did not start)");
    }
    return Integer.parseInt(result);
  }

  /**
   * The bean of the service.
   *
   * @param type the class of the bean
   * @param <T> the type of the bean
   * @return the bean
   */
  <T> T bean(Class<T> type) {
    return context.getBean(type);
  }

  @Override
  public void close() {
    context.close();
  }
}
