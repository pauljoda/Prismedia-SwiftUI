import XCTest

@testable import PrismediaCore

final class EntityThumbnailInteractionPolicyTests: XCTestCase {
    func testPlayableEpisodeLandscapeStartsPlaybackAndKeepsDetailInTheMenu() {
        let item = EntityThumbnail(
            id: UUID(),
            kind: .video,
            title: "The Episode",
            parentKind: .videoSeason,
            coverURL: "/assets/episode.jpg",
            hasSourceMedia: true,
            resumeSeconds: 321
        )

        let policy = EntityThumbnailInteractionPolicy(item: item, layout: .grid)

        XCTAssertEqual(policy.primaryIntent, .playback)
        XCTAssertEqual(policy.primaryAccessibilityHint, "Resumes playback")
        XCTAssertTrue(policy.showsContextMenu)
        XCTAssertEqual(policy.detailActionLabel, "Go to Episode")
    }

    func testStandalonePlayableVideoUsesGenericDetailMenuLanguage() {
        let item = EntityThumbnail(
            id: UUID(),
            kind: .video,
            title: "A Clip",
            coverURL: "/assets/clip.jpg",
            hasSourceMedia: true
        )

        let policy = EntityThumbnailInteractionPolicy(item: item, layout: .wall)

        XCTAssertEqual(policy.primaryIntent, .playback)
        XCTAssertEqual(policy.primaryAccessibilityHint, "Starts playback")
        XCTAssertEqual(policy.detailActionLabel, "Go to Details")
    }

    func testUnplayableVideoAndNonVideoCardsKeepDetailNavigation() {
        let unavailableVideo = EntityThumbnail(
            id: UUID(),
            kind: .video,
            title: "Unavailable"
        )
        let book = EntityThumbnail(
            id: UUID(),
            kind: .book,
            title: "A Book",
            hasSourceMedia: true
        )

        for item in [unavailableVideo, book] {
            let policy = EntityThumbnailInteractionPolicy(item: item, layout: .grid)

            XCTAssertEqual(policy.primaryIntent, .detail)
            XCTAssertEqual(policy.primaryAccessibilityHint, "Opens details")
            XCTAssertFalse(policy.showsContextMenu)
        }
    }

    func testListVideoKeepsDetailNavigationInsteadOfChangingRowBehavior() {
        let item = EntityThumbnail(
            id: UUID(),
            kind: .video,
            title: "A Clip",
            hasSourceMedia: true
        )

        let policy = EntityThumbnailInteractionPolicy(item: item, layout: .list)

        XCTAssertEqual(policy.primaryIntent, .detail)
        XCTAssertFalse(policy.showsContextMenu)
    }
}
