package biz.dfch.specmgrdemo.architecture;

import static com.tngtech.archunit.lang.syntax.ArchRuleDefinition.noClasses;

import com.tngtech.archunit.junit.ArchTest;
import com.tngtech.archunit.junit.AnalyzeClasses;
import com.tngtech.archunit.lang.ArchRule;

/**
 * The case that is not successful of the architecture tools (feat-7-verification-architecture-tools,
 * Task 130.100, ACC-002): a layer rule that the code of the module violates.
 *
 * <p>The rule: the layer {@code api} must not depend on the layer {@code model} - the opposite of
 * {@link LayerRuleTest#THE_MODEL_DOES_NOT_DEPEND_ON_THE_API}. The code violates the rule
 * deterministically: the generated interface {@code biz.dfch.specmgrdemo.api.StatusApi} references
 * the classes of {@code biz.dfch.specmgrdemo.model}. ArchUnit names the violating dependency in the
 * report of the run (the lines "Dependency from ... to ... violates ...").
 *
 * <p>The class has no suffix {@code Test}, so the default run of surefire does not start it (the
 * committed run of the tests is green). The recipe architecture-backend runs the class separately
 * (the argument -Dtest=BrokenLayerRule), and the recipe stops for the rule: the run of the tool is
 * red, and the recipe gives exit code 0.
 */
@AnalyzeClasses(packages = "biz.dfch.specmgrdemo")
class BrokenLayerRule {

  @ArchTest
  static final ArchRule THE_API_MUST_NOT_DEPEND_ON_THE_MODEL =
      noClasses()
          .that()
          .resideInAPackage("biz.dfch.specmgrdemo.api..")
          .should()
          .dependOnClassesThat()
          .resideInAPackage("biz.dfch.specmgrdemo.model..")
          .because("the case that is not successful: the code has the direction api -> model (ACC-002)");
}
