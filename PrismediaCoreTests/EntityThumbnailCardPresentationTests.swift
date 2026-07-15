import XCTest

@testable import PrismediaCore

final class EntityThumbnailCardPresentationTests: XCTestCase {
    func testThumbnailDecodesConciseDescriptionFromExistingServerNames() throws {
        let description = try decodeThumbnail(descriptionMember: #""description":"A description.""#)
        let overview = try decodeThumbnail(descriptionMember: #""overview":"An overview.""#)
        let summary = try decodeThumbnail(descriptionMember: #""summary":"A summary.""#)

        XCTAssertEqual(description.summary, "A description.")
        XCTAssertEqual(overview.summary, "An overview.")
        XCTAssertEqual(summary.summary, "A summary.")
    }

    func testOverlayPolicyCarriesWebThumbnailStatusChips() {
        let item = EntityThumbnail(
            id: UUID(),
            kind: .video,
            title: "Wanted Video",
            rating: 4,
            isNsfw: true,
            isWanted: true,
            wantedStatus: AcquisitionStatus(rawValue: "downloading")
        )

        let policy = EntityThumbnailOverlayPolicy(item: item)

        XCTAssertEqual(policy.topTrailing.map(\.kind), [.wanted, .nsfw])
        XCTAssertEqual(policy.topTrailing.first?.label, "Downloading")
        XCTAssertEqual(policy.bottomTrailing.map(\.kind), [.rating])
        XCTAssertEqual(policy.bottomTrailing.first?.label, "4")
    }

    func testOverlayPolicyOmitsZeroRating() {
        let item = EntityThumbnail(id: UUID(), kind: .movie, title: "Unrated", rating: 0)

        XCTAssertTrue(EntityThumbnailOverlayPolicy(item: item).bottomTrailing.isEmpty)
    }

    func testPosterArtworkKeepsStatusChipsVisible() {
        let item = EntityThumbnail(
            id: UUID(),
            kind: .movie,
            title: "Poster Movie",
            coverURL: "/poster.jpg",
            rating: 5,
            isNsfw: true,
            isWanted: true
        )

        let presentation = EntityThumbnailCardPresentation(item: item, layout: .grid)

        XCTAssertFalse(presentation.usesArtworkExtension)
        XCTAssertTrue(presentation.showsArtworkBadges)
    }

    func testRailWidthsPreserveAConsistentCardHeightAcrossThumbnailShapes() {
        let cardHeight = 216.0
        let presentations = [EntityKind.video, .movie, .collection, .person].map { kind in
            EntityThumbnailCardPresentation(
                item: EntityThumbnail(id: UUID(), kind: kind, title: kind.displayLabel),
                layout: .rail
            )
        }

        for presentation in presentations {
            let width = presentation.width(forCardHeight: cardHeight)

            XCTAssertEqual(width / presentation.cardAspectRatio, cardHeight, accuracy: 0.001)
        }
    }

    private func decodeThumbnail(descriptionMember: String) throws -> EntityThumbnail {
        let data = Data(
            """
            {
              "id": "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa",
              "kind": "video",
              "title": "Episode",
              \(descriptionMember)
            }
            """.utf8
        )
        return try PrismediaJSON.decoder().decode(EntityThumbnail.self, from: data)
    }
}
