import XCTest

@testable import PrismediaCore

final class DashboardHeroPresentationTests: XCTestCase {
    func testHeroStartsOnPosterAndDeduplicatesPreviewScenes() {
        let item = EntityThumbnail(
            id: UUID(),
            kind: .movie,
            title: "Arrival",
            coverURL: "/art/arrival-poster.jpg",
            hoverImages: [
                hoverImage(path: "/art/arrival-poster.jpg"),
                hoverImage(path: "/art/arrival-scene-one.jpg"),
                hoverImage(path: "/art/arrival-scene-one.jpg"),
                hoverImage(path: "/art/arrival-scene-two.jpg"),
            ],
            meta: [
                EntityThumbnailMeta(icon: "calendar", label: "2016"),
                EntityThumbnailMeta(icon: "duration", label: "1h 56m"),
            ],
            genres: ["Science Fiction"]
        )

        let presentation = DashboardHeroPresentation(item: item)

        XCTAssertEqual(
            presentation.scenePaths,
            [
                "/art/arrival-poster.jpg",
                "/art/arrival-scene-one.jpg",
                "/art/arrival-scene-two.jpg",
            ]
        )
        XCTAssertEqual(presentation.metadataChips, ["Movie", "Science Fiction", "2016"])
    }

    func testHeroPlayAndDetailsUseDistinctNavigationIntents() {
        let item = EntityThumbnail(
            id: UUID(),
            kind: .video,
            title: "The Signal",
            progress: 0.42,
            resumeSeconds: 312
        )

        let presentation = DashboardHeroPresentation(item: item)

        XCTAssertEqual(presentation.primaryActionTitle, "Resume")
        XCTAssertEqual(presentation.playLink.intent, .playback)
        XCTAssertEqual(presentation.detailsLink.intent, .detail)
    }

    func testSpritePlaylistIsKeptSeparateFromImageScenePaths() {
        let item = EntityThumbnail(
            id: UUID(),
            kind: .video,
            title: "The Signal",
            coverURL: "/art/poster.jpg",
            hoverKind: .trickplay,
            hoverURL: "/api/trickplay/index.vtt",
            hasSourceMedia: true
        )

        let presentation = DashboardHeroPresentation(item: item)

        XCTAssertEqual(presentation.scenePaths, ["/art/poster.jpg"])
        XCTAssertEqual(presentation.trickplayPlaylistPath, "/api/trickplay/index.vtt")
    }

    func testReducedMotionKeepsTheCurrentHeroSceneStatic() {
        let current = DashboardHeroPosition(itemIndex: 1, sceneIndex: 2)

        let next = DashboardHeroAdvancePolicy.next(
            from: current,
            sceneCounts: [2, 4, 1],
            reduceMotion: true
        )

        XCTAssertEqual(next, current)
    }

    func testHeroAdvanceMovesThroughScenesThenWrapsToTheNextItem() {
        XCTAssertEqual(
            DashboardHeroAdvancePolicy.next(
                from: DashboardHeroPosition(itemIndex: 0, sceneIndex: 0),
                sceneCounts: [2, 1],
                reduceMotion: false
            ),
            DashboardHeroPosition(itemIndex: 0, sceneIndex: 1)
        )
        XCTAssertEqual(
            DashboardHeroAdvancePolicy.next(
                from: DashboardHeroPosition(itemIndex: 0, sceneIndex: 1),
                sceneCounts: [2, 1],
                reduceMotion: false
            ),
            DashboardHeroPosition(itemIndex: 1, sceneIndex: 0)
        )
        XCTAssertEqual(
            DashboardHeroAdvancePolicy.next(
                from: DashboardHeroPosition(itemIndex: 1, sceneIndex: 0),
                sceneCounts: [2, 1],
                reduceMotion: false
            ),
            DashboardHeroPosition(itemIndex: 0, sceneIndex: 0)
        )
    }

    func testManualHeroPagingMovesForwardAndBackwardWithoutLeavingTheCarousel() {
        XCTAssertEqual(DashboardHeroPagingPolicy.nextIndex(from: 0, itemCount: 3), 1)
        XCTAssertEqual(DashboardHeroPagingPolicy.nextIndex(from: 2, itemCount: 3), 2)
        XCTAssertEqual(DashboardHeroPagingPolicy.previousIndex(from: 2, itemCount: 3), 1)
        XCTAssertEqual(DashboardHeroPagingPolicy.previousIndex(from: 0, itemCount: 3), 0)
    }

    private func hoverImage(path: String) -> EntityThumbnailHoverImage {
        EntityThumbnailHoverImage(entityID: nil, title: "Scene", path: path)
    }
}
