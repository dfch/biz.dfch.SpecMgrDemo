# backend

The Java backend. The project uses Maven (DEC 870244cf-9bea-46bf-8ff2-fe030325743d).

This folder has the Maven module and no product code. The folder has the Spring server interfaces that the generator makes from `contracts/openapi.yaml` (`feat-6-contracts-openapi-pipeline`). The first product code comes with the walking skeleton.

| Path | Content |
|---|---|
| `pom.xml` | The module `biz.dfch.specmgrdemo:backend`. It has the plug-in `openapi-generator-maven-plugin` (version in the property `openapi-generator.version`, the same as `OPENAPI_GENERATOR_MAVEN_PLUGIN_VERSION` of `tools/versions.env`) with two executions. It has the libraries that the generated code has as necessary for the build (see below) |
| `mvnw` | The Maven Wrapper (version 3.3.4, type `only-script`, no jar). Start Maven with `./mvnw`. CI has no action that installs Maven. CI does not use the Maven of the runner |
| `.mvn/wrapper/maven-wrapper.properties` | The Maven version of `tools/versions.env` and the sha256 of the Maven download. The procedure to change the values is in `tools/gates/README.md` (section "Maven Wrapper") |
| `src/generated/` | The generated Java code (the Spring server interfaces and the model classes). The code is committed to git, and no person changes it by hand. The folder has a `README.md` with the mark `Generated code, do not change`. Each Java file has the annotation `@Generated`. The folder `.openapi-generator` has the hash of the OpenAPI file that the generator read |
| `src/test/java/biz/dfch/specmgrdemo/testtools/` | The tests of the example module (feat-7-verification-architecture-tools, Phase 110). They exercise the generated code (the module has no product code): the unit tests of JUnit, the integration tests of Testcontainers (the suffix IT), the property tests of jqwik, and the cases that are not successful (the classes without a suffix; see below) |
| `src/test/java/biz/dfch/specmgrdemo/architecture/` | The architecture tools (feat-7-verification-architecture-tools, Phase 130): `ModuleStructureTest` (R1, the module structure with Spring Modulith: the top-level packages are exactly the modules api and model), `LayerRuleTest` (R2, the layer rule with ArchUnit: the layer model does not depend on the layer api), `BrokenLayerRule` (the case that is not successful: the violated layer rule, no suffix Test), and `ModelComparisonTest` (the test that compares the workspace of `model/` with the packages and the dependencies of the module; the recipe `architecture-model`) |

The folder `target/` is the output of a build, and it is not in git. The file `.jqwik-database` is the failure database of jqwik (a run of a property that is not successful writes it), and it is not in git.

## The two executions of the generator

| Execution | Phase | Generator | Output | Recipe |
|---|---|---|---|---|
| `spring-interfaces` | `generate-sources` | `spring` | `src/generated/java` (a source root for the Java code; the plug-in option `addCompileSourceRoot`; no other plug-in is necessary) | `just generate` (deletes `src/generated` first and makes the code again), `just compile` |
| `api-docs` | none | `html2` | `../build/api-docs` (not in git) | `just api-docs` (REQ-015) |

The recipes compare the sha256 of the jar of the plug-in before they start it (`OPENAPI_GENERATOR_MAVEN_PLUGIN_SHA256` of `tools/versions.env`). The project does not examine the dependencies of the plug-in (GitHub issue #23). The execution `spring-interfaces` is in the phase `generate-sources`. `./mvnw compile` starts the phase and makes the Java code again (the files are the same).

### The options of the Spring generator

| Option | Value | The cause |
|---|---|---|
| `interfaceOnly` | `true` | The plan (task 090.120): only the interfaces and the model, no controller |
| `skipDefaultInterface` | `true` | The plan: no method in the interface that the generator gives without the option |
| `hideGenerationTimestamp` | `true` | The plan: no time in the files. Two starts are the same (REQ-011) |
| `generateSupportingFiles` (plug-in option) | `false` | The plan: no `pom.xml`, no `OpenApiGeneratorApplication` and no other file of the generator |
| `useSpringBoot3` | `true` | 7.27.0 gives this value when the option is not set (written out): Jakarta EE 10, package `jakarta.*` |
| `annotationLibrary`, `documentationProvider` | `none` | Set by the agent: the generated code has no annotation of swagger, and the module has no `swagger-annotations-jakarta` |
| `openApiNullable` | `false` | Set by the agent: the generated code has no `JsonNullable`, and the module has no `jackson-databind-nullable` |
| `generateJsonIncludeAnnotations`, `generateJsonSetterNullsAnnotations` | `false` | 7.27.0 gives these values when the options are not set (written out). The generator writes a warning for an option that is not set |
| `sourceFolder` | `java` | The Java code is in `src/generated/java` and not in `src/generated/src/main/java` |
| `apiPackage`, `modelPackage` | `biz.dfch.specmgrdemo.api`, `biz.dfch.specmgrdemo.model` | Set by the agent |
| `generateApiTests`, `generateModelTests`, `generateApiDocumentation`, `generateModelDocumentation` | `false` | Set by the agent: only the interfaces and the model are code of the module |

## The libraries of the generated code

The module has no BOM. `spring-boot-dependencies` and a Spring Boot starter are not in the `pom.xml`. The version of each library is in the `pom.xml`. The Spring Boot BOM manages `tomcat-annotations-api` at a version that is lower. A Spring Boot starter can add `jakarta.annotation-api` to the module again. The owner selects `org.apache.tomcat:tomcat-annotations-api` for `jakarta.annotation.Generated` (the decision is on 2026-11-04). The tree has 12 components, all Apache-2.0 (`just sbom` and `just license-check`):

| Library | Version | The module has it for |
|---|---|---|
| `org.springframework:spring-web` | 6.2.19 | `ResponseEntity` and the annotations of Spring Web (the `MVC` part; gives `spring-beans`, `spring-core`, `spring-jcl` and `micrometer-observation`) |
| `org.springframework:spring-context` | 6.2.19 | `@Validated` (gives `spring-aop` and `spring-expression`) |
| `jakarta.validation:jakarta.validation-api` | 3.0.2 | Jakarta Bean Validation (the API only, no program that does the check) |
| `com.fasterxml.jackson.core:jackson-annotations` | 2.21 | `@JsonProperty` and `@JsonValue` of the model classes |
| `org.apache.tomcat:tomcat-annotations-api` | 10.1.61 | `jakarta.annotation.Generated` |

`./mvnw dependency:tree` must not show `jakarta.annotation-api`. The two jars have the same package, and they must not be on the same class path.

## The test tools (feat-7-verification-architecture-tools, the phases 110 and 130)

The test tools are in the `pom.xml` in the scope `test` (the property of each one is named there). `tools/versions.env` has the same versions, and `just check-pins` compares them. The license of each tool is in the license table of the plan of the feature: JUnit and jqwik are EPL-2.0 (the class Review), and the deviation of the owner is in the register DEC 93a6d588-e002-4daf-9a47-45e2d77786e9 (accepted 2026-11-09). Testcontainers is MIT, and the JDBC driver is BSD-2-Clause. The scope `test` keeps the tools out of the SBOM (the default `includeTestScope=false` of the cyclonedx plug-in), so the tree of 12 components above is the tree of the module:

| Tool | Version | The module has it for |
|---|---|---|
| `org.junit.jupiter:junit-jupiter` | 5.14.4 | The unit tests. The 5.x line and not the 6.x line: jqwik 1.10.2 needs the JUnit Platform 1.14.x |
| `org.testcontainers:testcontainers`, `org.testcontainers:junit-jupiter`, `org.testcontainers:postgresql` | 1.21.4 | The integration tests (one container). The 1.21.x line: the `junit-jupiter` module has no 2.x release, and the core and the modules are the same line |
| `org.postgresql:postgresql` | 42.7.14 | The JDBC driver of the container (test scope only) |
| `net.jqwik:jqwik` | 1.10.2 | The property tests (the JUnit Platform engine next to the JUnit engine) |
| `org.apache.maven.plugins:maven-surefire-plugin` | 3.6.1 | The test runner of the Maven build (runs the engines of the JUnit Platform) |
| `org.springframework.modulith:spring-modulith-core` | 1.4.14 | The module structure (R1, the recipe `architecture-backend`). The 1.4.x line and not the 2.x line: the core of the 2.x line has the dependencies spring-core and spring-context 7.0.9, and the module has the Spring Framework 6.2.19 line (the plan records the decision) |
| `org.springframework.boot:spring-boot` | 3.5.16 | A dependency of the code of Spring Modulith 1.4.14 that the POM of the artifact does not declare (the module detection calls the class ConfigDataEnvironmentPostProcessor of this jar in each start). The 3.5.x line of the Spring Framework 6.2.x line; its dependencies are spring-core and spring-context 6.2.19, the versions of the module. The module has no class of Spring Boot, and no context starts |
| `com.tngtech.archunit:archunit`, `com.tngtech.archunit:archunit-junit5` | 1.5.1 | The layer rule (R2, the recipe `architecture-backend`), and the source of the package dependencies of the comparison with the model (the recipe `architecture-model`) |
| `com.structurizr:structurizr-client` | 6.2.4 | The reader of the workspace of `model/` (the JSON reader and the model classes; the recipe `architecture-model`). The artifact with the reader of the 6.x line (the POM `com.structurizr:structurizr` has no jar) |

The recipes of the tests are in `tools/gates/` (the scripts `test-*-backend.sh`, the recipes of the `justfile`):

```bash
just test-unit-backend         # the unit tests with JUnit, and a test that is not successful
just test-integration-backend  # the integration tests with Testcontainers (one container), and a test that is not successful
just test-random-backend       # the property tests with jqwik, one that succeeds and one that is not successful
just architecture-backend      # the architecture tests with Spring Modulith and ArchUnit (R1, R2), and a rule that is not successful (Phase 130)
just architecture-model        # the test that compares the workspace of model/ with the packages and the dependencies of the module (Phase 130)
```

**The cases that are not successful (ACC-002).** A class whose name has no suffix `Test` (or `IT` for the integration tests) is a case that is not successful: the default run of surefire does not start it, and the committed run of the tests is green. `BrokenAssertion` (a wrong assertion of JUnit), `BrokenPostgres` (a wrong assertion against the real container), `BrokenProperty` (a property that jqwik falsifies with a counterexample) and `BrokenLayerRule` (a layer rule that the code violates, the opposite direction of R2; the recipe `architecture-backend` runs it and ArchUnit names the violating dependency) are such classes. Each recipe runs its class separately and stops for it (the tool reports the failure), so the recipe shows the case that is not successful and exits 0.

## Build

```bash
just generate   # makes the generated code again (and the code of frontend/)
just compile    # ./mvnw compile and the compile of frontend/
just api-docs   # the HTML documentation in build/api-docs
```
