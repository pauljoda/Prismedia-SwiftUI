import XCTest

@testable import PrismediaCore

final class RequestActivityPresentationPolicyTests: XCTestCase {
    func testUnknownAcquisitionStatusPollsAndLocksActions() {
        let status = AcquisitionStatus(rawValue: "future-state")

        XCTAssertTrue(RequestActivityStatusPolicy.shouldPoll(status))
        XCTAssertTrue(RequestActivityStatusPolicy.isTransitionLocked(status))
        XCTAssertNil(RequestActivityStatusPolicy.primaryAction(for: status, hasEntity: true))
    }

    func testDownloadPrimaryActionMatchesWebLifecycle() {
        XCTAssertEqual(
            RequestActivityStatusPolicy.primaryAction(
                for: AcquisitionStatus(rawValue: "awaiting-selection"),
                hasEntity: true
            ),
            .chooseRelease
        )
        XCTAssertEqual(
            RequestActivityStatusPolicy.primaryAction(
                for: AcquisitionStatus(rawValue: "failed"),
                hasEntity: false
            ),
            .searchAgain
        )
        XCTAssertEqual(
            RequestActivityStatusPolicy.primaryAction(
                for: AcquisitionStatus(rawValue: "downloading"),
                hasEntity: true
            ),
            .view
        )
    }

    func testEntityAcquisitionLifecycleUsesPreparingSearchBeforeIndexerWorkBegins() {
        let status = AcquisitionStatus(rawValue: "pending")

        XCTAssertEqual(
            RequestActivityAcquisitionLifecyclePolicy.label(for: status),
            "Preparing Search"
        )
        XCTAssertEqual(
            RequestActivityAcquisitionLifecyclePolicy.content(for: status),
            .preparingSearch
        )
        XCTAssertNil(
            RequestActivityAcquisitionLifecyclePolicy.primaryAction(
                for: status,
                hasResumableImport: false
            )
        )
        XCTAssertEqual(
            RequestActivityAcquisitionLifecyclePolicy.secondaryActions(
                for: status,
                hasResumableImport: false
            ),
            [.cancel]
        )
    }

    func testEntityAcquisitionLifecycleHidesCancelWhileImporting() {
        let status = AcquisitionStatus(rawValue: "importing")

        XCTAssertNil(
            RequestActivityAcquisitionLifecyclePolicy.primaryAction(
                for: status,
                hasResumableImport: true
            )
        )
        XCTAssertTrue(
            RequestActivityAcquisitionLifecyclePolicy.secondaryActions(
                for: status,
                hasResumableImport: true
            ).isEmpty
        )
    }

    func testEntityAcquisitionLifecycleSplitsFailedRecoveryByDurableImportState() {
        let status = AcquisitionStatus(rawValue: "failed")

        XCTAssertEqual(
            RequestActivityAcquisitionLifecyclePolicy.primaryAction(
                for: status,
                hasResumableImport: true
            ),
            .retryImport(allowFormatChange: false)
        )
        XCTAssertEqual(
            RequestActivityAcquisitionLifecyclePolicy.secondaryActions(
                for: status,
                hasResumableImport: true
            ),
            [.startOver]
        )
        XCTAssertEqual(
            RequestActivityAcquisitionLifecyclePolicy.primaryAction(
                for: status,
                hasResumableImport: false
            ),
            .research
        )
        XCTAssertTrue(
            RequestActivityAcquisitionLifecyclePolicy.secondaryActions(
                for: status,
                hasResumableImport: false
            ).isEmpty
        )
    }

    func testEntityAcquisitionLifecycleRevivesCancelledAttemptWithSearchAgain() {
        let status = AcquisitionStatus(rawValue: "cancelled")

        XCTAssertEqual(
            RequestActivityAcquisitionLifecyclePolicy.primaryAction(
                for: status,
                hasResumableImport: false
            ),
            .research
        )
        XCTAssertEqual(
            RequestActivityAcquisitionLifecyclePolicy.content(for: status),
            .lifecycleOnly
        )
    }

    func testEntityAcquisitionLifecycleLeavesAwaitingSelectionToDownstreamControls() {
        let status = AcquisitionStatus(rawValue: "awaiting-selection")

        XCTAssertNil(
            RequestActivityAcquisitionLifecyclePolicy.primaryAction(
                for: status,
                hasResumableImport: false
            )
        )
        XCTAssertEqual(
            RequestActivityAcquisitionLifecyclePolicy.secondaryActions(
                for: status,
                hasResumableImport: false
            ),
            [.research, .cancel]
        )
        XCTAssertEqual(
            RequestActivityAcquisitionLifecyclePolicy.content(for: status),
            .releases
        )
    }

    func testEntityAcquisitionRefreshWarningAppearsAfterThreeConsecutiveFailures() {
        var state = RequestActivityAcquisitionRefreshState()

        state.recordFailure()
        state.recordFailure()
        XCTAssertNil(state.message)

        state.recordFailure()
        XCTAssertEqual(
            state.message,
            "Live updates are failing. Prismedia will keep retrying in the background."
        )

        state.recordSuccess()
        XCTAssertNil(state.message)
        XCTAssertEqual(state.consecutiveFailures, 0)
    }

    func testEntityAcquisitionLifecycleKeepsCompletedAndUnknownStatesReadOnly() {
        let imported = AcquisitionStatus(rawValue: "imported")
        XCTAssertEqual(
            RequestActivityAcquisitionLifecyclePolicy.content(for: imported),
            .files
        )
        XCTAssertNil(
            RequestActivityAcquisitionLifecyclePolicy.primaryAction(
                for: imported,
                hasResumableImport: false
            )
        )
        XCTAssertTrue(
            RequestActivityAcquisitionLifecyclePolicy.secondaryActions(
                for: imported,
                hasResumableImport: false
            ).isEmpty
        )

        let unknown = AcquisitionStatus(rawValue: "future-state")
        XCTAssertEqual(
            RequestActivityAcquisitionLifecyclePolicy.content(for: unknown),
            .locked
        )
        XCTAssertNil(
            RequestActivityAcquisitionLifecyclePolicy.primaryAction(
                for: unknown,
                hasResumableImport: true
            )
        )
        XCTAssertTrue(
            RequestActivityAcquisitionLifecyclePolicy.secondaryActions(
                for: unknown,
                hasResumableImport: true
            ).isEmpty
        )
    }

    func testWantedTransitionsFailClosed() {
        XCTAssertTrue(
            RequestActivityWantedPolicy.isTransitionLocked(
                monitorStatus: .deletingFiles,
                acquisitionStatus: nil
            ))
        XCTAssertTrue(
            RequestActivityWantedPolicy.isTransitionLocked(
                monitorStatus: .active,
                acquisitionStatus: AcquisitionStatus(rawValue: "future-state")
            ))
        XCTAssertFalse(
            RequestActivityWantedPolicy.isTransitionLocked(
                monitorStatus: .active,
                acquisitionStatus: AcquisitionStatus(rawValue: "searching")
            ))
    }

}
