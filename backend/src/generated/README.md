# Generated code, do not change

Do not change a file in this folder by hand. `just generate` makes all files in this folder (and deletes the old ones) from
`contracts/openapi.yaml`, with the generator `spring` of `openapi-generator-maven-plugin`. A change by hand is lost at the next
generation, and the gate for generated code stops a pull request that has it.

To change an interface, change `contracts/openapi.yaml` first, and then run `just generate`. See `contracts/README.md`.

Each Java file has the annotation `@Generated`. The folder `.openapi-generator` has the hash of the OpenAPI file that the
generator read.
