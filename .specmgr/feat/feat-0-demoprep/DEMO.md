# feat-0-demoprep: the guide to the demo

The plan of the feature is in the file `README.md` of this folder. This file is the guide to the demo.

## The guide to the demo

The tools of the gates are listed in `TOOLS.md`.

All commands start in the root of the work tree (`/home/user/src/biz.dfch.SpecMgrDemo.worktree/feat-0`). `F` is the short name for the folder of the feature:

```bash
cd /home/user/src/biz.dfch.SpecMgrDemo.worktree/feat-0
F=.specmgr/feat/feat-0-demoprep
```

The scripts do not change a file outside of this folder. The code runs from a copy in `$F/build/work` (not in git). The first run installs the frontend dependencies in the copy (`pnpm install --frozen-lockfile --ignore-scripts`) and needs the network.

**Needs:** JDK 21, Maven wrapper (in the repository), Node, pnpm, Docker (the images `structurizr/structurizr:2026.10.26-noble` and `...-playwright`), rsync, curl, python3. For the PDF: `npx` and the network (Marp).

| # | What | Command | Result |
|---|---|---|---|
| 1 | The user interface (state up) | `$F/bin/130-100-00-run-demo.sh` | http://127.0.0.1:5273 (backend http://127.0.0.1:8180/status and /info) |
| 2 | The user interface (error response with trace id) | `$F/bin/130-100-00-run-demo.sh --fail` | the same address, the backend gives 503 |
| 3 | Stop 1 and 2 (and the servers of 4 and 5) | `$F/bin/130-110-00-stop-demo.sh` | |
| 4 | The page of the API specification | `$F/bin/130-120-00-serve-api-docs.sh` | http://127.0.0.1:8091/index.html |
| 5 | The model (C4 views, static site) | `$F/bin/130-130-00-serve-model-site.sh` | http://127.0.0.1:8092/index.html |
| 6 | Validate the model and compare it with `model/workspace.json` | `$F/bin/100-110-00-validate-model.sh` | `PASS ... 11 components, 19 relations` |
| 7 | Export the site, SVG and PlantUML of the model | `$F/bin/110-100-00-export-model.sh` | `$F/build/model-site`, `build/svg`, `build/plantuml` |
| 8 | Make the rules from the model and run them against the code | `$F/bin/120-110-00-run-rules.sh --generate` | 3 ArchUnit rules, 41 ArchUniTS rules, all green |
| 9 | Show a violated rule | `$F/bin/120-120-00-break-rule.sh` | both rules fail and name the dependency |
| 10 | The traceability check of the repository | `just traceability` | the chain of REQ, VCR, test, OpenAPI and model |
| 11 | The SBOM: make it with the gate and show the files | `$F/bin/160-100-00-show-sbom.sh` | `build/sbom/backend.cdx.json` (55 components) and `frontend.cdx.json` (451) in the root of the work tree; the gate prints the result. Needs the network |
| 12 | Make the images again | `$F/bin/140-100-00-take-screenshots.sh` | `$F/images/` |
| 13 | Make the PDF | `$F/bin/150-110-00-build-pdf.sh` | `$F/PRESENTATION.pdf` |
| 14 | Test: read the version from the page (head-less, no agent) | `$F/bin/170-100-00-playwright-headless.sh` | prints `Version on the page: 0.1.0 (commit <sha>)` and `PASS`; exit code 0 only if the page and `GET /info` have the same version and commit. It starts and stops the demo itself |
| 15 | Test: the same with an agent and the Playwright MCP | the prompt in `$F/bin/170-110-00-agent-prompt.md` (start the demo with 1 first, stop it with 3) | the agent prints the same line and `PASS` |

Order for the talk: 1, 2, 3, then 4, then 5, then 8 and 9, then 10, then 3 to stop the servers.

The two tests of 14 and 15 are on the backup slide of the presentation. Show 14 if there is time (about 10 seconds), and 15 only with the Playwright MCP enabled in the session.

### The prompts for the two Playwright tests

Start the agent in the root of the work tree (`/home/user/src/biz.dfch.SpecMgrDemo.worktree/feat-0`). The prompts below were not run word for word. The steps behind them ran once (see the Updates of `README.md`).

**Interactive: the agent with the Playwright MCP (step 15).** Start the demo before the talk, so the Maven compile does not use time on stage:

```bash
$F/bin/130-100-00-run-demo.sh
```

Prompt for the agent (the demo is running):

```text
Read .specmgr/feat/feat-0-demoprep/bin/170-110-00-agent-prompt.md and do exactly what the section "The prompt" says, with the Playwright MCP tools. The demo is already running. Your final answer must be exactly the two result lines of step 5, and nothing else.
```

The agent only tests. It does not start or stop a server and does not change a file (this is the rule of the prompt file). So you start the demo before the prompt, and after the answer you stop it and remove the folder that the MCP wrote:

```bash
$F/bin/130-110-00-stop-demo.sh
rm -rf .playwright-mcp
```

Expected answer:

```text
Version on the page: 0.1.0 (commit <sha of HEAD>)
PASS
```

In the one run in the session of the author, the agent gave the values in its own words and not the two exact lines. The sentence "must be exactly the two result lines" in the prompt above is there to prevent that. It is not tested yet.

**Non-interactive: the head-less test (step 14).** No agent is needed. Run the script in a terminal (about 10 seconds, it starts and stops the demo itself):

```bash
$F/bin/170-100-00-playwright-headless.sh; echo "exit=$?"
```

Expected: `Version on the page: 0.1.0 (commit <sha>)`, `Version of GET /info: ...`, `PASS ...` and `exit=0`.

Prompt for an agent that runs the script:

```text
Run .specmgr/feat/feat-0-demoprep/bin/170-100-00-playwright-headless.sh with bash. Do not change any file. Show me the output and the exit code.
```

With the `opencode run` command, the agent starts from the shell without the interface (not checked on this version of OpenCode):

```bash
opencode run "Run .specmgr/feat/feat-0-demoprep/bin/170-100-00-playwright-headless.sh with bash. Do not change any file. Show me the output and the exit code."
```

To show a failure: the test fails (exit code 1) if `/info` gives another version than the page. There is no script for this. The option `--fail` of the demo does not work for it, because it changes only `GET /status`. The agent run does not stop the demo, so run `$F/bin/130-110-00-stop-demo.sh` after it.

### Notes and fallbacks

- **Ports.** The ports are 8180 (backend), 5273 (frontend), 8091 and 8092. They are not the usual 8080 and 5173, because port 8080 is in use on the machine of the author. Change them with the environment variables `BACKEND_PORT`, `FRONTEND_PORT`, `API_DOCS_PORT` and `MODEL_SITE_PORT`.
- **Fonts.** The page of the API specification loads a font from `fonts.googleapis.com` (finding F2 of feat-6). Without a network the page shows in a fallback font.
- **Model site.** The viewer of Structurizr shows a help dialog at the first start. Close it with the button at the top right. Use the keys of the viewer (the arrow keys) to go to the next view.
- **No Docker or no network.** The images in `$F/images/` are the fallback for every demo: the screenshots of the user interface (`ui-up-en.png`, `ui-up-de.png`, `ui-error-en.png`), of the API specification (`api-docs.png`), of the model site (`model-site.png`) and the SVG of the four views (`model-*.svg`).
- **SVG.** The SVG export of Structurizr works (the playwright image, started against `structurizr local`). If it fails, the script prints the fallback: the PlantUML files in `build/plantuml`, that a PlantUML server renders.
- **Playwright MCP.** The MCP can write a folder `.playwright-mcp/` into the working folder of the session. It is not in git. Remove it after the test (`rm -rf .playwright-mcp`).
- **Stop all.** `$F/bin/130-110-00-stop-demo.sh` stops the processes that the scripts started. `docker ps` must show no container `demoprep-structurizr-local` afterwards.

### The model and the rules

- `model/workspace.dsl` is the hand-written Structurizr model with the views Context, Containers, Backend and Frontend. It is a hand conversion of `model/workspace.json` of the repository, with the properties `code.*`, `specmgr-req` and `rw.viewpoint`. The script of step 6 compares the two files (the components and the relations), so they cannot drift without a message.
- `bin/120-100-00-generate-rules.mjs` reads the exported JSON and writes `generated/ModelRulesTest.java` (ArchUnit) and `generated/rules.model.mjs` (ArchUniTS). The rule is the closed world: each ordered pair of components of one container without an arrow is a forbidden dependency. The files are committed, so the rules can be read without a run.
- This is a precursor of feat-50. It does not change the gates, and it does not replace the rules R1 to R3 of feat-7.
