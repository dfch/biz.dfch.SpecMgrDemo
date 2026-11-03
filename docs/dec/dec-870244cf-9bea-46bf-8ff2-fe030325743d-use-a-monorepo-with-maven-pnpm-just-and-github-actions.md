---
classification: null
created: '2026-11-02T14:44:12.788+01:00'
id: 870244cf-9bea-46bf-8ff2-fe030325743d
status: draft
type: dec
updated: '2026-11-02T15:17:51.779+01:00'
version: 1.0.0
---

# Use a Monorepo with Maven, pnpm, just and GitHub Actions

## Context and Problem Statement

The project has a Java backend and a TypeScript frontend. It also has models, contracts and documents. The project must have one repository layout, one build tool for each language and one entry point for local work and for CI.

## Decision Drivers

- The repository is a template. The layout must be easy to copy.
- Local work and CI must use the same commands.
- The code that a generator makes must be the same each time.

## Considered Options

- Maven, pnpm workspaces, just as task runner, GitHub Actions.
- Gradle, npm workspaces, Nx.
- One repository for each part.

## Decision Outcome

The project uses one monorepo. The backend uses Maven and the frontend uses pnpm workspaces. A `justfile` is the one entry point for local work and for CI. CI operates on GitHub Actions.

### Consequences

- A new author uses `just` commands and does not have to know the build tools.
- The skeleton FEAT must set the versions of the JDK and of Node to LTS versions.
- If one part changes, the gates of all parts that use it must operate.

### Confirmation

Each CI job starts a `just` recipe. A gate stops the pull request if a workflow has a build command that is not in the `justfile`.

## Roles and Responsibilities

### Accountable

Project owner.

### Responsible

- Maintainers of the gates.

## Tags

- technology
- build
- ci

## Source

Planning session of 2026-11-02.

## Related Artifacts

### Goals

- GOL 330a042f-8be7-4358-b451-25a4dfcba359: Make a Template for New Projects

## More Information

Planned layout: `backend/`, `frontend/`, `contracts/`, `model/`, `terminology/`, `tools/`, `docs/` and `.specmgr/`. The skeleton FEAT must make sure that the layout is correct.

## Updates

<!-- Newest entry first -- prepend new entries directly below this comment. -->

### 2026-11-02 00:00:00.000Z - Draft written

The first version of this decision is written.
