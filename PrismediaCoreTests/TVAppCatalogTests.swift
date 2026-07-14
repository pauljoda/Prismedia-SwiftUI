import Foundation
import XCTest

@testable import PrismediaCore

final class TVAppCatalogTests: XCTestCase {
    func testTVCatalogHasNoManageDestinations() {
        let manageDestinationIDs = Set(["files", "identify", "request"])

        XCTAssertTrue(manageDestinationIDs.isDisjoint(with: TVAppCatalog.tabs.map(\.id)))
    }

    func testTVShellDoesNotReferenceManageRoutingTypes() throws {
        let repositoryRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let shellSource = try String(
            contentsOf: repositoryRoot.appending(path: "PrismediaShared/App/Shell/PrismediaTVShellView.swift"),
            encoding: .utf8
        )

        XCTAssertFalse(shellSource.contains("ManageDestination"))
        XCTAssertFalse(shellSource.contains("ManageDestinationView"))
    }

    func testManageTypesAreCompileGatedAwayFromTVOS() throws {
        let repositoryRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let paths = [
            "PrismediaShared/Domain/Navigation/ManageDestination.swift",
            "PrismediaShared/Features/Manage/ManageDestinationView.swift",
        ]

        for path in paths {
            let source = try String(contentsOf: repositoryRoot.appending(path: path), encoding: .utf8)
            XCTAssertTrue(source.contains("#if os(iOS) || os(macOS)"), "\(path) must exclude tvOS at compile time.")
        }
    }

    func testTVShellContainsTheScopedBrowseAndDedicatedSearchDestinations() {
        XCTAssertEqual(
            TVAppCatalog.tabs.map(\.id),
            ["home", "movies", "series", "collections", "search"]
        )

        let search = TVAppCatalog.tabs.first { $0.id == "search" }
        XCTAssertEqual(search?.query?.kinds, [.movie, .videoSeries, .collection])
    }

    func testHomeShelvesMatchTheWebsiteActivityAndLibraryQueries() {
        XCTAssertEqual(
            TVAppCatalog.homeShelves,
            [
                TVHomeShelf(
                    id: "in-progress",
                    title: "Continue Watching",
                    systemImage: "play.circle",
                    query: EntityListQuery(
                        kinds: [.movie, .video, .videoSeries, .videoSeason],
                        sort: "last-played",
                        status: "in-progress"
                    ),
                    limit: 20
                ),
                TVHomeShelf(
                    id: "recently-watched",
                    title: "Recently Watched",
                    systemImage: "clock.arrow.circlepath",
                    query: EntityListQuery(
                        kinds: [.movie, .video, .videoSeries, .videoSeason],
                        sort: "last-played",
                        status: "watched"
                    ),
                    limit: 20
                ),
                TVHomeShelf(
                    id: "movies",
                    title: "Recently Added Movies",
                    systemImage: "movieclapper",
                    query: EntityListQuery(kind: .movie, sort: "added"),
                    limit: 20,
                    destinationTabID: "movies"
                ),
                TVHomeShelf(
                    id: "series",
                    title: "Recently Added Series",
                    systemImage: "rectangle.stack",
                    query: EntityListQuery(kind: .videoSeries, sort: "added"),
                    limit: 20,
                    destinationTabID: "series"
                ),
            ]
        )
    }

    func testTheMostRecentInProgressItemBecomesTheHeroAndIsRemovedFromItsRail() {
        let first = PrismediaPreviewData.videos[0]
        let second = PrismediaPreviewData.videos[1]
        let snapshot = TVHomeSnapshot(
            itemsByShelfID: ["in-progress": [first, second]]
        )

        XCTAssertEqual(snapshot.hero?.id, first.id)
        XCTAssertEqual(snapshot.items(for: "in-progress").map(\.id), [second.id])
    }

    func testHeroCarouselFillsFromMoviesAndSeriesWithoutDuplicates() {
        let inProgress = PrismediaPreviewData.videos[0]
        let movie = EntityThumbnail(id: UUID(), kind: .movie, title: "Movie")
        let series = EntityThumbnail(id: UUID(), kind: .videoSeries, title: "Series")
        let snapshot = TVHomeSnapshot(
            itemsByShelfID: [
                "in-progress": [inProgress],
                "movies": [inProgress, movie],
                "series": [series],
            ]
        )

        XCTAssertEqual(snapshot.heroItems.map(\.id), [inProgress.id, movie.id, series.id])
    }

    func testTVPlaybackOffersResumeOnlyWhenThereIsMeaningfulProgress() {
        XCTAssertEqual(TVPlaybackOptions(resumeSeconds: 0).actions, [.play])
        XCTAssertEqual(
            TVPlaybackOptions(resumeSeconds: 321).actions,
            [.resume(seconds: 321), .playFromBeginning]
        )
    }

    func testAutomaticTVPlaybackResumesProgressOtherwiseStartsNormally() {
        XCTAssertEqual(TVPlaybackOptions(resumeSeconds: 0).automaticAction, .play)
        XCTAssertEqual(
            TVPlaybackOptions(resumeSeconds: 321).automaticAction,
            .resume(seconds: 321)
        )
    }

    func testActivityShelvesExcludeNonVideoLibraryHistory() {
        let activityShelf = TVAppCatalog.homeShelves.first { $0.id == "in-progress" }!
        let book = EntityThumbnail(id: UUID(), kind: .book, title: "A Book")

        XCTAssertTrue(activityShelf.accepts(PrismediaPreviewData.videos[0]))
        XCTAssertFalse(activityShelf.accepts(book))
    }

    func testActivityShelvesRequestVideoKindsAtTheAPIBoundary() {
        let activityShelf = TVAppCatalog.homeShelves.first { $0.id == "in-progress" }!
        let kindValue = activityShelf.query.queryItems(limit: 20, search: nil)
            .first { $0.name == "kind" }?.value

        XCTAssertEqual(kindValue, "movie,video,video-series,video-season")
    }
}
