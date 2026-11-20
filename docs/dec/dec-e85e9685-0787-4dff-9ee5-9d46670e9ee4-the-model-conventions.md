---
classification: null
created: '2026-11-17T11:26:49.961+01:00'
id: e85e9685-0787-4dff-9ee5-9d46670e9ee4
status: draft
type: dec
updated: '2026-11-18T05:51:56.518+01:00'
version: 1.0.0
---

# The Model Conventions

## Context and Problem Statement

The comparison of the model with the code is closed world, and the runner of the rules reads the model (feat-50-structurizr-model-rules). Both need the exact form of the properties of the model: the mapping of an element to the code, the exceptions of the closed world, the meaning of a relation, the viewpoints of the views, the perspectives of the elements, and the references to the specmgr artifacts. DEC 9edc1071-4fd0-48b6-a037-1a4cb2331f73 fixes that "the name of a package is the same as the identifier of its component in the model". That rule couples the name of the code to the name of the model, and it does not cover the frontend (a unit is a folder or a set of files, and not a name). This decision replaces that rule with an explicit mapping, and it fixes the other conventions. This decision partly supersedes DEC 9edc1071-4fd0-48b6-a037-1a4cb2331f73: the choice of the tools (ArchUnit and Spring Modulith for the backend, ArchUniTS for the frontend) stays; the rule for the name of the package is replaced.

## Decision Drivers

- Goal: keep one source of truth for each fact (GOL 9ffb930c-44e8-4d0e-b4fd-f94c7162a894). The exceptions of the closed world live in the model, and not in the test code.
- The mapping of an element to the code does not depend on the name of the element.
- The conventions must fit the components of feat-9-walking-skeleton when that feature merges (the component `app` of the backend, and the units `client`, `i18n`, `telemetry` and `ui` of the frontend; the owner decision of 2026-11-17 defers the addition of those components to Phase 120 of feat-50-structurizr-model-rules).
- The two sides of the comparison (the backend and the frontend) read the same form of the value.

## Considered Options

- The explicit properties `code.*` on the element (the option of this decision).
- The equality of the name of the package and the name of the component (the rule of DEC 9edc1071-4fd0-48b6-a037-1a4cb2331f73; rejected for the reason above).
- The mapping in a different file next to the model (rejected: the second source of truth for the same fact).

## Decision Outcome

The model uses the conventions of this decision. The mapping of an element to the code is the property `code.*` (the language, the root and the package for Java, the path for TypeScript). Only the elements that have a mapping are compared with the code. The exceptions of the closed world are the properties `code.allowedExternal` and `code.ignore`. The relation of the model points in the direction of the dependency of the code, and a missing relation between two mapped elements is a forbidden dependency. The viewpoint of a view is the property `rw.viewpoint`, and the perspectives of an element are in the native block `perspectives` (documentation only). The references to the specmgr artifacts are in the property `specmgr-refs` (the form `TYPE UUID; TYPE UUID`). The differences of behavior between the tools of the two languages (the language skew) are in More Information.

### Consequences

- The reader of the frontend (`frontend/architecture/compare.mjs`) and the runner of the rules read the new properties, and they allow the new keys of the JSON that the generation gives (the top-level `properties`, the element key `perspectives`, the model key `deploymentNodes`): the strict reader accepts the three keys in Phase 110 of feat-50-structurizr-model-rules (the minimal extension, the record in the Decisions Made of the plan of that feature), and Phase 130 (Task 130.130) refactored the reading and the acceptance into the shared module `frontend/architecture/workspace.mjs`.
- The gate for the traceability reads `specmgr-refs` (Phase 150, Task 150.100). The old property `specmgr-req` keeps working for one release (Phase 150, Task 150.110), and DEC f21920d2-4da5-4cf7-bd94-2e9bcba77342 is updated in Phase 150, Task 150.120.
- The components of feat-9-walking-skeleton take the mapping `code.*` when that feature merges (Phase 120 of feat-50-structurizr-model-rules, deferred by the owner decision of 2026-11-17). The conventions of this decision are usable for those components (the component `app` of the backend, and the units `client`, `i18n`, `telemetry` and `ui` of the frontend) without a change (the fit is recorded in Phase 120, Task 120.100, of feat-50-structurizr-model-rules).
- The element without a mapping is not compared with the code, and the code that no element maps and that no exception names stops the comparison (the closed world, the limit of one source of truth).

### Confirmation

The comparison run is green on the code with the mapping (Phase 110, Task 110.140 of feat-50-structurizr-model-rules). The spike of Phase 100 of that feature shows that the rules are built from the JSON of the model in both languages (ArchUnit for the backend, ArchUniTS for the frontend), and it records the limits in More Information of this decision.

## Roles and Responsibilities

### Accountable

Project owner.

### Responsible

- Maintainers of the model and of the architecture.

## Tags

- architecture
- structurizr
- conventions

## Source

Planning session of 2026-11-16 (the transcript `session-feat-50-prep-c4-ses_e1b5.md` on the feat-50 branch), the decision of the owner of 2026-11-17, and the spike of Phase 100 of feat-50-structurizr-model-rules on 2026-11-17.

## Related Artifacts

### Decisions

- DEC 9edc1071-4fd0-48b6-a037-1a4cb2331f73: Make Sure That the Code Obeys the Structurizr Model
  Partly superseded by this decision. The choice of the tools stays; the rule "the name of a package is the same as the identifier of its component in the model" is replaced by the mapping `code.*`.

- DEC f21920d2-4da5-4cf7-bd94-2e9bcba77342: Use Specmgr Identifiers for Traceability
  This decision fixes the new form `specmgr-refs`. That decision is updated for the form in Phase 150 of feat-50-structurizr-model-rules.

### Goals

- GOL 9ffb930c-44e8-4d0e-b4fd-f94c7162a894: Keep One Source of Truth for Each Fact

### Risks

- RSK 025202ba-e4a7-4f6b-a65b-92f945b6f321: ArchUniTS Cannot Do Each Necessary Rule
  The spike of Phase 100 updates that risk with the limits of the tools.

## More Information

The form of the value of each property.

### The code mapping (`code.*`)

- `code.language` (required for a mapped element): the text `java` or the text `typescript` (lower case, no other value).
- `code.root` (required for Java): the base package of the module, for example `biz.dfch.specmgrdemo`. The adapter of the Java side imports the classes only from this package.
- `code.package` (required for Java): one or more full package names, that the character comma separates (a space after the comma is allowed). One entry is the form `biz.dfch.specmgrdemo.api`. Several entries are the form `biz.dfch.specmgrdemo.app, biz.dfch.specmgrdemo.app.state` (a component with several packages; the spike of Phase 100 shows that the adapter of the Java side handles the list, the predicate `resideInAnyPackage` of ArchUnit).
- `code.path` (required for TypeScript): one or more paths relative to the folder of the pnpm module (`frontend/`), that the character comma separates (a space after the comma is allowed). A folder is the path with the suffix `/**` (the files of the folder, at each depth), for example `src/generated/types/**`. A file is the path without the suffix, for example `src/mutation-example.ts`. Several entries are the form `src/service/**, src/persistence/**` (a unit with several folders; the spike of Phase 100 shows that the adapter of the Node side handles the list, the pattern of the type RegExp of ArchUniTS).
- An element is compared with the code only if it has `code.language` and the property of its language (`code.root` and `code.package` for Java, `code.path` for TypeScript). This is the first limit of the closed world.

### The exceptions of the closed world

- `code.allowedExternal` (optional): the dependency of a mapped element to code that is outside the mapped elements and that is allowed (for example the code of a third party or of a framework). For Java: one or more package names, that the character comma separates (a space after the comma is allowed); a trailing `..` marks the package and all its sub-packages, for example `org.springframework.., com.fasterxml.jackson..`. A dependency to a package that starts with an entry is allowed. For TypeScript: one or more names of packages, that the character comma separates (a space after the comma is allowed), for example `zod, react`. An external import whose name is the entry, or that starts with the entry and the character `/`, is allowed.
- `code.ignore` (optional): the code that no element maps and that the check does not examine (for example the code that a component owns and that is generated, or the code of a test that is no unit). For Java: one or more package names, with the same form as `code.allowedExternal`. For TypeScript: one or more paths, with the same form as `code.path`.
- The exception lives in the model, and never in the test code (the second limit of the closed world, the goal of one source of truth).

### The direction of the arrow

The relation of the model points in the direction of the dependency of the code. If the persistence implements the interface of the domain, the relation points from the persistence to the domain. A missing relation between two mapped elements is a forbidden dependency (the closed world). The relation of the container level (for example `frontend` to `backend`) is not compared with the code (the first limit of the closed world, the relation is not visible in the code of one module).

### The viewpoints (`rw.viewpoint`)

The view has the property `rw.viewpoint`. The value is the name of the viewpoint of Rozanski & Woods (lower case): `context`, `functional`, `information`, `concurrency`, `development`, `deployment`, `operational`. The enforcement of each viewpoint (the decision of the owner of 2026-11-16):

| Viewpoint | Value | Enforcement |
|---|---|---|
| Context | `context` | none, or only weak (which code may reach an external system) |
| Functional | `functional` | yes: the allowed dependencies, no unmapped code |
| Development | `development` | yes: the layers, the cycles, the naming, the annotations (the level C4) |
| Information | `information` | partly: the ownership of the data as a rule of dependency |
| Concurrency | `concurrency` | the rules of the annotations only |
| Deployment | `deployment` | none: documentation only |
| Operational | `operational` | none: documentation only |

### The perspectives

The perspectives of Rozanski & Woods (for example `Security`, `Performance`, `Availability`, `Evolution`) are in the native block `perspectives` of the element of the DSL (the form `perspectives { "Security" "the text" "High" }`, verified by the probe of the planning session). The form of the JSON is the list of the objects `{ name, description, value }`. The perspective is documentation, and not a test (the feature does not check it).

### The references (`specmgr-refs`)

The element has the property `specmgr-refs` for the references to the specmgr artifacts. The value is one or more entries, that the text `; ` (semicolon and one space, exactly) separates. The form of an entry is `TYPE UUID` (one space between the type and the identifier), for example `REQ 1ca335d7-969a-443e-9392-165fdeea99a0; DEC 9edc1071-4fd0-48b6-a037-1a4cb2331f73`. The type is one of the types of document of the specmgr that the tag of reference uses with an identifier of the form UUID: `GOL`, `PRB`, `QA`, `UC`, `REQ`, `RSK`, `DEC`, `ADR`, `VCR`, `SYSRS`, `TXT`. The gate for the traceability reads the property in Phase 150 of feat-50-structurizr-model-rules. The old property `specmgr-req` (the identifier bare, that the character comma separates) keeps working for one release (the compatibility of Phase 150).

### The language skew (the result of the spike of Phase 100)

The tools of the two sides do not behave the same. ArchUnit examines the bytecode (the compiled classes of the package `code.root`). ArchUniTS examines the TypeScript source (the files that the tsconfig of the module includes). The comparison (`frontend/architecture/compare.mjs`) examines the source with the compiler of the pinned package typescript. The spike of Phase 100 (2026-11-17) gives these facts:

| Behavior | ArchUnit (the backend) | ArchUniTS (the frontend) |
|---|---|---|
| The reference by type only (a method signature, a field type) | visible (the probe: the interface `StatusApi` references the class `Status` only in the return type, and ArchUnit counts the dependency) | visible (the probe: the construct `import type` gives the dependency, and `compare.mjs` counts it too) |
| The dynamic import | no such form in Java; a dependency by reflection or by injection is not visible | invisible (ArchUniTS reads only the import declarations; the probe: the construct `await import()` gives no dependency) |
| The construct `require()` | n/a | `compare.mjs` stops (exit code 2); ArchUniTS does not see it |
| The construct `export ... from` | n/a | `compare.mjs` counts it as a dependency; ArchUniTS does not see it |
| A component with several packages or folders | the list form is supported (the predicate `resideInAnyPackage` of ArchUnit, verified in the probe) | the list form is supported with a pattern of the type RegExp (the probe); the list form of a text glob `(a|b)` is not supported (minimatch escapes the parentheses: no file matches) |
| A unit that disappears | the class of the package is missing; the comparison names the component without a package | the rule gives the violation "No files found matching pattern(s)" (the option allowEmptyTests is false by default) |

- The spike of Phase 100 (the dated record of the probe): the header of the script `frontend/architecture/compare.mjs` of the day said that a dynamic import stops the script, and the probe showed that this is not the case with the pinned typescript 5.9.3 (the construct `import()` is silently ignored: its expression in the AST is the token `import`, and not an identifier; the check of the script tests for an identifier; the construct `require()` stops the script, as the header says). A dynamic import across a unit boundary is invisible to both tools of the frontend of the day (the runner of ArchUniTS reads only the import declarations, and the analyzer ignores the construct `import()` silently). Phase 130 of feat-50-structurizr-model-rules (Task 130.130, the Updates entry of 2026-11-18 of this decision) fixed the defect of the analyzer: the script `compare.mjs` reads the construct `import()` and the construct `require()` with the same resolution as the static imports. The limit of ArchUniTS (the tool does not see the constructs) is unchanged, and no rule of the runner can cover the constructs: the analyzer is the closed world for them.

## Updates

<!-- Newest entry first -- prepend new entries directly below this comment. -->

### 2026-11-18 02:56:00.000Z - The fix of the dynamic import (Phase 130 of feat-50-structurizr-model-rules)

Task 130.130 of feat-50-structurizr-model-rules fixes the defect of the spike recorded above: the script `frontend/architecture/compare.mjs` reads the construct `import()` and the construct `require()` as dependencies with the same resolution as the static imports (an internal specifier resolves to a file of the units, an external specifier is checked against `code.allowedExternal`, and a specifier that does not resolve stops the script, exit code 2). The row "The construct `require()`" of the table of the spike (the behavior of `compare.mjs` before the fix) is the dated record of the probe, and it stays. Two facts of the run of Phase 130 (recorded in the section "The rules the model gives" of `model/README.md`): the graph of the runner of the frontend (ArchUniTS) has no edge to the external packages (the folder `node_modules` is excluded from the graph of the tool), so the check of `code.allowedExternal` is in the analyzer `compare.mjs`, and not in the runner; and the cycle of the rule set (the group of the cycle rule) is possible with both tools (the pinned ArchUniTS has the construct `haveNoCycles`). The forms of this decision stay unchanged, and the decision stays draft (the owner accepts it in the review of the pull request).

### 2026-11-17 20:05:00.000Z - The fit to the components of feat-9 (Phase 120 of feat-50-structurizr-model-rules)

Phase 120 (Task 120.100) checks the conventions against the plan of feat-9-walking-skeleton (the status `review`; the code of the feature is done on the branch `feat-9`). This draft named the components as "the status service, the adapter, the persistence"; the plan of feat-9 names the actual structure: the product code of the backend is one top-level package `biz.dfch.specmgrdemo.app` (the component `app`), and the product code of the frontend is the four units `client`, `i18n`, `telemetry` and `ui` (and the entry point `src/main.tsx` lies in the unit `root`). The forms of this decision cover that structure without a change: the form of one entry and the form of several entries of `code.package` and of `code.path` (the unit `root` takes the form of several entries for the two files that lie in `frontend/src`), the package with the prefix `@` in `code.allowedExternal` (the one entry `@opentelemetry` allows the imports whose name starts with the entry and the character `/`), the direction of the arrow (the relation `app -> api`, where the controllers implement the generated interfaces, is the case of the interface that this decision names), and the Information view for the data-ownership case (the data of the contract is owned by the components `types` and `zod`, and the unit that uses the data, `client`, depends on the owners). The Decision Drivers and the Consequences name the actual components now (this correction). The addition of the components to the model stays deferred (Task 120.110, the owner decision of 2026-11-17); the record of the fit, and the content for the follow-up, are in the plan of feat-50.

### 2026-11-17 11:35:00.000Z - Draft written

The first version of this decision is written, with the result of the spike of Phase 100 of feat-50-structurizr-model-rules (the language skew). The owner accepts the decision in the review of the pull request of the feature.
