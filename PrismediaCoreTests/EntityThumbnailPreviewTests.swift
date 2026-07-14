import XCTest

@testable import PrismediaCore

final class EntityThumbnailPreviewTests: XCTestCase {
    func testSpriteHoverKindDecodesAsTypedPreviewMode() throws {
        let data = Data(
            """
            {
              "id": "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa",
              "kind": "video",
              "title": "A Film",
              "hoverKind": "sprite",
              "hoverUrl": "/api/trickplay/manifest.m3u8"
            }
            """.utf8
        )

        let thumbnail = try PrismediaJSON.decoder().decode(EntityThumbnail.self, from: data)

        XCTAssertEqual(thumbnail.hoverKind, .sprite)
    }

    func testMissingAndFutureHoverKindsRemainDecodable() throws {
        let missingKind = try decodeThumbnail(hoverKindJSON: nil)
        let futureKind = try decodeThumbnail(hoverKindJSON: "\"volumetric\"")

        XCTAssertEqual(missingKind.hoverKind, .none)
        XCTAssertEqual(futureKind.hoverKind, .unknown("volumetric"))
    }

    private func decodeThumbnail(hoverKindJSON: String?) throws -> EntityThumbnail {
        let hoverKindMember = hoverKindJSON.map { ", \"hoverKind\": \($0)" } ?? ""
        let data = Data(
            """
            {
              "id": "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa",
              "kind": "video",
              "title": "A Film"\(hoverKindMember)
            }
            """.utf8
        )
        return try PrismediaJSON.decoder().decode(EntityThumbnail.self, from: data)
    }
}
