package biz.dfch.specmgrdemo.architecture;

import static com.tngtech.archunit.lang.syntax.ArchRuleDefinition.noClasses;

import com.tngtech.archunit.junit.AnalyzeClasses;
import com.tngtech.archunit.junit.ArchTest;
import com.tngtech.archunit.lang.ArchRule;

/**
 * Made by bin/120-100-00-generate-rules.mjs from the model (model/workspace.dsl, feat-0-demoprep). Do not change by hand.
 * backend: 3 components, 3 arrows, 3 forbidden pairs.
 */
@AnalyzeClasses(packages = "biz.dfch.specmgrdemo")
class ModelRulesTest {

  @ArchTest
  static final ArchRule API_MUST_NOT_DEPEND_ON_APP =
      noClasses()
          .that()
          .resideInAPackage("biz.dfch.specmgrdemo.api..")
          .should()
          .dependOnClassesThat()
          .resideInAPackage("biz.dfch.specmgrdemo.app..")
          .because("the model has no arrow from api to app (container backend, feat-0-demoprep)");

  @ArchTest
  static final ArchRule MODEL_MUST_NOT_DEPEND_ON_API =
      noClasses()
          .that()
          .resideInAPackage("biz.dfch.specmgrdemo.model..")
          .should()
          .dependOnClassesThat()
          .resideInAPackage("biz.dfch.specmgrdemo.api..")
          .because("the model has no arrow from model to api (container backend, feat-0-demoprep)");

  @ArchTest
  static final ArchRule MODEL_MUST_NOT_DEPEND_ON_APP =
      noClasses()
          .that()
          .resideInAPackage("biz.dfch.specmgrdemo.model..")
          .should()
          .dependOnClassesThat()
          .resideInAPackage("biz.dfch.specmgrdemo.app..")
          .because("the model has no arrow from model to app (container backend, feat-0-demoprep)");
}
