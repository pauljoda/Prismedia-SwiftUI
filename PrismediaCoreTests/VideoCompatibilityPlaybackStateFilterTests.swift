import XCTest

@testable import PrismediaCore

final class VideoCompatibilityPlaybackStateFilterTests: XCTestCase {
    func testFrequentTimelineCallbacksAreCoalescedToTheUIRefreshInterval() {
        var filter = VideoCompatibilityPlaybackStateFilter()
        let initial = VideoCompatibilityPlaybackState(
            currentTime: 10,
            duration: 120,
            isPlaying: true,
            isWaiting: false
        )

        XCTAssertEqual(filter.stateToPublish(initial, at: 0), initial)
        XCTAssertNil(
            filter.stateToPublish(
                VideoCompatibilityPlaybackState(
                    currentTime: 10.1,
                    duration: 120,
                    isPlaying: true,
                    isWaiting: false
                ),
                at: 0.1
            )
        )

        let refreshed = VideoCompatibilityPlaybackState(
            currentTime: 10.5,
            duration: 120,
            isPlaying: true,
            isWaiting: false
        )
        XCTAssertEqual(filter.stateToPublish(refreshed, at: 0.5), refreshed)
    }

    func testPlaybackStateChangesPublishWithoutWaitingForTimelineRefresh() {
        var filter = VideoCompatibilityPlaybackStateFilter()
        _ = filter.stateToPublish(
            VideoCompatibilityPlaybackState(
                currentTime: 10,
                duration: 120,
                isPlaying: true,
                isWaiting: false
            ),
            at: 0
        )
        let buffering = VideoCompatibilityPlaybackState(
            currentTime: 10.1,
            duration: 120,
            isPlaying: false,
            isWaiting: true
        )

        XCTAssertEqual(filter.stateToPublish(buffering, at: 0.1), buffering)
    }

    func testStaleCallbacksCannotRollBackAnInFlightSeek() {
        var filter = VideoCompatibilityPlaybackStateFilter()
        _ = filter.stateToPublish(
            VideoCompatibilityPlaybackState(
                currentTime: 10,
                duration: 120,
                isPlaying: true,
                isWaiting: false
            ),
            at: 0
        )

        filter.beginSeek(to: 80, at: 0.1)

        XCTAssertNil(
            filter.stateToPublish(
                VideoCompatibilityPlaybackState(
                    currentTime: 10.2,
                    duration: 120,
                    isPlaying: true,
                    isWaiting: false
                ),
                at: 0.2
            )
        )
        XCTAssertEqual(
            filter.stateToPublish(
                VideoCompatibilityPlaybackState(
                    currentTime: 10.3,
                    duration: 120,
                    isPlaying: false,
                    isWaiting: true
                ),
                at: 0.3
            ),
            VideoCompatibilityPlaybackState(
                currentTime: 80,
                duration: 120,
                isPlaying: false,
                isWaiting: true
            )
        )
    }

    func testSeekProtectionEndsWhenVLCReachesTheTarget() {
        var filter = VideoCompatibilityPlaybackStateFilter()
        _ = filter.stateToPublish(
            VideoCompatibilityPlaybackState(
                currentTime: 10,
                duration: 120,
                isPlaying: true,
                isWaiting: false
            ),
            at: 0
        )
        filter.beginSeek(to: 80, at: 0.1)

        let settled = VideoCompatibilityPlaybackState(
            currentTime: 79.5,
            duration: 120,
            isPlaying: false,
            isWaiting: true
        )
        XCTAssertEqual(filter.stateToPublish(settled, at: 0.3), settled)
    }
}
