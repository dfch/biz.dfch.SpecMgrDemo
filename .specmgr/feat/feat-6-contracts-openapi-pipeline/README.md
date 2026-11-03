---
classification: null
created: '2026-11-03T07:53:51.955+01:00'
id: feat-6-contracts-openapi-pipeline
status: planning
type: feat
updated: '2026-11-03T07:53:51.955+01:00'
version: 1.0.0
---

# Feature: Contract Pipeline with OpenAPI

## Plan

### Overview

This feature makes the pipeline for interfaces. The OpenAPI file is the source of truth for the interfaces between the backend and the frontend. The pipeline has a linter, a check for breaking changes, generators for the server interfaces and for the client schemas, and a gate that compares the generated code with the code in the repository. Two small modules show that the pipeline operates: one Maven module and one pnpm module. They have no product code. GitHub issue #6 is for this feature. The feature is planned and not started.

### Requirements

- REQ-001: The OpenAPI file in `contracts/` must be the only source for interfaces. A change to an interface must start in this file.

- REQ-002: A linter must examine the OpenAPI file in each pull request.

- REQ-003: A tool must find breaking changes against the main branch.

- REQ-004: The build must make the Spring server interfaces and the Zod schemas from the OpenAPI file.

- REQ-005: CI must make the generated code again and must stop the pull request if the result is not the same as the code in the repository.

- REQ-006: Errors must use RFC 9457 Problem Details. The error codes must be the same for all languages.

- REQ-007: Each tool must have a license check before the project uses it. If a license is not clear, the work stops and the owner makes a decision.

- REQ-008: Each operation in the OpenAPI file must have the specmgr identifier of its requirement in an `x-` extension.

### Acceptance Criteria

- [ ] ACC-001: `contracts/` has an OpenAPI file with a minimum of one operation and the error schema for Problem Details.

- [ ] ACC-002: `just` has recipes for lint, breaking-change check and code generation, and CI starts only these recipes.

- [ ] ACC-003: A change to the OpenAPI file that removes a field causes a failure of the gate for breaking changes.

- [ ] ACC-004: A change by hand to a generated file causes a failure of the gate for generated code.

- [ ] ACC-005: The Maven module and the pnpm module compile with the generated code.

- [ ] ACC-006: Each tool has an entry in the license table of this plan with the result of the check.

### Scope

#### Included

- The OpenAPI file with one example operation and the error schema.

- Spectral, `oasdiff`, the server generator and the Zod generator (the tools are not selected at this time, see the license table).

- The gate for generated code.

- Two modules without product code.

#### Explicitly Out Of Scope

- The layout, the `justfile` and the CI workflow (feat-5-foundation-monorepo-ci).

- Test tools, mutation tools and architecture tools (feat-7-verification-architecture-tools).

- The interfaces of the canteen application (the walking skeleton).

### Dependencies

#### Depends On

- feat-5-foundation-monorepo-ci: it gives the layout, the `justfile`, the CI workflow and the tools on the machine.

#### Blocks

- feat-7-verification-architecture-tools

### Design Notes

The DEC about interfaces names these possible tools: Spectral (linter), oasdiff (breaking changes), openapi-generator (server interfaces) and a Zod generator for the client. The DEC states that the skeleton must make sure that each tool and its license are correct. This feature does that check. If a tool is not successful in the check, the owner selects a different tool or makes a DEC about the deviation.

The DEC about the architecture gives the rule that the code obeys the model. The OpenAPI operation has the identifier of its requirement, and the traceability script (a subsequent feature) reads it.

License table (the agent fills it from the license file of each tool and not from memory):

| Tool | Use | License | Result |
|---|---|---|---|
| Spectral | linter | not checked | open |
| oasdiff | breaking changes | not checked | open |
| openapi-generator | server interfaces | not checked | open |
| Zod generator (not selected) | client schemas | not checked | open |
| Zod | runtime library | not checked | open |
| Jakarta Bean Validation and the implementation | runtime library | not checked | open |

### Related Decisions

- DEC f92e35a1-77a2-4749-917f-bf9b644e8ddd: Write Interfaces First in OpenAPI and Use Layers for Validation
- DEC f21920d2-4da5-4cf7-bd94-2e9bcba77342: Use Specmgr Identifiers for Traceability
- DEC 84c37f7d-08cb-457d-8ab3-1db37dba9bc9: Use Only Open Source Libraries That Are Compatible With AGPL-3.0-only
- DEC 361678a6-f941-473b-a058-1ba2bacf7d3d: Use a Test Pyramid and Blocking Gates for Verification
- DEC 870244cf-9bea-46bf-8ff2-fe030325743d: Use a Monorepo with Maven, pnpm, just and GitHub Actions

### Task List

#### Phase 100: License Checks

- [ ] Task 100.100: Read the license file of each tool in the license table, and write the result. Stop and tell the owner if a license is not clear

#### Phase 110: OpenAPI Source and Lint

- [ ] Task 110.100: Write the OpenAPI file with one example operation, the Problem Details schema and the `x-` extension for the requirement identifier

- [ ] Task 110.110: Add the linter with its rules and the `just` recipe

- [ ] Task 110.120: Add the check for breaking changes against the main branch and the `just` recipe

#### Phase 120: Generators

- [ ] Task 120.100: Make the Maven module and the generation of the Spring server interfaces

- [ ] Task 120.110: Make the pnpm module and the generation of the Zod schemas

- [ ] Task 120.120: Write the `just` recipe that makes all generated code again

#### Phase 130: Gates

- [ ] Task 130.100: Write the gate that compares the generated code with the code in the repository

- [ ] Task 130.110: Add the lint gate, the gate for breaking changes and the gate for generated code to the CI workflow

- [ ] Task 130.120: Test each gate with a change that must cause a failure, and write the results in this plan

#### Phase 140: Review

- [ ] Task 140.100: The owner examines the license table and the open items

## Progress

### Current Status

**As of 2026-11-03**: The plan is written. Work has not started. This feature waits for feat-5-foundation-monorepo-ci.

### Blockers

- feat-5-foundation-monorepo-ci must give the layout, the `justfile` and the CI workflow first.

### Updates

<!-- Newest entry first -- prepend new entries directly below this comment. -->

#### 2026-11-03 00:00:00.000Z - Plan written

The plan is written from the planning session of 2026-11-03.

### Decisions Made

<!-- Newest entry first -- prepend new entries directly below this comment. -->

#### 2026-11-03 00:00:00.000Z - Own feature for the contracts

The contract pipeline is a different feature (issue #6), because it depends on the foundation and has a pull request for it.

### Related PRs / Commits

- [Issue #6](https://github.com/dfch/biz.dfch.SpecMgrDemo/issues/6): this feature.

### More Information

The first design issue is GitHub issue #1.
