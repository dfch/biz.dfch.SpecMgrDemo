---
classification: null
created: '2026-11-02T14:43:35.061+01:00'
id: 9eade4ab-2f03-439b-b798-770e43154f8b
status: draft
type: dec
updated: '2026-11-02T15:17:51.702+01:00'
version: 1.0.0
---

# Keep a Terminology Register for Technical Nouns and Verbs

## Context and Problem Statement

STE has a small set of approved words. Software projects use more terms, for example OpenAPI, Zod and mutation score. STE lets you use them only as technical nouns (TN) or technical verbs (TV). The project must have one location for them and one process to add them.

## Decision Drivers

- The asdste100 MCP loads word lists from JSONL files with the option `--file`.
- Three lists are loaded at this time: EARS, the CPRE glossary and RFC 2119.
- The project must record words that occur again and are not known.
- Other glossaries are available (for example CPRE and ISTQB). Some glossaries have limits of copyright.

## Considered Options

- A register in this repository, in the JSONL format of the asdste100 MCP.
- One register for all projects in a different repository.
- No register. Write each sentence again with approved words.

## Decision Outcome

The project keeps a terminology register in this repository, as JSONL files in the directory `terminology/en/`. Each record has the word format of the asdste100 MCP. The category is TN1 to TN22 or TV1 to TV4. Each record has a source and a meaning. The project writes the meanings. It must not copy the text of a glossary that has limits of copyright.

### Consequences

- The register is the source of truth for terms.
- The MCP configuration of each author must load the register files.
- The project must examine the license of each source list, because the project license is AGPL-3.0-only. IREB must agree in writing before the project stores text of the CPRE glossary.
- The owner has not accepted a record that an agent writes. The owner must examine it and accept it.

### Confirmation

A script validates the format of the register. Each record must have a source, a category, a status and a meaning. The script stops if two records have the same name.

## Roles and Responsibilities

### Accountable

Project owner.

### Responsible

- Maintainers of the terminology register.

## Tags

- process
- language
- terminology

## Source

Planning session of 2026-11-02.

## Related Artifacts

### Goals

- GOL 9ffb930c-44e8-4d0e-b4fd-f94c7162a894: Keep One Source of Truth for Each Fact

## More Information

Process for a word that is not known:

1. The STE check shows the word.
2. The author writes the sentence again, or adds the word to the gap log.
3. A word that occurs again in the gap log can go into the register.
4. A maintainer adds the word with a category, a meaning and a source. Or the maintainer rejects the word and gives an alternative.

Sources of terms: the TN19 and TV2 lists of ASD-STE100, the CPRE glossary, the ISTQB glossary, ISO/IEC/IEEE 24765, and glossaries of large vendors. The project must examine the license of each source before it copies terms.

## Updates

<!-- Newest entry first -- prepend new entries directly below this comment. -->

### 2026-11-02 00:00:00.000Z - Draft written

The first version of this decision is written.
