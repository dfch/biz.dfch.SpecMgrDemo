package biz.dfch.specmgrdemo.architecture;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.util.Set;
import java.util.stream.Collectors;
import org.junit.jupiter.api.Test;
import org.springframework.modulith.core.ApplicationModule;
import org.springframework.modulith.core.ApplicationModules;

/**
 * R1 of the architecture tools (feat-7-verification-architecture-tools, Task 130.100): the module
 * structure of the module, examined by Spring Modulith (DEC 9edc1071-4fd0-48b6-a037-1a4cb2331f73:
 * "In the backend, each top-level package is a Spring Modulith module and is one component of the
 * model").
 *
 * <p>The rule: the top-level packages of the module are the modules of the base package
 * {@code biz.dfch.specmgrdemo} - exactly {@code api} and {@code model}, no more, no less (given the
 * code that exists today). The module structure has no violation (no cycle, no unknown module).
 *
 * <p>The run of the rule is green on the committed code (ACC-002: the case that is successful). The
 * case that is not successful of ArchUnit (the tool that examines the layers in a module) is the class
 * {@code BrokenLayerRule} (no suffix {@code Test}, the violated layer rule): the recipe
 * architecture-backend runs it in part 2 and stops for it. The case that is not successful of Spring
 * Modulith is part 3 of the same recipe: in a temporary copy of the repository the copy has a new
 * top-level package ({@code extra}), and the recipe runs this test in the copy
 * ({@code -Dtest=ModuleStructureTest}) and stops for it: the run of the copy is red, and the report
 * names the package {@code extra}.
 *
 * <p>The test does not start a Spring context: {@code ApplicationModules.of(...)} derives the modules
 * from the classes on the class path (the classes of the test itself are in the folder
 * {@code target/test-classes}, and the default import option of the factory excludes the classes of
 * that folder, so the modules are the ones of the compiled classes of the module only).
 */
class ModuleStructureTest {

  private static final String BASE_PACKAGE = "biz.dfch.specmgrdemo";

  @Test
  void theTopLevelPackagesAreExactlyTheModulesApiAndModel() {
    ApplicationModules modules = ApplicationModules.of(BASE_PACKAGE);
    // getIdentifier() is the name of the module (getName() is deprecated in the 1.4.x line).
    Set<String> result = modules.stream().map(module -> module.getIdentifier().toString()).collect(Collectors.toSet());
    assertEquals(
        Set.of("api", "model"),
        result,
        "the top-level packages of the module are the modules of " + BASE_PACKAGE + " (exactly these two, no more, no less)");
  }

  @Test
  void apiAndModelAreModulesOfTheBasePackage() {
    ApplicationModules modules = ApplicationModules.of(BASE_PACKAGE);
    assertTrue(modules.getModuleByName("api").isPresent(), "the package api is a module of " + BASE_PACKAGE);
    assertTrue(modules.getModuleByName("model").isPresent(), "the package model is a module of " + BASE_PACKAGE);
  }

  @Test
  void theModuleStructureHasNoViolation() {
    // verify() stops (throws) for a violation of the module structure (a cycle, a module that the
    // structure does not know, ...). A green run is the assertion.
    ApplicationModules.of(BASE_PACKAGE).verify();
  }
}
