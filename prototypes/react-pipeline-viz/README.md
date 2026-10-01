# react-pipeline-viz

Spike prototype: renders the shared mock CI/CD pipeline DAG
(`src/pipeline-dag.mock.ts`, canonical copy at
`prototypes/shared/pipeline-dag.mock.ts`) as an interactive graph in React.
Part of `feat-2-react-angular-visualization-spike`
(`.specmgr/feat/feat-2-react-angular-visualization-spike/README.md`).

## Run it

```bash
npm install && npm run build && npm run preview
```

Then open the URL `vite preview` prints (default `http://localhost:4173/`).
For a dev server with HMR instead, use `npm install && npm run dev`.

## What's rendered

- All 12 jobs from the shared mock dataset as nodes, positioned in a static
  layout: stages are columns (`stage` index * fixed width), jobs within a
  stage are stacked rows. No auto-layout algorithm was needed for a dataset
  this small.
- All 14 `dependsOn` edges as directed connections (including the fan-out
  from `build-compile` and the two fan-ins).
- A color/border-coded legend + matching node styling for all 5 `status`
  values (`success`/`failed`/`running`/`pending`/`skipped`), see
  `src/PipelineDag.css`.
- Pan (drag the background) and zoom (scroll/pinch, plus on-canvas zoom
  controls) via the graph library's built-in viewport.

## Library used

[`@xyflow/react`](https://reactflow.dev/) (the current package name for what
used to be called React Flow), the candidate the plan's Design Notes called
"the natural choice" for this prototype. It was picked first and worked
without a fallback.

## Friction encountered

- `npm install @xyflow/react` and basic rendering of custom-styled nodes was
  straightforward (a `nodeTypes` map + a small React component).
- One real gotcha: a **custom node type must render its own
  `<Handle type="source">` / `<Handle type="target">` elements** (imported
  from `@xyflow/react`) for edges to visually attach to it. Without them,
  nodes and the edge container both render, edge `<path>` elements are
  simply never drawn and there's no console error or warning — it fails
  silently. This is easy to miss if you only skim the "basic example" docs,
  which use the library's default (handle-less-to-the-user) node type. Once
  the two `<Handle>` elements were added inside `StatusNode`, all 14 edges
  rendered correctly.
- No other blockers. Pan/zoom, the legend, and per-status styling were pure
  CSS + the library's default `<Background>`/`<Controls>`/`<MiniMap>`
  components — no extra configuration needed.

## Verification performed

Static build succeeded (`tsc -b && vite build`), and the built app was also
driven headlessly with Playwright/Chromium (downloaded on demand, not a
project dependency) against `npm run preview`: confirmed 12 `.status-node`
elements, 14 `.react-flow__edge-path` elements, 5 legend chips, a changing
`transform` on `.react-flow__viewport` after a drag (pan) and after a wheel
event (zoom), and zero browser console/page errors.
