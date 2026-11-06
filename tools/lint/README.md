# `tools/lint`: the rules of the OpenAPI linter

The rules for `contracts/openapi.yaml`, and the bad files that are the test of the rules
(`feat-6-contracts-openapi-pipeline`, Task 110.115). The linter is Spectral. The pnpm project with the
lock file that installs Spectral is in `tools/spectral/`. `just lint` starts Spectral through
`tools/gates/lint.sh`:

```bash
just lint               # contracts/openapi.yaml with tools/lint/ruleset.yaml (exit code 0 if no message)
just test-lint-gate     # the file of the project and each fixture (tools/gates/test-lint-gate.sh), also part of `just test-gates`
```

A code owner reviews a change in this folder (`.github/CODEOWNERS` covers `/tools/`). A rule cannot be
switched off without the owner.

## Files

| File | Content |
|---|---|
| `ruleset.yaml` | The rules. The header of the file has the cause of each design point |
| `fixtures/*.yaml` | One OpenAPI file for each case (the case gives exit code 0, or it stops with the rules) |
| `fixtures/expected.txt` | One line for each fixture: `<file> \| PASS \| <cause>` or `<file> \| STOP <rule>,<rule> \| <cause>` |

## The rules

The gate starts Spectral with `--fail-severity warn`. A warning is a failure too. The group `spectral:oas`
(recommended) examines that the file is a correct OpenAPI file (valid references and schemas, no two
operations with the same `operationId`, no component that no part of the file uses, and more). The group has four
rules that are switched off. They have a decision about the tags and the contact of the document as
necessary, and not a decision about the interface: `info-contact`, `openapi-tags`, `operation-tags` and
`tag-description`. The rules of the project:

| Rule | Requirement | The rule stops |
|---|---|---|
| `problem-response-media-type-and-schema` | REQ-006, ACC-007 | A response with a status 4xx or 5xx (also `4XX`, `5XX` and `default`). The response is not `$ref: '#/components/responses/ProblemResponse'`. It has no media type `application/problem+json` with the schema `$ref: '#/components/schemas/Problem'`. The rule stops a different media type, a different schema, two media types and a response with no content. The rule is for each operation of `paths`, of `webhooks` and of a callback. A webhook is a path item. A callback is a member of an operation. It maps a value of the request to a path item |
| `problem-response-component` | REQ-006 | The same rule for the one response `components.responses.ProblemResponse` |
| `problem-schema-exists`, `error-code-schema-exists` | REQ-006 | A file with no schema `Problem` or no schema `ErrorCode`. A rule on a part that is not there does not stop. These rules look for the parts |
| `problem-code-required` | REQ-006, ACC-007 | A schema `Problem` with no member `code`, or with `code` that is not in `required` |
| `problem-trace-id-required` | REQ-006, ACC-007 | A schema `Problem` with no member `traceId` (the trace identifier of OpenTelemetry), or with `traceId` that is not in `required` |
| `problem-code-uses-shared-list` | REQ-006 | `Problem.code` that is not `$ref: '#/components/schemas/ErrorCode'`. A list that is in the schema is a second list. The generators can make two types |
| `problem-members` | REQ-006, DEC 51b00b5f-d1d8-49d8-9f40-28537ff69698 | A schema `Problem` that does not have the members `type`, `title`, `status`, `detail`, `instance`, `code` and `traceId` and no other member. A different member, for example `message` or `localizedMessage`, is a text in a language. A new member has a change of this rule as necessary |
| `error-code-list` | REQ-006 | A schema `ErrorCode` that is not a string enum with one value or more. It stops two values that are the same. It stops a value that is not in lower snake case (`^[a-z][a-z0-9_]*$`) |
| `operation-req-present` | REQ-008, ACC-007 | An operation (each `HTTP` method: `get`, `put`, `post`, `delete`, `options`, `head`, `patch`, `trace`) with no value in `x-specmgr-req`. The rule is for each operation of `paths`, of `webhooks` and of a callback. A webhook is a path item. A callback is a member of an operation. It maps a value of the request to a path item |
| `operation-req-uuid` | REQ-008, ACC-007 | A value of `x-specmgr-req` that is not a text in the form of a UUID. An operation with no value has the two rules. The rule is for the same operations as `operation-req-present` |
| `info-version-semver` | DEC 93594b2b-be54-4f60-9f53-ec2ce6c84be4 | An `info.version` that is not a Semantic Versioning 2.0.0 version |

Points that the rules must handle (see the header of `ruleset.yaml`):

- A rule that examines a `$ref` has `resolved: false`. Without it, Spectral replaces the `$ref` with its
  target. The rule cannot see which schema a response uses.
- A `given` path that matches no part is not an error. The parts that must be there have their rules
  (`problem-schema-exists`, `error-code-schema-exists`).
- The function `pattern` does not report a field that is missing. `x-specmgr-req` has two rules.

The check that the UUID in `x-specmgr-req` is the identifier of a REQ document that is in `docs/req/` is
not in this folder. It is GitHub issue #8 (the traceability check).

## The fixtures

`00-good-minimal.yaml` is a small file that gives exit code 0 (the two forms of an error response). Each
other bad file is that file with one change. The test (`tools/gates/test-lint-gate.sh`) starts `lint.sh`
for each fixture. It compares the exit code and the set of rules that Spectral reports with
`expected.txt`. A bad file stops with the rules of its line and with no other rule. A rule that does not
work at this time makes the test stop. The cases of ACC-007 are: the media type and the schema of a response
4xx and 5xx (01 to 10, 43, 49 and 51), no `code` (11 and 12), no trace identifier (13 and 14), no
`x-specmgr-req` (26, 27, 33, 35 to 41, 50 and 52) and a value that is not a UUID (28 to 32 and 42). The
fixtures 49 to 53 have a webhook and a callback. A webhook is a path item (it has operations). A callback
is a member of an operation (an object that maps a callback name to an object that maps a value of the
request to a path item). `53-good-webhook-callback.yaml` gives exit code 0 with the two forms. Some lines
have a second rule that Spectral reports for the same change (for example `oas3-unused-component` for a
schema that no part of the file uses at this time). A new Spectral version can change this set. `just test-lint-gate`
shows it.

To add a rule: write the rule in `ruleset.yaml`. Add a fixture that must stop with the rule. Add a line
in `expected.txt`. Start `just lint` and `just test-lint-gate`. Each fixture has a line in `expected.txt`.
Each line has a fixture. If not, the test stops.
