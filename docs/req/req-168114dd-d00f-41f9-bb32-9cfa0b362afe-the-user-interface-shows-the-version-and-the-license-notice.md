---
classification: null
created: '2026-11-17T09:22:45.572+01:00'
id: 168114dd-d00f-41f9-bb32-9cfa0b362afe
status: draft
type: req
updated: '2026-11-17T09:29:10.939+01:00'
version: 1.0.0
---

# The User Interface Shows the Version and the License Notice

WHEN a user opens the page of the application, THE user interface must show the notice of the license, the version and the commit of the build.

## Description

The user interface sends a request to the backend with the operation `GET /info` (REQ 271168a4-2a6f-40a1-b277-89711b18a087). While it waits for the response, it shows the message `The information of the service is loading.` When the response comes, the user interface shows two items at the bottom of the page:

1. The notice of the license. It has the copyright holder, the address of the repository and the license, in one sentence of the selected language.
2. The version and the commit of the build, in one line of the selected language.

The values come from the response and not from the text of the catalog. The user can use the version and the commit to get the exact source of the build from the repository.

The notice section works independently of the other sections of the page. A failure of another operation does not change the notice section.

## Characteristics

1. Functional Suitability
2. Compatibility

## Level

MUST

## Priority

50

## Tags

- iso29148:strs
- ui
- license

## Source

FEAT feat-0-demoprep. On 2026-11-17, the owner told the author to write use cases and requirements that describe, from the view of the user, the demo with the dual-language user interface. The behavior is the behavior of the user interface of FEAT feat-9-walking-skeleton (Phase 300). The notice is necessary for the license of the service (DEC 5ddd8d7a-5e7d-4a9b-860f-7d0b1f05579c).

## Related Artifacts

### Requirements

- REQ 271168a4-2a6f-40a1-b277-89711b18a087: The System Gives Its Version and Its License

### Decisions

- DEC 5ddd8d7a-5e7d-4a9b-860f-7d0b1f05579c: Provide the Source, the Version and the License of the Service in the Info Operation and the User Interface
- DEC 51b00b5f-d1d8-49d8-9f40-28537ff69698: Use Internationalization in the Application From the Start

### Goals

- GOL b94e2758-3368-407e-8fee-827c897e192b: Show the Goal and the Test of Each Requirement

## More Information

This requirement is on the level of the stakeholder (the user of the page). REQ 271168a4-2a6f-40a1-b277-89711b18a087 is on the level of the system (the operation of the interface). The head-less Playwright test and the agent test of FEAT feat-0-demoprep read the version from the page. They show this requirement.

The verification case record of this requirement is VCR 129d2a7d-e215-4af9-b75d-ed1220125f8c: Verification of the Version and the License Notice of the User Interface. The use cases of this requirement are UC 0dbd4917-2a33-4b9f-8180-8ecac6a74f4c: View the Version and the License Notice and UC 0822f9bb-bbad-40ad-9e4b-d58862484b55: Open the Page.

## Notes

The status of this requirement is `draft`. The owner has not accepted it.
