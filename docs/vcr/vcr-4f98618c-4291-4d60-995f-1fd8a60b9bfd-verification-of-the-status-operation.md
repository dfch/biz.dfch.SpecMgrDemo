---
classification: null
created: '2026-11-15T21:50:00.000+01:00'
id: 4f98618c-4291-4d60-995f-1fd8a60b9bfd
status: draft
type: vcr
updated: '2026-11-18T12:06:59.333+01:00'
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

The tests are written in feat-9-walking-skeleton (the task 400.100 of the plan), and they exist: AC-001 is the test `ServiceIT` and AC-002 is the test `StatusErrorIT` (the package `biz.dfch.specmgrdemo.app` of the backend; each starts the real service with the class `RunningService`), and each has the name that this record states. They run in `just test-integration-backend` and they pass. The status of this record is `draft`. The owner decides the status (the record is not set to another status by the work of the feature).

## Updates

<!-- Newest entry first -- prepend new entries directly below this comment. -->

### 2026-11-18 12:07:00.000+01:00 - The tests exist; the step 4 of AC-002 is verified strictly

The sentence "Until the tests exist, the verification is not done" of More Information is replaced: the tests exist (`ServiceIT` for AC-001 and `StatusErrorIT` for AC-002, both with the name that this record states, in `just test-integration-backend`; the pull request #53 of feat-9-walking-skeleton is open and its CI is green). The step 4 of AC-002 ("The response has no text in a language") is verified strictly since the review fix S2 (2026-11-17): the error response has the members `type`, `status`, `instance`, `code` and `traceId` only (no `title` and no `detail`), and `StatusErrorIT` asserts the exact set of members and that no value is a sentence. Before the fix the test checked only that the body had no member outside the seven members of the schema `Problem`. The status stays `draft`: the owner decides the status. The statements of the verification case record are not changed.

### 2026-11-15 21:50:00.000+01:00 - Draft written

The first version of this verification case record is written in the planning of feat-9-walking-skeleton (the task 100.120 of the plan), per step 4 of SOP 95b6735b-03b8-47a0-92aa-7934a4ff1519.
