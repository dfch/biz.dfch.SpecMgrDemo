---
classification: null
created: '2026-10-01T08:56:50.337+02:00'
id: feat-1-frontend-technology-decision
status: planning
type: feat
updated: '2026-10-01T10:10:25.913+02:00'
version: 1.0.0
---

# Feature: Frontend Technology Decision for Java Backend Web App

## Plan

### Overview

Design-phase feature tracking the evaluation and eventual decision of frontend technology (Angular vs. React, possibly others) for the Java-backed web application. Originates from gh #1 ("Initial design considerations").

### Requirements

- REQ-001: Backend must be Java (fixed organisational standard, no exception).

- REQ-002: Frontend must be a responsive, browser-based web app usable on desktop, tablet, and phone; no app-store/native/hybrid packaging required.

- REQ-003: Frontend must support a highly interactive, responsive UI, including rich CI/CD pipeline visualisation (e.g., DAG/graph-style views).

- REQ-004: The frontend technology choice must be justified on technical merit (ecosystem fit, coding-agent authoring reliability), not on undocumented personal preference.

### Acceptance Criteria

- [ ] ACC-001: A documented elicitation (QA) exists capturing REQ-001..004.

- [ ] ACC-002: A spike/prototype (tracked in feat-2) has been built and evaluated for React and Angular.

- [ ] ACC-003: A formal DEC records the final technology choice and rationale.

### Scope

#### Included

- Evaluation criteria definition, stakeholder elicitation (QA), coordination with the spike FEAT, authoring the eventual DEC.

#### Explicitly Out Of Scope

- Implementation of the production application itself.

- App-store/hybrid packaging (confirmed not required).

### Dependencies

#### Depends On

- feat-2-react-angular-visualization-spike: spike results are required before the Decision phase (Task 300.100) can proceed.

#### Blocks

- Production frontend implementation work (not yet tracked as a FEAT).

### Design Notes

Musk-Algorithm requirement analysis (conducted prior to this FEAT) found: Java is a verified, non-negotiable constraint. The "Angular preferred" mandate traces to one architect's personal familiarity with Angular, not to any documented organisational, hiring, tooling, or compliance need — it fails the Chesterton's Fence test. The one argument that could have rescued it (team familiarity) is voided by the coding-agent delivery model, which is equally fluent in React and Angular. The real deciding criterion is ecosystem fit for CI/CD pipeline/DAG visualisation (react-flow/xyflow, D3 vs. Angular CDK, ngx-graph), to be validated empirically via feat-2 before a DEC is drafted.

The empirical validation (feat-2-react-angular-visualization-spike) is now complete; see `prototypes/COMPARISON.md` for the full write-up. Both `@xyflow/react` and `@swimlane/ngx-graph` rendered an equally correct, interactive, styled pipeline DAG, so this was not a capability gap. The spike recommends React + `@xyflow/react`, on two grounds: (1) its public types are fully exported and generic, which is more reliable for coding-agent authoring (REQ-004) than ngx-graph, whose own `Node`/`Edge`/`Graph` interfaces are used in public `@Input`s but not re-exported from its bundled `.d.ts` — a durable, every-future-change cost, not a one-time one; (2) a friction-profile comparison that, taken together, tips modestly toward React: xyflow's one real defect (a custom node type silently drops all edges unless it defines its own `<Handle>` elements) is severe but one-time and now documented, whereas ngx-graph's friction is more structural (an `ERESOLVE` peer-dependency conflict on first install, plus the permanently non-exported types from reason 1). **Correction**: an earlier version of this paragraph also cited "31 `npm audit` findings in ngx-graph's transitive dagre/webcola/d3-* dependency tree" as a third, independent ground. That attribution was factually wrong and has been removed: re-running `npm audit` in `prototypes/angular-pipeline-viz` confirms all 31 findings (8 with `--omit=dev`) trace to the Angular 19 framework/CLI/build-tooling baseline itself (`@angular/core`, `@angular/cli`, `@angular/build`, `@babel/core`, `vite`, `webpack-dev-server`, etc.) — none are `dagre`, `webcola`, `d3-*`, or `@swimlane/ngx-graph`. Any Angular 19 CLI scaffold would carry this baseline regardless of whether ngx-graph is used, so it is not evidence about the two graph libraries themselves; it remains noted in `prototypes/COMPARISON.md` as a (correctly attributed) data point about Angular's tooling baseline, but no longer as a deciding factor in this recommendation. With that reason removed, the case for React rests on narrower but still real grounds (reasons 1 and 2 above); it is not a blowout. The recommendation is not a blowout for other reasons too — ngx-graph's built-in `dagre` auto-layout is a genuine convenience that was not needed on React's side only because the mock dataset is small — and the spike explicitly did not test large/real-time datasets, backend integration, accessibility, or multi-developer day-to-day DX, which should be carried into the DEC as residual risks/follow-ups rather than assumed answered.

### Related Decisions

- None yet; a DEC will be linked here once authored.

### Task List

#### Phase 100: Requirements & Elicitation

- [x] Task 100.100: Conduct structured Q&A capturing elicitation (-> QA doc)

- [x] Task 100.110: Document Musk-Algorithm requirement analysis (Design Notes)

#### Phase 200: Spike Coordination

- [x] Task 200.100: Create GH issue for spike/prototype

- [x] Task 200.110: Create FEAT for spike/prototype (feat-2), link here

- [x] Task 200.120: Review spike results and comparison summary (written back via feat-2 Task 300.110)

#### Phase 300: Decision

- [ ] Task 300.100: Draft DEC with final framework choice (blocked by feat-2)

## Progress

### Current Status

**As of 2026-10-01**: Design-phase FEAT created from gh #1. Musk-Algorithm requirement analysis complete; Chesterton's-Fence finding on the Angular mandate documented. Spike (feat-2) created to gather empirical evidence before the DEC.

### Blockers

None. The spike (feat-2) is complete and its results have been reviewed (Task 200.120); drafting the DEC (Task 300.100) is now a decision-authoring task, not blocked by missing data.

### Updates

<!-- Newest entry first -- prepend new entries directly below this comment. -->

#### 2026-10-01 00:00:00.000Z - Spike (feat-2) complete; React + xyflow recommended

feat-2-react-angular-visualization-spike finished Phase 300 (Evaluation) and wrote its findings back here (Task 200.120 reviewed, ticked done). One-line conclusion: both prototypes rendered a correct, interactive, styled pipeline DAG, but the spike recommends React + `@xyflow/react` over Angular + `@swimlane/ngx-graph` on type-safety/agent-authoring reliability and friction-profile grounds; full write-up at `prototypes/COMPARISON.md` and Design Notes above. The Decision phase (Task 300.100, drafting the DEC) is unblocked.

#### 2026-10-01 00:00:00.000Z - Corrected npm-audit misattribution in Design Notes and this Updates log

A post-implementation review found that this FEAT's Design Notes and this Updates entry both misattributed "31 `npm audit` findings" to "ngx-graph's transitive dagre/webcola/d3-* dependency tree". Re-running `npm audit` in `prototypes/angular-pipeline-viz` confirms all 31 findings (8 with `--omit=dev`) trace to the Angular 19 framework/CLI/build-tooling baseline itself (`@angular/core`, `@angular/cli`, `@angular/build`, `@babel/core`, `vite`, `webpack-dev-server`, etc.) — none are `dagre`, `webcola`, `d3-*`, or `@swimlane/ngx-graph`. The Design Notes paragraph above and `prototypes/COMPARISON.md` have been corrected to attribute this accurately and to drop it as an independent deciding factor; the recommendation itself (React + `@xyflow/react`) is unchanged but now rests on two honestly-reweighted reasons (type-safety/agent-authoring reliability, and a friction-profile comparison) instead of three.

#### 2026-10-01 00:00:00.000Z - Clarified spike hand-off

Clarified Task 200.120 to explicitly depend on feat-2 Task 300.110's write-back, and updated the Blockers note accordingly, following a review of feat-2.

#### 2026-10-01 00:00:00.000Z - Created

FEAT created to track design/decision work for the frontend technology choice, following the Musk-Algorithm requirement analysis conducted on gh #1.

### Decisions Made

<!-- Newest entry first -- prepend new entries directly below this comment. -->

#### 2026-10-01 00:00:00.000Z - Deferred OTel and ISO 29148 scope

gh #1 was updated mid-analysis with two additional items (OpenTelemetry support, ISO/IEC/IEEE 29148-based requirements layering). Both are explicitly deferred and out of scope for this FEAT.

### Related PRs / Commits

- [Issue #1](https://github.com/dfch/biz.dfch.SpecMgrDemo/issues/1): parent design-considerations issue this FEAT tracks.

- [Issue #2](https://github.com/dfch/biz.dfch.SpecMgrDemo/issues/2): spike issue tracked by feat-2-react-angular-visualization-spike.

### More Information

gh #1 was updated after this FEAT's scope was set, adding two further items not addressed here: (1) OpenTelemetry (OTel) support for the application, and (2) designing requirements per ISO/IEC/IEEE 29148 (BRS, StRS, SyRS, SRS layering). Both are intentionally out of scope for this decision-tracking FEAT and are noted here only for traceability; they should be picked up as separate, future work.
