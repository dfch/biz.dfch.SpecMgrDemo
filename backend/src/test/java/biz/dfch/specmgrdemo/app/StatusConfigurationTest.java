package biz.dfch.specmgrdemo.app;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertInstanceOf;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import org.junit.jupiter.api.Test;
import org.springframework.mock.env.MockEnvironment;

/**
 * The unit test of the wiring of the check of the state (feat-9-walking-skeleton, Phase 200, Task 200.110). The
 * bean is the check that the property app.state-checker names: up (the default) or fail. Each other value stops the
 * start of the service with a message (no silent other check).
 */
class StatusConfigurationTest {

  private final StatusConfiguration configuration = new StatusConfiguration();

  @Test
  void theDefaultIsTheCheckThatGivesTheStateUp() {
    assertInstanceOf(UpStateChecker.class, configuration.stateChecker(new MockEnvironment()));
  }

  @Test
  void theValueUpIsTheCheckThatGivesTheStateUp() {
    MockEnvironment environment = new MockEnvironment().withProperty(StatusConfiguration.STATE_CHECKER_PROPERTY, "up");
    assertInstanceOf(UpStateChecker.class, configuration.stateChecker(environment));
  }

  @Test
  void theValueFailIsTheCheckThatFails() {
    MockEnvironment environment = new MockEnvironment().withProperty(StatusConfiguration.STATE_CHECKER_PROPERTY, "fail");
    assertInstanceOf(FailingStateChecker.class, configuration.stateChecker(environment));
  }

  @Test
  void anUnknownValueStopsTheStartWithAMessage() {
    MockEnvironment environment = new MockEnvironment().withProperty(StatusConfiguration.STATE_CHECKER_PROPERTY, "fial");
    IllegalStateException result = assertThrows(IllegalStateException.class, () -> configuration.stateChecker(environment));
    assertTrue(result.getMessage().contains("app.state-checker"), "the message names the property: " + result.getMessage());
    assertTrue(result.getMessage().contains("fial"), "the message names the value: " + result.getMessage());
    assertTrue(result.getMessage().contains("up") && result.getMessage().contains("fail"), "the message names the two values");
  }

  @Test
  void anEmptyValueStopsTheStartToo() {
    MockEnvironment environment = new MockEnvironment().withProperty(StatusConfiguration.STATE_CHECKER_PROPERTY, "");
    assertThrows(IllegalStateException.class, () -> configuration.stateChecker(environment));
  }

  @Test
  void theValueIsCaseSensitive() {
    MockEnvironment environment = new MockEnvironment().withProperty(StatusConfiguration.STATE_CHECKER_PROPERTY, "UP");
    IllegalStateException result = assertThrows(IllegalStateException.class, () -> configuration.stateChecker(environment));
    assertFalse(result.getMessage().isBlank());
  }
}
