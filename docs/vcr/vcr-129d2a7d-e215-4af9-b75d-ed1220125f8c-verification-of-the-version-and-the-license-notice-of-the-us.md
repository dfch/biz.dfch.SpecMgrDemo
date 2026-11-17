---
classification: null
created: '2026-11-17T09:27:39.015+01:00'
id: 129d2a7d-e215-4af9-b75d-ed1220125f8c
status: draft
type: vcr
updated: '2026-11-17T09:27:39.015+01:00'
version: 1.0.0
---

# Verification of the Version and the License Notice of the User Interface

## Verifies

REQ 168114dd-d00f-41f9-bb32-9cfa0b362afe: The User Interface Shows the Version and the License Notice

This verification case record makes sure that the user interface shows a waiting message, and then the notice of the license, the version and the commit of the build. It also makes sure that the values of the page are the values of the response of `GET /info`.

## Coverage

full

## Acceptance Criteria

### AC-001 (Test): The page shows the notice, the version and the commit

The unit test `shows the notice of the license of GET /info, exactly as the DEC has it` in `frontend/src/test/app.test.tsx` and the unit test `give the notice of the license in EN, exactly as the DEC has it` in `frontend/src/test/i18n.test.ts` are the tests for this criterion. The tests do not have the name prefix `vcr:` yet.

#### Test Steps

1. Show the page with a fake client that gives the version `0.1.0`, a commit, the copyright holder `Copyright 2026 Ronald Rink`, the repository `https://github.com/dfch/biz.dfch.SpecMgrDemo` and the license `AGPL-3.0-only` (language EN).
2. The first paragraph of the footer is `Copyright 2026 Ronald Rink, https://github.com/dfch/biz.dfch.SpecMgrDemo. Licensed under AGPL-3.0-only.`
3. The footer has the text `Version 0.1.0, commit <commit>` with the commit of the response.

### AC-002 (Test): The page shows the waiting message and no notice before the response

The unit test `shows the loading text before the answers arrive` in `frontend/src/test/app.test.tsx` is the test for this criterion.

#### Test Steps

1. Show the page with a fake client. The request `GET /info` has no response yet.
2. The page shows the text `The information of the service is loading.`
3. The first paragraph of the footer does not have the text `Copyright`.

### AC-003 (Test): The version on the page is the version of GET /info (head-less, no agent)

The script `.specmgr/feat/feat-0-demoprep/bin/170-100-00-playwright-headless.sh` is the test. It uses a real backend and a real browser (Chromium of Playwright). It is a test of FEAT feat-0-demoprep (ACC-009). It is not part of a gate or of CI.

#### Test Steps

1. Run `.specmgr/feat/feat-0-demoprep/bin/170-100-00-playwright-headless.sh; echo "exit=$?"`. The script starts the demo, runs the test and stops the demo.
2. The output has the line `Version on the page: <version> (commit <commit>)` and the line `Version of GET /info: <version> (commit <commit>)`.
3. The two lines have the same version and the same commit.
4. The output has the line `PASS` and the exit code is 0.

### AC-004 (Demonstration): An agent reads the version from the page

The prompt in `.specmgr/feat/feat-0-demoprep/bin/170-110-00-agent-prompt.md` is the demonstration. An agent with the Playwright MCP does the steps. The agent only reads. The owner starts and stops the demo.

#### Test Steps

1. Start the demo: `.specmgr/feat/feat-0-demoprep/bin/130-100-00-run-demo.sh`.
2. Give the prompt of the file to an agent that has the tools of the Playwright MCP.
3. The agent opens `http://127.0.0.1:5273` and reads the text `Version <version>, commit <commit>` at the bottom of the page.
4. The agent reads `http://127.0.0.1:8180/info` and compares the version and the commit.
5. The agent gives the line `Version on the page: <version> (commit <commit>)` and the result `PASS`.
6. Stop the demo: `.specmgr/feat/feat-0-demoprep/bin/130-110-00-stop-demo.sh`. Remove the folder `.playwright-mcp`.

### AC-005 (Test): An error of the status does not change the notice section

The unit test `shows the text of the error code, and the trace identifier, if GET /status gives an error` in `frontend/src/test/app.test.tsx` is the test for this criterion.

#### Test Steps

1. Show the page with a fake client. `GET /status` gives the error `service_unavailable`. `GET /info` gives the values.
2. The status section shows the error text.
3. The first paragraph of the footer is the notice of the license in English.

### AC-006 (Demonstration): The notice is in the demo in the two languages

#### Test Steps

1. Start the demo: `.specmgr/feat/feat-0-demoprep/bin/130-100-00-run-demo.sh`.
2. Open `http://127.0.0.1:5273` with the language English. The footer has the notice `... Licensed under AGPL-3.0-only.` and the line `Version <version>, commit <commit>`.
3. Select the button `Deutsch`. The footer has the notice `... Lizenziert unter AGPL-3.0-only.` and the line `Version <version>, Commit <commit>`. The address of the repository, the license, the version and the commit are the same as before.
4. Compare the page with the images `ui-up-en.png` and `ui-up-de.png` in `.specmgr/feat/feat-0-demoprep/images/`.
5. Stop the demo: `.specmgr/feat/feat-0-demoprep/bin/130-110-00-stop-demo.sh`.

## More Information

AC-003 has, in FEAT feat-0-demoprep, the result `PASS` and the exit code 0 (see the Updates of the plan of the feature). This record does not replace VCR eb8a7f16-880d-42b7-9852-37c96175d344: Verification of the Info Operation. That record is for the operation and for the end-to-end test of FEAT feat-9-walking-skeleton. The status of this record is `draft`.

## Updates

<!-- Newest entry first -- prepend new entries directly below this comment. -->

### 2026-11-17 09:32:00.000+01:00 - Draft written

The first version of this verification case record is written in FEAT feat-0-demoprep. It uses the existing tests and the demo scripts.
