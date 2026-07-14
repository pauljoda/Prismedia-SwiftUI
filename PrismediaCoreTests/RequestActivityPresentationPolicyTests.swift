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
