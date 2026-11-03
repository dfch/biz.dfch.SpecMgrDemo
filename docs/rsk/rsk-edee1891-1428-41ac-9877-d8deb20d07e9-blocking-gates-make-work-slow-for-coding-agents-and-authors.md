---
classification: null
created: '2026-11-02T14:45:27.431+01:00'
id: edee1891-1428-41ac-9877-d8deb20d07e9
status: open
type: rsk
updated: '2026-11-02T15:14:59.157+01:00'
version: 1.0.0
---

# Blocking Gates Make Work Slow for Coding Agents and Authors

## Cause

The project has eleven blocking gates from the first day. Some gates are slow.

## Trigger

A pull request has an error in a gate more than one time, or a gate uses much time.

## Consequence

The work is slow. Authors or agents can try to bypass a gate, or can decrease a threshold.

## Scope

- CI pipeline
- All pull requests

## Initial Assessment

### Probability 4

### Impact 3

## Strategy

reduce

## Mitigation

Start the fast gates first. Operate the same gates locally with `just`. Keep the results in a cache. A bypass is not permitted. Examine the time of each gate each month. A code owner must accept a change to a threshold.

## Residual Assessment

### Probability 3

### Impact 2

## Owner

Maintainer of the gates.

## Tags

- ci

## Source

Planning session of 2026-11-02. DEC 361678a6-f941-473b-a058-1ba2bacf7d3d.
