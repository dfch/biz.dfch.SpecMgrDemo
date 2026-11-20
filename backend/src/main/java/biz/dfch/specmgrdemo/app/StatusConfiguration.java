package biz.dfch.specmgrdemo.app;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.env.Environment;

/**
 * The wiring of the check of the state (feat-9-walking-skeleton, Phase 200, Task 200.110). The bean of the
 * service is the check that the property app.state-checker names:
 *
 * <ul>
 *   <li>the value up (the default): the check UpStateChecker (the system is in operation);
 *   <li>the value fail: the check FailingStateChecker (the system cannot give its state, the error response of
 *       the operation GET /status);
 *   <li>each other value (also an empty value): the start of the service fails with a message that names the
 *       property and the two values (no silent other check).
 * </ul>
 *
 * <p>The property is the seam of the verification (the class Javadoc of StateChecker): the test of the phase
 * 400 of the plan starts the service with the value fail (the class RunningService of the tests, which runs
 * SpringApplication with the argument --app.state-checker=fail), and it sees the error response.
 */
@Configuration
public class StatusConfiguration {

  /** The name of the property that gives the check of the state (the value up or fail, the class Javadoc). */
  public static final String STATE_CHECKER_PROPERTY = "app.state-checker";

  /** The value of the property that gives the check UpStateChecker. */
  public static final String STATE_CHECKER_UP = "up";

  /** The value of the property that gives the check FailingStateChecker. */
  public static final String STATE_CHECKER_FAIL = "fail";

  /**
   * The bean of the check of the state.
   *
   * @param environment the environment of the service (the properties and the environment variables)
   * @return the check
   * @throws IllegalStateException if the property has a value that is not up and not fail
   */
  @Bean
  public StateChecker stateChecker(Environment environment) {
    String mode = environment.getProperty(STATE_CHECKER_PROPERTY, STATE_CHECKER_UP);
    return switch (mode) {
      case STATE_CHECKER_UP -> new UpStateChecker();
      case STATE_CHECKER_FAIL -> new FailingStateChecker();
      default ->
          throw new IllegalStateException(
              "The property "
                  + STATE_CHECKER_PROPERTY
                  + " has the value '"
                  + mode
                  + "'. The value is "
                  + STATE_CHECKER_UP
                  + " or "
                  + STATE_CHECKER_FAIL
                  + ".");
    };
  }
}
