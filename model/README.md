# model

The architecture model (Structurizr). The code must obey this model:

- The file `workspace.dsl` of this folder is the one file that a person edits (DEC b6e8808f-86b4-41a4-92f2-33d38869beed).
- The file `workspace.json` is generated from the DSL by the pinned container (the recipe `just generate-model`; the image digest is in `tools/versions.env`), and it is committed to git. Do not change the JSON by hand: the gate `just check-model-generated` stops for a JSON that is not the JSON that the DSL makes now.
- The form of the value of each property of the model (the mapping `code.*`, the exceptions of the closed world, the direction of a relation, the viewpoint `rw.viewpoint`, the perspectives, the references `specmgr-refs`) is in DEC e85e9685-0787-4dff-9ee5-9d46670e9ee4 (the Model Conventions). That decision partly supersedes DEC 9edc1071-4fd0-48b6-a037-1a4cb2331f73: the rule "the name of a package is the same as the identifier of its component in the model" is replaced by the mapping `code.*`.

The content of the workspace (the C4 model, the level of the containers, and the components):

- The software system `SpecMgrDemo` (the project).
- The two containers: `backend` (the Maven module of the repository) and `frontend` (the pnpm module of the repository).
- The components of `backend`: `api` (the generated Spring server interfaces) and `model` (the generated model classes).
- The components of `frontend`: `types` (the generated TypeScript types), `zod` (the generated Zod schemas), `test` (the tests of the module) and `root` (the files that lie directly in `frontend/src`, today `frontend/src/mutation-example.ts`).
- The relations (the direction of a relation is the direction of the code dependency): `frontend` -> `backend`, `api` -> `model`, `test` -> `zod`, and `test` -> `root`.

The seven views (one per viewpoint of Rozanski & Woods; each view has the property `rw.viewpoint`, DEC e85e9685-0787-4dff-9ee5-9d46670e9ee4): Context (the view type `systemContext`), Functional (the view type `container`), Development (the view type `component`, the container `frontend`), Information (the view type `component`, the container `frontend`, the components that own the data of the contract), Concurrency (the view type `dynamic`), Deployment (the view type `deployment`, the single deployment unit of the model) and Operational (the view type `container`). Context, Functional, Development and Information have the rules. Concurrency, Deployment and Operational are documentation only.

The mapping of an element to the code is the property `code.*` of the element (the language, and the package or the path, per the form of DEC e85e9685-0787-4dff-9ee5-9d46670e9ee4): only the elements that have the mapping are compared with the code. The exceptions of the closed world are the properties `code.allowedExternal` (the dependency to code that is outside the mapped elements, and that is allowed) and `code.ignore` (the code that the check does not examine): the exception lives in the model, and not in the test code.

The test that compares the workspace with the code is the recipe `just architecture-model`: the side of the backend is the JUnit class `biz.dfch.specmgrdemo.architecture.ModelComparisonTest` (the library structurizr-java reads the JSON, and the source of the packages and the dependencies of the code is the analysis of ArchUnit on the compiled classes of the module), and the side of the frontend is the script `frontend/architecture/compare.mjs` (it reads the workspace strictly, discovers the units from the files of the code, and reads the imports with the compiler of the pinned package typescript). The comparison is closed world: a package (or a unit) without a component, and a dependency without a relation, stops the run. The other direction is closed too: a component without a package (or a unit), and a relation without the dependency of the code, stops the run. The relation of the container level (`frontend` -> `backend`) is not compared with the code, and the limits of the closed world are in DEC e85e9685-0787-4dff-9ee5-9d46670e9ee4.

## The property `specmgr-req` (traceability)

An element of the workspace has the identifier of its REQ document in the property `specmgr-req` (DEC f21920d2-4da5-4cf7-bd94-2e9bcba77342, `feat-8-traceability-security-gates`). The value is one identifier, or a list of identifiers that the character comma separates:

```json
"properties" : {
  "specmgr-req" : "1ca335d7-969a-443e-9392-165fdeea99a0"
}
```

Each identifier must be the identifier of a REQ document in `docs/req/`. The recipe `just traceability` reads the property from each software system, container and component of the workspace:

- **Error** (the gate stops): an identifier that is not the identifier of a REQ document, or a value that is not an identifier.
- **Warning** (no stop): an approved REQ (the status `accepted` or `implemented`) that no element has in its `specmgr-req`.

The element of a requirement is the component that makes it. The component `api` has the identifier of the REQ "The System Gives Its Status" (`GET /status`, the generated interface `StatusApi`). Put the property on the component, in the same pull request that adds the REQ with the status `accepted`.

The property `specmgr-refs` (the form `TYPE UUID; TYPE UUID`, DEC e85e9685-0787-4dff-9ee5-9d46670e9ee4) replaces `specmgr-req` in Phase 150 of feat-50-structurizr-model-rules. The old form keeps working for one release.
