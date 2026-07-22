import XCTest

@testable import PrismediaCore

final class EntityChildMonitoringItemTests: XCTestCase {
    private let entityID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
    private let monitorID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!

    func testNewWantedChildStartsThroughRequestFlow() {
        let item = makeItem(status: nil, canMonitor: true, canRequest: true)

        XCTAssertEqual(item.command(to: true), .searchForRelease(entityID))
    }

    func testPausedAndFulfilledChildResumeExistingMonitor() {
        for status in [EntityMonitorStatus.paused, .fulfilled] {
            XCTAssertEqual(
                makeItem(status: status).command(to: true),
                .resume(monitorID)
            )
        }
    }

    func testActiveChildCanUnmonitorButLockedStatesCannotMutate() {
        XCTAssertEqual(
            makeItem(status: .active).command(to: false),
            .unmonitor(monitorID)
        )
        XCTAssertNil(makeItem(status: .deletingFiles).command(to: false))
        XCTAssertNil(makeItem(status: .stopping).command(to: true))
        XCTAssertNil(
            makeItem(status: EntityMonitorStatus(rawValue: "future-state"))
                .command(to: false)
        )
    }

    func testStoppingChildOffersCleanupRetry() {
        let item = makeItem(status: .stopping)

        XCTAssertTrue(item.canRetryCleanup)
        XCTAssertEqual(item.cleanupCommand, .unmonitor(monitorID))
    }

    private func makeItem(
        status: EntityMonitorStatus?,
        canMonitor: Bool = true,
        canRequest: Bool = true
    ) -> EntityChildMonitoringItem {
        EntityChildMonitoringItem(
            entity: EntityThumbnail(
                id: entityID,
                kind: .video,
                title: "Episode 1",
                isWanted: true
            ),
            state: EntityMonitorState(
                entityID: entityID,
                canMonitor: canMonitor,
                canRequest: canRequest,
                trackableProviders: ["TMDB"],
                discoversChildren: false,
                canSearchMissingChildren: false,
                missingChildEntityKind: nil,
                monitor: status.map { status in
                    EntityMonitor(
                        id: monitorID,
                        kind: .video,
                        acquisitionID: nil,
                        status: status,
                        title: "Episode 1",
                        author: nil,
                        acquisitionStatus: nil,
                        createdAt: Date(timeIntervalSince1970: 0),
                        updatedAt: Date(timeIntervalSince1970: 0),
                        entityID: entityID,
                        preset: "all"
                    )
                },
                latestAcquisition: nil
            )
        )
    }
}
