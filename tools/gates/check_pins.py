#!/usr/bin/env python3
"""Gate: the pins in the workflows (ACC-013), the lock file of cdxgen and the lock files of the Python tools.

feat-5-foundation-monorepo-ci, Task 130.142 (REQ-003, REQ-015).
feat-16-cdxgen-lockfile, Task 110.100 (REQ-003, REQ-005).
feat-22-python-tools-lockfile, Task 120.100 (REQ-003, REQ-004).

Usage: check_pins.py <versions.env> <workflows-dir> <allowed-actions> <project-root> <sbom-tool-dir> <python-lock-dir>

The script stops for each of these:

  * a `uses:` that is not `<owner>/<name>[/<path>]@<40 hexadecimal characters>` (a tag, a branch,
    a short SHA, a local action `./...`, and `docker://...` are not allowed);
  * a `uses:` with no comment on the same line, or a comment that is not `# <owner>/<name> <tag>`
    (the name is the name of the action, the tag is a release tag such as v7.0.1);
  * an action that is not in <allowed-actions> (the actions of the license table), or whose tag
    or SHA is not the one in this file;
  * a setup action whose version input is missing, is not a text, or is not the same as the
    value in tools/versions.env (see TOOL_INPUTS below);
  * `actions/setup-java` with a distribution that is not `temurin`;
  * a version input of an action that has no entry in TOOL_INPUTS (the gate cannot check it);
  * a `uses:` in the YAML that the text check did not find, or the other way round (this stops
    a form of the YAML that the text check does not read, for example a `uses:` in two lines).

The Maven pin (the finding G1 of the review; REQ-003 wants the same Maven version in CI as in
tools/versions.env, and the repository has no Maven setup action). The Maven Wrapper pins Maven in the
repository, so the script looks in <project-root> (not in .git, node_modules, build, target, and from the
root only .specmgr and the fixtures of the gates; EXCLUDED_* below, the same list as manifest_files in
_lib.sh) and stops for each of these:

  * a `.mvn/wrapper/maven-wrapper.properties` whose `distributionUrl` has no file
    `apache-maven-<MAVEN_VERSION>-bin.zip` (or `.tar.gz`), with MAVEN_VERSION of tools/versions.env;
  * a wrapper with no `distributionSha256Sum` (64 hexadecimal characters). The script cannot compare the
    value with versions.env (the file has the sha512 of the tar.gz), so it checks that the value is there;
  * a project with a `pom.xml` and no wrapper (fail closed: sbom.sh does not use the Maven of the runner).

A project with no `pom.xml` and no wrapper passes, and the script says "no Maven project". Until
feat-6-contracts-openapi-pipeline adds the wrapper, a `pom.xml` stops this gate on purpose.

The lock file of the SBOM tool cdxgen (the finding G2 of the review, feat-16-cdxgen-lockfile; REQ-003, REQ-005).
tools/versions.env is the one source of truth for CDXGEN_VERSION and CDXGEN_INTEGRITY. <sbom-tool-dir> is the
pnpm project tools/sbom/. The check is always on (also if frontend/ does not exist), and it fails closed. The
script stops for each of these:

  * <sbom-tool-dir>, its package.json or its pnpm-lock.yaml is missing, or the folder has a file that pnpm
    could read as a setting (for example `.npmrc`, `pnpm-workspace.yaml`, `.pnpmfile.cjs`): only package.json,
    pnpm-lock.yaml, README.md and node_modules are allowed (SBOM_TOOL_FILES below);
  * CDXGEN_VERSION is not an exact version (a range, a tag), or CDXGEN_INTEGRITY is not a sha512 value;
  * package.json: it has a key that is not in PACKAGE_JSON_KEYS (this stops devDependencies,
    optionalDependencies, peerDependencies, overrides, `pnpm`, `packageManager` and every other key), its
    `dependencies` is not exactly {"@cyclonedx/cdxgen": CDXGEN_VERSION} (another version, a range, a tag, one
    more dependency), or the file is not JSON, has a key two times, or is not an object;
  * the lock file: it is not exactly one YAML document with no key twice (a `packageManager` in package.json
    adds a second document), `lockfileVersion` is not a text that starts with `9.`, it has a top-level key
    that is not in LOCK_KEYS (for example `overrides`), it has not exactly one importer `.` with exactly one
    direct dependency `@cyclonedx/cdxgen` whose `specifier` and `version` are CDXGEN_VERSION, the entry of
    cdxgen in `packages` is missing or has another integrity value than CDXGEN_INTEGRITY;
  * a package in the lock file with no integrity value, with an integrity value that is not sha256, sha384 or
    sha512, with a `resolution` that has another key than `integrity` (`tarball`, `repo`, `commit`,
    `directory`, `type`: a package from another place than the registry), or with a key that is not
    `<name>@<exact version>`; a `snapshots` entry for a package that is not in `packages`.

The check reads the lock file as text with PyYAML (it does not need Node or pnpm), so the job `check-pins` of CI
runs it. The frozen install in sbom.sh does the real check of each tarball against the lock file; this check
ties the lock file to tools/versions.env and stops a lock file that the install would accept but that has a
source that is not the registry. A change of only one of the three places (versions.env, package.json, the
lock file) stops the check.

The lock files of the Python tools (the finding G2 of the review, feat-22-python-tools-lockfile; REQ-003, REQ-004).
<python-lock-dir> is tools/python/. It has one lock file for each tool (PYTHON_LOCKS below), and no other lock
file. The check is always on, and it fails closed. The script reads each lock file as text (it does not start uv
and does not make the file again, so the result does not depend on the version of uv). It stops for each of these:

  * the folder or a lock file is missing, the folder has a file that is not in PYTHON_LOCK_FILES, or a lock file has
    no package;
  * a line of a lock file that is not a comment, an empty line or an entry `name==version` (with an optional
    marker after ` ; `) that has one or more `--hash=sha256:<64 hexadecimal characters>` values. This stops a
    package with no hash, a range or an unpinned package, a URL (`name @ https://...`), a path, `git+...`, `-e`, and an
    option such as `--index-url`, `--extra-index-url`, `--find-links` and `--no-binary` (a line that continues with
    a backslash is one entry);
  * the version of the tool (`SPECMGR_VERSION`, `PYYAML_VERSION`, `LICENSE_EXPRESSION_VERSION`) is missing in
    tools/versions.env or is not an exact version, or the lock file has no entry of the tool or an entry with
    another version (the name is compared after the normalization of PEP 503).

A change of only one of the two places (versions.env, the lock file) stops the check. The install itself checks
each file against the hashes (make_python_env in _lib.sh); this check ties the lock file to tools/versions.env and
stops a lock file that has a source that is not an exact pin with hashes.

The comment is not in the YAML data, so the script reads the lines of the file for the comment,
and the YAML data for the inputs. Exit codes: 0 pass; 1 a pin is not correct; 2 an error in a file (versions.env or a workflow).
"""

import json
import os
import re
import sys
from collections import Counter
from pathlib import Path
from typing import Any

import yaml
from _workflow import GateError, iter_jobs, iter_steps, load_workflows

# The setup actions: the input with the version of the tool, and the key in tools/versions.env.
TOOL_INPUTS: dict[str, dict[str, str]] = {
    "actions/setup-java": {"java-version": "JDK_VERSION"},
    "actions/setup-node": {"node-version": "NODE_VERSION"},
    "pnpm/action-setup": {"version": "PNPM_VERSION"},
    "astral-sh/setup-uv": {"version": "UV_VERSION"},
    "extractions/setup-just": {"just-version": "JUST_VERSION"},
}
# Other inputs that must have a fixed value.
FIXED_INPUTS: dict[str, dict[str, str]] = {"actions/setup-java": {"distribution": "temurin"}}

USES_LINE = re.compile(r"^\s*(?:-\s+)?uses:\s*(\S+)[ \t]*(?:#(.*))?$")
USES_VALUE = re.compile(
    r"(?P<name>[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+)(?P<path>(?:/[A-Za-z0-9_./-]+)?)@(?P<sha>[0-9a-f]{40})"
)
COMMENT = re.compile(r"\s*(?P<name>[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+) (?P<tag>v[0-9]+(?:\.[0-9]+){0,2})\s*")
VERSION_KEY = re.compile(r"(^|[-_])version([-_]|$)", re.IGNORECASE)

# The folders that the search for pom.xml and for the wrapper does not enter (see the header). The names
# are at each level; the paths are relative to the project root. manifest_files in _lib.sh has the same list.
# manifest_files also does not list tools/sbom/package.json and tools/sbom/pnpm-lock.yaml (the lock file of
# cdxgen, feat-16-cdxgen-lockfile). This script needs no entry for them: it searches for pom.xml and for the
# Maven Wrapper only.
EXCLUDED_NAMES = {".git", "node_modules", "build", "target"}
EXCLUDED_PATHS = {".specmgr", "tools/license/fixtures", "tools/gates/fixtures"}
WRAPPER_FILE = Path(".mvn") / "wrapper" / "maven-wrapper.properties"

# The lock file of cdxgen (feat-16-cdxgen-lockfile). See the header.
CDXGEN_PACKAGE = "@cyclonedx/cdxgen"
# The files that tools/sbom/ may have. A settings file (.npmrc, pnpm-workspace.yaml, .pnpmfile.cjs, ...) could
# change where pnpm gets the packages, so each other file stops the check (node_modules is the install).
SBOM_TOOL_FILES = {"package.json", "pnpm-lock.yaml", "README.md", "node_modules"}
# The keys that package.json may have. All of them are text that does not change the install.
PACKAGE_JSON_KEYS = {"name", "private", "description", "dependencies"}
# The top-level keys of pnpm-lock.yaml (lockfileVersion 9) that the check knows. `overrides`,
# `patchedDependencies`, `catalogs` and the other keys change the install, so they stop the check.
LOCK_KEYS = {"lockfileVersion", "settings", "importers", "packages", "snapshots"}
EXACT_VERSION = re.compile(r"[0-9]+\.[0-9]+\.[0-9]+(?:-[0-9A-Za-z.-]+)?")
INTEGRITY = re.compile(r"sha(?:256|384|512)-[A-Za-z0-9+/]+={0,2}")
CDXGEN_INTEGRITY_FORM = re.compile(r"sha512-[A-Za-z0-9+/]{86}==")


# The lock files of the Python tools (feat-22-python-tools-lockfile): the file, the name of the package of the
# tool (normalized) and the key of its version in tools/versions.env. PYTHON_LOCK_FILES are the only files that
# the folder may have.
PYTHON_LOCKS = (
    ("specmgr.lock", "biz-dfch-specmgr", "SPECMGR_VERSION"),
    ("pyyaml.lock", "pyyaml", "PYYAML_VERSION"),
    ("license-expression.lock", "license-expression", "LICENSE_EXPRESSION_VERSION"),
)
PYTHON_LOCK_FILES = {lock[0] for lock in PYTHON_LOCKS} | {"README.md", "make-locks.sh"}
# `name==version`, with an optional marker after ` ; `. The marker has no `@`, `/` or `:`, so a URL is not a marker.
LOCK_REQUIREMENT = re.compile(
    r"(?P<name>[A-Za-z0-9][A-Za-z0-9._-]*)==(?P<version>[0-9][0-9A-Za-z.+!_-]*)(?: ; [A-Za-z0-9_.'\"()<>=! ,~-]+)?"
)
LOCK_HASH = re.compile(r"--hash=sha256:[0-9a-f]{64}")
MAX_LOCK_PROBLEMS = 5


def read_versions(path: Path) -> dict[str, str]:
    """Read tools/versions.env (lines `KEY=value`)."""
    versions: dict[str, str] = {}
    try:
        lines = path.read_text(encoding="utf-8").splitlines()
    except OSError as error:
        raise GateError(f"cannot read {path}: {error}") from error
    for number, line in enumerate(lines, start=1):
        if not line.strip() or line.lstrip().startswith("#"):
            continue
        match = re.fullmatch(r"([A-Z][A-Z0-9_]*)=(\S*)", line)
        if not match:
            raise GateError(f"{path}, line {number}: the form is not KEY=value")
        versions[match.group(1)] = match.group(2)
    return versions


def read_allowed(path: Path) -> dict[str, tuple[str, str]]:
    """Read the allowed actions: lines `<owner>/<name> <tag> <sha>`."""
    allowed: dict[str, tuple[str, str]] = {}
    try:
        lines = path.read_text(encoding="utf-8").splitlines()
    except OSError as error:
        raise GateError(f"cannot read {path}: {error}") from error
    for number, line in enumerate(lines, start=1):
        if not line.strip() or line.lstrip().startswith("#"):
            continue
        match = re.fullmatch(r"(\S+/\S+) (v[0-9]+(?:\.[0-9]+){0,2}) ([0-9a-f]{40})", line.strip())
        if not match:
            raise GateError(f"{path}, line {number}: the form is not `<owner>/<name> <tag> <sha>`")
        allowed[match.group(1)] = (match.group(2), match.group(3))
    if not allowed:
        raise GateError(f"{path} has no action")
    return allowed


def check_use(location: str, text: str, comment: str | None, allowed: dict[str, tuple[str, str]]) -> list[str]:
    """Check one `uses:` value and its comment. Return the problems."""
    value = USES_VALUE.fullmatch(text)
    if not value:
        return [f"{location}: `uses: {text}` is not `<owner>/<name>@<40 hexadecimal characters>`"]
    name, sha = value.group("name"), value.group("sha")
    if value.group("path"):
        return [f"{location}: `uses: {text}` has a path in the action. The table has the action {name} only"]
    if comment is None:
        return [f"{location}: `uses: {text}` has no comment `# {name} <tag>` on the same line"]
    match = COMMENT.fullmatch(comment)
    if not match or match.group("name") != name:
        return [f"{location}: the comment `#{comment}` must be `# {name} <tag>` (a release tag such as v7.0.1)"]
    tag = match.group("tag")
    if name not in allowed:
        return [f"{location}: the action {name} is not in the table of allowed actions (the license table)"]
    if allowed[name] != (tag, sha):
        return [
            f"{location}: {name} is {tag} {sha}, but the table has {allowed[name][0]} {allowed[name][1]}",
        ]
    return []


def check_inputs(location: str, name: str, with_block: Any, versions: dict[str, str]) -> list[str]:
    """Check the inputs of an action step against tools/versions.env."""
    problems: list[str] = []
    inputs = with_block if isinstance(with_block, dict) else {}
    tool_inputs = TOOL_INPUTS.get(name, {})
    for input_name, key in tool_inputs.items():
        if key not in versions:
            problems.append(f"{location}: {key} is not in tools/versions.env")
            continue
        value = inputs.get(input_name)
        if value is None:
            problems.append(f"{location}: {name} has no input `{input_name}` (it must be {versions[key]})")
        elif not isinstance(value, str):
            problems.append(f"{location}: the input `{input_name}` must be a text in quotes ({value!r})")
        elif value != versions[key]:
            problems.append(
                f"{location}: `{input_name}` is {value}, but {key} in tools/versions.env is {versions[key]}"
            )
    for input_name, expected in FIXED_INPUTS.get(name, {}).items():
        if inputs.get(input_name) != expected:
            problems.append(f"{location}: `{input_name}` of {name} must be {expected}")
    for input_name in inputs:
        if VERSION_KEY.search(str(input_name)) and input_name not in tool_inputs:
            problems.append(f"{location}: the input `{input_name}` of {name} has a version that the gate cannot check")
    return problems


def check_file(
    path: Path, workflow: dict[Any, Any], versions: dict[str, str], allowed: dict[str, tuple[str, str]]
) -> tuple[int, list[str]]:
    """Check one workflow file. Return the number of `uses:` steps and the problems."""
    problems: list[str] = []

    # The text check: each `uses:` line, with its comment.
    from_text: list[tuple[str, str | None, int]] = []
    for number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), start=1):
        match = USES_LINE.match(line)
        if match:
            from_text.append((match.group(1), match.group(2), number))

    # The YAML check: each `uses:` of a step (a job with `uses:` has no steps, and stops iter_steps).
    from_yaml: list[tuple[str, str, Any]] = []
    for job_id, job in iter_jobs(path, workflow):
        for index, step in enumerate(iter_steps(path, job_id, job), start=1):
            if "uses" in step:
                from_yaml.append((f"job '{job_id}', step {index}", str(step["uses"]), step.get("with")))

    if Counter(text for text, _, _ in from_text) != Counter(uses for _, uses, _ in from_yaml):
        problems.append(
            f"{path}: the `uses:` entries in the text and in the YAML are not the same. "
            "Write each `uses: <owner>/<name>@<sha> # <owner>/<name> <tag>` on one line"
        )
        return len(from_yaml), problems

    for text, comment, number in from_text:
        problems += check_use(f"{path}:{number}", text, comment, allowed)
    for where, uses, with_block in from_yaml:
        value = USES_VALUE.fullmatch(uses)
        if value:
            problems += check_inputs(f"{path}, {where}", value.group("name"), with_block, versions)
    return len(from_yaml), problems


def find_files(root: Path, name: str) -> list[Path]:
    """Return the paths (relative to the root) of the files with this name, without the excluded folders."""
    found: list[Path] = []
    for folder, dirs, files in os.walk(root):
        relative = Path(folder).relative_to(root)
        dirs[:] = sorted(d for d in dirs if d not in EXCLUDED_NAMES and (relative / d).as_posix() not in EXCLUDED_PATHS)
        if name in files:
            found.append(relative / name)
    return sorted(found)


def read_properties(path: Path) -> dict[str, str]:
    """Read a Java properties file (lines `key=value`; `#` and `!` start a comment; `\\:` is a colon)."""
    properties: dict[str, str] = {}
    try:
        lines = path.read_text(encoding="utf-8").splitlines()
    except OSError as error:
        raise GateError(f"cannot read {path}: {error}") from error
    for line in lines:
        stripped = line.strip()
        if not stripped or stripped[0] in "#!" or "=" not in stripped:
            continue
        key, value = stripped.split("=", 1)
        properties[key.strip()] = value.strip().replace("\\:", ":")
    return properties


def check_maven(root: Path, versions: dict[str, str]) -> tuple[str, list[str]]:
    """Check the Maven pin (finding G1). Return a message for the log and the problems."""
    if "MAVEN_VERSION" not in versions:
        return "", ["MAVEN_VERSION is not in tools/versions.env"]
    version = versions["MAVEN_VERSION"]
    poms = find_files(root, "pom.xml")
    wrappers = [path for path in find_files(root, "maven-wrapper.properties") if path.parts[-3:] == WRAPPER_FILE.parts]
    if not poms and not wrappers:
        return "no Maven project (no pom.xml and no Maven Wrapper)", []
    problems: list[str] = []
    if poms and not wrappers:
        problems.append(
            f"Maven: {', '.join(str(p) for p in poms)} exists, but no {WRAPPER_FILE} (the Maven Wrapper). "
            f"Add the wrapper for Maven {version}: CI has no Maven setup action and must not use the Maven of the runner"
        )
    url_pattern = re.compile(r"/apache-maven-" + re.escape(version) + r"-bin\.(zip|tar\.gz)")
    for wrapper in wrappers:
        properties = read_properties(root / wrapper)
        url = properties.get("distributionUrl")
        if url is None:
            problems.append(f"Maven: {wrapper} has no `distributionUrl`")
        elif not url_pattern.search(url):
            problems.append(
                f"Maven: {wrapper}: `distributionUrl` is {url}, but MAVEN_VERSION in tools/versions.env is {version} "
                f"(the URL must have apache-maven-{version}-bin.zip)"
            )
        checksum = properties.get("distributionSha256Sum")
        if checksum is None:
            problems.append(f"Maven: {wrapper} has no `distributionSha256Sum` (the sha256 of the Maven download)")
        elif not re.fullmatch(r"[0-9a-fA-F]{64}", checksum):
            problems.append(f"Maven: {wrapper}: `distributionSha256Sum` is not a sha256 value ({checksum!r})")
    note = f"Maven Wrapper: {len(wrappers)} file(s), Maven {version}" if not problems else ""
    return note, problems


class _UniqueKeyLoader(yaml.SafeLoader):
    """A YAML loader that stops for a key that is there two times (the standard loader keeps the last one)."""


def _construct_unique_mapping(loader: _UniqueKeyLoader, node: yaml.MappingNode, deep: bool = False) -> dict[Any, Any]:
    seen: set[Any] = set()
    for key_node, _ in node.value:
        key = loader.construct_object(key_node, deep=deep)
        if key in seen:
            raise yaml.constructor.ConstructorError(
                None, None, f"the key {key!r} is there two times", key_node.start_mark
            )
        seen.add(key)
    return yaml.SafeLoader.construct_mapping(loader, node, deep=deep)


_UniqueKeyLoader.add_constructor(yaml.resolver.BaseResolver.DEFAULT_MAPPING_TAG, _construct_unique_mapping)


def _unique_object(pairs: list[tuple[str, Any]]) -> dict[str, Any]:
    """The `object_pairs_hook` of the JSON reader: stop for a key that is there two times."""
    result: dict[str, Any] = {}
    for key, value in pairs:
        if key in result:
            raise ValueError(f"the key {key!r} is there two times")
        result[key] = value
    return result


def check_package_json(path: Path, version: str) -> list[str]:
    """Check tools/sbom/package.json: the one dependency in the exact version, and no other key that matters."""
    where = f"SBOM tool: {path}"
    try:
        data = json.loads(path.read_text(encoding="utf-8"), object_pairs_hook=_unique_object)
    except (OSError, ValueError) as error:
        return [f"{where} cannot be read as JSON: {error}"]
    if not isinstance(data, dict):
        return [f"{where} is not a JSON object"]
    problems: list[str] = []
    for key in sorted(set(data) - PACKAGE_JSON_KEYS):
        problems.append(
            f"{where} has the key `{key}`. The project has only {sorted(PACKAGE_JSON_KEYS)}: no other dependency "
            "key (devDependencies, optionalDependencies, peerDependencies), no overrides, no `pnpm` settings and "
            "no `packageManager` (it changes the lock file)"
        )
    dependencies = data.get("dependencies")
    if not isinstance(dependencies, dict):
        problems.append(f"{where} has no `dependencies` object with {CDXGEN_PACKAGE}")
    else:
        for name in sorted(set(dependencies) - {CDXGEN_PACKAGE}):
            problems.append(f"{where} has the dependency {name}. The only dependency is {CDXGEN_PACKAGE}")
        if CDXGEN_PACKAGE not in dependencies:
            problems.append(f"{where} has no dependency {CDXGEN_PACKAGE}")
        elif dependencies[CDXGEN_PACKAGE] != version:
            problems.append(
                f"{where}: {CDXGEN_PACKAGE} is {dependencies[CDXGEN_PACKAGE]!r}, but CDXGEN_VERSION in "
                f"tools/versions.env is {version} (an exact version, no range and no tag)"
            )
    return problems


def _split_package_key(key: str) -> tuple[str, str] | None:
    """Split `name@version` or `@scope/name@version`. Return None if the key has another form."""
    index = key.rfind("@")
    if index <= 0:
        return None
    return key[:index], key[index + 1 :]


def check_lock(path: Path, version: str, integrity: str) -> list[str]:
    """Check tools/sbom/pnpm-lock.yaml (see the header). Return the problems."""
    where = f"SBOM tool: {path}"
    try:
        documents = list(yaml.load_all(path.read_text(encoding="utf-8"), Loader=_UniqueKeyLoader))
    except (OSError, yaml.YAMLError, TypeError, ValueError) as error:
        return [f"{where} cannot be read as YAML: {error}"]
    if len(documents) != 1:
        return [
            f"{where} has {len(documents)} YAML documents, but it must have exactly one"
            + " (a `packageManager` field in package.json makes a second document)"
        ]
    lock = documents[0]
    if not isinstance(lock, dict):
        return [f"{where} is not a YAML mapping"]
    problems: list[str] = []
    lock_version = lock.get("lockfileVersion")
    if not isinstance(lock_version, str) or not lock_version.startswith("9."):
        problems.append(f"{where}: `lockfileVersion` is {lock_version!r}, but it must be a text that starts with `9.`")
    for key in sorted(set(lock) - LOCK_KEYS, key=str):
        problems.append(
            f"{where} has the top-level key `{key}`, which the check does not know (known: {sorted(LOCK_KEYS)})"
        )

    problems += _check_importers(where, lock.get("importers"), version)
    packages = lock.get("packages")
    if not isinstance(packages, dict) or not packages:
        problems.append(f"{where} has no `packages`")
        return problems
    problems += _check_packages(where, packages, version, integrity)
    snapshots = lock.get("snapshots")
    if snapshots is not None:
        if not isinstance(snapshots, dict):
            problems.append(f"{where}: `snapshots` is not a mapping")
        else:
            for key in snapshots:
                if str(key).split("(", 1)[0] not in packages:
                    problems.append(f"{where}: `snapshots` has {key!r}, which is not in `packages`")
    return problems


def _check_importers(where: str, importers: Any, version: str) -> list[str]:
    """Exactly one importer `.` with exactly one direct dependency: cdxgen, in the version of versions.env."""
    if not isinstance(importers, dict) or set(importers) != {"."}:
        found = sorted(importers, key=str) if isinstance(importers, dict) else importers
        return [f"{where}: `importers` must have exactly one importer `.` (it has {found!r})"]
    importer = importers["."]
    if not isinstance(importer, dict) or set(importer) != {"dependencies"}:
        found = sorted(importer, key=str) if isinstance(importer, dict) else importer
        return [f"{where}: the importer `.` must have `dependencies` and nothing else (it has {found!r})"]
    dependencies = importer["dependencies"]
    if not isinstance(dependencies, dict) or set(dependencies) != {CDXGEN_PACKAGE}:
        found = sorted(dependencies, key=str) if isinstance(dependencies, dict) else dependencies
        return [f"{where}: the importer `.` must have exactly one dependency, {CDXGEN_PACKAGE} (it has {found!r})"]
    entry = dependencies[CDXGEN_PACKAGE]
    if not isinstance(entry, dict) or set(entry) != {"specifier", "version"}:
        return [f"{where}: the dependency {CDXGEN_PACKAGE} of the importer must have `specifier` and `version`"]
    return [
        f"{where}: the importer has {CDXGEN_PACKAGE} `{field}` {entry[field]!r}, but CDXGEN_VERSION in "
        f"tools/versions.env is {version}"
        for field in ("specifier", "version")
        if entry[field] != version
    ]


def _check_packages(where: str, packages: dict[Any, Any], version: str, integrity: str) -> list[str]:
    """Each package has a registry source and an integrity value. cdxgen has the version and the value of versions.env."""
    problems: list[str] = []
    cdxgen_keys = []
    for key, entry in packages.items():
        parts = _split_package_key(str(key)) if isinstance(key, str) else None
        if parts is None or not EXACT_VERSION.fullmatch(parts[1]):
            problems.append(
                f"{where}: the package {key!r} is not `<name>@<exact version>` (a link, a URL or a git source?)"
            )
            continue
        if parts[0] == CDXGEN_PACKAGE:
            cdxgen_keys.append(key)
        resolution = entry.get("resolution") if isinstance(entry, dict) else None
        if not isinstance(resolution, dict):
            problems.append(f"{where}: the package {key} has no `resolution`")
        elif "integrity" not in resolution:
            problems.append(f"{where}: the package {key} has no integrity value")
        elif not isinstance(resolution["integrity"], str) or not INTEGRITY.fullmatch(resolution["integrity"]):
            problems.append(f"{where}: the package {key} has an integrity value that is not sha256, sha384 or sha512")
        elif set(resolution) != {"integrity"}:
            others = sorted(set(resolution) - {"integrity"}, key=str)
            problems.append(
                f"{where}: the package {key} has the `resolution` keys {others}. The check allows `integrity` only"
            )
    expected_key = f"{CDXGEN_PACKAGE}@{version}"
    if cdxgen_keys != [expected_key]:
        problems.append(
            f"{where}: `packages` must have exactly one {CDXGEN_PACKAGE}, and it must be {expected_key} "
            f"(CDXGEN_VERSION in tools/versions.env). It has {cdxgen_keys}"
        )
    else:
        resolution = packages[expected_key].get("resolution") if isinstance(packages[expected_key], dict) else None
        found = resolution.get("integrity") if isinstance(resolution, dict) else None
        if found != integrity:
            problems.append(
                f"{where}: the integrity value of {expected_key} is {found}, but CDXGEN_INTEGRITY in "
                f"tools/versions.env is {integrity}"
            )
    return problems


def check_sbom_tool(tool_dir: Path, versions: dict[str, str]) -> tuple[str, list[str]]:
    """Check the pnpm project of cdxgen (feat-16-cdxgen-lockfile). Return a message for the log and the problems."""
    problems: list[str] = []
    version, integrity = versions.get("CDXGEN_VERSION", ""), versions.get("CDXGEN_INTEGRITY", "")
    for key in ("CDXGEN_VERSION", "CDXGEN_INTEGRITY"):
        if key not in versions:
            problems.append(f"{key} is not in tools/versions.env")
    if version and not EXACT_VERSION.fullmatch(version):
        problems.append(
            f"CDXGEN_VERSION in tools/versions.env is {version!r}, but it must be an exact version (no range, no tag)"
        )
    if integrity and not CDXGEN_INTEGRITY_FORM.fullmatch(integrity):
        problems.append(
            f"CDXGEN_INTEGRITY in tools/versions.env is {integrity!r}, but it must be a sha512 integrity value of npm"
        )
    if not tool_dir.is_dir():
        problems.append(f"SBOM tool: the folder {tool_dir} (the lock file of cdxgen) does not exist")
        return "", problems
    for name in sorted(path.name for path in tool_dir.iterdir()):
        if name not in SBOM_TOOL_FILES:
            problems.append(
                f"SBOM tool: {tool_dir / name} is not allowed. The folder has only {sorted(SBOM_TOOL_FILES)} "
                "(a settings file could change where pnpm gets the packages)"
            )
    package_json, lock = tool_dir / "package.json", tool_dir / "pnpm-lock.yaml"
    for path in (package_json, lock):
        if not path.is_file():
            problems.append(f"SBOM tool: {path} does not exist")
    if problems:
        return "", problems
    # CDXGEN_VERSION and CDXGEN_INTEGRITY are in the right form here, or the problems above stopped.
    problems += check_package_json(package_json, version)
    problems += check_lock(lock, version, integrity)
    note = f"SBOM tool: {tool_dir}: @cyclonedx/cdxgen {version}, package.json and lock file as in tools/versions.env"
    return ("" if problems else note), problems


def _normalize_name(name: str) -> str:
    """The name of a Python package after the normalization of PEP 503."""
    return re.sub(r"[-_.]+", "-", name).lower()


def _python_lock_entries(path: Path) -> tuple[list[tuple[int, str, str]], list[str]]:
    """Read a lock file. Return the entries (line, normalized name, version) and the problems.

    A line that ends with a backslash continues in the next line, and both lines are one entry.
    """
    problems: list[str] = []
    entries: list[tuple[int, str, str]] = []
    try:
        lines = path.read_text(encoding="utf-8").splitlines()
    except (OSError, UnicodeDecodeError) as error:
        return [], [f"Python lock: cannot read {path}: {error}"]
    logical: list[tuple[int, str]] = []
    pending: tuple[int, str] | None = None
    for number, line in enumerate(lines, start=1):
        if pending is not None:
            joined = pending[1] + " " + line.strip()
        else:
            joined = line
        if joined.endswith("\\"):
            pending = (pending[0] if pending is not None else number, joined[:-1].rstrip())
            continue
        logical.append((pending[0] if pending is not None else number, joined))
        pending = None
    if pending is not None:
        problems.append(f"Python lock: {path}, line {pending[0]}: the file ends after a backslash")
    for number, line in logical:
        text = line.strip()
        if not text or text.startswith("#"):
            continue
        requirement, separator, hashes = text.partition(" --hash=")
        match = LOCK_REQUIREMENT.fullmatch(requirement)
        hash_values = ("--hash=" + hashes).split() if separator else []
        if not match or not hash_values or not all(LOCK_HASH.fullmatch(value) for value in hash_values):
            problems.append(
                f"Python lock: {path}, line {number}: {text[:90]!r} is not an exact pin `name==version` with "
                "`--hash=sha256:<64 hexadecimal characters>` values (a package with no hash, a range, a URL, a path, "
                "a VCS source, an editable entry and an option are not allowed)"
            )
            continue
        entries.append((number, _normalize_name(match.group("name")), match.group("version")))
    if len(problems) > MAX_LOCK_PROBLEMS:
        # One broken entry can make a problem for each of its hash lines. The first ones are enough to find the place.
        hidden = len(problems) - MAX_LOCK_PROBLEMS
        problems = problems[:MAX_LOCK_PROBLEMS] + [f"Python lock: {path}: and {hidden} more line(s) that are not correct"]
    return entries, problems


def check_python_locks(lock_dir: Path, versions: dict[str, str]) -> tuple[str, list[str]]:
    """Check the lock files of the Python tools (feat-22-python-tools-lockfile). Return a message and the problems."""
    problems: list[str] = []
    if not lock_dir.is_dir():
        return "", [f"Python lock: the folder {lock_dir} (the lock files of the Python tools) does not exist"]
    for name in sorted(path.name for path in lock_dir.iterdir()):
        if name not in PYTHON_LOCK_FILES:
            problems.append(
                f"Python lock: {lock_dir / name} is not allowed. The folder has only {sorted(PYTHON_LOCK_FILES)}"
            )
    notes: list[str] = []
    total = 0
    for lock_name, package, key in PYTHON_LOCKS:
        path = lock_dir / lock_name
        version = versions.get(key, "")
        if not version:
            problems.append(f"{key} is not in tools/versions.env")
        elif not EXACT_VERSION.fullmatch(version):
            problems.append(f"{key} in tools/versions.env is {version!r}, but it must be an exact version")
        if not path.is_file():
            problems.append(f"Python lock: {path} does not exist")
            continue
        entries, found = _python_lock_entries(path)
        problems += found
        total += len(entries)
        if not entries and not found:
            problems.append(f"Python lock: {path} has no package")
        tool_versions = sorted({entry_version for _, entry, entry_version in entries if entry == package})
        if not tool_versions:
            if entries:
                problems.append(f"Python lock: {path} has no entry of {package}")
        elif version and tool_versions != [version]:
            problems.append(
                f"Python lock: {path} has {package} {', '.join(tool_versions)}, but {key} in tools/versions.env is {version}"
            )
        notes.append(f"{package} {version}")
    note = f"Python locks: {lock_dir}: {len(PYTHON_LOCKS)} lock files, {total} entries ({', '.join(notes)}), exact pins with hashes"
    return ("" if problems else note), problems


def main(argv: list[str]) -> int:
    if len(argv) != 7:
        print(
            "Usage: check_pins.py <versions.env> <workflows-dir> <allowed-actions> <project-root> <sbom-tool-dir> "
            "<python-lock-dir>",
            file=sys.stderr,
        )
        return 2
    try:
        versions = read_versions(Path(argv[1]))
        allowed = read_allowed(Path(argv[3]))
        problems: list[str] = []
        total = 0
        for path, workflow in load_workflows(Path(argv[2])):
            count, found = check_file(path, workflow, versions, allowed)
            print(f"{path}: {count} `uses:` step(s), {len(found)} problem(s)")
            total += count
            problems += found
        note, maven_problems = check_maven(Path(argv[4]), versions)
        print(f"Maven pin: {note or str(len(maven_problems)) + ' problem(s)'}")
        problems += maven_problems
        note, sbom_problems = check_sbom_tool(Path(argv[5]), versions)
        print(f"SBOM tool pin: {note or str(len(sbom_problems)) + ' problem(s)'}")
        problems += sbom_problems
        note, python_problems = check_python_locks(Path(argv[6]), versions)
        print(f"Python lock pin: {note or str(len(python_problems)) + ' problem(s)'}")
        problems += python_problems
    except GateError as error:
        print(f"ERROR: {error}", file=sys.stderr)
        return 2
    if problems:
        for problem in problems:
            print(f"STOP {problem}")
        print(f"RESULT: STOP. {len(problems)} problem(s).")
        return 1
    print(
        f"RESULT: PASS. {total} `uses:` step(s) with a full SHA, a comment and the versions of tools/versions.env. "
        "The lock file of cdxgen and the lock files of the Python tools are the ones of tools/versions.env."
    )
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
