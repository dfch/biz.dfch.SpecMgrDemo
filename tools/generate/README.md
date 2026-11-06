# `tools/generate`: helper programs for the test of the generators

The generators are not in this folder. The plug-in `openapi-generator-maven-plugin` makes the Spring
server interfaces (`backend/pom.xml`, the execution `spring-interfaces`). Kubb makes the Zod schemas
(`frontend/kubb.config.mjs`, the runner `frontend/generate.mjs`). The second execution of the plug-in
makes the API documentation (`api-docs`). The recipes are `just generate`, `just compile` and
`just api-docs`. The scripts are in `tools/gates/` (`generate.sh`, `compile.sh` and `api-docs.sh`).
This folder has only the programs that `just test-generate-gate` uses to compare the result with the
OpenAPI file (`feat-6-contracts-openapi-pipeline`, Task 120.120, ACC-008).

| File | Its task |
|---|---|
| `ErrorCodes.java` | Prints the values of the generated Java enum `ErrorCode` as a JSON list. It uses `getValue()` and not the names of the constants. The generator can add a number to a name if two names are the same. The value is the value that goes on the wire. Java starts the file directly, with the classes of the Maven build: `java -cp backend/target/classes tools/generate/ErrorCodes.java` |
| `error-codes.mjs` | Prints the list `errorCodeSchema.options` and the list of `Problem.code` of the generated Zod schemas as JSON. Node 26 removes the types of a `.ts` file. A small program for the start (`registerHooks`) lets Node read the imports with no file extension that Kubb writes |
| `error_codes.py` | Compares the list `components.schemas.ErrorCode.enum` of `contracts/openapi.yaml` with the two outputs above: the same values in the same sequence. Exit code 0: the values are the same. 1: a list is not the same (the message has the values that are missing and the values that are not in the other list). 2: a file cannot be read |
| `openapi-generator-maven-plugin.sha256` | The second file of the pin of the jar of the generator plug-in (`feat-6-contracts-openapi-pipeline`, ACC-011). One line with the sha256 of `openapi-generator-maven-plugin-<OPENAPI_GENERATOR_MAVEN_PLUGIN_VERSION>.jar` on Maven Central. The value is `OPENAPI_GENERATOR_MAVEN_PLUGIN_SHA256` in `tools/versions.env`. The value agrees with the `.sha1` file of Maven Central and with a new value of the sha256 that the agent gets again. `just check-pins` compares the file with `tools/versions.env`. `verify_generator_plugin` in `tools/gates/_lib.sh` compares the jar in the local Maven repository with the file |

The files are not a manifest for the SBOM gate (no `pom.xml`, no `package.json`), and they do not go to users.
