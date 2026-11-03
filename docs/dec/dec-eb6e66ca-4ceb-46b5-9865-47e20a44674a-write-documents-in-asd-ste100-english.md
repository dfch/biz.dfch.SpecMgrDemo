---
classification: null
created: '2026-11-02T14:43:28.229+01:00'
id: eb6e66ca-4ceb-46b5-9865-47e20a44674a
status: draft
type: dec
updated: '2026-11-03T06:59:10.989+01:00'
version: 1.0.0
---

# Write Documents in ASD-STE100 English

## Context and Problem Statement

Requirements and policies must have one meaning. Free text can have more than one meaning. Coding agents and reviewers must receive the same information. The application must show its texts in EN, DE and FR.

## Decision Drivers

- A requirement must have one clear meaning.
- ASD-STE100 is only in English.
- Specmgr has language variants of documents. The French heading table is not available at this time (GitHub issue #4).
- The application must show its texts in EN, DE and FR. The first release uses EN only.

## Considered Options

- Write all specmgr documents in ASD-STE100 English. Make translations only for the texts of the application.
- Write requirements in STE and the explanations in free English.
- Write documents in free English.

## Decision Outcome

The project writes all specmgr documents in ASD-STE100 English. EN is the language of the project documents. Documents stay in EN. A translation of documents is not in the scope at this time. The texts of the application have translations (see the DEC about internationalization of the application).

### Consequences

- If a word is not approved in STE, it must be in the terminology register as a technical noun or a technical verb. Or the author must write the sentence again.
- A document must have no error in the STE check before the owner accepts it.
- A DE variant or an FR variant of a document is a translation of the EN source.

### Confirmation

A gate does the STE check on the text of each changed document. It shows each word that is not known. The pull request cannot merge if a word is not approved, is not in the register, and is not in a code span.

## Roles and Responsibilities

### Accountable

Project owner.

### Responsible

- Authors of documents.
- Maintainers of the terminology register.

## Tags

- process
- language
- ste

## Source

Planning session of 2026-11-02.

## Related Artifacts

### Goals

- GOL fde907fd-6fa5-4d87-b0ce-10babc0b4562: Make Software of High Quality

## More Information

The asdste100 MCP gives the rules and the words of ASD-STE100. It loads the terminology register as an extra word list. Authors and reviewers use the MCP to look up words and rules. They do not use a separate script for the STE check.

Rules 1.5 and 1.12 of ASD-STE100 let an author use technical nouns and technical verbs from the glossary of a company. Rule 1.12 tells an author to use an approved verb with a technical noun if it gives the same information. Rule 1.7 tells an author not to use a technical noun as a verb.

## Updates

<!-- Newest entry first -- prepend new entries directly below this comment. -->

### 2026-11-02 00:00:00.000Z - Draft written

The first version of this decision is written.
