#!/usr/bin/env python3
"""Mock Prismedia server for UI smoke tests.

Implements just enough of the user-auth API contract for the shell test:
setup-status, login, me, logout, entity browsing, and deterministic mixed-image
source/preview media. Run on port 8899; credentials are test / test1234.
"""

import base64
import io
import json
import os
import random
import time
import wave
import zipfile
from http.server import BaseHTTPRequestHandler, HTTPServer, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import parse_qs, urlsplit

TOKEN = "mock-session-token"
MOCK_VIDEO_PATH = os.environ.get("PRISMEDIA_MOCK_VIDEO", "/tmp/prismedia-mock-video.mp4")
DETAIL_DELAY_SECONDS = float(os.environ.get("PRISMEDIA_MOCK_DETAIL_DELAY", "0"))
PLAYBACK_DELAY_SECONDS = float(os.environ.get("PRISMEDIA_MOCK_PLAYBACK_DELAY", "0.5"))
MOCK_PORT = int(os.environ.get("PRISMEDIA_MOCK_PORT", "8899"))
DEFAULT_IMAGE_FIXTURE_ROOT = (
    Path(__file__).resolve().parents[2]
    / "Prismedia"
    / "apps"
    / "web-svelte"
    / "static"
    / "fixtures"
)
IMAGE_FIXTURE_ROOT = Path(
    os.environ.get("PRISMEDIA_MOCK_IMAGE_FIXTURES", DEFAULT_IMAGE_FIXTURE_ROOT)
)

USER = {
    "id": "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa",
    "username": "test",
    "displayName": "Test User",
    "role": "admin",
    "allowSfw": True,
    "allowNsfw": True,
    "canCreateLibraries": True,
    "enabled": True,
    "lastLoginAt": "2026-07-07T18:30:00.1234567+00:00",
    "createdAt": "2026-07-06T20:00:00Z",
    "updatedAt": "2026-07-07T18:30:00.1234567Z",
}

ACCOUNT_SESSIONS = {
    "items": [
        {
            "id": "11111111-aaaa-bbbb-cccc-111111111111",
            "client": "Prismedia for iOS",
            "deviceName": "UI Test iPhone",
            "deviceId": "ui-test-device",
            "applicationVersion": "1.0",
            "createdAt": "2026-07-15T18:30:00Z",
            "lastSeenAt": "2026-07-16T18:30:00Z",
            "isCurrent": True,
        }
    ]
}

LIBRARY_ROOT = {
    "id": "22222222-aaaa-bbbb-cccc-222222222222",
    "path": "/media/movies",
    "label": "Fixture Movies",
    "enabled": True,
    "recursive": True,
    "scanVideos": True,
    "scanImages": False,
    "scanAudio": False,
    "scanBooks": False,
    "isNsfw": False,
    "lastScannedAt": "2026-07-16T18:00:00Z",
    "createdAt": "2026-07-01T12:00:00Z",
    "updatedAt": "2026-07-16T18:00:00Z",
    "autoIdentify": True,
    "createdByUserId": USER["id"],
    "accessUserIds": [],
}

MEMBER_USER = {
    "id": "33333333-aaaa-bbbb-cccc-333333333333",
    "username": "reader",
    "displayName": "Fixture Reader",
    "role": "member",
    "allowSfw": True,
    "allowNsfw": False,
    "canCreateLibraries": False,
    "enabled": True,
    "libraryRootIds": [LIBRARY_ROOT["id"]],
    "lastLoginAt": "2026-07-15T12:00:00Z",
    "createdAt": "2026-07-01T12:00:00Z",
    "updatedAt": "2026-07-15T12:00:00Z",
}

DATABASE_BACKUPS = {
    "backups": [
        {
            "id": "44444444-aaaa-bbbb-cccc-444444444444",
            "fileName": "manual-ui-fixture.sqlite",
            "backupPath": "/data/backups/manual-ui-fixture.sqlite",
            "status": "completed",
            "isManual": True,
            "sizeBytes": 10485760,
            "createdAt": "2026-07-16T17:00:00Z",
            "completedAt": "2026-07-16T17:00:02Z",
            "expiresAt": None,
            "error": None,
        }
    ],
    "nextAutomaticBackupAt": "2026-07-17T17:00:00Z",
    "backupDirectory": "/data/backups",
    "automaticRetentionDays": 7,
    "restoreConfirmationText": "DESTROY AND RESTORE",
}

METADATA_PROVIDER = {
    "id": "tmdb",
    "name": "The Movie Database",
    "version": "2.4.0",
    "installed": True,
    "enabled": True,
    "isNsfw": False,
    "supports": [
        {
            "entityKind": "movie",
            "actions": ["search", "lookup-id"],
            "identityNamespaces": ["tmdb"],
            "search": {
                "fields": [
                    {
                        "key": "query",
                        "label": "Title",
                        "type": "text",
                        "required": True,
                        "placeholder": "Arrival",
                        "help": "Search by the original release title.",
                    },
                    {
                        "key": "year",
                        "label": "Year",
                        "type": "year",
                        "required": False,
                        "placeholder": "2016",
                        "help": "Optional release year.",
                    },
                ]
            },
            "identityUrls": None,
        }
    ],
    "auth": [],
    "missingAuthKeys": [],
    "updateAvailable": False,
    "availableVersion": None,
}

IDENTIFY_PROPOSAL = {
    "proposalId": "tmdb-arrival",
    "provider": "TMDB",
    "targetKind": "movie",
    "confidence": 0.96,
    "matchReason": "Title and year match",
    "patch": {
        "title": "Arrival (2016)",
        "description": "A linguist works with the military to communicate with alien lifeforms.",
        "externalIds": {"tmdb": "329865"},
        "urls": [],
        "tags": ["Science Fiction", "Drama"],
        "studio": "Paramount Pictures",
        "credits": [],
        "dates": {"release": "2016-11-11"},
        "stats": {},
        "positions": {},
        "classification": "PG-13",
        "rating": 8,
        "flags": None,
    },
    "images": [],
    "children": [],
    "candidates": [],
    "targetEntityId": None,
    "relationships": [],
}

IDENTIFY_QUEUE = [
    {
        "id": "b1000000-0000-0000-0000-000000000001",
        "entityId": "b2000000-0000-0000-0000-000000000001",
        "entityKind": "movie",
        "title": "Arrival",
        "isNsfw": False,
        "state": "proposal",
        "provider": "TMDB",
        "action": "identify",
        "query": None,
        "candidates": [],
        "proposal": IDENTIFY_PROPOSAL,
        "error": None,
        "cascadeRunning": False,
        "createdAt": "2026-07-12T12:00:00Z",
        "updatedAt": "2026-07-12T12:00:00Z",
        "completedAt": None,
    }
]

REQUEST_DOWNLOADS = [
    {
        "acquisitionId": "11111111-1111-1111-1111-111111111111",
        "entityId": "33333333-3333-3333-3333-333333333333",
        "kind": "movie",
        "title": "Arrival",
        "status": "downloading",
        "progress": 0.64,
        "updatedAt": "2026-07-12T18:00:00Z",
        "totalSizeBytes": 2800000000,
        "downloadSpeedBytesPerSecond": 8500000,
        "etaSeconds": 780,
        "clientName": "qBittorrent",
    }
]


def thumb(id_suffix, kind, title):
    return {
        "id": f"{id_suffix * 8}-{id_suffix * 4}-{id_suffix * 4}-{id_suffix * 4}-{id_suffix * 12}",
        "kind": kind,
        "title": title,
        "parentEntityId": None,
        "parentKind": None,
        "sortOrder": None,
        "coverUrl": None,
        "coverThumbUrl": None,
        "hoverKind": "none",
        "hoverUrl": None,
        "hoverImages": [],
        "meta": [
            {"icon": "duration", "label": "01:45"},
            {"icon": "resolution", "label": "1440p"},
        ],
        "rating": 4,
        "isFavorite": False,
        "isNsfw": False,
        "isOrganized": True,
        "progress": None,
        "playCount": 0,
        "genres": [],
        "referenceCounts": [],
    }


LONG_MOVIES = []
for index in range(1, 21):
    movie = thumb("9", "movie", f"Mock Long Movie {index:02d}")
    movie["id"] = f"90000000-0000-0000-0000-{index:012d}"
    LONG_MOVIES.append(movie)


IMAGE_GALLERY_ID = "66666666-6666-6666-6666-666666666666"
STILL_IMAGE_ID = "99999999-9999-9999-9999-999999999999"
ANIMATED_GIF_IMAGE_ID = "a1000000-0000-0000-0000-000000000001"
MP4_IMAGE_ID = "a2000000-0000-0000-0000-000000000002"
WEBM_IMAGE_ID = "a3000000-0000-0000-0000-000000000003"
PUBLIC_WEBM_PREVIEW_PATH = "/assets/mock-fixtures/preview.mp4"
PUBLIC_POSTER_PATH = "/assets/mock-fixtures/poster.jpg"
PUBLIC_BANNER_PATH = "/assets/mock-fixtures/banner.jpg"
PUBLIC_TRICKPLAY_PATH = "/assets/mock-fixtures/episode-trickplay.vtt"


def gallery_image(entity_id, title, sort_order, cover_entity_id):
    image = thumb("9", "image", title)
    image.update(
        {
            "id": entity_id,
            "parentEntityId": IMAGE_GALLERY_ID,
            "parentKind": "gallery",
            "sortOrder": sort_order,
            "coverUrl": f"/api/entities/{cover_entity_id}/files/source",
            "coverThumbUrl": f"/api/entities/{cover_entity_id}/files/source",
            "meta": [],
        }
    )
    return image


STILL_IMAGE = gallery_image(STILL_IMAGE_ID, "Mock Still Image", 0, STILL_IMAGE_ID)
ANIMATED_GIF_IMAGE = gallery_image(
    ANIMATED_GIF_IMAGE_ID,
    "Mock Animated GIF",
    1,
    ANIMATED_GIF_IMAGE_ID,
)
MP4_IMAGE = gallery_image(MP4_IMAGE_ID, "Mock MP4 Image", 2, STILL_IMAGE_ID)
WEBM_IMAGE = gallery_image(WEBM_IMAGE_ID, "Mock WebM Image", 3, STILL_IMAGE_ID)
MIXED_IMAGE_ENTITIES = [STILL_IMAGE, ANIMATED_GIF_IMAGE, MP4_IMAGE, WEBM_IMAGE]

IMAGE_MEDIA_FILES = {
    STILL_IMAGE_ID: {
        "source": ("poster-petethecat.jpg", "image/jpeg", "still.jpg"),
    },
    ANIMATED_GIF_IMAGE_ID: {
        "source": ("lightbox/animated-loop.gif", "image/gif", "animated-loop.gif"),
    },
    MP4_IMAGE_ID: {
        "source": ("lightbox/animated-loop.mp4", "video/mp4", "animated-loop.mp4"),
        "preview": ("lightbox/animated-loop.mp4", "video/mp4", "preview.mp4"),
    },
    WEBM_IMAGE_ID: {
        "source": ("lightbox/animated-loop.webm", "video/webm", "animated-loop.webm"),
        "preview": ("lightbox/animated-loop.mp4", "video/mp4", "preview.mp4"),
    },
}


ENTITIES = LONG_MOVIES + [
    thumb("1", "video", "Mock Video Alpha"),
    thumb("2", "video", "Mock Video Beta"),
    thumb("3", "movie", "Mock Movie One"),
    thumb("4", "movie", "Mock Movie Two"),
    thumb("5", "video-series", "Mock Series"),
    thumb("6", "gallery", "Mock Gallery"),
    thumb("7", "person", "Mock Person"),
    thumb("8", "book", "Mock Book"),
    STILL_IMAGE,
    thumb("a", "music-artist", "Mock Artist"),
    thumb("b", "audio-library", "Mock Album"),
    thumb("c", "audio-track", "Mock Track"),
    thumb("d", "book-author", "Mock Author"),
    thumb("e", "studio", "Mock Studio"),
    thumb("f", "tag", "Mock Tag"),
    ANIMATED_GIF_IMAGE,
    MP4_IMAGE,
    WEBM_IMAGE,
    thumb("0", "collection", "Mock Collection"),
]
EPUB_BOOK = thumb("e", "book", "Mock EPUB Novel")
EPUB_BOOK["id"] = "edededed-eded-eded-eded-edededededed"
PDF_BOOK = thumb("f", "book", "Mock PDF Document")
PDF_BOOK["id"] = "dfdfdfdf-dfdf-dfdf-dfdf-dfdfdfdfdfdf"
AUDIOBOOK = thumb("7", "book", "Mock Audiobook")
AUDIOBOOK["id"] = "abababab-abab-abab-abab-abababababab"
ENTITIES.insert(-1, EPUB_BOOK)
ENTITIES.insert(-1, PDF_BOOK)
ENTITIES.insert(-1, AUDIOBOOK)
VIDEO_ALPHA_INDEX = len(LONG_MOVIES)
VIDEO_BETA_INDEX = VIDEO_ALPHA_INDEX + 1
MOVIE_ONE_INDEX = VIDEO_ALPHA_INDEX + 2
MOVIE_TWO_INDEX = VIDEO_ALPHA_INDEX + 3
SERIES_INDEX = VIDEO_ALPHA_INDEX + 4
PERSON_INDEX = VIDEO_ALPHA_INDEX + 6
BOOK_INDEX = VIDEO_ALPHA_INDEX + 7
ARTIST_INDEX = VIDEO_ALPHA_INDEX + 9
COLLECTION_INDEX = len(ENTITIES) - 1

COLLECTION_ID = ENTITIES[COLLECTION_INDEX]["id"]
COLLECTION_MEMBERS = [
    ENTITIES[MOVIE_ONE_INDEX],
    ENTITIES[BOOK_INDEX],
    ENTITIES[ARTIST_INDEX],
]

BOOK_ID = ENTITIES[BOOK_INDEX]["id"]
EPUB_BOOK_ID = EPUB_BOOK["id"]
PDF_BOOK_ID = PDF_BOOK["id"]
AUDIOBOOK_ID = AUDIOBOOK["id"]
AUDIOBOOK_PARTS = [
    {
        **thumb("2", "audio-track", "Part Two"),
        "id": "b2000000-0000-0000-0000-000000000002",
        "parentEntityId": AUDIOBOOK_ID,
        "parentKind": "book",
        "sortOrder": 1,
        "meta": [{"icon": "duration", "label": "01:20"}],
        "duration": "00:01:20",
    },
    {
        **thumb("1", "audio-track", "Part One"),
        "id": "b1000000-0000-0000-0000-000000000001",
        "parentEntityId": AUDIOBOOK_ID,
        "parentKind": "book",
        "sortOrder": 0,
        "meta": [{"icon": "duration", "label": "01:40"}],
        "duration": "00:01:40",
    },
    {
        **thumb("3", "audio-track", "Part Three"),
        "id": "b3000000-0000-0000-0000-000000000003",
        "parentEntityId": AUDIOBOOK_ID,
        "parentKind": "book",
        "sortOrder": 2,
        "meta": [{"icon": "duration", "label": "02:00"}],
        "duration": "00:02:00",
    },
]
AUDIOBOOK_PLAYBACK = {
    "playCount": 0,
    "skipCount": 0,
    "playDurationSeconds": 0,
    "resumeSeconds": 145,
    "lastPlayedAt": "2026-07-11T00:00:00Z",
    "completedAt": None,
}
CHAPTER_ID = "81818181-8181-8181-8181-818181818181"
PAGE_IDS = [
    "82828282-8282-8282-8282-828282828281",
    "82828282-8282-8282-8282-828282828282",
    "82828282-8282-8282-8282-828282828283",
]
BOOK_PROGRESS = {
    "currentEntityId": CHAPTER_ID,
    "unit": "page",
    "index": 0,
    "total": len(PAGE_IDS),
    "mode": "paged",
    "completedAt": None,
    "updatedAt": "2026-07-11T00:00:00Z",
    "workIndex": 0,
    "workTotal": len(PAGE_IDS),
    "location": None,
}
EPUB_BOOK_PROGRESS = {
    "currentEntityId": EPUB_BOOK_ID,
    "unit": "cfi",
    "index": 2500,
    "total": 10000,
    "mode": "paged",
    "completedAt": None,
    "updatedAt": "2026-07-11T00:00:00Z",
    "workIndex": 2500,
    "workTotal": 10000,
    "location": None,
}
PDF_BOOK_PROGRESS = {
    "currentEntityId": PDF_BOOK_ID,
    "unit": "page",
    "index": 0,
    "total": 2,
    "mode": "scrolled",
    "completedAt": None,
    "updatedAt": "2026-07-11T00:00:00Z",
    "workIndex": 0,
    "workTotal": 2,
    "location": None,
}
BOOK_PROGRESS_BY_ID = {
    BOOK_ID: BOOK_PROGRESS,
    EPUB_BOOK_ID: EPUB_BOOK_PROGRESS,
    PDF_BOOK_ID: PDF_BOOK_PROGRESS,
}
MOCK_PAGE_PNG = base64.b64decode(
    "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVQIHWP4z8DwHwAFgAI/ScL+WQAAAABJRU5ErkJggg=="
)
MOCK_ASS_SUBTITLE = """[Script Info]
ScriptType: v4.00+
PlayResX: 1920
PlayResY: 1080

[V4+ Styles]
Format: Name, Fontname, Fontsize, PrimaryColour, SecondaryColour, OutlineColour, BackColour, Bold, Italic, Underline, StrikeOut, ScaleX, ScaleY, Spacing, Angle, BorderStyle, Outline, Shadow, Alignment, MarginL, MarginR, MarginV, Encoding
Style: Default,Arial,54,&H00FFFFFF,&H000000FF,&H00000000,&H64000000,0,0,0,0,100,100,0,0,1,3,1,2,60,60,70,1

[Events]
Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text
Dialogue: 0,0:00:00.00,0:01:00.00,Default,,0,0,0,,Styled English ASS fixture
"""
MOCK_NORMALIZED_ASS_SUBTITLE = """WEBVTT

00:00:00.000 --> 00:01:00.000
Styled English ASS fixture
"""
MOCK_VTT_MARKUP_SUBTITLE = """WEBVTT

00:00:00.000 --> 00:01:00.000
This is <i>italic</i>, <b>bold</b>, and <u>underlined</u>.
"""


def build_mock_epub():
    """Build a small EPUB 3 fixture with navigation, images, and searchable text."""
    container = io.BytesIO()
    with zipfile.ZipFile(container, "w") as archive:
        archive.writestr("mimetype", "application/epub+zip", compress_type=zipfile.ZIP_STORED)
        archive.writestr(
            "META-INF/container.xml",
            """<?xml version="1.0" encoding="UTF-8"?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
  <rootfiles><rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/></rootfiles>
</container>""",
        )
        archive.writestr(
            "OEBPS/content.opf",
            """<?xml version="1.0" encoding="UTF-8"?>
<package version="3.0" unique-identifier="book-id" xmlns="http://www.idpf.org/2007/opf">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:identifier id="book-id">prismedia-mock-epub</dc:identifier>
    <dc:title>Mock EPUB Novel</dc:title><dc:language>en</dc:language>
  </metadata>
  <manifest>
    <item id="nav" href="nav.xhtml" media-type="application/xhtml+xml" properties="nav"/>
    <item id="chapter-1" href="chapter-1.xhtml" media-type="application/xhtml+xml"/>
    <item id="chapter-2" href="chapter-2.xhtml" media-type="application/xhtml+xml"/>
  </manifest>
  <spine><itemref idref="chapter-1"/><itemref idref="chapter-2"/></spine>
</package>""",
        )
        archive.writestr(
            "OEBPS/nav.xhtml",
            """<?xml version="1.0" encoding="UTF-8"?>
<html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops">
  <head><title>Contents</title></head><body><nav epub:type="toc"><h1>Contents</h1><ol>
    <li><a href="chapter-1.xhtml">The First Signal</a></li>
    <li><a href="chapter-2.xhtml">The Second Signal</a></li>
  </ol></nav></body>
</html>""",
        )
        archive.writestr(
            "OEBPS/chapter-1.xhtml",
            """<?xml version="1.0" encoding="UTF-8"?>
<html xmlns="http://www.w3.org/1999/xhtml"><head><title>The First Signal</title></head>
<body><h1>The First Signal</h1><p>The lighthouse answered from beyond the quiet sea.</p></body></html>""",
        )
        archive.writestr(
            "OEBPS/chapter-2.xhtml",
            """<?xml version="1.0" encoding="UTF-8"?>
<html xmlns="http://www.w3.org/1999/xhtml"><head><title>The Second Signal</title></head>
<body><h1>The Second Signal</h1><p>A native reader keeps every word close at hand.</p></body></html>""",
        )
    return container.getvalue()


def build_mock_pdf():
    """Build a two-page searchable PDF fixture with a native outline."""
    first_stream = b"BT /F1 24 Tf 72 700 Td (First PDF chapter searchable lighthouse) Tj ET"
    second_stream = b"BT /F1 24 Tf 72 700 Td (Second PDF chapter native reader) Tj ET"
    objects = [
        b"<< /Type /Catalog /Pages 2 0 R /Outlines 8 0 R /PageMode /UseOutlines >>",
        b"<< /Type /Pages /Kids [4 0 R 6 0 R] /Count 2 >>",
        b"<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>",
        b"<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] /Resources << /Font << /F1 3 0 R >> >> /Contents 5 0 R >>",
        b"<< /Length %d >>\nstream\n%s\nendstream" % (len(first_stream), first_stream),
        b"<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] /Resources << /Font << /F1 3 0 R >> >> /Contents 7 0 R >>",
        b"<< /Length %d >>\nstream\n%s\nendstream" % (len(second_stream), second_stream),
        b"<< /Type /Outlines /First 9 0 R /Last 10 0 R /Count 2 >>",
        b"<< /Title (The First Signal) /Parent 8 0 R /Dest [4 0 R /Fit] /Next 10 0 R >>",
        b"<< /Title (The Second Signal) /Parent 8 0 R /Dest [6 0 R /Fit] /Prev 9 0 R >>",
    ]
    document = bytearray(b"%PDF-1.4\n%\xe2\xe3\xcf\xd3\n")
    offsets = [0]
    for number, contents in enumerate(objects, start=1):
        offsets.append(len(document))
        document.extend(f"{number} 0 obj\n".encode())
        document.extend(contents)
        document.extend(b"\nendobj\n")
    xref_offset = len(document)
    document.extend(f"xref\n0 {len(objects) + 1}\n".encode())
    document.extend(b"0000000000 65535 f \n")
    for offset in offsets[1:]:
        document.extend(f"{offset:010d} 00000 n \n".encode())
    document.extend(
        f"trailer\n<< /Size {len(objects) + 1} /Root 1 0 R >>\nstartxref\n{xref_offset}\n%%EOF\n".encode()
    )
    return bytes(document)


def build_mock_audio():
    """Build a small, seekable 50-second mono WAV for native AVPlayer smoke tests."""
    container = io.BytesIO()
    with wave.open(container, "wb") as audio:
        audio.setnchannels(1)
        audio.setsampwidth(1)
        audio.setframerate(8000)
        audio.writeframes(b"\x80" * (50 * 8000))
    return container.getvalue()


MOCK_EPUB = build_mock_epub()
MOCK_PDF = build_mock_pdf()
MOCK_AUDIO = build_mock_audio()

ENTITIES[VIDEO_ALPHA_INDEX]["progress"] = 0.25
ENTITIES[VIDEO_ALPHA_INDEX]["resumeSeconds"] = 15
ENTITIES[MOVIE_ONE_INDEX]["rating"] = None
ENTITIES[VIDEO_ALPHA_INDEX]["parentEntityId"] = ENTITIES[MOVIE_ONE_INDEX]["id"]
ENTITIES[VIDEO_ALPHA_INDEX]["parentKind"] = "movie"
ENTITIES[VIDEO_ALPHA_INDEX]["sortOrder"] = 0
ENTITIES[VIDEO_BETA_INDEX]["parentEntityId"] = ENTITIES[MOVIE_ONE_INDEX]["id"]
ENTITIES[VIDEO_BETA_INDEX]["parentKind"] = "movie"
ENTITIES[VIDEO_BETA_INDEX]["sortOrder"] = 1
ENTITIES[MOVIE_ONE_INDEX]["progress"] = 0.25
ENTITIES[MOVIE_ONE_INDEX]["resumeSeconds"] = 15
ENTITIES[MOVIE_TWO_INDEX]["playCount"] = 1

for artwork_entity in (
    ENTITIES[VIDEO_ALPHA_INDEX],
    ENTITIES[VIDEO_BETA_INDEX],
    ENTITIES[MOVIE_ONE_INDEX],
    ENTITIES[MOVIE_TWO_INDEX],
):
    artwork_entity["coverUrl"] = PUBLIC_POSTER_PATH
    artwork_entity["coverThumbUrl"] = artwork_entity["coverUrl"]

ENTITIES[MOVIE_ONE_INDEX]["hoverImages"] = [
    {
        "entityId": ENTITIES[MOVIE_ONE_INDEX]["id"],
        "title": "Mock Movie One Backdrop",
        "path": PUBLIC_BANNER_PATH,
    }
]

SEASONS = [
    thumb("1", "video-season", "Season 1"),
    thumb("2", "video-season", "Season 2"),
]
SEASONS[0]["id"] = "10101010-1010-1010-1010-101010101010"
SEASONS[1]["id"] = "20202020-2020-2020-2020-202020202020"
for season_index, season in enumerate(SEASONS, start=1):
    season.update(
        {
            "parentEntityId": ENTITIES[SERIES_INDEX]["id"],
            "parentKind": "video-series",
            "sortOrder": season_index,
            "coverUrl": f"{PUBLIC_BANNER_PATH}?season={season_index}",
            "coverThumbUrl": f"{PUBLIC_BANNER_PATH}?season={season_index}",
        }
    )

ENTITIES[SERIES_INDEX].update(
    {
        "coverUrl": PUBLIC_POSTER_PATH,
        "coverThumbUrl": PUBLIC_POSTER_PATH,
        "hoverImages": [
            {
                "entityId": ENTITIES[SERIES_INDEX]["id"],
                "title": "Mock Series Backdrop",
                "path": PUBLIC_BANNER_PATH,
            }
        ],
    }
)


def episode_thumbnail(index, season_index=0):
    title = "Mock Episode One" if index == 1 and season_index == 0 else f"Mock Episode {index:02d}"
    episode = thumb("1", "video", title)
    short_summary = f"Episode {index} changes the focused description immediately."
    long_summary = (
        f"Episode {index} follows the crew through a long, atmospheric mystery. "
        "The full synopsis deliberately continues with enough detail to verify that the "
        "collapsed copy stays within three lines and that More presents every sentence "
        "without changing focus or disturbing the full-screen backdrop."
    )
    episode.update(
        {
            "id": f"12{season_index + 1:02d}{index:02d}00-1212-1212-1212-{index:012d}",
            "summary": long_summary if index % 2 == 1 else short_summary,
            "parentEntityId": SEASONS[season_index]["id"],
            "parentKind": "video-season",
            "sortOrder": index,
            "coverUrl": f"{PUBLIC_BANNER_PATH}?episode={season_index + 1}-{index}",
            "coverThumbUrl": f"{PUBLIC_BANNER_PATH}?episode={season_index + 1}-{index}",
            "hoverKind": "trickplay",
            "hoverUrl": f"{PUBLIC_TRICKPLAY_PATH}?episode={season_index + 1}-{index}",
            "hasSourceMedia": True,
        }
    )
    return episode


SEASON_EPISODES = {
    SEASONS[0]["id"]: [episode_thumbnail(index) for index in range(1, 21)],
    SEASONS[1]["id"]: [episode_thumbnail(index, season_index=1) for index in range(1, 7)],
}
EPISODE = SEASON_EPISODES[SEASONS[0]["id"]][0]
ENTITIES.append(EPISODE)
DETAIL_ENTITIES = ENTITIES + SEASONS + [
    episode
    for episodes in SEASON_EPISODES.values()
    for episode in episodes
]


def build_mock_trickplay_playlist():
    cues = []
    crops = [
        "0,0,800,449",
        "800,0,800,449",
        "0,449,800,449",
        "800,449,800,449",
    ]
    for index in range(10):
        start = index * 10
        end = start + 10
        crop = crops[index % len(crops)]
        cues.append(
            f"00:{start // 60:02d}:{start % 60:02d}.000 --> "
            f"00:{end // 60:02d}:{end % 60:02d}.000\n"
            f"{PUBLIC_BANNER_PATH}#xywh={crop}"
        )
    return "WEBVTT\n\n" + "\n\n".join(cues) + "\n"


MOCK_TRICKPLAY_PLAYLIST = build_mock_trickplay_playlist()


def build_entity_list_response(path, raw_query):
    """Build the list-shaped response used by browse and Search UI tests."""
    parameters = parse_qs(raw_query, keep_blank_values=True)
    indexed_items = list(enumerate(ENTITIES))
    if path == "/api/collections":
        indexed_items = [pair for pair in indexed_items if pair[1]["kind"] == "collection"]
    indexed_items = _filter_entities(indexed_items, parameters)
    indexed_items = _sort_entities(indexed_items, parameters)

    total_count = len(indexed_items)
    limit = _entity_limit(parameters, total_count)
    items = [item for _, item in indexed_items[:limit]]
    return {"items": items, "nextCursor": None, "totalCount": total_count}


def build_collection_items_response(collection_id):
    """Build the ordered, mixed-media membership document used by detail UI tests."""
    if collection_id != COLLECTION_ID:
        return None
    return {"items": [{"entity": item} for item in COLLECTION_MEMBERS]}


def image_file_capability_items(entity_id):
    """Project mock media descriptors into the production files capability shape."""
    descriptors = IMAGE_MEDIA_FILES.get(entity_id, {})
    return [
        {
            "role": role,
            "path": (
                PUBLIC_WEBM_PREVIEW_PATH
                if entity_id == WEBM_IMAGE_ID and role == "preview"
                else f"/mock-fixtures/{stored_name}"
            ),
            "mimeType": mime_type,
        }
        for role, (_, mime_type, stored_name) in descriptors.items()
    ]


def load_image_media(entity_id, role):
    """Load one mock image role from the sibling web fixture catalog."""
    descriptor = IMAGE_MEDIA_FILES.get(entity_id, {}).get(role)
    if descriptor is None:
        return None
    relative_path, mime_type, _ = descriptor
    fixture_path = IMAGE_FIXTURE_ROOT / relative_path
    try:
        return fixture_path.read_bytes(), mime_type
    except OSError:
        return None


def build_entity_detail_response(entity_id):
    """Build the generic EntityCard document returned by GET /api/entities/{id}."""
    audiobook_part = next((item for item in AUDIOBOOK_PARTS if item["id"] == entity_id), None)
    if audiobook_part is not None:
        return {
            "id": audiobook_part["id"],
            "kind": "audio-track",
            "title": audiobook_part["title"],
            "parentEntityId": AUDIOBOOK_ID,
            "sortOrder": audiobook_part["sortOrder"],
            "hasSourceMedia": True,
            "capabilities": [
                {
                    "kind": "technical",
                    "duration": audiobook_part["duration"],
                    "codec": "pcm_u8",
                    "container": "wav",
                }
            ],
            "childrenByKind": [],
            "relationships": [],
        }
    entity = next((item for item in DETAIL_ENTITIES if item["id"] == entity_id), None)
    if entity is None:
        if entity_id == CHAPTER_ID:
            return build_chapter_detail_response()
        return None

    child_groups = []
    if entity["kind"] == "movie":
        child_groups.append(
            {
                "kind": "video",
                "label": "Videos",
                "entities": [ENTITIES[VIDEO_ALPHA_INDEX], ENTITIES[VIDEO_BETA_INDEX]],
            }
        )
    if entity["kind"] == "video-series":
        child_groups.append(
            {
                "kind": "video-season",
                "label": "Seasons",
                "entities": SEASONS,
            }
        )
    if entity["kind"] == "video-season":
        child_groups.append(
            {
                "kind": "video",
                "label": "Episodes",
                "entities": SEASON_EPISODES.get(entity["id"], []),
            }
        )
    if entity["kind"] == "gallery" and entity["id"] == IMAGE_GALLERY_ID:
        child_groups.append(
            {
                "kind": "image",
                "label": "Images",
                "entities": MIXED_IMAGE_ENTITIES,
            }
        )
    if entity["kind"] == "book" and entity["id"] == BOOK_ID:
        child_groups.append(
            {
                "kind": "book-chapter",
                "label": "Chapters",
                "entities": [book_child(CHAPTER_ID, "book-chapter", "Chapter One", BOOK_ID, 0)],
            }
        )
    if entity["kind"] == "book" and entity["id"] == AUDIOBOOK_ID:
        child_groups.append(
            {
                "kind": "audio-track",
                "label": "Audio Tracks",
                "entities": AUDIOBOOK_PARTS,
            }
        )

    image_items = []
    image_kinds = ["cover"]
    if entity["id"] == ENTITIES[MOVIE_ONE_INDEX]["id"]:
        image_items.append(
            {
                "kind": "backdrop",
                "path": PUBLIC_BANNER_PATH,
                "mimeType": "image/jpeg",
            }
        )
        image_kinds.append("backdrop")

    capabilities = [
        {
            "kind": "description",
            "value": f"Native detail fixture for {entity['title']}.",
        },
        {
            "kind": "images",
            "supportedKinds": image_kinds,
            "items": image_items,
            "thumbnailUrl": entity["coverThumbUrl"],
            "thumbnail2xUrl": None,
            "coverUrl": entity["coverUrl"],
        },
        {"kind": "rating", "value": entity["rating"]},
        {
            "kind": "flags",
            "isFavorite": entity["isFavorite"],
            "isNsfw": entity["isNsfw"],
            "isOrganized": entity["isOrganized"],
            "isWanted": False,
        },
    ]
    if entity["kind"] == "video":
        capabilities.append(
            {
                "kind": "playback",
                "playCount": 0,
                "skipCount": 0,
                "playDurationSeconds": 15,
                "resumeSeconds": entity.get("resumeSeconds") or 15,
                "lastPlayedAt": "2026-07-11T00:00:00Z",
                "completedAt": None,
            }
        )
        capabilities.append(
            {
                "kind": "subtitles",
                "items": [
                    {
                        "id": "mock-ass-en",
                        "language": "en",
                        "label": "English Styled",
                        "format": "ass",
                        "source": "embedded",
                        "storagePath": "subtitles/mock-ass-en.vtt",
                        "sourceFormat": "ass",
                        "sourcePath": "subtitles/mock-ass-en.ass",
                        "isDefault": False,
                    },
                    {
                        "id": "mock-vtt-en",
                        "language": "en",
                        "label": "English WebVTT Markup",
                        "format": "vtt",
                        "source": "sidecar",
                        "storagePath": "subtitles/mock-vtt-en.vtt",
                        "sourceFormat": "vtt",
                        "sourcePath": None,
                        "isDefault": False,
                    },
                ],
            }
        )
        capabilities.append(
            {
                "kind": "files",
                "items": [
                    {
                        "role": "trickplay",
                        "path": PUBLIC_TRICKPLAY_PATH,
                        "mimeType": "text/vtt",
                    }
                ],
            }
        )
    if entity["kind"] == "image":
        capabilities.append(
            {
                "kind": "files",
                "items": image_file_capability_items(entity["id"]),
            }
        )
    if entity["kind"] == "book" and entity["id"] in BOOK_PROGRESS_BY_ID:
        capabilities.append({"kind": "progress", **BOOK_PROGRESS_BY_ID[entity["id"]]})
    if entity["id"] == AUDIOBOOK_ID:
        capabilities.append({"kind": "playback", **AUDIOBOOK_PLAYBACK})

    relationships = []
    if entity["kind"] == "movie":
        relationships.append(
            {
                "kind": "person",
                "label": "Cast",
                "entities": [ENTITIES[PERSON_INDEX]],
            }
        )

    response = {
        "id": entity["id"],
        "kind": entity["kind"],
        "title": entity["title"],
        "parentEntityId": entity["parentEntityId"],
        "sortOrder": entity["sortOrder"],
        "hasSourceMedia": entity["kind"] in ("video", "image")
        or entity["id"] in (EPUB_BOOK_ID, PDF_BOOK_ID, AUDIOBOOK_ID),
        "capabilities": capabilities,
        "childrenByKind": child_groups,
        "relationships": relationships,
    }
    return response


def build_book_detail_response(entity_id):
    response = build_entity_detail_response(entity_id)
    if response is None or response["kind"] != "book":
        return None
    if entity_id == BOOK_ID:
        response.update({"bookType": "comic", "format": "image-archive", "coverPageId": PAGE_IDS[0]})
    elif entity_id == EPUB_BOOK_ID:
        response.update({"bookType": "novel", "format": "epub", "coverPageId": None})
    elif entity_id == AUDIOBOOK_ID:
        response.update({"bookType": "novel", "format": "audio", "coverPageId": None})
    else:
        response.update({"bookType": "document", "format": "pdf", "coverPageId": None})
    return response


def build_playback_info_response(audio_stream_index):
    """Build playback negotiation with a deterministic selectable audio pair."""
    selected_index = audio_stream_index if audio_stream_index in (1, 2) else 1
    is_explicit_selection = audio_stream_index is not None
    return {
        "PlaySessionId": "mock-play-session",
        "MediaSources": [
            {
                "Id": "mock-source",
                "Path": MOCK_VIDEO_PATH,
                "Protocol": "File",
                "Container": "mp4",
                "RunTimeTicks": 300_000_000,
                "SupportsDirectPlay": not is_explicit_selection,
                "SupportsDirectStream": True,
                "SupportsTranscoding": is_explicit_selection,
                "TranscodingUrl": (
                    f"/Videos/mock/stream?AudioStreamIndex={selected_index}"
                    if is_explicit_selection
                    else None
                ),
                "MediaStreams": [
                    {"Index": 0, "Type": "Video", "Codec": "h264", "Width": 1280, "Height": 720},
                    {
                        "Index": 1,
                        "Type": "Audio",
                        "Codec": "aac",
                        "Channels": 2,
                        "Language": "eng",
                        "DisplayTitle": "Main",
                        "IsDefault": selected_index == 1,
                    },
                    {
                        "Index": 2,
                        "Type": "Audio",
                        "Codec": "aac",
                        "Channels": 2,
                        "Language": "eng",
                        "DisplayTitle": "Commentary",
                        "IsDefault": selected_index == 2,
                    },
                ],
                "TranscodingInfo": (
                    {"IsVideoDirect": True, "VideoCodec": "h264", "AudioCodec": "aac"}
                    if is_explicit_selection
                    else None
                ),
            }
        ],
    }


def book_child(entity_id, kind, title, parent_id, sort_order):
    item = thumb("1", kind, title)
    item.update(
        {
            "id": entity_id,
            "parentEntityId": parent_id,
            "parentKind": "book" if kind == "book-chapter" else "book-chapter",
            "sortOrder": sort_order,
            "meta": [],
            "rating": None,
        }
    )
    return item


def build_chapter_detail_response():
    return {
        "id": CHAPTER_ID,
        "kind": "book-chapter",
        "title": "Chapter One",
        "parentEntityId": BOOK_ID,
        "sortOrder": 0,
        "hasSourceMedia": False,
        "capabilities": [],
        "childrenByKind": [
            {
                "kind": "book-page",
                "label": "Pages",
                "entities": [
                    book_child(page_id, "book-page", f"Page {index + 1}", CHAPTER_ID, index)
                    for index, page_id in enumerate(PAGE_IDS)
                ],
            }
        ],
        "relationships": [],
    }


def _filter_entities(indexed_items, parameters):
    kind = _first_parameter(parameters, "kind")
    query = _first_parameter(parameters, "query").strip().casefold()

    if kind:
        indexed_items = [pair for pair in indexed_items if pair[1]["kind"] == kind]
    if query:
        indexed_items = [pair for pair in indexed_items if query in pair[1]["title"].casefold()]
    status = _first_parameter(parameters, "status").casefold()
    if status == "in-progress":
        indexed_items = [pair for pair in indexed_items if (pair[1].get("progress") or 0) > 0]
    elif status == "watched":
        indexed_items = [pair for pair in indexed_items if (pair[1].get("playCount") or 0) > 0]
    return indexed_items


def _sort_entities(indexed_items, parameters):
    sort_key = _first_parameter(parameters, "sort").casefold()
    descending = _first_parameter(parameters, "sortDir").casefold() == "desc"

    if sort_key in ("random", "shuffle"):
        try:
            seed = int(_first_parameter(parameters, "seed") or "0")
        except ValueError:
            seed = 0
        shuffled = list(indexed_items)
        random.Random(seed).shuffle(shuffled)
        return shuffled
    if sort_key in ("added", "date"):
        return sorted(indexed_items, key=lambda pair: pair[0], reverse=descending)
    return sorted(indexed_items, key=lambda pair: pair[1]["title"].casefold(), reverse=descending)


def _entity_limit(parameters, total_count):
    raw_limit = _first_parameter(parameters, "limit")
    if not raw_limit:
        return total_count

    try:
        return min(200, max(1, int(raw_limit)))
    except ValueError:
        return total_count


def _first_parameter(parameters, name):
    values = parameters.get(name)
    return values[0] if values else ""


class Handler(BaseHTTPRequestHandler):
    def _send(self, status, payload=None):
        body = json.dumps(payload).encode() if payload is not None else b""
        self.send_response(status)
        if body:
            self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def _authed(self):
        query = parse_qs(urlsplit(self.path).query)
        return (
            self.headers.get("Authorization") == f"Bearer {TOKEN}"
            or _first_parameter(query, "api_key") == TOKEN
        )

    def _send_text(self, status, contents, content_type="text/plain; charset=utf-8"):
        body = contents.encode()
        self.send_response(status)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def _send_page(self):
        self.send_response(200)
        self.send_header("Content-Type", "image/png")
        self.send_header("Content-Length", str(len(MOCK_PAGE_PNG)))
        self.end_headers()
        self.wfile.write(MOCK_PAGE_PNG)

    def _send_binary(self, contents, content_type):
        self.send_response(200)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(contents)))
        self.end_headers()
        self.wfile.write(contents)

    def _send_media(self, contents, content_type, head_only=False):
        size = len(contents)
        start, end = 0, size - 1
        range_header = self.headers.get("Range")
        if range_header and range_header.startswith("bytes="):
            start_text, _, end_text = range_header.removeprefix("bytes=").partition("-")
            start = int(start_text or 0)
            end = min(size - 1, int(end_text)) if end_text else size - 1

        length = max(0, end - start + 1)
        self.send_response(206 if range_header else 200)
        self.send_header("Content-Type", content_type)
        self.send_header("Accept-Ranges", "bytes")
        self.send_header("Content-Length", str(length))
        if range_header:
            self.send_header("Content-Range", f"bytes {start}-{end}/{size}")
        self.end_headers()
        if not head_only:
            try:
                self.wfile.write(contents[start : end + 1])
            except (BrokenPipeError, ConnectionResetError):
                pass

    def do_GET(self):
        request_url = urlsplit(self.path)
        path = request_url.path

        if path == "/api/health":
            return self._send(200, {"status": "ok", "runtime": "mock"})

        if path == "/api/health/database-restore":
            return self._send(200, {"restorePending": False, "restoreFailed": False, "error": None})

        if path == "/api/auth/setup-status":
            return self._send(200, {"needsSetup": False, "hasUsers": True})

        if path == PUBLIC_WEBM_PREVIEW_PATH:
            contents, content_type = load_image_media(WEBM_IMAGE_ID, "preview")
            return self._send_media(contents, content_type)

        if path in (PUBLIC_POSTER_PATH, PUBLIC_BANNER_PATH):
            fixture_name = (
                "poster-petethecat.jpg"
                if path == PUBLIC_POSTER_PATH
                else "banner-petethecat.jpg"
            )
            try:
                contents = (IMAGE_FIXTURE_ROOT / fixture_name).read_bytes()
            except OSError:
                return self._send(404, {"code": "fixture_not_found"})
            return self._send_media(contents, "image/jpeg")

        if not self._authed():
            return self._send(401, {"code": "authentication_required", "message": "Authentication is required."})

        if path == "/api/auth/me":
            return self._send(200, USER)

        if path == "/api/auth/sessions":
            return self._send(200, ACCOUNT_SESSIONS)

        if path == "/api/libraries":
            return self._send(200, [LIBRARY_ROOT])

        if path == "/api/users":
            current = dict(USER)
            current["libraryRootIds"] = [LIBRARY_ROOT["id"]]
            return self._send(200, {"items": [current, MEMBER_USER]})

        if path == "/api/health/worker":
            return self._send(
                200,
                {
                    "status": "online",
                    "workerId": "ui-fixture-worker",
                    "lastSeenAt": "2026-07-16T18:30:00Z",
                    "staleAfterSeconds": 45,
                },
            )

        if path == "/api/settings/database-backups":
            return self._send(200, DATABASE_BACKUPS)

        if path in ("/api/settings", "/api/settings/"):
            return self._send(200, {"groups": []})

        if path == "/api/settings/transcode-cache":
            return self._send(200, {"usedBytes": 1048576, "maxBytes": 1073741824})

        if path == PUBLIC_TRICKPLAY_PATH:
            return self._send_text(200, MOCK_TRICKPLAY_PLAYLIST, "text/vtt; charset=utf-8")

        if path == "/api/settings/values":
            return self._send(
                200,
                {
                    "values": {
                        "subtitles.autoEnable": True,
                        "subtitles.preferredLanguages": ["en", "eng", "English"],
                        "subtitles.style": "outline",
                        "subtitles.fontScale": 1,
                        "subtitles.positionPercent": 88,
                        "subtitles.opacity": 1,
                    }
                },
            )

        if path in ("/api/plugins", "/api/plugins/", "/api/identify/providers"):
            return self._send(200, [METADATA_PROVIDER])

        if path == "/api/identify/queue":
            return self._send(200, IDENTIFY_QUEUE)

        if path == "/api/acquisitions/downloads":
            return self._send(200, REQUEST_DOWNLOADS)

        if path in ("/api/monitors/missing", "/api/monitors/cutoff-unmet"):
            return self._send(200, {"items": [], "total": 0})

        if path == "/api/acquisitions/history":
            return self._send(200, [])

        if path.startswith("/api/audio-stream/"):
            track_id = path.removeprefix("/api/audio-stream/")
            if any(item["id"] == track_id for item in AUDIOBOOK_PARTS):
                return self._send_audio()
            return self._send(404, {"code": "audio_track_not_found", "message": "Audio track was not found."})

        if path.startswith("/api/videos/") and path.endswith("/subtitles/mock-ass-en/source"):
            return self._send_text(200, MOCK_ASS_SUBTITLE, "text/plain; charset=utf-8")

        if path.startswith("/api/videos/") and path.endswith("/subtitles/mock-ass-en"):
            return self._send_text(200, MOCK_NORMALIZED_ASS_SUBTITLE, "text/vtt; charset=utf-8")

        if path.startswith("/api/videos/") and path.endswith("/subtitles/mock-vtt-en"):
            return self._send_text(200, MOCK_VTT_MARKUP_SUBTITLE, "text/vtt; charset=utf-8")

        if path in ("/api/entities", "/api/collections"):
            return self._send(200, build_entity_list_response(path, request_url.query))

        collection_parts = path.strip("/").split("/")
        if (
            len(collection_parts) == 4
            and collection_parts[:2] == ["api", "collections"]
            and collection_parts[3] == "items"
        ):
            collection_items = build_collection_items_response(collection_parts[2])
            if collection_items is not None:
                return self._send(200, collection_items)
            return self._send(404, {"code": "collection_not_found", "message": "Collection was not found."})

        file_parts = path.strip("/").split("/")
        if len(file_parts) == 5 and file_parts[:2] == ["api", "entities"] and file_parts[3] == "files":
            entity_id, role = file_parts[2], file_parts[4]
            image_media = load_image_media(entity_id, role)
            if image_media is not None:
                contents, content_type = image_media
                return self._send_media(contents, content_type)

        if path.startswith("/api/entities/") and path.endswith("/files/source"):
            entity_id = path.split("/")[3]
            if entity_id in PAGE_IDS:
                return self._send_page()
            if entity_id == EPUB_BOOK_ID:
                return self._send_binary(MOCK_EPUB, "application/epub+zip")
            if entity_id == PDF_BOOK_ID:
                return self._send_binary(MOCK_PDF, "application/pdf")
            return self._send(404, {"code": "entity_file_not_found", "message": "Page not found."})

        if path.startswith("/api/books/"):
            entity_id = path.removeprefix("/api/books/")
            if DETAIL_DELAY_SECONDS > 0:
                time.sleep(DETAIL_DELAY_SECONDS)
            detail = build_book_detail_response(entity_id)
            if detail is not None:
                return self._send(200, detail)
            return self._send(404, {"code": "book_not_found", "message": "Book was not found."})

        if path.startswith(("/api/movies/", "/api/videos/")):
            entity_id = path.rsplit("/", 1)[-1]
            if DETAIL_DELAY_SECONDS > 0:
                time.sleep(DETAIL_DELAY_SECONDS)
            detail = build_entity_detail_response(entity_id)
            if detail is not None:
                return self._send(200, detail)
            return self._send(404, {"code": "entity_not_found", "message": "Entity was not found."})

        if path.startswith("/api/entities/"):
            entity_id = path.removeprefix("/api/entities/")
            if DETAIL_DELAY_SECONDS > 0:
                time.sleep(DETAIL_DELAY_SECONDS)
            detail = build_entity_detail_response(entity_id)
            if detail is not None:
                return self._send(200, detail)
            return self._send(404, {"code": "entity_not_found", "message": "Entity was not found."})

        if path.startswith("/Videos/") and path.endswith("/stream"):
            return self._send_video()

        return self._send(404, {"code": "not_found", "message": f"No mock for {path}"})

    def do_HEAD(self):
        request_url = urlsplit(self.path)
        path = request_url.path
        if path == PUBLIC_WEBM_PREVIEW_PATH:
            contents, content_type = load_image_media(WEBM_IMAGE_ID, "preview")
            return self._send_media(contents, content_type, head_only=True)
        if not self._authed():
            return self._send(401, {"code": "authentication_required", "message": "Authentication is required."})
        file_parts = path.strip("/").split("/")
        if len(file_parts) == 5 and file_parts[:2] == ["api", "entities"] and file_parts[3] == "files":
            entity_id, role = file_parts[2], file_parts[4]
            image_media = load_image_media(entity_id, role)
            if image_media is not None:
                contents, content_type = image_media
                return self._send_media(contents, content_type, head_only=True)
        if path.startswith("/api/audio-stream/"):
            track_id = path.removeprefix("/api/audio-stream/")
            if any(item["id"] == track_id for item in AUDIOBOOK_PARTS):
                return self._send_audio(head_only=True)
        return self._send(404, {"code": "not_found", "message": f"No mock for {path}"})

    def do_PATCH(self):
        request_url = urlsplit(self.path)
        if request_url.path == "/api/auth/me":
            if not self._authed():
                return self._send(401, {"code": "authentication_required", "message": "Authentication is required."})
            length = int(self.headers.get("Content-Length", 0))
            body = json.loads(self.rfile.read(length) or b"{}")
            USER["displayName"] = body.get("displayName", USER["displayName"])
            USER["updatedAt"] = "2026-07-16T18:31:00Z"
            return self._send(200, USER)
        parts = request_url.path.strip("/").split("/")
        if len(parts) != 4 or parts[:2] != ["api", "entities"]:
            return self._send(404, {"code": "not_found", "message": f"No mock for {self.path}"})

        entity = next((item for item in ENTITIES if item["id"] == parts[2]), None)
        if entity is None:
            return self._send(404, {"code": "not_found", "message": "Entity not found"})

        length = int(self.headers.get("Content-Length", 0))
        body = json.loads(self.rfile.read(length) or b"{}")
        if parts[3] == "rating":
            entity["rating"] = body.get("value")
        elif parts[3] == "flags":
            if body.get("isFavorite") is not None:
                entity["isFavorite"] = body["isFavorite"]
            if body.get("isOrganized") is not None:
                entity["isOrganized"] = body["isOrganized"]
        elif parts[3] == "progress" and entity["id"] in BOOK_PROGRESS_BY_ID:
            progress = BOOK_PROGRESS_BY_ID[entity["id"]]
            progress.update(
                {
                    "currentEntityId": body.get("currentEntityId", progress["currentEntityId"]),
                    "unit": body.get("unit", progress["unit"]),
                    "index": body.get("index", progress["index"]),
                    "total": body.get("total", progress["total"]),
                    "mode": body.get("mode", progress["mode"]),
                    "workIndex": body.get("index", progress["workIndex"]),
                    "workTotal": body.get("total", progress["workTotal"]),
                    "location": body.get("location", progress["location"]),
                    "updatedAt": "2026-07-11T00:01:00Z",
                }
            )
            if body.get("reset"):
                progress["completedAt"] = None
            elif body.get("completed") is True:
                progress["completedAt"] = "2026-07-11T00:01:00Z"
            elif body.get("completed") is False:
                progress["completedAt"] = None
        elif parts[3] == "playback" and entity["id"] == AUDIOBOOK_ID:
            if body.get("resumeSeconds") is not None:
                AUDIOBOOK_PLAYBACK["resumeSeconds"] = max(0, float(body["resumeSeconds"]))
            if body.get("completed") is True:
                AUDIOBOOK_PLAYBACK["completedAt"] = "2026-07-11T00:01:00Z"
            elif body.get("completed") is False:
                AUDIOBOOK_PLAYBACK["completedAt"] = None
        else:
            return self._send(404, {"code": "not_found", "message": f"No mock for {self.path}"})

        shallow = build_entity_detail_response(entity["id"])
        shallow["childrenByKind"] = []
        shallow["relationships"] = []
        return self._send(200, shallow)

    def do_POST(self):
        length = int(self.headers.get("Content-Length", 0))
        body = json.loads(self.rfile.read(length) or b"{}")

        if self.path == "/api/auth/login":
            if body.get("username") == "test" and body.get("password") == "test1234":
                return self._send(200, {"accessToken": TOKEN, "user": USER})
            return self._send(401, {"code": "invalid_credentials", "message": "Invalid username or password."})

        if self.path == "/api/auth/logout":
            return self._send(204)

        request_url = urlsplit(self.path)
        if request_url.path.startswith("/Items/") and request_url.path.endswith("/PlaybackInfo"):
            if PLAYBACK_DELAY_SECONDS > 0:
                time.sleep(PLAYBACK_DELAY_SECONDS)
            return self._send(
                200,
                build_playback_info_response(body.get("AudioStreamIndex")),
            )

        if request_url.path.startswith("/api/audio-tracks/") and request_url.path.endswith("/play"):
            track_id = request_url.path.split("/")[3]
            detail = build_entity_detail_response(track_id)
            if detail is not None:
                return self._send(200, detail)

        return self._send(404, {"code": "not_found", "message": f"No mock for {self.path}"})

    def _send_audio(self, head_only=False):
        size = len(MOCK_AUDIO)
        start, end = 0, size - 1
        range_header = self.headers.get("Range")
        if range_header and range_header.startswith("bytes="):
            start_text, _, end_text = range_header.removeprefix("bytes=").partition("-")
            start = int(start_text or 0)
            end = min(size - 1, int(end_text)) if end_text else size - 1

        length = max(0, end - start + 1)
        self.send_response(206 if range_header else 200)
        self.send_header("Content-Type", "audio/wav")
        self.send_header("Accept-Ranges", "bytes")
        self.send_header("Content-Length", str(length))
        if range_header:
            self.send_header("Content-Range", f"bytes {start}-{end}/{size}")
        self.end_headers()
        if not head_only:
            try:
                self.wfile.write(MOCK_AUDIO[start : end + 1])
            except (BrokenPipeError, ConnectionResetError):
                pass

    def _send_video(self):
        if not os.path.exists(MOCK_VIDEO_PATH):
            return self._send(404, {"code": "mock_video_missing", "message": MOCK_VIDEO_PATH})

        size = os.path.getsize(MOCK_VIDEO_PATH)
        start, end = 0, size - 1
        range_header = self.headers.get("Range")
        if range_header and range_header.startswith("bytes="):
            start_text, _, end_text = range_header.removeprefix("bytes=").partition("-")
            start = int(start_text or 0)
            end = min(size - 1, int(end_text)) if end_text else size - 1

        length = max(0, end - start + 1)
        self.send_response(206 if range_header else 200)
        self.send_header("Content-Type", "video/mp4")
        self.send_header("Accept-Ranges", "bytes")
        self.send_header("Content-Length", str(length))
        if range_header:
            self.send_header("Content-Range", f"bytes {start}-{end}/{size}")
        self.end_headers()
        with open(MOCK_VIDEO_PATH, "rb") as media:
            media.seek(start)
            try:
                self.wfile.write(media.read(length))
            except (BrokenPipeError, ConnectionResetError):
                pass

    def log_message(self, fmt, *args):
        print(f"[mock] {fmt % args}")


if __name__ == "__main__":
    print(f"Mock Prismedia server on http://localhost:{MOCK_PORT} (test / test1234)")
    ThreadingHTTPServer(("127.0.0.1", MOCK_PORT), Handler).serve_forever()
