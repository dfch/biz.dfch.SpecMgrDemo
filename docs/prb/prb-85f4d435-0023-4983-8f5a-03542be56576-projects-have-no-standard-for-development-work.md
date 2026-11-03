---
classification: null
created: '2026-11-02T14:37:35.090+01:00'
id: 85f4d435-0023-4983-8f5a-03542be56576
status: draft
type: prb
updated: '2026-11-02T15:17:51.980+01:00'
version: 1.0.0
---

# Projects Have No Standard for Development Work

The work method is causing quality problems, for development teams because the teams have no policy baseline.

## Current State

### Summary

No policy gives the procedure to write and examine requirements, architecture, contracts, tests and quality. Each project selects different tools and a different quality level. Coding agents write most of the code. They must have clear rules that a tool can examine.

### What Is the Problem?

Policies are missing, or tools do not examine them. Documents and code give different values for the same fact.

### Why Is It a Problem?

The quality is different between projects. A reviewer cannot show that the software does the function in a requirement. Coding agents have no limits and make decisions that no person examines.

### Who Is Impacted?

Developers, reviewers, coding agents and the owners of the software.

## Gap

At this time no automatic gate examines the links between requirements and tests, the interface files, the architecture or the licenses. The target is a blocking gate for each of these.

## Impactt

More defects occur and more work is necessary to correct them. A license violation can stop the project from giving the software to users.

## Future State

The project has a policy baseline in specmgr documents. Blocking gates examine each policy. A new project can use the baseline with no change.

## References

- The plan feat-3-process-policy-baseline gives the work.
- GitHub issue #1 is the first design issue.
