package biz.dfch.specmgrdemo.architecture;

import static org.junit.jupiter.api.Assertions.assertTrue;

import com.structurizr.Workspace;
import com.tngtech.archunit.core.domain.JavaClass;
import com.tngtech.archunit.core.domain.JavaClasses;
import java.nio.file.Path;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.TreeMap;
import java.util.TreeSet;
import org.junit.jupiter.api.Test;

/**
 * The test that compares the Structurizr workspace with the packages and the dependencies of the code
 * (feat-7-verification-architecture-tools, Task 130.120, REQ-004, ACC-003; refactored onto the rule
 * set the model gives in feat-50-structurizr-model-rules, Task 130.130, REQ-005; the canonical form is
 * the section "The rules the model gives" of model/README.md; DEC e85e9685-0787-4dff-9ee5-9d46670e9ee4,
 * that replaces the name rule of DEC 9edc1071-4fd0-48b6-a037-1a4cb2331f73).
 *
 * <p>The side of the backend (this class; the side of the frontend is the script
 * frontend/architecture/compare.mjs of the recipe architecture-model). The workspace is the file
 * model/workspace.json of the repository (the path is relative to the folder of the module; the
 * property {@code model.workspace.path} gives another file, for the temporary copy of the recipe
 * architecture-model, part 2). The reader is the library structurizr-java (the artifact
 * structurizr-client, the class com.structurizr.io.json.JsonReader), and the reading and the
 * derivation are the shared class {@link ModelRules} (the same rule set that the runner
 * {@link ModelRuleRunnerTest} uses, so the two cannot drift apart).
 *
 * <p>The comparison is mapping-based (and not name-based): the components of the container {@code
 * backend} are read by their entries of the property {@code code.package} (the list form of the DEC),
 * and the code is the source: the classes of the base package of the container's property {@code
 * code.root} (the test classes are excluded by the import option DoNotIncludeTests of ArchUnit), and
 * their dependencies (the analysis of the dependencies of ArchUnit, the natural source: for each
 * class, the classes that it references). A package is owned by the component of the most specific
 * entry (the entry that is the package itself, or the longest entry that is a prefix of the package).
 *
 * <p>The assertions (the groups 3 and 4 of the canonical section, the closed set and the exceptions):
 * <ul>
 *   <li>every code location (the package of every class under code.root) is owned by exactly one
 *       component (the package that no component owns stops the test, and the message names the
 *       package; the package that two components own is the ambiguous mapping, and the message names
 *       the two components);
 *   <li>every code dependency between mapped components has a relation in the model (the message
 *       names the dependency, the packages of the source and of the destination);
 *   <li>the other direction: no component in the model without a class in the code, and no relation
 *       in the model without the code dependency (a model that the code does not have is a drift too:
 *       the code must obey the model, and the model must describe the code);
 *   <li>every code dependency to a package that no component owns is allowed if and only if it
 *       matches an entry of the source component's code.allowedExternal (the form of the DEC: the
 *       package is the entry, or a sub-package of the entry; a trailing .. marks the sub-packages).
 *       The dependency to the platform of the language (the packages java.* and javax.*) is given
 *       (the runtime of the language), and the check does not examine it. The package that an entry
 *       of code.ignore of the container covers is not examined at all (none today).
 * </ul>
 *
 * <p>The run is green on the committed code (ACC-002: the case that is successful, and ACC-003: the
 * workspace matches the code). The recipe architecture-model shows the case that is not successful
 * in a temporary copy of the repository: it removes a component (or a relation) from the copy of the
 * workspace, and the run of this class stops for it, naming the package (or the dependency) that the
 * model has no record of.
 */
class ModelComparisonTest {

  @Test
  void thePackagesAndDependenciesOfTheModuleAreInTheWorkspace() throws Exception {
    Path workspacePath = ModelRules.workspacePath();
    Workspace workspace = ModelRules.readWorkspace(workspacePath);
    ModelRules.ContainerMapping mapping = ModelRules.derive(workspace, "backend");
    JavaClasses classes = ModelRules.importClasses(mapping.root());

    // The code: the packages of the classes (the class that lies directly in the base package has no
    // top-level package, and it is no code location of the closed world, as before the refactor), and
    // their dependencies.
    Map<String, List<ModelRules.MappedComponent>> ownersByPackage = new TreeMap<>();
    for (JavaClass javaClass : classes) {
      String packageName = javaClass.getPackageName();
      if (!packageName.equals(mapping.root())) {
        ownersByPackage.putIfAbsent(packageName, ModelRules.owners(mapping, packageName));
      }
    }
    // The dependencies of the code: the pair of the packages (the source and the destination, and
    // the components that own them, or null for a package that no component owns).
    record CodeDependency(String sourcePackage, String destinationPackage, String sourceComponent, String destinationComponent)
        implements Comparable<CodeDependency> {
      @Override
      public int compareTo(CodeDependency other) {
        return java.util.Comparator.comparing(CodeDependency::sourcePackage)
            .thenComparing(CodeDependency::destinationPackage)
            .compare(this, other);
      }
    }
    Set<CodeDependency> codeDependencies = new TreeSet<>();
    for (JavaClass javaClass : classes) {
      String sourcePackage = javaClass.getPackageName();
      if (sourcePackage.equals(mapping.root())) {
        continue;
      }
      ModelRules.MappedComponent sourceOwner = ModelRules.ownerOf(mapping, sourcePackage);
      for (com.tngtech.archunit.core.domain.Dependency dependency : javaClass.getDirectDependenciesFromSelf()) {
        String destinationPackage = dependency.getTargetClass().getPackageName();
        if (destinationPackage.equals(sourcePackage)) {
          continue;
        }
        ModelRules.MappedComponent destinationOwner = ModelRules.ownerOf(mapping, destinationPackage);
        codeDependencies.add(
            new CodeDependency(
                sourcePackage,
                destinationPackage,
                sourceOwner == null ? null : sourceOwner.name(),
                destinationOwner == null ? null : destinationOwner.name()));
      }
    }

    // Group 3 (a): the code location that no component owns stops the test, and the message names
    // the package (the condition (a) of ACC-003). The code location that two components own is the
    // ambiguous mapping (the exactly one of the closed set).
    for (Map.Entry<String, List<ModelRules.MappedComponent>> entry : ownersByPackage.entrySet()) {
      List<ModelRules.MappedComponent> owners = entry.getValue();
      if (owners.isEmpty()) {
        if (ModelRules.entryCoversPackage(mapping.ignore(), entry.getKey())) {
          continue; // the package is in code.ignore of the container: the check does not examine it.
        }
        assertTrue(
            false,
            "the package " + entry.getKey() + " has no component in the model (the workspace " + workspacePath + ")");
      }
      if (owners.size() > 1) {
        String names = owners.stream().map(ModelRules.MappedComponent::name).reduce((a, b) -> a + ", " + b).orElse("");
        assertTrue(
            false,
            "the package " + entry.getKey() + " has two components in the model (" + names
                + ") (the workspace " + workspacePath + ")");
      }
    }
    // Group 3 (b): the code dependency between mapped components that is not in the model stops the
    // test, and the message names the dependency (the condition (b) of ACC-003).
    for (CodeDependency dependency : codeDependencies) {
      if (dependency.sourceComponent() != null && dependency.destinationComponent() != null
          && !dependency.sourceComponent().equals(dependency.destinationComponent())
          && !mapping.relations().contains(new ModelRules.ModelPair(dependency.sourceComponent(), dependency.destinationComponent()))) {
        assertTrue(
            false,
            "the dependency "
                + dependency.sourcePackage()
                + " -> "
                + dependency.destinationPackage()
                + " is not in the model (the workspace "
                + workspacePath
                + ")");
      }
    }
    // Group 3 (c): the other direction: the model has no component without a class in the code, and
    // no relation without the code dependency.
    for (ModelRules.MappedComponent component : mapping.components()) {
      boolean inCode =
          ownersByPackage.values().stream().anyMatch(owners -> owners.size() == 1 && owners.get(0).name().equals(component.name()));
      assertTrue(inCode, "the component " + component.name() + " of the model (the container backend) has no package in the code");
    }
    for (ModelRules.ModelPair relation : mapping.relations()) {
      boolean inCode =
          codeDependencies.stream()
              .anyMatch(dependency -> dependency.sourceComponent().equals(relation.source())
                  && dependency.destinationComponent().equals(relation.destination()));
      assertTrue(
          inCode,
          "the dependency " + relation.source() + " -> " + relation.destination()
              + " of the model (the container backend) is not in the code");
    }
    // Group 4: the code dependency to a package that no component owns (and that code.ignore does not
    // cover) is allowed if and only if it matches an entry of the source component's
    // code.allowedExternal. The dependency to the platform of the language is given.
    for (CodeDependency dependency : codeDependencies) {
      if (dependency.destinationComponent() != null || dependency.sourceComponent() == null) {
        continue; // the dependency between mapped components is the condition (b) above.
      }
      if (ModelRules.isPlatformPackage(dependency.destinationPackage())
          || ModelRules.entryCoversPackage(mapping.ignore(), dependency.destinationPackage())) {
        continue;
      }
      ModelRules.MappedComponent source =
          mapping.components().stream()
              .filter(component -> component.name().equals(dependency.sourceComponent()))
              .findFirst()
              .orElseThrow();
      assertTrue(
          ModelRules.entryCoversPackage(source.allowedExternal(), dependency.destinationPackage()),
          "the dependency "
              + dependency.sourcePackage()
              + " -> "
              + dependency.destinationPackage()
              + " is not allowed: the component "
              + source.name()
              + " has no entry in code.allowedExternal for "
              + dependency.destinationPackage()
              + " (the workspace "
              + workspacePath
              + ")");
    }
  }
}
