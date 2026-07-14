import XCTest

@testable import PrismediaCore

final class SearchHubCatalogTests: XCTestCase {
    func testOverviewDoesNotDuplicateTheSearchDestination() {
        XCTAssertFalse(ModeCatalog.overview.destinations.contains { $0.id == "search" })
    }

    func testModeCardsExposeDestinationSubtitleAndPreferredArtworkKinds() {
        let expectedKinds: [String: [EntityKind]] = [
            "overview": [.movie, .videoSeries, .gallery, .audioLibrary, .book],
            "video": [.video, .movie, .videoSeries],
            "images": [.image, .gallery],
            "audio": [.audioLibrary, .musicArtist, .audioTrack],
            "books": [.book, .bookAuthor],
            "browse": [.collection, .person, .studio, .tag],
            "manage": [],
            "operate": [],
        ]

        for mode in ModeCatalog.all {
            let card = SearchHubCatalog.card(for: mode)

            XCTAssertEqual(card.mode, mode)
            XCTAssertEqual(card.title, mode.title)
            XCTAssertEqual(card.systemImage, mode.systemImage)
            XCTAssertEqual(card.subtitle, mode.destinations.map(\.title).joined(separator: " · "))
            XCTAssertEqual(card.preferredArtworkKinds, expectedKinds[mode.id])
        }
    }

    func testNavigationMatchForAlbumsTargetsAudioAlbums() throws {
        let target = try XCTUnwrap(SearchHubCatalog.navigationMatch(for: "Albums"))

        XCTAssertEqual(target.mode.id, "audio")
        XCTAssertEqual(target.destination.id, "albums")
    }

    func testMovieEntityKindTargetsVideoMovies() throws {
        let target = try XCTUnwrap(SearchHubCatalog.navigationTarget(for: .movie))

        XCTAssertEqual(target.mode.id, "video")
        XCTAssertEqual(target.destination.id, "movies")
    }

    func testResultRankingPlacesExactThenPrefixThenSubstringMatches() {
        let results = ["My Albums", "Albums Live", "Albums"]

        let ranked = SearchHubCatalog.rankedResults(results, query: "albums") { $0 }

        XCTAssertEqual(ranked, ["Albums", "Albums Live", "My Albums"])
    }

    func testResultRankingProjectsEachTitleOnlyOnce() {
        let results = (0..<128).map { "Album \(127 - $0)" }
        var projectionCount = 0

        _ = SearchHubCatalog.rankedResults(results, query: "album") { title in
            projectionCount += 1
            return title
        }

        XCTAssertEqual(projectionCount, results.count)
    }

    func testResultRankingPreservesInputOrderForEqualRanks() {
        let results = ["Albums Third", "Albums First", "Albums Second"]

        let ranked = SearchHubCatalog.rankedResults(results, query: "albums") { $0 }

        XCTAssertEqual(ranked, results)
    }

    func testSearchResultsGroupParentsBeforeLeafMedia() {
        let episode = thumbnail(kind: .video, title: "Pilot")
        let series = thumbnail(kind: .videoSeries, title: "The Expanse")
        let track = thumbnail(kind: .audioTrack, title: "Intro")
        let album = thumbnail(kind: .audioLibrary, title: "Signals")

        let groups = SearchHubCatalog.groupedResults(
            [episode, series, track, album],
            query: "i"
        )

        XCTAssertEqual(groups.map(\.kind), [.videoSeries, .audioLibrary, .video, .audioTrack])
    }

    func testExactLeafMatchFloatsAheadOfParentGroups() {
        let episode = thumbnail(kind: .video, title: "Pilot")
        let series = thumbnail(kind: .videoSeries, title: "Pilot Stories")

        let groups = SearchHubCatalog.groupedResults([series, episode], query: "Pilot")

        XCTAssertEqual(groups.map(\.kind), [.video, .videoSeries])
        XCTAssertEqual(groups.first?.items.map(\.title), ["Pilot"])
    }

    func testPreviewKindsFollowEachModesPrimaryDestination() {
        XCTAssertEqual(
            SearchHubCatalog.previewKinds,
            [.video, .image, .audioLibrary, .book, .collection]
        )
    }

    func testFallbackGradientIndexIsStableAndMatchesTheWebPaletteHash() {
        let first = StableStringHash.paletteIndex(for: "Amélie", paletteCount: 8)
        let second = StableStringHash.paletteIndex(for: "Amélie", paletteCount: 8)

        XCTAssertEqual(first, 3)
        XCTAssertEqual(second, first)
    }
}

private func thumbnail(kind: EntityKind, title: String) -> EntityThumbnail {
    EntityThumbnail(id: UUID(), kind: kind, title: title)
}
