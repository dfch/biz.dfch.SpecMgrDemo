package biz.dfch.specmgrdemo.app;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.io.InputStream;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;
import java.time.OffsetDateTime;
import org.junit.jupiter.api.AfterAll;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import tools.jackson.databind.JsonNode;
import tools.jackson.databind.json.JsonMapper;

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
 *
 * <p>The two tests of the phase 400 (the tasks 400.100 and 400.110) have the identifier of their verification
 * case record in the display name, as the convention of DEC f21920d2-4da5-4cf7-bd94-2e9bcba77342 says (the text
 * vcr:&lt;uuid&gt; and the name that the record states): the verification case record
 * 4f98618c-4291-4d60-995f-1fd8a60b9bfd (the operation GET /status, the criterion AC-001) and the verification
 * case record eb8a7f16-880d-42b7-9852-37c96175d344 (the operation GET /info, the criterion AC-001; the criterion
 * AC-002 is the end-to-end test of the frontend). The error response of the operation GET /status is the test of
 * the class StatusErrorIT (the criterion AC-002 of the first record).
 */
class ServiceIT {

  private static final JsonMapper JSON = JsonMapper.builder().build();

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
  @DisplayName("vcr:4f98618c-4291-4d60-995f-1fd8a60b9bfd the operation gives the state of the system")
  void theOperationGivesTheStateOfTheSystem() throws Exception {
    // The steps of the criterion AC-001 of the verification case record: the backend of the build runs (the
    // class), the client sends the request GET /status, the response has the status code 200 and the media type
    // application/json, and the body has the state up and the time of the check (the format date-time).
    HttpResponse<String> response = get("/status");
    assertEquals(200, response.statusCode(), "the response 200 of the operation GET /status");
    assertTrue(
        response.headers().firstValue("Content-Type").orElse("").startsWith("application/json"),
        "the media type application/json");
    JsonNode body = JSON.readTree(response.body());
    assertEquals("up", body.path("state").asString(), "the state is the condition up: " + response.body());
    String checkedAt = body.path("checkedAt").asString();
    assertFalse(checkedAt.isEmpty(), "the response has the time of the check: " + response.body());
    // The format date-time of the contract is the date and the time of RFC 3339 (the parse stops for another form).
    OffsetDateTime.parse(checkedAt);
  }

  @Test
  @DisplayName("vcr:eb8a7f16-880d-42b7-9852-37c96175d344 the operation gives the identification and the license")
  void theOperationGivesTheIdentificationAndTheLicense() throws Exception {
    // The steps of the criterion AC-001 of the verification case record: the backend of the build runs (the
    // build has the version and the commit), the client sends the request GET /info, the response has the
    // status code 200 and the media type application/json, and the body has the version, the commit, the
    // copyright holder, the address of the repository and the license AGPL-3.0-only.
    HttpResponse<String> response = get("/info");
    assertEquals(200, response.statusCode(), "the response 200 of the operation GET /info");
    assertTrue(
        response.headers().firstValue("Content-Type").orElse("").startsWith("application/json"),
        "the media type application/json");
    BuildInfo buildInfo = buildInfoProvider.buildInfo();
    assertFalse(buildInfo.version().isBlank(), "the build has a version");
    assertFalse(buildInfo.commit().isBlank(), "the build has a commit");
    JsonNode body = JSON.readTree(response.body());
    assertEquals(buildInfo.version(), body.path("version").asString(), "the version is the value of the build: " + response.body());
    assertEquals(buildInfo.commit(), body.path("commit").asString(), "the commit is the value of the build: " + response.body());
    assertEquals("Copyright 2026 Ronald Rink", body.path("copyright").asString(), "the copyright holder: " + response.body());
    assertEquals(
        "https://github.com/dfch/biz.dfch.SpecMgrDemo",
        body.path("repository").asString(),
        "the address of the repository: " + response.body());
    assertEquals("AGPL-3.0-only", body.path("license").asString(), "the license: " + response.body());
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
