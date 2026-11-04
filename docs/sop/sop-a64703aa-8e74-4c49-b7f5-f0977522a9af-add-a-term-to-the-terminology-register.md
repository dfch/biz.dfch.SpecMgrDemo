---
classification: null
created: '2026-11-02T14:45:19.189+01:00'
id: a64703aa-8e74-4c49-b7f5-f0977522a9af
status: draft
type: sop
updated: '2026-11-02T15:17:51.940+01:00'
version: 1.0.0
---

# Add a Term to the Terminology Register

## Purpose

This SOP gives the procedure to add a technical noun or a technical verb to the terminology register. The STE check then accepts the term.

## Scope

This SOP is for English terms in documents. It is not for the texts of the application.

## Definitions

- **TN**: a technical noun, category TN1 to TN22.
- **TV**: a technical verb, category TV1 to TV4.
- **Gap log**: the list of words that the STE check did not accept. It is the file `terminology/en/gap-log.md`.

## Roles and Responsibilities

### Accountable

Project owner.

### Responsible

- Maintainer of the terminology register.

### Consulted

- Author who uses the term.

## Safety and Precautions

Examine the license of a source before you copy terms from it. The project license is AGPL-3.0-only. Do not copy glossary text that has limits of copyright. Write a new meaning. Do not copy it.

## Procedure

### Step 1: Write the sentence again

Use an approved word or an approved technical noun. A technical verb must be necessary. If a new sentence is possible, stop here.

### Step 2: Add the word to the gap log

Write the word, the document and the date in the gap log.

### Step 3: Make a decision

A maintainer makes the decision when the word occurs again in the gap log. The maintainer accepts the word as a TN or a TV. Or the maintainer rejects the word and gives an alternative.

### Step 4: Write the record

Add one record in JSONL format to a register file in `terminology/en/`. Set the name, the status, the type, the category, a short meaning and the source. Do not add a name two times.

### Step 5: Do the checks

Do the register check and the STE check. Load the word lists again in the asdste100 MCP.

## Related Artifacts

### Decisions

- DEC 9eade4ab-2f03-439b-b798-770e43154f8b: Keep a Terminology Register for Technical Nouns and Verbs
- DEC eb6e66ca-4ceb-46b5-9865-47e20a44674a: Write Documents in ASD-STE100 English

### Goals

- GOL 9ffb930c-44e8-4d0e-b4fd-f94c7162a894: Keep One Source of Truth for Each Fact

## Updates

### 2026-11-02T14:17:51.797Z - Draft written

The first version of this SOP is written.
