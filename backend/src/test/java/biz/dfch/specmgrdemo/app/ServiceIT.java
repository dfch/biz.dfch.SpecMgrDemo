package biz.dfch.specmgrdemo.app;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.io.InputStream;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;
import org.junit.jupiter.api.AfterAll;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;

/**
 * The integration test of the service that starts (feat-9-walking-skeleton, Phase 200, Task 200.110): the
 * app of the walking skeleton starts on a random port (the embedded Tomcat of spring-boot-starter-web, the
 * class RunningService), and the service gives the two operations of the contract. The test names the
 * OTEL_* variables with an empty value (the argument has priority over the environment variable, and the empty
 * value is the same as a missing value): the service runs with no endpoint of the exporter, and the test is deterministic in the CI
 * (the feature gives no collector, DEC e3eadec0-a6ea-4efe-8e6d-fd19287122fa). The test reads the value of the
 * build from the resource of the classpath (the filtered file of the build), and it asserts that the response
 * of the operation GET /info is the value of the build (the version and the commit come from the build, and
 * not from a fixed text, the task 200.120).
 */
class ServiceIT {

  private static RunningService service;

  private static int port;

  private static BuildInfoProvider buildInfoProvider;

  @BeforeAll
  static void startTheService() {
    service = RunningService.start();
    port = service.port();
    buildInfoProvider = service.bean(BuildInfoProvider.class);
  }

  @AfterAll
  static void stopTheService() {
    service.close();
  }

  @Test
  void theServiceGivesTheStateOfTheSystem() throws Exception {
    HttpResponse<String> response = get("/status");
    assertEquals(200, response.statusCode(), "the response 200 of the operation GET /status");
    assertTrue(response.headers().firstValue("Content-Type").orElse("").startsWith("application/json"));
    assertTrue(response.body().contains("\"state\":\"up\""), "the state is the condition up: " + response.body());
    assertTrue(response.body().contains("\"checkedAt\":\""), "the response has the time of the check: " + response.body());
  }

  @Test
  void theServiceGivesTheInformationOfTheSystem() throws Exception {
    HttpResponse<String> response = get("/info");
    assertEquals(200, response.statusCode(), "the response 200 of the operation GET /info");
    assertTrue(response.headers().firstValue("Content-Type").orElse("").startsWith("application/json"));
    BuildInfo buildInfo = buildInfoProvider.buildInfo();
    assertTrue(response.body().contains("\"version\":\"" + buildInfo.version() + "\""), "the version is the value of the build: " + response.body());
    assertTrue(response.body().contains("\"commit\":\"" + buildInfo.commit() + "\""), "the commit is the value of the build: " + response.body());
    assertTrue(response.body().contains("\"copyright\":\"Copyright 2026 Ronald Rink\""), "the copyright holder: " + response.body());
    assertTrue(response.body().contains("\"repository\":\"https://github.com/dfch/biz.dfch.SpecMgrDemo\""), "the address of the repository: " + response.body());
    assertTrue(response.body().contains("\"license\":\"AGPL-3.0-only\""), "the license: " + response.body());
  }

  @Test
  void theVersionOfTheBuildIsTheVersionOfTheContract() throws Exception {
    // The version of the build is the constant of the pom (0.1.0, the version of the contract, and not a
    // value of git, the task 200.120).
    assertEquals("0.1.0", buildInfoProvider.buildInfo().version());
  }


  @Test
  void theCommitOfTheBuildIsTheCommitOfTheWorkTree() throws Exception {
    // The recipe of the justfile passes the value of git rev-parse HEAD as the property build.info.commit
    // (the function backend_maven_args of tools/gates/_lib.sh), and the build filters the value into the
    // resource of the classpath. The test asserts that the value of the resource is the commit of the work
    // tree (the directory of the test run, the module backend).
    String head = gitHead();
    assertEquals(head, buildInfoProvider.buildInfo().commit());
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

  /**
   * The commit of the work tree (git rev-parse HEAD, the directory of the test run, the module backend).
   *
   * @return the commit
   * @throws Exception if the command fails
   */
  private static String gitHead() throws Exception {
    Process process = new ProcessBuilder("git", "rev-parse", "HEAD").redirectErrorStream(true).start();
    try (InputStream in = process.getInputStream()) {
      String result = new String(in.readAllBytes()).trim();
      int code = process.waitFor();
      if (code != 0) {
        throw new IllegalStateException("git rev-parse HEAD gives the exit code " + code + ": " + result);
      }
      return result;
    }
  }
}
