import XCTest

@testable import PrismediaCore

final class EntityMonitorPresentationTests: XCTestCase {
    private let entityID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
    private let monitorID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!

    func testLoadingAndUnknownStatusesAreIndeterminate() {
        XCTAssertNil(
            EntityMonitorPresentation(
                state: nil,
                isMutating: false,
                pendingValue: nil
            ).isOn
        )

        let presentation = EntityMonitorPresentation(
            state: state(status: EntityMonitorStatus(rawValue: "future-state")),
            isMutating: false,
            pendingValue: nil
        )

        XCTAssertNil(presentation.isOn)
        XCTAssertFalse(presentation.isEnabled)
        XCTAssertFalse(presentation.showsExpandedContent)
    }

    func testPausedAndFulfilledMonitorsCanBeResumed() {
        for status in [EntityMonitorStatus.paused, .fulfilled] {
            let presentation = EntityMonitorPresentation(
                state: state(status: status),
                isMutating: false,
                pendingValue: nil
            )

            XCTAssertEqual(presentation.isOn, false)
            XCTAssertTrue(presentation.isEnabled)
            XCTAssertFalse(presentation.showsExpandedContent)
        }
    }

    func testDeletingFilesIsLockedOnAndStoppingCanRetryCleanup() {
        let deleting = EntityMonitorPresentation(
            state: state(status: .deletingFiles),
            isMutating: false,
            pendingValue: nil
        )
        XCTAssertEqual(deleting.isOn, true)
        XCTAssertFalse(deleting.isEnabled)
        XCTAssertTrue(deleting.showsExpandedContent)

        let stopping = EntityMonitorPresentation(
            state: state(status: .stopping),
            isMutating: false,
            pendingValue: nil
        )
        XCTAssertEqual(stopping.isOn, false)
        XCTAssertFalse(stopping.isEnabled)
        XCTAssertTrue(stopping.canRetryCleanup)
    }

    func testPendingMutationIsOptimisticAndLocked() {
        let presentation = EntityMonitorPresentation(
            state: state(status: nil),
            isMutating: true,
            pendingValue: true
        )

        XCTAssertEqual(presentation.isOn, true)
        XCTAssertTrue(presentation.isBusy)
        XCTAssertFalse(presentation.isEnabled)
        XCTAssertFalse(presentation.showsExpandedContent)
    }

    func testUnavailableMonitorIsAVisibleDisabledOffState() {
        let presentation = EntityMonitorPresentation(
            state: state(status: nil, canMonitor: false),
            isMutating: false,
            pendingValue: nil
        )

        XCTAssertEqual(presentation.isOn, false)
        XCTAssertFalse(presentation.isEnabled)
    }

    private func state(
        status: EntityMonitorStatus?,
        canMonitor: Bool = true
    ) -> EntityMonitorState {
        EntityMonitorState(
            entityID: entityID,
            canMonitor: canMonitor,
            canRequest: true,
            trackableProviders: ["TMDB"],
            discoversChildren: true,
            canSearchMissingChildren: true,
            missingChildEntityKind: .video,
            monitor: status.map(monitor(status:)),
            latestAcquisition: nil
        )
    }

    private func monitor(status: EntityMonitorStatus) -> EntityMonitor {
        EntityMonitor(
            id: monitorID,
            kind: .videoSeason,
            acquisitionID: nil,
            status: status,
            title: "Season 15",
            author: nil,
            acquisitionStatus: nil,
            createdAt: Date(timeIntervalSince1970: 0),
            updatedAt: Date(timeIntervalSince1970: 0),
            entityID: entityID,
            preset: "all"
        )
    }
}
