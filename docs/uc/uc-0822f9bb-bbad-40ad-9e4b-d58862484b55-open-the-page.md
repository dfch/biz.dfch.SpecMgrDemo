---
classification: null
created: '2026-11-17T09:24:47.646+01:00'
id: 0822f9bb-bbad-40ad-9e4b-d58862484b55
status: draft
type: uc
updated: '2026-11-17T09:29:18.700+01:00'
version: 1.0.0
---

# Open the Page

## Characteristic Information

### Goal in Context

User wants to open the page of the application. User wants to see the state of the system, the notice of the license and the version of the build, in the language of the user.

### Scope

Frontend (the user interface of the SpecMgr Demo application, as a black box)

### Level

Summary

### Preconditions

- User has a web browser and the address of the page.
- Frontend has a full catalog of text for English and for German.

### Success End Condition

- The page shows the state of the system and the time of the check.
- The page shows the notice of the license, the version and the commit.
- All text of the page is in the language of User.

### Failed End Condition

- Each section that did not get its information shows the heading that the information is not available, and the text for the cause.
- The other sections of the page are not changed by this failure.

### Primary Actor

User (a person with a web browser)

### Secondary Actors

- Browser (gives the list of the preferred languages of User)
- Backend (the service that gives the operations GET /status and GET /info)

### Trigger

User opens the page of the application.

### Frequency

At each time that a user opens the page again.

### Priority

Top

### Channels to Primary Actor

- Web browser (interactive, HTTP)

### Channels to Secondary Actors

- Browser: the list of the languages of the browser
- Backend: HTTP, the operations GET /status and GET /info of the contract

### Related Use Cases

- Subordinate: View the System Status (UC aa8f713b-946f-4625-bf64-aa827ee5aa56), View the Version and the License Notice (UC 0dbd4917-2a33-4b9f-8180-8ecac6a74f4c), Choose the Language (UC 3ecb44fa-73d5-4985-9444-bfb444c321b3)

## Main Success Scenario

1. Browser sends the list of the preferred languages to Frontend.
2. Frontend selects the language of the page and shows User the page with the choice of the language.
    This is the use case "Choose the Language", steps 2 and 3.
3. Frontend sends the request GET /status to Backend.
    This is the use case "View the System Status". Frontend sends the request GET /info (step 4) at the same time. Each section of the page waits for its own response.
4. Frontend sends the request GET /info to Backend.
    This is the use case "View the Version and the License Notice".
5. Backend sends the state of the system and the time of the check to Frontend.
6. Backend sends the version, the commit, the copyright holder, the address of the repository and the license to Frontend.
    The sequence of the two responses can be different. The sections of the page do not wait for each other.
7. Frontend shows User the state, the time of the check, the notice of the license, the version and the commit, in the language of the page.
8. User reads the page.
9. User selects the other language with its button.
10. Frontend shows User all text of the page in the other language.

## Extensions

### Extension 5a. Backend sends an error response for the status, or it gives no response

1. Frontend shows User the error text in the section of the status.
2. Continue to step 6.

### Extension 6a. Backend sends an error response for the information, or it gives no response

1. Frontend shows User the error text in the section of the notice.
2. Continue to step 7.

## Sub-Variations

### Step 1: The language of the browser can be

- English or German, with or without a region (for example en-GB or de-CH)
- Not known (for example French): Frontend uses English

## Open Issues

- The page has no automatic update. User must open the page again to get a new status.

## Related Information

### Notes

- This summary use case has three subordinate use cases. The sequence diagram of this use case shows the two requests at the same time.
- REQ 4ed458ff-49c5-452a-a545-0fb8805f872d: The User Interface Shows the System Status
- REQ 168114dd-d00f-41f9-bb32-9cfa0b362afe: The User Interface Shows the Version and the License Notice
- REQ 848be85d-ba2c-44ec-b2d2-66fb0e6c84ef: The User Interface Shows an Error in the Language of the User
- REQ 52f9b02a-69e1-40db-af6e-ad3fb67987bc: The User Interface Is in English and in German

- VCR cc436d0a-998c-4d8d-a6fe-b233a9ccf262: Verification of the Use Case Open the Page

### Assumptions

- The demo runs as FEAT feat-0-demoprep describes: the backend at http://127.0.0.1:8180 and the frontend at http://127.0.0.1:5273.
