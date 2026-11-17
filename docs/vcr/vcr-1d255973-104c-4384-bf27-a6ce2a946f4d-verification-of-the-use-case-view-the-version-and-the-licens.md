---
classification: null
created: '2026-11-17T09:28:37.842+01:00'
id: 1d255973-104c-4384-bf27-a6ce2a946f4d
status: draft
type: vcr
updated: '2026-11-17T09:28:37.842+01:00'
version: 1.0.0
---

# Verification of the Use Case View the Version and the License Notice

## Verifies

UC 0dbd4917-2a33-4b9f-8180-8ecac6a74f4c: View the Version and the License Notice

This verification case record makes sure that a user can see the notice of the license, the version and the commit of the build. It does this for the main success scenario and for each extension of the use case.

## Coverage

full

## Acceptance Criteria

### AC-001 (Demonstration): The main success scenario in the demo

#### Test Steps

1. Start the demo: `.specmgr/feat/feat-0-demoprep/bin/130-100-00-run-demo.sh`.
2. Open `http://127.0.0.1:5273` in a browser with the language English (the trigger).
3. The footer shows the notice `Copyright 2026 Ronald Rink, https://github.com/dfch/biz.dfch.SpecMgrDemo. Licensed under AGPL-3.0-only.` (step 4).
4. The footer shows `Version <version>, commit <commit>` (step 5).
5. `curl http://127.0.0.1:8180/info` gives the same version, the same commit, the same copyright holder, the same repository and the same license (step 3).
6. Stop the demo: `.specmgr/feat/feat-0-demoprep/bin/130-110-00-stop-demo.sh`.

### AC-002 (Test): The version on the page is the version of GET /info (head-less, no agent)

The script `.specmgr/feat/feat-0-demoprep/bin/170-100-00-playwright-headless.sh` is the test. It does steps 2 to 6 of the use case with a real backend and a real browser.

#### Test Steps

1. Run `.specmgr/feat/feat-0-demoprep/bin/170-100-00-playwright-headless.sh; echo "exit=$?"`.
2. The output has the line `Version on the page: <version> (commit <commit>)` and the line `Version of GET /info: <version> (commit <commit>)` with the same values.
3. The output has the line `PASS` and the exit code is 0.

### AC-003 (Demonstration): An agent reads the version from the page

The prompt in `.specmgr/feat/feat-0-demoprep/bin/170-110-00-agent-prompt.md` is the demonstration.

#### Test Steps

1. Start the demo: `.specmgr/feat/feat-0-demoprep/bin/130-100-00-run-demo.sh`.
2. Give the prompt of the file to an agent that has the tools of the Playwright MCP.
3. The agent reads the version and the commit from the footer of the page, and from `http://127.0.0.1:8180/info`.
4. The agent gives the line `Version on the page: <version> (commit <commit>)` and the result `PASS`.
5. Stop the demo: `.specmgr/feat/feat-0-demoprep/bin/130-110-00-stop-demo.sh`. Remove the folder `.playwright-mcp`.

### AC-004 (Test): The notice in English and in German

The unit tests `shows the notice of the license of GET /info, exactly as the DEC has it` and `shows the text of the second language DE: the state, the time, the notice and the version` in `frontend/src/test/app.test.tsx`, and `give the notice of the license in EN, exactly as the DEC has it` and `give the notice of the license in the second language DE` in `frontend/src/test/i18n.test.ts` are the tests for the sub-variations of steps 4 and 5. The tests do not have the name prefix `vcr:` yet.

#### Test Steps

1. Show the page with a fake client (language EN). The first paragraph of the footer is `Copyright 2026 Ronald Rink, https://github.com/dfch/biz.dfch.SpecMgrDemo. Licensed under AGPL-3.0-only.`
2. The footer has `Version 0.1.0, commit <commit>`.
3. Show the page in the language DE. The first paragraph is `Copyright 2026 Ronald Rink, https://github.com/dfch/biz.dfch.SpecMgrDemo. Lizenziert unter AGPL-3.0-only.`
4. The footer has `Version 0.1.0, Commit <commit>`.

### AC-005 (Test): The waiting message and extension 3a, the error response

The unit tests `shows the loading text before the answers arrive` and `shows no notice of the license, and an error text, if GET /info gives an error` in `frontend/src/test/app.test.tsx` are the tests for step 1 and extension 3a.

#### Test Steps

1. Show the page with a fake client. `GET /info` has no response. The footer shows `The information of the service is loading.` and not the word `Copyright`.
2. Let `GET /info` give the error `internal_error` with a trace identifier. The footer shows `The service has an internal error.`
3. The page does not have the text `Licensed under`.

### AC-006 (Test): Extensions 3b and 3c, no response and a response that Frontend cannot read

The unit test `shows the text for a service that cannot be reached, and for an answer that is not valid` in `frontend/src/test/app.test.tsx` is the test for these extensions for `GET /info`.

#### Test Steps

1. Show the page with a fake client (language EN). `GET /info` gives a response that does not obey the contract.
2. The footer shows `The service gave an answer that the application does not understand.` and no trace identifier.
3. The case of the network error for `GET /info` is not in the test yet. The test has this case for `GET /status` only. This is a gap that this record shows.

## More Information

The use case has the sequence diagram `.specmgr/feat/feat-0-demoprep/uml/0dbd4917-2a33-4b9f-8180-8ecac6a74f4c.sequence.puml`. The requirements of the use case are REQ 168114dd-d00f-41f9-bb32-9cfa0b362afe and REQ 848be85d-ba2c-44ec-b2d2-66fb0e6c84ef. The status of this record is `draft`.

## Updates

<!-- Newest entry first -- prepend new entries directly below this comment. -->

### 2026-11-17 09:40:00.000+01:00 - Draft written

The first version of this verification case record is written in FEAT feat-0-demoprep. It uses the existing tests and the demo scripts.
