---
created: '2026-11-15T21:50:00.000+01:00'
id: eb8a7f16-880d-42b7-9852-37c96175d344
status: draft
type: vcr
updated: '2026-11-15T21:50:00.000+01:00'
version: 1.0.0
---

# Verification of the Info Operation

## Verifies

REQ 271168a4-2a6f-40a1-b277-89711b18a087: The System Gives Its Version and Its License

This verification case record confirms that the system gives its identification and the notice of the license with the operation `GET /info`, and that the user interface shows the notice.

## Coverage

full

## Acceptance Criteria

### AC-001 (Test): The operation gives the identification and the license

The integration test of the backend has the name `vcr:eb8a7f16-880d-42b7-9852-37c96175d344 the operation gives the identification and the license`.

#### Test Steps

1. Start the backend of the build (the build has the version and the commit).
2. The client sends the request `GET /info`.
3. The response has the status code 200 and the media type `application/json`.
4. The body of the response has the version, the commit, the copyright holder, the address of the repository and the license `AGPL-3.0-only`.

### AC-002 (Test): The user interface shows the notice of the license

The end-to-end test has the name `vcr:eb8a7f16-880d-42b7-9852-37c96175d344 the user interface shows the notice of the license`.

#### Test Steps

1. Start the service (the backend and the frontend of the build).
2. The test opens the page of the frontend.
3. The user interface shows the copyright holder, the address of the repository and the license.
4. The values of the user interface are the values of the response of `GET /info`.

## More Information

The tests are written in feat-9-walking-skeleton (the task 400.110 of the plan). Until the tests exist, the verification is not done. The status of this record is `draft`.

## Updates

<!-- Newest entry first -- prepend new entries directly below this comment. -->

### 2026-11-15 21:50:00.000+01:00 - Draft written

The first version of this verification case record is written in the planning of feat-9-walking-skeleton (the task 100.120 of the plan), per step 4 of SOP 95b6735b-03b8-47a0-92aa-7934a4ff1519.
