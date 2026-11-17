---
classification: null
created: '2026-11-17T09:22:57.558+01:00'
id: 52f9b02a-69e1-40db-af6e-ad3fb67987bc
status: draft
type: req
updated: '2026-11-17T09:29:14.403+01:00'
version: 1.0.0
---

# The User Interface Is in English and in German

WHEN a user opens the page of the application, THE user interface must show all its text in the language of the browser. The language is English or German. If the language of the browser is not known, the language is English. The user must be able to change the language on the page.

## Description

The user interface has a full catalog of text for each of two languages: English (EN) and German (DE). The user interface does these things:

1. It selects the language when the page opens. It uses the first language of the browser that has a catalog. If no language of the browser has a catalog, it uses English.
2. It shows a choice of the language. The choice has one button for each language. The name on each button is in its own language. The button of the selected language shows that it is selected.
3. When the user selects a language, all text of the page changes to this language immediately. The browser does not get the page again and the user interface does not send a new request to the backend. The language of the page (the attribute `lang` of the page) and the title of the page change too.
4. The format of the time of the check follows the language.

The values that come from the backend (the address of the repository, the license, the version and the commit) are not changed by the language.

## Characteristics

1. Interaction Capability
2. Flexibility

## Level

MUST

## Priority

50

## Tags

- iso29148:strs
- ui
- i18n

## Source

FEAT feat-0-demoprep. On 2026-11-17, the owner told the author to write use cases and requirements that describe, from the view of the user, the demo with the dual-language user interface. The rule that the user interface has the i18n from the start is in DEC 51b00b5f-d1d8-49d8-9f40-28537ff69698.

## Related Artifacts

### Decisions

- DEC 51b00b5f-d1d8-49d8-9f40-28537ff69698: Use Internationalization in the Application From the Start

### Goals

- GOL b94e2758-3368-407e-8fee-827c897e192b: Show the Goal and the Test of Each Requirement

## More Information

The layout must work with the long German texts. A language that has no catalog is not in scope. The project has no plan for a French catalog (see RSK 5dfbf884-0ba4-4ecc-b97e-191aca335b98: Specmgr Has No French Heading Table and No SRS Type).

The verification case record of this requirement is VCR ce246106-f17b-4b17-aed9-b9af6a3d248a: Verification of the Languages of the User Interface. The use cases of this requirement are UC 3ecb44fa-73d5-4985-9444-bfb444c321b3: Choose the Language and UC 0822f9bb-bbad-40ad-9e4b-d58862484b55: Open the Page.

## Notes

The status of this requirement is `draft`. The owner has not accepted it.
