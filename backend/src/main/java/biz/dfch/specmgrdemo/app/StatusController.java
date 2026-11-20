package biz.dfch.specmgrdemo.app;

import biz.dfch.specmgrdemo.api.StatusApi;
import biz.dfch.specmgrdemo.model.Status;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.RestController;

/**
 * The implementation of the operation GET /status (feat-9-walking-skeleton, Phase 200, Task 200.110; the
 * interface is the generated interface biz.dfch.specmgrdemo.api.StatusApi, REQ
 * 1ca335d7-969a-443e-9392-165fdeea99a0). The controller asks the check of the state (the bean StateChecker of
 * the configuration StatusConfiguration) and gives the state (the condition up or degraded, and the time of
 * the check) as the response 200. If the system cannot give its state, the check throws the failure
 * StatusCheckException, and the handler of the error (ProblemAdvice) sends the error response (the media type
 * application/problem+json, the code service_unavailable, the status 503, the trace identifier).
 */
@RestController
public class StatusController implements StatusApi {

  private final StateChecker stateChecker;

  /**
   * Make the controller with the check of the state.
   *
   * @param stateChecker the check
   */
  public StatusController(StateChecker stateChecker) {
    this.stateChecker = stateChecker;
  }

  @Override
  public ResponseEntity<Status> getStatus() {
    return ResponseEntity.ok(stateChecker.check());
  }
}
