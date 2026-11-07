---
classification: null
created: '2026-11-02T14:45:15.034+01:00'
id: 95b6735b-03b8-47a0-92aa-7934a4ff1519
status: draft
type: sop
updated: '2026-11-02T15:17:51.921+01:00'
version: 1.0.0
---

# Add a Requirement With Traceability

## Purpose

This SOP gives the procedure to add a requirement. The requirement has a level, a source, a link to a goal and a verification case record.

## Scope

This SOP is for new REQ documents. It is not for changes to the gates.

## Definitions

- **REQ**: the specmgr document type for a requirement.
- **VCR**: the specmgr document type for a verification case record.
- **Level**: the level of ISO/IEC/IEEE 29148 of the requirement.

## Roles and Responsibilities

### Accountable

Project owner.

### Responsible

- Author of the requirement.

### Consulted

- Reviewer.

## Safety and Precautions

Do not put text from a document with the classification VERTRAULICH or GEHEIM into an external service.

## Procedure

### Step 1: Find a requirement with the same meaning

Examine the repository for a requirement with the same meaning. If it is there, change it. Do not add a copy.

### Step 2: Write the requirement

Make the REQ. Write the statement in ASD-STE100. Set the requirement level (MUST, SHOULD, MUST NOT, SHOULD NOT or MAY), the priority, the source and one or more ISO/IEC 25010 characteristics. Add one tag in the format `iso29148:strs`, `iso29148:syrs` or `iso29148:srs`.

### Step 3: Add the link to the goal

Add a link to one or more goals in the section Related Artifacts.

### Step 4: Make the verification case record

Make a VCR for the requirement. Give the name of the automatic test in the VCR.

### Step 5: Add the requirement to a SYSRS

Add the requirement to the SYSRS of the system or of the software item. Put it in the part for its characteristic.

### Step 6: Do the checks

Do the validation of the documents, the STE check and the traceability check. Correct each error. Open the pull request when no gate shows an error.

## Related Artifacts

### Decisions

- DEC 00a85fb8-19a2-4850-bf5f-4a18e47d46e9: Use One Mapping of ISO 29148 Levels to Specmgr Artifacts
- DEC f21920d2-4da5-4cf7-bd94-2e9bcba77342: Use Specmgr Identifiers for Traceability
- DEC eb6e66ca-4ceb-46b5-9865-47e20a44674a: Write Documents in ASD-STE100 English

### Goals

- GOL b94e2758-3368-407e-8fee-827c897e192b: Show the Goal and the Test of Each Requirement

## Updates

### 2026-11-02T14:17:51.797Z - Draft written

The first version of this SOP is written.
