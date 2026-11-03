---
classification: null
created: '2026-11-02T14:43:12.143+01:00'
id: 00a85fb8-19a2-4850-bf5f-4a18e47d46e9
status: draft
type: dec
updated: '2026-11-02T15:17:51.636+01:00'
version: 1.0.0
---

# Use One Mapping of ISO 29148 Levels to Specmgr Artifacts

## Context and Problem Statement

ISO/IEC/IEEE 29148 gives four levels of requirements: business (BRS), stakeholder (StRS), system (SyRS) and software (SRS). Specmgr has no document type for each level. The project must have one clear mapping.

## Decision Drivers

- Each requirement must show its level.
- Specmgr has no SRS document type.
- QA documents have the nine ISO/IEC 25010 categories for all four levels.
- A script must examine the mapping.

## Considered Options

- Use a REQ tag for the level and a QA title prefix for the level of the interview.
- Use the REQ field classification for the level.
- Use only SYSRS and do not use the stakeholder level.

## Decision Outcome

The project uses a REQ tag for the level and a QA title prefix for the level of the interview. Each REQ has one tag in the format `iso29148:strs`, `iso29148:syrs` or `iso29148:srs`. Specmgr has no SRS type. Until it has one, one SYSRS for each software item holds the requirements of the SRS level.

### Consequences

- The field classification does not show the level. It shows the data class (see the DEC about data classification).
- A script can show each REQ with its level.
- The project must remove the SYSRS solution when specmgr has an SRS type.

### Confirmation

A gate stops the pull request in each of these conditions. A REQ has no tag that starts with `iso29148:`. A REQ has more than one such tag. The value of the tag is not known. A REQ has no Source. A REQ has no entry for Characteristics.

## Roles and Responsibilities

### Accountable

Project owner.

### Responsible

- Maintainers of the gates.

## Tags

- process
- iso29148

## Source

Planning session of 2026-11-02.

## Related Artifacts

### Goals

- GOL b94e2758-3368-407e-8fee-827c897e192b: Show the Goal and the Test of Each Requirement

## More Information

| Level | Artifacts |
|---|---|
| BRS | GOL, PRB, and QA with the title prefix `BRS:` |
| StRS | QA with the title prefix `StRS:`, and REQ with the tag `iso29148:strs` |
| SyRS | SYSRS, REQ with the tag `iso29148:syrs`, and QA with the title prefix `SyRS:` |
| SRS | REQ with the tag `iso29148:srs`, and QA with the title prefix `SRS:` |

## Updates

<!-- Newest entry first -- prepend new entries directly below this comment. -->

### 2026-11-02 00:00:00.000Z - Draft written

The first version of this decision is written.
