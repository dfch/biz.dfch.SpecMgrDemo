package biz.dfch.specmgrdemo.app;

import biz.dfch.specmgrdemo.model.Status;

/**
 * The check of the state of the system (feat-9-walking-skeleton, Phase 200, Task 200.110). The controller of
 * the operation GET /status asks the check for the state (the model class Status of the generated package, the
 * condition up or degraded and the time of the check).
 *
 * <p>The interface is the seam of the verification (the test of the phase 400 of the plan, "the test makes the
 * check of the state fail"): a test gives the controller a check that throws the exception
 * StatusCheckException, and it sees the error response of the operation (the media type
 * application/problem+json, the code service_unavailable, the trace identifier). The bean of the service is the
 * check of the property app.state-checker of the configuration StatusConfiguration (the value up, the default,
 * gives the check UpStateChecker, and the value fail gives the check FailingStateChecker).
 */
public interface StateChecker {

  /**
   * Check the state of the system.
   *
   * @return the state (the condition up or degraded, and the time of the check)
   * @throws StatusCheckException if the system cannot give its state
   */
  Status check();
}
