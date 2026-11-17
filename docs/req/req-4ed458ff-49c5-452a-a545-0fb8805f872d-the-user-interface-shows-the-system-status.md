---
classification: null
created: '2026-11-17T09:22:36.771+01:00'
id: 4ed458ff-49c5-452a-a545-0fb8805f872d
status: draft
type: req
updated: '2026-11-17T09:29:08.954+01:00'
version: 1.0.0
---

# The User Interface Shows the System Status

WHEN a user opens the page of the application, THE user interface must show the state of the system and the time of the check.

## Description

The user interface sends a request to the backend with the operation `GET /status` (REQ 1ca335d7-969a-443e-9392-165fdeea99a0). While it waits for the response, it shows the message `The status is loading.` When the response comes, the user interface shows a text for the state (`up` or `degraded`) and the time of the check.

The time of the check is in the format of the selected language. The time zone is UTC and the time zone name is in the text.

The status section works independently of the other sections of the page. A failure of another operation does not change the status section.

## Characteristics

1. Functional Suitability
2. Interaction Capability

## Level

MUST

## Priority

50

## Tags

- iso29148:strs
- ui

## Source

FEAT feat-0-demoprep. On 2026-11-17, the owner told the author to write use cases and requirements that describe, from the view of the user, the demo with the dual-language user interface. The behavior is the behavior of the user interface of FEAT feat-9-walking-skeleton (Phase 300).

## Related Artifacts

### Requirements

- REQ 1ca335d7-969a-443e-9392-165fdeea99a0: The System Gives Its Status

### Decisions

- DEC 51b00b5f-d1d8-49d8-9f40-28537ff69698: Use Internationalization in the Application From the Start

### Goals

- GOL b94e2758-3368-407e-8fee-827c897e192b: Show the Goal and the Test of Each Requirement

## More Information

This requirement is on the level of the stakeholder (the user of the page). REQ 1ca335d7-969a-443e-9392-165fdeea99a0 is on the level of the system (the operation of the interface).

The verification case record of this requirement is VCR fdddfec7-2601-4c30-95aa-39df60effeea: Verification of the Status Display of the User Interface. The use cases of this requirement are UC aa8f713b-946f-4625-bf64-aa827ee5aa56: View the System Status and UC 0822f9bb-bbad-40ad-9e4b-d58862484b55: Open the Page.

## Notes

The status of this requirement is `draft`. The owner has not accepted it.
