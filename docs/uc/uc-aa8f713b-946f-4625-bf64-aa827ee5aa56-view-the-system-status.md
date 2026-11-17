---
classification: null
created: '2026-11-17T09:23:39.746+01:00'
id: aa8f713b-946f-4625-bf64-aa827ee5aa56
status: draft
type: uc
updated: '2026-11-17T09:29:15.424+01:00'
version: 1.0.0
---

# View the System Status

## Characteristic Information

### Goal in Context

User wants to know if the system is in operation and when the system did its last check.

### Scope

Frontend (the user interface of the SpecMgr Demo application, as a black box)

### Level

User Goal

### Preconditions

- Backend is in operation, or it gives an error response.
- User has a web browser and the address of the page.

### Success End Condition

- The page shows the state of the system (up or degraded).
- The page shows the time of the check.

### Failed End Condition

- The page shows the heading that the information is not available, and the text for the cause.
- The page shows no state and no time of the check.

### Primary Actor

User (a person with a web browser)

### Secondary Actors

- Backend (the service that gives the operation GET /status)

### Trigger

User opens the page of the application in the browser.

### Frequency

At each time that a user opens the page again.

### Priority

Top

### Channels to Primary Actor

- Web browser (interactive, HTTP)

### Channels to Secondary Actors

- Backend: HTTP, the operation GET /status of the contract

## Main Success Scenario

1. Frontend shows User the waiting message for the status.
2. Frontend sends the request GET /status to Backend.
3. Backend sends the response with the state and the time of the check to Frontend.
4. Frontend shows User the text for the state and the time of the check, in the language of the page.
5. User reads the state of the system.

## Extensions

The extensions are for the section of the status only. The other sections of the page do not change.

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

### Step 4: Frontend shows the state as

- English: The system is up.
- English: The system is degraded.
- German: Das System läuft.
- German: Das System ist eingeschränkt.

## Open Issues

- The page does not check the state again. The user must open the page again to get a new check.

## Related Information

### Notes

- This use case is a part of UC "Open the Page". It is the same for the English and the German page. UC "Choose the Language" changes the language of the text.
- The section has the heading "System status" (German: "Systemstatus").
- REQ 4ed458ff-49c5-452a-a545-0fb8805f872d: The User Interface Shows the System Status
- REQ 848be85d-ba2c-44ec-b2d2-66fb0e6c84ef: The User Interface Shows an Error in the Language of the User
- REQ 1ca335d7-969a-443e-9392-165fdeea99a0: The System Gives Its Status

- VCR 5d5b07e6-c091-4357-98cf-da269128dd9b: Verification of the Use Case View the System Status

### Assumptions

- The backend gives the time in UTC. Frontend shows the time in UTC.
- The language of the page is English or German.
