package biz.dfch.specmgrdemo.app;

import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;
import org.junit.jupiter.api.Test;

/**
 * The backend that the end-to-end test starts (feat-9-walking-skeleton, Phase 400, Task 400.110). The class is
 * no test: it has no assertion. It is the start of the service for the browser tests of the frontend, and it uses
 * the class RunningService, as the integration tests do (the same app, the same configuration, a random port, the
 * four variables OTEL_* at the empty value, so the start is deterministic in the CI and the service gives no
 * collector, REQ-004).
 *
 * <p>The module has no executable jar and no plug-in that starts a class (a new plug-in needs a pin, the phase 400
 * of the plan adds no new tool). So the run of the test runner is the way to start the classes of the module
 * with the class path of the module: the script frontend/e2e/service.mjs starts
 * {@code ./mvnw test -Dtest=ServiceForE2e}. The name has no part that the default includes of surefire (Test*,
 * *Test, *Tests, *TestCase) or the pattern *IT of the integration run select, so no normal run of the tests starts
 * the class (as the classes that are not successful, see backend/README.md); only the option -Dtest selects it.
 *
 * <p>The method prints the line {@code E2E_BACKEND_URL=http://127.0.0.1:<port>} (the script waits for it), and it
 * waits. The script ends the run (the process group is stopped when the end-to-end run is over). The wait has an
 * end of its own (the constant {@link #LIFETIME_MINUTES}), so a run that nobody stops does not stay for ever.
 */
class ServiceForE2e {

  /** The longest time of the service: the end of the wait if nobody stops the process. */
  static final long LIFETIME_MINUTES = 15;

  @Test
  void runsTheServiceForTheEndToEndTest() throws InterruptedException {
    try (RunningService service = RunningService.start()) {
      System.out.println("E2E_BACKEND_URL=http://127.0.0.1:" + service.port());
      System.out.flush();
      new CountDownLatch(1).await(LIFETIME_MINUTES, TimeUnit.MINUTES);
    }
  }
}
