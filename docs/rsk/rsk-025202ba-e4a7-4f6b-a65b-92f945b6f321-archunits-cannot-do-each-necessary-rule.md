---
classification: null
created: '2026-11-02T14:45:23.225+01:00'
id: 025202ba-e4a7-4f6b-a65b-92f945b6f321
status: open
type: rsk
updated: '2026-11-02T15:14:59.121+01:00'
version: 1.0.0
---

# ArchUniTS Cannot Do Each Necessary Rule

## Cause

ArchUniTS is a new tool. The project does not know its maturity.

## Trigger

A rule about architecture is not possible in ArchUniTS, or the tool has a defect.

## Consequence

The architecture of the frontend is not examined, or the project must use one more tool.

## Scope

- Architecture tests of the frontend

## Initial Assessment

### Probability 3

### Impact 3

## Strategy

reduce

## Mitigation

Write the same rules as in the backend with ArchUniTS in the skeleton. If a rule is not possible, write a DEC for one more tool.

## Residual Assessment

### Probability 2

### Impact 2

## Owner

Maintainer of the architecture.

## Tags

- architecture

## Source

Planning session of 2026-11-02. DEC 9edc1071-4fd0-48b6-a037-1a4cb2331f73.
