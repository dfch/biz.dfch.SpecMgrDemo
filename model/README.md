# model

The architecture model (Structurizr). The code must obey this model (DEC 9edc1071-4fd0-48b6-a037-1a4cb2331f73):

- In the backend, each top-level package is a Spring Modulith module and is one component of the model.
- The name of a package is the same as the identifier of its component in the model.
- A test reads the workspace and compares the components with the modules and the packages.

The workspace of the model is the file `workspace.json` of this folder (the one canonical file). It is the
machine-generated-shaped file that the writer of the library structurizr-java makes (the JSON form of the model of
structurizr), and it is hand-maintained: the file is read by the two sides of the comparison test (the library
structurizr-java on the side of the backend, a strict reading in the script `frontend/architecture/compare.mjs` on the
side of the frontend), and the test stops for a form of the file that a reader does not understand.

The content of the workspace (the C4 model, the level of the containers, and the components of the DEC):

- The software system `SpecMgrDemo` (the project).
- The two containers: `backend` (the Maven module of the repository) and `frontend` (the pnpm module of the repository).
- The components of `backend`, named like the top-level packages of the module: `api` (the package
  `biz.dfch.specmgrdemo.api`, the generated Spring server interfaces), `model` (the package
  `biz.dfch.specmgrdemo.model`, the generated model classes) and `app` (the package
  `biz.dfch.specmgrdemo.app`, the product code of the service since the walking skeleton, feat-9-walking-skeleton,
  Phase 200).
- The components of `frontend`, named by the rule of thumb of the units (the same for the rules of ArchUniTS and for
  the comparison, see below): `types` (the folder `frontend/src/generated/types`, the generated TypeScript types),
  `zod` (the folder `frontend/src/generated/zod`, the generated Zod schemas), `test` (the folder `frontend/src/test`,
  the tests of the module) and `root` (the files that lie directly in `frontend/src`, today
  `frontend/src/mutation-example.ts`).
- The dependencies: `frontend` -> `backend` (the frontend consumes the API of the backend, the dependency of the
  container level), `api` -> `model` (the real package dependency of the module, the interfaces of `api` reference the
  classes of `model`), `app` -> `api` (the controllers of `app` implement the generated interfaces of `api`) and
  `app` -> `model` (the product code of `app` uses the classes of `model`), `test` -> `zod` (the tests import the
  generated Zod schemas) and `test` -> `root` (the test of the example imports the example file).

The rule of thumb of the units of the frontend (the identifier of a component is the name of its unit): a unit is a
folder that contains TypeScript source - the top-level folders of `frontend/src` (today: `test`), the folders of
`frontend/src/generated` (today: `types` and `zod`; the generator makes two independent artifacts, so the folders of
the generated code are the units and not the folder `generated`), and the files that lie directly in `frontend/src`
form the unit `root`. A change of the code that adds a folder with TypeScript source (a new unit) or a file directly
in `frontend/src/generated` needs a change of the workspace in the same pull request (the comparison test stops for a
unit that is not in the model, and for a file that the rule of thumb has no unit for).

The test that compares the workspace with the code is the recipe `just architecture-model` (Task 130.120 of
feat-7-verification-architecture-tools): the side of the backend is the JUnit class
`biz.dfch.specmgrdemo.architecture.ModelComparisonTest` (it reads the workspace with the library structurizr-java, and
the source of the packages and the dependencies of the code is the analysis of ArchUnit on the compiled classes of the
module), and the side of the frontend is the script `frontend/architecture/compare.mjs` (it reads the workspace
strictly, discovers the units from the files of the code, and reads the imports with the compiler of the pinned
package typescript). The committed run is green (the workspace matches the code), and the recipe shows the two
conditions of ACC-003 in a temporary copy of the repository: a package (or a unit) that has no component in the model,
and a dependency that is not in the model. The comparison gives the same result on the other direction too (a
component of the model without a package, or a dependency of the model without the code, stops the test: the model must
describe the code, and the code must obey the model).

The dependency of the container level `frontend` -> `backend` is in the workspace as the model of the project (the
frontend consumes the API of the backend), and it is not compared by the two sides (the comparison is on the level of
the packages of the module and of the units of the frontend).

## The property `specmgr-req` (traceability)

An element of the workspace has the identifier of its REQ document in the property `specmgr-req` (DEC f21920d2-4da5-4cf7-bd94-2e9bcba77342, `feat-8-traceability-security-gates`). The value is one identifier, or a list of identifiers that the character comma separates:

```json
"properties" : {
  "specmgr-req" : "1ca335d7-969a-443e-9392-165fdeea99a0"
}
```

A property of Structurizr is a text, so the list is one text (`"<uuid>,<uuid>"`; a space after the comma is allowed). Each identifier must be the identifier of a REQ document in `docs/req/`. The recipe `just traceability` reads the property from each software system, container and component of the workspace:

- **Error** (the gate stops): an identifier that is not the identifier of a REQ document, or a value that is not an identifier.
- **Warning** (no stop): an approved REQ (the status `accepted` or `implemented`) that no element has in its `specmgr-req`.

The element of a requirement is the component that makes it. The component `api` has the identifier of the REQ "The System Gives Its Status" (`GET /status`, the generated interface `StatusApi`) and of the REQ "The System Gives Its Version and Its License" (`GET /info`, the generated interface `InfoApi`, the list that the character comma separates, feat-9-walking-skeleton, the task 200.130). Put the property on the component, in the same pull request that adds the REQ with the status `accepted`.

The comparison tests (`just architecture-model`) accept the key `properties` of a software system, a container and a component, and they do not use its values. The side of the backend (structurizr-java) reads the key. The side of the frontend (`frontend/architecture/compare.mjs`) accepts the key, and stops if its value is not a map of texts.
