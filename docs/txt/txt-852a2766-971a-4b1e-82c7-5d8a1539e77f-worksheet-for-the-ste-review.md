---
classification: null
created: '2026-11-03T07:33:36.702+01:00'
id: 852a2766-971a-4b1e-82c7-5d8a1539e77f
status: draft
type: txt
updated: '2026-11-03T10:36:32.580+01:00'
version: 1.0.0
---

# Worksheet for the STE Review

This worksheet is for the reviewer of task 500.130 and of ACC-007 of feat-3-process-policy-baseline. The reviewer examines the STE rules that a word check does not examine. The worksheet has the results of a check with three scripts. They are in `.specmgr/feat/feat-3-process-policy-baseline/bin/` (names start with `500.120-`). They are for reference only and are not a gate.

## Method

- A temporary program read the 31 documents of the feature. It compared each word with the base dictionary of ASD-STE100, the technical words and the terminology register.
- The program does not know the grammar. A person must examine the items below.
- The headings that specmgr gives to each document type are not in the scope (for example Consequences, Considered Options, Responsible, Mitigation).

## Results of the Word Check

- The check found 3 words in the text that are not approved: `extra` (2 times) and `separate` (1 time). An agent wrote the text again. The text has the words more and different.
- The check found one verb that is only approved as a noun: work. An agent changed it to operate.
- The check cannot find a technical noun that is used as a verb. The reviewer must look for this fault (rule 1.7).

## Items for the Reviewer

### Part of Speech

About 90 words are approved as one part of speech and rejected as a different part of speech. The reviewer examines the words below in their sentences. A search with the pattern "to word", "must word" and "can word" found no other fault.

| Word | Approved as | Rejected as |
|---|---|---|
| code | noun | verb |
| test | noun | verb |
| check | noun | verb |
| request | noun | noun and verb |
| register | technical noun | verb |
| file | technical noun | verb |
| list | technical noun | verb |
| link | technical noun | verb |
| log | technical noun | verb |
| branch | technical noun | verb |
| build | technical noun | noun and verb |
| review | technical noun | noun |
| process | technical noun and verb | noun and verb |
| work | noun | verb |
| use | noun and verb | noun |

### Tenses and Passive Voice

- Rule 3.6: use the active voice. In descriptive writing, the passive voice is permitted only when the agent is unknown.
- Rule 3.2: use only the verb forms and tenses that this rule gives. These are the infinitive, the imperative, the simple present, the simple past, the simple future and the past participle as an adjective.
- Rule 3.5: use the -ing form only as a technical noun or as a modifier in a technical noun. The reviewer looks for other -ing forms.
- A pattern search found 38 sentences with a passive verb. The pattern search is not a grammar check.
- 21 of them are the sentences in the Updates log (for example, "The first version of this decision is written."). The agent is known in these sentences (the author). The reviewer examines if they are correct for a log.
- 11 of them are in this worksheet. They are examples that the worksheet quotes, and the reviewer can ignore them.
- The reviewer examines these sentences:
  - "A quality target that has no measure cannot be examined." (DEC about quality)
  - "Three lists are loaded at this time: EARS, the CPRE glossary and RFC 2119." (DEC about the register)
  - "A task is done only if no blocking gate stops the pull request." (DEC about commits)
  - "Branch protection and CI make sure that the limits are obeyed." (DEC about limits for coding agents)
  - "Examine each change after it is done." (DEC about limits for coding agents)
  - "After the owner accepts the DEC about React, task 300.100 of feature feat-1 is done." (handbook)

### Sentence Length

- Rule 6.3: a sentence in descriptive writing has 25 words at the most. Rule 5.1: a sentence in a procedure has 20 words at the most.
- No sentence has more than 25 words.
- One sentence in the SOP about requirements has 24 words. The reviewer examines the sentence that starts with "Set the requirement level".
- The program divides sentences at the full stop. It can make an error in a list or in a table. The reviewer examines the lists and the tables.

### Other STE Rules

- Rule 6.6: a paragraph has 6 sentences at the most. Rule 6.5: a paragraph has one topic.
- Rule 5.2: one instruction in each sentence of a procedure.
- Rule 5.5: a note gives information and not an instruction.
- Rule 4.5: use an article or a demonstrative adjective before a noun where it is correct.
- Rule 2.1: a multi-word noun has 3 words at the most. Rule 2.2 gives the methods for a longer technical noun.
- Rule 1.7 (see the DEC about the STE language): do not use a technical noun as a verb. Rule 1.13: do not use a technical verb as a noun.
- Words of a requirement (MUST, MAY): the register tells the author to use them in UPPERCASE and for requirements only.
- Names of tools and standards (for example OpenAPI, Testcontainers): they are in the register or in a code span.

## Result of the Reviewer

The reviewer writes the result in this section. The reviewer then marks ACC-007 in the feature plan as done.

- Reviewer: dfch
- Date:
- Result:

## Updates

<!-- Newest entry first -- prepend new entries directly below this comment. -->

### 2026-11-03 00:00:00.000Z - Draft written

An agent writes the first version of this worksheet. The reviewer has not examined the items.
