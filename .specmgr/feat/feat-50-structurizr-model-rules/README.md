---
classification: null
created: '2026-11-16T22:46:31.684+01:00'
id: feat-50-structurizr-model-rules
status: planning
type: feat
updated: '2026-11-18T07:37:33.965+01:00'
version: 1.0.0
---

# Feature: Rules From the Structurizr Model with R&W Viewpoints

## Plan

### Overview

The C4/Structurizr workspace in `model/` becomes the source of truth for the structure, with views that follow the Rozanski & Woods viewpoints. The code must obey the model. A generic test runner reads the model and derives the architecture rules of ArchUnit (the backend) and ArchUniTS (the frontend). The comparison of the model with the code stays closed world: a package or unit without a component, and a dependency without a relation, stops the build.

Today the model (`model/workspace.json`, 9 elements, 4 relations) has no views, no code mapping beyond "package name equals component name", and no runner: the rules R1 to R3 and R1' to R3' are hard-coded (feat-7-verification-architecture-tools), and only `ModelComparisonTest` and `compare.mjs` read the model. This feature adds the views, the code mapping, and the one runner, and removes the hard-coded rules. The closed-world check itself already exists and is not duplicated. The design, the decisions and the phase structure are in the session transcript on the feat-50 branch.

### Requirements

- REQ-001: The model holds the views of the Rozanski & Woods viewpoints. Each view has the property `rw.viewpoint`, and the perspectives are in the native `perspectives` block, per the model conventions DEC.

- REQ-002: Each element that maps to code has the `code.*` properties (the language, the package or the path). The mapping does not depend on the name.

- REQ-003: The DSL is the source of the model. The pinned tool generates the JSON from the DSL. A gate stops for a JSON that is not up to date.

- REQ-004: The test runner reads the JSON of the model and derives the rules of ArchUnit (the backend) and ArchUniTS (the frontend) at test time. The hand-written rules R1 to R3 and R1' to R3' are removed.

- REQ-005: The comparison of the model with the code is closed world. A package or unit without a component, and a dependency without a relation, stops the build. The exceptions are explicit in the model (the properties `code.allowedExternal` and `code.ignore`), and the direction of a model arrow is the direction of the code dependency.

- REQ-006: The model holds the references to the specmgr artifacts in the property `specmgr-refs` (the form `TYPE UUID; TYPE UUID`). The traceability gate reads the new form and keeps the old form `specmgr-req` working for one release.

- REQ-007: Each rule category has a case that is not successful (the `Broken*` pattern) in the backend and in the frontend, so the tests of the tests prove that a violation stops the build.

- REQ-008: The new checks run as `just` recipes and CI jobs. `just check-workflows` passes (CI runs only `just` recipes), and the versions are pinned in `tools/versions.env`.

### Acceptance Criteria

- [x] ACC-001: The workspace has the views Context, Functional, Development and Information (with rules), and Concurrency, Deployment and Operational (documentation only). Each view has `rw.viewpoint`.

- [x] ACC-002: The comparison run is green on the committed code: each package and unit has a component, each dependency has a relation, and each modelled code element exists in the code.

- [x] ACC-003: In a temporary copy of the repository, a package without a component and a dependency without a relation each stop the build, and the report names the violation.

- [x] ACC-004: Two runs of the JSON generation make no change, and the gate stops for a JSON that differs from the DSL (like `check-generated`).

- [x] ACC-005: The runner derives the rules from the JSON. The hard-coded rules R1 to R3 and R1' to R3' are removed, and the same rules run from the model.

- [ ] ACC-006: Each rule category has one case that is not successful in the backend and one in the frontend. The recipes run the broken case separately, stop for it, and name the violation.

- [ ] ACC-007: The traceability gate stops for a `specmgr-refs` entry that has no document, passes for the fixtures of each type, and keeps the old `specmgr-req` working.

- [ ] ACC-008: The new recipes run in CI as jobs, `just check-workflows` passes, and the pins of `tools/versions.env` cover the new tools.

### Scope

#### Included

- The R&W views and the model conventions (`rw.viewpoint`, `perspectives`, `code.*`, `specmgr-refs`, the closed-world exceptions, the arrow direction).

- The DSL as the source of the model, the generated JSON, and the gate for it.

- The generic rule runner (the Java adapter for ArchUnit, the Node adapter for ArchUniTS) and the refactor of `ModelComparisonTest` and `compare.mjs` onto it.

- The removal of the hard-coded rules R1 to R3 and R1' to R3'.

- The tests of the tests (the failing fixtures of each rule category, both languages).

- The extension of the traceability gate to `specmgr-refs` (the update of DEC f21920d2-4da5-4cf7-bd94-2e9bcba77342).

- The `just` recipes, the CI jobs, the pins, and the CODEOWNERS entry for `model/`.

- The two new DECs (the DSL as the source; the model conventions, partly superseding DEC 9edc1071-4fd0-48b6-a037-1a4cb2331f73) and the update of RSK 025202ba-e4a7-4f6b-a65b-92f945b6f321.

#### Explicitly Out Of Scope

- The product components that the rules examine: they come from feat-9-walking-skeleton (the dependency).

- The generation of the model from the specmgr artifacts (the future work, probably a skill or a tool in another repository, for example the specmgr MCP).

- The checks of the Deployment and Operational views (they need infrastructure-as-code checks, not ArchUnit).

- The perspectives as tests (security, performance, availability): they stay documentation only.

### Dependencies

#### Depends On

- feat-9-walking-skeleton: the product components (the status service, the adapter, the persistence) that the rules examine. The branch `feat-9` exists with the phase 100 documents; its code phases are not done at the writing of this plan.

#### Blocks

- The generation of the model from the specmgr artifacts (the future skill or tool that reads the conventions of this feature).

### Design Notes

- The mapping of the viewpoints: Context (no check, or only weakly: which code may reach an external system), Functional (yes: the allowed dependencies, no unmapped code), Development (yes: the layers, the cycles, the naming, the annotations at the C4 level), Information (partly: the data ownership as a dependency rule), Concurrency (the annotation rules only), Deployment and Operational (no check).

- The runner design: the model is a language-neutral rule set. A thin Java adapter builds the ArchUnit rules at test time (for example the JUnit `@TestFactory`). A thin Node adapter builds the ArchUniTS rules. The limit is the parity: ArchUniTS cannot check a closed set of units (the result of feat-7), so the closed-set checks stay in the analyzers of `compare.mjs` and `ModelComparisonTest`.

- The JSON stays the interchange, and the DSL is the only thing a person edits: the Node cannot parse the DSL (only the Java library `structurizr-dsl` parses it), one parse gives one result (the `!include`, `!identifiers` and the constants), the readers already exist (the `JsonReader` in the backend, the strict reader in `compare.mjs`), and a reviewer sees the resolved model in the diff. The Structurizr MCP cannot make the JSON (its tools are parse, validate, inspect, and the export to PlantUML and Mermaid). The container `structurizr/structurizr` (2026.10.26-noble, present locally) probably has the `export` command with the JSON format: this is unverified and is checked in Phase 100, and the image digest is pinned.

- The limits of the closed world: only the elements that have a `code.*` mapping are checked (the container relations such as `frontend -> backend` are not visible in the code), the exceptions are explicit in the model (a silent exception list in the test code would break the one-source-of-truth goal), and the direction of a model arrow is the direction of the code dependency (for example: if the persistence implements the interface of the domain, the arrow points from the persistence to the domain).

- The spike records the limits: the component with several folders, the type-only imports, the dynamic imports.

- The risks: the conversion drift (the comparison run before and after the hand conversion of the JSON to the DSL), the strict reader (`compare.mjs` stops for a JSON key that it does not know: the views, the perspectives and the view properties must be allowed), the language skew (ArchUnit works on the bytecode, ArchUniTS on the source: the rule sets do not behave the same, and each known difference is recorded in the model conventions DEC), the rule churn (the strict closed world blocks the work: the exceptions stay in the model).

### Related Decisions

- DEC 9edc1071-4fd0-48b6-a037-1a4cb2331f73 (Make Sure That the Code Obeys the Structurizr Model): partly superseded by the model conventions DEC of this feature.

- DEC f21920d2-4da5-4cf7-bd94-2e9bcba77342 (Use Specmgr Identifiers for Traceability): updated by Phase 150 for the `specmgr-refs` form.

- DEC 84c37f7d-08cb-457d-8ab3-1db37dba9bc9 (the license clause): the DSL-to-JSON tool must be AGPL-compatible.

- RSK 025202ba-e4a7-4f6b-a65b-92f945b6f321 (ArchUniTS Cannot Do Each Necessary Rule): updated by the spike of Phase 100.

- GOL 9ffb930c-44e8-4d0e-b4fd-f94c7162a894 (Keep One Source of Truth for Each Fact).

- DEC d778d444-6227-4070-ae6e-b1083c78c58b (the git workflow): the documents of this feature reach dev through a branch and a pull request, not a local commit.

### Task List

#### Phase 100: Decisions and Spike

- [x] Task 100.100: Write the DEC "The DSL Is the Source and the JSON Is Generated" (the tool, the pin, the gate).

- [x] Task 100.110: Write the DEC "The Model Conventions" (`code.*`, `specmgr-refs`, `rw.viewpoint`, the perspectives, the closed-world exceptions, the arrow direction). It partly supersedes DEC 9edc1071-4fd0-48b6-a037-1a4cb2331f73.

- [x] Task 100.120: Check the JSON export of the container `structurizr/structurizr` (and the MCP), and pin the image digest. Record the result in the FEAT.

- [x] Task 100.130: Spike: build the rules from the JSON in ArchUnit and in ArchUniTS. Record the limits (the component with several folders, the type-only imports, the dynamic imports).

- [x] Task 100.140: Update RSK 025202ba-e4a7-4f6b-a65b-92f945b6f321 with the result of the spike.

#### Phase 110: The Model in DSL

- [x] Task 110.100: Convert `workspace.json` to `workspace.dsl` by hand (the 9 elements, the 4 relations). Run the comparison before and after (the conversion drift check).

- [x] Task 110.110: Add the pinned step from the DSL to the JSON (the library or the container of Task 100.120).

- [x] Task 110.120: Add the gate "the JSON is generated and up to date" (like `check-generated`), and the test with the fixtures.

- [x] Task 110.130: Write the views (Context, Functional, Development, Information; Concurrency, Deployment, Operational documentation only), with `rw.viewpoint` and the perspectives. Set `!impliedRelationships` explicitly, so the implied-relationship strategy adds no relation.

- [x] Task 110.140: Add the `code.*` mapping and the closed-world exceptions to the elements, and keep the comparison green.

#### Phase 120: The Model of the Walking Skeleton

- [x] Task 120.100: Read the plan of feat-9-walking-skeleton, and fit the model conventions to its components (the status service, the adapter, the persistence).

- [ ] Task 120.110: Add the components and the relations of feat-9 to the model (including one data-ownership case), and keep the comparison green. This feature adds no product code.

#### Phase 130: The Rule Set and the Runner

- [x] Task 130.100: Define the rule set that the model gives (the JSON form of the rules, the language-neutral part).

- [x] Task 130.110: Write the Java adapter: build the ArchUnit rules from the model at test time (for example the `@TestFactory`).

- [x] Task 130.120: Write the Node adapter: build the ArchUniTS rules from the model.

- [x] Task 130.130: Refactor `ModelComparisonTest` and `compare.mjs` onto the same rule set (allow the new JSON keys: the views, the perspectives, the view properties).

- [x] Task 130.140: Remove the hard-coded rules R1 to R3 (the backend) and R1' to R3' (the frontend).

#### Phase 140: The Tests of the Tests

- [ ] Task 140.100: Add one case that is not successful for each rule category in the backend (the `Broken*` pattern).

- [ ] Task 140.110: Add one case that is not successful for each rule category in the frontend (the `Broken*` pattern).

- [ ] Task 140.120: Demonstrate the two conditions of the closed world in a temporary copy (the package without a component, the dependency without a relation), and record the names of the violations.

#### Phase 150: The References

- [ ] Task 150.100: Extend `tools/gates/traceability.py` to read `specmgr-refs` (the form `TYPE UUID; TYPE UUID`) and check each type. Add the fixtures of the gate test for the new form.

- [ ] Task 150.110: Keep `specmgr-req` working for one release (the compatibility).

- [ ] Task 150.120: Update DEC f21920d2-4da5-4cf7-bd94-2e9bcba77342 for the `specmgr-refs` form.

#### Phase 160: The Wiring and the Close

- [ ] Task 160.100: Add the `just` recipes for the new checks, and the CI jobs. `just check-workflows` passes.

- [ ] Task 160.110: Add the pins to `tools/versions.env`. The SBOM and the license gates pass (the new tools are in the permitted licenses).

- [ ] Task 160.120: Add the entry for `model/` in CODEOWNERS.

- [ ] Task 160.130: Close the feature per the SOP (the status, the updates, the references).

## Progress

### Current Status

**As of 2026-11-18**: Phases 100 to 130 are done. The model is in `model/workspace.dsl` (the one file that a person edits, DEC b6e8808f-86b4-41a4-92f2-33d38869beed), and `model/workspace.json` is generated from it by the pinned container (the recipe `just generate-model`; the step names the digest of `tools/versions.env`, and not the tag; two runs make no change). The gate `just check-model-generated` stops for a JSON that is not up to date with the DSL, and for a DSL that does not parse (the line named). The model has the seven views (each with the property `rw.viewpoint`), the mapping `code.*`, and the closed-world exceptions `code.allowedExternal` (DEC e85e9685-0787-4dff-9ee5-9d46670e9ee4). Phase 120 (the model of the walking skeleton) is done in the part the owner scheduled now: the fit of the model conventions to the components of feat-9-walking-skeleton is recorded (Task 120.100), and Task 120.110 is deferred until the merge of feat-9 into dev (the owner decision A1 of 2026-11-17; the reason is in the Blockers entry, and the content for the follow-up is in the Updates entry). Phase 130 (the rule set and the runner) is done: the rule set the model gives is documented in one place (the section "The rules the model gives" of `model/README.md`: the forbidden dependencies, the cycle rule, the closed set, and the exceptions), the runner reads the JSON and makes the rules at run time (the Java adapter `ModelRuleRunnerTest`: 2 derived rules for the container `backend` today; the Node adapter `frontend/architecture/runner.mjs`: 11 derived rules for the container `frontend` today, the 10 forbidden pairs and the cycle rule), the hard-coded rules R1 to R3 and R1' to R3' are removed (five files), and the comparison (`ModelComparisonTest` and `compare.mjs`) is mapping-based (the property `code.*`, and not the name), with the shared reading and derivation per side (the class `ModelRules`, the module `frontend/architecture/workspace.mjs`) so the runner and the analyzer of a side cannot drift apart; the defect of the dynamic import of `compare.mjs` is fixed. The gates are green: `just architecture-backend`, `just architecture-frontend` and `just architecture-model` (the two conditions of ACC-003 in a temporary copy still stop the run and name the violation, and the `properties` cases pass). Phase 140 (the tests of the tests: one case that is not successful per rule category, the `Broken*` pattern) is next.

### Blockers

- feat-9-walking-skeleton is not merged into dev (the owner decision A1 of 2026-11-17): the code of feat-9 is done and committed on the branch `feat-9` (the status of the plan of feat-9 is `review`; the criteria ACC-008 and ACC-009 of that plan wait for the action of the owner and the pull request), and the branch is not merged. Task 120.110 of this feature (the addition of the components and the relations of feat-9 to the model) is deferred until the merge of feat-9 into dev: the closed-world comparison requires that each modelled code element exists in the code, and the package `biz.dfch.specmgrdemo.app` and the units `client`, `i18n`, `telemetry` and `ui` of feat-9 are not on this branch (an element of the model without the code of the element stops the comparison on this branch); the owner decided to defer the task until the merge, and not to model the components before the code exists on this branch. The rules run against its components only after the merge of feat-9. The runner is tested with the fixtures and with the current code of the repository in the meantime. The content for the follow-up of Task 120.110 (the components with the mapping `code.*`, the relations with the descriptions in the arrow direction, the one data-ownership case, and the view-reference constraint of the recipe `architecture-model`) is in the Updates entry of Phase 120 (2026-11-17 20:05:00.000Z).

### Updates

<!-- Newest entry first -- prepend new entries directly below this comment. -->

#### 2026-11-18 02:56:00.000Z - Phase 130 done (the rule set and the runner)

**The rule set (Task 130.100).** The model is the language-neutral rule set (there is no separate file of the rules, one source of truth). The derivation is documented in one canonical place: the section "The rules the model gives" of `model/README.md` (the headers of the adapters point to it). The runner confirms the reading of Phase 110: `code.root` is on the container only (the base package of the module, the entry of the DEC e85e9685 says "the base package of the module"), and not on the Java components. The four rule groups, per container with a `code.language` mapping (today: `backend`, `frontend`): (1) the forbidden dependencies (the closed world between the mapped elements: every ordered pair of distinct mapped elements that has no relation gives the rule "the source must not depend on the destination"; the backend gives 1 pair, `model` -> `api`, and the frontend gives 10 pairs, all the ordered pairs of the four components except the two modelled relations `test` -> `zod` and `test` -> `root`); (2) the cycle rule (the viewpoint development: no dependency cycle among the mapped elements; the verdict per language below); (3) the closed set (the parity limit of the plan: it stays in the analyzers `ModelComparisonTest` / `compare.mjs`); (4) the exceptions (`code.allowedExternal` and `code.ignore`, from the model and never from the test code; a dependency to the platform of the language, the packages `java.*` and `javax.*` in Java, is given, and the check does not examine it). No model change was necessary: the committed code passes the mapping-based comparison without a new `code.ignore` entry (the probe of the run names the external dependency surface of the backend: `com.fasterxml.jackson.annotation`, `jakarta.validation`, `jakarta.validation.constraints`, `org.springframework.*` and the platform `java.*` - the entries of `code.allowedExternal` of Phase 110 cover all but the platform).

**The Java adapter (Task 130.110).** The class `biz.dfch.specmgrdemo.architecture.ModelRuleRunnerTest` (the recipe `just architecture-backend`): it reads the workspace (the property `model.workspace.path`, the default `model/workspace.json`, the same interface as the comparison), derives the rule set of the container `backend` (the shared class `ModelRules`), imports the classes of the container's `code.root` (the import option DoNotIncludeTests), and builds the ArchUnit rules at test time (the `@TestFactory`: one dynamic test per derived rule). The derived rules for `backend` today: 2 (the 1 forbidden pair, `model` must not depend on `api`, the predicate `resideInAnyPackage` with the suffix `..` per entry, the form of the spike of Phase 100, and the 1 cycle rule, the slices of the mapped components, one slice per component by the most specific entry of `code.package`, `beFreeOfCycles`). The run is green; a violation names the dependency (the report of ArchUnit, as the R2 of feat-7). The test does not start a Spring context.

**The Node adapter (Task 130.120).** The script `frontend/architecture/runner.mjs` (the recipe `just architecture-frontend`): it reads the workspace strictly (the shared module `frontend/architecture/workspace.mjs`, the same reading and the same derivation as the comparison), derives the rule set of the container `frontend`, and builds the checks of ArchUniTS programmatically (one check per derived forbidden pair, the RegExp of the entries of `code.path` of the source component should not depend on the RegExp of the destination component - a folder entry with the folder suffix, a file entry without - and one cycle rule, `haveNoCycles` over the union of the patterns of all the mapped components). The derived rules for `frontend` today: 11 (the 10 forbidden pairs and the cycle rule). The run is green; a violation names the imports (the source file and the target file of each dependency, as the rules.mjs of feat-7).

**The refactored analyzers (Task 130.130).** `ModelComparisonTest` (the backend) and `compare.mjs` (the frontend) are mapping-based (and not name-based): the components are read by their entries of `code.package` / `code.path`, a code location (a package of a class in the backend, a file in the frontend) belongs to the component of the most specific entry (exactly one), every code dependency between mapped components has a relation, the other direction is closed (a component without a code location, a relation without the code dependency), and every code dependency to a package that no component owns is allowed if and only if it matches an entry of the source component's `code.allowedExternal` (Java: the package is the entry, or a sub-package of the entry; TypeScript: the name of the imported package is the entry, or starts with the entry and the character `/`; the message names the import and the missing entry). The messages the recipes assert are kept: "the package biz.dfch.specmgrdemo.model has no component in the model", "the dependency biz.dfch.specmgrdemo.api -> biz.dfch.specmgrdemo.model is not in the model", "the unit zod of the frontend has no component in the model", "the dependency test -> zod of the frontend is not in the model". The strict reading keeps accepting all the keys of the generated JSON (the top-level `properties`, the element `perspectives`, the model `deploymentNodes`; the content of the key `views` is not inspected: the rules are derived from the elements of the model, and the reader of the backend validates the references of the views, the record of Phase 110). The shared reading/derivation per side makes the runner and the analyzer of a side unable to drift apart. The defect of the dynamic import (the spike of Phase 100, the conventions DEC) is fixed in `compare.mjs`: the construct `import()` and the construct `require()` are read as dependencies with the same resolution as the static imports (an internal specifier resolves to a file of the units, an external specifier is checked against `code.allowedExternal`, a specifier that does not resolve stops the script with exit code 2), and the header says it now (verified: a dynamic `import()` to the external package `zod` from a file of the component `test` stops the run and names the import and the missing entry; before the fix, the pinned typescript 5.9.3 ignored the construct).

**The removal (Task 130.140).** The hard-coded rules are removed: `backend/src/test/java/biz/dfch/specmgrdemo/architecture/ModuleStructureTest.java` (R1), `LayerRuleTest.java` (R2), `BrokenLayerRule.java` (the violated direction of R2), `frontend/architecture/rules.mjs` (R1' to R3') and `rules.broken.mjs` (the violated direction of R2'). The "R1 to R3" of the plan names R1 and R2 as the hard-coded rules of the backend; the third rule of the backend is the closed-world comparison, which is refactored in Task 130.130, and not removed. The recipes `architecture-backend` and `architecture-frontend` are rewired to the runners (the committed run is green, the house form of the script stays: the number header, the exit codes, the console report); the "case that is not successful" parts (the run of `BrokenLayerRule`, the temp-copy run of the module structure, the run of `rules.broken.mjs`) are removed: Phase 140 re-adds the broken case per rule category (the `Broken*` pattern, ACC-006) and rewires the recipes again. The stale references are updated: the `justfile` (the comment headers of the three recipes, and the sentence of the numbers), `model/README.md` (the canonical section and the paragraph of the comparison), `backend/README.md`, `frontend/README.md`, `tools/gates/README.md` (the lines of the three recipes, the table of the tools, the table of the CI jobs). The plan of feat-7 and the DECs are the records of finished work, and they are not rewritten.

**The note of the dependencies.** After the removal of R1, the test code does not use the artifacts `org.springframework.modulith:spring-modulith-core` (1.4.14) and `org.springframework.boot:spring-boot` (3.5.16) any more (verified: no import of `org.springframework.modulith` in the test sources; the jar of spring-boot was the dependency of the module detection of Spring Modulith, removed with R1). The `pom.xml` is not changed in this phase (the change of the `pom.xml` is the territory of the SBOM/license gate, and Phase 160 owns the pins): the pins stay in `tools/versions.env` (the check `just check-pins` passes), and Phase 160 decides (the removal changes the SBOM and the pins).

**The verdict of the cycle rule per language.** Both tools can express the cycle rule (group 2): the backend with ArchUnit (the slices of the mapped components, `beFreeOfCycles`; the violation names the slices of the cycle), the frontend with ArchUniTS (the construct `haveNoCycles`, the graph of the files of the tsconfig, the self-referencing edges of the tool are excluded by the check; the violation names the edges of the cycle). The current model has no cycle, and the committed run is green in both languages; the pair rules do not cover a cycle of three or more elements (the cycle rule covers it). The spike of Phase 100 recorded that ArchUniTS cannot do a closed set of units (group 3, the parity limit that stays in the analyzer); the cycle was not a limit. A new fact of the run (recorded in the section of `model/README.md`): the graph of ArchUniTS has no edge to the external packages (the folder `node_modules` is excluded from the graph of the tool), so the check of `code.allowedExternal` (group 4) is in the analyzer `compare.mjs`, and not in the runner.

**The gates.** `just architecture-backend` (2 ok: the run is green, and the report names the 2 derived rules), `just architecture-frontend` (2 ok: the report names the 11 derived rules, and the run is green), `just architecture-model` (16 ok: the mapping-based comparison is green on both sides, the two conditions of ACC-003 in a temporary copy still stop the run and name the violation, and the cases of `properties` pass - the case of the component with the map of texts keeps the mapping of the component, the merge, and the case of the empty map is on the software system, because the comparison is mapping-based now), `just test-unit-backend` (14 tests green: the runner in, the three classes out), `just test-unit-frontend` (11 tests green: unchanged), `just mutation-backend` and `just mutation-frontend` (green: the recipes assert a surviving mutant, and not the count - the deterministic surviving mutants stay), `just compile` and `just check-generated` (green: no generated code is changed), `just test-gates` (1029 ok, 0 failed), `just validate`, `just traceability`, `just check-pins`, `just check-sudo`, `just check-workflows` and `just commit-check` (green).

#### 2026-11-17 20:05:00.000Z - Phase 120: the fit of the model conventions to the components of feat-9 (Task 120.100), and the deferral of Task 120.110 (the owner decision A1 of 2026-11-17)

**The fit (Task 120.100).** The plan of feat-9-walking-skeleton is read from the branch `feat-9` (the status `review`: the code of the phases 200 to 500 is done and committed on the branch, and the criteria ACC-008 and ACC-009 wait for the action of the owner and the pull request). This plan names the components of feat-9 as "the status service, the adapter, the persistence" (the planning session of 2026-11-16, before the code of feat-9 is done); the plan of feat-9 does not have those three components: the product code of the backend is one top-level package (the component `app`), and the product code of the frontend is four units (`client`, `i18n`, `telemetry`, `ui`). The actual structure, with the exact form of each property of the future model, per DEC e85e9685-0787-4dff-9ee5-9d46670e9ee4:

- The backend (the container `backend`; the mapping of the container: `code.language=java`, `code.root=biz.dfch.specmgrdemo`): the new component `app` (technology `Java class`; the description of the model of the branch `feat-9`: "The product code of the service (the top-level package biz.dfch.specmgrdemo.app, feat-9-walking-skeleton, Phase 200): the main class, the controllers of the two operations, the check of the state, the error handling and the OpenTelemetry filter."). The plan of feat-9 names the content of the package `biz.dfch.specmgrdemo.app`: the main class `SpecMgrDemoApplication`, the controllers that implement the generated interfaces `StatusApi` and `InfoApi`, the check of the state (the interface `StateChecker`, the checks `UpStateChecker` and `FailingStateChecker`, the selection by the property `app.state-checker`), the handler of the errors `ProblemAdvice`, the value of the build `BuildInfoProvider`, the filter `TraceFilter` and the configuration of OpenTelemetry (the Design Notes of the plan of feat-9, and its Decisions Made entry "The new component `app` of the model (the id 14), and the two dependencies (the id 15 and 16)"). The future properties: `code.language=java`, `code.package=biz.dfch.specmgrdemo.app` (the form of one entry; the plan of feat-9 names one top-level package: "The product code of the service is one new top-level package `biz.dfch.specmgrdemo.app`"), and `code.allowedExternal` with the entries that the run of the closed-world comparison names (the plan of feat-9 states that the main code "uses the servlet API, the Spring Web annotations and the OpenTelemetry API only; no class of Jackson is imported", so the expected entries are the packages of the servlet API, of Spring Web and of OpenTelemetry).

- The frontend (the container `frontend`; the mapping of the container: `code.language=typescript`): the new units (technology `TypeScript`, each with the description of the model of the branch `feat-9`): `client` ("The client of the API (the unit client, the folder frontend/src/client, feat-9-walking-skeleton, Phase 300): it calls GET /status and GET /info and validates the responses with the generated Zod schemas."), `i18n` ("The i18n of the user interface (the unit i18n, the folder frontend/src/i18n, feat-9-walking-skeleton, Phase 300): i18next with the catalogs EN and DE."), `telemetry` ("The OpenTelemetry of the browser (the unit telemetry, the folder frontend/src/telemetry, feat-9-walking-skeleton, Phase 300): the Web SDK and the exporter OTLP/HTTP.") and `ui` ("The user interface (the unit ui, the folder frontend/src/ui, feat-9-walking-skeleton, Phase 300): the React components of the page of the status and of the notice of the license."). The future properties of each unit: `code.language=typescript`, `code.path=src/client/**`, `src/i18n/**`, `src/telemetry/**` or `src/ui/**` (the form of one folder, the suffix `/**`), and `code.allowedExternal` with the entries that the run names. The expected entries from the plan of feat-9 (its Decisions Made entry "The structure of the frontend: four units, the file type .tsx in the architecture tools, and the layers"): `i18next, react-i18next` for `i18n`; the one entry `@opentelemetry` for `telemetry` (the form of the DEC allows the imports whose name starts with the entry and the character `/`: `@opentelemetry/api`, `@opentelemetry/sdk-trace-web`, `@opentelemetry/resources`, `@opentelemetry/exporter-trace-otlp-http`); `react, react-dom, react-i18next` for `ui`; no entry expected for `client` (the client takes the function `fetch` as a parameter, and uses the generated types and the generated schemas only).

- The existing elements that the merge of feat-9 changes: the unit `root` gains the entry point `src/main.tsx` (the plan of feat-9: "the entry point `src/main.tsx` lies in the unit `root`"), so its `code.path` takes the form of several entries: `src/mutation-example.ts, src/main.tsx` (two files, no suffix); the description of `root` becomes the one of the model of the branch `feat-9` ("The files that lie directly in frontend/src (the unit root: the entry point main.tsx of the walking skeleton and the example file mutation-example.ts)."); the `code.allowedExternal` of `root` gains the entries of the imports of the entry point that the run names (`react`, `react-dom`); the `code.allowedExternal` of the unit `test` may gain the entries that the tests of the page need (the tests render with `react-dom/client`, the plan of feat-9; the run names them); the component `api` gains the second identifier in `specmgr-req` (the list `1ca335d7-969a-443e-9392-165fdeea99a0, 271168a4-2a6f-40a1-b277-89711b18a087`, the Task 200.130 of the plan of feat-9; the old form keeps working until Phase 150); the description of the container `backend` becomes the one of the model of the branch `feat-9` (it names the product code of the service since the walking skeleton); the note `Evolution` of the perspectives of the system (the components of feat-9 join the model in Phase 120) is done, and is updated or removed.

**The relations (the direction of the arrow is the direction of the dependency of the code, per the DEC).** The 15 relations of feat-9, with the descriptions of the model of the branch `feat-9` (the ids 15 and 16, and 21 to 33, of that model):

- `app -> api` ("The controllers of app implement the generated interfaces of api")
- `app -> model` ("The product code of app uses the classes of model (the state, the information and the problem of the operations)")
- `root -> client` ("The entry point builds the client of the API")
- `root -> i18n` ("The entry point builds the i18n")
- `root -> telemetry` ("The entry point builds the telemetry")
- `root -> ui` ("The entry point renders the user interface")
- `client -> types` ("The client uses the generated types")
- `client -> zod` ("The client validates the responses with the generated Zod schemas")
- `ui -> client` ("The user interface uses the client of the API")
- `ui -> i18n` ("The user interface uses the text of the i18n (the languages)")
- `test -> client` ("The tests import the client of the API")
- `test -> i18n` ("The tests import the i18n")
- `test -> telemetry` ("The tests import the telemetry")
- `test -> ui` ("The tests import the user interface")
- `test -> types` ("The tests import the generated types")

The existing relations (`frontend -> backend`, `api -> model`, `test -> zod`, `test -> root`) stay. The case of the direction of the arrow of the DEC is the relation `app -> api`: the controllers of `app` implement the interfaces of `api`, so the relation points from the code that implements the interface to the interface (the same case the DEC names for the persistence and the domain). The layers of the plan of feat-9: the unit `ui` depends on `client` and on `i18n`; the units `client`, `i18n` and `telemetry` do not depend on `ui`, and are independent of each other.

**The one data-ownership case.** The data of the contract (the generated types, and the generated Zod schemas) is owned by the components `types` and `zod` (the generated code; the product code does not change it). The unit that feat-9 adds and that uses the data is `client`, and the arrows point from the code that uses the data to the owners (`client -> types`, `client -> zod`): that is the enforcement of the Information view, "the ownership of the data as a rule of dependency". The Information view (the component view of the container `frontend`, `rw.viewpoint=information`) gains `include client`, so the view shows the owners, the code that uses the data, and the two arrows; the other direction (a generated unit depends on the product code) has no relation, and is a forbidden dependency. The same pattern holds for the data of the catalogs that the unit `i18n` owns (the unit that uses the data is `ui`, the arrow `ui -> i18n`); the DEC covers the case without a change.

**The verdict of the fit.** The forms of DEC e85e9685-0787-4dff-9ee5-9d46670e9ee4 cover the actual structure of the plan of feat-9 without a change of the forms: the form of one entry and the form of several entries of `code.package` and of `code.path`, the package with the prefix `@` in `code.allowedExternal` (the one entry allows all the packages of the group), the direction of the arrow (the case of the implementation of an interface, that the DEC names), and the Information view for the data-ownership case. The draft DEC is corrected for the names of the components only (the Decision Drivers and the Consequences name the components of the plan of feat-9: `app`, `client`, `i18n`, `telemetry`, `ui`; the entry of Updates of the DEC names the correction). The DEC stays draft (the owner accepts it in the review of the pull request).

**The deferral of Task 120.110 (the owner decision A1 of 2026-11-17).** Task 120.110 (the addition of the components and the relations of feat-9 to the model) is deferred until the merge of feat-9 into dev, and the task stays not ticked. The reason: the closed-world comparison requires that each modelled code element exists in the code, and the package and the units of feat-9 are not on this branch (an element of the model without the code of the element stops the comparison on this branch); the owner decided to defer the task until the merge. The text above is the content for the follow-up of Task 120.110. At the execution, the follow-up adds to `model/workspace.dsl`: the component `app` (the properties above), the units `client`, `i18n`, `telemetry`, `ui` (the properties above), the 15 relations above (with the descriptions above), `include client` in the Information view, and the changes of the existing elements above (the `code.path`, the description and the `code.allowedExternal` of `root`; the `code.allowedExternal` of `test`; the `specmgr-req` of `api`; the description of the container `backend`; the note `Evolution` of the perspectives of the system). The follow-up regenerates the JSON (`just generate-model`) and keeps the comparison green (`just architecture-model`, and the gate `just check-model-generated`). The view-reference constraint (the entry of Decisions Made of Phase 110): the reader of the backend (structurizr-client) validates the references of the views when it reads the JSON, and the recipe `architecture-model` removes the component `model` and the relation `api -> model` of the container `backend` in the temporary copy of the demos of ACC-003 - no view may reference an element or a relation of the container `backend` that the demos remove. The addition of feat-9 keeps that: the seven views stay (no new view references the container `backend`), and the mutation set of the recipe removes the new relation `app -> model` with the component `model` (otherwise the reader meets a reference to an element that is removed, before the comparison names the violation). The two conditions of ACC-003 still stop the run, and the report still names the violation (the package without a component is `biz.dfch.specmgrdemo.model`, and the dependency without a relation is the dependency of `api` to `model`).

#### 2026-11-17 17:14:00.000Z - Phase 110 done (the model in DSL)

The model is in `model/workspace.dsl` (the one file that a person edits, DEC b6e8808f-86b4-41a4-92f2-33d38869beed), and `model/workspace.json` is generated from it by the pinned container (the recipe `just generate-model`; the step names the digest `STRUCTURIZR_IMAGE_DIGEST`, and not the tag). Drift check (the comparison before and after the conversion, and after each regeneration): green at each step - the backend side and the frontend side of `just architecture-model` match the code, and the two conditions of ACC-003 in a temporary copy still stop the run and name the violation. What the generated JSON adds to the hand-maintained file: the top-level key `properties` (the base64 of the DSL under `structurizr.dsl`, the counts of the inspection under `structurizr.inspection.*`), the element property `structurizr.dsl.identifier` for each element that has a variable of the DSL (the id of the element stays the digit text of the writer; no `!identifiers hierarchical` - a verified fact that extends the claim of the DEC), the element key `perspectives`, and the model key `deploymentNodes` (the deployment unit of the view of the deployment). The set of relations is exactly the 4 modelled relations (`!impliedRelationships false`; the parser adds no implied relation). The new recipes and their test, all passing: `just generate-model` (two runs make no change), `just check-model-generated` (it validates the DSL, it makes the JSON twice in a temporary folder, and it stops for a JSON that is not up to date), and `just test-check-model-generated-gate` (8 fixture cases: the good case twice, the changed-JSON case (the diff names the difference), the stale-JSON case, the broken-DSL case (the line named), the pin case, and the usage). The seven views (each with `rw.viewpoint`): Context (the view type `systemContext`), Functional (the view type `container`), Development (the view type `component`, the container `frontend`), Information (the view type `component`, the container `frontend`, the data-owning components `types` and `zod`), Concurrency (the view type `dynamic`), Deployment (the view type `deployment`, one node documented as the single deployment unit of the model) and Operational (the view type `container`). The `code.*` mapping and the closed-world exceptions (the form of DEC e85e9685-0787-4dff-9ee5-9d46670e9ee4): the container `backend` has `code.language` `java` and `code.root`; the components `api` and `model` have `code.language` `java` and `code.package`; the container `frontend` has `code.language` `typescript`; the components `types`, `zod`, `test` and `root` have `code.language` `typescript` and `code.path`. `code.allowedExternal` is on the elements that the code of depends on, per the verified imports: `api` (`org.springframework.., jakarta.validation.., jakarta.annotation`), `model` (`com.fasterxml.jackson.., org.springframework.., jakarta.validation.., jakarta.annotation`), `zod` (`zod`), `test` (`vitest, fast-check`); `types` and `root` have no external import, and `code.ignore` is not needed (the test classes of the backend are excluded by the reader, and each file of the frontend is in a unit). The minimal extension of the strict reader `frontend/architecture/compare.mjs` (the full reader refactor stays in Task 130.130): it accepts the top-level key `properties` (a map of texts), the element key `perspectives` (an array of the objects with the text keys `name`, `description` and `value`), and the model key `deploymentNodes` (an array of the nodes, validated strictly). The property `specmgr-req` of the component `api` stays as-is (the switch to `specmgr-refs` happens in Phase 150 together with the extension of the traceability gate, so the link stays gate-checked throughout). `model/README.md` is rewritten for the new state, and the workspace description names the two new DECs (b6e8808f, e85e9685). Gates that pass: `just architecture-model` (16 ok), `just architecture-backend` (4 ok), `just architecture-frontend` (2 ok), `just generate-model` (twice, no change), `just check-model-generated`, `just test-check-model-generated-gate` (8 ok), `just test-gates` (1029 ok), `just validate`, `just traceability` (0 errors), `just check-pins`, `just check-sudo`, `just check-workflows` and `just commit-check`.

#### 2026-11-17 12:10:00.000Z - Phase 100 done (the decisions and the spike)

The two DECs are written (the status is draft; the owner accepts them in the review of the pull request): DEC b6e8808f-86b4-41a4-92f2-33d38869beed (The DSL Is the Source and the JSON Is Generated) and DEC e85e9685-0787-4dff-9ee5-9d46670e9ee4 (The Model Conventions; it partly supersedes DEC 9edc1071-4fd0-48b6-a037-1a4cb2331f73, and the Updates section of that DEC names it). The tool decision (the owner D1, verified): the container `structurizr/structurizr` (the tag `2026.10.26-noble`, the digest `sha256:1081d615e7a539aee8b8360e36a58f42ff6412dd8f0e1b053134cb2c76ab2303`, pinned in `tools/versions.env` as `STRUCTURIZR_IMAGE` and `STRUCTURIZR_IMAGE_DIGEST`) makes the JSON from the DSL with the command `export -f json`; the Java library `structurizr-dsl` 6.2.4 is the confirmed fallback (not needed); the Structurizr MCP cannot make the JSON (the verified limit: its tools are parse, validate, inspect, and the export to PlantUML, Mermaid and C4-PlantUML). The spike verdict: the rules are built from the JSON of the model in both languages (the forbidden pairs derived from the workspace; the green case and the red case with the violation named by the tool). The limits per language (in the conventions DEC and in the RSK): Java - a component with several packages is supported (`resideInAnyPackage`), a reference by type only is visible (the probe: the interface `StatusApi`), a dependency by reflection or injection is not visible; Node - a unit with several folders is supported only with a pattern of the type RegExp (a text glob of the form `(a|b)` is not supported), a type-only import is visible, a dynamic import is invisible; a defect of `compare.mjs` - the header says that a dynamic import stops the script, but with the pinned typescript 5.9.3 the construct `import()` is silently ignored (the fix is Task 130.130). RSK 025202ba-e4a7-4f6b-a65b-92f945b6f321 is updated (the mitigation is confirmed for each category of rule that the model gives; the status stays open; the assessment is not changed). The gates `just validate`, `just traceability`, `just check-pins`, `just check-sudo`, `just check-workflows` and `just commit-check` pass at the end of the phase.

#### 2026-11-16 16:40:00.000Z - Plan written

The feature is created from the planning session of 2026-11-16 (issue #50). The design, the decisions and the phase structure are in the session transcript on the feat-50 branch. The feature depends on feat-9-walking-skeleton for the product components.

### Decisions Made

<!-- Newest entry first -- prepend new entries directly below this comment. -->

#### 2026-11-18 02:56:00.000Z - The shared reading and derivation per side (the design of the runner and the analyzer)

The plan leaves the names of the adapters open. The side of the backend has the shared class `ModelRules` (the reading of the workspace, the derivation of the rule set of the container, the ownership of the most specific entry, the form of `code.allowedExternal`, and the import of the classes), used by the runner `ModelRuleRunnerTest` and by the comparison `ModelComparisonTest`. The side of the frontend has the shared module `frontend/architecture/workspace.mjs` (the strict reading, the derivation, the RegExp of the entries of `code.path`, the ownership of the most specific entry, and the form of `code.allowedExternal`), used by the runner `runner.mjs` and by the comparison `compare.mjs`. The runner and the analyzer of a side read the model through the same code, so they cannot drift apart (the rule set of the model is one, per the canonical section of `model/README.md`).

#### 2026-11-18 02:56:00.000Z - The ownership of the most specific entry (the mapping-based comparison)

A code location (a package of a class in the backend, a file in the frontend) belongs to the component of the most specific entry of `code.package` / `code.path`: the entry that is the location itself, or the longest entry that is a prefix of it. An entry covers the package and its sub-packages (Java, the form of `resideInAnyPackage` with the suffix `..` of the runner) and the files of the folder at each depth (TypeScript, the folder suffix of `code.path`). The model may nest the entries (a component that owns a sub-package of the tree of another component; the most specific entry resolves it). Two components that have the same most specific entry for a location is the ambiguous mapping: the comparison stops, and the message names the location and the two components (the exactly one of the closed set).

#### 2026-11-18 02:56:00.000Z - The scope of the exceptions (the platform of the language is given)

Group 4 of the rule set (the exceptions): a code dependency to a package that no component owns is allowed if and only if it matches an entry of the `code.allowedExternal` of the source component, except the platform of the Java language (the packages `java.*` and `javax.*`), which the check of the backend does not examine. On the side of the TypeScript, there is no such exemption: every import of a package (also the constructs of the runtime of the language, for example the packages with the prefix `node:`) must match an entry of `code.allowedExternal` (no entry of the platform is in the model today, and the committed run is green: the imports of the units are `zod`, `vitest` and `fast-check`, all listed). The reason (verified by the probe of the run): the external dependency surface of the committed backend code is the framework (`org.springframework.*`, `com.fasterxml.jackson.annotation`, `jakarta.validation(.constraints)`) and the platform (`java.lang`, `java.time`, `java.util`), and the entries of `code.allowedExternal` of the model cover the framework, and not the platform (the record of Phase 120 of the future entries of the components of feat-9 has the same form: no entry of the platform). The exception lives in the model, and never in the test code (DEC e85e9685); the platform of the Java language is no exception (the runtime of the Java language is given to all the Java code), and the side of the TypeScript has no exemption (the sentence above).

#### 2026-11-18 02:56:00.000Z - The location of `code.ignore` (the container)

The DEC e85e9685 names `code.ignore` (the code that no element maps and that the check does not examine), and does not fix the element that holds it. The implementation reads it on the container (the level of the module), and not on the component: a code location that no element maps is a concern of the closed world of the module. The form is the same as `code.allowedExternal` (Java: the package and the sub-packages; TypeScript: the folder / the file entries of `code.path`). No entry is in the model today (the mapping-based comparison is green on the committed code without it).

#### 2026-11-18 02:56:00.000Z - The verdict of the cycle rule (both tools can express it)

The cycle rule (group 2 of the rule set) is in both runners, and not only in the analyzer: the backend with ArchUnit (the slices of the mapped components, the construct `beFreeOfCycles`), the frontend with ArchUniTS (the construct `haveNoCycles`, the graph of the files of the tsconfig; the violation names the edges of the cycle). The spike of Phase 100 recorded that ArchUniTS cannot do a closed set of units (group 3, the parity limit that stays in the analyzer); the cycle was no limit (the pinned ArchUniTS 2.5.4 has the construct, verified in the run).

#### 2026-11-18 02:56:00.000Z - The cases of `properties` of the recipe `architecture-model` (the merge keeps the mapping)

The comparison is mapping-based now (Task 130.130): a case that replaces the whole `properties` of a mapped component destroys the mapping `code.*` of the component (the files of the component have no mapped element, and the comparison stops - the correct behavior of the closed set, and not the case of the reader that part 3 of the recipe examines). The case of the component with the map of texts keeps the mapping of the component (the merge of the key into the existing properties), and the case of the empty map is on the software system (the properties of the system carry no mapping). The strict reader is not changed (the acceptance and the rejection are the same, the cases of exit code 2 pass without a change).

#### 2026-11-17 20:05:00.000Z - The fit of the model conventions to the actual components of feat-9 (the names, and the data-ownership case)

The entry of Task 120.100 records the fit in the section Updates. Two decisions of the fit: (1) the names of the components. This plan names the components of feat-9 as "the status service, the adapter, the persistence" (the planning session of 2026-11-16, before the code of feat-9 is done). The plan of feat-9 (read on 2026-11-17, the status `review`) names the actual structure: the product code of the backend is one top-level package `biz.dfch.specmgrdemo.app` (the component `app`), and the product code of the frontend is the four units `client`, `i18n`, `telemetry` and `ui` (and the entry point `src/main.tsx` lies in the unit `root`). The draft DEC e85e9685-0787-4dff-9ee5-9d46670e9ee4 is corrected for the names (the Decision Drivers and the Consequences); the forms of the DEC stay unchanged, and the DEC stays draft. (2) The one data-ownership case of the addition of feat-9 (Task 120.110, deferred until the merge of feat-9): the data of the contract (the generated types, and the generated Zod schemas) is owned by the components `types` and `zod`, and the unit that uses the data (`client`) depends on the owners (`client -> types`, `client -> zod`); the Information view (`rw.viewpoint=information`) shows the case (the view gains `include client`).

#### 2026-11-17 17:14:00.000Z - The view types of the seven viewpoints (the constraint of the reader)

Context is the view type `systemContext`, Functional is `container`, Development and Information are `component` views of the container `frontend` (Information includes only the data-owning components `types` and `zod`), Concurrency is `dynamic`, Deployment is `deployment` (one node, the single deployment unit of the model), and Operational is `container`. The constraint (verified): the reader of the backend (structurizr-client) validates the references of the views when it reads the JSON, and the recipe `architecture-model` (fixed in this phase) removes the component `model` and the relation `api` -> `model` of the container `backend` in its temporary copy. A view that references them stops the reader before the comparison names the violation. The units of the container `frontend` are not removed in those demos, so the `component` views of `frontend` are safe.

#### 2026-11-17 17:14:00.000Z - The id scheme of the elements (no `!identifiers hierarchical`)

The id of the element stays the digit text of the writer (the readers resolve the id only inside the file, and any consistent scheme works). Verified fact that extends the claim of DEC b6e8808f: an element that has a variable of the DSL gets the property `structurizr.dsl.identifier` (the variable name) even without `!identifiers hierarchical`.

#### 2026-11-17 17:14:00.000Z - The mapping `code.*` per element (the reading of the form of the DEC)

`code.language` is on each mapped element (the DEC says it is required for a mapped element, including the components). `code.root` is on the container `backend` only (the base package of the module), and not on the Java components: the runner of Phase 130 confirms that reading, or adds `code.root` to the components (a change of the model only, no change of the code).

#### 2026-11-17 17:14:00.000Z - The property `specmgr-req` stays until Phase 150 (the ordering)

The conversion keeps the property `specmgr-req` of the component `api` as-is (and does not switch it to `specmgr-refs` in this phase): the switch happens in Phase 150 together with the extension of the traceability gate, so the traceability link stays gate-checked throughout the feature.

#### 2026-11-17 17:14:00.000Z - The minimal reader extension now, the full refactor in Task 130.130

`frontend/architecture/compare.mjs` accepts only the keys that the exporter of the pinned container adds (the top-level `properties`, the element `perspectives`, the model `deploymentNodes`), each validated strictly. The name-based comparison logic, the unit discovery, and the fix of the dynamic-import defect stay in Task 130.130 (as the plan assigns them).

#### 2026-11-17 12:10:00.000Z - The tool of the DSL-to-JSON generation (verified, the fallback confirmed)

The container `structurizr/structurizr` (the tag `2026.10.26-noble`, the digest `sha256:1081d615e7a539aee8b8360e36a58f42ff6412dd8f0e1b053134cb2c76ab2303`) is the tool that makes the JSON of the model from the DSL (the owner decision D1, verified in Phase 100: the output has the shape of the writer, two runs make no change, the properties and the views come through, the command `validate` stops for a DSL that does not parse). The pin is in `tools/versions.env` (the keys `STRUCTURIZR_IMAGE` and `STRUCTURIZR_IMAGE_DIGEST`). The Java library `structurizr-dsl` 6.2.4 is the confirmed fallback (the owner decision of 2026-11-17), and it is not needed at this time. What is open: the DSL of the project (Phase 110) must set `!impliedRelationships false`, because the parser of the DSL adds implied relations by default (the verified result is in the DEC b6e8808f-86b4-41a4-92f2-33d38869beed).

#### 2026-11-17 12:10:00.000Z - The forms of the model conventions are fixed

The DEC e85e9685-0787-4dff-9ee5-9d46670e9ee4 (The Model Conventions) fixes the form of the value of each property: the mapping `code.*` (the list of packages or paths that the character comma separates, a space after the comma is allowed), the exceptions `code.allowedExternal` and `code.ignore`, the arrow direction (the direction of the dependency of the code), the viewpoint `rw.viewpoint` (the seven values), the native perspectives (documentation only), and the references `specmgr-refs` (the form `TYPE UUID; TYPE UUID`, the text `; ` separates the entries, exactly one space after the semicolon). What is open: the owner accepts the DEC in the review of the pull request; the components of feat-9-walking-skeleton take the mapping when that feature merges (Phase 120, deferred by the owner decision of 2026-11-17).

#### 2026-11-16 16:40:00.000Z - The views of the demo

Context, Functional, Development and Information have the rules. Concurrency, Deployment and Operational are documentation only. This is the answer of the owner in the planning session.

#### 2026-11-16 15:30:00.000Z - No own walking skeleton

The feature does not build its own skeleton: it depends on feat-9-walking-skeleton for the product components. The overlap was found in the planning session, and issue #50 names the dependency.

#### 2026-11-16 15:10:00.000Z - The JSON stays the interchange

The DSL is the hand-edited source, and the JSON is generated and is the input of the runner: the Node cannot parse the DSL, one parse gives one result, the readers exist, and the diff shows the resolved model. The MCP cannot make the JSON, and the container is checked in Phase 100.

### Related PRs / Commits

- [Issue #50](https://github.com/dfch/biz.dfch.SpecMgrDemo/issues/50): the tracking issue.

### More Information

- The session transcript: `session-feat-50-prep-c4-ses_e1b5.md` on the branch `feat-50` (the worktree `../biz.dfch.SpecMgrDemo.worktree/feat-50`).
- The delivery follows DEC d778d444-6227-4070-ae6e-b1083c78c58b (no local commit on dev): the documents of this feature reach dev through a branch and a pull request.
