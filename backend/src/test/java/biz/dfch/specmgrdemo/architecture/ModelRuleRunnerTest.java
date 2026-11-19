package biz.dfch.specmgrdemo.architecture;

import static com.tngtech.archunit.lang.syntax.ArchRuleDefinition.noClasses;
import static com.tngtech.archunit.library.dependencies.SlicesRuleDefinition.slices;
import static org.junit.jupiter.api.DynamicTest.dynamicTest;

import com.tngtech.archunit.core.domain.JavaClass;
import com.tngtech.archunit.core.domain.JavaClasses;
import com.tngtech.archunit.lang.ArchRule;
import com.tngtech.archunit.library.dependencies.SliceAssignment;
import com.tngtech.archunit.library.dependencies.SliceIdentifier;
import com.tngtech.archunit.library.dependencies.SliceRule;
import java.util.ArrayList;
import java.util.List;
import java.util.stream.Stream;
import org.junit.jupiter.api.DynamicTest;
import org.junit.jupiter.api.TestFactory;

/**
 * The runner of the rules the model gives (feat-50-structurizr-model-rules, Task 130.110, REQ-004,
 * ACC-005; the canonical form is the section "The rules the model gives" of model/README.md; DEC
 * e85e9685-0787-4dff-9ee5-9d46670e9ee4). This class replaces the hard-coded rules R1 and R2 of
 * feat-7-verification-architecture-tools (the classes ModuleStructureTest and LayerRuleTest, removed
 * in Task 130.140).
 *
 * <p>The test reads the workspace (the file model/workspace.json of the repository; the property
 * model.workspace.path gives another file, the same interface as ModelComparisonTest), derives the
 * rule set of the container backend (the groups 1 and 2 of the canonical section: the forbidden
 * dependencies and the cycle rule), and builds the ArchUnit rules at test time. One dynamic test per
 * derived rule:
 * <ul>
 *   <li>the forbidden dependencies: for every ordered pair of distinct mapped components that has no
 *       relation in the model, no classes that reside in the packages of the source component may
 *       depend on classes that reside in the packages of the destination component (the form of the
 *       spike of Phase 100: a component with several entries of code.package is the predicate
 *       resideInAnyPackage, and an entry covers the package and its sub-packages, the suffix ..);
 *   <li>the cycle rule: the slices of the mapped components (one slice per component, the most
 *       specific entry of code.package, the same ownership as the comparison) are free of cycles.
 * </ul>
 *
 * <p>The classes: the base package of the container's code.root, the test classes excluded by the
 * import option DoNotIncludeTests (the same option as the comparison). The violations that ArchUnit
 * reports name the dependency, as the rule R2 of feat-7 (the report of the run). The run is green on
 * the committed code (ACC-002 and ACC-005): the model gives one forbidden pair (the component model
 * must not depend on the component api; the direction of the code is api -> model) and one cycle
 * rule. The test does not start a Spring context (plain JUnit and ArchUnit only).
 */
class ModelRuleRunnerTest {

  @TestFactory
  Stream<DynamicTest> theRulesTheModelGives() throws Exception {
    ModelRules.ContainerMapping mapping = ModelRules.derive(ModelRules.readWorkspace(ModelRules.workspacePath()), "backend");
    if (mapping.components().isEmpty()) {
      throw new IllegalStateException("the container backend has no mapped component (code.language java and code.package); "
          + "the model gives no rule (the comparison of ModelComparisonTest stops for it)");
    }
    JavaClasses classes = ModelRules.importClasses(mapping.root());
    List<ModelRules.ModelPair> forbidden = mapping.forbiddenPairs();
    System.out.println("the model gives " + forbidden.size() + " forbidden pair(s) and 1 cycle rule for the container "
        + mapping.name() + " (" + (forbidden.size() + 1) + " derived rule(s))");
    List<DynamicTest> result = new ArrayList<>();
    for (ModelRules.ModelPair pair : forbidden) {
      ArchRule rule =
          noClasses()
              .that()
              .resideInAnyPackage(packagesOf(mapping, pair.source()).toArray(String[]::new))
              .should()
              .dependOnClassesThat()
              .resideInAnyPackage(packagesOf(mapping, pair.destination()).toArray(String[]::new))
              .because("the model gives no relation " + pair.source() + " -> " + pair.destination()
                  + " (the closed world between the mapped elements, the section of model/README.md)");
      result.add(
          dynamicTest("the component " + pair.source() + " must not depend on the component " + pair.destination(), () -> rule.check(classes)));
    }
    SliceRule cycleRule =
        slices()
            .assignedFrom(sliceAssignment(mapping))
            .as("the slices of the mapped components of the container " + mapping.name())
            .should()
            .beFreeOfCycles();
    result.add(
        dynamicTest("the mapped components of the container " + mapping.name() + " have no dependency cycle", () -> cycleRule.check(classes)));
    return result.stream();
  }

  /**
   * The entries of the mapping of the component of the name, in the form of the package identifier of
   * ArchUnit (the entry and its sub-packages, the suffix ..).
   */
  private static List<String> packagesOf(ModelRules.ContainerMapping mapping, String componentName) {
    return mapping.components().stream()
        .filter(component -> component.name().equals(componentName))
        .flatMap(component -> component.entries().stream())
        .map(entry -> entry + "..")
        .toList();
  }

  /**
   * The assignment of the classes to the slices of the mapped components (the most specific entry of
   * code.package, the same ownership as the comparison, per the canonical section of model/README.md).
   */
  private static SliceAssignment sliceAssignment(ModelRules.ContainerMapping mapping) {
    return new SliceAssignment() {
      @Override
      public SliceIdentifier getIdentifierOf(JavaClass javaClass) {
        ModelRules.MappedComponent owner = ModelRules.ownerOf(mapping, javaClass.getPackageName());
        return owner == null ? SliceIdentifier.ignore() : SliceIdentifier.of(owner.name());
      }

      @Override
      public String getDescription() {
        return "the mapped component of the container " + mapping.name();
      }
    };
  }
}
