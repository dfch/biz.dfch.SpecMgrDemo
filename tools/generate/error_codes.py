#!/usr/bin/env python3
"""Compare the list of error codes of the OpenAPI file with the generated Java enum and the generated Zod schemas.

feat-6-contracts-openapi-pipeline, Task 120.120 (REQ-006, ACC-008).

Usage: error_codes.py <openapi file> <java json> <zod json>
  <openapi file>  contracts/openapi.yaml. The list is `components.schemas.ErrorCode.enum`.
  <java json>     the output of ErrorCodes.java: a JSON array with the value (getValue()) of each constant of the enum.
  <zod json>      the output of error-codes.mjs: a JSON object with the arrays `errorCodeSchema` (the export
                  `errorCodeSchema`) and `problemCode` (the schema of `Problem.code`).

The three lists must be the same, with the same values in the same order. The script reports each list that is not the
same as the list of the OpenAPI file, with the values that are missing and the values that are extra. Exit codes: 0 the
lists are the same; 1 a list is not the same; 2 a file cannot be read or has not the expected form.
"""

import json
import sys
from pathlib import Path
from typing import Any

import yaml


class InputError(Exception):
    """A file cannot be read or has not the expected form (exit code 2)."""


def load_json(path: str) -> Any:
    try:
        return json.loads(Path(path).read_text(encoding="utf-8"))
    except (OSError, ValueError) as error:
        raise InputError(f"cannot read {path} as JSON: {error}") from error


def string_list(name: str, value: Any) -> list[str]:
    if not isinstance(value, list) or not all(isinstance(item, str) for item in value):
        raise InputError(f"{name} is not a list of texts: {value!r}")
    return value


def main(argv: list[str]) -> int:
    if len(argv) != 4:
        print("Usage: error_codes.py <openapi file> <java json> <zod json>", file=sys.stderr)
        return 2
    try:
        spec = yaml.safe_load(Path(argv[1]).read_text(encoding="utf-8"))
        expected = string_list("components.schemas.ErrorCode.enum", spec["components"]["schemas"]["ErrorCode"]["enum"])
    except (OSError, yaml.YAMLError, KeyError, TypeError, InputError) as error:
        print(f"ERROR: cannot read the list of error codes in {argv[1]}: {error!r}", file=sys.stderr)
        return 2
    try:
        java = string_list("the Java list", load_json(argv[2]))
        zod = load_json(argv[3])
        if not isinstance(zod, dict) or not {"errorCodeSchema", "problemCode"} <= set(zod):
            raise InputError(f"{argv[3]} is not an object with `errorCodeSchema` and `problemCode`")
        candidates = {
            "Java enum ErrorCode (getValue())": java,
            "Zod export errorCodeSchema (.options)": string_list("errorCodeSchema", zod["errorCodeSchema"]),
            "Zod Problem.code (.options)": string_list("problemCode", zod["problemCode"]),
        }
    except InputError as error:
        print(f"ERROR: {error}", file=sys.stderr)
        return 2
    print(f"OpenAPI file ({argv[1]}): {expected}")
    problems = 0
    if len(set(expected)) != len(expected):
        print("STOP the list in the OpenAPI file has a value twice")
        problems += 1
    for name, found in candidates.items():
        if found == expected:
            print(f"ok   {name}: the same {len(found)} values in the same order")
            continue
        problems += 1
        missing, extra = [v for v in expected if v not in found], [v for v in found if v not in expected]
        detail = (
            f"missing {missing}, extra {extra}"
            if missing or extra
            else "the same values in another order or a value twice"
        )
        print(f"STOP {name}: {found} is not the list of the OpenAPI file ({detail})")
    if problems:
        print(f"RESULT: STOP. {problems} list(s) are not the list of the OpenAPI file.")
        return 1
    print(
        "RESULT: PASS. The list of error codes is the same in the OpenAPI file, in the Java enum and in the Zod schemas."
    )
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
