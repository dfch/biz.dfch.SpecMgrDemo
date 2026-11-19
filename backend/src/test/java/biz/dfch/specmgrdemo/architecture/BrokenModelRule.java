package biz.dfch.specmgrdemo.architecture;

import static com.tngtech.archunit.lang.syntax.ArchRuleDefinition.noClasses;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.junit.jupiter.api.Assertions.fail;

import com.tngtech.archunit.core.domain.JavaClasses;
import com.tngtech.archunit.lang.ArchRule;
import com.tngtech.archunit.lang.EvaluationResult;
import java.util.ArrayList;
import java.util.List;
import org.junit.jupiter.api.Test;

/**
 * The case that is not successful of the forbidden dependencies (the rule category of group 1 of
 * the canonical section; feat-50-structurizr-model-rules, Task 140.100, REQ-007, ACC-006; the
 * canonical form is the section "The rules the model gives" of model/README.md; DEC
 * e85e9685-0787-4dff-9ee5-9d46670e9ee4). The recipe architecture-backend runs this class
 * separately (the argument -Dtest=BrokenModelRule) and stops for it: the run of the tool is red,
 * and the recipe gives exit code 0.
 *
 * <p>The rules are derived, and not hard-coded (the same reading and the same derivation as the
 * runner ModelRuleRunnerTest, the shared class ModelRules): the class reads the workspace (the
 * file model/workspace.json of the repository; the property model.workspace.path gives another
 * file, the same interface as the runner and the comparison), takes the relations of the model
 * between the mapped components of the container backend (today exactly one: api -> model), and
 * builds for each of them the ArchUnit rule that FORBIDS it (the component api must not depend on
 * the component model). The code has the direction of each modelled relation (the other direction
 * of the closed world of the comparison ModelComparisonTest: a relation of the model without the
 * dependency of the code stops the run), so each rule is violated deterministically, and ArchUnit
 * names the violating dependency in the report of the run (the method getStatus() of the
 * generated interface StatusApi, with the return type of the model class Status).
 *
 * <p>The class has no suffix Test, so the default run of surefire does not start it (the committed
 * run of the tests is green). A modelled relation that the code does not violate any more stops
 * the class (the case that is not successful that passes silently would hide a change of the
 * code), and a model without a relation between the mapped components stops the class too (the
 * case cannot be demonstrated; no silent pass). The case that is not successful of the cycle rule
 * (group 2 of the canonical section) is the temporary copy of the recipe architecture-backend
 * (the part 3; the committed code has no cycle, and the scratch class of the copy makes it).
 */
class BrokenModelRule {

  @Test
  void theModelledRelationsAreViolatedByTheCode() throws Exception {
    ModelRules.ContainerMapping mapping =
        ModelRules.derive(ModelRules.readWorkspace(ModelRules.workspacePath()), "backend");
    List<ModelRules.ModelPair> modelled = new ArrayList<>(mapping.relations());
    modelled.sort(null);
    assertTrue(
        !modelled.isEmpty(),
        "the container backend has no relation between the mapped components (the model gives no "
            + "direction that the code has); the case that is not successful cannot be demonstrated");
    JavaClasses classes = ModelRules.importClasses(mapping.root());
    int total = 0;
    StringBuilder report = new StringBuilder();
    for (ModelRules.ModelPair pair : modelled) {
      ArchRule rule =
          noClasses()
              .that()
              .resideInAnyPackage(packagesOf(mapping, pair.source()).toArray(String[]::new))
              .should()
              .dependOnClassesThat()
              .resideInAnyPackage(packagesOf(mapping, pair.destination()).toArray(String[]::new))
              .because("the case that is not successful: the code has the direction "
                  + pair.source() + " -> " + pair.destination() + " (the relation of the model)");
      EvaluationResult result = rule.evaluate(classes);
      if (result.hasViolation()) {
        total += result.getFailureReport().getDetails().size();
        report.append(result.getFailureReport()).append(System.lineSeparator());
      }
    }
    if (total == 0) {
      fail("the violated rules have no violation (the code does not have the direction of the "
          + "modelled relations any more); the case that is not successful would pass silently, "
          + "and a change of the code or of the model would hide");
    }
    // The run of the tool is red (the case that is not successful of the forbidden dependencies,
    // ACC-006): the failure message is the report of ArchUnit, and it names the violating
    // dependency (the report of the run, as the rule R2 of feat-7). The recipe
    // architecture-backend (the part 2) asserts the exit code and the report, and the recipe
    // gives exit code 0.
    fail("the violated rules have "
        + total
        + " violation(s) (the case that is not successful: the code has the direction of the "
        + "modelled relations)\n"
        + report);
  }

  /**
   * The entries of the mapping of the component of the name, in the form of the package identifier
   * of ArchUnit (the entry and its sub-packages, the suffix ..; the same form as the runner
   * ModelRuleRunnerTest).
   */
  private static List<String> packagesOf(ModelRules.ContainerMapping mapping, String componentName) {
    return mapping.components().stream()
        .filter(component -> component.name().equals(componentName))
        .flatMap(component -> component.entries().stream())
        .map(entry -> entry + "..")
        .toList();
  }
}
