# React vs. Angular: CI/CD Pipeline Visualization Spike — Comparison

Spike for `feat-2-react-angular-visualization-spike`, feeding
`feat-1-frontend-technology-decision`. Both prototypes render the same
shared mock DAG (`prototypes/shared/pipeline-dag.mock.ts`: 12 jobs, 5
stages, 14 `dependsOn` edges, 5 status values) with pan/zoom and
per-status styling. Source: `prototypes/react-pipeline-viz/README.md`,
`prototypes/angular-pipeline-viz/README.md`, `git log`/`git show` on the
Phase 100/200 commits, and a direct read of `PipelineDag.tsx` vs.
`pipeline-dag.component.ts`/`.html`.

## Effort

Comparable overall, but the *shape* of the effort differed. React reached
a working render slightly faster because `@xyflow/react` needed almost no
configuration beyond a `nodeTypes` map and a small component — the
layout itself (stage columns, job rows) had to be hand-computed, but that
computation is ~15 lines and trivial for a 12-node DAG. Angular's
`@swimlane/ngx-graph` needed more setup *before* any pixels appeared
(resolving a peer-dependency conflict, pinning two extra packages, wiring
`provideAnimations()`), but once set up, layout was free (`dagre`
auto-layout, zero manual positioning code). Net effort was similar; React
front-loaded "write a tiny layout function", Angular front-loaded
"fight the dependency resolver once". Neither took more than a focused
session to reach a fully working, verified prototype.

## Ecosystem maturity / library fit

| | `@xyflow/react` | `@swimlane/ngx-graph` |
|---|---|---|
| Popularity/maintenance | Actively maintained, de-facto standard for React node-graph UIs (rebrand of React Flow); large user base | Smaller, slower-moving; last major (v13) wraps `dagre`/`webcola`/`d3-*`, not developed in-house |
| API ergonomics | Declarative `nodes`/`edges` arrays + a `nodeTypes` component map; idiomatic React | Declarative `[nodes]`/`[links]` inputs + `ng-template` content projection for SVG; idiomatic Angular, slightly more ceremony (`defsTemplate`/`nodeTemplate`/`linkTemplate`) |
| Pan/zoom/styling built-in | Yes — `<Background>`/`<Controls>`/`<MiniMap>` components, CSS-based node styling, zero extra config | Yes — `enablePan`/`enableZoom`/`autoZoom`/`autoCenter` inputs, CSS-based node styling, zero extra config |
| Auto-layout | None built in (by design) — must hand-layout or bring your own (e.g. dagre) | Built in (`dagre` layout mode ships with the package) |
| Documentation | Good quick-start, but the custom-node/`Handle` requirement is under-documented (see Friction) | Adequate but sparser; typings gap (below) isn't documented at all |
| Type-safety | Full `Node<T>`/`Edge`/`NodeProps<T>` generics, all importable | `Node`/`Edge`/`Graph` interfaces used in public `@Input`s but **not re-exported** from the bundled `.d.ts` — must fall back to structural typing |
| Bundle/dependency footprint | No npm audit findings reported in Phase 200; purpose-built package | `ng build` exceeds the 500 KB budget by ~43 KB (transitively via `dagre`/`webcola`/`d3-*`), two CJS/non-ESM warnings, **31 `npm audit` findings** (mostly moderate/high) in that same transitive tree |

For *this specific use case* — CI/CD DAG visualization — `@xyflow/react`
is the better-fitted, better-maintained, better-typed library. `ngx-graph`
works and ships the convenience of free auto-layout, but it is a thinner
wrapper around an older, heavier, CVE-bearing dependency chain (`dagre` +
`webcola` + multiple `d3-*` packages), and its own public API isn't fully
type-exported, which undercuts a key reason (type-safety/agent-authoring
reliability) feat-1 cares about.

## Friction encountered

| | React / `@xyflow/react` | Angular / `@swimlane/ngx-graph` |
|---|---|---|
| Install | Clean, single package, no conflicts | `ERESOLVE` peer-dependency conflict — `@angular/cdk`/`@angular/animations` had to be explicitly pinned to `^19.2.0` or they resolved to v22 and broke the install |
| Silent failure mode | **Yes, severe**: a custom node type that omits its own `<Handle>` elements renders nodes but silently drops *all* edges — no console warning, easy to miss from the quick-start docs | None observed |
| Type-safety | Full generics, all public types importable | `Node`/`Edge`/`Graph` not re-exported despite being used in public `@Input` signatures; worked around with structural typing |
| Build warnings | None | Bundle-budget overage (~543 KB vs. 500 KB) + two CJS/non-ESM warnings (non-fatal) |
| Security signal | None reported | 31 `npm audit` findings in the transitive tree (not investigated further, flagged for a real adoption decision) |
| Extra runtime wiring | None | `provideAnimations()` added defensively for the animations peer dep (no observed runtime failure either way) |

**Code shape/verbosity** (`PipelineDag.tsx`, 125 lines, one file vs.
`pipeline-dag.component.ts` + `.html`, 48 + 65 = 113 lines, two files —
comparable total length, different distribution): React keeps layout
*logic* (the hand-computed column/row positions) in TypeScript and node
*rendering* as a small JSX component — everything is "just a function
returning a value", which is easy to follow linearly. Angular has no
layout logic at all (delegated entirely to `dagre`) but trades that for
more declarative template surface area — three `ng-template`s
(`defsTemplate`/`nodeTemplate`/`linkTemplate`) with raw `svg:g`/`svg:rect`/
`svg:path` markup and Angular's `[attr.x]`/`{{ }}` binding syntax, which
reads a bit more like hand-rolled SVG authoring than React's JSX-as-
component approach. Styling in both cases is plain CSS with BEM-ish class
names and is essentially a wash. Overall: React's file is more
self-contained; Angular's split (component class + template) is idiomatic
Angular but means reading two files to understand one visual element.

## Recommendation

**Prefer React + `@xyflow/react`** for the pipeline-visualization surface
of the production app. The deciding factors, in order:

1. **Type-safety and agent-authoring reliability** (feat-1's own REQ-004
   criterion): xyflow's fully-exported generic types are more reliable to
   author against with a coding agent than a library whose own public
   `@Input` types aren't importable.
2. **Dependency/security footprint**: 31 audit findings and a
   budget-exceeding, partly-CJS transitive tree are real adoption-risk
   signal for `ngx-graph`, not just spike noise — a production app would
   inherit that risk on every `npm audit`/`npm update`.
3. **Fit for the specific use case**: both render a correct, interactive,
   styled DAG equally well visually, so this isn't a capability gap — it's
   a "which dependency tree do we want to own" call, and xyflow's is
   lighter and purpose-built.

This is not a blowout: Angular's auto-layout (free `dagre` layout vs.
hand-computed positions) is a genuine convenience that matters more as the
DAG grows past a dataset this small, and `ngx-graph`'s peer-dependency
pinning and CSS/audit warnings are all known, fixable, one-time costs, not
fundamental blockers. If feat-1's decision were already leaning Angular
for other organisational reasons, this spike would not be strong enough
evidence to override that — but absent such a reason, xyflow is the
better-evidenced choice.

**What this spike did not test** (important caveats for the DEC): no
large/real-time dataset (hundreds of nodes, live status updates via
WebSocket/polling), no actual Java backend integration, no accessibility
audit (keyboard nav, screen readers, ARIA on either graph), no
multi-developer day-to-day DX beyond a single implementation pass, and no
performance profiling under load. These should be flagged as explicit
residual risks/follow-ups in the DEC rather than assumed answered by this
spike.
