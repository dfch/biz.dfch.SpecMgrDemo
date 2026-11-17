---
classification: null
created: '2026-11-17T09:28:08.187+01:00'
id: ce246106-f17b-4b17-aed9-b9af6a3d248a
status: draft
type: vcr
updated: '2026-11-17T09:28:13.790+01:00'
version: 1.0.0
---

# Verification of the Languages of the User Interface

## Verifies

REQ 52f9b02a-69e1-40db-af6e-ad3fb67987bc: The User Interface Is in English and in German

This verification case record makes sure that the user interface has a full catalog in English and in German. It also makes sure that the user interface selects the language from the languages of the browser, that the user can change the language with a button, and that the page changes all its text without a new request to the backend.

## Coverage

full

## Acceptance Criteria

### AC-001 (Test): The language is selected from the languages of the browser

The unit tests `takes the first language tag of the browser that has a catalog` and `takes EN if no tag has a catalog` in `frontend/src/test/i18n.test.ts` are the tests for this criterion. The tests do not have the name prefix `vcr:` yet.

#### Test Steps

1. Give the list `de-CH, en-US` to the function `detectLanguage`. The result is `de`.
2. Give the list `fr-FR, DE`. The result is `de`.
3. Give the list `en-GB`. The result is `en`.
4. Give the list `fr-FR, it` and the empty list. The result is `en` in each case.

### AC-002 (Test): The two catalogs are full

The unit tests `have the same keys in EN and DE`, `have no empty text, and a different text in DE for the texts that are not names` and `have the two languages EN and DE` in `frontend/src/test/i18n.test.ts` are the tests for this criterion.

#### Test Steps

1. Read the catalog EN and the catalog DE.
2. The two catalogs have the same keys.
3. No text is empty. The texts of the catalog DE are different from the texts of the catalog EN, except for the texts that are names.
4. The list of the languages is `en` and `de`.

### AC-003 (Test): The page shows its text in German

The unit test `shows the text of the second language DE: the state, the time, the notice and the version` in `frontend/src/test/app.test.tsx` is the test for this criterion.

#### Test Steps

1. Show the page with a fake client (language DE).
2. The heading of the status section is `Systemstatus`, and the state is `Das System läuft.`
3. The page has the text `Geprüft am` and the time in the format of the language DE.
4. The notice is `Copyright 2026 Ronald Rink, https://github.com/dfch/biz.dfch.SpecMgrDemo. Lizenziert unter AGPL-3.0-only.`
5. The footer has the text `Version 0.1.0, Commit <commit>`.
6. The page does not have the English text `The system is up.`

### AC-004 (Test): The button changes the language of the page

The unit test `changes the language with the button, and sets the language of the page` in `frontend/src/test/app.test.tsx` is the test for this criterion.

#### Test Steps

1. Show the page (language EN). The attribute `lang` of the page is `en`, the title is `SpecMgr Demo`.
2. The button `English` has `aria-pressed="true"` and the button `Deutsch` has `aria-pressed="false"`.
3. Select the button `Deutsch`.
4. The attribute `lang` of the page is `de`. The heading of the status section is `Systemstatus`. The notice is in German.
5. The button `Deutsch` has `aria-pressed="true"`. The label of the choice of the language is `Sprache`.

### AC-005 (Test): The change of the language does not send a new request

The criterion has no test yet. The test must be a new unit test in `frontend/src/test/app.test.tsx`. The existing test `asks each operation once` examines the first request only.

#### Test Steps

1. Show the page with a fake client (language EN).
2. Select the button `Deutsch`.
3. The page shows the German text.
4. The fake client has one call of `getStatus` and one call of `getInfo`, not more.

### AC-006 (Demonstration): The browser language selects the language in the demo

#### Test Steps

1. Start the demo: `.specmgr/feat/feat-0-demoprep/bin/130-100-00-run-demo.sh`.
2. Open `http://127.0.0.1:5273` in a browser that has `de-DE` as its first language. This is the way to make the image `ui-up-de.png`: use the option `--lang de` of the script `.specmgr/feat/feat-0-demoprep/bin/140-100-01-shot.mjs`.
3. The page is in German (`Systemstatus`, `Das System läuft.`). The button `Deutsch` is the selected button.
4. Open the page with the language `fr-FR`. The page is in English.
5. Select the other button on each page. The text of the page changes immediately, and the browser does not get the page again (the status and the time of the check stay the same).
6. Stop the demo: `.specmgr/feat/feat-0-demoprep/bin/130-110-00-stop-demo.sh`.

### AC-007 (Inspection): The layout works with the long German texts

#### Test Steps

1. Open the image `.specmgr/feat/feat-0-demoprep/images/ui-up-de.png` (the page in German, 820 pixels wide).
2. No text is cut off or over another element.
3. The buttons of the choice of the language are visible and their names are `English` and `Deutsch`.

## More Information

The unit tests of AC-001 to AC-004 exist in the frontend of FEAT feat-9-walking-skeleton (Phase 300). The test of AC-005 is a gap that this record shows. A French catalog is not in scope. The status of this record is `draft`.

## Updates

<!-- Newest entry first -- prepend new entries directly below this comment. -->

### 2026-11-17 09:36:00.000+01:00 - Draft written

The first version of this verification case record is written in FEAT feat-0-demoprep. It uses the existing tests and the demo scripts.
