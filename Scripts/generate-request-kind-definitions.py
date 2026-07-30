#!/usr/bin/env python3
"""Generate native request-kind definitions from Prismedia's backend code manifest."""

from __future__ import annotations

import argparse
import json
import os
from pathlib import Path
from urllib.request import urlopen

from request_kind_definition_codegen import OUTPUT, render_manifest


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--url", default=os.environ.get("PRISMEDIA_CODES_URL", "http://127.0.0.1:8008/api/_codegen/codes.json"))
    parser.add_argument("--check", action="store_true")
    arguments = parser.parse_args()
    with urlopen(arguments.url, timeout=10) as response:
        expected = render_manifest(json.load(response))
    current = OUTPUT.read_text(encoding="utf-8") if OUTPUT.exists() else None
    if arguments.check:
        if current == expected:
            print("Generated native request-kind definitions match the backend manifest.")
            return 0
        print("Generated native request-kind definitions are out of date.")
        return 1
    OUTPUT.write_text(expected, encoding="utf-8")
    print(f"Wrote {OUTPUT}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
