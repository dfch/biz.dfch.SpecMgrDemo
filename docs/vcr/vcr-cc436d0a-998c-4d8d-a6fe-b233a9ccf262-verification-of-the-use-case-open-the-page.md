---
classification: null
created: '2026-11-17T09:29:00.797+01:00'
id: cc436d0a-998c-4d8d-a6fe-b233a9ccf262
status: draft
type: vcr
updated: '2026-11-17T09:29:00.797+01:00'
version: 1.0.0
---

# Verification of the Use Case Open the Page

## Verifies

UC 0822f9bb-bbad-40ad-9e4b-d58862484b55: Open the Page

This verification case record makes sure that a user can open the page and see the state of the system, the notice of the license and the version of the build, in the language of the user. It does this for the main success scenario and for each extension of the summary use case. The three subordinate use cases have their own verification case records.

## Coverage

full

## Acceptance Criteria

### AC-001 (Demonstration): The main success scenario in the demo

The demonstration follows the sequence of the talk in `.specmgr/feat/feat-0-demoprep/DEMO.md` (steps 1, 2 and 3).

#### Test Steps

1. Start the demo: `.specmgr/feat/feat-0-demoprep/bin/130-100-00-run-demo.sh`.
2. Open `http://127.0.0.1:5273` in a browser that has English as its first language.
3. The page shows the section `System status` with `The system is up.` and the time, and the footer with the notice of the license and `Version <version>, commit <commit>`.
4. Select the button `Deutsch`. All text of the page changes to German.
5. Stop the demo: `.specmgr/feat/feat-0-demoprep/bin/130-110-00-stop-demo.sh`.

### AC-002 (Test): The page sends one request for each operation

The unit test `asks each operation once` in `frontend/src/test/app.test.tsx` is the test for steps 3 and 4.

#### Test Steps

1. Show the page with a fake client of the API.
2. The client has one call of `getStatus` and one call of `getInfo`.

### AC-003 (Test): The two sections work independently (extensions 5a and 6a)

The unit tests `shows the text of the error code, and the trace identifier, if GET /status gives an error` and `shows no notice of the license, and an error text, if GET /info gives an error` in `frontend/src/test/app.test.tsx` are the tests for these extensions. The tests do not have the name prefix `vcr:` yet.

#### Test Steps

1. Show the page with a fake client. `GET /status` gives the error `service_unavailable`.
2. The status section shows the error text. The notice section shows the notice of the license (extension 5a).
3. Show the page again. `GET /info` gives the error `internal_error`.
4. The notice section shows the error text and not the notice (extension 6a).
5. The test does not examine the status section in step 4. This is a gap that this record shows. The new test of VCR fdddfec7-2601-4c30-95aa-39df60effeea (AC-004) closes it.

### AC-004 (Demonstration): The status section shows an error and the notice section works (extension 5a)

#### Test Steps

1. Start the demo with the error state: `.specmgr/feat/feat-0-demoprep/bin/130-100-00-run-demo.sh --fail`.
2. Open `http://127.0.0.1:5273` in a browser that has English as its first language.
3. The status section shows `The information is not available.`, `The service is not available.` and a trace identifier.
4. The footer shows the notice of the license and the version.
5. Stop the demo: `.specmgr/feat/feat-0-demoprep/bin/130-110-00-stop-demo.sh`.

### AC-005 (Test): The page and the backend give the same version (head-less, no agent)

The script `.specmgr/feat/feat-0-demoprep/bin/170-100-00-playwright-headless.sh` does the use case with a real backend and a real browser.

#### Test Steps

1. Run `.specmgr/feat/feat-0-demoprep/bin/170-100-00-playwright-headless.sh; echo "exit=$?"`.
2. The version and the commit on the page are the version and the commit of `GET /info`.
3. The output has the line `PASS` and the exit code is 0.

### AC-006 (Inspection): Each section has its own request

#### Test Steps

1. Read `frontend/src/ui/App.tsx`, `frontend/src/ui/StatusPanel.tsx`, `frontend/src/ui/LicenseNotice.tsx` and `frontend/src/ui/useRemote.ts`.
2. `StatusPanel` and `LicenseNotice` each call `useRemote` with their own operation (`getStatus` and `getInfo`).
3. Each call of `useRemote` has its own state (`loading`, `ready` or `failed`). No section reads the state of the other section.
4. A new request starts only when the list of the dependencies changes. A change of the language is not in the list.

## More Information

The use case has the sequence diagram `.specmgr/feat/feat-0-demoprep/uml/0822f9bb-bbad-40ad-9e4b-d58862484b55.sequence.puml` and the package diagram `.specmgr/feat/feat-0-demoprep/uml/package.puml`. The requirements of the use case are REQ 4ed458ff-49c5-452a-a545-0fb8805f872d, REQ 168114dd-d00f-41f9-bb32-9cfa0b362afe, REQ 848be85d-ba2c-44ec-b2d2-66fb0e6c84ef and REQ 52f9b02a-69e1-40db-af6e-ad3fb67987bc. The status of this record is `draft`.

## Updates

<!-- Newest entry first -- prepend new entries directly below this comment. -->

### 2026-11-17 09:44:00.000+01:00 - Draft written

The first version of this verification case record is written in FEAT feat-0-demoprep. It uses the existing tests and the demo scripts.
