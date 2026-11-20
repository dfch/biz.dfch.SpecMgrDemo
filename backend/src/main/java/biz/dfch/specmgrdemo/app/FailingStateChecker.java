package biz.dfch.specmgrdemo.app;

import biz.dfch.specmgrdemo.model.Status;

/**
 * The check of the state that fails (feat-9-walking-skeleton, Phase 200, Task 200.110): the system cannot give
 * its state, so the check throws the failure StatusCheckException, and the operation GET /status sends the
 * error response (the code service_unavailable, the status 503). The bean of the property app.state-checker
 * with the value fail is this check (the configuration StatusConfiguration): the integration test of the phase
 * 400 of the plan starts the service with the property, and the unit test gives the check to the controller
 * directly.
 */
public class FailingStateChecker implements StateChecker {

  @Override
  public Status check() {
    throw new StatusCheckException("the check of the state failed");
  }
}
