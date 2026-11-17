# The test for an agent with the Playwright MCP (Task 170.110, ACC-010, REQ-007)

The same test as `170-100-00-playwright-headless.sh`, but an agent does it with the tools of the Playwright MCP and no script.

## Before the test (the owner or a script)

```bash
.specmgr/feat/feat-0-demoprep/bin/130-100-00-run-demo.sh      # the page is http://127.0.0.1:5273
```

After the test: `.specmgr/feat/feat-0-demoprep/bin/130-110-00-stop-demo.sh`

## The prompt (copy it to the agent)

> You test the page of a web application with the tools of the Playwright MCP. Do not change any file and do not start or stop a server.
>
> 1. Open `http://127.0.0.1:5273` with `playwright_browser_navigate`.
> 2. Find the notice at the bottom of the page with `playwright_browser_find` (search for `Version`) or with `playwright_browser_snapshot`. It has the text `Version <version>, commit <commit>` (in German: `Commit`).
> 3. Read `<version>` and `<commit>` from that text. Do not guess a value. If the text is not on the page, say that and stop.
> 4. Read `http://127.0.0.1:8180/info` (the field `version` and the field `commit`). Use `playwright_browser_navigate` or `curl`.
> 5. Print these two lines to the console, and nothing else as a result:
>    `Version on the page: <version> (commit <commit>)`
>    `PASS` if the version and the commit are the same as in `/info`, or `FAIL` and the two values if they are not.
> 6. Close the browser with `playwright_browser_close`.

## The expected result

The same values as the head-less test (`Version on the page: 0.1.0 (commit <sha of the build>)`) and `PASS`. The `<sha>` is the commit of the work tree when the demo was started.

## Notes

- The Playwright MCP can write files (a folder `.playwright-mcp/`, snapshots) into the working folder of the session. They are not in git. Remove them after the test.
- The result of a run is in the Updates of the plan (`README.md`). A result that was not run is not recorded.
