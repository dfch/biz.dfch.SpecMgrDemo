# tools/generate: helper programs for the test of the generators

The generators are not in this folder. The Spring server interfaces are made by the plugin `openapi-generator-maven-plugin`
(`backend/pom.xml`, the execution `spring-interfaces`), the Zod schemas by Kubb (`frontend/kubb.config.mjs` and the runner
`frontend/generate.mjs`), and the API documentation by the second execution of the plugin (`api-docs`). The recipes are
`just generate`, `just compile` and `just api-docs`, and the scripts are in `tools/gates/` (`generate.sh`, `compile.sh` and
`api-docs.sh`). This folder has only the programs that `just test-generate-gate` uses to compare the result with the OpenAPI
file (feat-6-contracts-openapi-pipeline, Task 120.120, ACC-008).

| File | What it does |
|---|---|
| `ErrorCodes.java` | Prints the values of the generated Java enum `ErrorCode` as a JSON array. It uses `getValue()` and not the names of the constants (the generator can add a number to a name if two names are the same, and the value is what goes over the wire). The test starts it with the source launcher of the JDK and the classes of the Maven build: `java -cp backend/target/classes tools/generate/ErrorCodes.java` |
| `error-codes.mjs` | Prints the list `errorCodeSchema.options` and the list of `Problem.code` of the generated Zod schemas as JSON. Node 26 removes the types of a `.ts` file, and a small hook (`registerHooks`) lets it read the imports with no file extension that Kubb writes |
| `error_codes.py` | Compares the list `components.schemas.ErrorCode.enum` of `contracts/openapi.yaml` with the two outputs above: the same values in the same order. Exit code 0: the same. 1: a list is not the same (the message has the values that are missing and the values that are extra). 2: a file cannot be read |

The files are not a manifest for the SBOM gate (no `pom.xml`, no `package.json`), and they do not go to users.
