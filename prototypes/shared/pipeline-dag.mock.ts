/**
 * CANONICAL shared mock CI/CD pipeline DAG dataset.
 *
 * This is the single source of truth for Task 100.120 / REQ-004 of
 * feat-2-react-angular-visualization-spike (see
 * .specmgr/feat/feat-2-react-angular-visualization-spike/README.md).
 *
 * Both prototype apps keep a byte-identical copy of the data section below
 * (from `export type PipelineJobStatus` to the end of the file) under their
 * own `src/` tree, since a literal cross-package TypeScript import across
 * two independently-scaffolded apps (Vite/React and Angular CLI) is not
 * required/expected to work cleanly for this spike:
 *   - prototypes/react-pipeline-viz/src/pipeline-dag.mock.ts
 *   - prototypes/angular-pipeline-viz/src/app/pipeline-dag.mock.ts
 *
 * If you change the data below, copy the same change into both prototype
 * copies so all three stay byte-identical.
 *
 * Shape: a directed acyclic graph of pipeline jobs grouped into stages.
 * - 5 stages: build, test, security-scan, deploy-staging, deploy-prod
 * - 12 jobs (nodes)
 * - dependencies (edges) include a fan-out (build-compile feeds 4
 *   downstream jobs across two stages, two parallel jobs each) and
 *   fan-ins (test-e2e depends on two upstream jobs; deploy-staging-deploy
 *   depends on three upstream jobs)
 * - 5 distinct status values: success, failed, running, pending, skipped
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
