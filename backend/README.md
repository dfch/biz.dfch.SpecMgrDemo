# backend

The Java backend. It uses Maven (DEC 870244cf-9bea-46bf-8ff2-fe030325743d).

This folder has the shell of the Maven module and no product code. The first code comes with the walking skeleton.

| Path | Content |
|---|---|
| `pom.xml` | The module `biz.dfch.specmgrdemo:backend` with no dependency (feat-6-contracts-openapi-pipeline, Phase 105). The phase 120 adds the generated server interfaces |
| `mvnw` | The Maven Wrapper (version 3.3.4, type `only-script`, no jar). Start Maven with `./mvnw`. CI has no Maven setup action and does not use the Maven of the runner |
| `.mvn/wrapper/maven-wrapper.properties` | The Maven version of `tools/versions.env` and the sha256 of the Maven download. The procedure to change them is in `tools/gates/README.md` (section "Maven Wrapper") |

The folder `target/` is the output of a build and is not in git.
