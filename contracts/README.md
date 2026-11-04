# contracts

The interface contracts. The OpenAPI file is written first, and the code is generated from it (DEC f92e35a1-77a2-4749-917f-bf9b644e8ddd).

| File | Content |
|---|---|
| `openapi.yaml` | The only source for the interfaces between the backend and the frontend (OpenAPI 3.1.0). It has one example operation: `GET /status` |

The pipeline is the work of feat-6-contracts-openapi-pipeline. The lint is done (phase 110). The check for breaking changes, the generators and the gate for generated code are not yet done (phases 115, 120 and 130).

## A change of an interface starts in the OpenAPI file

Do not start a change of an interface in the backend or in the frontend. Change `contracts/openapi.yaml` first, then make the code again. A change that removes or changes something that a client uses is a breaking change. It needs a higher `info.version` and an entry in an ignore file below `tools/` that the owner examines (DEC 93594b2b-be54-4f60-9f53-ec2ce6c84be4). The gate for breaking changes is phase 115.

## Generated code

The generators make this code from the OpenAPI file. Both folders are committed to git, so that a gate can compare them with a new generation:

| Folder | Content | Generator |
|---|---|---|
| `backend/src/generated` | The Spring server interfaces (Java) | `openapi-generator` 7.27.0, generator `spring` |
| `frontend/src/generated` | The Zod schemas (TypeScript), with the list of error codes | Kubb |

These folders do not exist yet. Phase 120 makes them, and each folder gets a mark "generated, do not change". Nobody changes a generated file by hand. The gate for generated code (phase 130) makes the code again and stops the pull request if the result is not the same as the code in the repository. This includes a file that is changed, deleted or added. Change the OpenAPI file and make the code again.

## Lint

```bash
just lint
```

The recipe installs Spectral from the lock file in `tools/spectral/` and examines `contracts/openapi.yaml` with the rules in `tools/lint/ruleset.yaml` (see `tools/lint/README.md`). It must return exit code 0. A warning is a failure too.

## The rules that this file must obey

- **Problem Details (REQ-006).** Each response with a status 4xx or 5xx (also `4XX`, `5XX` and `default`) uses the shared response `#/components/responses/ProblemResponse`, or it has exactly one media type, `application/problem+json`, with the schema `#/components/schemas/Problem`. The schema `Problem` is RFC 9457 (Problem Details). It has the required members `code` and `traceId` (the trace identifier of OpenTelemetry, DEC e3eadec0-a6ea-4efe-8e6d-fd19287122fa). `code` is a `$ref` to the one list `ErrorCode` (a string enum with unique values in lower snake case, for example `not_found`). The schema has no text in a language (DEC 51b00b5f-d1d8-49d8-9f40-28537ff69698): the backend sends the code, and the frontend shows the text for the code. `title` and `detail` are for logs and developers.
- **`x-specmgr-req` (REQ-008).** Each operation has the extension `x-specmgr-req` with the identifier (a UUID) of its REQ document in `docs/req/`. Make the REQ first (SOP 95b6735b-03b8-47a0-92aa-7934a4ff1519). The operation `GET /status` has the identifier of the REQ "The System Gives Its Status". The lint stops an operation with no value or with a value that is not a UUID. The check that the UUID is the identifier of a real REQ document is GitHub issue #8 (DEC f21920d2-4da5-4cf7-bd94-2e9bcba77342).
- **Version.** `info.version` is the version of the interface (Semantic Versioning 2.0.0).

Do not add a `package.json` in this folder. The SBOM gate (`just sbom`) stops for a manifest in `contracts/`.
