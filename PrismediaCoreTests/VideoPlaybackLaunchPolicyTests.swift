import XCTest

@testable import PrismediaCore

final class VideoPlaybackLaunchPolicyTests: XCTestCase {
    func testOnlyPlaybackIntentPreparesAutomatically() {
        XCTAssertTrue(VideoPlaybackLaunchPolicy.shouldPrepareAutomatically(for: .playback))
        XCTAssertFalse(VideoPlaybackLaunchPolicy.shouldPrepareAutomatically(for: .detail))
        XCTAssertFalse(VideoPlaybackLaunchPolicy.shouldPrepareAutomatically(for: .metadata))
    }

    func testTVPlaybackActionAutoplaysUnlessValidationExplicitlyPausesIt() {
        XCTAssertTrue(
            VideoPlaybackLaunchPolicy.shouldAutoPlayOnTV(
                isValidationPlaybackPaused: false
            ))
        XCTAssertFalse(
            VideoPlaybackLaunchPolicy.shouldAutoPlayOnTV(
                isValidationPlaybackPaused: true
            ))
    }

    func testFullscreenLaunchOnlyPausesForAValidResumeChoice() {
        XCTAssertTrue(VideoPlaybackLaunchPolicy.shouldAutoStartFullscreen(resumeSeconds: nil))
        XCTAssertTrue(VideoPlaybackLaunchPolicy.shouldAutoStartFullscreen(resumeSeconds: 0))
        XCTAssertTrue(VideoPlaybackLaunchPolicy.shouldAutoStartFullscreen(resumeSeconds: .infinity))
        XCTAssertFalse(VideoPlaybackLaunchPolicy.shouldAutoStartFullscreen(resumeSeconds: 84))
        XCTAssertTrue(VideoPlaybackLaunchPolicy.shouldOfferResumeChoice(resumeSeconds: 84))
    }

    func testSeasonEpisodePlaybackTransfersToFullscreenWithoutChangingOtherOwnership() {
        let seasonID = UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa")!
        let episode = EntityThumbnail(
            id: UUID(uuidString: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb")!,
            kind: .video,
            title: "Episode Seven",
            parentEntityID: seasonID,
            parentKind: .videoSeason,
            hasSourceMedia: true
        )
        let playback = EntityLink(thumbnail: episode, intent: .playback)
        let detail = EntityLink(thumbnail: episode, intent: .detail)
        let standalone = EntityLink(
            entityID: UUID(uuidString: "cccccccc-cccc-cccc-cccc-cccccccccccc")!,
            kind: .video,
            intent: .playback
        )

        XCTAssertEqual(VideoPlaybackLaunchPolicy.presentationMode(for: playback), .fullscreenOnly)
        XCTAssertEqual(VideoPlaybackLaunchPolicy.presentationMode(for: detail), .inline)
        XCTAssertEqual(VideoPlaybackLaunchPolicy.presentationMode(for: standalone), .inline)
    }
}
