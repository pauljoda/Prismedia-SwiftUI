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

    func testSpriteProjectionKeepsPlaylistSeparateFromRestingArtwork() {
        let thumbnail = EntityThumbnail(
            id: UUID(),
            kind: .video,
            title: "A Film",
            coverThumb2xURL: "/assets/film@2x.jpg",
            hoverKind: .sprite,
            hoverURL: "/api/trickplay/manifest.m3u8",
            hoverImages: [hoverImage(title: "Scene", path: "/assets/scene.jpg")]
        )

        let preview = EntityThumbnailPreview(thumbnail: thumbnail)

        XCTAssertEqual(preview.kind, .sprite)
        XCTAssertEqual(preview.restingArtworkPath, "/assets/film@2x.jpg")
        XCTAssertEqual(preview.spritePlaylistPath, "/api/trickplay/manifest.m3u8")
        XCTAssertTrue(preview.imageOptions.isEmpty)
    }

    func testRepresentativeChildrenProjectAsSegmentedSequence() {
        let thumbnail = EntityThumbnail(
            id: UUID(),
            kind: .videoSeries,
            title: "A Series",
            hoverImages: [
                hoverImage(title: "Pilot", path: "/assets/pilot.jpg"),
                hoverImage(title: "Finale", path: "/assets/finale.jpg"),
            ]
        )

        let preview = EntityThumbnailPreview(thumbnail: thumbnail)

        XCTAssertEqual(preview.kind, .imageSequence)
        XCTAssertEqual(preview.restingArtworkPath, "/assets/pilot.jpg")
        XCTAssertEqual(preview.imageOptions.map(\.title), ["Pilot", "Finale"])
    }

    func testPreviewRatioAndIndexAreClampedAtBothEdges() {
        XCTAssertEqual(EntityThumbnailPreview.ratio(location: -30, width: 200), 0)
        XCTAssertEqual(EntityThumbnailPreview.ratio(location: 250, width: 200), 1)
        XCTAssertEqual(EntityThumbnailPreview.index(for: -0.1, count: 5), 0)
        XCTAssertEqual(EntityThumbnailPreview.index(for: 0.4, count: 5), 2)
        XCTAssertEqual(EntityThumbnailPreview.index(for: 1.1, count: 5), 4)
        XCTAssertNil(EntityThumbnailPreview.index(for: 0.5, count: 0))
    }

    func testHeroArtworkNeverUsesAPlaylistDescriptor() {
        let thumbnail = EntityThumbnail(
            id: UUID(),
            kind: .video,
            title: "A Film",
            coverURL: "/assets/cover.jpg",
            hoverKind: .sprite,
            hoverURL: "/api/trickplay/manifest.m3u8",
            hoverImages: [hoverImage(title: "Scene", path: "/assets/scene.jpg")]
        )

        XCTAssertEqual(thumbnail.bestHeroPath, "/assets/scene.jpg")
    }

    func testSegmentAccessibilityValueNamesPositionAndRepresentedEntity() {
        let preview = EntityThumbnailPreview(
            thumbnail: EntityThumbnail(
                id: UUID(),
                kind: .gallery,
                title: "Portraits",
                hoverImages: [
                    hoverImage(title: "Ada", path: "/assets/ada.jpg"),
                    hoverImage(title: "Grace", path: "/assets/grace.jpg"),
                ]
            )
        )

        XCTAssertEqual(preview.accessibilityValue(at: 1), "Preview 2 of 2, Grace")
        XCTAssertEqual(preview.accessibilityValue(at: nil), "Cover")
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

    private func hoverImage(title: String, path: String) -> EntityThumbnailHoverImage {
        EntityThumbnailHoverImage(entityID: UUID(), title: title, path: path)
    }
}
