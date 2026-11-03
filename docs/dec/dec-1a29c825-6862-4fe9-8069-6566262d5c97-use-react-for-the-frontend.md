---
classification: null
created: '2026-11-02T14:44:08.220+01:00'
id: 1a29c825-6862-4fe9-8069-6566262d5c97
status: accepted
type: dec
updated: '2026-11-03T07:31:31.557+01:00'
version: 1.0.0
---

# Use React for the Frontend

## Context and Problem Statement

The project must have one frontend technology for the web application in a browser. Feature feat-1 has the task to select Angular or React. Feature feat-2 makes a prototype with each technology and compares them.

## Decision Drivers

- The application must operate on desktop, tablet and phone in a browser.
- The application must show graph views that a user can operate.
- Coding agents write most of the code. The library must give all types.
- The selection must have a cause in technology. A person who wants one technology does not give a cause.

## Considered Options

- React with `@xyflow/react`.
- Angular with `@swimlane/ngx-graph`.

## Decision Outcome

The project uses React with TypeScript for the frontend. The owner selected React on 2026-11-02. The spike gave the same result.

### Consequences

- `@xyflow/react` gives all types. This helps coding agents.
- A custom node that has no `Handle` elements shows no edges and gives no warning. A test must examine this condition.
- The library has no automatic layout. If the graphs become large, the project must add a layout library.

### Confirmation

The results of the spike are in `prototypes/COMPARISON.md`. The license gate must show no error for React and for each frontend library.

## Roles and Responsibilities

### Accountable

Project owner.

### Responsible

- Maintainers of the frontend.

## Tags

- technology
- frontend

## Source

Feature feat-1-frontend-technology-decision, task 300.100. Decision of the owner on 2026-11-02.

## Related Artifacts

### Goals

- GOL fde907fd-6fa5-4d87-b0ce-10babc0b4562: Make Software of High Quality

## Pros and Cons

### Option 1: React with xyflow

Good: the library gives all types, the maintenance is active, and it is easy to start. Bad: no automatic layout, and no warning for a custom node with no Handle.

### Option 2: Angular with ngx-graph

Good: the library has an automatic layout. Bad: the library does not make its types available for import. The first install shows an error about peer dependencies. The bundle is too large.

## More Information

The spike did not examine large data sets, data that changes with time, integration with the backend, accessibility, or the work of developers each day. These are open risks. The DEC about verification and the DEC about quality must include them.

## Updates

<!-- Newest entry first -- prepend new entries directly below this comment. -->

### 2026-11-03 00:00:00.000Z - Accepted

The project owner told the coding agent in the session of 2026-11-03: set the status of this DEC to accepted. The agent set the status because of this order. The order is for this DEC only and for one time.

### 2026-11-02 00:00:00.000Z - Draft written

The first version of this decision is written.
