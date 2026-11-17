---
classification: null
created: '2026-11-17T09:22:51.752+01:00'
id: 848be85d-ba2c-44ec-b2d2-66fb0e6c84ef
status: draft
type: req
updated: '2026-11-17T09:29:12.806+01:00'
version: 1.0.0
---

# The User Interface Shows an Error in the Language of the User

IF the backend gives an error response, THE user interface must show a text for the error code in the language of the user and the trace identifier. It must not show the text that the backend sends.

## Description

The backend sends an error response with the media type `application/problem+json`. The response has an error code and a trace identifier. It has no text in a language (REQ 1ca335d7-969a-443e-9392-165fdeea99a0). The user interface does these things:

1. It shows a heading that says the information is not available.
2. It shows the text that is in its catalog for the error code, in the selected language.
3. It shows the trace identifier, so the user can give it to the service desk.
4. It does not show the members `title` and `detail` of the response. They are for logs and developers.

If the backend gives no response, the user interface shows a text for this case. If the backend sends a response that the user interface cannot read, the user interface shows a text for this case. These two cases have no trace identifier.

The error of one section does not change the other sections. The section of the status and the section of the notice can show an error separately.

## Characteristics

1. Reliability
2. Interaction Capability

## Level

MUST

## Priority

50

## Tags

- iso29148:strs
- ui
- i18n

## Source

FEAT feat-0-demoprep. On 2026-11-17, the owner told the author to write use cases and requirements that describe, from the view of the user, the demo with the dual-language user interface. The behavior is the behavior of the user interface of FEAT feat-9-walking-skeleton (Phase 300). The demo shows this behavior with the option `--fail` of the script `bin/130-100-00-run-demo.sh`.

## Related Artifacts

### Requirements

- REQ 1ca335d7-969a-443e-9392-165fdeea99a0: The System Gives Its Status

### Decisions

- DEC 51b00b5f-d1d8-49d8-9f40-28537ff69698: Use Internationalization in the Application From the Start
- DEC e3eadec0-a6ea-4efe-8e6d-fd19287122fa: Use OpenTelemetry for Observability

### Goals

- GOL b94e2758-3368-407e-8fee-827c897e192b: Show the Goal and the Test of Each Requirement

## More Information

The catalog has one text for each error code of the contract: `not_found`, `validation_failed`, `rate_limited`, `internal_error` and `service_unavailable`.

The verification case record of this requirement is VCR d99b707f-bd15-4d41-85d5-1ba85ec9c997: Verification of the Error Display of the User Interface. The use cases of this requirement are UC aa8f713b-946f-4625-bf64-aa827ee5aa56: View the System Status, UC 0dbd4917-2a33-4b9f-8180-8ecac6a74f4c: View the Version and the License Notice and UC 3ecb44fa-73d5-4985-9444-bfb444c321b3: Choose the Language.

## Notes

The status of this requirement is `draft`. The owner has not accepted it.
