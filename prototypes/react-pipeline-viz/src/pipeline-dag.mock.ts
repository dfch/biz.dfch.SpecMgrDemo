/**
 * Copy of the canonical shared mock CI/CD pipeline DAG dataset.
 *
 * SOURCE OF TRUTH: prototypes/shared/pipeline-dag.mock.ts
 * (feat-2-react-angular-visualization-spike, Task 100.120 / REQ-004).
 *
 * The data section below (from `export type PipelineJobStatus` onward) is
 * kept byte-identical to the canonical file. A literal cross-package
 * TypeScript import from this independently-scaffolded Vite/React app back
 * into prototypes/shared is out of scope for this spike, so this file is a
 * plain copy instead -- if the canonical file changes, copy the change
 * here too (and into the Angular prototype's copy).
 */

export type PipelineJobStatus = "success" | "failed" | "running" | "pending" | "skipped";

export interface PipelineJob {
  /** Unique, stable identifier for this job (used as the DAG node id). */
  id: string;
  /** Human-readable label for display. */
  label: string;
  /** The pipeline stage this job belongs to. */
  stage: string;
  /** Current execution status of this job. */
  status: PipelineJobStatus;
  /** IDs of this job's direct DAG predecessors (upstream dependencies). */
  dependsOn: string[];
}

export const PIPELINE_STAGES: readonly string[] = [
  "build",
  "test",
  "security-scan",
  "deploy-staging",
  "deploy-prod",
];

export const PIPELINE_JOBS: readonly PipelineJob[] = [
  { id: "build-checkout", label: "Checkout", stage: "build", status: "success", dependsOn: [] },
  { id: "build-compile", label: "Compile", stage: "build", status: "success", dependsOn: ["build-checkout"] },

  // Fan-out: build-compile feeds two parallel jobs in `test` ...
  { id: "test-unit", label: "Unit Tests", stage: "test", status: "success", dependsOn: ["build-compile"] },
  {
    id: "test-integration",
    label: "Integration Tests",
    stage: "test",
    status: "failed",
    dependsOn: ["build-compile"],
  },

  // ... and two parallel jobs in `security-scan`.
  {
    id: "security-scan-sast",
    label: "Static Analysis (SAST)",
    stage: "security-scan",
    status: "success",
    dependsOn: ["build-compile"],
  },
  {
    id: "security-scan-dependency-audit",
    label: "Dependency Audit",
    stage: "security-scan",
    status: "running",
    dependsOn: ["build-compile"],
  },

  // Fan-in: test-e2e needs both test jobs to finish first.
  {
    id: "test-e2e",
    label: "End-to-End Tests",
    stage: "test",
    status: "pending",
    dependsOn: ["test-unit", "test-integration"],
  },

  // Fan-in: deploy-staging-deploy needs e2e tests plus both security scans.
  {
    id: "deploy-staging-deploy",
    label: "Deploy to Staging",
    stage: "deploy-staging",
    status: "running",
    dependsOn: ["test-e2e", "security-scan-sast", "security-scan-dependency-audit"],
  },
  {
    id: "deploy-staging-smoke-test",
    label: "Smoke Test (Staging)",
    stage: "deploy-staging",
    status: "pending",
    dependsOn: ["deploy-staging-deploy"],
  },

  {
    id: "deploy-prod-approval",
    label: "Manual Approval",
    stage: "deploy-prod",
    status: "skipped",
    dependsOn: ["deploy-staging-smoke-test"],
  },
  {
    id: "deploy-prod-deploy",
    label: "Deploy to Production",
    stage: "deploy-prod",
    status: "pending",
    dependsOn: ["deploy-prod-approval"],
  },
  {
    id: "deploy-prod-verify",
    label: "Verify Production",
    stage: "deploy-prod",
    status: "pending",
    dependsOn: ["deploy-prod-deploy"],
  },
];
