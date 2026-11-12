package biz.dfch.specmgrdemo.architecture;

import static com.tngtech.archunit.lang.syntax.ArchRuleDefinition.noClasses;

import com.tngtech.archunit.junit.ArchTest;
import com.tngtech.archunit.junit.AnalyzeClasses;
import com.tngtech.archunit.lang.ArchRule;

/**
 * R2 of the architecture tools (feat-7-verification-architecture-tools, Task 130.100): the layer
 * rule of the module, examined by ArchUnit (DEC 9edc1071-4fd0-48b6-a037-1a4cb2331f73: "ArchUnit
 * examines the layers in a module").
 *
 * <p>The rule: the layer {@code model} does not depend on the layer {@code api}. The direction of
 * the code is {@code api} -&gt; {@code model} (the generated interfaces of {@code api} reference the
 * classes of {@code model}, and the classes of {@code model} reference no class of {@code api}).
 *
 * <p>The run of the rule is green on the committed code (ACC-002: the case that is successful). The
 * case that is not successful is the class {@link BrokenLayerRule} (no suffix {@code Test}, so the
 * default run of surefire does not start it): the recipe architecture-backend runs it separately and
 * stops for it. ArchUnit names the violating dependency in the report.
 */
@AnalyzeClasses(packages = "biz.dfch.specmgrdemo")
class LayerRuleTest {

  @ArchTest
  static final ArchRule THE_MODEL_DOES_NOT_DEPEND_ON_THE_API =
      noClasses()
          .that()
          .resideInAPackage("biz.dfch.specmgrdemo.model..")
          .should()
          .dependOnClassesThat()
          .resideInAPackage("biz.dfch.specmgrdemo.api..")
          .because("the direction of the code is api -> model (DEC 9edc1071-4fd0-48b6-a037-1a4cb2331f73)");
}
