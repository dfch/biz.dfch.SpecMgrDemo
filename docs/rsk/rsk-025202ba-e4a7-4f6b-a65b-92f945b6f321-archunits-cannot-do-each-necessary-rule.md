---
classification: null
created: '2026-11-02T14:45:23.225+01:00'
id: 025202ba-e4a7-4f6b-a65b-92f945b6f321
status: open
type: rsk
updated: '2026-11-17T11:54:03.081+01:00'
version: 1.0.0
---

# ArchUniTS Cannot Do Each Necessary Rule

## Cause

ArchUniTS is a new tool. The project does not know its maturity.

## Trigger

A rule about architecture is not possible in ArchUniTS, or the tool has a defect.

## Consequence

The architecture of the frontend is not examined, or the project must use one more tool.

## Scope

- Architecture tests of the frontend

## Initial Assessment

### Probability 3

### Impact 3

## Strategy

reduce

## Mitigation

Write the same rules as in the backend with ArchUniTS in the skeleton. If a rule is not possible, write a DEC for one more tool. The spike of Phase 100 of feat-50-structurizr-model-rules (2026-11-17) confirms this mitigation for each category of rule that the model gives: the rules are built from the JSON of the model with the pinned tools (ArchUnit 1.5.1 for the backend, ArchUniTS 2.5.4 for the frontend), a green case and a red case (the violation is named by the tool) exist for each category, and the closed-set check stays in the comparison analyzers (`ModelComparisonTest` and `frontend/architecture/compare.mjs`), as the known limit of ArchUniTS since feat-7-verification-architecture-tools (unchanged by the spike). The trigger of this risk (a necessary rule that is not possible, or a defect of the tool) is not confirmed by the spike; the new limits of the tools are in More Information below.

## Residual Assessment

### Probability 2

### Impact 2

## Owner

Maintainer of the architecture.

## Tags

- architecture

## Source

Planning session of 2026-11-02. DEC 9edc1071-4fd0-48b6-a037-1a4cb2331f73.

## More Information

The result of the spike of Phase 100 of feat-50-structurizr-model-rules (2026-11-17, DEC e85e9685-0787-4dff-9ee5-9d46670e9ee4 records it in the section "The language skew").

- What worked: the rules are built from the JSON of the model at run time in both languages. In the backend (ArchUnit 1.5.1, the reader structurizr-client 6.2.4): the forbidden pair `model -> api` of the container `backend` is derived from the workspace, the derived rule is green, and the violated direction (`api -> model`, the dependency the code has) is red with the violation named by ArchUnit (the method of the interface `StatusApi` with the generic return type of the class `Status`). In the frontend (ArchUniTS 2.5.4, the strict reader as in `compare.mjs`): the 10 forbidden pairs of the container `frontend` are derived from the workspace, all 10 checks are green on the committed code, and the violated direction (`test -> zod` asserted as forbidden) is red with the 4 violating imports named.
- The limits of ArchUnit (the backend): a component with several packages is supported (the predicate `resideInAnyPackage`, verified in the probe). A reference by type only (a method signature, a field type) is visible (the probe: the interface `StatusApi` references the model only in the signature, and ArchUnit counts the dependency). A dependency by reflection or by injection (for example the wiring of the framework) is not visible (the tool examines the bytecode).
- The limits of ArchUniTS (the frontend): a unit with several folders is supported with a pattern of the type RegExp (verified in the probe), and not with a text glob of the form `(a|b)` (the matcher escapes the parentheses, and no file matches). A type-only import (`import type`) is visible (verified in the probe). A dynamic import (`await import()`) is invisible (the tool reads only the import declarations). A construct `export ... from` is invisible for the tool, and the comparison (`compare.mjs`) counts it as a dependency. A construct `require()` is invisible for the tool, and the comparison stops for it (exit code 2).
- A defect of the project's own script: the header of `frontend/architecture/compare.mjs` says that a dynamic import stops the script. With the pinned typescript 5.9.3, the construct `import()` is silently ignored (its expression in the AST is the token `import`, and not an identifier; the check of the script tests for an identifier). The probe shows that a file with a dynamic import passes the comparison, and that a file with `require()` stops it. The fix of this check is part of Task 130.130 of feat-50-structurizr-model-rules (the refactor of the reader onto the rule set).
