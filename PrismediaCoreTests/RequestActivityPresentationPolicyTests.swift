import XCTest

@testable import PrismediaCore

final class RequestActivityPresentationPolicyTests: XCTestCase {
    func testUnknownAcquisitionStatusPollsAndLocksActions() {
        let status = AcquisitionStatus(rawValue: "future-state")

        XCTAssertTrue(RequestActivityStatusPolicy.shouldPoll(status))
        XCTAssertTrue(RequestActivityStatusPolicy.isTransitionLocked(status))
        XCTAssertNil(RequestActivityStatusPolicy.primaryAction(for: status, hasEntity: true))
        XCTAssertEqual(RequestActivityStatusPolicy.label(for: status), "Updating")
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

    func testDownloadFilterCombinesTextStatusKindAndSort() throws {
        let downloads = try PrismediaJSON.decoder().decode(
            [RequestActivityDownload].self,
            from: Data(downloadJSON.utf8)
        )
        let filter = RequestActivityDownloadFilter(
            query: "dune",
            status: .downloading,
            kind: .book,
            sort: .title
        )

        XCTAssertEqual(filter.apply(to: downloads).map(\.title), ["Dune"])
    }

    func testEmptyStateDistinguishesNoDataFromFilteredResults() {
        XCTAssertEqual(RequestActivityEmptyState.resolve(sourceCount: 0, visibleCount: 0), .empty)
        XCTAssertEqual(RequestActivityEmptyState.resolve(sourceCount: 2, visibleCount: 0), .filtered)
        XCTAssertNil(RequestActivityEmptyState.resolve(sourceCount: 2, visibleCount: 1))
    }

    func testPartialRemovalSummaryPreservesCountsAndReasons() {
        let summary = RequestActivityRemovalSummary(
            attempted: 3,
            failures: ["Dune: timed out"]
        )

        XCTAssertEqual(summary.succeeded, 2)
        XCTAssertEqual(summary.message, "Removed 2 of 3 downloads. Dune: timed out")
    }

    private let downloadJSON = """
        [
          {
            "acquisitionId": "11111111-1111-1111-1111-111111111111",
            "kind": "book",
            "title": "Dune",
            "status": "downloading",
            "progress": 0.4,
            "updatedAt": "2026-07-12T12:00:00Z"
          },
          {
            "acquisitionId": "22222222-2222-2222-2222-222222222222",
            "kind": "movie",
            "title": "Arrival",
            "status": "searching",
            "updatedAt": "2026-07-12T13:00:00Z"
          }
        ]
        """
}
