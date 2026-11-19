package biz.dfch.specmgrdemo.app;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import org.junit.jupiter.api.Test;

/**
 * The unit test of the reader of the value of the build (feat-9-walking-skeleton, Phase 200, Task 200.120).
 * The reader loads the resource from the classpath, and the test classpath has the resource of the build that
 * the execution default-resources of maven-resources-plugin filters (target/classes/build-info.properties, the
 * value of the build) and the two resources of the test (src/test/resources, the seam of the constructor).
 */
class BuildInfoProviderTest {

  @Test
  void theReaderLoadsTheResourceOfTheBuildFromTheClasspath() {
    // The resource of the build: the filtered file of target/classes (the phase process-resources of the run).
    BuildInfo buildInfo = new BuildInfoProvider().buildInfo();
    assertFalse(buildInfo.version().isBlank(), "the version of the build is a value");
    assertFalse(buildInfo.commit().isBlank(), "the commit of the build is a value");
  }

  @Test
  void theReaderLoadsTheResourceOfTheNameFromTheTestClasspath() {
    BuildInfo buildInfo = new BuildInfoProvider("build-info-test.properties").buildInfo();
    assertEquals("9.9.9-test", buildInfo.version());
    assertEquals("0123456789abcdef0123456789abcdef01234567", buildInfo.commit());
  }

  @Test
  void theReaderStopsForAResourceThatTheClasspathHasNot() {
    IllegalStateException result =
        assertThrows(IllegalStateException.class, () -> new BuildInfoProvider("build-info-not-there.properties"));
    assertTrue(result.getMessage().contains("build-info-not-there.properties"));
  }

  @Test
  void theReaderStopsForTheCommitUnknownThatIsTheDefaultOfThePom() {
    IllegalStateException result =
        assertThrows(IllegalStateException.class, () -> new BuildInfoProvider("build-info-test-unknown.properties"));
    assertTrue(result.getMessage().contains("build.info.commit"), "the message names the property: " + result.getMessage());
    assertTrue(result.getMessage().contains("build-info-test-unknown.properties"), "the message names the resource");
  }

  @Test
  void theReaderStopsForAPlaceholderThatTheFilterDidNotReplace() {
    IllegalStateException result =
        assertThrows(IllegalStateException.class, () -> new BuildInfoProvider("build-info-test-unresolved.properties"));
    assertTrue(result.getMessage().contains("build.info.commit"), "the message names the property: " + result.getMessage());
  }

  @Test
  void theReaderStopsForAVersionThatTheFilterDidNotReplace() {
    IllegalStateException result =
        assertThrows(
            IllegalStateException.class, () -> new BuildInfoProvider("build-info-test-unresolved-version.properties"));
    assertTrue(result.getMessage().contains("build.info.version"), "the message names the property: " + result.getMessage());
  }

  @Test
  void theSeamOfTheConstructorAllowsAValueThatTheBuildDidNotSet() {
    BuildInfo unknown = new BuildInfoProvider("build-info-test-unknown.properties", true).buildInfo();
    assertEquals("unknown", unknown.commit());
    BuildInfo unresolved = new BuildInfoProvider("build-info-test-unresolved.properties", true).buildInfo();
    assertEquals("${build.info.commit}", unresolved.commit());
  }
}
