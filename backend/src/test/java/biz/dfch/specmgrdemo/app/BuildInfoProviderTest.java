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
}
