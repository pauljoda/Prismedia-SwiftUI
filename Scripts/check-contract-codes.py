#!/usr/bin/env python3
"""Validate native contract-code declarations against Prismedia's code manifest.

The backend publishes this manifest from its canonical definitions and code registries. This
checker intentionally accepts either a URL or a saved manifest so this independent native
checkout never assumes a specific sibling checkout location. It validates the manually modeled
code families that the native client consumes outside playback.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import sys
from pathlib import Path
from urllib.error import URLError
from urllib.request import urlopen

from entity_kind_definition_codegen import OUTPUT as ENTITY_KIND_DEFINITIONS_PATH
from entity_kind_definition_codegen import render_manifest as render_entity_kind_definitions


REPOSITORY_ROOT = Path(__file__).resolve().parent.parent
DEFAULT_CODES_URL = "http://127.0.0.1:8008/api/_codegen/codes.json"
STATIC_CODE_PATTERN = re.compile(
    r'public static let \w+ = (?:EntityKind|Self)\(rawValue: "([^"]+)"\)'
)
ENUM_CASE_CODE_PATTERN = re.compile(r'case \w+ = "([^"]+)"')
FAMILIES = {
    "AutoIdentifySelectorKind": (
        "PrismediaShared/Features/Administration/Models/AutoIdentifySelectorKind.swift",
        ENUM_CASE_CODE_PATTERN,
    ),
    "BookFormat": ("PrismediaShared/Features/Reader/Models/BookFormat.swift", STATIC_CODE_PATTERN),
    "ReaderMode": ("PrismediaShared/Features/Reader/Models/ReaderMode.swift", STATIC_CODE_PATTERN),
    "ProgressUnit": ("PrismediaShared/Features/Reader/Models/ProgressUnit.swift", STATIC_CODE_PATTERN),
}
CAPABILITY_KINDS_PATH = "PrismediaShared/Domain/Entities/Detail/EntityCapabilityKind.swift"
PROPOSAL_KIND_PATH = "PrismediaShared/Domain/Entities/ProposalKind.swift"


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


def swift_codes(relative_path: str, pattern: re.Pattern[str]) -> set[str]:
    source = (REPOSITORY_ROOT / relative_path).read_text(encoding="utf-8")
    matches = pattern.findall(source)
    codes = set(matches)
    if not codes:
        raise ValueError(f"No contract codes found in {relative_path}")
    if len(codes) != len(matches):
        raise ValueError(f"Duplicate static raw-value codes found in {relative_path}")
    return codes


def compare(family: str, expected: set[str], actual: set[str]) -> list[str]:
    missing = sorted(expected - actual)
    extra = sorted(actual - expected)
    if not missing and not extra:
        return []
    details = []
    if missing:
        details.append(f"missing [{', '.join(missing)}]")
    if extra:
        details.append(f"extra [{', '.join(extra)}]")
    return [f"{family}: {'; '.join(details)}"]


def main() -> int:
    arguments = parse_arguments()
    try:
        manifest = load_manifest(arguments)
        manifest_enums = manifest["enums"]
        failures: list[str] = []

        expected_definitions = render_entity_kind_definitions(manifest)
        actual_definitions = ENTITY_KIND_DEFINITIONS_PATH.read_text(encoding="utf-8")
        if actual_definitions != expected_definitions:
            failures.append(
                "Generated EntityKind definitions differ; run "
                "`python3 Scripts/generate-entity-kind-definitions.py`"
            )

        for family, (relative_path, pattern) in FAMILIES.items():
            expected = {entry["code"] for entry in manifest_enums[family]}
            failures.extend(compare(family, expected, swift_codes(relative_path, pattern)))

        entity_kind_codes = {entry["code"] for entry in manifest_enums["EntityKind"]}
        proposal_kind_codes = {entry["code"] for entry in manifest_enums["ProposalKind"]}
        failures.extend(
            compare(
                "ProposalKind protocol-only values",
                proposal_kind_codes - entity_kind_codes,
                swift_codes(PROPOSAL_KIND_PATH, STATIC_CODE_PATTERN),
            )
        )

        failures.extend(
            compare(
                "CapabilityKinds",
                set(manifest["capabilityKinds"]),
                swift_codes(CAPABILITY_KINDS_PATH, STATIC_CODE_PATTERN),
            )
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
