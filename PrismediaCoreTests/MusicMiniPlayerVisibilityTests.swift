import XCTest

@testable import PrismediaCore

@MainActor
final class MusicMiniPlayerVisibilityTests: XCTestCase {
    func testVisibilityRemainsSuppressedUntilEveryImmersiveSurfaceIsGone() {
        let visibility = MusicMiniPlayerVisibility()
        let imageViewer = UUID()
        let videoPlayer = UUID()

        visibility.suppress(id: imageViewer)
        visibility.suppress(id: videoPlayer)
        visibility.restore(id: imageViewer)

        XCTAssertTrue(visibility.isSuppressed)

        visibility.restore(id: videoPlayer)

        XCTAssertFalse(visibility.isSuppressed)
    }

    func testRepeatedLifecycleEventsAreIdempotent() {
        let visibility = MusicMiniPlayerVisibility()
        let imageViewer = UUID()

        visibility.suppress(id: imageViewer)
        visibility.suppress(id: imageViewer)
        visibility.restore(id: imageViewer)
        visibility.restore(id: imageViewer)

        XCTAssertFalse(visibility.isSuppressed)
    }
}
