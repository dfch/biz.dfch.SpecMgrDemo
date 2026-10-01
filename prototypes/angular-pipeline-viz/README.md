# angular-pipeline-viz

Spike prototype: renders the shared mock CI/CD pipeline DAG
(`src/app/pipeline-dag.mock.ts`, canonical copy at
`prototypes/shared/pipeline-dag.mock.ts`) as an interactive graph in
Angular. Part of `feat-2-react-angular-visualization-spike`
(`.specmgr/feat/feat-2-react-angular-visualization-spike/README.md`).

This project was originally generated using
[Angular CLI](https://github.com/angular/angular-cli) 19.2.27.

## Run it

```bash
npm install && npm run build && npx http-server dist/angular-pipeline-viz/browser -p 4322
```

Then open `http://localhost:4322/`. For a dev server with live reload
instead, use `npm install && npm start` and open
`http://localhost:4200/`.

## What's rendered

- All 12 jobs from the shared mock dataset as SVG nodes (`#nodeTemplate`),
  positioned by ngx-graph's built-in `dagre` auto-layout (left-to-right
  orientation) — no manual positioning was written. Because the dataset's
  dependency edges flow in the same direction as pipeline stage order, the
  resulting rank columns naturally line up with `stage`.
- All 14 `dependsOn` edges as directed connections (`#linkTemplate` +
  marker-end arrowhead, via `#defsTemplate`).
- A color/border-coded legend + matching node styling for all 5 `status`
  values (`success`/`failed`/`running`/`pending`/`skipped`), see
  `src/app/pipeline-dag.component.css` (deliberately mirrors the color
  choices in the React prototype's `PipelineDag.css` for a fair visual
  comparison).
- Pan (drag the background) and zoom (scroll/pinch, plus the on-canvas
  zoom/fit/center controls) via ngx-graph's built-in viewport (`enablePan`,
  `enableZoom`, `autoZoom`, `autoCenter`, `panOnZoom` inputs).

## Library used

[`@swimlane/ngx-graph`](https://github.com/swimlane/ngx-graph) v13 — the
plan's Design Notes called this "the closest Angular analogue to
react-flow". It needed `@angular/cdk` and `@angular/animations` as peer
dependencies (both pinned to `^19.2.0` to match the scaffolded Angular
core version); no fallback to another candidate (PrimeNG/AG Grid/custom
CDK drag-drop) was necessary.

## Friction encountered

- **Peer dependency version pinning**: a plain
  `npm install @swimlane/ngx-graph @angular/cdk @angular/animations`
  resolved `@angular/animations` to v22 (latest) instead of matching the
  already-installed Angular 19 core, causing an `ERESOLVE` conflict.
  Fixed by explicitly pinning `@angular/cdk@^19.2.0 @angular/animations@^19.2.0`
  to match the scaffold's existing `@angular/core@^19.2.0`.
- **Public TypeScript types are not importable**: `Node`/`Edge`/`Graph`
  interfaces are used in `GraphComponent`'s public `@Input` signatures but
  are *not* re-exported from the package's bundled `.d.ts` (its single
  rollup-generated `export { ... }` statement omits them). In practice this
  means you cannot `import type { Node, Edge } from '@swimlane/ngx-graph'`
  — you have to either rely on TypeScript's structural typing (pass plain
  object literals / inferred-type arrays, as this prototype does) or
  declare your own locally-shaped interfaces. Minor papercut, not a
  blocker.
- **`provideAnimations()` wiring**: `@angular/animations` is a hard peer
  dependency of ngx-graph even though this prototype's usage path doesn't
  appear to need Angular animation triggers directly; added
  `provideAnimations()` to `app.config.ts` defensively (no runtime error
  was observed either way, but this is the documented safe default).
- **Build warnings, not errors**: `ng build` succeeds but prints two
  warnings worth noting for Phase 300: (1) the initial bundle (~543 KB)
  exceeds the CLI's default 500 KB budget by ~43 KB — almost entirely
  `dagre`/`webcola`/`d3-*` transitively pulled in by ngx-graph; (2) `dagre`
  and `webcola` are flagged as non-ESM (CommonJS) dependencies, which can
  disable some build optimizations. Neither blocks the build or the
  rendered output.
- **`npm audit` reports 31 vulnerabilities** (mostly moderate/high) in
  ngx-graph's transitive dependency tree (old `d3-*`/`webcola`/`dagre`
  releases). Not investigated further for this throwaway spike, but a
  real adoption decision should weigh this against react-flow/xyflow's
  dependency footprint.
- Everything else (custom node/edge SVG templates, per-status CSS, the
  legend, and pan/zoom config) was straightforward declarative
  `@Input`/content-template wiring, no further surprises.

## Verification performed

Static build succeeded (`ng build`), and the built `dist/.../browser`
output was also driven headlessly with Playwright/Chromium (downloaded on
demand, not a project dependency) behind a plain static file server:
confirmed 12 `.status-node` elements, 14 `.pipeline-dag__edge-line`
elements, 5 legend chips, a changing SVG `transform` matrix on the graph's
root `<g>` after a drag (pan) and after a wheel event (zoom scale
0.5 → 0.55), and zero browser console/page errors.
