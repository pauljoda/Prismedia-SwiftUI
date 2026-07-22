import XCTest

@testable import PrismediaCore

final class EntityAcquisitionPanelStateTests: XCTestCase {
    func testMutationFailureKeepsContentAndPublishesError() {
        var state = EntityAcquisitionPanelState()
        state.finishLoad(.content(snapshot))

        XCTAssertTrue(state.beginMutation())
        let effect = state.finishMutation(.failure("Monitor is busy."))

        XCTAssertEqual(effect, .none)
        XCTAssertFalse(state.isMutating)
        XCTAssertEqual(state.mutationError, "Monitor is busy.")
        XCTAssertEqual(state.phase, .content(snapshot))
    }

    func testPrunedUnmonitorRequestsNavigationDismissal() {
        var state = EntityAcquisitionPanelState()

        XCTAssertTrue(state.beginMutation())
        XCTAssertFalse(state.beginMutation(), "A second command must not overlap the first")
        XCTAssertEqual(
            state.finishMutation(.completed(entityPruned: true)),
            .entityPruned
        )
    }

    func testFailedRefreshAfterSuccessfulMutationKeepsConfirmedContent() {
        var state = EntityAcquisitionPanelState()
        state.finishLoad(.content(snapshot))

        XCTAssertTrue(state.beginMutation())
        XCTAssertEqual(
            state.finishMutation(.completed(entityPruned: false)),
            .refresh
        )

        XCTAssertFalse(
            state.finishMutationRefresh(.failure("The server is unavailable."))
        )
        XCTAssertEqual(state.phase, .content(snapshot))
        XCTAssertEqual(state.refreshError, "The server is unavailable.")
    }

    func testSuccessfulRefreshClearsRefreshWarning() {
        var state = EntityAcquisitionPanelState()
        state.finishLoad(.content(snapshot))
        _ = state.finishMutationRefresh(.failure("The server is unavailable."))

        XCTAssertTrue(state.finishMutationRefresh(.content(snapshot)))
        XCTAssertNil(state.refreshError)
        XCTAssertEqual(state.phase, .content(snapshot))
    }

    private var snapshot: EntityAcquisitionPanelSnapshot {
        EntityAcquisitionPanelSnapshot(
            state: EntityMonitorState(
                entityID: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
                canMonitor: true,
                canRequest: true,
                trackableProviders: ["openlibrary"],
                discoversChildren: false,
                canSearchMissingChildren: false,
                missingChildEntityKind: nil,
                monitor: nil,
                latestAcquisition: nil
            ),
            latestAcquisition: nil
        )
    }
}
