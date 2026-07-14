import XCTest

@testable import PrismediaCore

@MainActor
final class TVFullscreenPresentationPolicyTests: XCTestCase {
    func testEmbeddedNativePlayerDelegatesDismissalToSwiftUICover() {
        XCTAssertEqual(
            TVFullscreenPresentationPolicy.dismissalAction,
            .requestSwiftUICoverDismissal
        )
        XCTAssertFalse(TVFullscreenPresentationPolicy.playerControllerDismissesItself)
    }

    func testFullscreenPresentationAdoptsTheAutoAdvancedController() {
        let originalController = VideoPlaybackController(
            videoID: UUID(),
            service: VideoPlaybackPreviewService()
        )
        let advancedController = VideoPlaybackController(
            videoID: UUID(),
            service: VideoPlaybackPreviewService()
        )
        let presentation = TVFullscreenPlaybackPresentation(
            controller: originalController
        )
        let presentationID = presentation.id

        presentation.updateController(advancedController)

        XCTAssertEqual(presentation.id, presentationID)
        XCTAssertTrue(presentation.controller === advancedController)
        XCTAssertFalse(presentation.controller === originalController)
    }
}
