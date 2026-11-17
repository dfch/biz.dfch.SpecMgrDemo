---
classification: null
created: '2026-11-17T09:28:49.279+01:00'
id: fc71e18f-8d48-44b5-baf7-5ec47941178e
status: draft
type: vcr
updated: '2026-11-17T09:28:49.279+01:00'
version: 1.0.0
---

# Verification of the Use Case Choose the Language

## Verifies

UC 3ecb44fa-73d5-4985-9444-bfb444c321b3: Choose the Language

This verification case record makes sure that the page selects its language from the languages of the browser. It also makes sure that a user can change the language with a button. It does this for the main success scenario and for each extension of the use case.

## Coverage

full

## Acceptance Criteria

### AC-001 (Test): Steps 1 and 2 and extensions 2a and 2b, the selection of the language

The unit tests `takes the first language tag of the browser that has a catalog` and `takes EN if no tag has a catalog` in `frontend/src/test/i18n.test.ts` are the tests for these steps. The tests do not have the name prefix `vcr:` yet.

#### Test Steps

1. The list `de-CH, en-US` gives the language `de` (extension 2b, the language tag has a region).
2. The list `fr-FR, DE` gives the language `de`.
3. The list `en-GB` gives the language `en`.
4. The list `fr-FR, it` and the empty list give the language `en` (extension 2a).

### AC-002 (Test): Steps 3 to 5, the choice and the change of the language

The unit test `changes the language with the button, and sets the language of the page` in `frontend/src/test/app.test.tsx` is the test for these steps.

#### Test Steps

1. Show the page in the language EN. The attribute `lang` of the page is `en`. The button `English` has `aria-pressed="true"`.
2. Select the button `Deutsch` (step 4).
3. The attribute `lang` of the page is `de`, the heading of the status is `Systemstatus` and the notice is in German (step 5).
4. The button `Deutsch` has `aria-pressed="true"`.

### AC-003 (Demonstration): The main success scenario in the demo

#### Test Steps

1. Start the demo: `.specmgr/feat/feat-0-demoprep/bin/130-100-00-run-demo.sh`.
2. Open `http://127.0.0.1:5273` in a browser that has `de-DE` as its first language (steps 1 to 3). This is the way to make the image `.specmgr/feat/feat-0-demoprep/images/ui-up-de.png`.
3. The page is in German. The button `Deutsch` is selected. The names of the two buttons are `English` and `Deutsch`.
4. Select the button `English` (step 4).
5. All text of the page is in English and the time of the check has the English format. The browser does not get the page again (step 5).
6. Open the page again with the first language `fr-FR`. The page is in English (extension 2a).
7. Stop the demo: `.specmgr/feat/feat-0-demoprep/bin/130-110-00-stop-demo.sh`.

### AC-004 (Test): Extension 5a, an error text changes with the language

The unit test `shows the text of the error code in the second language DE` shows the error text in German. It does not change the language of a page that shows an error. The test of this extension does not exist yet. The test must be a new unit test in `frontend/src/test/app.test.tsx`.

#### Test Steps

1. Show the page with a fake client (language EN). `GET /status` gives the error `service_unavailable` with a trace identifier.
2. The page has `The service is not available.`
3. Select the button `Deutsch`.
4. The page has `Der Dienst ist nicht verfügbar.` and `Trace-Kennung: <the same identifier>`.
5. The fake client has one call of `getStatus` and one call of `getInfo`, not more.

## More Information

The use case has the sequence diagram `.specmgr/feat/feat-0-demoprep/uml/3ecb44fa-73d5-4985-9444-bfb444c321b3.sequence.puml`. The requirements of the use case are REQ 52f9b02a-69e1-40db-af6e-ad3fb67987bc and REQ 848be85d-ba2c-44ec-b2d2-66fb0e6c84ef. The test of AC-004 is a gap that this record shows. The status of this record is `draft`.

## Updates

<!-- Newest entry first -- prepend new entries directly below this comment. -->

### 2026-11-17 09:42:00.000+01:00 - Draft written

The first version of this verification case record is written in FEAT feat-0-demoprep. It uses the existing tests and the demo scripts.
