---
classification: null
created: '2026-11-02T14:45:29.492+01:00'
id: 5dfbf884-0ba4-4ecc-b97e-191aca335b98
status: open
type: rsk
updated: '2026-11-02T15:14:59.174+01:00'
version: 1.0.0
---

# Specmgr Has No French Heading Table and No SRS Type

## Cause

Specmgr has no `fr.json` heading table. Specmgr has no document type for the software level (SRS) of ISO/IEC/IEEE 29148.

## Trigger

The project must make a French variant of a document, or an SRS document.

## Consequence

A French document is not possible. The SRS level uses one SYSRS for each software item.

## Scope

- Specmgr
- All documents

## Initial Assessment

### Probability 3

### Impact 2

## Strategy

accept

## Mitigation

None. GitHub issue #4 is about the French table. The DEC about the ISO 29148 levels gives the solution for the SRS level. Documents stay in EN.

## Residual Assessment

### Probability 3

### Impact 2

## Owner

Project owner.

## Tags

- specmgr

## Source

Planning session of 2026-11-02. GitHub issue #4.
