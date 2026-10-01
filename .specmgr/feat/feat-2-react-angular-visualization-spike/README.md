---
classification: null
created: '2026-10-01T08:56:56.842+02:00'
id: feat-2-react-angular-visualization-spike
status: planning
type: feat
updated: '2026-10-01T09:49:07.130+02:00'
version: 1.0.0
---

# Feature: Spike: React vs Angular CI/CD Pipeline Visualization Prototype

## Plan

### Overview

Build minimal prototypes in React and Angular to visualize a representative CI/CD pipeline topology, validating ecosystem fit before finalizing the frontend technology choice tracked in feat-1-frontend-technology-decision.

### Requirements

- REQ-001: Render a representative CI/CD pipeline DAG (stages/jobs/dependencies) as an interactive graph using React (e.g., react-flow/xyflow, D3).

- REQ-002: Render an equivalent DAG view using Angular (e.g., Angular CDK drag-drop + custom rendering, ngx-graph).

- REQ-003: Both prototypes must be buildable/runnable by the coding agent without requiring additional human framework expertise beyond review.

- REQ-004: Both prototypes must support pan/zoom navigation and node-status styling (e.g., success/failure/running) on the rendered graph, using the same mock pipeline dataset (see Task 100.120) so the two implementations are directly comparable.

### Acceptance Criteria

- [ ] ACC-001: Both prototypes render a comparable pipeline graph with pan/zoom and node-status styling.

- [ ] ACC-002: A short written comparison documents effort, ecosystem maturity/library fit, and friction encountered per framework.

- [ ] ACC-003: Each prototype includes a documented single-command build/run procedure (e.g., a README) that an agent can execute without additional manual framework setup, verifying REQ-003.

### Scope

#### Included

- Throwaway/minimal prototype code for both frameworks.

- A single shared mock pipeline DAG dataset (stages/jobs/dependencies/status) used by both prototypes.

- A minimal README per prototype documenting the single-command build/run procedure.

- A written comparison summary.

#### Explicitly Out Of Scope

- Production-quality code or integration with the real Java backend (mock/static data is sufficient).

- Any additional frontend candidate beyond React and Angular.

### Dependencies

#### Depends On

- None blocking. This spike originates from feat-1-frontend-technology-decision, which defines the evaluation criteria (see Overview); feat-2 can proceed independently of feat-1's own task state.

#### Blocks

- feat-1-frontend-technology-decision (Task 200.120, Spike Coordination phase): the spike results must be reviewed before this task can be completed.

- feat-1-frontend-technology-decision (Task 300.100, Decision phase): the DEC cannot be drafted until this spike's comparison is complete.

### Design Notes

Candidate libraries — React: react-flow/xyflow, D3, AG Grid, Recharts. Angular: Angular CDK (drag-drop), ngx-graph, PrimeNG, AG Grid (Angular build).

### Related Decisions

- None yet.

### Task List

#### Phase 100: Setup

- [x] Task 100.100: Scaffold React prototype project

- [x] Task 100.110: Scaffold Angular prototype project

- [x] Task 100.120: Define common mock pipeline DAG dataset (stages/jobs/dependencies/status) shared by both prototypes

#### Phase 200: Implementation

- [x] Task 200.100: Implement pipeline DAG visualization in React using the shared mock dataset (Task 100.120), including pan/zoom and node-status styling

- [x] Task 200.110: Implement pipeline DAG visualization in Angular using the shared mock dataset (Task 100.120), including pan/zoom and node-status styling

#### Phase 300: Evaluation

- [ ] Task 300.100: Write comparison summary

- [ ] Task 300.110: Feed results back into feat-1 Design Notes / Related Decisions

## Progress

### Current Status

**As of 2026-10-01**: Phase 200 (Implementation) complete. Both prototypes render the full shared mock pipeline DAG (12 nodes, 14 edges, 5 distinct status stylings, a legend, and pan/zoom) and build cleanly; both READMEs document a single-command run procedure. Phase 300 (Evaluation) is next.

### Blockers

None yet.

### Updates

<!-- Newest entry first -- prepend new entries directly below this comment. -->

#### 2026-10-01T00:00:00.000Z - Phase 200 (Implementation) complete

Implemented the pipeline DAG visualization in both prototypes on top of the shared mock dataset from Phase 100, and both now render all 12 jobs as nodes, all 14 `dependsOn` edges as directed connections, a 5-value status legend with matching node styling, and support mouse/trackpad pan and zoom, verified headlessly with Playwright/Chromium (downloaded on demand into the sandbox, not added as a project dependency) against each app's production build, confirming node/edge/legend counts and a changing SVG/CSS transform after drag and wheel gestures with zero browser console errors in both cases. React (`prototypes/react-pipeline-viz/`) uses `@xyflow/react` as planned, laid out with a small hand-computed static layout (stage columns, job rows) rather than an auto-layout algorithm, with all 5 statuses styled via CSS on a custom node component; the one real piece of friction was that a custom xyflow node type renders no edges at all, with no console warning, unless it explicitly includes its own `<Handle>` elements for the edges to attach to, which was non-obvious from the quick-start docs and initially left all 14 edges silently un-rendered until fixed. Angular (`prototypes/angular-pipeline-viz/`) uses `@swimlane/ngx-graph` v13 as planned (no fallback needed), relying entirely on its built-in `dagre` auto-layout (left-to-right orientation) rather than a hand-computed layout, with per-status SVG styling via `#nodeTemplate`/`#linkTemplate` content templates; friction there included an `ERESOLVE` peer-dependency conflict requiring `@angular/cdk`/`@angular/animations` to be explicitly pinned to `^19.2.0` to match the already-scaffolded Angular 19 core (installing them unpinned resolved to Angular 22 and failed), the package's bundled `.d.ts` not actually re-exporting its own `Node`/`Edge`/`Graph` TypeScript interfaces despite using them in public `@Input` signatures (worked around via structural typing on plain object literals instead of named imports), and two non-fatal `ng build` warnings (an initial bundle ~43 KB over the CLI's default 500 KB budget, and `dagre`/`webcola` flagged as non-ESM/CommonJS) plus 31 `npm audit` findings in ngx-graph's transitive dependency tree (versus 0 for the React side's `@xyflow/react`), all of which are documented in the Angular prototype's README as raw material for the Phase 300 comparison rather than acted on further in this throwaway spike. Both prototype READMEs were rewritten to document the exact single-command install/build/run procedure (`npm install && npm run build && npm run preview` for React; `npm install && npm run build && npx http-server dist/angular-pipeline-viz/browser -p 4322` for Angular, or `npm start` for a dev server), satisfying ACC-003/REQ-003; leftover Vite/Angular starter boilerplate (default hero/logo assets, the starter counter button, the default Angular landing template) was removed from both apps' entry components since it was no longer relevant once the DAG view became the app's only content.

#### 2026-10-01T00:00:00.000Z - Phase 100 (Setup) complete

Scaffolded both prototypes under `prototypes/`. `prototypes/react-pipeline-viz/` is a Vite + React + TypeScript app, scaffolded non-interactively via `npm create vite@latest . -- --template react-ts` (create-vite 9.2.1, React 19.2.8, Vite 8.3.0, TypeScript ~6.0.2); `npm install` and `npm run build` (`tsc -b && vite build`) succeed. `prototypes/angular-pipeline-viz/` is an Angular CLI standalone scaffold (no routing, CSS styles, no SSR), scaffolded non-interactively via `npx @angular/cli@19 new . --routing=false --style=css --ssr=false --skip-git --defaults` (Angular CLI/core 19.2.27/19.2.0, pinned to major 19 because `@angular/cli@latest`, i.e. v22, requires Node >=22.22.3 while the available Node is v22.22.1); `npm install` and `npm run build` (`ng build`) succeed. Defined the shared mock pipeline DAG dataset for Task 100.120 / REQ-004 at `prototypes/shared/pipeline-dag.mock.ts` (the canonical source of truth): a representative CI/CD pipeline with 5 stages (build, test, security-scan, deploy-staging, deploy-prod), 12 job nodes, and 5 distinct `status` values (`success`, `failed`, `running`, `pending`, `skipped`). The DAG includes a genuine fan-out (`build-compile` feeds 4 downstream jobs, two parallel jobs each in `test` and `security-scan`) and fan-ins (`test-e2e` depends on 2 upstream jobs; `deploy-staging-deploy` depends on 3 upstream jobs), so it is not a straight line. Byte-identical copies of the data section live at `prototypes/react-pipeline-viz/src/pipeline-dag.mock.ts` and `prototypes/angular-pipeline-viz/src/app/pipeline-dag.mock.ts`, each with a header comment pointing back at the canonical file; a literal cross-package TypeScript import between the two independently-scaffolded apps was intentionally not attempted. No DAG rendering was implemented yet (that is Phase 200); both apps still show their default starter page. Each scaffold ships its own `.gitignore` excluding `node_modules`, `dist`, and `.angular/cache`; verified via `git status` that nothing generated is untracked-but-wanted.

#### 2026-10-01T00:00:00.000Z - Plan refined after review

Added REQ-004 (pan/zoom + node-status styling) and ACC-003 (build/run without manual setup); added Task 100.120 to define a shared mock pipeline dataset so both prototypes are directly comparable; clarified Dependencies (Depends On is non-blocking; Blocks now also references feat-1 Task 200.120).

#### 2026-10-01T00:00:00.000Z - Created

FEAT created to track the React-vs-Angular visualization spike referenced from feat-1-frontend-technology-decision.

### Decisions Made

<!-- Newest entry first -- prepend new entries directly below this comment. -->

#### 2026-10-01T00:00:00.000Z - No decisions yet

No decisions have been made for this spike yet.

### Related PRs / Commits

- [Issue #2](https://github.com/dfch/biz.dfch.SpecMgrDemo/issues/2): tracking issue for this spike.

### More Information

(none)
