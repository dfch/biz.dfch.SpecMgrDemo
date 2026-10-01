---
classification: null
created: '2026-10-01T08:57:58.660+02:00'
id: cd9040d6-3a96-4c6d-9117-4a2abbb4e62f
status: draft
type: qa
updated: '2026-10-01T08:57:58.660+02:00'
version: 1.0.0
---


# Frontend Technology Decision — Requirements Interview

## General

### Introduction

This Q&A captures the short requirements-elicitation conversation backing FEAT feat-1-frontend-technology-decision (frontend technology choice for the Java-backed web application, tracked from gh #1 "Initial design considerations"). Conducted as a single interactive session with the requester acting as ARCH/BA for this decision.

### Raw Requirements

Prior to structured elicitation, the following constraints were stated directly: Java must be used for the backend (organisational standard, no exception); the frontend must be usable from desktop and mobile (tablet or phone); the organisation prefers Angular, but with no documented reason for that preference.

## Elicitation Context

> **0.0010**: Why must Java be used for the backend?

It is the organisation's standard backend platform — non-negotiable, no exception or further discussion in scope.

> **0.0020**: Why does the organisation prefer Angular?

Asked directly: the answer given is that Angular is the preference of a leading architect who happens to be most familiar with Angular himself. No further documented technical, hiring, tooling, or compliance rationale was provided.

## Functional Suitability

> **1.0010**: What level of interactivity/responsiveness does the frontend need?

A highly interactive, responsive frontend is desired. In particular, the application must fulfill delicate organisational CI/CD visualisation requirements (e.g., pipeline/DAG-style views).

## Performance Efficiency

## Compatibility

> **2.0010**: Does the application need to be an installable app-store application (native or hybrid), or is a browser-driven app sufficient?

An app-store app is not necessary; an HTML/browser-driven app is acceptable. This removes any need for a hybrid shell or installable-PWA behaviour as a hard requirement.

## Interaction Capability

## Reliability

## Security

## Maintainability

> **3.0010**: Does the team's existing Angular know-how constrain the technology choice?

Angular know-how exists within the organisation, but it is not a binding constraint: the application will be built using a coding agent fluent in all mainstream frontend technologies, neutralising "team familiarity" as an argument for defaulting to Angular.

## Flexibility

## Safety

## More Information

Categories not populated above (Performance Efficiency, Interaction Capability, Reliability, Security, Flexibility, Safety) had no elicited content in this short session; nothing relevant to them came up, so they are left empty rather than filled with placeholder TODOs.

See also gh issue [Initial design considerations](https://github.com/dfch/biz.dfch.SpecMgrDemo/issues/1).
