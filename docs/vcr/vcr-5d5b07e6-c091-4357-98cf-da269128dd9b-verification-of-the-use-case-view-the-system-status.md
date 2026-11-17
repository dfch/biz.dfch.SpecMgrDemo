---
classification: null
created: '2026-11-17T09:28:26.371+01:00'
id: 5d5b07e6-c091-4357-98cf-da269128dd9b
status: draft
type: vcr
updated: '2026-11-17T09:28:26.371+01:00'
version: 1.0.0
---

# Verification of the Use Case View the System Status

## Verifies

UC aa8f713b-946f-4625-bf64-aa827ee5aa56: View the System Status

This verification case record makes sure that a user can see the state of the system and the time of the check. It does this for the main success scenario and for each extension of the use case.

## Coverage

full

## Acceptance Criteria

### AC-001 (Demonstration): The main success scenario in the demo

#### Test Steps

1. Start the demo: `.specmgr/feat/feat-0-demoprep/bin/130-100-00-run-demo.sh`.
2. Open `http://127.0.0.1:5273` in a browser with the language English (the trigger).
3. The page shows the message `The status is loading.` while the request is open (step 1). A fast backend can make this message too short to see. The unit test of AC-002 shows it.
4. The section `System status` shows `The system is up.` and `Checked at` with the time in UTC (steps 3 and 4).
5. `curl http://127.0.0.1:8180/status` gives the state `up` (step 3).
6. Stop the demo: `.specmgr/feat/feat-0-demoprep/bin/130-110-00-stop-demo.sh`.

### AC-002 (Test): The waiting message, the state and the time

The unit tests `shows the loading text before the answers arrive` and `shows the state of GET /status and the time of the check` in `frontend/src/test/app.test.tsx` are the tests for steps 1 to 4. The tests do not have the name prefix `vcr:` yet.

#### Test Steps

1. Show the page with a fake client of the API (language EN). The request `GET /status` has no response.
2. The page shows `The status is loading.`
3. Give the state `up` and a time. The page shows `The system is up.` and `Checked at` with the time.

### AC-003 (Demonstration): Extension 3a, the backend sends an error response

#### Test Steps

1. Start the demo with the error state: `.specmgr/feat/feat-0-demoprep/bin/130-100-00-run-demo.sh --fail`.
2. Open `http://127.0.0.1:5273` in a browser with the language English.
3. The section of the status shows `The information is not available.`, `The service is not available.` and `Trace identifier: <32 characters>`.
4. The section of the status shows no state and no time of the check.
5. The page does not show the text of the members `title` and `detail` of the response.
6. Stop the demo: `.specmgr/feat/feat-0-demoprep/bin/130-110-00-stop-demo.sh`.

### AC-004 (Test): Extension 3a, the text for the error code

The unit tests `shows the text of the error code, and the trace identifier, if GET /status gives an error` and `shows the text of the error code in the second language DE` in `frontend/src/test/app.test.tsx` are the tests for this extension.

#### Test Steps

1. Show the page with a fake client. `GET /status` gives the error `service_unavailable` with a trace identifier (language EN, then language DE).
2. In English the page has `The information is not available.`, `The service is not available.` and `Trace identifier: <the identifier>`.
3. In German the page has `Der Dienst ist nicht verfügbar.` and `Trace-Kennung: <the identifier>`.

### AC-005 (Test): Extensions 3b and 3c, no response and a response that Frontend cannot read

The unit test `shows the text for a service that cannot be reached, and for an answer that is not valid` in `frontend/src/test/app.test.tsx` is the test for these extensions.

#### Test Steps

1. Show the page with a fake client (language EN). `GET /status` gives a network error.
2. The section of the status shows `The service cannot be reached.` and no trace identifier.
3. Let `GET /status` give a response that does not obey the contract. The section shows `The service gave an answer that the application does not understand.` and no trace identifier.

### AC-006 (Test): The texts of the states in English and in German

The unit tests `shows the state degraded` and `shows the text of the second language DE: the state, the time, the notice and the version` in `frontend/src/test/app.test.tsx` are the tests for the sub-variation of step 4.

#### Test Steps

1. The state `up` shows `The system is up.` (EN) and `Das System läuft.` (DE).
2. The state `degraded` shows `The system is degraded.` (EN).
3. The text `Das System ist eingeschränkt.` (DE) for the state `degraded` is in the catalog DE. No test shows it on the page yet.

## More Information

The use case has the sequence diagram `.specmgr/feat/feat-0-demoprep/uml/aa8f713b-946f-4625-bf64-aa827ee5aa56.sequence.puml`. The requirements of the use case are REQ 4ed458ff-49c5-452a-a545-0fb8805f872d and REQ 848be85d-ba2c-44ec-b2d2-66fb0e6c84ef. The test of the state `degraded` in German (AC-006, step 3) is a gap that this record shows. The status of this record is `draft`.

## Updates

<!-- Newest entry first -- prepend new entries directly below this comment. -->

### 2026-11-17 09:38:00.000+01:00 - Draft written

The first version of this verification case record is written in FEAT feat-0-demoprep. It uses the existing tests and the demo scripts.
