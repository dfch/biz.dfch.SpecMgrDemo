---
classification: null
created: '2026-11-17T09:27:52.395+01:00'
id: d99b707f-bd15-4d41-85d5-1ba85ec9c997
status: draft
type: vcr
updated: '2026-11-17T09:27:56.958+01:00'
version: 1.0.0
---

# Verification of the Error Display of the User Interface

## Verifies

REQ 848be85d-ba2c-44ec-b2d2-66fb0e6c84ef: The User Interface Shows an Error in the Language of the User

This verification case record makes sure that the user interface shows the text for the error code in the language of the user, and the trace identifier. It also makes sure that the user interface has a text for a service that gives no response, and for a response that it cannot read. It makes sure that the user interface does not show the members `title` and `detail` of the error response.

## Coverage

full

## Acceptance Criteria

### AC-001 (Test): The page shows the text for the error code and the trace identifier

The unit test `shows the text of the error code, and the trace identifier, if GET /status gives an error` in `frontend/src/test/app.test.tsx` is the test for this criterion. The test does not have the name prefix `vcr:` yet.

#### Test Steps

1. Show the page with a fake client (language EN). `GET /status` gives the error `service_unavailable` with the status 503 and a trace identifier of 32 characters.
2. The element with the role `alert` has the text `The information is not available.`
3. The element has the text `The service is not available.`
4. The element has the text `Trace identifier: ` and the trace identifier.

### AC-002 (Test): The text for the error code is in German

The unit test `shows the text of the error code in the second language DE` in `frontend/src/test/app.test.tsx` is the test for this criterion.

#### Test Steps

1. Show the page with a fake client (language DE). `GET /status` gives the error `service_unavailable` with a trace identifier.
2. The element with the role `alert` has the text `Der Dienst ist nicht verfügbar.`
3. The element has the text `Trace-Kennung: ` and the trace identifier.

### AC-003 (Test): The page shows a text for a service that gives no response and for a response that is not valid

The unit test `shows the text for a service that cannot be reached, and for an answer that is not valid` in `frontend/src/test/app.test.tsx` is the test for this criterion.

#### Test Steps

1. Show the page with a fake client (language EN). `GET /status` gives a network error. `GET /info` gives a response that does not obey the contract.
2. The first element with the role `alert` has the text `The service cannot be reached.`
3. The second element with the role `alert` has the text `The service gave an answer that the application does not understand.`
4. The page does not have the text `Trace identifier`.

### AC-004 (Test): Each error code of the contract has a text in each language

The unit test `have a text for each error code of the contract` in `frontend/src/test/i18n.test.ts` is the test for this criterion.

#### Test Steps

1. Read the list `ErrorCode` of `contracts/openapi.yaml` (`not_found`, `validation_failed`, `rate_limited`, `internal_error`, `service_unavailable`).
2. The catalog EN and the catalog DE each have a text in `error.code.<code>` for each code of the list.

### AC-005 (Inspection): The user interface does not show the members title and detail

Examine the source file `frontend/src/ui/ErrorMessage.tsx`. A new unit test must also make sure of it (the test does not exist yet).

#### Test Steps

1. Read `frontend/src/ui/ErrorMessage.tsx`.
2. The text that the component shows comes only from the keys `error.heading`, `error.code.<code>`, `error.network`, `error.invalid` and `error.traceId` of the catalog.
3. The component does not read the members `title` and `detail` of the error response.
4. The planned unit test gives an error response with the `title` `SECRET-TITLE` and the `detail` `SECRET-DETAIL` and examines that the page does not have these texts.

### AC-006 (Demonstration): The demo shows the error response of the backend

#### Test Steps

1. Start the demo with the error state: `.specmgr/feat/feat-0-demoprep/bin/130-100-00-run-demo.sh --fail`. The backend gives `503 service_unavailable` for `GET /status`.
2. Open `http://127.0.0.1:5273` with the language English. The status section shows `The information is not available.`, `The service is not available.` and `Trace identifier: <32 characters>`.
3. The notice section at the bottom of the page still shows the notice of the license.
4. Select the button `Deutsch`. The status section shows `Der Dienst ist nicht verfügbar.` and `Trace-Kennung: <the same 32 characters>`.
5. Send the request `curl -i http://127.0.0.1:8180/status`. The response has the media type `application/problem+json`, the code `service_unavailable` and a trace identifier (32 lower case hexadecimal characters). The response has no text in a language.
6. Compare the page with the image `.specmgr/feat/feat-0-demoprep/images/ui-error-en.png`.
7. Stop the demo: `.specmgr/feat/feat-0-demoprep/bin/130-110-00-stop-demo.sh`.

## More Information

The unit tests of AC-001 to AC-004 exist in the frontend of FEAT feat-9-walking-skeleton (Phase 300). The test of AC-005 is a gap that this record shows. The status of this record is `draft`.

## Updates

<!-- Newest entry first -- prepend new entries directly below this comment. -->

### 2026-11-17 09:34:00.000+01:00 - Draft written

The first version of this verification case record is written in FEAT feat-0-demoprep. It uses the existing tests and the demo scripts.
