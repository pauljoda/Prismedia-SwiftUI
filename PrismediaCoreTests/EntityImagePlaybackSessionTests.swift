import XCTest

@testable import PrismediaCore

@MainActor
final class EntityImagePlaybackSessionTests: XCTestCase {
    func testOnlyTheActivePlaybackClaimCanBeAudible() {
        let session = EntityImagePlaybackSession()
        let firstClaimID = UUID()
        let secondClaimID = UUID()

        session.toggleMute()
        session.activate(UUID(), claimID: firstClaimID)

        XCTAssertFalse(session.isMuted(for: firstClaimID))
        XCTAssertTrue(session.isMuted(for: secondClaimID))

        session.activate(UUID(), claimID: secondClaimID)

        XCTAssertTrue(session.isMuted(for: firstClaimID))
        XCTAssertFalse(session.isMuted(for: secondClaimID))
    }

    func testARecycledRowCannotReleaseANewerPlaybackClaim() {
        let session = EntityImagePlaybackSession()
        let sharedEntityID = UUID()
        let recycledRowClaimID = UUID()
        let fullscreenClaimID = UUID()

        session.activate(sharedEntityID, claimID: recycledRowClaimID)
        session.activate(sharedEntityID, claimID: fullscreenClaimID)
        session.deactivate(sharedEntityID, claimID: recycledRowClaimID)

        XCTAssertEqual(session.activeEntityID, sharedEntityID)
        XCTAssertTrue(session.isMuted(for: recycledRowClaimID))
    }

    func testMuteControlTransfersAudibilityBeforeMutingTheActiveClaim() {
        let session = EntityImagePlaybackSession()
        let firstEntityID = UUID()
        let secondEntityID = UUID()
        let firstClaimID = UUID()
        let secondClaimID = UUID()

        session.toggleMute(entityID: firstEntityID, claimID: firstClaimID)
        XCTAssertFalse(session.isMuted(for: firstClaimID))

        session.toggleMute(entityID: secondEntityID, claimID: secondClaimID)
        XCTAssertTrue(session.isMuted(for: firstClaimID))
        XCTAssertFalse(session.isMuted(for: secondClaimID))
        XCTAssertEqual(session.activeEntityID, secondEntityID)

        session.toggleMute(entityID: secondEntityID, claimID: secondClaimID)
        XCTAssertTrue(session.isMuted)
        XCTAssertTrue(session.isMuted(for: secondClaimID))
    }
}
