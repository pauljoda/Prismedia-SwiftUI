import SwiftUI
import XCTest

@testable import PrismediaCore

final class EntityThumbnailCardPresentationTests: XCTestCase {
    @MainActor
    func testShortAndLongEpisodeDescriptionsRenderAtTheSameCardSize() throws {
        let short = try renderedCard(
            thumbnail(title: "Episode One", summary: "Short.")
        )
        let long = try renderedCard(
            thumbnail(
                title: "Episode Two with a Longer Title",
                summary: String(repeating: "A long description with more context. ", count: 20)
            )
        )

        XCTAssertEqual(short.width, 300)
        XCTAssertEqual(short.height, 250)
        XCTAssertEqual(long.width, short.width)
        XCTAssertEqual(long.height, short.height)
    }

    func testLandscapeVideoUsesOneStableExtendedArtworkGeometry() {
        let short = thumbnail(
            title: "Episode One",
            summary: "A short description."
        )
        let long = thumbnail(
            title: "Episode Two",
            summary: String(repeating: "A much longer episode description. ", count: 12)
        )

        let shortPresentation = EntityThumbnailCardPresentation(item: short, layout: .grid)
        let longPresentation = EntityThumbnailCardPresentation(item: long, layout: .grid)

        XCTAssertTrue(shortPresentation.usesArtworkExtension)
        XCTAssertEqual(shortPresentation.cardAspectRatio, 6.0 / 5.0)
        XCTAssertEqual(longPresentation.cardAspectRatio, shortPresentation.cardAspectRatio)
    }

    func testRealPosterLetsArtworkStandAloneWithoutAnExternalTitle() {
        let item = EntityThumbnail(
            id: UUID(),
            kind: .movie,
            title: "The Feature",
            coverURL: "/assets/feature.jpg"
        )

        let presentation = EntityThumbnailCardPresentation(item: item, layout: .grid)

        XCTAssertFalse(presentation.usesArtworkExtension)
        XCTAssertFalse(presentation.showsTitleOverlay)
        XCTAssertFalse(presentation.showsArtworkBadges)
        XCTAssertEqual(presentation.cardAspectRatio, 2.0 / 3.0)
    }

    func testMissingPosterKeepsTheTitleInsideTheFallbackArtwork() {
        let item = EntityThumbnail(
            id: UUID(),
            kind: .book,
            title: "Uncovered Book"
        )

        let presentation = EntityThumbnailCardPresentation(item: item, layout: .rail)

        XCTAssertFalse(presentation.usesArtworkExtension)
        XCTAssertTrue(presentation.showsTitleOverlay)
        XCTAssertTrue(presentation.showsArtworkBadges)
    }

    func testArtworkBackedTaxonomyAndCollectionCardsKeepTheirTitlesOnTheCard() {
        let identifyingKinds: [EntityKind] = [.person, .studio, .tag, .collection]
        let cardLayouts: [EntityThumbnailLayout] = [.grid, .rail, .wall, .mediaOnly, .feed]

        for kind in identifyingKinds {
            let item = EntityThumbnail(
                id: UUID(),
                kind: kind,
                title: "Identifying title",
                coverURL: "/assets/identifying-artwork.jpg"
            )

            for layout in cardLayouts {
                let presentation = EntityThumbnailCardPresentation(item: item, layout: layout)

                XCTAssertTrue(
                    presentation.usesArtworkExtension || presentation.showsTitleOverlay,
                    "\(kind.rawValue) cards must remain identifiable in \(layout) when artwork is present"
                )
            }
        }
    }

    func testListAndMediaOnlyLayoutsKeepTheirExistingPresentationKinds() {
        let item = thumbnail(title: "Episode", summary: nil)

        XCTAssertFalse(
            EntityThumbnailCardPresentation(item: item, layout: .list).usesArtworkExtension
        )
        XCTAssertFalse(
            EntityThumbnailCardPresentation(item: item, layout: .mediaOnly).usesArtworkExtension
        )
    }

    func testThumbnailDecodesConciseDescriptionFromExistingServerNames() throws {
        let description = try decodeThumbnail(descriptionMember: #""description":"A description.""#)
        let overview = try decodeThumbnail(descriptionMember: #""overview":"An overview.""#)
        let summary = try decodeThumbnail(descriptionMember: #""summary":"A summary.""#)

        XCTAssertEqual(description.summary, "A description.")
        XCTAssertEqual(overview.summary, "An overview.")
        XCTAssertEqual(summary.summary, "A summary.")
    }

    private func thumbnail(title: String, summary: String?) -> EntityThumbnail {
        EntityThumbnail(
            id: UUID(),
            kind: .video,
            title: title,
            summary: summary,
            coverURL: "/assets/episode.jpg",
            hasSourceMedia: true
        )
    }

    @MainActor
    private func renderedCard(_ item: EntityThumbnail) throws -> CGImage {
        let view = EntityThumbnailCardView(item: item, layout: .grid)
            .frame(width: 300)
            .environment(PrismediaPreviewData.model())
        let renderer = ImageRenderer(content: view)
        renderer.scale = 1
        return try XCTUnwrap(renderer.cgImage)
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
