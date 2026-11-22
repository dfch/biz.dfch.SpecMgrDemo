#!/usr/bin/env python3
"""Gate 2: the traceability check (feat-8-traceability-security-gates, Task 110.110 to 110.120).

DEC f21920d2-4da5-4cf7-bd94-2e9bcba77342: the project uses the specmgr identifier as the only reference. This script
reads the references of the documents and the identifiers in the OpenAPI file, in the Structurizr workspace and in the
tests.

Usage: traceability.py <repository root> [--reader-module <module>]

The script runs in the hash-locked environment of specmgr (`traceability.sh` makes it). It reads the references of the
documents with the function `find_references` of the pinned specmgr. It has no second copy of the syntax of the
references. The module of the function is not a public interface of specmgr, so the script examines its form before each
run (the function exists, it has the parameter `text`, and it gives the pairs that the script expects for a probe text).
The script stops with exit code 2 if the form is not the same. `--reader-module` names another module for this (only the
self-test uses it).

What the script checks (the table of checks of the plan):

  Level    Rule                              Check
  -------  --------------------------------  ----------------------------------------------------------------------
  ERROR    reference-has-no-target           each reference in the `.md` files of `docs/` and `.specmgr/` has a
                                             document with this identifier in `docs/<type>/` (feat: `.specmgr/feat/`)
  ERROR    openapi-req-not-found             `x-specmgr-req` of each operation of `contracts/openapi.yaml` is the
                                             identifier of a REQ document
  ERROR    model-id-has-no-document          each identifier in the property `specmgr-req` of `model/workspace.json`
                                             (one identifier, or a list that the character comma separates) is the
                                             identifier of a REQ document (the old form: it keeps working for one
                                             release, the compatibility of feat-50 Task 150.110)
  ERROR    model-ref-bad-form                the value of the property `specmgr-refs` of `model/workspace.json`
                                             (the new form, DEC e85e9685-0787-4dff-9ee5-9d46670e9ee4) is a text of the
                                             form TYPE UUID; TYPE UUID (each entry is a document type and an
                                             identifier, one space between them, the text '; ' between the entries)
  ERROR    model-ref-has-no-document         the identifier of each entry of the property `specmgr-refs` is the
                                             identifier of a document of that type in `docs/<type>/` (a document of
                                             another type for the identifier is an error too)
  ERROR    test-vcr-has-no-document          each `vcr:<uuid>` in a test of the backend and of the frontend is the
                                             identifier of a VCR document
  ERROR    approved-req-has-no-vcr           an approved REQ has a VCR
  ERROR    test-file-outside-test-roots      a test file of `backend/` or `frontend/` (`*Test.java`, `*Tests.java`,
                                             `*IT.java`, `*.test.ts`, `*.spec.ts` and the same for the other suffixes)
                                             is in a folder of TEST_ROOTS. A new test folder must not be ignored in silence
  WARNING  approved-req-has-no-model-element an approved REQ is in the property `specmgr-req` of an element, or in
                                             an entry of the type REQ of the property `specmgr-refs` (the check reads
                                             the two forms independently and counts the REQ identifiers of the
                                             element in the two forms)
  WARNING  approved-req-vcr-not-in-test      the VCR of an approved REQ is in the name of a test

Definitions (Task 110.100):

  - A REQ is approved if its `status` is `accepted` or `implemented`. The REQ has no status `approved`. The other
    statuses (`draft`, `proposed`, `superseded`, `deprecated`, `rejected`) are not approved.
  - A VCR belongs to a REQ if the section `## Verifies` of the VCR has the reference `REQ <uuid>` of the REQ. The status
    of the VCR is not examined.
  - The property `specmgr-refs` of the model (the new form, DEC e85e9685-0787-4dff-9ee5-9d46670e9ee4): the value is
    one or more entries that the text `; ` (semicolon and one space, exactly) separates, and the form of an entry is
    `TYPE UUID` (one space between the type and the identifier). The type is one of the types of document that the tag
    of reference uses with an identifier of the form UUID (GOL, PRB, QA, UC, REQ, RSK, DEC, ADR, VCR, SYSRS and TXT,
    upper case), and the identifier is the identifier of a document of that type in `docs/<type>/` (the same index
    that the check of the references of the documents uses). The old property `specmgr-req` (the identifier bare, that
    the character comma separates) keeps working for one release (the compatibility of feat-50 Task 150.110): an
    element may have the old form, the new form, or both (the compatibility of one release); the check reads the two
    forms independently, and the warning and the report count the REQ identifiers of the element in the two forms (an
    identifier that the element gives in the two forms is counted one time).
  - A test has a VCR if the text `vcr:<uuid>` is inside a string literal ("...", '...', a backtick string, or a text
    block with three double quotes) of a test source. The script splits the source into code, comments and strings (a
    line comment `//`, a block comment `/* ... */` that can span lines, also for lines that do not start with `*`), and
    it reads only the strings. A `vcr:<uuid>` in a comment of any form does not count. The script reads the text of the
    source, and not the name that the test run reports.
  - The folders of the test sources are TEST_ROOTS. The guard `test-file-outside-test-roots` walks the folders
    `backend/` and `frontend/` and stops (error) for a test file (by its name) outside TEST_ROOTS, so a new test folder
    is not ignored in silence. A folder of SKIPPED_FOLDERS (`node_modules`, `build`, `target`, `.git`) is not entered;
    in a module the output folders of the recipes (`.stryker-tmp`, `mutation-report`, `coverage`, `test-results`,
    `playwright-report`) are not entered either.
  - A loop of directory links below a folder that the script walks (a link to a parent folder) stops the script
    (exit code 2): it fails closed and does not follow the loop. A link to a folder that is no loop is followed.

The script prints each finding with the file and the rule. The errors and the warnings are two separate parts of the
output. Exit codes: 0 no error (a warning is no stop), 1 at least one error, 2 an input that the script cannot read, or
a reader of references that has not the expected form.
"""

from __future__ import annotations

import argparse
import importlib
import inspect
import json
import re
import sys
from collections.abc import Callable, Iterator
from dataclasses import dataclass
from pathlib import Path
from typing import Any

import yaml

DEFAULT_READER_MODULE = "biz.dfch.specmgr.general.tools._references"
READER_FUNCTION = "find_references"

# The statuses of a REQ document (the model of specmgr) that are "approved" for this check.
APPROVED_REQ_STATUSES = frozenset({"accepted", "implemented"})

# The identifier of a specmgr document (not the syntax of a reference: this is in find_references).
UUID_PATTERN = re.compile(r"[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}")
# The convention for the name of a test: the text `vcr:<uuid>`.
VCR_TEST_PATTERN = re.compile(r"\bvcr:(" + UUID_PATTERN.pattern + r")(?![0-9a-f])", re.IGNORECASE)

MODEL_PROPERTY = "specmgr-req"
MODEL_REFS_PROPERTY = "specmgr-refs"
OPENAPI_EXTENSION = "x-specmgr-req"
OPENAPI_METHODS = ("get", "put", "post", "delete", "options", "head", "patch", "trace")

# The folder of each type of document that a reference can name (the types of find_references). `feat` is not in the
# list: a feature is a folder with a README.md in `.specmgr/feat/`.
DOC_TYPES = (
    "gol",
    "prb",
    "qa",
    "uc",
    "req",
    "rsk",
    "dec",
    "adr",
    "vcr",
    "sysrs",
    "txt",
)
FEAT_TYPE = "feat"
FEAT_DIR = Path(".specmgr") / "feat"

# The text that separates the entries of `specmgr-refs` (DEC e85e9685-0787-4dff-9ee5-9d46670e9ee4: semicolon and one
# space, exactly).
MODEL_REFS_SEPARATOR = "; "
# The document types of an entry of `specmgr-refs`: the types of DOC_TYPES, upper case (the form names the type in
# upper case). One source for the types: `feat` is not in DOC_TYPES, and the id of a feature is no UUID.
MODEL_REF_TYPES = frozenset(doc_type.upper() for doc_type in DOC_TYPES)
# The form of one entry of `specmgr-refs`: TYPE UUID (one space between the type and the identifier). The type is
# upper case; the case of the identifier does not matter (the check compares it in lower case, as the old form does).
MODEL_REF_ENTRY = re.compile(r"([A-Z]+) ([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12})")

# The suffixes of the test files of the frontend (all the suffixes of the files that the check reads there).
FRONTEND_SUFFIXES = frozenset({".ts", ".tsx", ".js", ".jsx", ".mjs", ".cjs", ".mts", ".cts"})

# The folders and the suffixes of the test sources: the tests of the backend (JUnit) and of the frontend (Vitest,
# Playwright).
TEST_ROOTS: tuple[tuple[Path, frozenset[str]], ...] = (
    (Path("backend") / "src" / "test", frozenset({".java", ".kt"})),
    (Path("frontend") / "src" / "test", FRONTEND_SUFFIXES),
    (Path("frontend") / "e2e", FRONTEND_SUFFIXES),
)
# The guard of TEST_ROOTS: the modules that the guard walks, and the names of a test file in them. The pattern is a
# deliberate simplification: it covers a subset of the default test file names of JUnit with Maven Surefire and
# Failsafe (*Test.java, *Tests.java, *IT.java, also .kt), of Vitest (*.test.<suffix>) and of Playwright
# (*.spec.<suffix>). The defaults also have names that the pattern does not catch (Test*.java and *TestCase.java of
# Surefire, IT*.java and *ITCase.java of Failsafe).
TEST_GUARD_MODULES = (Path("backend"), Path("frontend"))
# `IT` needs a lower case letter or a digit before it, so a class name in capital letters (for example EDIT) is not a test.
TEST_FILE_NAME = re.compile(r"(?:(?:Tests?|(?<=[a-z0-9])IT)\.(?:java|kt)|\.(?:test|spec)\.(?:[cm]?[jt]sx?))$")
SKIPPED_FOLDERS = frozenset({"node_modules", ".git", "build", "target"})
# The guard of TEST_ROOTS also skips these folders directly in a module: the output of the recipes (they are in
# .gitignore). The sandbox of Stryker has a copy of the tests, and the guard must not stop for it after a local run.
# A folder with one of these names deeper in a module (for example frontend/src/test/coverage) is walked.
GUARD_SKIPPED_MODULE_FOLDERS = frozenset(
    {".stryker-tmp", "mutation-report", "coverage", "test-results", "playwright-report"}
)

PROBE_TEXT = (
    "REQ 1ca335d7-969a-443e-9392-165fdeea99a0: a requirement\n"
    "- VCR-0e15a8c1-2b3d-4e5f-8a9b-0c1d2e3f4a5b\n"
    "Text FEAT feat-8-traceability-security-gates and reqx 1ca335d7-969a-443e-9392-165fdeea99a0.\n"
)
PROBE_RESULT = [
    ("req", "1ca335d7-969a-443e-9392-165fdeea99a0"),
    ("vcr", "0e15a8c1-2b3d-4e5f-8a9b-0c1d2e3f4a5b"),
    ("feat", "feat-8-traceability-security-gates"),
]

FindReferences = Callable[[str], list[tuple[str, str]]]


class InputError(Exception):
    """An input that the script cannot read (exit code 2)."""


@dataclass(frozen=True)
class Finding:
    """One finding of the check."""

    level: str  # ERROR or WARNING
    rule: str
    file: str
    line: int | None
    message: str

    def render(self) -> str:
        """Return the line of the report."""
        place = self.file if self.line is None else f"{self.file}:{self.line}"
        result = f"  {self.level} {place}: [{self.rule}] {self.message}"
        return result


@dataclass(frozen=True)
class Document:
    """A document that the index has."""

    path: Path
    status: str | None


@dataclass
class Index:
    """The documents of `docs/<type>/` (by type and identifier) and the features of `.specmgr/feat/`."""

    documents: dict[tuple[str, str], Document]
    features: set[str]

    def has(self, doc_type: str, doc_id: str) -> bool:
        """Return True if a document with this type and identifier exists. `feat` accepts the full or the bare id."""
        if doc_type == FEAT_TYPE:
            if doc_id in self.features:
                return True
            return re.fullmatch(r"feat-[0-9]+", doc_id) is not None and any(
                name.startswith(f"{doc_id}-") for name in self.features
            )
        return (doc_type, doc_id) in self.documents


def read_text(path: Path) -> str:
    """Read a file as UTF-8 text, or stop with an input error."""
    try:
        return path.read_text(encoding="utf-8")
    except (OSError, UnicodeDecodeError) as error:
        raise InputError(f"cannot read {path}: {error}") from error


def load_reader(module_name: str) -> FindReferences:
    """Return `find_references` of the module, after the examination of its form (ACC-004)."""
    try:
        module = importlib.import_module(module_name)
    except ImportError as error:
        raise InputError(f"the reader of references: cannot import the module {module_name}: {error}") from error
    reader = getattr(module, READER_FUNCTION, None)
    if not callable(reader):
        raise InputError(f"the reader of references: the module {module_name} has no function {READER_FUNCTION}")
    try:
        parameters = list(inspect.signature(reader).parameters.values())
    except (TypeError, ValueError) as error:
        raise InputError(
            f"the reader of references: cannot read the signature of {READER_FUNCTION}: {error}"
        ) from error
    if [parameter.name for parameter in parameters] != ["text"]:
        names = [parameter.name for parameter in parameters]
        raise InputError(
            f"the reader of references: {READER_FUNCTION} of {module_name} has the parameters {names}, "
            "but the form that the check expects is (text)"
        )
    try:
        probe = reader(PROBE_TEXT)
    except Exception as error:  # pylint: disable=broad-exception-caught
        raise InputError(f"the reader of references: {READER_FUNCTION}(probe text) raised {error!r}") from error
    if probe != PROBE_RESULT:
        raise InputError(
            f"the reader of references: {READER_FUNCTION} of {module_name} gives {probe!r} for the probe text, "
            f"but the form that the check expects is {PROBE_RESULT!r}"
        )
    return reader  # type: ignore[no-any-return]


def split_frontmatter(text: str) -> tuple[str | None, str, int]:
    """Split a document into the frontmatter (None if none), the body, and the number of lines of the frontmatter."""
    match = re.match(r"---[ \t]*\r?\n(.*?\r?\n)?---[ \t]*(?:\r?\n|$)", text, re.DOTALL)
    if match is None:
        return None, text, 0
    consumed = match.group(0)
    return match.group(1) or "", text[len(consumed) :], consumed.count("\n")


def walk_files(folder: Path, suffixes: frozenset[str], _ancestors: tuple[Path, ...] = ()) -> Iterator[Path]:
    """Yield the files with one of the suffixes below the folder (sorted), without the folders of SKIPPED_FOLDERS.

    A link to a folder is followed, but a loop of links (a folder that is the folder itself or one of its parents, after
    the links are resolved) stops the script with an input error (exit code 2): the walk fails closed and does not
    follow a loop.
    """
    real = folder.resolve()
    if real in _ancestors:
        raise InputError(
            f"the folder {folder} is a loop of links: after the links are resolved it is {real}, which the walk "
            "has entered already (a folder that is its own parent). Remove the link"
        )
    chain = (*_ancestors, real)
    for path in sorted(folder.iterdir()):
        if path.is_dir():
            if path.name not in SKIPPED_FOLDERS:
                yield from walk_files(path, suffixes, chain)
        elif path.suffix in suffixes:
            yield path


def require_folder(root: Path, relative: Path) -> Path:
    """Return the folder of the repository, or stop with an input error."""
    path = root / relative
    if not path.is_dir():
        raise InputError(f"the folder {relative.as_posix()} does not exist in {root}")
    return path


def build_index(root: Path) -> Index:
    """Read the identifiers and the statuses of the documents in `docs/<type>/` and the folders of `.specmgr/feat/`."""
    require_folder(root, Path("docs"))
    documents: dict[tuple[str, str], Document] = {}
    for doc_type in DOC_TYPES:
        folder = root / "docs" / doc_type
        if not folder.is_dir():
            continue
        for path in sorted(folder.glob("*.md")):
            front, _, _ = split_frontmatter(read_text(path))
            if front is None:
                continue
            try:
                data = yaml.safe_load(front)
            except yaml.YAMLError as error:
                raise InputError(
                    f"cannot read the frontmatter of {path.relative_to(root).as_posix()}: {error}"
                ) from error
            if not isinstance(data, dict) or not isinstance(data.get("id"), str):
                continue
            status = data.get("status")
            documents[(doc_type, data["id"].lower())] = Document(path, status if isinstance(status, str) else None)
    features: set[str] = set()
    feat_folder = require_folder(root, FEAT_DIR)
    for path in sorted(feat_folder.iterdir()):
        if path.is_dir() and (path / "README.md").is_file():
            features.add(path.name.lower())
    return Index(documents, features)


def line_of(lines: list[str], needle: str, start: int) -> int | None:
    """Return the 1-based number of the first line from `start` (0-based) that has the text, or None."""
    for number in range(start, len(lines)):
        if needle in lines[number].lower():
            return number + 1
    return None


def check_references(root: Path, reader: FindReferences, index: Index, findings: list[Finding]) -> tuple[int, int]:
    """Check each reference in the `.md` files of `docs/` and `.specmgr/`. Return the numbers of files, references."""
    files = 0
    references = 0
    for base in (Path("docs"), Path(".specmgr")):
        folder = require_folder(root, base)
        for path in walk_files(folder, frozenset({".md"})):
            files += 1
            text = read_text(path)
            _, body, front_lines = split_frontmatter(text)
            lines = text.splitlines()
            seen: set[tuple[str, str]] = set()
            for ref_type, ref_id in reader(body):
                if (ref_type, ref_id) in seen:
                    continue
                seen.add((ref_type, ref_id))
                references += 1
                if ref_type != FEAT_TYPE and ref_type not in DOC_TYPES:
                    message = f"the reference {ref_type.upper()} {ref_id} has a type that the check does not know"
                elif index.has(ref_type, ref_id):
                    continue
                else:
                    where = FEAT_DIR.as_posix() if ref_type == FEAT_TYPE else f"docs/{ref_type}"
                    message = (
                        f"the reference {ref_type.upper()} {ref_id} has no target: no document with this id in {where}"
                    )
                findings.append(
                    Finding(
                        "ERROR",
                        "reference-has-no-target",
                        path.relative_to(root).as_posix(),
                        line_of(lines, ref_id, front_lines),
                        message,
                    )
                )
    return files, references


def split_ids(value: Any) -> list[str] | str:
    """Split the value of `specmgr-req` or `x-specmgr-req` at the commas. Return the cause if it is not a text."""
    if isinstance(value, list):
        parts: list[str] = []
        for item in value:
            if not isinstance(item, str):
                return f"the value {item!r} is not a text"
            parts.extend(item.split(","))
        return [part.strip().lower() for part in parts]
    if not isinstance(value, str):
        return f"the value {value!r} is not a text"
    return [part.strip().lower() for part in value.split(",")]


def check_req_ids(rule: str, file: str, where: str, value: Any, index: Index, findings: list[Finding]) -> list[str]:
    """Check that each identifier in the value is the identifier of a REQ document. Return the identifiers."""
    ids = split_ids(value)
    if isinstance(ids, str):
        findings.append(Finding("ERROR", rule, file, None, f"{where}: {ids}"))
        return []
    for item in ids:
        if not UUID_PATTERN.fullmatch(item):
            findings.append(
                Finding(
                    "ERROR",
                    rule,
                    file,
                    None,
                    f"{where}: '{item}' is not a specmgr identifier",
                )
            )
        elif not index.has("req", item):
            others = [doc_type for doc_type in DOC_TYPES if doc_type != "req" and index.has(doc_type, item)]
            cause = f"it is the id of a {others[0].upper()} document" if others else "no document has this id"
            findings.append(
                Finding(
                    "ERROR",
                    rule,
                    file,
                    None,
                    f"{where}: {item} is not the id of a REQ document ({cause})",
                )
            )
    return [item for item in ids if UUID_PATTERN.fullmatch(item)]


def check_openapi(root: Path, index: Index, findings: list[Finding]) -> int:
    """Check `x-specmgr-req` of each operation of `contracts/openapi.yaml`. Return the number of identifiers."""
    relative = Path("contracts") / "openapi.yaml"
    path = root / relative
    if not path.is_file():
        raise InputError(f"the file {relative.as_posix()} does not exist in {root}")
    try:
        data = yaml.safe_load(read_text(path))
    except yaml.YAMLError as error:
        raise InputError(f"cannot read {relative.as_posix()}: {error}") from error
    if not isinstance(data, dict) or not isinstance(data.get("paths"), dict):
        raise InputError(f"{relative.as_posix()} has no `paths` object")
    count = 0
    for route, operations in data["paths"].items():
        if not isinstance(operations, dict):
            continue
        for method in OPENAPI_METHODS:
            operation = operations.get(method)
            if not isinstance(operation, dict) or OPENAPI_EXTENSION not in operation:
                continue
            ids = check_req_ids(
                "openapi-req-not-found",
                relative.as_posix(),
                f"the operation {method.upper()} {route}, {OPENAPI_EXTENSION}",
                operation[OPENAPI_EXTENSION],
                index,
                findings,
            )
            count += len(ids)
    return count


def walk_model(node: Any, trail: str) -> Iterator[tuple[str, str, Any]]:
    """Yield (the label, the property name, the value) for each object of the workspace that has one of the
    traceability properties (`specmgr-req`, the old form, `specmgr-refs`, the new form)."""
    if isinstance(node, dict):
        label = trail
        if isinstance(node.get("name"), str):
            label = f"{trail}/{node['name']}" if trail else node["name"]
        properties = node.get("properties")
        if isinstance(properties, dict):
            for property_name in (MODEL_PROPERTY, MODEL_REFS_PROPERTY):
                if property_name in properties:
                    yield label or "(workspace)", property_name, properties[property_name]
        for key, value in node.items():
            if key != "properties":
                yield from walk_model(value, label)
    elif isinstance(node, list):
        for item in node:
            yield from walk_model(item, trail)


def article(doc_type: str) -> str:
    """Return the article for the upper case document type (ADR is the only type that starts with a vowel sound)."""
    return "an" if doc_type.upper() == "ADR" else "a"


def check_refs(label: str, value: Any, model_file: str, index: Index, findings: list[Finding]) -> list[str]:
    """Check the value of the property `specmgr-refs` of the element `label` (the form TYPE UUID; TYPE UUID).

    Stop (error) for a value that is no text, for an entry that is no form TYPE UUID (the text '; ' with no space
    after the semicolon, an identifier without the type), for a type that is not a document type, and for an
    identifier that has no document of that type (a document of another type for the identifier is an error too).
    Return the REQ identifiers of the value (the entries of the type REQ, also the ones that the check stops for:
    the behavior of the old form).
    """
    where = f"the element {label}, {MODEL_REFS_PROPERTY}"
    if not isinstance(value, str):
        findings.append(
            Finding("ERROR", "model-ref-bad-form", model_file, None, f"{where}: the value {value!r} is not a text")
        )
        return []
    ids: list[str] = []
    for entry in value.split(MODEL_REFS_SEPARATOR):
        match = MODEL_REF_ENTRY.fullmatch(entry)
        if match is None:
            findings.append(
                Finding(
                    "ERROR",
                    "model-ref-bad-form",
                    model_file,
                    None,
                    f"{where}: the entry '{entry}' is not the form TYPE UUID (one space between the type and the "
                    "identifier, the text '; ' between the entries)",
                )
            )
            continue
        ref_type = match.group(1)
        ref_id = match.group(2).lower()
        if ref_type not in MODEL_REF_TYPES:
            findings.append(
                Finding(
                    "ERROR",
                    "model-ref-bad-form",
                    model_file,
                    None,
                    f"{where}: the type {ref_type} is not a document type (the entry is '{entry}')",
                )
            )
        elif not index.has(ref_type.lower(), ref_id):
            others = [
                doc_type for doc_type in DOC_TYPES if doc_type != ref_type.lower() and index.has(doc_type, ref_id)
            ]
            cause = (
                f"it is the id of {article(others[0])} {others[0].upper()} document"
                if others
                else "no document has this id"
            )
            findings.append(
                Finding(
                    "ERROR",
                    "model-ref-has-no-document",
                    model_file,
                    None,
                    f"{where}: {ref_id} is not the id of {article(ref_type)} {ref_type} document ({cause})",
                )
            )
        if ref_type == "REQ":
            ids.append(ref_id)
    return ids


def read_model(root: Path, index: Index, findings: list[Finding]) -> set[str]:
    """Check `specmgr-req` and `specmgr-refs` of `model/workspace.json`. Return the REQ identifiers that the model has.

    The check reads the two forms independently (an element may have the old form, the new form, or both, the
    compatibility of one release): each identifier of the property `specmgr-req` must be the identifier of a REQ
    document, and each entry of the property `specmgr-refs` is checked per entry (the form, the type, the document).
    The warning and the report count the REQ identifiers of the element in the two forms (an identifier that the
    element gives in the two forms is counted one time).
    """
    relative = Path("model") / "workspace.json"
    path = root / relative
    if not path.is_file():
        raise InputError(f"the file {relative.as_posix()} does not exist in {root}")
    try:
        data = json.loads(read_text(path))
    except ValueError as error:
        raise InputError(f"cannot read {relative.as_posix()}: {error}") from error
    if not isinstance(data, dict) or not isinstance(data.get("model"), dict):
        raise InputError(f"{relative.as_posix()} has no `model` object")
    model_file = relative.as_posix()
    found: set[str] = set()
    for label, property_name, value in walk_model(data["model"], ""):
        if property_name == MODEL_PROPERTY:
            found.update(
                check_req_ids(
                    "model-id-has-no-document",
                    model_file,
                    f"the element {label}, {MODEL_PROPERTY}",
                    value,
                    index,
                    findings,
                )
            )
        else:
            found.update(check_refs(label, value, model_file, index, findings))
    return found


def string_spans(text: str, nested_comments: bool) -> list[tuple[int, int]]:
    """Return the (start, end) offsets of the content of each string literal of a source text.

    The scan goes from the start of the text and knows four states: code, a line comment (`//`, to the end of the line),
    a block comment (`/*` to `*/`, over any number of lines, also for lines that do not start with `*`; Kotlin nests
    them), and a string. A string is "...", '...' (the end of the line ends it, a backslash escapes the next
    character), a backtick string (it can span lines) or a text block with three double quotes (Java, Kotlin; it can
    span lines). A quote character in a comment does not start a string, and a comment mark in a string does not start a
    comment. The scan is not a parser: a regular expression literal of JavaScript with a quote character can start a
    string that ends at the end of the line, and this affects one line only.
    """
    spans: list[tuple[int, int]] = []
    length = len(text)
    position = 0
    while position < length:
        two = text[position : position + 2]
        if two == "//":
            end = text.find("\n", position)
            position = length if end < 0 else end
        elif two == "/*":
            depth = 1
            position += 2
            while position < length and depth > 0:
                if nested_comments and text.startswith("/*", position):
                    depth += 1
                    position += 2
                elif text.startswith("*/", position):
                    depth -= 1
                    position += 2
                else:
                    position += 1
        elif text.startswith('"""', position):
            end = text.find('"""', position + 3)
            end = length if end < 0 else end
            spans.append((position + 3, end))
            position = end + 3
        elif text[position] in "\"'`":
            quote = text[position]
            end = position + 1
            while end < length:
                char = text[end]
                if char == "\\":
                    end += 2
                    continue
                if char == quote or (char == "\n" and quote != "`"):
                    break
                end += 1
            end = min(end, length)
            spans.append((position + 1, end))
            position = end + 1
        else:
            position += 1
    return spans


def vcr_in_strings(text: str, nested_comments: bool) -> Iterator[tuple[int, str]]:
    """Yield (the 1-based line, the lower case identifier) of each `vcr:<uuid>` that is inside a string literal."""
    for start, end in string_spans(text, nested_comments):
        for match in VCR_TEST_PATTERN.finditer(text, start, end):
            yield text.count("\n", 0, match.start()) + 1, match.group(1).lower()


def read_tests(root: Path, index: Index, findings: list[Finding]) -> set[str]:
    """Check `vcr:<uuid>` in the test sources. Return the identifiers that the tests have."""
    found: set[str] = set()
    for relative, suffixes in TEST_ROOTS:
        folder = require_folder(root, relative)
        for path in walk_files(folder, suffixes):
            for number, vcr_id in vcr_in_strings(read_text(path), path.suffix == ".kt"):
                found.add(vcr_id)
                if not index.has("vcr", vcr_id):
                    others = [doc_type for doc_type in DOC_TYPES if doc_type != "vcr" and index.has(doc_type, vcr_id)]
                    cause = f"it is the id of a {others[0].upper()} document" if others else "no document has this id"
                    findings.append(
                        Finding(
                            "ERROR",
                            "test-vcr-has-no-document",
                            path.relative_to(root).as_posix(),
                            number,
                            f"vcr:{vcr_id} is not the id of a VCR document ({cause})",
                        )
                    )
    return found


def check_test_roots(root: Path, findings: list[Finding]) -> int:
    """Stop (error) for a test file in `backend/` or `frontend/` outside TEST_ROOTS. Return the number of such files.

    The folders of TEST_ROOTS are fixed in this script. A new test folder (another source set of Maven, another
    include of Vitest or Playwright) would be ignored in silence, and a `vcr:<uuid>` in it would be neither read nor
    checked. This guard finds a test file by its name (JUnit: `*Test.java`, `*Tests.java`, `*IT.java`, and the same
    for `.kt`; Vitest and Playwright: `*.test.<suffix>` and `*.spec.<suffix>`) outside the folders that the script
    reads, and the fix is one line in TEST_ROOTS.
    """
    roots = [relative for relative, _ in TEST_ROOTS]
    count = 0
    for module in TEST_GUARD_MODULES:
        folder = require_folder(root, module)
        suffixes = frozenset({".java", ".kt"}) | FRONTEND_SUFFIXES
        paths: list[Path] = []
        for child in sorted(folder.iterdir()):
            if child.is_dir():
                if child.name not in SKIPPED_FOLDERS and child.name not in GUARD_SKIPPED_MODULE_FOLDERS:
                    paths.extend(walk_files(child, suffixes))
            elif child.suffix in suffixes:
                paths.append(child)
        for path in paths:
            relative = path.relative_to(root)
            if not TEST_FILE_NAME.search(path.name) or any(relative.is_relative_to(test_root) for test_root in roots):
                continue
            count += 1
            findings.append(
                Finding(
                    "ERROR",
                    "test-file-outside-test-roots",
                    relative.as_posix(),
                    None,
                    "this test file is in no folder that the check reads for `vcr:<uuid>` "
                    f"({', '.join(test_root.as_posix() for test_root in roots)}). Add its folder to TEST_ROOTS in "
                    "tools/gates/traceability.py, or move the file",
                )
            )
    return count


def vcr_links(reader: FindReferences, index: Index) -> dict[str, list[str]]:
    """Return the identifiers of the VCR documents for each REQ: the REQ in the section `## Verifies` of the VCR."""
    links: dict[str, list[str]] = {}
    for (doc_type, vcr_id), document in sorted(index.documents.items()):
        if doc_type != "vcr":
            continue
        _, body, _ = split_frontmatter(read_text(document.path))
        section = re.search(
            r"^##[ \t]+Verifies[ \t]*\r?\n(.*?)(?=^##[ \t]|\Z)",
            body,
            re.DOTALL | re.MULTILINE,
        )
        if section is None:
            continue
        for ref_type, ref_id in reader(section.group(1)):
            if ref_type == "req" and vcr_id not in links.setdefault(ref_id, []):
                links[ref_id].append(vcr_id)
    return links


def check_approved_reqs(
    root: Path,
    index: Index,
    links: dict[str, list[str]],
    model_ids: set[str],
    test_ids: set[str],
    findings: list[Finding],
) -> int:
    """Check each approved REQ: a VCR (error), an element in the model (warning), and the VCR in a test (warning)."""
    approved = 0
    for (doc_type, req_id), document in sorted(index.documents.items()):
        if doc_type != "req" or document.status not in APPROVED_REQ_STATUSES:
            continue
        approved += 1
        file = document.path.relative_to(root).as_posix()
        vcrs = links.get(req_id, [])
        if not vcrs:
            findings.append(
                Finding(
                    "ERROR",
                    "approved-req-has-no-vcr",
                    file,
                    None,
                    f"the REQ {req_id} has the status {document.status}, but no VCR has it in the section Verifies",
                )
            )
        if req_id not in model_ids:
            findings.append(
                Finding(
                    "WARNING",
                    "approved-req-has-no-model-element",
                    file,
                    None,
                    f"the REQ {req_id} has the status {document.status}, but no element of model/workspace.json has it "
                    f"in the property {MODEL_PROPERTY} or in an entry of the type REQ of the property "
                    f"{MODEL_REFS_PROPERTY}",
                )
            )
        for vcr_id in vcrs:
            if vcr_id not in test_ids:
                findings.append(
                    Finding(
                        "WARNING",
                        "approved-req-vcr-not-in-test",
                        file,
                        None,
                        f"the VCR {vcr_id} of the REQ {req_id} is not in the name of a test (the text vcr:{vcr_id})",
                    )
                )
    return approved


def report(findings: list[Finding]) -> int:
    """Print the warnings and the errors as two parts, then the result. Return the exit code."""
    errors = [finding for finding in findings if finding.level == "ERROR"]
    warnings = [finding for finding in findings if finding.level == "WARNING"]
    print(f"WARNINGS ({len(warnings)}): these do not stop the check")
    for finding in warnings:
        print(finding.render())
    print(f"ERRORS ({len(errors)}): these stop the check")
    for finding in errors:
        print(finding.render())
    if errors:
        print(f"RESULT: FAIL ({len(errors)} error(s), {len(warnings)} warning(s))")
        return 1
    print(f"RESULT: PASS ({len(warnings)} warning(s))")
    return 0


def run(root: Path, reader_module: str) -> int:
    """Run the check on the repository in `root`. Return the exit code."""
    reader = load_reader(reader_module)
    print(f"traceability: reader of references: {READER_FUNCTION} of {reader_module} (the form is the expected form)")
    index = build_index(root)
    findings: list[Finding] = []
    files, references = check_references(root, reader, index, findings)
    openapi_ids = check_openapi(root, index, findings)
    model_ids = read_model(root, index, findings)
    test_ids = read_tests(root, index, findings)
    check_test_roots(root, findings)
    links = vcr_links(reader, index)
    approved = check_approved_reqs(root, index, links, model_ids, test_ids, findings)
    reqs = sum(1 for doc_type, _ in index.documents if doc_type == "req")
    vcrs = sum(1 for doc_type, _ in index.documents if doc_type == "vcr")
    print(
        f"traceability: {files} document files with {references} references (unique per file); "
        f"{reqs} REQ ({approved} approved) and {vcrs} VCR documents; {openapi_ids} identifiers in the OpenAPI file, "
        f"{len(model_ids)} in the model, {len(test_ids)} in the tests"
    )
    return report(findings)


def main(argv: list[str]) -> int:
    """Read the arguments and run the check."""
    parser = argparse.ArgumentParser(description="Gate 2: the traceability check")
    parser.add_argument("root", type=Path, help="the root of the repository")
    parser.add_argument(
        "--reader-module",
        default=DEFAULT_READER_MODULE,
        help="only the self-test uses this",
    )
    arguments = parser.parse_args(argv)
    root: Path = arguments.root.resolve()
    if not root.is_dir():
        print(f"traceability: ERROR: {root} is not a folder", file=sys.stderr)
        return 2
    try:
        result = run(root, arguments.reader_module)
    except InputError as error:
        print(f"traceability: ERROR: {error}", file=sys.stderr)
        result = 2
    return result


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
