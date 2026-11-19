---
classification: null
created: '2026-11-15T21:50:00.000+01:00'
id: eb8a7f16-880d-42b7-9852-37c96175d344
status: approved
type: vcr
updated: '2026-11-19T00:21:59.018+01:00'
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

The tests are written in feat-9-walking-skeleton (the task 400.110 of the plan), and they exist: AC-001 is the test `ServiceIT` (the package `biz.dfch.specmgrdemo.app` of the backend, it starts the real service with the class `RunningService`, and it runs in `just test-integration-backend`) and AC-002 is the end-to-end test in `frontend/e2e/service.spec.ts` (Playwright, it runs in `just test-e2e` against the real service and the built frontend). Each has the name that this record states, and they pass. The owner accepted the evidence of this record on 2026-11-18 (the one-time permission, the statement in the chat: "VCR: one-time permission: accept evidence"), and the status is `approved`.

## Updates

<!-- Newest entry first -- prepend new entries directly below this comment. -->

### 2026-11-18 23:55:00.000+01:00 - The owner accepts the evidence; the status is `approved`

The owner gave a permission for one time to accept the evidence of this record (statement of the owner on 2026-11-18, in the chat: "VCR: one-time permission: accept evidence"). The evidence is the test that carries it: AC-001 is the test `ServiceIT` (the package `biz.dfch.specmgrdemo.app` of the backend, in `just test-integration-backend`) and AC-002 is the end-to-end test in `frontend/e2e/service.spec.ts` (Playwright, in `just test-e2e`); each has the name that this record states (the pull request #53 of feat-9-walking-skeleton is open and its CI is green). The sentence of More Information that the status is `draft` and the owner decides is replaced by the fact: the owner accepted the evidence on 2026-11-18, and the status is `approved` (the frontmatter is changed with the status tool in the same work). The statements (the acceptance criteria) of this record are not changed.

### 2026-11-18 12:07:00.000+01:00 - The tests exist

The sentence "Until the tests exist, the verification is not done" of More Information is replaced: the tests exist (`ServiceIT` for AC-001, and `frontend/e2e/service.spec.ts` for AC-002, both with the name that this record states; the pull request #53 of feat-9-walking-skeleton is open and its CI is green). Since the review fix N6b (2026-11-18) the end-to-end test of AC-002 runs against the built bundle of the frontend that `vite preview` serves (the step 1 of AC-002, "the backend and the frontend of the build", holds to the letter). The status stays `draft`: the owner decides the status. The statements of the verification case record are not changed.

### 2026-11-15 21:50:00.000+01:00 - Draft written

The first version of this verification case record is written in the planning of feat-9-walking-skeleton (the task 100.120 of the plan), per step 4 of SOP 95b6735b-03b8-47a0-92aa-7934a4ff1519.
