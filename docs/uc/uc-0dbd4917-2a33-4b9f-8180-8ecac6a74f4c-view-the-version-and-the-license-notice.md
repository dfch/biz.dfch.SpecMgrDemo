---
classification: null
created: '2026-11-17T09:23:54.859+01:00'
id: 0dbd4917-2a33-4b9f-8180-8ecac6a74f4c
status: draft
type: uc
updated: '2026-11-17T09:29:16.701+01:00'
version: 1.0.0
---

# View the Version and the License Notice

## Characteristic Information

### Goal in Context

User wants to know which version and which commit of the system the page comes from. User also wants to know the license of the system. User can use them to get the exact source of the build.

### Scope

Frontend (the user interface of the SpecMgr Demo application, as a black box)

### Level

User Goal

### Preconditions

- Backend is in operation, or it gives an error response.
- User has a web browser and the address of the page.

### Success End Condition

- The page shows the notice of the license (the copyright holder, the address of the repository and the license).
- The page shows the version and the commit of the build.

### Failed End Condition

- The page shows the heading that the information is not available, and the text for the cause.
- The page shows no notice, no version and no commit.

### Primary Actor

User (a person with a web browser)

### Secondary Actors

- Backend (the service that gives the operation GET /info)

### Trigger

User opens the page of the application in the browser.

### Frequency

At each time that a user opens the page again.

### Priority

Top

### Channels to Primary Actor

- Web browser (interactive, HTTP)

### Channels to Secondary Actors

- Backend: HTTP, the operation GET /info of the contract

## Main Success Scenario

1. Frontend shows User the waiting message for the information of the service.
2. Frontend sends the request GET /info to Backend.
3. Backend sends the response with the version, the commit, the copyright holder, the address of the repository and the license to Frontend.
4. Frontend shows User the notice of the license at the bottom of the page, in the language of the page.
5. Frontend shows User the version and the commit of the build, in the language of the page.
6. User reads the notice of the license, the version and the commit.

## Extensions

The extensions are for the section of the notice only. The other sections of the page do not change.

### Extension 3a. Backend sends an error response

1. Backend sends the error response with the error code and the trace identifier to Frontend.
2. Frontend shows User the heading that the information is not available, the text for the error code, and the trace identifier.
    The text is in the language of the page. Frontend does not show the members title and detail of the error response.

### Extension 3b. Backend gives no response

1. Frontend shows User the heading that the information is not available and the text that the service gives no response.
    There is no trace identifier in this case.

### Extension 3c. Backend sends a response that Frontend cannot read

1. Frontend shows User the heading that the information is not available and the text that the response of the service is not valid.
    There is no trace identifier in this case.

## Sub-Variations

### Step 4: Frontend shows the notice as

- English: Copyright 2026 Ronald Rink, https://github.com/dfch/biz.dfch.SpecMgrDemo. Licensed under AGPL-3.0-only.
- German: Copyright 2026 Ronald Rink, https://github.com/dfch/biz.dfch.SpecMgrDemo. Lizenziert unter AGPL-3.0-only.

### Step 5: Frontend shows the version as

- English: `Version {version}, commit {commit}`
- German: `Version {version}, Commit {commit}`

## Open Issues

- The values of the example (the version 0.1.0 and the copyright holder) come from the build. They can be different in another build.

## Related Information

### Notes

- This use case is a part of UC "Open the Page". The head-less Playwright test and the agent test of FEAT feat-0-demoprep do this use case: they read the version from the page and compare it with the version of GET /info.
- The notice is at the bottom of the page.
- REQ 168114dd-d00f-41f9-bb32-9cfa0b362afe: The User Interface Shows the Version and the License Notice
- REQ 848be85d-ba2c-44ec-b2d2-66fb0e6c84ef: The User Interface Shows an Error in the Language of the User
- REQ 271168a4-2a6f-40a1-b277-89711b18a087: The System Gives Its Version and Its License

- VCR 1d255973-104c-4384-bf27-a6ce2a946f4d: Verification of the Use Case View the Version and the License Notice

### Assumptions

- The values that Backend gives are not changed by the language of the page.
- The build is from a pinned commit of the public repository.
