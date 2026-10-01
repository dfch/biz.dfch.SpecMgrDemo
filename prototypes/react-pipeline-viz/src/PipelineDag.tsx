import { useMemo } from 'react'
import {
  ReactFlow,
  Background,
  Controls,
  Handle,
  MiniMap,
  Position,
  type Edge,
  type Node,
  type NodeProps,
} from '@xyflow/react'
import '@xyflow/react/dist/style.css'
import { PIPELINE_JOBS, PIPELINE_STAGES, type PipelineJob, type PipelineJobStatus } from './pipeline-dag.mock'
import './PipelineDag.css'

/** Horizontal gap between stage columns, in px. */
const COLUMN_WIDTH = 260
/** Vertical gap between job rows within a stage, in px. */
const ROW_HEIGHT = 110

/**
 * Compute a static layout: stages become columns (x = stage index *
 * COLUMN_WIDTH), jobs within a stage become rows (y = row index within that
 * stage * ROW_HEIGHT). No auto-layout library is used -- the dataset is
 * small and stable enough that this hand-computed layout is sufficient for
 * the spike (see plan ACC-001).
 */
function layoutNodes(jobs: readonly PipelineJob[], stages: readonly string[]): Node<StatusNodeData>[] {
  const rowCounters = new Map<string, number>()
  return jobs.map((job) => {
    const stageIndex = stages.indexOf(job.stage)
    const row = rowCounters.get(job.stage) ?? 0
    rowCounters.set(job.stage, row + 1)
    return {
      id: job.id,
      type: 'status',
      position: { x: stageIndex * COLUMN_WIDTH, y: row * ROW_HEIGHT },
      data: { label: job.label, stage: job.stage, status: job.status },
      sourcePosition: Position.Right,
      targetPosition: Position.Left,
    }
  })
}

function layoutEdges(jobs: readonly PipelineJob[]): Edge[] {
  const edges: Edge[] = []
  for (const job of jobs) {
    for (const dep of job.dependsOn) {
      edges.push({
        id: `${dep}->${job.id}`,
        source: dep,
        target: job.id,
        animated: job.status === 'running',
      })
    }
  }
  return edges
}

interface StatusNodeData {
  label: string
  stage: string
  status: PipelineJobStatus
  [key: string]: unknown
}

/** Custom node renderer: visually distinguishes each of the 5 status values (REQ-004). */
function StatusNode({ data }: NodeProps<Node<StatusNodeData>>) {
  return (
    <div className={`status-node status-node--${data.status}`}>
      {/* Custom node types must declare their own handles for edges to attach. */}
      <Handle type="target" position={Position.Left} />
      <div className="status-node__label">{data.label}</div>
      <div className="status-node__stage">{data.stage}</div>
      <Handle type="source" position={Position.Right} />
    </div>
  )
}

const nodeTypes = { status: StatusNode }

const STATUS_LEGEND: { status: PipelineJobStatus; text: string }[] = [
  { status: 'success', text: 'Success' },
  { status: 'failed', text: 'Failed' },
  { status: 'running', text: 'Running' },
  { status: 'pending', text: 'Pending' },
  { status: 'skipped', text: 'Skipped' },
]

/**
 * Renders the shared mock pipeline DAG (Task 100.120) as an interactive,
 * pannable/zoomable graph using @xyflow/react (Task 200.100 / REQ-001).
 */
export default function PipelineDag() {
  const nodes = useMemo(() => layoutNodes(PIPELINE_JOBS, PIPELINE_STAGES), [])
  const edges = useMemo(() => layoutEdges(PIPELINE_JOBS), [])

  return (
    <div className="pipeline-dag">
      <div className="pipeline-dag__legend">
        {STATUS_LEGEND.map(({ status, text }) => (
          <span key={status} className={`legend-chip legend-chip--${status}`}>
            {text}
          </span>
        ))}
      </div>
      <div className="pipeline-dag__canvas">
        <ReactFlow
          nodes={nodes}
          edges={edges}
          nodeTypes={nodeTypes}
          fitView
          minZoom={0.2}
          maxZoom={2}
          proOptions={{ hideAttribution: true }}
        >
          <Background />
          <Controls />
          <MiniMap pannable zoomable />
        </ReactFlow>
      </div>
    </div>
  )
}
