# backend

The Java backend. The project uses Maven (DEC 870244cf-9bea-46bf-8ff2-fe030325743d).

This folder has the Maven module and no product code. The folder has the Spring server interfaces that the generator makes from `contracts/openapi.yaml` (`feat-6-contracts-openapi-pipeline`). The first product code comes with the walking skeleton.

| Path | Content |
|---|---|
| `pom.xml` | The module `biz.dfch.specmgrdemo:backend`. It has the plug-in `openapi-generator-maven-plugin` (version in the property `openapi-generator.version`, the same as `OPENAPI_GENERATOR_MAVEN_PLUGIN_VERSION` of `tools/versions.env`) with two executions. It has the libraries that the generated code has as necessary for the build (see below) |
| `mvnw` | The Maven Wrapper (version 3.3.4, type `only-script`, no jar). Start Maven with `./mvnw`. CI has no action that installs Maven. CI does not use the Maven of the runner |
| `.mvn/wrapper/maven-wrapper.properties` | The Maven version of `tools/versions.env` and the sha256 of the Maven download. The procedure to change the values is in `tools/gates/README.md` (section "Maven Wrapper") |
| `src/generated/` | The generated Java code (the Spring server interfaces and the model classes). The code is committed to git, and no person changes it by hand. The folder has a `README.md` with the mark `Generated code, do not change`. Each Java file has the annotation `@Generated`. The folder `.openapi-generator` has the hash of the OpenAPI file that the generator read |

The folder `target/` is the output of a build, and it is not in git.

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

## Build

```bash
just generate   # makes the generated code again (and the code of frontend/)
just compile    # ./mvnw compile and the compile of frontend/
just api-docs   # the HTML documentation in build/api-docs
```
