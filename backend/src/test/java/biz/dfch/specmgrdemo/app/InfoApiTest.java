package biz.dfch.specmgrdemo.app;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotEquals;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import org.junit.jupiter.api.Test;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

/**
 * The unit test of the operation GET /info (feat-9-walking-skeleton, Phase 200, the task 200.110 and the task
 * 200.120; the acceptance criterion ACC-003 of the plan). The controller gives the five values of the contract:
 * the version and the commit come from the build (the reader BuildInfoProvider, the resource of the name), and
 * the copyright holder, the address of the repository and the license are the constants of the project (DEC
 * 5ddd8d7a-5e7d-4a9b-860f-7d0b1f05579c).
 *
 * <p>The test of the ACC-003: the test changes the value of the build (the version, the commit) - the name of
 * the resource of the classpath is the seam (the two files of src/test/resources) - and it sees the change of
 * the response.
 */
class InfoApiTest {

  @Test
  void theTestChangesTheValueOfTheBuildAndSeesTheChangeOfTheResponse() {
    // The value of the build of the test (the resource build-info-test.properties of the test classpath).
    InfoController controller = new InfoController(new BuildInfoProvider("build-info-test.properties"));
    var first = controller.getInfo().getBody();
    assertEquals("9.9.9-test", first.getVersion());
    assertEquals("0123456789abcdef0123456789abcdef01234567", first.getCommit());

    // The change of the value of the build (the resource build-info-test-changed.properties).
    InfoController changedController = new InfoController(new BuildInfoProvider("build-info-test-changed.properties"));
    var changed = changedController.getInfo().getBody();
    assertEquals("8.8.8-test", changed.getVersion());
    assertEquals("fedcba9876543210fedcba9876543210fedcba98", changed.getCommit());

    // The test sees the change of the response (the version and the commit are other values).
    assertNotEquals(first.getVersion(), changed.getVersion());
    assertNotEquals(first.getCommit(), changed.getCommit());
  }

  @Test
  void theOperationSendsTheFiveValuesOfTheContractAsJson() throws Exception {
    InfoController controller = new InfoController(new BuildInfoProvider("build-info-test.properties"));
    MockMvc mockMvc = MockMvcBuilders.standaloneSetup(controller).build();
    mockMvc.perform(get("/info")).andExpect(status().isOk())
        .andExpect(jsonPath("$.version").value("9.9.9-test"))
        .andExpect(jsonPath("$.commit").value("0123456789abcdef0123456789abcdef01234567"))
        .andExpect(jsonPath("$.copyright").value("Copyright 2026 Ronald Rink"))
        .andExpect(jsonPath("$.repository").value("https://github.com/dfch/biz.dfch.SpecMgrDemo"))
        .andExpect(jsonPath("$.license").value("AGPL-3.0-only"));
  }
}
