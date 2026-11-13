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
  `biz.dfch.specmgrdemo.api`, the generated Spring server interfaces) and `model` (the package
  `biz.dfch.specmgrdemo.model`, the generated model classes).
- The components of `frontend`, named by the rule of thumb of the units (the same for the rules of ArchUniTS and for
  the comparison, see below): `types` (the folder `frontend/src/generated/types`, the generated TypeScript types),
  `zod` (the folder `frontend/src/generated/zod`, the generated Zod schemas), `test` (the folder `frontend/src/test`,
  the tests of the module) and `root` (the files that lie directly in `frontend/src`, today
  `frontend/src/mutation-example.ts`).
- The dependencies: `frontend` -> `backend` (the frontend consumes the API of the backend, the dependency of the
  container level), `api` -> `model` (the real package dependency of the module, the interfaces of `api` reference the
  classes of `model`), `test` -> `zod` (the tests import the generated Zod schemas) and `test` -> `root` (the test of
  the example imports the example file).

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
