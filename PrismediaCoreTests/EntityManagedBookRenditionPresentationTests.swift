import XCTest

@testable import PrismediaCore

final class EntityManagedBookRenditionPresentationTests: XCTestCase {
    func testWaitingAndCompletedRenditionsKeepIndependentManagerOwnership() {
        let waiting = presentation(phase: .awaitingFiles, tracking: .waitingForFiles)
        let completed = presentation(phase: .completed, tracking: .tracking)

        XCTAssertEqual(waiting.state, .waitingForFiles)
        XCTAssertEqual(completed.state, .completed)
        XCTAssertTrue(waiting.isManagerOwned)
        XCTAssertTrue(completed.isManagerOwned)
    }

    func testRemovedHoldingNeedsReviewUntilOwnershipIsReleased() {
        let removed = presentation(
            phase: .remoteRemoved,
            tracking: .removed,
            problem: "Exact remote holding disappeared"
        )
        let releasing = presentation(phase: .cancelled, tracking: .releasePending)
        let released = presentation(phase: .ownershipReleased, tracking: .released)

        XCTAssertEqual(removed.state, .needsReview)
        XCTAssertEqual(removed.reviewProblem, "Exact remote holding disappeared")
        XCTAssertTrue(removed.isManagerOwned)
        XCTAssertEqual(releasing.state, .releasing)
        XCTAssertTrue(releasing.isManagerOwned)
        XCTAssertEqual(released.state, .released)
        XCTAssertFalse(released.isManagerOwned)
    }

    func testRoutineWaitingExplanationIsNotPresentedAsAProblem() {
        let waiting = presentation(
            phase: .awaitingFiles,
            tracking: .waitingForFiles,
            problem: "Waiting for the manager to import this Book rendition."
        )

        XCTAssertNil(waiting.reviewProblem)
    }

    private func presentation(
        phase: EntityManagedRequestPhase,
        tracking: EntityManagedTrackingStatus,
        problem: String? = nil
    ) -> EntityManagedBookRenditionPresentation {
        let item = EntityManagedItemInput(
            entityKind: .book,
            remoteID: "review-work",
            expectedExternalIDs: [:],
            bookRendition: .ebook
        )
        let holding = EntityManagedHoldingReference(
            holdingID: UUID(),
            item: item,
            status: tracking
        )
        let request = EntityManagedRequestReference(
            requestID: UUID(),
            phase: phase,
            updatedAt: Date(),
            problem: problem
        )
        return EntityManagedBookRenditionPresentation(
            provenance: EntityExternalBookRenditionProvenance(
                rendition: .ebook,
                connectionID: UUID(),
                connectionName: "Review manager",
                pluginID: "fixture",
                libraryRootID: UUID(),
                libraryLabel: "Books",
                holding: holding,
                request: request
            )
        )
    }
}
