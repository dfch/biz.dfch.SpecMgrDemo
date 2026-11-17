---
classification: null
created: '2026-11-16T22:46:31.684+01:00'
id: feat-50-structurizr-model-rules
status: planning
type: feat
updated: '2026-11-17T19:04:52.101+01:00'
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

- [ ] ACC-003: In a temporary copy of the repository, a package without a component and a dependency without a relation each stop the build, and the report names the violation.

- [x] ACC-004: Two runs of the JSON generation make no change, and the gate stops for a JSON that differs from the DSL (like `check-generated`).

- [ ] ACC-005: The runner derives the rules from the JSON. The hard-coded rules R1 to R3 and R1' to R3' are removed, and the same rules run from the model.

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

- [ ] Task 120.100: Read the plan of feat-9-walking-skeleton, and fit the model conventions to its components (the status service, the adapter, the persistence).

- [ ] Task 120.110: Add the components and the relations of feat-9 to the model (including one data-ownership case), and keep the comparison green. This feature adds no product code.

#### Phase 130: The Rule Set and the Runner

- [ ] Task 130.100: Define the rule set that the model gives (the JSON form of the rules, the language-neutral part).

- [ ] Task 130.110: Write the Java adapter: build the ArchUnit rules from the model at test time (for example the `@TestFactory`).

- [ ] Task 130.120: Write the Node adapter: build the ArchUniTS rules from the model.

- [ ] Task 130.130: Refactor `ModelComparisonTest` and `compare.mjs` onto the same rule set (allow the new JSON keys: the views, the perspectives, the view properties).

- [ ] Task 130.140: Remove the hard-coded rules R1 to R3 (the backend) and R1' to R3' (the frontend).

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

**As of 2026-11-17**: Phase 110 (the model in DSL) is done. The model is in `model/workspace.dsl` (the one file that a person edits, DEC b6e8808f-86b4-41a4-92f2-33d38869beed), and `model/workspace.json` is generated from it by the pinned container (the recipe `just generate-model`; the step names the digest of `tools/versions.env`, and not the tag; two runs make no change). The gate `just check-model-generated` stops for a JSON that is not up to date with the DSL, and for a DSL that does not parse (the line named), and its fixture test `just test-check-model-generated-gate` passes (8 cases). The model has the seven views (each with the property `rw.viewpoint`), the mapping `code.*`, and the closed-world exceptions `code.allowedExternal` (DEC e85e9685-0787-4dff-9ee5-9d46670e9ee4). The comparison stays green on the committed code (`just architecture-model`, 16 ok, and the two conditions of ACC-003 in a temporary copy still stop the run and name the violation). The strict reader `frontend/architecture/compare.mjs` accepts the keys that the exporter adds (the top-level `properties`, the element `perspectives`, the model `deploymentNodes`); the full reader refactor is Task 130.130. Phase 120 (the model of the walking skeleton) is next.

### Blockers

- feat-9-walking-skeleton is in progress (its code phases are not done): the rules run against its components only after the merge of feat-9. The runner is tested with the fixtures and with the current code of the repository in the meantime.

### Updates

<!-- Newest entry first -- prepend new entries directly below this comment. -->

#### 2026-11-17 17:14:00.000Z - Phase 110 done (the model in DSL)

The model is in `model/workspace.dsl` (the one file that a person edits, DEC b6e8808f-86b4-41a4-92f2-33d38869beed), and `model/workspace.json` is generated from it by the pinned container (the recipe `just generate-model`; the step names the digest `STRUCTURIZR_IMAGE_DIGEST`, and not the tag). Drift check (the comparison before and after the conversion, and after each regeneration): green at each step - the backend side and the frontend side of `just architecture-model` match the code, and the two conditions of ACC-003 in a temporary copy still stop the run and name the violation. What the generated JSON adds to the hand-maintained file: the top-level key `properties` (the base64 of the DSL under `structurizr.dsl`, the counts of the inspection under `structurizr.inspection.*`), the element property `structurizr.dsl.identifier` for each element that has a variable of the DSL (the id of the element stays the digit text of the writer; no `!identifiers hierarchical` - a verified fact that extends the claim of the DEC), the element key `perspectives`, and the model key `deploymentNodes` (the deployment unit of the view of the deployment). The set of relations is exactly the 4 modelled relations (`!impliedRelationships false`; the parser adds no implied relation). The new recipes and their test, all passing: `just generate-model` (two runs make no change), `just check-model-generated` (it validates the DSL, it makes the JSON twice in a temporary folder, and it stops for a JSON that is not up to date), and `just test-check-model-generated-gate` (8 fixture cases: the good case twice, the changed-JSON case (the diff names the difference), the stale-JSON case, the broken-DSL case (the line named), the pin case, and the usage). The seven views (each with `rw.viewpoint`): Context (the view type `systemContext`), Functional (the view type `container`), Development (the view type `component`, the container `frontend`), Information (the view type `component`, the container `frontend`, the data-owning components `types` and `zod`), Concurrency (the view type `dynamic`), Deployment (the view type `deployment`, one node documented as the single deployment unit of the model) and Operational (the view type `container`). The `code.*` mapping and the closed-world exceptions (the form of DEC e85e9685-0787-4dff-9ee5-9d46670e9ee4): the container `backend` has `code.language` `java` and `code.root`; the components `api` and `model` have `code.language` `java` and `code.package`; the container `frontend` has `code.language` `typescript`; the components `types`, `zod`, `test` and `root` have `code.language` `typescript` and `code.path`. `code.allowedExternal` is on the elements that the code of depends on, per the verified imports: `api` (`org.springframework.., jakarta.validation.., jakarta.annotation`), `model` (`com.fasterxml.jackson.., org.springframework.., jakarta.validation.., jakarta.annotation`), `zod` (`zod`), `test` (`vitest, fast-check`); `types` and `root` have no external import, and `code.ignore` is not needed (the test classes of the backend are excluded by the reader, and each file of the frontend is in a unit). The minimal extension of the strict reader `frontend/architecture/compare.mjs` (the full reader refactor stays in Task 130.130): it accepts the top-level key `properties` (a map of texts), the element key `perspectives` (an array of the objects with the text keys `name`, `description` and `value`), and the model key `deploymentNodes` (an array of the nodes, validated strictly). The property `specmgr-req` of the component `api` stays as-is (the switch to `specmgr-refs` happens in Phase 150 together with the extension of the traceability gate, so the link stays gate-checked throughout). `model/README.md` is rewritten for the new state, and the workspace description names the two new DECs (b6e8808f, e85e9685). Gates that pass: `just architecture-model` (16 ok), `just architecture-backend` (4 ok), `just architecture-frontend` (2 ok), `just generate-model` (twice, no change), `just check-model-generated`, `just test-check-model-generated-gate` (8 ok), `just test-gates` (1029 ok), `just validate`, `just traceability` (0 errors), `just check-pins`, `just check-sudo`, `just check-workflows` and `just commit-check`.

#### 2026-11-17 12:10:00.000Z - Phase 100 done (the decisions and the spike)

The two DECs are written (the status is draft; the owner accepts them in the review of the pull request): DEC b6e8808f-86b4-41a4-92f2-33d38869beed (The DSL Is the Source and the JSON Is Generated) and DEC e85e9685-0787-4dff-9ee5-9d46670e9ee4 (The Model Conventions; it partly supersedes DEC 9edc1071-4fd0-48b6-a037-1a4cb2331f73, and the Updates section of that DEC names it). The tool decision (the owner D1, verified): the container `structurizr/structurizr` (the tag `2026.10.26-noble`, the digest `sha256:1081d615e7a539aee8b8360e36a58f42ff6412dd8f0e1b053134cb2c76ab2303`, pinned in `tools/versions.env` as `STRUCTURIZR_IMAGE` and `STRUCTURIZR_IMAGE_DIGEST`) makes the JSON from the DSL with the command `export -f json`; the Java library `structurizr-dsl` 6.2.4 is the confirmed fallback (not needed); the Structurizr MCP cannot make the JSON (the verified limit: its tools are parse, validate, inspect, and the export to PlantUML, Mermaid and C4-PlantUML). The spike verdict: the rules are built from the JSON of the model in both languages (the forbidden pairs derived from the workspace; the green case and the red case with the violation named by the tool). The limits per language (in the conventions DEC and in the RSK): Java - a component with several packages is supported (`resideInAnyPackage`), a reference by type only is visible (the probe: the interface `StatusApi`), a dependency by reflection or injection is not visible; Node - a unit with several folders is supported only with a pattern of the type RegExp (a text glob of the form `(a|b)` is not supported), a type-only import is visible, a dynamic import is invisible; a defect of `compare.mjs` - the header says that a dynamic import stops the script, but with the pinned typescript 5.9.3 the construct `import()` is silently ignored (the fix is Task 130.130). RSK 025202ba-e4a7-4f6b-a65b-92f945b6f321 is updated (the mitigation is confirmed for each category of rule that the model gives; the status stays open; the assessment is not changed). The gates `just validate`, `just traceability`, `just check-pins`, `just check-sudo`, `just check-workflows` and `just commit-check` pass at the end of the phase.

#### 2026-11-16 16:40:00.000Z - Plan written

The feature is created from the planning session of 2026-11-16 (issue #50). The design, the decisions and the phase structure are in the session transcript on the feat-50 branch. The feature depends on feat-9-walking-skeleton for the product components.

### Decisions Made

<!-- Newest entry first -- prepend new entries directly below this comment. -->

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
