package biz.dfch.specmgrdemo.architecture;

import com.structurizr.Workspace;
import com.structurizr.io.json.JsonReader;
import com.structurizr.model.Component;
import com.structurizr.model.Container;
import com.structurizr.model.Element;
import com.structurizr.model.Relationship;
import com.structurizr.model.SoftwareSystem;
import com.tngtech.archunit.core.domain.JavaClasses;
import com.tngtech.archunit.core.importer.ClassFileImporter;
import com.tngtech.archunit.core.importer.ImportOption;
import java.io.StringReader;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.TreeSet;
import java.util.stream.Collectors;
import org.junit.jupiter.api.Assertions;

/**
 * The shared reading and derivation of the rule set the model gives (feat-50-structurizr-model-rules,
 * Task 130.100, REQ-004 and REQ-005; the canonical form is the section "The rules the model gives" of
 * model/README.md; DEC e85e9685-0787-4dff-9ee5-9d46670e9ee4).
 *
 * <p>The runner (ModelRuleRunnerTest: the forbidden dependencies and the cycle rule, groups 1 and 2 of
 * the canonical section) and the comparison (ModelComparisonTest: the closed set and the exceptions,
 * groups 3 and 4) both read the workspace through this class, and they derive the same rule set, so the
 * two cannot drift apart.
 *
 * <p>The derivation of one container (the container of the name, in the one software system of the
 * model): the mapped elements are the components that have the property code.language with the value
 * java and the property code.package (the list of full package names, that the character comma
 * separates, DEC e85e9685); the container has the properties code.language (java) and code.root (the
 * base package of the module; the import of the classes is from this package), and the optional
 * property code.ignore (the list of packages that no element maps and that the check does not examine).
 * The forbidden dependencies (group 1): every ordered pair of distinct mapped elements that has no
 * relation in the model. The relations: the relationships of the model whose both sides are mapped
 * components of the container (the container-level relationships are not compared with the code, the
 * first limit of the closed world, DEC e85e9685).
 */
final class ModelRules {

  private ModelRules() {
  }

  /** The system property that gives the file of the workspace (the temporary copy of the recipe architecture-model). */
  static final String WORKSPACE_PROPERTY = "model.workspace.path";

  /** The file of the workspace (the property, or the default file of the repository). */
  static Path workspacePath() {
    return Path.of(System.getProperty(WORKSPACE_PROPERTY, "../model/workspace.json"));
  }

  /**
   * One mapped component of the container (the name, the entries of the mapping, the entries of the
   * exception code.allowedExternal).
   */
  record MappedComponent(String name, List<String> entries, List<String> allowedExternal) {}

  /**
   * A pair of mapped components of the container (the names, the source and the destination).
   */
  record ModelPair(String source, String destination) implements Comparable<ModelPair> {
    @Override
    public int compareTo(ModelPair other) {
      return Comparator.comparing(ModelPair::source).thenComparing(ModelPair::destination).compare(this, other);
    }
  }

  /**
   * The mapping of one container (the rule set the model gives for the container, per the canonical
   * section of model/README.md).
   */
  record ContainerMapping(
      String name, String language, String root, List<String> ignore, List<MappedComponent> components, Set<ModelPair> relations) {

    /**
     * The forbidden dependencies (group 1 of the canonical section): every ordered pair of distinct
     * mapped components that has no relation in the model (the closed world between the mapped
     * elements).
     */
    List<ModelPair> forbiddenPairs() {
      List<ModelPair> result = new ArrayList<>();
      for (MappedComponent source : components) {
        for (MappedComponent destination : components) {
          if (!source.name().equals(destination.name())
              && !relations.contains(new ModelPair(source.name(), destination.name()))) {
            result.add(new ModelPair(source.name(), destination.name()));
          }
        }
      }
      return result;
    }
  }

  /**
   * Read the workspace file with the library structurizr-java. A file that is not in the form of the
   * writer of the library (or that is not JSON) stops the test (the reader throws).
   */
  static Workspace readWorkspace(Path workspacePath) throws Exception {
    Assertions.assertTrue(Files.isRegularFile(workspacePath), "the workspace does not exist: " + workspacePath);
    String content = Files.readString(workspacePath);
    try (StringReader reader = new StringReader(content)) {
      Workspace result = new JsonReader().read(reader);
      Assertions.assertNotNull(result, "the reader of structurizr-java made no workspace from " + workspacePath);
      return result;
    }
  }

  /**
   * The container of the name in the one software system of the model.
   */
  static Container theContainer(Workspace workspace, String name) {
    Set<SoftwareSystem> systems = workspace.getModel().getSoftwareSystems();
    Assertions.assertEquals(1, systems.size(), "the model has exactly one software system (it has " + systems.size() + ")");
    Container result = systems.iterator().next().getContainerWithName(name);
    Assertions.assertNotNull(result, "the model has no container " + name);
    return result;
  }

  /**
   * Derive the mapping of the container of the name (the rule set the model gives for the container).
   * The language of the container must be java (the side of the backend; the side of the frontend
   * derives through the module frontend/architecture/workspace.mjs, the same derivation).
   */
  static ContainerMapping derive(Workspace workspace, String containerName) {
    Container container = theContainer(workspace, containerName);
    String language = property(container, "code.language");
    Assertions.assertNotNull(language, "the container " + containerName + " has no property code.language (the workspace)");
    Assertions.assertEquals("java", language, "the container " + containerName + " has the language " + language
        + ", and this side has java only");
    String root = property(container, "code.root");
    Assertions.assertNotNull(root, "the container " + containerName + " has no property code.root (the workspace)");
    List<String> ignore = parseList(property(container, "code.ignore"));
    List<MappedComponent> components = new ArrayList<>();
    for (Component component : container.getComponents()) {
      // An element without a mapping is not compared with the code (the first limit of the closed
      // world, DEC e85e9685).
      if (!"java".equals(property(component, "code.language"))) {
        continue;
      }
      String packages = property(component, "code.package");
      if (packages == null) {
        continue;
      }
      components.add(
          new MappedComponent(component.getName(), parseList(packages), parseList(property(component, "code.allowedExternal"))));
    }
    components.sort(Comparator.comparing(MappedComponent::name));
    return new ContainerMapping(container.getName(), language, root, ignore, components, relationsBetween(container, components));
  }

  /**
   * The value of the property of the element, or null if the element has no such property (or the value
   * is blank).
   */
  static String property(Element element, String key) {
    String result = element.getProperties().get(key);
    return result == null || result.isBlank() ? null : result;
  }

  /**
   * The list form of the DEC: the entries that the character comma separates (a space after the comma
   * is allowed), or the empty list for no value.
   */
  static List<String> parseList(String value) {
    if (value == null) {
      return List.of();
    }
    return java.util.Arrays.stream(value.split(",")).map(String::trim).filter(entry -> !entry.isEmpty()).collect(Collectors.toList());
  }

  /**
   * The relationships of the model between the mapped components of the container (the names of the
   * components; the ids of the relationship resolve to the components of the container - the reader
   * resolves the objects of the source and of the destination too, and the ids are the fallback).
   */
  static Set<ModelPair> relationsBetween(Container container, List<MappedComponent> components) {
    Map<String, Component> componentsById =
        container.getComponents().stream().collect(Collectors.toMap(Element::getId, component -> component));
    Set<String> mappedNames = components.stream().map(MappedComponent::name).collect(Collectors.toCollection(TreeSet::new));
    Set<ModelPair> result = new TreeSet<>();
    for (Relationship relationship : container.getModel().getRelationships()) {
      Element source = relationship.getSource();
      Element destination = relationship.getDestination();
      if (source instanceof Component sourceComponent
          && destination instanceof Component destinationComponent
          && sourceComponent.getContainer() == container
          && destinationComponent.getContainer() == container) {
        if (mappedNames.contains(sourceComponent.getName()) && mappedNames.contains(destinationComponent.getName())) {
          result.add(new ModelPair(sourceComponent.getName(), destinationComponent.getName()));
        }
      } else if (source == null || destination == null) {
        // The reader has not resolved one side of the relationship (the file has an id that the model
        // has no element for). The ids give the pair, if both ids are mapped components of the container.
        Component sourceById = componentsById.get(relationship.getSourceId());
        Component destinationById = componentsById.get(relationship.getDestinationId());
        if (sourceById != null && destinationById != null
            && mappedNames.contains(sourceById.getName()) && mappedNames.contains(destinationById.getName())) {
          result.add(new ModelPair(sourceById.getName(), destinationById.getName()));
        }
      }
    }
    return result;
  }

  /**
   * The mapped component that owns the package: the component of the most specific entry (the entry
   * that is the package itself, or the longest entry that is a prefix of the package at the boundary
   * of the package), or null if no component owns the package. Two components that have the same most
   * specific entry for the package is an ambiguous mapping (the comparison stops for it, the exactly
   * one of group 3 of the canonical section).
   */
  static MappedComponent ownerOf(ContainerMapping mapping, String packageName) {
    MappedComponent best = null;
    int bestLength = -1;
    for (MappedComponent component : mapping.components()) {
      for (String entry : component.entries()) {
        if ((packageName.equals(entry) || packageName.startsWith(entry + ".")) && entry.length() > bestLength) {
          best = component;
          bestLength = entry.length();
        }
      }
    }
    return best;
  }

  /**
   * The mapped components that have the most specific entry for the package (the list form, for the
   * exactly one check: the empty list is no owner, the list of two is the ambiguous mapping).
   */
  static List<MappedComponent> owners(ContainerMapping mapping, String packageName) {
    int bestLength = -1;
    for (MappedComponent component : mapping.components()) {
      for (String entry : component.entries()) {
        if (packageName.equals(entry) || packageName.startsWith(entry + ".")) {
          bestLength = Math.max(bestLength, entry.length());
        }
      }
    }
    List<MappedComponent> result = new ArrayList<>();
    if (bestLength >= 0) {
      for (MappedComponent component : mapping.components()) {
        for (String entry : component.entries()) {
          if ((packageName.equals(entry) || packageName.startsWith(entry + ".")) && entry.length() == bestLength) {
            result.add(component);
            break;
          }
        }
      }
    }
    return result;
  }

  /**
   * The package that an entry of code.ignore or of code.allowedExternal covers: the package is the
   * entry (the trailing .. of the form is no part of the package), or a sub-package of the entry (the
   * form of the DEC: a trailing .. marks the package and all its sub-packages; a dependency to a
   * package that starts with an entry is allowed).
   */
  static boolean entryCoversPackage(List<String> entries, String packageName) {
    for (String entry : entries) {
      String base = entry.endsWith("..") ? entry.substring(0, entry.length() - 2) : entry;
      if (packageName.equals(base) || packageName.startsWith(base + ".")) {
        return true;
      }
    }
    return false;
  }

  /**
   * The package of the platform of the language (the runtime that the check does not examine: a
   * dependency to the platform is given, per the canonical section of model/README.md).
   */
  static boolean isPlatformPackage(String packageName) {
    return packageName.startsWith("java.") || packageName.startsWith("javax.");
  }

  /**
   * The classes of the base package (the import option DoNotIncludeTests excludes the test classes, the
   * same option of the comparison and of the runner).
   */
  static JavaClasses importClasses(String root) {
    return new ClassFileImporter().withImportOption(ImportOption.Predefined.DO_NOT_INCLUDE_TESTS).importPackages(root);
  }
}
