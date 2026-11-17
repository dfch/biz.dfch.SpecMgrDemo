# backend

The Java backend. The project uses Maven (DEC 870244cf-9bea-46bf-8ff2-fe030325743d).

This folder has the Maven module. It has the Spring server interfaces that the generator makes from `contracts/openapi.yaml` (`feat-6-contracts-openapi-pipeline`), and the product code of the walking skeleton (`feat-9-walking-skeleton`): the package `biz.dfch.specmgrdemo.app` has the main class `SpecMgrDemoApplication`, the controllers of the two operations `GET /status` and `GET /info`, the check of the state, the handler of the error (`ProblemAdvice`, the response `application/problem+json` with machine values only), the reader of the value of the build (`BuildInfoProvider`) and the OpenTelemetry filter and configuration (`TraceFilter`, `OpenTelemetryConfiguration`). The runtime is Spring Boot 4.0.9 with Spring Framework 7.0.10.

| Path | Content |
|---|---|
| `pom.xml` | The module `biz.dfch.specmgrdemo:backend`. It has the plug-in `openapi-generator-maven-plugin` (version in the property `openapi-generator.version`, the same as `OPENAPI_GENERATOR_MAVEN_PLUGIN_VERSION` of `tools/versions.env`) with two executions. It has the libraries that the generated code has as necessary for the build (see below) |
| `mvnw` | The Maven Wrapper (version 3.3.4, type `only-script`, no jar). Start Maven with `./mvnw`. CI has no action that installs Maven. CI does not use the Maven of the runner |
| `.mvn/wrapper/maven-wrapper.properties` | The Maven version of `tools/versions.env` and the sha256 of the Maven download. The procedure to change the values is in `tools/gates/README.md` (section "Maven Wrapper") |
| `src/generated/` | The generated Java code (the Spring server interfaces and the model classes). The code is committed to git, and no person changes it by hand. The folder has a `README.md` with the mark `Generated code, do not change`. Each Java file has the annotation `@Generated`. The folder `.openapi-generator` has the hash of the OpenAPI file that the generator read |
| `src/test/java/biz/dfch/specmgrdemo/testtools/` | The tests of the example module (feat-7-verification-architecture-tools, Phase 110). They exercise the generated code (the model): the unit tests of JUnit, the integration tests of Testcontainers (the suffix IT), the property tests of jqwik, and the cases that are not successful (the classes without a suffix; see below) |
| `src/main/java/biz/dfch/specmgrdemo/app/` | The product code of the walking skeleton (the package `app`, the module `app` of `model/workspace.json`) |
| `src/test/java/biz/dfch/specmgrdemo/app/` | The tests of the package `app`: the unit tests (`StatusApiTest`, `InfoApiTest`, `TraceFilterTest`, `OpenTelemetryConfigurationTest`, `BuildInfoProviderTest`, `StatusConfigurationTest`) and the integration tests that start the service with `RunningService` (`ServiceIT`, `StatusErrorIT`). The service does not start with the commit `unknown`: the recipes of the `justfile` give the property `build.info.commit` (`git rev-parse HEAD`, with the suffix `-dirty` for a work tree with a change that is not committed), and a run in an IDE needs `-Dbuild.info.commit=$(git rev-parse HEAD)` |
| `src/test/java/biz/dfch/specmgrdemo/architecture/` | The architecture tools (feat-7-verification-architecture-tools, Phase 130): `ModuleStructureTest` (R1, the module structure with Spring Modulith: the top-level packages are exactly the modules api, model and app), `LayerRuleTest` (R2, the layer rule with ArchUnit: the layer model does not depend on the layer api), `BrokenLayerRule` (the case that is not successful: the violated layer rule, no suffix Test), and `ModelComparisonTest` (the test that compares the workspace of `model/` with the packages and the dependencies of the module; the recipe `architecture-model`) |

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
| `useSpringBoot4` | `true` | The runtime is Spring Boot 4.0.9 with Spring Framework 7.0.10 (the rework of feat-9-walking-skeleton, 2026-11-17; the option was `useSpringBoot3` before). Jakarta EE 11, package `jakarta.*`. The generated files are the same as with `useSpringBoot3` (the interfaces and the model) |
| `annotationLibrary`, `documentationProvider` | `none` | Set by the agent: the generated code has no annotation of swagger, and the module has no `swagger-annotations-jakarta` |
| `openApiNullable` | `false` | Set by the agent: the generated code has no `JsonNullable`, and the module has no `jackson-databind-nullable` |
| `generateJsonIncludeAnnotations`, `generateJsonSetterNullsAnnotations` | `false` | 7.27.0 gives these values when the options are not set (written out). The generator writes a warning for an option that is not set |
| `sourceFolder` | `java` | The Java code is in `src/generated/java` and not in `src/generated/src/main/java` |
| `apiPackage`, `modelPackage` | `biz.dfch.specmgrdemo.api`, `biz.dfch.specmgrdemo.model` | Set by the agent |
| `generateApiTests`, `generateModelTests`, `generateApiDocumentation`, `generateModelDocumentation` | `false` | Set by the agent: only the interfaces and the model are code of the module |

## The libraries of the generated code

The module has no BOM: `spring-boot-dependencies` is not imported in the `pom.xml`, and the version of each library is named there (the starters `spring-boot-starter-web` and `spring-boot-starter-log4j2` too, each with the exclusion of `jakarta.annotation-api` and of `spring-boot-starter-logging`). The Spring Boot BOM manages `tomcat-annotations-api` at a version that is lower. A Spring Boot starter can add `jakarta.annotation-api` to the module again, so the starters exclude it. The owner selects `org.apache.tomcat:tomcat-annotations-api` for `jakarta.annotation.Generated` (the decision is on 2026-11-04). The generated code needs the five libraries of the table, and the tree of the SBOM of the module (the scope compile and runtime, with the web service, the logging and OpenTelemetry of the walking skeleton, see the header of the `pom.xml`) has 55 components, all permitted (`just sbom` and `just license-check`):

| Library | Version | The module has it for |
|---|---|---|
| `org.springframework:spring-web` | 7.0.10 | `ResponseEntity` and the annotations of Spring Web (the `MVC` part; gives `spring-beans`, `spring-core`, `commons-logging` and `micrometer-observation`) |
| `org.springframework:spring-context` | 7.0.10 | `@Validated` (gives `spring-aop` and `spring-expression`) |
| `jakarta.validation:jakarta.validation-api` | 3.1.1 | Jakarta Bean Validation (the API only, no program that does the check) |
| `com.fasterxml.jackson.core:jackson-annotations` | 2.21 | `@JsonProperty` and `@JsonValue` of the model classes |
| `org.apache.tomcat:tomcat-annotations-api` | 11.0.29 | `jakarta.annotation.Generated` (Jakarta Annotations 3.0; the scope `provided`) |

`./mvnw dependency:tree` must not show `jakarta.annotation-api`. The two jars have the same package, and they must not be on the same class path.

## The test tools (feat-7-verification-architecture-tools, the phases 110 and 130)

The test tools are in the `pom.xml` in the scope `test` (the property of each one is named there). `tools/versions.env` has the same versions, and `just check-pins` compares them. The license of each tool is in the license table of the plan of the feature: JUnit and jqwik are EPL-2.0 (the class Review), and the deviation of the owner is in the register DEC 93a6d588-e002-4daf-9a47-45e2d77786e9 (accepted 2026-11-09). Testcontainers is MIT, and the JDBC driver is BSD-2-Clause. The scope `test` keeps the tools out of the SBOM (the default `includeTestScope=false` of the cyclonedx plug-in), so the tree of the SBOM (55 components) is the tree of the module:

| Tool | Version | The module has it for |
|---|---|---|
| `org.junit.jupiter:junit-jupiter` | 5.14.4 | The unit tests. The 5.x line and not the 6.x line: jqwik 1.10.2 needs the JUnit Platform 1.14.x |
| `org.testcontainers:testcontainers`, `org.testcontainers:junit-jupiter`, `org.testcontainers:postgresql` | 1.21.4 | The integration tests (one container). The 1.21.x line: the `junit-jupiter` module has no 2.x release, and the core and the modules are the same line |
| `org.postgresql:postgresql` | 42.7.14 | The JDBC driver of the container (test scope only) |
| `net.jqwik:jqwik` | 1.10.2 | The property tests (the JUnit Platform engine next to the JUnit engine) |
| `org.apache.maven.plugins:maven-surefire-plugin` | 3.6.1 | The test runner of the Maven build (runs the engines of the JUnit Platform) |
| `org.springframework.modulith:spring-modulith-core` | 2.0.9 | The module structure (R1, the recipe `architecture-backend`). The 2.0.x line is the line of Spring Boot 4.0.x (the core has the dependencies spring-core and spring-context 7.0.9, and the module has the Spring Framework 7.0.10; the plan records the decision) |
| `org.springframework.boot:spring-boot` | 4.0.9 | The jar is in the scope compile through the starter `spring-boot-starter-web` (the version of the property `spring-boot.version`, the same as `SPRING_BOOT_VERSION` of `tools/versions.env`); the `pom.xml` has no declaration of the jar |
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

## The identifier of the VCR in the name of a test

A test that verifies a requirement has the identifier of its VCR document in its display name: the text `vcr:<uuid>` (DEC f21920d2-4da5-4cf7-bd94-2e9bcba77342, `feat-8-traceability-security-gates`).

```java
@Test
@DisplayName("the status has a state vcr:00000000-0000-4000-8000-000000000000")
void theStatusHasAState() { ... }
```

The recipe `just traceability` reads the files `.java` and `.kt` in `backend/src/test/`. A `vcr:<uuid>` inside a string literal counts (also an upper case identifier), and a `vcr:<uuid>` in a comment of any form (a line comment, a trailing comment after code, a block comment over many lines) is not read. A test file outside the folders that the check reads is an error (`TEST_ROOTS`, see `tools/gates/README.md`). The check stops (error) for a `vcr:<uuid>` that is not the identifier of a VCR document. It gives a warning (no stop) if the VCR of an approved REQ is in no test name. The check does not read the report of the test run. Since `feat-9-walking-skeleton` (Phase 400) the tests `ServiceIT` and `StatusErrorIT` have the display names `vcr:4f98618c-4291-4d60-995f-1fd8a60b9bfd the operation gives the state of the system`, `vcr:4f98618c-4291-4d60-995f-1fd8a60b9bfd the operation gives the error response` and `vcr:eb8a7f16-880d-42b7-9852-37c96175d344 the operation gives the identification and the license` (the name of each is the one that its verification case record states). The class `ServiceForE2e` is no test: it starts the service for the end-to-end test of the frontend (`./mvnw test -Dtest=ServiceForE2e`, started by `frontend/e2e/service.mjs`), and no normal run selects it. The rules are in `tools/gates/README.md` (the section "The traceability check (Gate 2)").

## Build

```bash
just generate   # makes the generated code again (and the code of frontend/)
just compile    # ./mvnw compile and the compile of frontend/
just api-docs   # the HTML documentation in build/api-docs
```
