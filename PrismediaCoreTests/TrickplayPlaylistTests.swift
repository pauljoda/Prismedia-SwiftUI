import Foundation
import XCTest

@testable import PrismediaCore

final class TrickplayPlaylistTests: XCTestCase {
    func testParsesTileGeometryAndTimingInRowMajorOrder() throws {
        let playlist = try TrickplayPlaylist.parse(
            contents: """
                #EXTM3U
                #EXT-X-IMAGES-ONLY
                #EXT-X-TILES:RESOLUTION=320x180,LAYOUT=3x2,DURATION=10.000
                #EXTINF:60.000,
                sheet-1.jpg
                #EXT-X-ENDLIST
                """,
            playlistURL: URL(string: "https://media.example/videos/trickplay/playlist.m3u8")!
        )

        XCTAssertEqual(playlist.frames.count, 6)
        XCTAssertEqual(playlist.frames.map(\.startTime), [0, 10, 20, 30, 40, 50])
        XCTAssertEqual(
            playlist.frames.map(\.crop),
            [
                .init(x: 0, y: 0, width: 320, height: 180),
                .init(x: 320, y: 0, width: 320, height: 180),
                .init(x: 640, y: 0, width: 320, height: 180),
                .init(x: 0, y: 180, width: 320, height: 180),
                .init(x: 320, y: 180, width: 320, height: 180),
                .init(x: 640, y: 180, width: 320, height: 180),
            ]
        )
        XCTAssertTrue(
            playlist.frames.allSatisfy {
                $0.imageURL == URL(string: "https://media.example/videos/trickplay/sheet-1.jpg")!
            })
    }

    func testMultipleSheetsUseExtinfForCumulativeStartTimesAndPartialFinalSheet() throws {
        let playlist = try TrickplayPlaylist.parse(
            contents: """
                #EXTM3U
                #EXT-X-TILES:RESOLUTION=160x90,LAYOUT=2x2,DURATION=5
                #EXTINF:20,
                first.jpg
                #EXTINF:12,
                second.jpg
                """,
            playlistURL: URL(string: "https://media.example/trickplay/index.m3u8")!
        )

        XCTAssertEqual(playlist.frames.count, 7)
        XCTAssertEqual(playlist.frames.map(\.startTime), [0, 5, 10, 15, 20, 25, 30])
        XCTAssertEqual(playlist.frames[4].crop, .init(x: 0, y: 0, width: 160, height: 90))
        XCTAssertEqual(playlist.frames[6].crop, .init(x: 0, y: 90, width: 160, height: 90))
        XCTAssertEqual(
            playlist.frames[6].imageURL,
            URL(string: "https://media.example/trickplay/second.jpg")!
        )
    }

    func testPreservesAbsoluteImageURLs() throws {
        let playlist = try TrickplayPlaylist.parse(
            contents: """
                #EXTM3U
                #EXT-X-TILES:RESOLUTION=320x180,LAYOUT=1x1,DURATION=10
                #EXTINF:10,
                https://cdn.example/previews/frame.jpg?token=abc
                """,
            playlistURL: URL(string: "https://media.example/trickplay/index.m3u8")!
        )

        XCTAssertEqual(
            playlist.frames.first?.imageURL,
            URL(string: "https://cdn.example/previews/frame.jpg?token=abc")!
        )
    }

    func testParsesLegacyWebVTTSpriteMapsAndInfersSheetGeometry() throws {
        let playlist = try TrickplayPlaylist.parse(
            contents: """
                WEBVTT

                00:00.000 --> 00:10.000
                sheet.jpg#xywh=0,0,160,90

                00:10.000 --> 00:20.000
                sheet.jpg#xywh=160,0,160,90

                00:20.000 --> 00:30.000
                second.jpg#xywh=0,90,160,90
                """,
            playlistURL: URL(string: "https://media.example/trickplay/index.vtt")!
        )

        XCTAssertEqual(playlist.frames.map(\.startTime), [0, 10, 20])
        XCTAssertEqual(playlist.frames[1].crop, .init(x: 160, y: 0, width: 160, height: 90))
        XCTAssertEqual(playlist.frames[1].imageWidth, 320)
        XCTAssertEqual(playlist.frames[1].imageHeight, 90)
        XCTAssertEqual(playlist.frames[2].imageWidth, 160)
        XCTAssertEqual(playlist.frames[2].imageHeight, 180)
        XCTAssertEqual(
            playlist.frames[0].imageURL,
            URL(string: "https://media.example/trickplay/sheet.jpg")!
        )
    }

    func testRejectsMalformedWebVTTSpriteMaps() {
        XCTAssertThrowsError(
            try TrickplayPlaylist.parse(
                contents: """
                    WEBVTT

                    00:00.000 --> 00:10.000
                    sheet.jpg
                    """,
                playlistURL: URL(string: "https://media.example/trickplay/index.vtt")!
            )
        ) { error in
            XCTAssertEqual(error as? TrickplayPlaylist.ParseError, .invalidWebVTT)
        }
    }

    func testRejectsImageSegmentsWithoutTileMetadata() {
        XCTAssertThrowsError(
            try TrickplayPlaylist.parse(
                contents: """
                    #EXTM3U
                    #EXTINF:10,
                    sheet.jpg
                    """,
                playlistURL: URL(string: "https://media.example/trickplay/index.m3u8")!
            )
        ) { error in
            XCTAssertEqual(error as? TrickplayPlaylist.ParseError, .missingTileMetadata)
        }
    }
}
