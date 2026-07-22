#!/usr/bin/env python3
"""Focused contract tests for the Prismedia UI-test mock server."""

import importlib.util
import io
import json
import threading
import unittest
import zipfile
from pathlib import Path
from urllib.request import Request, urlopen


def load_mock_server_module():
    script_path = Path(__file__).with_name("mock-server.py")
    spec = importlib.util.spec_from_file_location("prismedia_mock_server", script_path)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"Could not load {script_path}")

    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


mock_server = load_mock_server_module()


class EntityListResponseTests(unittest.TestCase):
    def test_query_is_url_decoded_and_matches_titles_case_insensitively(self):
        response = mock_server.build_entity_list_response(
            "/api/entities",
            "query=mock%20movie",
        )

        self.assertEqual(
            ["Mock Movie One", "Mock Movie Two"],
            [item["title"] for item in response["items"]],
        )
        self.assertEqual(2, response["totalCount"])

    def test_limit_is_applied_after_filtering_without_changing_total_count(self):
        response = mock_server.build_entity_list_response(
            "/api/entities",
            "kind=video&query=Mock&sort=title&sortDir=desc&limit=2",
        )

        self.assertEqual(
            ["Mock Video Beta", "Mock Video Alpha"],
            [item["title"] for item in response["items"]],
        )
        self.assertEqual(3, response["totalCount"])

    def test_added_sort_uses_fixture_order_and_honors_descending_direction(self):
        response = mock_server.build_entity_list_response(
            "/api/entities",
            "sort=added&sortDir=desc&limit=3",
        )

        self.assertEqual(
            ["Mock Episode One", "Mock Collection", "Mock Audiobook"],
            [item["title"] for item in response["items"]],
        )

    def test_collections_endpoint_uses_the_shared_list_contract(self):
        response = mock_server.build_entity_list_response(
            "/api/collections",
            "query=Mock&limit=1",
        )

        self.assertEqual(["Mock Collection"], [item["title"] for item in response["items"]])
        self.assertEqual(1, response["totalCount"])

    def test_every_native_grid_kind_has_a_deterministic_fixture(self):
        expected_kinds = {
            "video",
            "movie",
            "video-series",
            "gallery",
            "image",
            "music-artist",
            "audio-library",
            "audio-track",
            "book-author",
            "book",
            "person",
            "studio",
            "tag",
        }

        for kind in expected_kinds:
            with self.subTest(kind=kind):
                response = mock_server.build_entity_list_response(
                    "/api/entities",
                    f"kind={kind}&limit=1",
                )
                self.assertEqual(1, len(response["items"]))
                self.assertEqual(kind, response["items"][0]["kind"])

    def test_detail_document_reuses_the_thumbnail_identity_and_exposes_groups(self):
        entity_id = "33333333-3333-3333-3333-333333333333"

        detail = mock_server.build_entity_detail_response(entity_id)

        self.assertEqual(entity_id, detail["id"])
        self.assertEqual("Mock Movie One", detail["title"])
        self.assertEqual("description", detail["capabilities"][0]["kind"])
        images = detail["capabilities"][1]
        self.assertEqual("backdrop", images["items"][0]["kind"])
        self.assertEqual(mock_server.PUBLIC_BANNER_PATH, images["items"][0]["path"])
        self.assertEqual("Mock Video Alpha", detail["childrenByKind"][0]["entities"][0]["title"])

    def test_detail_document_returns_none_for_an_unknown_entity(self):
        self.assertIsNone(
            mock_server.build_entity_detail_response(
                "12345678-1234-1234-1234-123456789abc"
            )
        )

    def test_video_detail_exposes_an_ass_subtitle_fixture(self):
        video_id = mock_server.ENTITIES[mock_server.VIDEO_ALPHA_INDEX]["id"]

        detail = mock_server.build_entity_detail_response(video_id)

        subtitles = next(
            capability
            for capability in detail["capabilities"]
            if capability["kind"] == "subtitles"
        )
        self.assertEqual("English Styled", subtitles["items"][0]["label"])
        self.assertEqual("ass", subtitles["items"][0]["format"])
        self.assertEqual("ass", subtitles["items"][0]["sourceFormat"])
        self.assertEqual("English WebVTT Markup", subtitles["items"][1]["label"])
        self.assertEqual("vtt", subtitles["items"][1]["sourceFormat"])

    def test_generic_book_details_omit_kind_specific_fields_like_production(self):
        detail = mock_server.build_entity_detail_response(mock_server.EPUB_BOOK_ID)

        self.assertNotIn("bookType", detail)
        self.assertNotIn("format", detail)
        self.assertNotIn("coverPageId", detail)

    def test_specialized_book_details_expose_native_formats_and_progress_contracts(self):
        epub = mock_server.build_book_detail_response(mock_server.EPUB_BOOK_ID)
        pdf = mock_server.build_book_detail_response(mock_server.PDF_BOOK_ID)

        self.assertEqual("epub", epub["format"])
        self.assertTrue(epub["hasSourceMedia"])
        self.assertEqual("cfi", epub["capabilities"][-1]["unit"])
        self.assertEqual(10000, epub["capabilities"][-1]["total"])
        self.assertEqual("pdf", pdf["format"])
        self.assertTrue(pdf["hasSourceMedia"])
        self.assertEqual("page", pdf["capabilities"][-1]["unit"])

    def test_native_reader_files_are_structurally_valid(self):
        with zipfile.ZipFile(io.BytesIO(mock_server.MOCK_EPUB)) as archive:
            self.assertEqual(b"application/epub+zip", archive.read("mimetype"))
            self.assertIn("OEBPS/nav.xhtml", archive.namelist())
            self.assertIn("The First Signal", archive.read("OEBPS/nav.xhtml").decode())

        self.assertTrue(mock_server.MOCK_PDF.startswith(b"%PDF-1.4"))
        self.assertIn(b"/Type /Outlines", mock_server.MOCK_PDF)
        self.assertIn(b"searchable lighthouse", mock_server.MOCK_PDF)

    def test_audiobook_detail_exposes_scrambled_parts_and_book_resume(self):
        detail = mock_server.build_book_detail_response(mock_server.AUDIOBOOK_ID)
        parts = detail["childrenByKind"][0]["entities"]
        playback = next(item for item in detail["capabilities"] if item["kind"] == "playback")

        self.assertEqual("audio", detail["format"])
        self.assertEqual(["Part Two", "Part One", "Part Three"], [item["title"] for item in parts])
        self.assertEqual([1, 0, 2], [item["sortOrder"] for item in parts])
        self.assertEqual(145, playback["resumeSeconds"])

    def test_mixed_media_gallery_exposes_still_gif_mp4_and_webm_images(self):
        detail = mock_server.build_entity_detail_response(mock_server.IMAGE_GALLERY_ID)

        images = detail["childrenByKind"][0]["entities"]

        self.assertEqual(
            [
                "Mock Still Image",
                "Mock Animated GIF",
                "Mock MP4 Image",
                "Mock WebM Image",
            ],
            [image["title"] for image in images],
        )
        self.assertEqual(["image"] * 4, [image["kind"] for image in images])

    def test_mixed_media_image_details_expose_source_and_preview_roles(self):
        expected_files = {
            mock_server.STILL_IMAGE_ID: [("source", "image/jpeg")],
            mock_server.ANIMATED_GIF_IMAGE_ID: [("source", "image/gif")],
            mock_server.MP4_IMAGE_ID: [
                ("source", "video/mp4"),
                ("preview", "video/mp4"),
            ],
            mock_server.WEBM_IMAGE_ID: [
                ("source", "video/webm"),
                ("preview", "video/mp4"),
            ],
        }

        for entity_id, expected in expected_files.items():
            with self.subTest(entity_id=entity_id):
                detail = mock_server.build_entity_detail_response(entity_id)
                files = next(
                    capability
                    for capability in detail["capabilities"]
                    if capability["kind"] == "files"
                )["items"]

                self.assertTrue(detail["hasSourceMedia"])
                self.assertEqual(expected, [(item["role"], item["mimeType"]) for item in files])

        webm_detail = mock_server.build_entity_detail_response(mock_server.WEBM_IMAGE_ID)
        webm_files = next(
            capability
            for capability in webm_detail["capabilities"]
            if capability["kind"] == "files"
        )["items"]
        webm_preview = next(item for item in webm_files if item["role"] == "preview")

        self.assertEqual(
            "/assets/mock-fixtures/preview.mp4",
            webm_preview["path"],
        )


class PlaybackFixtureTests(unittest.TestCase):
    def test_default_playback_info_exposes_two_audio_tracks(self):
        response = mock_server.build_playback_info_response(audio_stream_index=None)
        source = response["MediaSources"][0]
        audio = [stream for stream in source["MediaStreams"] if stream["Type"] == "Audio"]

        self.assertEqual(["Main", "Commentary"], [stream["DisplayTitle"] for stream in audio])
        self.assertTrue(source["SupportsDirectPlay"])
        self.assertTrue(audio[0]["IsDefault"])

    def test_explicit_audio_selection_returns_a_remux_url_and_selected_track(self):
        response = mock_server.build_playback_info_response(audio_stream_index=2)
        source = response["MediaSources"][0]
        audio = [stream for stream in source["MediaStreams"] if stream["Type"] == "Audio"]

        self.assertFalse(source["SupportsDirectPlay"])
        self.assertEqual("/Videos/mock/stream?AudioStreamIndex=2", source["TranscodingUrl"])
        self.assertTrue(source["TranscodingInfo"]["IsVideoDirect"])
        self.assertEqual([False, True], [stream["IsDefault"] for stream in audio])


class EntityListHTTPTests(unittest.TestCase):
    def setUp(self):
        mock_server.AUDIOBOOK_PLAYBACK.update({"resumeSeconds": 145, "completedAt": None})
        self.server = mock_server.HTTPServer(("127.0.0.1", 0), mock_server.Handler)
        self.thread = threading.Thread(target=self.server.serve_forever, daemon=True)
        self.thread.start()

    def tearDown(self):
        self.server.shutdown()
        self.server.server_close()
        self.thread.join(timeout=2)

    def test_authenticated_endpoint_applies_decoded_query_sort_and_limit(self):
        port = self.server.server_address[1]
        request = Request(
            f"http://127.0.0.1:{port}/api/entities?query=mock%20movie&sort=title&sortDir=desc&limit=1",
            headers={"Authorization": f"Bearer {mock_server.TOKEN}"},
        )

        with urlopen(request) as response:
            payload = json.load(response)

        self.assertEqual(["Mock Movie Two"], [item["title"] for item in payload["items"]])
        self.assertEqual(2, payload["totalCount"])

    def test_subtitle_settings_and_ass_routes_support_both_player_contracts(self):
        port = self.server.server_address[1]
        headers = {"Authorization": f"Bearer {mock_server.TOKEN}"}
        settings_request = Request(
            f"http://127.0.0.1:{port}/api/settings/values?keys=subtitles.autoEnable",
            headers=headers,
        )
        with urlopen(settings_request) as response:
            settings = json.loads(response.read())

        caption_request = Request(
            f"http://127.0.0.1:{port}/api/videos/{mock_server.ENTITIES[mock_server.VIDEO_ALPHA_INDEX]['id']}/subtitles/mock-ass-en",
            headers=headers,
        )
        with urlopen(caption_request) as response:
            normalized_caption = response.read().decode()

        source_request = Request(
            f"http://127.0.0.1:{port}/api/videos/{mock_server.ENTITIES[mock_server.VIDEO_ALPHA_INDEX]['id']}/subtitles/mock-ass-en/source",
            headers=headers,
        )
        with urlopen(source_request) as response:
            preserved_source = response.read().decode()

        self.assertTrue(settings["values"]["subtitles.autoEnable"])
        self.assertEqual(["en", "eng", "English"], settings["values"]["subtitles.preferredLanguages"])
        self.assertTrue(normalized_caption.startswith("WEBVTT"))
        self.assertIn("Styled English ASS fixture", normalized_caption)
        self.assertTrue(preserved_source.startswith("[Script Info]"))
        self.assertIn("Dialogue:", preserved_source)
        self.assertIn("Styled English ASS fixture", preserved_source)

    def test_webvtt_markup_source_preserves_inline_style_tags(self):
        port = self.server.server_address[1]
        request = Request(
            f"http://127.0.0.1:{port}/api/videos/{mock_server.ENTITIES[mock_server.VIDEO_ALPHA_INDEX]['id']}/subtitles/mock-vtt-en",
            headers={"Authorization": f"Bearer {mock_server.TOKEN}"},
        )

        with urlopen(request) as response:
            source = response.read().decode()

        self.assertIn("<i>italic</i>", source)
        self.assertIn("<b>bold</b>", source)
        self.assertIn("<u>underlined</u>", source)

    def test_authenticated_detail_endpoint_returns_the_entity_document(self):
        port = self.server.server_address[1]
        request = Request(
            f"http://127.0.0.1:{port}/api/entities/33333333-3333-3333-3333-333333333333",
            headers={"Authorization": f"Bearer {mock_server.TOKEN}"},
        )

        with urlopen(request) as response:
            payload = json.load(response)

        self.assertEqual("Mock Movie One", payload["title"])
        self.assertEqual("movie", payload["kind"])

    def test_authenticated_collection_detail_endpoint_returns_the_collection_document(self):
        port = self.server.server_address[1]
        request = Request(
            f"http://127.0.0.1:{port}/api/collections/{mock_server.COLLECTION_ID}",
            headers={"Authorization": f"Bearer {mock_server.TOKEN}"},
        )

        with urlopen(request) as response:
            payload = json.load(response)

        self.assertEqual("Mock Collection", payload["title"])
        self.assertEqual("collection", payload["kind"])

    def test_authenticated_book_endpoint_returns_the_specialized_contract(self):
        port = self.server.server_address[1]
        request = Request(
            f"http://127.0.0.1:{port}/api/books/{mock_server.EPUB_BOOK_ID}",
            headers={"Authorization": f"Bearer {mock_server.TOKEN}"},
        )

        with urlopen(request) as response:
            payload = json.load(response)

        self.assertEqual("epub", payload["format"])
        self.assertEqual("novel", payload["bookType"])

    def test_authenticated_collection_items_endpoint_returns_mixed_members_in_order(self):
        port = self.server.server_address[1]
        request = Request(
            f"http://127.0.0.1:{port}/api/collections/{mock_server.COLLECTION_ID}/items",
            headers={"Authorization": f"Bearer {mock_server.TOKEN}"},
        )

        with urlopen(request) as response:
            payload = json.load(response)

        self.assertEqual(
            [
                "Mock Movie One",
                "Mock Book",
                "Mock Artist",
                "Mock Long Movie 01",
                "Mock Long Movie 02",
                "Mock Long Movie 03",
                "Mock Long Movie 04",
                "Mock Long Movie 05",
                "Mock Long Movie 06",
            ],
            [item["entity"]["title"] for item in payload["items"]],
        )
        self.assertEqual(
            [
                "movie",
                "book",
                "music-artist",
                "movie",
                "movie",
                "movie",
                "movie",
                "movie",
                "movie",
            ],
            [item["entity"]["kind"] for item in payload["items"]],
        )

    def test_authenticated_native_reader_sources_use_exact_media_types(self):
        port = self.server.server_address[1]
        headers = {"Authorization": f"Bearer {mock_server.TOKEN}"}

        for entity_id, expected_type, prefix in [
            (mock_server.EPUB_BOOK_ID, "application/epub+zip", b"PK"),
            (mock_server.PDF_BOOK_ID, "application/pdf", b"%PDF"),
        ]:
            with self.subTest(entity_id=entity_id):
                request = Request(
                    f"http://127.0.0.1:{port}/api/entities/{entity_id}/files/source",
                    headers=headers,
                )
                with urlopen(request) as response:
                    self.assertEqual(expected_type, response.headers.get_content_type())
                    self.assertTrue(response.read().startswith(prefix))

    def test_authenticated_mixed_image_sources_and_previews_use_exact_media_types(self):
        port = self.server.server_address[1]
        headers = {"Authorization": f"Bearer {mock_server.TOKEN}"}
        cases = [
            (mock_server.STILL_IMAGE_ID, "source", "image/jpeg", b"\xff\xd8"),
            (mock_server.ANIMATED_GIF_IMAGE_ID, "source", "image/gif", b"GIF8"),
            (mock_server.MP4_IMAGE_ID, "source", "video/mp4", None),
            (mock_server.MP4_IMAGE_ID, "preview", "video/mp4", None),
            (mock_server.WEBM_IMAGE_ID, "source", "video/webm", b"\x1aE\xdf\xa3"),
            (mock_server.WEBM_IMAGE_ID, "preview", "video/mp4", None),
        ]

        for entity_id, role, expected_type, prefix in cases:
            with self.subTest(entity_id=entity_id, role=role):
                request = Request(
                    f"http://127.0.0.1:{port}/api/entities/{entity_id}/files/{role}",
                    headers=headers,
                )
                with urlopen(request) as response:
                    body = response.read()
                    self.assertEqual(expected_type, response.headers.get_content_type())
                    self.assertGreater(len(body), 128)
                    if prefix is not None:
                        self.assertTrue(body.startswith(prefix))
                    if expected_type == "video/mp4":
                        self.assertEqual(b"ftyp", body[4:8])

    def test_public_webm_image_preview_supports_head_and_byte_ranges_without_authentication(self):
        port = self.server.server_address[1]
        url = f"http://127.0.0.1:{port}/assets/mock-fixtures/preview.mp4"

        with urlopen(Request(url, method="HEAD")) as response:
            full_length = int(response.headers["Content-Length"])
            self.assertEqual("video/mp4", response.headers.get_content_type())
            self.assertEqual("bytes", response.headers["Accept-Ranges"])

        with urlopen(Request(url, headers={"Range": "bytes=10-29"})) as response:
            self.assertEqual(206, response.status)
            self.assertEqual(f"bytes 10-29/{full_length}", response.headers["Content-Range"])
            self.assertEqual(20, len(response.read()))

    def test_authenticated_audiobook_stream_supports_head_and_ranges(self):
        port = self.server.server_address[1]
        track_id = mock_server.AUDIOBOOK_PARTS[0]["id"]
        url = f"http://127.0.0.1:{port}/api/audio-stream/{track_id}?api_key={mock_server.TOKEN}"

        with urlopen(Request(url, method="HEAD")) as response:
            self.assertEqual("audio/wav", response.headers.get_content_type())
            self.assertEqual("bytes", response.headers["Accept-Ranges"])

        with urlopen(Request(url, headers={"Range": "bytes=10-19"})) as response:
            self.assertEqual(206, response.status)
            self.assertEqual("bytes 10-19/400044", response.headers["Content-Range"])
            self.assertEqual(10, len(response.read()))

    def test_book_playback_patch_updates_durable_audiobook_cursor(self):
        port = self.server.server_address[1]
        url = f"http://127.0.0.1:{port}/api/entities/{mock_server.AUDIOBOOK_ID}/playback"
        request = Request(
            url,
            data=json.dumps({"resumeSeconds": 151, "completed": False}).encode(),
            headers={
                "Authorization": f"Bearer {mock_server.TOKEN}",
                "Content-Type": "application/json",
            },
            method="PATCH",
        )

        with urlopen(request) as response:
            payload = json.load(response)

        playback = next(item for item in payload["capabilities"] if item["kind"] == "playback")
        self.assertEqual(151, playback["resumeSeconds"])
        self.assertIsNone(playback["completedAt"])


if __name__ == "__main__":
    unittest.main()
