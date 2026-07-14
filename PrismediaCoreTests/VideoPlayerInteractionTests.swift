import CoreGraphics
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

    func testDoubleTapRegionsSplitThePlayerIntoLeftAndRightHalves() {
        XCTAssertEqual(VideoPlayerGesturePolicy.side(at: 99, width: 200), .left)
        XCTAssertEqual(VideoPlayerGesturePolicy.side(at: 101, width: 200), .right)
    }

    func testOnlyAConfidentDownwardSwipeDismissesFullscreen() {
        XCTAssertTrue(VideoPlayerGesturePolicy.shouldDismissFullscreen(translation: .init(width: 12, height: 88)))
        XCTAssertFalse(VideoPlayerGesturePolicy.shouldDismissFullscreen(translation: .init(width: 90, height: 88)))
        XCTAssertFalse(VideoPlayerGesturePolicy.shouldDismissFullscreen(translation: .init(width: 0, height: -88)))
    }

    func testPlaybackSpeedChoicesIncludeNaturalAndAccessibilityRates() {
        XCTAssertEqual(VideoPlaybackSettings.availableRates, [0.5, 0.75, 1, 1.25, 1.5, 2])
        XCTAssertEqual(VideoPlaybackSettings.label(for: 1), "Normal")
        XCTAssertEqual(VideoPlaybackSettings.label(for: 1.5), "1.5×")
    }

    func testOpenPlaybackOptionsPreventChromeAutoHide() {
        XCTAssertFalse(VideoPlayerChromePolicy.shouldAutoHide(isPlaying: true, optionsPresented: true))
        XCTAssertTrue(VideoPlayerChromePolicy.shouldAutoHide(isPlaying: true, optionsPresented: false))
        XCTAssertFalse(VideoPlayerChromePolicy.shouldAutoHide(isPlaying: false, optionsPresented: false))
    }

    func testFilmstripProjectionUsesPredictedDragAndClampsToDuration() {
        XCTAssertEqual(
            VideoFilmstripLayout.projectedTime(
                from: 50,
                predictedTranslation: -100,
                trackWidth: 1_000,
                duration: 100
            ),
            60
        )
        XCTAssertEqual(
            VideoFilmstripLayout.projectedTime(
                from: 95,
                predictedTranslation: -500,
                trackWidth: 1_000,
                duration: 100
            ),
            100
        )
    }

    func testFilmstripLowerFrameLookupIsLogarithmicForTenThousandFrames() {
        let frameStartTimes = (0..<10_000).map(Double.init)
        var projectionCount = 0

        let index = VideoFilmstripLayout.lowerFrameIndex(
            at: 5_678.5,
            frames: frameStartTimes
        ) { startTime in
            projectionCount += 1
            return startTime
        }

        XCTAssertEqual(index, 5_678)
        XCTAssertLessThanOrEqual(projectionCount, 15)
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

    func testLandscapeFallbackOnlyRotatesAPortraitCanvas() {
        XCTAssertTrue(VideoFullscreenLayout.shouldRotateFallback(enabled: true, width: 390, height: 844))
        XCTAssertFalse(VideoFullscreenLayout.shouldRotateFallback(enabled: true, width: 844, height: 390))
        XCTAssertFalse(VideoFullscreenLayout.shouldRotateFallback(enabled: false, width: 390, height: 844))
    }

    func testFullscreenForcesLandscapeOnlyOnIPhone() {
        XCTAssertTrue(VideoFullscreenOrientationPolicy.forcesLandscape(isPad: false))
        XCTAssertFalse(VideoFullscreenOrientationPolicy.forcesLandscape(isPad: true))
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

    func testBottomChromeUsesBalancedVisualAndHitSizes() {
        XCTAssertEqual(VideoPlayerControlMetrics.bottomVisualWidth, 34)
        XCTAssertEqual(VideoPlayerControlMetrics.bottomVisualHeight, 30)
        XCTAssertEqual(VideoPlayerControlMetrics.bottomHitSize, 44)
    }

    func testPlaybackTimelineAccessibilityAdjustsByTenSecondsAndClampsToDuration() {
        XCTAssertEqual(
            VideoPlaybackTimelineAccessibility.adjustedTime(
                from: 25,
                duration: 100,
                incrementing: true
            ),
            35
        )
        XCTAssertEqual(
            VideoPlaybackTimelineAccessibility.adjustedTime(
                from: 95,
                duration: 100,
                incrementing: true
            ),
            100
        )
        XCTAssertEqual(
            VideoPlaybackTimelineAccessibility.adjustedTime(
                from: 5,
                duration: 100,
                incrementing: false
            ),
            0
        )
    }

    func testPlaybackTimelineAccessibilityDescribesCurrentAndTotalTime() {
        XCTAssertEqual(
            VideoPlaybackTimelineAccessibility.value(currentTime: 65, duration: 120),
            "1:05 of 2:00"
        )
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
