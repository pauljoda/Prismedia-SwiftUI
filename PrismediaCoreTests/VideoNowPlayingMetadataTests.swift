import Foundation
import XCTest

@testable import PrismediaCore

final class VideoNowPlayingMetadataTests: XCTestCase {
    func testOwnerDetailSuppliesTitleAndPreferredArtwork() throws {
        let detail = try makeDetail(
            title: "Episode Title",
            imageCapability: """
                {"kind":"images","supportedKinds":[],"items":[{"kind":"poster","path":"/detail.jpg"}]}
                """
        )
        let owner = EntityLink(
            entityID: detail.id,
            kind: .video,
            thumbnailPreview: .init(
                title: "Grid Title",
                subtitle: "Season 1, Episode 3",
                artworkPath: "/preview.jpg"
            )
        )

        let metadata = VideoNowPlayingMetadata(detail: detail, ownerLink: owner)

        XCTAssertEqual(metadata.title, "Episode Title")
        XCTAssertEqual(metadata.subtitle, "Season 1, Episode 3")
        XCTAssertEqual(metadata.artworkPath, "/detail.jpg")
    }

    func testDetailPosterSuppliesArtworkWhenNavigationHasNoPreview() throws {
        let detail = try makeDetail(
            title: "Direct Navigation",
            imageCapability: """
                {"kind":"images","supportedKinds":[],"items":[{"kind":"backdrop","path":"/wide.jpg"},{"kind":"poster","path":"/poster.jpg"}]}
                """
        )

        let metadata = VideoNowPlayingMetadata(
            detail: detail,
            ownerLink: EntityLink(entityID: detail.id, kind: .video)
        )

        XCTAssertEqual(metadata.artworkPath, "/poster.jpg")
    }

    private func makeDetail(title: String, imageCapability: String) throws -> EntityDetail {
        try PrismediaJSON.decoder().decode(
            EntityDetail.self,
            from: Data(
                """
                {"id":"30303030-3030-3030-3030-303030303030","kind":"video","title":"\(title)","hasSourceMedia":true,"capabilities":[\(imageCapability)],"childrenByKind":[],"relationships":[]}
                """.utf8
            )
        )
    }
}
