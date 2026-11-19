package biz.dfch.specmgrdemo.app;

import biz.dfch.specmgrdemo.model.Status;
import biz.dfch.specmgrdemo.model.Status.StateEnum;
import java.time.OffsetDateTime;
import java.time.ZoneOffset;

/**
 * The check of the state that gives the condition up (feat-9-walking-skeleton, Phase 200, Task 200.110): the
 * system is in operation, and the check of the state is the time now (the zone UTC, the format date-time of the
 * contract). This is the check of the service of the walking skeleton (the bean of the default of the property
 * app.state-checker, the configuration StatusConfiguration).
 */
public class UpStateChecker implements StateChecker {

  @Override
  public Status check() {
    Status result = new Status();
    result.setState(StateEnum.UP);
    result.setCheckedAt(OffsetDateTime.now(ZoneOffset.UTC));
    return result;
  }
}
