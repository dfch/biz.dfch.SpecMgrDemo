---
classification: null
created: '2026-11-02T14:44:42.045+01:00'
id: 51b00b5f-d1d8-49d8-9f40-28537ff69698
status: accepted
type: dec
updated: '2026-11-02T15:17:51.853+01:00'
version: 1.0.0
---

# Use Internationalization in the Application From the Start

## Context and Problem Statement

The application must show its texts in EN, DE and FR. The first release uses EN only. A change to more languages after the start is much work. The walking skeleton is a web application for a company canteen. It gives the menu selection.

## Decision Drivers

- Texts that are in the code are hard to change for other languages.
- Dates, numbers and the sequence of lists are different in each language.
- Menu data (names of dishes, text about allergens) must have translations too.

## Considered Options

- Message catalogs and formats for each locale from the first day.
- Text in EN only in the code, and translations after the first release.

## Decision Outcome

The project uses message catalogs for all texts that a user sees from the first day. There is one catalog file for each language. The first release gives the EN catalog. The code does not make a sentence from parts of texts in a different language. The code formats dates, numbers and lists with the `Intl` functions of the platform.

### Consequences

- The backend sends error codes that do not have a language. The frontend shows the text for each error code from the catalog.
- Each field of menu data that has a translation has a language code.
- The layout must operate correctly with long texts in German and French.

### Confirmation

A gate stops the pull request if a catalog does not have a key, or if a key is not used. Playwright tests operate for each language that has a full catalog.

## Roles and Responsibilities

### Accountable

Project owner.

### Responsible

- Maintainers of the frontend and the backend.

## Tags

- technology
- i18n

## Source

Planning session of 2026-11-02.

## Related Artifacts

### Goals

- GOL 330a042f-8be7-4358-b451-25a4dfcba359: Make a Template for New Projects

## More Information

The project has not selected the library for internationalization at this time. The skeleton FEAT selects it and examines its license. Documents stay in EN. GitHub issue #4 is about French in specmgr.

## Updates

<!-- Newest entry first -- prepend new entries directly below this comment. -->

### 2026-11-02 00:00:00.000Z - Draft written

The first version of this decision is written.
