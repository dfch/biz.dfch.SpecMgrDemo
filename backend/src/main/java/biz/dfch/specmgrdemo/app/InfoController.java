package biz.dfch.specmgrdemo.app;

import biz.dfch.specmgrdemo.api.InfoApi;
import biz.dfch.specmgrdemo.model.Info;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.RestController;

/**
 * The implementation of the operation GET /info (feat-9-walking-skeleton, Phase 200, Task 200.110; the
 * interface is the generated interface biz.dfch.specmgrdemo.api.InfoApi, REQ 271168a4-2a6f-40a1-b277-
 * 89711b18a087). The response has the five values of the contract: the version and the commit come from the
 * build (the reader BuildInfoProvider, the task 200.120), and the copyright holder, the address of the
 * repository and the license are the constants of the project (DEC 5ddd8d7a-5e7d-4a9b-860f-7d0b1f05579c, the
 * notice confirmed by the owner on 2026-11-15).
 */
@RestController
public class InfoController implements InfoApi {

  /** The copyright holder of the system (the constant of the project, DEC 5ddd8d7a-5e7d-4a9b-860f-7d0b1f05579c). */
  public static final String COPYRIGHT = "Copyright 2026 Ronald Rink";

  /** The address of the repository of the system (the constant of the project, DEC 5ddd8d7a-5e7d-4a9b-860f-7d0b1f05579c). */
  public static final String REPOSITORY = "https://github.com/dfch/biz.dfch.SpecMgrDemo";

  /** The license of the system (the constant of the project, DEC 5ddd8d7a-5e7d-4a9b-860f-7d0b1f05579c). */
  public static final String LICENSE = "AGPL-3.0-only";

  private final BuildInfoProvider buildInfoProvider;

  /**
   * Make the controller with the reader of the value of the build.
   *
   * @param buildInfoProvider the reader
   */
  public InfoController(BuildInfoProvider buildInfoProvider) {
    this.buildInfoProvider = buildInfoProvider;
  }

  @Override
  public ResponseEntity<Info> getInfo() {
    BuildInfo buildInfo = buildInfoProvider.buildInfo();
    return ResponseEntity.ok(new Info(buildInfo.version(), buildInfo.commit(), COPYRIGHT, REPOSITORY, LICENSE));
  }
}
