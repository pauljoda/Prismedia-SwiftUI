import XCTest

@testable import PrismediaCore

final class VideoRenderReadinessPolicyTests: XCTestCase {
    func testPlayingVideoThatAdvancesWithoutRenderingNeedsRecoveryAfterDeadline() {
        XCTAssertTrue(
            VideoRenderReadinessPolicy.shouldRecover(
                isSurfaceAttached: true,
                isReadyForDisplay: false,
                isPlaying: true,
                isWaiting: false,
                playbackAdvance: 1.5
            )
        )
    }

    func testBufferingOrDetachedVideoDoesNotTriggerBlackFrameRecovery() {
        XCTAssertFalse(
            VideoRenderReadinessPolicy.shouldRecover(
                isSurfaceAttached: true,
                isReadyForDisplay: false,
                isPlaying: false,
                isWaiting: true,
                playbackAdvance: 0
            )
        )
        XCTAssertFalse(
            VideoRenderReadinessPolicy.shouldRecover(
                isSurfaceAttached: false,
                isReadyForDisplay: false,
                isPlaying: true,
                isWaiting: false,
                playbackAdvance: 2
            )
        )
    }

    func testRenderedVideoDoesNotTriggerRecovery() {
        XCTAssertFalse(
            VideoRenderReadinessPolicy.shouldRecover(
                isSurfaceAttached: true,
                isReadyForDisplay: true,
                isPlaying: true,
                isWaiting: false,
                playbackAdvance: 2
            )
        )
    }
}
