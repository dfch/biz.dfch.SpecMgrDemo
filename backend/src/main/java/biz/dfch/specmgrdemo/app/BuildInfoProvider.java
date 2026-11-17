package biz.dfch.specmgrdemo.app;

import java.io.IOException;
import java.io.InputStream;
import java.util.Properties;
import org.springframework.stereotype.Component;

/**
 * The reader of the value of the build (feat-9-walking-skeleton, Phase 200, Task 200.120). The reader loads the
 * resource of the name from the classpath (the default name is build-info.properties, the file that the execution
 * default-resources of maven-resources-plugin filters from the template of src/main/resources with the two
 * properties of the pom), and it makes the value of the build from the two keys version and commit.
 *
 * <p>The name of the resource is the seam of the unit test (ACC-003 of the plan): the test passes the name of a
 * resource of the test classpath (the files build-info-test.properties and
 * build-info-test-changed.properties of src/test/resources), so the test changes the value of the build (the
 * version, the commit) and sees the change of the response of the operation GET /info.
 *
 * <p>A resource that the classpath has not, or a key that is missing, stops the start of the service (the
 * fail-fast): the operation GET /info gives no value in this case.
 */
@Component
public class BuildInfoProvider {

  /** The default name of the resource of the classpath (the filtered file of the build). */
  public static final String DEFAULT_RESOURCE = "build-info.properties";

  private final BuildInfo buildInfo;

  /**
   * Make the reader with the default resource (build-info.properties of the classpath).
   */
  public BuildInfoProvider() {
    this(DEFAULT_RESOURCE);
  }

  /**
   * Make the reader with the resource of the name (the seam of the unit test, the class Javadoc).
   *
   * @param resource the name of the resource of the classpath
   */
  public BuildInfoProvider(String resource) {
    this.buildInfo = read(resource);
  }

  /**
   * The value of the build.
   *
   * @return the value
   */
  public BuildInfo buildInfo() {
    return buildInfo;
  }

  /**
   * Load the resource of the name from the classpath, and make the value of the build.
   *
   * @param resource the name of the resource
   * @return the value
   */
  private static BuildInfo read(String resource) {
    ClassLoader loader = BuildInfoProvider.class.getClassLoader();
    try (InputStream in = loader.getResourceAsStream(resource)) {
      if (in == null) {
        throw new IllegalStateException("the classpath has no resource " + resource);
      }
      Properties properties = new Properties();
      properties.load(in);
      String version = properties.getProperty("version");
      String commit = properties.getProperty("commit");
      if (version == null || version.isBlank() || commit == null || commit.isBlank()) {
        throw new IllegalStateException("the resource " + resource + " has no key version or no key commit");
      }
      return new BuildInfo(version, commit);
    } catch (IOException e) {
      throw new IllegalStateException("the resource " + resource + " cannot be read", e);
    }
  }
}
