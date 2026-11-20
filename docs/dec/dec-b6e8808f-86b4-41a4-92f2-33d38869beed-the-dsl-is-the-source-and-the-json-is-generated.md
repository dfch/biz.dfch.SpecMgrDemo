---
classification: null
created: '2026-11-17T11:02:06.338+01:00'
id: b6e8808f-86b4-41a4-92f2-33d38869beed
status: draft
type: dec
updated: '2026-11-17T11:02:06.338+01:00'
version: 1.0.0
---

# The DSL Is the Source and the JSON Is Generated

## Context and Problem Statement

Today the architecture model is the hand-maintained file `model/workspace.json` (9 elements, 4 relations, no views). The model must gain the views of the Rozanski & Woods viewpoints, the properties of the code mapping, and the references to the specmgr artifacts (feat-50-structurizr-model-rules). This content is far easier to write in the Structurizr DSL than in the JSON by hand. The project needs one file a person edits (the source) and one file the tools read (the interchange).

## Decision Drivers

- Goal: keep one source of truth for each fact (GOL 9ffb930c-44e8-4d0e-b4fd-f94c7162a894).
- The Node side cannot parse the DSL. Only the Java library `structurizr-dsl` parses the DSL, and the readers of the Node side (`frontend/architecture/compare.mjs` and the runner of the frontend) work in Node.
- One parse gives one result. The `!include`, the `!identifiers` and the constants of the DSL are resolved once, and the two sides of the comparison see the same model.
- The readers already exist. The backend reads the JSON with the class `JsonReader` of the artifact structurizr-client 6.2.4. The frontend reads the JSON with the strict reader of the script `frontend/architecture/compare.mjs`.
- A reviewer sees the resolved model in the diff of the pull request. A gate can compare the JSON with the DSL.
- The tool must be AGPL-compatible (DEC 84c37f7d-08cb-457d-8ab3-1db37dba9bc9).

## Considered Options

- The container `structurizr/structurizr` makes the JSON from the DSL (the option the owner prefers if it can convert, verified in Phase 100 of feat-50-structurizr-model-rules).
- The Java library `structurizr-dsl` 6.2.4 makes the JSON from the DSL (the confirmed fallback).
- The hand-edited JSON stays the source (rejected: the JSON is error-prone, and no tool validates the shape of the model in the JSON).
- The Structurizr MCP makes the JSON (rejected: the verified limit of Phase 100. The tools of the MCP are parse, validate, inspect, and the export to PlantUML, Mermaid and C4-PlantUML. The MCP gives no workspace JSON).

## Decision Outcome

The file `model/workspace.dsl` is the one file a person edits. The container `structurizr/structurizr` (the tag `2026.10.26-noble`, the digest `sha256:1081d615e7a539aee8b8360e36a58f42ff6412dd8f0e1b053134cb2c76ab2303`, the app Structurizr v2026.10.26) makes `model/workspace.json` from the DSL with the command `export -w <workspace.dsl> -f json -o <folder>`. The JSON is the interchange that the two readers consume. A gate stops for a JSON that is not up to date with the DSL (the gate is built in Phase 110, Task 110.120 of feat-50-structurizr-model-rules; the DEC mandates the gate, as the gate `check-generated` mandates the other generated code).

### Consequences

- The JSON stays committed. The readers and the gate compare with the committed file.
- Two runs of the generation make no change (the idempotence, verified in Phase 100: two runs of the probe give the same file).
- The license of the tool is Apache-2.0 (the class Permitted of DEC 84c37f7d-08cb-457d-8ab3-1db37dba9bc9). The pin is in `tools/versions.env` (the keys `STRUCTURIZR_IMAGE` and `STRUCTURIZR_IMAGE_DIGEST`, added in Phase 100).
- The step that makes the JSON must name the digest of the image, and not the tag.
- The generated JSON has the keys that the strict reader of the frontend does not know today (the top-level `properties`, the element key `perspectives`, the model key `deploymentNodes`). The strict reader accepts the three keys in Phase 110 of feat-50-structurizr-model-rules (the minimal extension, the record in the Decisions Made of the plan of that feature), and Phase 130 (Task 130.130) refactored the reading and the acceptance into the shared module `frontend/architecture/workspace.mjs`.
- The DSL must set `!impliedRelationships false`. The parser of the DSL adds implied relationships by default (verified in Phase 100: the declared relation of an external system to a container adds the implied relation of the external system to the software system), and the closed world must not allow a relation that the code does not have.
- The command `validate` of the container stops for a DSL that does not parse (verified in Phase 100), so the generation step has a syntax check without a second tool.

### Confirmation

The up-to-date gate operates as a `just` recipe and a CI job (Phase 110 and Phase 160 of feat-50-structurizr-model-rules). The recipe makes the JSON again from the DSL in a temporary folder, and stops if the result differs from the committed file. The verification of Phase 100 (the probe with two elements, one relation, one property and one view) shows the form of the output: the JSON has the same top-level shape as the file the reader knows today (the keys `configuration`, `description`, `documentation`, `id`, `model`, `name` and `views`, the ids of the elements as texts of digits), and the properties, the perspectives and the views come through.

## Roles and Responsibilities

### Accountable

Project owner.

### Responsible

- Maintainers of the model and of the architecture.

## Tags

- technology
- architecture
- structurizr

## Source

Planning session of 2026-11-16 (the transcript `session-feat-50-prep-c4-ses_e1b5.md` on the feat-50 branch), and the verification of Phase 100 of feat-50-structurizr-model-rules on 2026-11-17.

## Related Artifacts

### Decisions

- DEC 84c37f7d-08cb-457d-8ab3-1db37dba9bc9: Use Only Open Source Libraries That Are Compatible With AGPL-3.0-only

- DEC 9edc1071-4fd0-48b6-a037-1a4cb2331f73: Make Sure That the Code Obeys the Structurizr Model
  The tooling choice of that decision (ArchUnit and Spring Modulith for the backend, ArchUniTS for the frontend) stays. That decision gives no rule for the source of the model; this decision fixes it.

### Goals

- GOL 9ffb930c-44e8-4d0e-b4fd-f94c7162a894: Keep One Source of Truth for Each Fact

## More Information

The verification of Phase 100 (2026-11-17) gives these facts.

- The command of the generation (the probe of Phase 100, the image `structurizr/structurizr:2026.10.26-noble`): `export -w <file.dsl> -f json -o <folder>`. The output file is in the folder `<folder>`, and its name is the name of the input file without the part `.dsl` (the input `workspace.dsl` gives the file `workspace.json`).
- The digest of the image is `sha256:1081d615e7a539aee8b8360e36a58f42ff6412dd8f0e1b053134cb2c76ab2303` (the value of `RepoDigests` of `docker inspect`, verified on 2026-11-17). The pin is in `tools/versions.env` (the keys `STRUCTURIZR_IMAGE` and `STRUCTURIZR_IMAGE_DIGEST`).
- The app in the image is Structurizr v2026.10.26. The image bundles the artifacts of the structurizr 6.2.4 line (the jars `structurizr-client-6.2.4`, `structurizr-core-6.2.4` and `structurizr-dsl-6.2.4`, verified in the file `structurizr.war` of the image). The parent POM of the line `com.structurizr:structurizr:6.2.4` names the license "The Apache License, Version 2.0" (verified in the local Maven repository, the same artifact the build of the backend resolves). The line is the same as the artifact structurizr-client 6.2.4 that the backend already pins (the class Permitted, checked in Phase 100 of feat-7-verification-architecture-tools).
- The generated JSON has four additions to the shape the readers know today. First, the top-level key `properties` (the base64 text of the source DSL under the key `structurizr.dsl`, and the count of the inspection under the keys `structurizr.inspection.*`). Second, the element key `properties` gains the key `structurizr.dsl.identifier` for each element that has a variable of the DSL (the value is the bare name of the variable, for example `api`; the committed DSL has no `!identifiers` directive, and the property appears without it, a verified fact of Phase 110 of feat-50-structurizr-model-rules). Third, the element key `perspectives` (the list of the perspectives, the form `{ name, description, value }`). Fourth, the model key `deploymentNodes` (the deployment nodes of the model; the key appears once the DSL declares a deployment view, and the committed JSON has it for the node `host`; the content of the key is empty of containment, the limit recorded in the Updates entry of 2026-11-19).
- The parser of the DSL adds implied relationships by default. The probe of Phase 100 shows it: the declared relation of the external system to the container `backend` gives, by default, also the implied relation of the external system to the software system. The directive `!impliedRelationships false` removes the implied relation (verified). The DSL of the project must set the directive explicitly (Phase 110, Task 110.130).
- The command `validate` of the container exits with code 0 for a DSL that parses, and with code 1 (the error names the line) for a DSL that does not parse (verified).

## Updates

<!-- Newest entry first -- prepend new entries directly below this comment. -->

### 2026-11-19 22:30:00.000Z - The limit of the pinned exporter for the deployment content (the fix pass of the post-implementation review of feat-50-structurizr-model-rules)

Verified with the digest-pinned container (the image of this decision, the digest of `tools/versions.env`): the committed DSL declares the deployment environment "The environment" with the node `host` and the two containments of the node (the relations `host` -> `backend` and `host` -> `frontend`; the DSL declares 6 relations in total), but the generated JSON carries exactly 4 (the two deployment containments are not serialized: a minimal probe confirms that a workspace with one deployment node and one containment exports zero relationships of the containment, and the command `validate` passes). In the interchange, the deployment node `host` (the model key `deploymentNodes`) and the Deployment view (the view key `deploymentViews`) are empty of containment. The stable, recorded consequence: the JSON embeds the count of the inspection under the top-level property `structurizr.inspection.error` (the value 14; the command `inspect` names the causes, among them the empty deployment node and the empty deployment view), and two runs of the generation make the same file (the value is verified twice). The gate `just check-model-generated` asserts the value 14 in the committed file (a changed count stops the gate, and the message names the expected and the found value). The deployment content is documentation on the DSL side only, and the runner and the analyzers never read it (the closed world is unaffected: DEC e85e9685-0787-4dff-9ee5-9d46670e9ee4 does not compare the container-level and the deployment relations with the code). The Decision Outcome of this decision stays true (the JSON is the interchange; the limit is a property of the pinned tool, and it is recorded per the house pattern of dated Updates entries).

### 2026-11-17 09:25:00.000Z - Draft written

The first version of this decision is written, with the result of the verification of Phase 100 of feat-50-structurizr-model-rules (the container `structurizr/structurizr` gives the JSON from the DSL, the digest is pinned in `tools/versions.env`). The owner accepts the decision in the review of the pull request of the feature.
