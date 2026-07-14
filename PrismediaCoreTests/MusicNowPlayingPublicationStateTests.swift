import XCTest

@testable import PrismediaCore

final class MusicNowPlayingPublicationStateTests: XCTestCase {
    func testArtworkIsRequestedOnceWhileTheCurrentTrackPublishesProgressUpdates() {
        let trackID = UUID()
        var state = MusicNowPlayingPublicationState()

        XCTAssertTrue(state.beginPublishing(trackID: trackID))
        XCTAssertFalse(state.beginPublishing(trackID: trackID))
        XCTAssertFalse(state.beginPublishing(trackID: trackID))
    }

    func testChangingOrClearingTheTrackRequiresFreshArtwork() {
        let firstTrackID = UUID()
        let secondTrackID = UUID()
        var state = MusicNowPlayingPublicationState()

        XCTAssertTrue(state.beginPublishing(trackID: firstTrackID))
        XCTAssertTrue(state.beginPublishing(trackID: secondTrackID))

        state.clear()

        XCTAssertTrue(state.beginPublishing(trackID: secondTrackID))
    }
}
