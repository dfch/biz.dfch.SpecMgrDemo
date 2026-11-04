# tools/lint: the rules of the OpenAPI linter

The rules for `contracts/openapi.yaml` and the bad files that test them (feat-6-contracts-openapi-pipeline,
Task 110.115). The linter is Spectral. The pnpm project with the lock file that installs it is in
`tools/spectral/`. `just lint` starts it through `tools/gates/lint.sh`:

```bash
just lint               # contracts/openapi.yaml with tools/lint/ruleset.yaml (exit code 0 if no finding)
just test-lint-gate     # the real file and each fixture (tools/gates/test-lint-gate.sh), also part of `just test-gates`
```

A change in this folder needs the review of a code owner (`.github/CODEOWNERS` covers `/tools/`), so a rule
cannot be switched off without the owner.

## Files

| File | Content |
|---|---|
| `ruleset.yaml` | The rules. The header of the file has the cause of each design point |
| `fixtures/*.yaml` | One OpenAPI file for each case that must pass or must fail |
| `fixtures/expected.txt` | One line for each fixture: `<file> \| PASS \| <cause>` or `<file> \| STOP <rule>,<rule> \| <cause>` |

## The rules

The gate starts Spectral with `--fail-severity warn`, so a warning is a failure too. The group `spectral:oas`
(recommended) checks that the file is a correct OpenAPI file (valid references and schemas, a unique
`operationId`, no unused component, and more). Four rules of that group are switched off, because they need a
decision about the organization and not about the interface: `info-contact`, `openapi-tags`, `operation-tags` and
`tag-description`. The rules of the project:

| Rule | Requirement | What it stops |
|---|---|---|
| `problem-response-media-type-and-schema` | REQ-006, ACC-007 | A response with a status 4xx or 5xx (also `4XX`, `5XX` and `default`) that is not `$ref: '#/components/responses/ProblemResponse'`, and does not have exactly one media type, `application/problem+json`, with the schema `$ref: '#/components/schemas/Problem'`. This includes another media type, another schema, two media types and a response with no content |
| `problem-response-component` | REQ-006 | The same rule for the shared response `components.responses.ProblemResponse` |
| `problem-schema-exists`, `error-code-schema-exists` | REQ-006 | A file with no schema `Problem` or no schema `ErrorCode` (a rule on a part that is not there does not fail, so these rules look for the parts) |
| `problem-code-required` | REQ-006, ACC-007 | A schema `Problem` with no member `code`, or with `code` that is not in `required` |
| `problem-trace-id-required` | REQ-006, ACC-007 | A schema `Problem` with no member `traceId` (the trace identifier of OpenTelemetry), or with `traceId` that is not in `required` |
| `problem-code-uses-shared-list` | REQ-006 | `Problem.code` that is not `$ref: '#/components/schemas/ErrorCode'` (an inline list is a second list, and the generators would make two types) |
| `problem-members` | REQ-006, DEC 51b00b5f-d1d8-49d8-9f40-28537ff69698 | A schema `Problem` that does not have exactly the members `type`, `title`, `status`, `detail`, `instance`, `code` and `traceId`. Another member, for example `message` or `localizedMessage`, is a text in a language. A new member needs a change of this rule |
| `error-code-list` | REQ-006 | A schema `ErrorCode` that is not a string enum with at least one value, with values that are not unique, or with a value that is not in lower snake case (`^[a-z][a-z0-9_]*$`) |
| `operation-req-present` | REQ-008, ACC-007 | An operation (each HTTP method: `get`, `put`, `post`, `delete`, `options`, `head`, `patch`, `trace`) with no value in `x-specmgr-req` |
| `operation-req-uuid` | REQ-008, ACC-007 | A value of `x-specmgr-req` that is not a text in the form of a UUID. An operation with no value has both findings |
| `info-version-semver` | DEC 93594b2b-be54-4f60-9f53-ec2ce6c84be4 | An `info.version` that is not a Semantic Versioning 2.0.0 version |

Points that the rules must handle (see the header of `ruleset.yaml`):

- A rule that checks a `$ref` has `resolved: false`. Without it, Spectral replaces the `$ref` with its target, and
  the rule cannot see which schema a response uses.
- A `given` path that matches nothing is not an error, so the parts that must be there have their own rules
  (`problem-schema-exists`, `error-code-schema-exists`).
- The function `pattern` does not report a field that is missing, so `x-specmgr-req` has two rules.

The check that the UUID in `x-specmgr-req` is the identifier of a real REQ document is not in this folder. It is
GitHub issue #8 (the traceability check).

## The fixtures

`00-good-minimal.yaml` is a small file that passes (both forms of an error response). Each other bad file is that
file with one change. The test (`tools/gates/test-lint-gate.sh`) starts `lint.sh` for each fixture and compares
the exit code and the set of rules that Spectral reports with `expected.txt`. So a bad file must fail with the
rules of its line and with no other rule, and a rule that does not work any more makes the test fail. The cases of
ACC-007 are: the media type and the schema of a response 4xx and 5xx (01 to 10 and 43), no `code` (11 and 12), no
trace identifier (13 and 14), no `x-specmgr-req` (26, 27, 33 and 35 to 41) and a value that is not a UUID (28 to 32
and 42). Some lines have a second rule that Spectral reports for the same change (for example
`oas3-unused-component` for a schema that nothing uses any more). A new Spectral version can change this set, and
`just test-lint-gate` shows it.

To add a rule: write the rule in `ruleset.yaml`, add a fixture that must fail with it, add a line in
`expected.txt`, and run `just lint` and `just test-lint-gate`. Each fixture has a line in `expected.txt` and each
line has a fixture, or the test fails.
