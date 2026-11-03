---
classification: null
created: '2026-11-02T14:45:25.158+01:00'
id: f682b3fb-ef1d-48f3-9fef-1e9e5ff147f7
status: open
type: rsk
updated: '2026-11-02T15:15:07.673+01:00'
version: 1.0.0
---

# A Code Generator Can Cause Delay

## Cause

The project makes server interfaces and client schemas from the OpenAPI file with tools from other companies.

## Trigger

A generator has a defect, has no more maintenance, or changes its output.

## Consequence

The build stops, or the code that the generator makes changes with no cause. More time is necessary for the work.

## Scope

- Pipeline for contracts

## Initial Assessment

### Probability 3

### Impact 3

## Strategy

reduce

## Mitigation

Set the version of each generator. Compare the code that a generator makes with the code in the repository in CI. Keep the OpenAPI file as the only source. Then the project can replace the tool.

## Residual Assessment

### Probability 2

### Impact 2

## Owner

Maintainer of the backend.

## Tags

- contracts

## Source

Planning session of 2026-11-02. DEC f92e35a1-77a2-4749-917f-bf9b644e8ddd.
