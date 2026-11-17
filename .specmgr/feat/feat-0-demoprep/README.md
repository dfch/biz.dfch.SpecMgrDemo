---
created: '2026-11-17T07:24:57.788+01:00'
id: feat-0-demoprep
status: progress
type: feat
updated: '2026-11-17T07:45:00.000+01:00'
version: 1.0.0
---

# Feature: Prepare the Technical Demo and the Presentation

## Plan

### Overview

The owner must give a technical presentation about this repository to the head of development, and the presentation is in about two hours. This feature gives the material for it: a short presentation (PDF) with the strong points, a demo of the user interface, a view of the API specification, and a view of the C4 model with rules that come from the model.

All files of this feature are in the folder of the feature. The feature does not change a gate, the justfile, the workflows, the contract, the existing model `model/workspace.json`, or the existing architecture rules. It starts from the commit of feat-9 Phase 300 (`8f11e3e`) and does not wait for feat-9.

The scripts in `bin/` are the commands of the demo. Their names follow the form `<phase>-<task>-<nn>-<name>.sh` (the form of feat-20 of biz.dfch.LlmOps). The guide to the demo with the exact commands is the file `DEMO.md`.

### Requirements

- REQ-001: The feature has a hand-written Structurizr DSL model with a system context view, a container view and a component view of the backend and of the frontend. Each element has the properties `code.*` and, where a REQ exists, `specmgr-req`.
- REQ-002: The feature gives a static site of the model (`index.html`) and SVG images of its views. If the SVG export of Structurizr does not work, the PlantUML export is the fallback.
- REQ-003: The feature has architecture rules for ArchUnit (Java) and ArchUniTS (TypeScript) that come from the model (the closed-world forbidden dependencies), and a script that shows a violated rule.
- REQ-004: The feature has scripts in `bin/` that start the demo: the backend and the frontend, the backend with the error state, the API documentation, the model site, and the rules.
- REQ-005: The feature has screenshots of the user interface, of the API documentation and of the model, as files in the folder of the feature.
- REQ-006: The feature has a short presentation in Markdown (6 slides, English) with the strong points, the differences to other specification frameworks, and the weak points, and the PDF made from it.

### Acceptance Criteria

- [x] ACC-001: `bin/100-110-00-validate-model.sh` gives no error for `model/workspace.dsl`, and the exported JSON has the same components and relations as `model/workspace.json` of the repository for the elements that exist there (REQ-001).
- [x] ACC-002: `bin/110-100-00-export-model.sh` makes the static site with `index.html` and the SVG files of the views (REQ-002).
- [x] ACC-003: `bin/120-110-00-run-rules.sh` runs the generated rules in the code, and they pass. `bin/120-120-00-break-rule.sh` shows a failing rule with its message (REQ-003).
- [x] ACC-004: `bin/130-100-00-run-demo.sh` shows the user interface in a browser and `--fail` shows the error response (REQ-004).
- [x] ACC-005: `bin/130-120-00-serve-api-docs.sh` and `bin/130-130-00-serve-model-site.sh` serve the pages on the loopback address (REQ-004).
- [x] ACC-006: The folder `images/` has the screenshots (REQ-005).
- [x] ACC-007: `PRESENTATION.md` and `PRESENTATION.pdf` exist, and the PDF has 6 slides (REQ-006).
- [x] ACC-008: `just validate` and `just commit-check` pass for the branch.

### Scope

#### Included

- The DSL model, the exports, the generated rules, the scripts, the images, the presentation and the guide to the demo, all in the folder of this feature.
- The list of the strong points (in the presentation).

#### Explicitly Out Of Scope

- A change of a gate, of the justfile, of the CI, of the contract, or of the existing model and rules.
- The Structurizr DSL as the source of the repository (this is feat-50).
- A generator of the model from specmgr documents.
- A new dependency in the Maven module or the pnpm module. The presentation tool is not a dependency of the repository.
- The features feat-9, feat-48 and feat-50.

### Dependencies

#### Depends On

- feat-9-walking-skeleton, Phase 300 (commit `8f11e3e`): the user interface and the backend.
- feat-7-verification-architecture-tools: ArchUnit, ArchUniTS and the model comparison.

#### Blocks

- Nothing.

### Design Notes

- **No change outside of the folder.** The code runs from a copy of `backend/` and `frontend/` in `build/work` (not in git). The generated rules are copied into the copy and not into the code folders of the repository, and the demo of a violated rule adds its files to the copy only. The owner told the agent to not work in the code folders of the repository root.
- **Start of the backend.** The module has no executable jar and no plug-in that starts a class. The script compiles with `./mvnw compile`, makes the class path with `maven-dependency-plugin` (it is in the local Maven repository), and starts `biz.dfch.specmgrdemo.app.SpecMgrDemoApplication` with `java -cp`. It does not use the files of feat-9 Phase 400.
- **Ports.** The ports are 8180, 5273, 8091 and 8092. The usual port 8080 is in use on the machine of the author.
- **Model.** The model is a hand conversion of `model/workspace.json` with the components of feat-9. It is a small precursor of feat-50, and not a replacement of the JSON. The script of ACC-001 compares the two (the names and the relations, not the descriptions, which are shorter in the DSL for the readability of the views), so they cannot drift without a message.
- **Rules.** The generator makes 3 rules for ArchUnit (backend) and 41 for ArchUniTS (frontend). ArchUniTS does not see the form `export { x } from '...'` as a dependency (the demo of a violated rule uses an `import`).
- **Images.** The SVG export of Structurizr works with the playwright image against `structurizr local` (the URL is `/workspace/1/diagrams`). The PlantUML export is the fallback.
- **Presentation.** Marp makes the PDF with `npx` (no pin in the repository, the tool is outside of the code). Pandoc is the fallback.
- **Other frameworks.** The statements about other specification frameworks are the judgement of the author and not a check of their current versions. The slide says so.
- **Mistake of the agent.** The agent wrote the guide to the demo over this plan (the file `README.md`) and wrote the plan again from its own text. The guide is the file `DEMO.md`.

### Related Decisions

- DEC 9edc1071-4fd0-48b6-a037-1a4cb2331f73: The code must obey the Structurizr model.
- DEC f21920d2-4da5-4cf7-bd94-2e9bcba77342: Traceability by specmgr identifier.
- DEC 84c37f7d-08cb-457d-8ab3-1db37dba9bc9: Use only open source libraries that are compatible with AGPL (no new dependency in this feature).
- DEC d778d444-6227-4070-ae6e-b1083c78c58b: Keep dev and main free of local commits (the branch has the name of the feature).

### Task List

#### Phase 100: The Model

- [x] Task 100.100: Make `model/workspace.dsl` with the views and the properties.
- [x] Task 100.110: Make `bin/100-110-00-validate-model.sh` (validate, export JSON, compare with `model/workspace.json`).

#### Phase 110: Exports

- [x] Task 110.100: Make `bin/110-100-00-export-model.sh` (static site, SVG, PlantUML fallback).

#### Phase 120: Rules from the Model

- [x] Task 120.100: Make `bin/120-100-00-generate-rules.mjs` (reads the JSON, writes the ArchUnit and ArchUniTS rules).
- [x] Task 120.110: Make `bin/120-110-00-run-rules.sh`.
- [x] Task 120.120: Make `bin/120-120-00-break-rule.sh`.

#### Phase 130: The Demo Scripts

- [x] Task 130.100: Make `bin/130-100-00-run-demo.sh`.
- [x] Task 130.110: Make `bin/130-110-00-stop-demo.sh`.
- [x] Task 130.120: Make `bin/130-120-00-serve-api-docs.sh`.
- [x] Task 130.130: Make `bin/130-130-00-serve-model-site.sh`.

#### Phase 140: Images

- [x] Task 140.100: Make `bin/140-100-00-take-screenshots.sh` and the files in `images/`.

#### Phase 150: Presentation

- [x] Task 150.100: Write `PRESENTATION.md`.
- [x] Task 150.110: Make `bin/150-110-00-build-pdf.sh` and `PRESENTATION.pdf`.
- [x] Task 150.120: Write `DEMO.md` (the exact commands) and run each command once.

#### Phase 160: SBOM, Tools, Decisions

- [x] Task 160.100: Make `bin/160-100-00-show-sbom.sh`, `TOOLS.md` and the slides about the SBOM, the tools, and the DECs and RSKs.

## Progress

### Current Status

**As of 2026-11-17**: All tasks and all acceptance criteria are done (`just validate` and `just commit-check` pass). Nothing is pushed.

### Blockers

- None.

### Updates

<!-- Newest entry first -- prepend new entries directly below this comment. -->

#### 2026-11-17 07:00:00.000Z - SBOM, tools and DEC slides

The presentation has 9 slides now (the owner asked for the SBOM, the tools and the DECs and RSKs). One run of `just license-check` on this work tree stopped with NOT KNOWN for `vite` and `typescript` (the SBOM of cdxgen had no license for them), and an earlier run passed with 506 components. The cause is not examined. The gate stops, as it must.

#### 2026-11-17 06:45:00.000Z - Demo, images and presentation made

The model, the exports, the rules, the demo scripts, the images, the presentation and the guide to the demo are made. Each script ran once in this session. The rules gave 3 and 41 rules, all green on the code of feat-9 Phase 300, and the violated rules failed with the named dependency.

#### 2026-11-17 06:30:00.000Z - Created

The plan of the feature is written. The branch starts at the commit `8f11e3e` of feat-9.

### Decisions Made

<!-- Newest entry first -- prepend new entries directly below this comment. -->

#### 2026-11-17 06:30:00.000Z - Isolated demo in the folder of the feature

The owner decided that all items are in the folder of the feature, that the feature does not wait for feat-9, and that the scripts are in `bin/`.

### Related PRs / Commits

- None yet.
