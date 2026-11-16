---
created: '2026-11-15T21:50:00.000+01:00'
id: 4f98618c-4291-4d60-995f-1fd8a60b9bfd
status: draft
type: vcr
updated: '2026-11-15T21:50:00.000+01:00'
version: 1.0.0
---

# Verification of the Status Operation

## Verifies

REQ 1ca335d7-969a-443e-9392-165fdeea99a0: The System Gives Its Status

This verification case record confirms that the system gives its state with the operation `GET /status` (the state of the system and the time of the check, or the error response).

## Coverage

full

## Acceptance Criteria

### AC-001 (Test): The operation gives the state of the system

The integration test of the backend has the name `vcr:4f98618c-4291-4d60-995f-1fd8a60b9bfd the operation gives the state of the system`.

#### Test Steps

1. Start the backend of the build.
2. The client sends the request `GET /status`.
3. The response has the status code 200 and the media type `application/json`.
4. The body of the response has the state `up` and the time of the check (the format date-time).

### AC-002 (Test): The operation gives the error response

The integration test of the backend has the name `vcr:4f98618c-4291-4d60-995f-1fd8a60b9bfd the operation gives the error response`.

#### Test Steps

1. Start the backend of the build. The test makes the check of the state fail.
2. The client sends the request `GET /status`.
3. The response has the media type `application/problem+json`, an error code and a trace identifier.
4. The response has no text in a language.

## More Information

The tests are written in feat-9-walking-skeleton (the task 400.100 of the plan). Until the tests exist, the verification is not done. The status of this record is `draft`.

## Updates

<!-- Newest entry first -- prepend new entries directly below this comment. -->

### 2026-11-15 21:50:00.000+01:00 - Draft written

The first version of this verification case record is written in the planning of feat-9-walking-skeleton (the task 100.120 of the plan), per step 4 of SOP 95b6735b-03b8-47a0-92aa-7934a4ff1519.
