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
 * <p>The service gives no made-up value (the notice of the license names the exact source of the build, AGPL-3.0
 * section 13). A resource that the classpath has not, a key that is missing, a value that the build did not set
 * (the text unknown, the default of the pom, or a placeholder of the form ${...} that the filter did not replace)
 * stops the start of the service (the fail-fast): the operation GET /info gives no value in this case. Each just
 * recipe that starts Maven gives the commit (the property build.info.commit, the function backend_maven_args of
 * tools/gates/_lib.sh); a build without the property (for example a run in an IDE) gives the failure with the
 * message that names the property. The constructor with the second parameter is the seam of a test that needs the
 * reader with a value that is not set: it allows such a value (the class Javadoc of the test says why).
 */
@Component
public class BuildInfoProvider {

  /** The default name of the resource of the classpath (the filtered file of the build). */
  public static final String DEFAULT_RESOURCE = "build-info.properties";

  /** The default of the commit in the pom: the value that the build did not set. */
  static final String UNSET_VALUE = "unknown";

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
    this(resource, false);
  }

  /**
   * Make the reader with the resource of the name, and with the choice for a value that the build did not set
   * (the seam of the unit test, the class Javadoc). The service uses the constructors above, which allow no such
   * value.
   *
   * @param resource the name of the resource of the classpath
   * @param allowUnset true allows the value unknown and a placeholder that is not replaced (only a test of the
   *     reader itself does this)
   */
  BuildInfoProvider(String resource, boolean allowUnset) {
    this.buildInfo = read(resource, allowUnset);
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
   * @param allowUnset true allows a value that the build did not set (the class Javadoc)
   * @return the value
   */
  private static BuildInfo read(String resource, boolean allowUnset) {
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
      if (!allowUnset) {
        requireSet(resource, "version", version);
        requireSet(resource, "commit", commit);
      }
      return new BuildInfo(version, commit);
    } catch (IOException e) {
      throw new IllegalStateException("the resource " + resource + " cannot be read", e);
    }
  }

  /**
   * Stop for a value that the build did not set: the text unknown (the default of the pom) or a placeholder of
   * the form ${...} (the filter did not replace it).
   *
   * @param resource the name of the resource
   * @param key the key of the value
   * @param value the value
   */
  private static void requireSet(String resource, String key, String value) {
    String text = value.trim();
    if (text.equalsIgnoreCase(UNSET_VALUE) || text.contains("${")) {
      throw new IllegalStateException(
          "the resource "
              + resource
              + " has no value of the build for the key "
              + key
              + " (the value is '"
              + text
              + "'). The build must give the property build.info."
              + key
              + ": start Maven with the recipe of the justfile, or with -Dbuild.info.commit=$(git rev-parse HEAD)");
    }
  }
}
