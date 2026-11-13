package biz.dfch.specmgrdemo.architecture;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.structurizr.Workspace;
import com.structurizr.io.json.JsonReader;
import com.structurizr.model.Component;
import com.structurizr.model.Container;
import com.structurizr.model.Element;
import com.structurizr.model.Relationship;
import com.structurizr.model.SoftwareSystem;
import com.tngtech.archunit.core.domain.JavaClass;
import com.tngtech.archunit.core.domain.JavaClasses;
import com.tngtech.archunit.core.importer.ClassFileImporter;
import com.tngtech.archunit.core.importer.ImportOption;
import java.io.StringReader;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Comparator;
import java.util.Map;
import java.util.Set;
import java.util.TreeMap;
import java.util.TreeSet;
import java.util.stream.Collectors;
import org.junit.jupiter.api.Test;

/**
 * The test that compares the Structurizr workspace with the modules and the packages of the code
 * (feat-7-verification-architecture-tools, Task 130.120, REQ-004, ACC-003; DEC
 * 9edc1071-4fd0-48b6-a037-1a4cb2331f73: "A test reads the workspace and compares the components
 * with the modules and the packages").
 *
 * <p>The side of the backend (this class; the side of the frontend is the script
 * frontend/architecture/compare.mjs of the recipe architecture-model). The workspace is the file
 * {@code model/workspace.json} of the repository (the path is relative to the folder of the module;
 * the property {@code model.workspace.path} gives another file, for the temporary copy of the
 * recipe architecture-model, part 2). The reader is the library structurizr-java (the artifact
 * structurizr-client, the class com.structurizr.io.json.JsonReader).
 *
 * <p>The code is the source: the top-level packages of the compiled classes of the module (the
 * packages {@code biz.dfch.specmgrdemo.*}; the classes of the test are excluded by the import
 * option DoNotIncludeTests of ArchUnit, the same option that Spring Modulith uses for R1), and
 * their dependencies (the analysis of the dependencies of ArchUnit, the natural source: for each
 * class, the classes that it references).
 *
 * <p>The assertions (the two conditions of ACC-003, and the other direction, recorded in the plan):
 * <ul>
 *   <li>every package has a component in the model (the components of the container {@code backend},
 *       named like the packages, DEC 9edc1071: "The name of a package is the same as the identifier
 *       of its component in the model");
 *   <li>every package dependency is in the model (the dependencies between the components of the
 *       container {@code backend});
 *   <li>the other direction: no component in the model without a package, and no dependency in the
 *       model without the package dependency of the code.
 * </ul>
 *
 * <p>The run is green on the committed code (ACC-002: the case that is successful, and ACC-003: the
 * workspace matches the code). The recipe architecture-model shows the case that is not successful
 * in a temporary copy of the repository: it removes a component (or a dependency) from the copy of
 * the workspace, and the run of this class stops for it, naming the package (or the dependency)
 * that the model has no record of.
 */
class ModelComparisonTest {

  private static final String BASE_PACKAGE = "biz.dfch.specmgrdemo";

  /**
   * A dependency between two top-level packages of the module (the source and the target, in the
   * name of the package and not in the full name).
   */
  record PackageDependency(String source, String target) implements Comparable<PackageDependency> {
    @Override
    public int compareTo(PackageDependency other) {
      int result = Comparator.comparing(PackageDependency::source).thenComparing(PackageDependency::target)
          .compare(this, other);
      return result;
    }
  }

  @Test
  void thePackagesAndDependenciesOfTheModuleAreInTheWorkspace() throws Exception {
    Path workspacePath = Path.of(System.getProperty("model.workspace.path", "../model/workspace.json"));
    Workspace workspace = readWorkspace(workspacePath);
    Container backend = theContainer(workspace, "backend");

    // The code: the top-level packages of the compiled classes of the module, and their dependencies.
    JavaClasses classes =
        new ClassFileImporter()
            .withImportOption(ImportOption.Predefined.DO_NOT_INCLUDE_TESTS)
            .importPackages(BASE_PACKAGE);
    Set<String> packages =
        classes.stream()
            .map(ModelComparisonTest::topLevelPackage)
            .filter(java.util.Objects::nonNull)
            .collect(Collectors.toCollection(TreeSet::new));
    Set<PackageDependency> codeDependencies = dependenciesOf(classes);

    // The model: the components of the container backend, and the dependencies between them.
    Set<String> modelComponents =
        backend.getComponents().stream().map(Element::getName).collect(Collectors.toCollection(TreeSet::new));
    Map<String, Component> componentsById =
        backend.getComponents().stream().collect(Collectors.toMap(Element::getId, component -> component));
    Set<PackageDependency> modelDependencies = dependenciesBetween(backend, componentsById);

    // ACC-003 (a): a package that has no component in the model stops the test, and the message
    // names the package.
    for (String p : packages) {
      assertTrue(
          modelComponents.contains(p),
          "the package " + BASE_PACKAGE + "." + p + " has no component in the model (the workspace " + workspacePath + ")");
    }
    // ACC-003 (b): a package dependency that is not in the model stops the test, and the message
    // names the dependency.
    for (PackageDependency dependency : codeDependencies) {
      assertTrue(
          modelDependencies.contains(dependency),
          "the dependency "
              + BASE_PACKAGE
              + "."
              + dependency.source()
              + " -> "
              + BASE_PACKAGE
              + "."
              + dependency.target()
              + " is not in the model (the workspace "
              + workspacePath
              + ")");
    }
    // The other direction (recorded in the plan): the model has no component without a package, and
    // no dependency without the dependency of the code. A model that the code does not have is a
    // drift too (the code must obey the model, and the model must describe the code).
    for (String component : modelComponents) {
      assertTrue(
          packages.contains(component),
          "the component " + component + " of the model (the container backend) has no package in the code");
    }
    for (PackageDependency dependency : modelDependencies) {
      assertTrue(
          codeDependencies.contains(dependency),
          "the dependency "
              + dependency.source()
              + " -> "
              + dependency.target()
              + " of the model (the container backend) is not in the code");
    }
  }

  /**
   * Read the workspace file with the library structurizr-java. A file that is not in the form of the
   * writer of the library (or that is not JSON) stops the test (the reader throws).
   */
  private static Workspace readWorkspace(Path workspacePath) throws Exception {
    assertTrue(Files.isRegularFile(workspacePath), "the workspace does not exist: " + workspacePath);
    String content = Files.readString(workspacePath);
    try (StringReader reader = new StringReader(content)) {
      Workspace result = new JsonReader().read(reader);
      assertNotNull(result, "the reader of structurizr-java made no workspace from " + workspacePath);
      return result;
    }
  }

  /**
   * The container of the name in the one software system of the model.
   */
  private static Container theContainer(Workspace workspace, String name) {
    Set<SoftwareSystem> systems = workspace.getModel().getSoftwareSystems();
    assertEquals(1, systems.size(), "the model has exactly one software system (it has " + systems.size() + ")");
    Container result = systems.iterator().next().getContainerWithName(name);
    assertNotNull(result, "the model has no container " + name);
    return result;
  }

  /**
   * The top-level package of the class under the base package (the segment after the base package),
   * or null if the class is not under the base package.
   */
  private static String topLevelPackage(JavaClass javaClass) {
    String packageName = javaClass.getPackageName();
    String prefix = BASE_PACKAGE + ".";
    if (!packageName.startsWith(prefix)) {
      return null;
    }
    String rest = packageName.substring(prefix.length());
    int separator = rest.indexOf('.');
    String result = separator < 0 ? rest : rest.substring(0, separator);
    return result.isEmpty() ? null : result;
  }

  /**
   * The dependencies between the top-level packages of the module: for each class of the compiled
   * classes (the test classes are excluded), the classes that it references, in the other top-level
   * packages.
   */
  private static Set<PackageDependency> dependenciesOf(JavaClasses classes) {
    Set<PackageDependency> result = new TreeSet<>();
    for (JavaClass javaClass : classes) {
      String source = topLevelPackage(javaClass);
      if (source == null) {
        continue;
      }
      for (com.tngtech.archunit.core.domain.Dependency dependency : javaClass.getDirectDependenciesFromSelf()) {
        String target = topLevelPackage(dependency.getTargetClass());
        if (target != null && !target.equals(source)) {
          result.add(new PackageDependency(source, target));
        }
      }
    }
    return result;
  }

  /**
   * The dependencies of the model between the components of the container: the relationships of the
   * model whose source and whose destination are components of the container (the ids of the
   * relationship are resolved with the ids of the components; the reader of the library resolves the
   * objects of the source and of the destination too, and both give the same pair).
   */
  private static Set<PackageDependency> dependenciesBetween(Container container, Map<String, Component> componentsById) {
    Set<PackageDependency> result = new TreeSet<>();
    for (Relationship relationship : container.getModel().getRelationships()) {
      Element source = relationship.getSource();
      Element destination = relationship.getDestination();
      if (source instanceof Component sourceComponent
          && destination instanceof Component destinationComponent
          && sourceComponent.getContainer() == container
          && destinationComponent.getContainer() == container) {
        result.add(new PackageDependency(sourceComponent.getName(), destinationComponent.getName()));
      } else if (source == null || destination == null) {
        // The reader has not resolved one side of the relationship (the file has an id that the
        // model has no element for). The id of the source and the id of the destination give the
        // pair, if both ids are components of the container.
        Component sourceById = componentsById.get(relationship.getSourceId());
        Component destinationById = componentsById.get(relationship.getDestinationId());
        if (sourceById != null && destinationById != null) {
          result.add(new PackageDependency(sourceById.getName(), destinationById.getName()));
        }
      }
    }
    return result;
  }
}
