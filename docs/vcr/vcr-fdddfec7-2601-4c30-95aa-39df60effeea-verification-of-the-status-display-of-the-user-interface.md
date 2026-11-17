---
classification: null
created: '2026-11-17T09:27:22.955+01:00'
id: fdddfec7-2601-4c30-95aa-39df60effeea
status: draft
type: vcr
updated: '2026-11-17T09:27:26.970+01:00'
version: 1.0.0
---

# Verification of the Status Display of the User Interface

## Verifies

REQ 4ed458ff-49c5-452a-a545-0fb8805f872d: The User Interface Shows the System Status

This verification case record makes sure that the user interface shows a waiting message in the section of the status. It also makes sure that the user interface then shows the state of the system and the time of the check.

## Coverage

full

## Acceptance Criteria

### AC-001 (Test): The page shows the waiting message and then the state and the time

The unit test `shows the loading text before the answers arrive` and the unit test `shows the state of GET /status and the time of the check` in `frontend/src/test/app.test.tsx` are the tests for this criterion. The tests do not have the name prefix `vcr:` yet.

#### Test Steps

1. Show the page with a fake client of the API (language EN). The request `GET /status` has no response yet.
2. The page shows the text `The status is loading.`
3. Give the response `{"state": "up", "checkedAt": "2026-11-17T04:30:00Z"}`.
4. The heading of the section is `System status`.
5. The page shows the text `The system is up.` in the element that has `data-state="up"`.
6. The page shows the text `Checked at` and the time in the format of the language EN, with the year 2026 and the time zone UTC.

### AC-002 (Test): The page shows the state degraded

The unit test `shows the state degraded` in `frontend/src/test/app.test.tsx` is the test for this criterion.

#### Test Steps

1. Show the page with a fake client that gives the state `degraded` (language EN).
2. The page shows the text `The system is degraded.` in the element that has `data-state="degraded"`.

### AC-003 (Demonstration): The demo shows the state of the real backend

#### Test Steps

1. Start the demo: `.specmgr/feat/feat-0-demoprep/bin/130-100-00-run-demo.sh`.
2. Open `http://127.0.0.1:5273` in a browser with the language English.
3. The section `System status` shows `The system is up.` and `Checked at` with a time.
4. Send the request `curl http://127.0.0.1:8180/status`. The response has the state `up` and a `checkedAt` (the format date-time). The state is the state on the page.
5. Compare the page with the image `.specmgr/feat/feat-0-demoprep/images/ui-up-en.png`.
6. Stop the demo: `.specmgr/feat/feat-0-demoprep/bin/130-110-00-stop-demo.sh`.

### AC-004 (Test): An error of the notice does not change the status section

The criterion has no test yet. The test must be a new unit test in `frontend/src/test/app.test.tsx`. The existing test `shows no notice of the license, and an error text, if GET /info gives an error` does not examine the status section.

#### Test Steps

1. Show the page with a fake client. `GET /status` gives the state `up`. `GET /info` gives the error `internal_error`.
2. The status section shows `The system is up.` and the time of the check.
3. The notice section shows the text `The service has an internal error.`

## More Information

The unit tests of AC-001 and AC-002 exist in the frontend of FEAT feat-9-walking-skeleton (Phase 300). AC-004 is a gap that this record shows. Until the test of AC-004 exists, the verification is not done. The status of this record is `draft`.

## Updates

<!-- Newest entry first -- prepend new entries directly below this comment. -->

### 2026-11-17 09:30:00.000+01:00 - Draft written

The first version of this verification case record is written in FEAT feat-0-demoprep. It uses the existing tests and the demo scripts.
