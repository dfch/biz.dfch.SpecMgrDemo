import { Component } from '@angular/core';
import { NgxGraphModule } from '@swimlane/ngx-graph';
import { PIPELINE_JOBS, type PipelineJobStatus } from './pipeline-dag.mock';

/**
 * Renders the shared mock pipeline DAG (Task 100.120) as an interactive,
 * pannable/zoomable graph using @swimlane/ngx-graph (Task 200.110 / REQ-002).
 *
 * Layout: ngx-graph's built-in "dagre" auto-layout engine (orientation
 * left-to-right) computes node positions from the `links` (dependency)
 * graph -- no manual positioning is needed. Because dependencies flow in
 * the same direction as pipeline stage order in the shared mock dataset,
 * the resulting rank columns closely track `stage` without us needing to
 * pass `stage` into the layout algorithm itself (see plan ACC-001, which
 * explicitly allows relying on a library's own auto-layout).
 */
@Component({
  selector: 'app-pipeline-dag',
  standalone: true,
  imports: [NgxGraphModule],
  templateUrl: './pipeline-dag.component.html',
  styleUrl: './pipeline-dag.component.css',
})
export class PipelineDagComponent {
  /** ngx-graph node list, built from the shared mock dataset. `data` carries status/stage for styling. */
  readonly nodes = PIPELINE_JOBS.map((job) => ({
    id: job.id,
    label: job.label,
    data: { stage: job.stage, status: job.status },
  }));

  /** ngx-graph link (edge) list, one per `dependsOn` entry. */
  readonly links = PIPELINE_JOBS.flatMap((job) =>
    job.dependsOn.map((dep) => ({
      id: `${dep}->${job.id}`,
      source: dep,
      target: job.id,
    })),
  );

  readonly statusLegend: { status: PipelineJobStatus; text: string }[] = [
    { status: 'success', text: 'Success' },
    { status: 'failed', text: 'Failed' },
    { status: 'running', text: 'Running' },
    { status: 'pending', text: 'Pending' },
    { status: 'skipped', text: 'Skipped' },
  ];
}
