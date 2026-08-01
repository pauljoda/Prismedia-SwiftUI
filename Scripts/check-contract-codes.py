#!/usr/bin/env python3
"""Validate native contract-code declarations against Prismedia's code manifest.

The backend publishes this manifest from its canonical definitions and code registries. This
checker intentionally accepts either a URL or a saved manifest so this independent native
checkout never assumes a specific sibling checkout location. It validates every generated native
definition surface against the backend-owned manifest.
"""

from __future__ import annotations

import argparse
import json
import os
import sys
from pathlib import Path
from urllib.error import URLError
from urllib.request import urlopen

from contract_code_codegen import OUTPUT as CONTRACT_CODES_PATH
from contract_code_codegen import render_manifest as render_contract_codes
from entity_capability_codegen import OUTPUT as ENTITY_CAPABILITIES_PATH
from entity_capability_codegen import render_manifest as render_entity_capabilities
from entity_kind_definition_codegen import OUTPUT as ENTITY_KIND_DEFINITIONS_PATH
from entity_kind_definition_codegen import render_manifest as render_entity_kind_definitions
from request_kind_definition_codegen import OUTPUT as REQUEST_KIND_DEFINITIONS_PATH
from request_kind_definition_codegen import render_manifest as render_request_kind_definitions


DEFAULT_CODES_URL = "http://127.0.0.1:8008/api/_codegen/codes.json"


def parse_arguments() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    source = parser.add_mutually_exclusive_group()
    source.add_argument("--manifest", type=Path, help="Saved backend codes.json manifest")
    source.add_argument(
        "--url",
        default=os.environ.get("PRISMEDIA_CODES_URL", DEFAULT_CODES_URL),
        help="Backend codes manifest URL (default: %(default)s)",
    )
    return parser.parse_args()


def load_manifest(arguments: argparse.Namespace) -> dict:
    if arguments.manifest:
        return json.loads(arguments.manifest.read_text(encoding="utf-8"))
    with urlopen(arguments.url, timeout=10) as response:
        return json.load(response)


def main() -> int:
    arguments = parse_arguments()
    try:
        manifest = load_manifest(arguments)
        failures: list[str] = []

        expected_contract_codes = render_contract_codes(manifest)
        actual_contract_codes = CONTRACT_CODES_PATH.read_text(encoding="utf-8")
        if actual_contract_codes != expected_contract_codes:
            failures.append(
                "Generated contract codes differ; run "
                "`python3 Scripts/generate-contract-codes.py`"
            )

        expected_entity_capabilities = render_entity_capabilities(manifest)
        actual_entity_capabilities = ENTITY_CAPABILITIES_PATH.read_text(encoding="utf-8")
        if actual_entity_capabilities != expected_entity_capabilities:
            failures.append(
                "Generated Entity capabilities differ; run "
                "`python3 Scripts/generate-entity-capabilities.py`"
            )

        expected_definitions = render_entity_kind_definitions(manifest)
        actual_definitions = ENTITY_KIND_DEFINITIONS_PATH.read_text(encoding="utf-8")
        if actual_definitions != expected_definitions:
            failures.append(
                "Generated EntityKind definitions differ; run "
                "`python3 Scripts/generate-entity-kind-definitions.py`"
            )

        expected_request_definitions = render_request_kind_definitions(manifest)
        actual_request_definitions = REQUEST_KIND_DEFINITIONS_PATH.read_text(encoding="utf-8")
        if actual_request_definitions != expected_request_definitions:
            failures.append(
                "Generated RequestKind definitions differ; run "
                "`python3 Scripts/generate-request-kind-definitions.py`"
            )

    except (KeyError, OSError, URLError, ValueError, json.JSONDecodeError) as error:
        print(f"Unable to validate Prismedia contract codes: {error}", file=sys.stderr)
        return 2

    if failures:
        print("Native contract codes are out of sync with the backend manifest:", file=sys.stderr)
        for failure in failures:
            print(f"- {failure}", file=sys.stderr)
        return 1

    print("Native contract code families match the backend manifest.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
