"""Shared code of the gates for the GitHub Actions workflows.

feat-5-foundation-monorepo-ci, Tasks 130.140 and 130.142. Do not run this file.
check_workflows.py and check_pins.py import it. PyYAML must be installed (the
scripts check-workflows.sh and check-pins.sh start Python with `uv run --with`).
"""

from pathlib import Path
from typing import Any

import yaml


class GateError(Exception):
    """A file is wrong, so the gate cannot decide."""


class UniqueKeyLoader(yaml.SafeLoader):
    """A YAML loader that stops for a key that is twice in one mapping.

    PyYAML keeps the last value for a key that is twice in a mapping. With this loader, a
    second `run:` in a step cannot hide the first one.
    """

    def construct_mapping(self, node: yaml.MappingNode, deep: bool = False) -> dict[Any, Any]:
        keys: set[Any] = set()
        for key_node, _ in node.value:
            key = self.construct_object(key_node, deep=deep)  # type: ignore[no-untyped-call]
            if key in keys:
                raise yaml.constructor.ConstructorError(
                    None, None, f"the key {key!r} is twice in one mapping", key_node.start_mark
                )
            keys.add(key)
        return super().construct_mapping(node, deep)


def load_workflows(directory: Path) -> list[tuple[Path, dict[Any, Any]]]:
    """Read all workflow files (*.yml and *.yaml) of a folder. Stop if there is none."""
    if not directory.is_dir():
        raise GateError(f"the folder {directory} does not exist")
    files = sorted([*directory.glob("*.yml"), *directory.glob("*.yaml")])
    if not files:
        raise GateError(f"no workflow file (*.yml, *.yaml) in {directory}")
    workflows: list[tuple[Path, dict[Any, Any]]] = []
    for path in files:
        try:
            data = yaml.load(path.read_text(encoding="utf-8"), Loader=UniqueKeyLoader)  # noqa: S506
        except (OSError, yaml.YAMLError) as error:
            raise GateError(f"{path}: cannot read the YAML: {error}") from error
        if not isinstance(data, dict):
            raise GateError(f"{path}: the workflow is not a mapping")
        workflows.append((path, data))
    return workflows


def iter_jobs(path: Path, workflow: dict[Any, Any]) -> list[tuple[str, dict[Any, Any]]]:
    """Return the jobs of a workflow. Stop if there is no job."""
    jobs = workflow.get("jobs")
    if not isinstance(jobs, dict) or not jobs:
        raise GateError(f"{path}: the workflow has no jobs")
    result: list[tuple[str, dict[Any, Any]]] = []
    for job_id, job in jobs.items():
        if not isinstance(job, dict):
            raise GateError(f"{path}: job '{job_id}' is not a mapping")
        result.append((str(job_id), job))
    return result


def iter_steps(path: Path, job_id: str, job: dict[Any, Any]) -> list[dict[Any, Any]]:
    """Return the steps of a job. A job with no steps (for example a job that calls a workflow) stops the gate."""
    steps = job.get("steps")
    if not isinstance(steps, list) or not steps:
        raise GateError(f"{path}: job '{job_id}' has no steps (a job with `uses:` or with no `steps:` is not allowed)")
    for index, step in enumerate(steps, start=1):
        if not isinstance(step, dict):
            raise GateError(f"{path}: job '{job_id}', step {index} is not a mapping")
    return steps
