#!/usr/bin/env python3
"""Generate native wire-code constants from Prismedia's backend code manifest."""

from __future__ import annotations

import argparse
import json
import os
import sys
from pathlib import Path
from urllib.error import URLError
from urllib.request import urlopen

from contract_code_codegen import OUTPUT, render_manifest


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
    parser.add_argument("--check", action="store_true", help="Fail instead of writing when output differs")
    return parser.parse_args()


def load_manifest(arguments: argparse.Namespace) -> dict:
    if arguments.manifest:
        return json.loads(arguments.manifest.read_text(encoding="utf-8"))
    with urlopen(arguments.url, timeout=10) as response:
        return json.load(response)


def main() -> int:
    arguments = parse_arguments()
    try:
        expected = render_manifest(load_manifest(arguments))
        current = OUTPUT.read_text(encoding="utf-8") if OUTPUT.exists() else None
    except (KeyError, OSError, URLError, ValueError, json.JSONDecodeError) as error:
        print(f"Unable to generate native contract codes: {error}", file=sys.stderr)
        return 2

    if arguments.check:
        if current == expected:
            print("Generated native contract codes match the backend manifest.")
            return 0
        print(
            "Generated native contract codes are out of date. "
            "Run `python3 Scripts/generate-contract-codes.py`.",
            file=sys.stderr,
        )
        return 1

    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT.write_text(expected, encoding="utf-8")
    print(f"Wrote {OUTPUT}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
