# The tools of the gates (state of the feat-9 branch, `tools/versions.env`)

Each CI job runs one `just` recipe. The versions are pinned in `tools/versions.env`, and `just check-pins` compares them with the manifests and lock files.

| Tool (version) | What it does | Recipe (CI job) |
|---|---|---|
| just 1.59.0 | The one entry point of every gate. A CI step may only run `just <recipe>` | all |
| uv 0.13.7, Python 3.13 | Run the gate scripts (`check_pins`, `check_workflows`, `traceability`, `license_check`) and the hash-locked Python tools | most |
| specmgr 0.38.0 | Lints the specmgr documents (`docs/`, `.specmgr/`). Its `find_references` is the base of the traceability check | `validate`, `traceability` |
| own scripts | Conventional Commits with the feature scope; workflow form; pins; `sudo` scan | `commit-check`, `check-workflows`, `check-pins`, `check-sudo` |
| cyclonedx-maven-plugin 2.9.3 | SBOM of the backend (CycloneDX 1.6, Maven) | `sbom`, `license-check` |
| cdxgen 12.9.0 | SBOM of the frontend (CycloneDX 1.6, from the pnpm lock file) | `sbom`, `license-check` |
| license-expression 30.4.4 | Reads the SPDX expressions of the SBOM and compares them with the permitted list | `license-check` |
| OSV-Scanner 2.7.1 | Known vulnerabilities in the SBOM components (report) | `vuln-scan` |
| gitleaks 8.30.1 | Secrets in the files and in the history (report) | `secret-scan` |
| zizmor 1.32.0 | Security problems in the GitHub workflows (report) | `workflow-scan` |
| CodeQL (hosted by GitHub) | Code scanning. No recipe and no job (default setup) | - |
| Spectral 6.17.0 | Lints `contracts/openapi.yaml` with the rules of the project (warnings fail) | `lint` |
| oasdiff 1.35.0 | Breaking changes of the OpenAPI file against the merge base | `breaking-changes` |
| openapi-generator-maven-plugin 7.27.0 | Spring server interfaces; the HTML of the API specification (`html2`) | `generate`, `check-generated`, `api-docs` |
| Kubb 5.15.3 (+ Zod 4.6.7) | TypeScript types and Zod schemas from the OpenAPI file | `generate`, `check-generated` |
| Maven 3.10.0 (wrapper), JDK 21, TypeScript 5.9.3 | Compile the backend and the frontend (`tsc --noEmit --strict`) | `compile` |
| JUnit 5.14.4, Testcontainers 1.21.4 | Unit and integration tests of the backend | `test-unit-backend`, `test-integration-backend` |
| jqwik 1.10.2, fast-check 4.10.2 | Property tests (backend, frontend) | `test-random-backend`, `test-random-frontend` |
| Vitest 5.1.0 | Unit tests of the frontend | `test-unit-frontend` |
| Playwright 1.65.0, axe-core 4.14.0 | End-to-end tests and the accessibility check | `test-e2e` |
| PIT 1.30.2, Stryker 10.1.1 | Mutation tests (report, no threshold) | `mutation-backend`, `mutation-frontend` |
| JaCoCo 0.8.16, @vitest/coverage-v8 | Coverage (numbers only, no CI job) | `coverage-backend`, `coverage-frontend` |
| Spring Modulith 2.0.9, ArchUnit 1.5.1 | Module structure and layer rules of the backend | `architecture-backend` |
| ArchUniTS 2.5.4 | Layer and import rules of the frontend | `architecture-frontend` |
| structurizr-client 6.2.4 | Reads `model/workspace.json` for the comparison of the model with the code | `architecture-model` |
| Structurizr (image 2026.10.26, feat-0 demo only) | DSL, views, static site, SVG | demo, not a gate |
