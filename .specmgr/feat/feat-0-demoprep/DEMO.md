# feat-0-demoprep: the guide to the demo

The plan of the feature is in the file `README.md` of this folder. This file is the guide to the demo.

## The guide to the demo

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
| 11 | Make the images again | `$F/bin/140-100-00-take-screenshots.sh` | `$F/images/` |
| 12 | Make the PDF | `$F/bin/150-110-00-build-pdf.sh` | `$F/PRESENTATION.pdf` |

Order for the talk: 1, 2, 3, then 4, then 5, then 8 and 9, then 10, then 3 to stop the servers.

### Notes and fallbacks

- **Ports.** The ports are 8180 (backend), 5273 (frontend), 8091 and 8092. They are not the usual 8080 and 5173, because port 8080 is in use on the machine of the author. Change them with the environment variables `BACKEND_PORT`, `FRONTEND_PORT`, `API_DOCS_PORT` and `MODEL_SITE_PORT`.
- **Fonts.** The page of the API specification loads a font from `fonts.googleapis.com` (finding F2 of feat-6). Without a network the page shows in a fallback font.
- **Model site.** The viewer of Structurizr shows a help dialog at the first start. Close it with the button at the top right. Use the keys of the viewer (the arrow keys) to go to the next view.
- **No Docker or no network.** The images in `$F/images/` are the fallback for every demo: the screenshots of the user interface (`ui-up-en.png`, `ui-up-de.png`, `ui-error-en.png`), of the API specification (`api-docs.png`), of the model site (`model-site.png`) and the SVG of the four views (`model-*.svg`).
- **SVG.** The SVG export of Structurizr works (the playwright image, started against `structurizr local`). If it fails, the script prints the fallback: the PlantUML files in `build/plantuml`, that a PlantUML server renders.
- **Stop all.** `$F/bin/130-110-00-stop-demo.sh` stops the processes that the scripts started. `docker ps` must show no container `demoprep-structurizr-local` afterwards.

### The model and the rules

- `model/workspace.dsl` is the hand-written Structurizr model with the views Context, Containers, Backend and Frontend. It is a hand conversion of `model/workspace.json` of the repository, with the properties `code.*`, `specmgr-req` and `rw.viewpoint`. The script of step 6 compares the two files (the components and the relations), so they cannot drift without a message.
- `bin/120-100-00-generate-rules.mjs` reads the exported JSON and writes `generated/ModelRulesTest.java` (ArchUnit) and `generated/rules.model.mjs` (ArchUniTS). The rule is the closed world: each ordered pair of components of one container without an arrow is a forbidden dependency. The files are committed, so the rules can be read without a run.
- This is a precursor of feat-50. It does not change the gates, and it does not replace the rules R1 to R3 of feat-7.
