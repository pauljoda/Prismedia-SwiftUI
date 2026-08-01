#!/usr/bin/env python3
"""Generate native Entity capability decoding from the backend manifest."""

from __future__ import annotations

import argparse
import json
import os
from urllib.request import urlopen

from entity_capability_codegen import OUTPUT, render_manifest


DEFAULT_CODES_URL = "http://127.0.0.1:8008/api/_codegen/codes.json"


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--url",
        default=os.environ.get("PRISMEDIA_CODES_URL", DEFAULT_CODES_URL),
        help="Backend codes manifest URL (default: %(default)s)",
    )
    arguments = parser.parse_args()
    with urlopen(arguments.url, timeout=10) as response:
        manifest = json.load(response)
    OUTPUT.write_text(render_manifest(manifest), encoding="utf-8")
    print(f"Wrote {OUTPUT}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
