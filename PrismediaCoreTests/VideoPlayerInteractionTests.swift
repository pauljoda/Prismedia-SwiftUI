import XCTest

@testable import PrismediaCore

final class VideoPlayerInteractionTests: XCTestCase {
    func testDetailMarkerOnlySeeksTheVideoOwnedByTheVisibleDetail() {
        let videoID = UUID()

        XCTAssertTrue(
            EntityMarkerSeekPolicy.canSeek(
                resolvedVideoID: videoID,
                activeVideoID: videoID
            )
        )
        XCTAssertFalse(
            EntityMarkerSeekPolicy.canSeek(
                resolvedVideoID: videoID,
                activeVideoID: UUID()
            )
        )
        XCTAssertFalse(
            EntityMarkerSeekPolicy.canSeek(
                resolvedVideoID: nil,
                activeVideoID: videoID
            )
        )
    }

    func testFilmstripLowerFrameLookupPreservesBoundarySemantics() {
        let frameStartTimes = [10.0, 20.0, 30.0]

        XCTAssertNil(
            VideoFilmstripLayout.lowerFrameIndex(
                at: 9,
                frames: frameStartTimes,
                startTime: { $0 }
            )
        )
        XCTAssertEqual(
            VideoFilmstripLayout.lowerFrameIndex(
                at: 20,
                frames: frameStartTimes,
                startTime: { $0 }
            ),
            1
        )
        XCTAssertEqual(
            VideoFilmstripLayout.lowerFrameIndex(
                at: 31,
                frames: frameStartTimes,
                startTime: { $0 }
            ),
            2
        )
        XCTAssertEqual(
            VideoFilmstripLayout.lowerFrameIndex(
                at: 20,
                frames: [10.0, 20.0, 20.0, 30.0],
                startTime: { $0 }
            ),
            2
        )
    }

    func testPlayerDoesNotUnlockBeforeCachedOptionsAndFilmstripAreReady() {
        XCTAssertFalse(
            VideoPlaybackReadiness.isInteractive(
                playerReady: true,
                optionsReady: false,
                filmstripReady: true
            ))
        XCTAssertTrue(
            VideoPlaybackReadiness.isInteractive(
                playerReady: true,
                optionsReady: true,
                filmstripReady: true
            ))
    }

    func testFreshDetailResumeOverridesThumbnailFallbackIncludingResetToZero() {
        XCTAssertEqual(
            VideoInitialResumePosition.resolve(
                detailResumeSeconds: 0,
                thumbnailResumeSeconds: 120
            ),
            0
        )
        XCTAssertEqual(
            VideoInitialResumePosition.resolve(
                detailResumeSeconds: nil,
                thumbnailResumeSeconds: 120
            ),
            120
        )
    }

    func testPageExitTransfersPlaybackOwnershipOnlyToIntentionalPictureInPicture() {
        XCTAssertFalse(
            VideoPlaybackPageExitPolicy.shouldReleasePlayback(
                pictureInPictureIsActiveOrStarting: true
            ))
        XCTAssertTrue(
            VideoPlaybackPageExitPolicy.shouldReleasePlayback(
                pictureInPictureIsActiveOrStarting: false
            ))
    }

    func testPausedScanEscalatesThroughSupportedRatesPerDirection() {
        XCTAssertEqual(
            VideoPlaybackScanPolicy.nextRate(
                currentSide: nil,
                currentRate: 2,
                direction: .right
            ),
            2
        )
        XCTAssertEqual(
            VideoPlaybackScanPolicy.nextRate(
                currentSide: .right,
                currentRate: 2,
                direction: .right
            ),
            4
        )
        XCTAssertEqual(
            VideoPlaybackScanPolicy.nextRate(
                currentSide: .right,
                currentRate: 4,
                direction: .right
            ),
            8
        )
        XCTAssertEqual(
            VideoPlaybackScanPolicy.nextRate(
                currentSide: .right,
                currentRate: 8,
                direction: .right
            ),
            16
        )
        XCTAssertEqual(
            VideoPlaybackScanPolicy.nextRate(
                currentSide: .right,
                currentRate: 16,
                direction: .right
            ),
            32
        )
        XCTAssertEqual(
            VideoPlaybackScanPolicy.nextRate(
                currentSide: .right,
                currentRate: 32,
                direction: .right
            ),
            32
        )
        XCTAssertEqual(
            VideoPlaybackScanPolicy.nextRate(
                currentSide: .right,
                currentRate: 8,
                direction: .left
            ),
            2
        )
    }

    func testScrubTranslationMovesPendingTimeAndClampsToRuntime() {
        XCTAssertEqual(
            VideoPlaybackScrubPolicy.targetTime(
                origin: 45,
                translation: 1_000,
                duration: 90
            ),
            49.5,
            accuracy: 0.001
        )
        XCTAssertEqual(
            VideoPlaybackScrubPolicy.targetTime(
                origin: 5,
                translation: -10_000,
                duration: 90
            ),
            0
        )
        XCTAssertEqual(
            VideoPlaybackScrubPolicy.targetTime(
                origin: 85,
                translation: 10_000,
                duration: 90
            ),
            90
        )
    }

    func testOnlyPlayingOrWaitingVideoNeedsVisiblePictureInPictureHandoff() {
        XCTAssertTrue(
            VideoPlaybackVisibilityPolicy.shouldEnterPictureInPicture(
                isPlaying: true,
                isWaiting: false,
                playerRate: 0
            ))
        XCTAssertTrue(
            VideoPlaybackVisibilityPolicy.shouldEnterPictureInPicture(
                isPlaying: false,
                isWaiting: true,
                playerRate: 0
            ))
        XCTAssertTrue(
            VideoPlaybackVisibilityPolicy.shouldEnterPictureInPicture(
                isPlaying: false,
                isWaiting: false,
                playerRate: 1
            ))
        XCTAssertFalse(
            VideoPlaybackVisibilityPolicy.shouldEnterPictureInPicture(
                isPlaying: false,
                isWaiting: false,
                playerRate: 0
            ))
    }

}
