---
classification: null
created: '2026-11-13T13:26:20.564+01:00'
id: 31335cec-5c52-419b-86c6-f1030828b0dc
status: draft
type: txt
updated: '2026-11-13T13:26:20.564+01:00'
version: 1.0.0
---

# Feature Work at the Same Time as the feat-7 Review

This TXT gives the result of the check of the feature work on 2026-11-13. Another agent works on feat-7-verification-architecture-tools at the same time. The TXT lists the work that an agent can start at the same time and the work that waits for the merge of feat-7.

## Current State

- feat-7 has the status `review`. The other agent is still active: it changes files of `tools/`, `frontend/`, `backend/`, `.github/workflows/ci.yml` and the `justfile`.
- feat-1-frontend-technology-decision has all tasks done. It waits for the owner to set the status `done`.
- feat-2, feat-3, feat-5, feat-6, feat-16 and feat-22 have the status `done`.
- The feature of the walking skeleton does not exist at this time. feat-7 blocks it, because the skeleton sets each threshold from the baseline that feat-7 measures.

## Work That an Agent Can Start at the Same Time

| Work | Reason |
|---|---|
| The requirements of the canteen application in the levels of ISO 29148: the business requirements, the stakeholder requirements and the system requirements, with the goal and the test of each requirement (deferred in feat-1; mapping DEC 00a85fb8) | It changes only the documents of `docs/` and `.specmgr/`. It does not touch the files of feat-7. It gives the input to the walking skeleton. |
| The plan of the walking skeleton feature, written as a new FEAT document | A new document of `.specmgr/feat/` only. The work of the code starts after the merge of feat-7. The plan uses the OpenAPI contract of feat-6. |
| The tool selection and the license check of GitHub issue #8 (the traceability check and the security checks) | The selection and the license table are document work. The new gates go into `tools/gates/`, the CI workflow and the `justfile`, the files of feat-7. This work follows the merge of feat-7. |
| The user configuration of the asdste100 MCP that loads the register files of `terminology/en/` | A configuration change only. The owner decides. |

## Work That Waits for the Merge of feat-7

- GitHub issue #45, "Gates: the self-test reuses the Python environment of the gates": it changes `tools/gates/_lib.sh` and `tools/gates/selftest.sh`.
- GitHub issue #23, "Gates: pin the dependencies of cyclonedx-maven-plugin": it changes `tools/gates/sbom*.sh` and can change `backend/pom.xml`.
- GitHub issue #31, "Process: reduce the cost of pull requests for document-only changes", option B: it changes the recipes `test-gates` and `license-check`. The owner decides between option B and option C first.

## Suggested Order

1. The requirements of the canteen application, as a new feature.
2. The plan of the walking skeleton, after the requirements exist.
3. The tool selection and the license check of issue #8, now; the new gates, after the merge of feat-7.
4. The owner: sets feat-1 to `done`, decides issue #31 and the MCP configuration.

FEAT feat-7-verification-architecture-tools: Verification and Architecture Tools with Baseline Measurement
FEAT feat-1-frontend-technology-decision: Frontend Technology Decision for Java Backend Web App
DEC 00a85fb8-19a2-4850-bf5f-4a18e47d46e9: Use One Mapping of ISO 29148 Levels to Specmgr Artifacts
DEC 361678a6-f941-473b-a058-1ba2bacf7d3d: Use a Test Pyramid and Blocking Gates for Verification
DEC 84c37f7d-08cb-457d-8ab3-1db37dba9bc9: Use Only Open Source Libraries That Are Compatible With AGPL-3.0-only

## Updates

<!-- Newest entry first -- prepend new entries directly below this comment. -->

### 2026-11-13 12:25:57.000Z - Created

The TXT is written from the check of the feature work of 2026-11-13.
