import XCTest

@testable import PrismediaCore

@MainActor
final class MusicMiniPlayerVisibilityTests: XCTestCase {
    func testUserDismissalHidesPlayerUntilPlaybackActivityRevealsIt() {
        let visibility = MusicMiniPlayerVisibility()

        visibility.hideByUser()

        XCTAssertTrue(visibility.isSuppressed)

        visibility.revealForPlaybackActivity()

        XCTAssertFalse(visibility.isSuppressed)
    }

    func testRestoringASurfaceDoesNotOverrideUserDismissal() {
        let visibility = MusicMiniPlayerVisibility()
        let surfaceID = UUID()
        visibility.suppress(id: surfaceID)
        visibility.hideByUser()

        visibility.restore(id: surfaceID)

        XCTAssertTrue(visibility.isSuppressed)
    }
}
