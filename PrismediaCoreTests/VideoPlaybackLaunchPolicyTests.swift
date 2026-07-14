import XCTest

@testable import PrismediaCore

final class VideoPlaybackLaunchPolicyTests: XCTestCase {
    func testPlaybackIntentStartsAutomatically() {
        XCTAssertTrue(
            VideoPlaybackLaunchPolicy.shouldStartAutomatically(for: .playback)
        )
    }

    func testDetailAndMetadataIntentsWaitForAnExplicitPlayAction() {
        XCTAssertFalse(
            VideoPlaybackLaunchPolicy.shouldStartAutomatically(for: .detail)
        )
        XCTAssertFalse(
            VideoPlaybackLaunchPolicy.shouldStartAutomatically(for: .metadata)
        )
    }

    func testEpisodeThumbnailPlaybackUsesFullscreenOnlySeasonPresentation() {
        let seasonID = UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa")!
        let episode = EntityThumbnail(
            id: UUID(uuidString: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb")!,
            kind: .video,
            title: "Episode Seven",
            parentEntityID: seasonID,
            parentKind: .videoSeason,
            hasSourceMedia: true
        )

        let ownerLink = EntityLink(thumbnail: episode, intent: .playback)

        XCTAssertEqual(
            VideoPlaybackLaunchPolicy.presentationMode(for: ownerLink),
            .fullscreenOnly
        )
    }

    func testEpisodeDetailAndStandalonePlaybackKeepInlinePlayerPresentation() {
        let seasonID = UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa")!
        let episode = EntityThumbnail(
            id: UUID(uuidString: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb")!,
            kind: .video,
            title: "Episode Seven",
            parentEntityID: seasonID,
            parentKind: .videoSeason,
            hasSourceMedia: true
        )
        let standalone = EntityLink(
            entityID: UUID(uuidString: "cccccccc-cccc-cccc-cccc-cccccccccccc")!,
            kind: .video,
            intent: .playback
        )

        XCTAssertEqual(
            VideoPlaybackLaunchPolicy.presentationMode(
                for: EntityLink(thumbnail: episode, intent: .detail)
            ),
            .inline
        )
        XCTAssertEqual(
            VideoPlaybackLaunchPolicy.presentationMode(for: standalone),
            .inline
        )
    }
}
