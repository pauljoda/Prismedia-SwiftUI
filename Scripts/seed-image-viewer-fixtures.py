#!/usr/bin/env python3
"""Seed or remove a temporary mixed-image library on a local Prismedia server.

Authentication is read from PRISMEDIA_TOKEN and is never persisted. The cleanup
path removes the fixture folder through Prismedia first so the follow-up gallery
scan can delete entities before the watched root is removed.
"""

import argparse
import json
import os
import shutil
import subprocess
import sys
import tempfile
import time
from datetime import datetime, timezone
from pathlib import Path
from urllib.error import HTTPError, URLError
from urllib.parse import urlencode
from urllib.request import Request, urlopen


DEFAULT_BASE_URL = "http://localhost:8008"
DEFAULT_STATE_PATH = Path("/tmp/prismedia-swiftui-image-fixture-state.json")
DEFAULT_FIXTURE_ROOT = (
    Path(__file__).resolve().parents[2]
    / "Prismedia"
    / "apps"
    / "web-svelte"
    / "static"
    / "fixtures"
)
FIXTURE_FILES = (
    ("poster-petethecat.jpg", "Portrait.jpg"),
    ("banner-petethecat.jpg", "Landscape.jpg"),
    ("lightbox/animated-loop.gif", "Animated GIF.gif"),
    ("lightbox/animated-loop.mp4", "Animated MP4.mp4"),
    ("lightbox/animated-loop.webm", "Animated WebM.webm"),
)
AUDIO_VIDEO_NAME = "Animated MP4 With Audio.mp4"


def api_json(base_url, token, method, path, payload=None):
    body = None if payload is None else json.dumps(payload).encode()
    headers = {"Authorization": f"Bearer {token}"}
    if body is not None:
        headers["Content-Type"] = "application/json"
    request = Request(
        f"{base_url.rstrip('/')}{path}",
        data=body,
        headers=headers,
        method=method,
    )
    try:
        with urlopen(request, timeout=15) as response:
            response_body = response.read()
    except HTTPError as error:
        detail = error.read().decode(errors="replace")
        raise RuntimeError(f"{method} {path} failed with HTTP {error.code}: {detail}") from error
    except URLError as error:
        raise RuntimeError(f"Could not reach {base_url}: {error.reason}") from error
    return json.loads(response_body) if response_body else None


def require_token():
    token = os.environ.get("PRISMEDIA_TOKEN", "").strip()
    if not token:
        raise RuntimeError("Set PRISMEDIA_TOKEN to an admin or library-creator bearer token.")
    return token


def validate_fixture_files(fixture_root):
    missing = [str(fixture_root / source) for source, _ in FIXTURE_FILES if not (fixture_root / source).is_file()]
    if missing:
        raise RuntimeError("Missing sibling web fixtures:\n" + "\n".join(missing))


def generate_audio_video_fixture(output_path):
    """Generate deterministic animated H.264/AAC media for mute-control validation."""
    ffmpeg = shutil.which("ffmpeg")
    if ffmpeg is None:
        raise RuntimeError(
            "ffmpeg is required to generate the audio-bearing image-video fixture."
        )
    command = [
        ffmpeg,
        "-hide_banner",
        "-loglevel",
        "error",
        "-y",
        "-f",
        "lavfi",
        "-i",
        "testsrc2=size=320x180:rate=24:duration=6",
        "-f",
        "lavfi",
        "-i",
        "sine=frequency=660:sample_rate=48000:duration=6",
        "-shortest",
        "-c:v",
        "libx264",
        "-pix_fmt",
        "yuv420p",
        "-movflags",
        "+faststart",
        "-c:a",
        "aac",
        "-b:a",
        "128k",
        str(output_path),
    ]
    result = subprocess.run(command, capture_output=True, text=True, check=False)
    if result.returncode != 0:
        detail = result.stderr.strip() or "ffmpeg exited without an error message"
        raise RuntimeError(f"Could not generate H.264/AAC fixture: {detail}")


def matching_image_count(base_url, token, tag):
    query = urlencode({"kind": "image", "query": tag, "limit": 20})
    response = api_json(base_url, token, "GET", f"/api/entities?{query}")
    return len(response.get("items", []))


def wait_for_image_count(base_url, token, tag, expected, timeout):
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        count = matching_image_count(base_url, token, tag)
        if count == expected:
            return
        time.sleep(1)
    raise RuntimeError(
        f"Timed out waiting for {expected} matching images. "
        "Keep the state file and run cleanup after the worker catches up."
    )


def write_state(state_path, state):
    state_path.parent.mkdir(parents=True, exist_ok=True)
    descriptor = os.open(state_path, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
    with os.fdopen(descriptor, "w") as output:
        json.dump(state, output, indent=2)
        output.write("\n")


def seed(args):
    token = require_token()
    state_path = args.state.expanduser().resolve()
    if state_path.exists():
        raise RuntimeError(f"State already exists at {state_path}; run cleanup first.")

    fixture_root = args.fixture_root.expanduser().resolve()
    validate_fixture_files(fixture_root)
    tag = f"SwiftUI Mixed Image Fixture {datetime.now(timezone.utc):%Y%m%d-%H%M%S}"
    root_path = Path(tempfile.mkdtemp(prefix="prismedia-swiftui-gallery-"))
    gallery_path = root_path / tag
    gallery_path.mkdir()
    created_root_id = None

    try:
        for source, destination in FIXTURE_FILES:
            shutil.copy2(fixture_root / source, gallery_path / f"{tag} {destination}")
        generate_audio_video_fixture(gallery_path / f"{tag} {AUDIO_VIDEO_NAME}")
        root = api_json(
            args.base,
            token,
            "POST",
            "/api/libraries",
            {
                "path": str(root_path),
                "label": tag,
                "enabled": True,
                "recursive": True,
                "scanVideos": False,
                "scanImages": True,
                "scanAudio": False,
                "scanBooks": False,
                "isNsfw": False,
                "autoIdentify": False,
            },
        )
        created_root_id = root["id"]
        state = {
            "baseURL": args.base.rstrip("/"),
            "rootID": root["id"],
            "rootPath": str(root_path),
            "galleryName": tag,
            "tag": tag,
        }
        write_state(state_path, state)
    except Exception:
        if created_root_id is not None:
            try:
                api_json(args.base, token, "DELETE", f"/api/libraries/{created_root_id}")
            except RuntimeError:
                pass
        shutil.rmtree(root_path, ignore_errors=True)
        raise

    fixture_count = len(FIXTURE_FILES) + 1
    wait_for_image_count(args.base, token, tag, fixture_count, args.timeout)
    print(f"Seeded {fixture_count} mixed-image fixtures in {tag}")
    print(f"Library root: {root['id']}")
    print(f"Cleanup: PRISMEDIA_TOKEN=... {sys.argv[0]} cleanup --state {state_path}")


def cleanup(args):
    token = require_token()
    state_path = args.state.expanduser().resolve()
    with state_path.open() as source:
        state = json.load(source)

    base_url = state["baseURL"]
    delete_query = urlencode(
        {"rootId": state["rootID"], "path": state["galleryName"]}
    )
    api_json(base_url, token, "DELETE", f"/api/files?{delete_query}")
    wait_for_image_count(base_url, token, state["tag"], 0, args.timeout)
    api_json(base_url, token, "DELETE", f"/api/libraries/{state['rootID']}")

    root_path = Path(state["rootPath"]).resolve()
    temp_root = Path(tempfile.gettempdir()).resolve()
    if root_path.parent != temp_root or not root_path.name.startswith("prismedia-swiftui-gallery-"):
        raise RuntimeError(f"Refusing to remove unexpected local path: {root_path}")
    shutil.rmtree(root_path, ignore_errors=True)
    state_path.unlink()
    print(f"Removed mixed-image fixture library {state['rootID']}")


def parser():
    result = argparse.ArgumentParser(description=__doc__)
    subcommands = result.add_subparsers(dest="command", required=True)

    seed_parser = subcommands.add_parser("seed", help="Create and scan a temporary Images library.")
    seed_parser.add_argument("--base", default=DEFAULT_BASE_URL)
    seed_parser.add_argument("--state", type=Path, default=DEFAULT_STATE_PATH)
    seed_parser.add_argument("--fixture-root", type=Path, default=DEFAULT_FIXTURE_ROOT)
    seed_parser.add_argument("--timeout", type=float, default=90)
    seed_parser.set_defaults(action=seed)

    cleanup_parser = subcommands.add_parser("cleanup", help="Remove the seeded media and library root.")
    cleanup_parser.add_argument("--state", type=Path, default=DEFAULT_STATE_PATH)
    cleanup_parser.add_argument("--timeout", type=float, default=90)
    cleanup_parser.set_defaults(action=cleanup)
    return result


def main():
    args = parser().parse_args()
    try:
        args.action(args)
    except (OSError, RuntimeError, KeyError, json.JSONDecodeError) as error:
        print(f"error: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
