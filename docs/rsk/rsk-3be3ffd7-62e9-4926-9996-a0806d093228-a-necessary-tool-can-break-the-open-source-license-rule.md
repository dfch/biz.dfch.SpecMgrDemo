---
classification: null
created: '2026-11-02T14:45:31.836+01:00'
id: 3be3ffd7-62e9-4926-9996-a0806d093228
status: open
type: rsk
updated: '2026-11-02T15:14:59.193+01:00'
version: 1.0.0
---

# A Necessary Tool Can Break the Open Source License Rule

## Cause

The project must use open source libraries that are compatible with AGPL-3.0-only. Some tools in the planned stack can have other terms. The project did not examine their licenses.

## Trigger

The license gate finds a tool or a library with a license that is not permitted or is not known.

## Consequence

The project must replace the tool. More time is necessary for the work.

## Scope

- All dependencies and tools in CI

## Initial Assessment

### Probability 3

### Impact 3

## Strategy

reduce

## Mitigation

Examine the license of each tool before the skeleton FEAT uses it. Operate the license gate from the first commit. Use only tools that obey the gate.

## Residual Assessment

### Probability 2

### Impact 2

## Owner

Maintainer of the license gate.

## Tags

- license

## Source

Planning session of 2026-11-02. DEC 84c37f7d-08cb-457d-8ab3-1db37dba9bc9.
