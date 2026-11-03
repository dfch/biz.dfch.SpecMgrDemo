# tools/license

The files of the license gate (feat-5-foundation-monorepo-ci, REQ-006). The gate is `tools/gates/license-check.sh` (recipe `just license-check`).

| File | Content |
|---|---|
| `permitted-licenses.txt` | The permitted licenses. It has the same entries as the class Permitted in DEC 84c37f7d-08cb-457d-8ab3-1db37dba9bc9. The gate matches the complete expression, so `GPL-2.0-only WITH Classpath-exception-2.0` is permitted and `GPL-2.0-only` alone is not |
| `license-names.txt` | The table of names. It gives the SPDX expression of a license name that is not an SPDX identifier (for example `Apache License, Version 2.0`). A name that is not in the table is "not known", and the gate stops |
| `allowed-actions.txt` | The GitHub Actions of the license table with the release tag and the full SHA. `just check-pins` uses it |
| `fixtures/` | The SBOM files for the test of the license gate, and `expected.txt` with the expected result of each file. The test is `just test-license-gate` |

## How the gate decides

The gate reads each `*.json` file (CycloneDX) in the folder of the SBOM (`build/sbom/`). For each component, it reads `licenses`. It does not parse an expression by itself. The library `license-expression` parses it. The gate evaluates the parsed expression with the list:

- `A OR B` is permitted if one of them is permitted.
- `A AND B` is permitted if both are permitted.
- `A WITH B` is one entry. It must be in the list as a complete expression.
- Parentheses are handled by the library.
- A component with more than one entry in `licenses` is permitted only if all entries are permitted.

The gate fails closed. It stops for these reasons:

| Result | Reason |
|---|---|
| NOT PERMITTED | The license is known, but the evaluation with the list gives "not permitted" |
| NOT KNOWN | The library cannot parse the expression, or a license or an exception is not on the SPDX list, or the identifier is a `LicenseRef-` or `DocumentRef-`, or a license name is not in the table of names, or the component has no license |
| Exit code 2 | A file is wrong (not JSON, not CycloneDX, no `components` list, a wrong line in the list or in the table), so the gate cannot decide |

Note: `OR` with one unknown license is "not known" (for example `MIT OR FooBar-1.0`), also if the other alternative is permitted. The reason is that the gate fails closed. A deprecated identifier (for example `LGPL-3.0`) is read in its current form (`LGPL-3.0-only`) in the list and in the SBOM.

A change in this folder needs the review of a code owner. A change of `permitted-licenses.txt` needs a change of the DEC first.
