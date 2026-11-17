---
marp: true
theme: default
paginate: true
size: 16:9
style: |
  section { font-size: 24px; padding: 40px 56px; }
  h1 { font-size: 40px; color: #08427b; }
  h2 { font-size: 32px; color: #08427b; margin-bottom: 8px; }
  table { font-size: 20px; }
  code { font-size: 0.85em; }
  .small { font-size: 18px; }
  .tiny, .tiny li, .tiny p { font-size: 19px; line-height: 1.25; }
  .small table { font-size: 14px; }
  .small td, .small th { padding: 3px 8px; }
  .cols { display: grid; grid-template-columns: 1fr 1fr; gap: 28px; }
  img { max-width: 100%; }
---

# Specs the build enforces

**SpecMgrDemo: specmgr + autonomous coding, with gates**

Ronald Rink - technical presentation for the head of development

- The product code is a placeholder (one operation: `GET /status`). **The policies, the standards and the gates are the product.**
- Work in progress: this talk shows what runs today, and what does not yet.

<div class="small">

**Where it differs from typical "spec frameworks"** (my judgement, not a check of their current versions): they produce markdown specs and rely on the agent to follow them. Here **a CI gate checks the link from spec to code**, and the rules for agents are recorded decisions with an owner.

</div>

---

## 1. One chain, checked by a gate

`GOL -> REQ -> SYSRS -> VCR -> test -> OpenAPI -> model`, all by **specmgr UUID** (DEC `f21920d2`)

| Link | Example (`GET /info`, feat-9 branch) |
|---|---|
| REQ (EARS: "WHEN ... THE system must ...") | `271168a4-...` |
| VCR (`## Verifies` the REQ) | `eb8a7f16-...` |
| Test title | `vcr:eb8a7f16-... the operation gives the identification and the license` |
| OpenAPI | `x-specmgr-req: 271168a4-...` on `GET /info` |
| Model element | property `specmgr-req` on component `api` |

`just traceability` (733 lines, 32 fixture cases): **error** if an approved REQ has no VCR, a `vcr:` id has no document, or a reference has no target. The id is a UUID, so it survives renames.

<div class="small">

Status: the gate is done and merged. feat-9 is the first feature that fills the chain end to end (VCRs still `draft` at the time of writing).

</div>

---

## 2. Gates that fail closed, and are tested

<div class="cols"><div>

- **27 CI jobs**, each exactly `just <recipe>`. `check_workflows` rejects any other form (no `env`, `needs`, `continue-on-error`).
- A missing gate script gives "NOT IMPLEMENTED", never a pass. An empty SBOM is a failure.
- **The gates have tests:** 1148 self-test cases on the feat-9 branch (good and bad fixtures). `Broken*` rules must fail and name the violation.
- **Breaking changes** (oasdiff) need an ignore line **and** a version bump.

</div><div>

- **Supply chain:** actions pinned to a full SHA, hash-locked Python tools, pnpm lock files, sha256 for binaries and Maven plug-ins. Known limit stated openly: Maven plug-in dependencies (issue #23).
- **Libraries:** licence classes in DEC `84c37f7d`. `license-check` reads the CycloneDX SBOM and fails closed on unknown licences. An exception needs a dated owner entry (DEC `93a6d588`).
- **Real example:** OSV found 2 Critical findings in Spring 6.2.19 with no fix on that line. The agent stopped, the owner decided, the project moved to Spring Boot 4.0.9.

</div></div>

---

## 3. SBOM: made by the gate, used by two gates

<div class="cols"><div class="small">

- `just sbom` makes **CycloneDX 1.6** (JSON): `build/sbom/backend.cdx.json` (Maven, **55 components**) and `build/sbom/frontend.cdx.json` (pnpm lock file, **451 components**). Not in git.
- **CI keeps both files** as the artifact `sbom` of the job `license-check` (90 days, also when the gate fails).
- `license-check` compares each SPDX expression with the permitted list (DEC `84c37f7d`): **506 components, all permitted** (run on the feat-9 branch).
- `vuln-scan` gives the same files to OSV-Scanner.

</div><div class="small">

**Fail closed**
- A `pom.xml`, `package.json` or lock file outside the scanned set stops the gate (no hidden manifest).
- A manifest with dependencies but an SBOM without components stops the gate.
- A component without a licence, or an unknown licence, stops the gate.
- The SBOM tools are hash-locked (cdxgen lock file, plug-in jar sha256).

**Not done:** the SBOM is not signed or attested, and no release publishes it yet (no release exists). Dev-only tools with a non-permitted licence (`axe-core`, `caniuse-lite`) are removed from the frontend SBOM under a recorded owner decision (DEC `93a6d588`).

</div></div>

---

## 4. The tools of the gates

<div class="small">

| Area | Tools (pinned in `tools/versions.env`) | Used in |
|---|---|---|
| Entry and scripts | just 1.59, uv 0.13 + Python 3.13, own scripts (pins, workflows, `sudo`, commits) | all, `check-*`, `commit-check` |
| Documents, traceability | specmgr 0.38 (`lint`, `find_references`) | `validate`, `traceability` |
| SBOM and licences | cyclonedx-maven-plugin 2.9.3, cdxgen 12.9, license-expression | `sbom`, `license-check` |
| Security | OSV-Scanner 2.7, gitleaks 8.30, zizmor 1.32, CodeQL (GitHub) | `vuln-scan`, `secret-scan`, `workflow-scan` |
| Contract | Spectral 6.17 (lint), oasdiff 1.35 (breaking changes), openapi-generator 7.27, Kubb 5.15 + Zod | `lint`, `breaking-changes`, `generate`, `api-docs` |
| Build | Maven 3.10 (wrapper), JDK 21, TypeScript 5.9 | `compile` |
| Tests | JUnit 5, Testcontainers, jqwik, Vitest, fast-check, Playwright + axe-core | `test-unit-*`, `test-integration-*`, `test-random-*`, `test-e2e` |
| Mutation, coverage | PIT, Stryker, JaCoCo, v8 coverage | `mutation-*`, `coverage-*` (reports) |
| Architecture | Spring Modulith, ArchUnit, ArchUniTS, structurizr-client | `architecture-backend`, `-frontend`, `-model` |
| Gates of the gates | `selftest.sh` and the `test-*-gate` scripts | `test-gates` |

</div>

<div class="small">Demo only (not a gate): Structurizr (DSL, views, static site, SVG), Marp (this PDF), Playwright (screenshots).</div>

---


## 5. Architecture is a checked contract, not a diagram

<div style="text-align:center">

![w:860](images/model-Backend.svg)

</div>

<div class="small">

- Structurizr model with **context, container and component views**. Elements carry `code.*` (where the code is) and `specmgr-req`.
- Rules **derive from the model** (closed world): no arrow means a forbidden dependency. Backend: **3 ArchUnit rules**, frontend: **41 ArchUniTS rules**. Demo: add one forbidden import, the generated rule fails and names it.
- Today the repo also has hand-written rules and a model-vs-code comparison. The DSL and the generator are a demo slice (feat-0). DSL as the source of the repo is planned (feat-50). A model generated from REQs is **not** built.

</div>

---

## 6. Agents with boundaries, on a running system

<div class="cols"><div>

- **Limits as decisions** (DEC `cc4449cd`): an agent must not accept a DEC, lower a threshold, disable a gate, or add a dependency without a licence check. CODEOWNERS covers DECs, workflows, `justfile`, `tools/`.
- **Orchestrator** (cannot edit, cannot push) runs one fresh **implementer** per phase and re-runs the gates itself. Reviewer agents list findings with file and line.
- **Plans are the memory:** phases, tasks, owner decisions with dates, handover notes.
- Tool output is untrusted: the jqwik jar prints text that tells AI agents to ignore results. It is recorded, and agents ignore it.

</div><div>

![w:520](images/ui-up-en.png)
![w:520](images/api-docs.png)

<div class="small">

The walking skeleton: React UI (EN/DE), `GET /status`, `GET /info`, API docs from `contracts/openapi.yaml`.

</div>

</div></div>

---

## 7. Decisions and risks of this demo

<div class="cols tiny"><div>

**21 DECs, all accepted by the owner**

- **Traceability, docs:** `f21920d2` UUID traceability, `2468257f` one source of truth, `00a85fb8` ISO 29148 mapping, `7784ddef` ISO 25010 scenarios, `eb6e66ca` STE writing, `9eade4ab` terminology register
- **Gates, quality:** `361678a6` test pyramid + blocking gates, `93594b2b` breaking changes, `f92e35a1` OpenAPI first, `9edc1071` code obeys the model
- **Licences:** `84c37f7d` AGPL-compatible only, `93a6d588` deviation register, `5ddd8d7a` licence in `/info`
- **Process, agents:** `cc4449cd` agent limits, `d778d444` dev/main rules, `a56f231b` commits + Definition of Done, `50ade92a` data classes
- **Technology:** `870244cf` monorepo, `1a29c825` React, `51b00b5f` i18n, `e3eadec0` OpenTelemetry

</div><div>

**6 risks, all open**

- `025202ba` ArchUniTS cannot do each necessary rule
- `3be3ffd7` a necessary tool can break the licence rule
- `5dfbf884` specmgr has no French headings, no SRS type
- `edee1891` blocking gates slow down agents and authors
- `f126e1b7` STE limits the words for specifications
- `f682b3fb` a code generator can cause delay

Every DEC and RSK is a specmgr document, linted in CI and cited by UUID. Only the owner accepts a DEC.

</div></div>

---

## 8. Honest status

| Done and merged | In progress or planned |
|---|---|
| Traceability gate, security reports (OSV, gitleaks, zizmor, CodeQL) | feat-9 walking skeleton: phases 100-400 on a branch, security thresholds not started |
| Contract pipeline, breaking-change policy | feat-50 model as DSL source and generic rules (plan only) |
| Pins, licence gate, SBOM, tested gates | feat-48 pre-commit hooks (plan only) |
| 21 DECs, 4 SOPs, all validated by `specmgr lint` | ASD-STE100 check (on hold by owner decision) |

**Weak points, stated plainly**
- Thin demo on `dev`: **one REQ**, one operation. Coverage and mutation score are low (backend line coverage 12%, PIT 5.8% on `dev`), **no thresholds**. Security findings do not block yet.
- Agent boundaries are **not machine-enforced** (agents use the owner's token). No `AGENTS.md` or opencode config in the repo. The agent prompts still name gates of a sibling repo.
- Rulesets live in GitHub settings, not in git. No release or tag yet. No legal review of the licence entries. The SBOM is not signed.
