import XCTest

@testable import PrismediaCore

final class EntityImageAutoplayPolicyTests: XCTestCase {
    func testVisibleMotionMediaAutoplays() {
        XCTAssertTrue(
            EntityImageAutoplayPolicy.shouldPlay(
                isVisible: true,
                isPausedByUser: false,
                reduceMotion: false,
                isSceneActive: true
            )
        )
    }

    func testUserPauseWinsWhenVisibilityChanges() {
        XCTAssertFalse(
            EntityImageAutoplayPolicy.shouldPlay(
                isVisible: true,
                isPausedByUser: true,
                reduceMotion: false,
                isSceneActive: true
            )
        )
    }

    func testReduceMotionAndInactiveScenesSuppressAutoplay() {
        XCTAssertFalse(
            EntityImageAutoplayPolicy.shouldPlay(
                isVisible: true,
                isPausedByUser: false,
                reduceMotion: true,
                isSceneActive: true
            )
        )
        XCTAssertFalse(
            EntityImageAutoplayPolicy.shouldPlay(
                isVisible: true,
                isPausedByUser: false,
                reduceMotion: false,
                isSceneActive: false
            )
        )
    }

    func testReduceMotionAllowsAnExplicitPlayRequest() {
        XCTAssertTrue(
            EntityImageAutoplayPolicy.shouldPlay(
                isVisible: true,
                isPausedByUser: false,
                reduceMotion: true,
                isSceneActive: true,
                isExplicitPlaybackRequested: true
            )
        )
    }

    func testOffscreenMediaNeverAutoplays() {
        XCTAssertFalse(
            EntityImageAutoplayPolicy.shouldPlay(
                isVisible: false,
                isPausedByUser: false,
                reduceMotion: false,
                isSceneActive: true
            )
        )
    }
}
