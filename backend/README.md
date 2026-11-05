# backend

The Java backend. It uses Maven (DEC 870244cf-9bea-46bf-8ff2-fe030325743d).

This folder has the Maven module and no product code. It has the Spring server interfaces that the generator makes from `contracts/openapi.yaml` (feat-6-contracts-openapi-pipeline, Phase 120). The first product code comes with the walking skeleton.

| Path | Content |
|---|---|
| `pom.xml` | The module `biz.dfch.specmgrdemo:backend`. It has the plugin `openapi-generator-maven-plugin` (version in the property `openapi-generator.version`, the same as `OPENAPI_GENERATOR_MAVEN_PLUGIN_VERSION` of `tools/versions.env`) with two executions, and the libraries that the generated code needs to compile (see below) |
| `mvnw` | The Maven Wrapper (version 3.3.4, type `only-script`, no jar). Start Maven with `./mvnw`. CI has no Maven setup action and does not use the Maven of the runner |
| `.mvn/wrapper/maven-wrapper.properties` | The Maven version of `tools/versions.env` and the sha256 of the Maven download. The procedure to change them is in `tools/gates/README.md` (section "Maven Wrapper") |
| `src/generated/` | The generated Java code (the Spring server interfaces and the model classes). It is committed to git, and nobody changes it by hand: the folder has a `README.md` with the mark "generated, do not change", and each Java file has the annotation `@Generated`. The folder `.openapi-generator` has the hash of the OpenAPI file that the generator read |

The folder `target/` is the output of a build and is not in git.

## The two executions of the generator

| Execution | Phase | Generator | Output | Recipe |
|---|---|---|---|---|
| `spring-interfaces` | `generate-sources` | `spring` | `src/generated/java` (a compile source root: the plugin option `addCompileSourceRoot`, so no other plugin) | `just generate` (deletes `src/generated` first and makes the code again), `just compile` |
| `api-docs` | none | `html2` | `../build/api-docs` (not in git) | `just api-docs` (REQ-015) |

The recipes check the sha256 of the jar of the plugin before they start it (`OPENAPI_GENERATOR_MAVEN_PLUGIN_SHA256` of `tools/versions.env`). The dependencies of the plugin are not checked (GitHub issue #23). Because the execution `spring-interfaces` is bound to `generate-sources`, `./mvnw compile` also makes the Java code again (the same bytes).

### The options of the Spring generator

| Option | Value | Why |
|---|---|---|
| `interfaceOnly` | `true` | The plan (task 090.120): only the interfaces and the model, no controller |
| `skipDefaultInterface` | `true` | The plan: no default method in an interface |
| `hideGenerationTimestamp` | `true` | The plan: no time in the files, so two runs are the same (REQ-011) |
| `generateSupportingFiles` (plugin option) | `false` | The plan: no `pom.xml`, no `OpenApiGeneratorApplication` and no other support file |
| `useSpringBoot3` | `true` | The default of 7.27.0, written out: Jakarta EE 10, package `jakarta.*` |
| `annotationLibrary`, `documentationProvider` | `none` | Set by the agent: the generated code has no annotation of swagger, so it needs no `swagger-annotations-jakarta` |
| `openApiNullable` | `false` | Set by the agent: the generated code has no `JsonNullable`, so it needs no `jackson-databind-nullable` |
| `generateJsonIncludeAnnotations`, `generateJsonSetterNullsAnnotations` | `false` | The defaults of 7.27.0, written out, because the generator writes a warning if they are not set |
| `sourceFolder` | `java` | The Java code is in `src/generated/java` and not in `src/generated/src/main/java` |
| `apiPackage`, `modelPackage` | `biz.dfch.specmgrdemo.api`, `biz.dfch.specmgrdemo.model` | Set by the agent |
| `generateApiTests`, `generateModelTests`, `generateApiDocumentation`, `generateModelDocumentation` | `false` | Set by the agent: only the interfaces and the model are code of the module |

## The libraries of the generated code

There is no BOM (no `spring-boot-dependencies` and no starter): the version of each library is in the `pom.xml`. The Spring Boot BOM would manage `tomcat-annotations-api` at an older version, and a Spring Boot starter can bring `jakarta.annotation-api` in again. The owner decided on 2026-11-04 to use `org.apache.tomcat:tomcat-annotations-api` for `jakarta.annotation.Generated`. The tree has 12 components, all Apache-2.0 (`just sbom` and `just license-check`):

| Library | Version | Needed for |
|---|---|---|
| `org.springframework:spring-web` | 6.2.19 | `ResponseEntity` and the annotations of Spring Web MVC (brings `spring-beans`, `spring-core`, `spring-jcl` and `micrometer-observation`) |
| `org.springframework:spring-context` | 6.2.19 | `@Validated` (brings `spring-aop` and `spring-expression`) |
| `jakarta.validation:jakarta.validation-api` | 3.0.2 | Jakarta Bean Validation (the API only, no implementation) |
| `com.fasterxml.jackson.core:jackson-annotations` | 2.21 | `@JsonProperty` and `@JsonValue` of the model classes |
| `org.apache.tomcat:tomcat-annotations-api` | 10.1.61 | `jakarta.annotation.Generated` |

`./mvnw dependency:tree` must not show `jakarta.annotation-api`. The two jars have the same package, so they must not be on the same class path.

## Build

```bash
just generate   # makes the generated code again (and the code of frontend/)
just compile    # ./mvnw compile and the compile of frontend/
just api-docs   # the HTML documentation in build/api-docs
```
