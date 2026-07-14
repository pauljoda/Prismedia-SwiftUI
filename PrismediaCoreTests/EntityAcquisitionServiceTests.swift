import XCTest

@testable import PrismediaCore

@MainActor
final class EntityAcquisitionServiceTests: XCTestCase {
    private let entityID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
    private let monitorID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
    private let acquisitionID = UUID(uuidString: "33333333-3333-3333-3333-333333333333")!

    func testLoadPublishesCapabilityDrivenState() async {
        let port = EntityAcquisitionServiceStub(state: makeState())
        let service = EntityAcquisitionService(port: port)

        let outcome = await service.load(entityID: entityID)

        guard case .content(let state) = outcome else {
            return XCTFail("Expected monitor state content")
        }
        XCTAssertTrue(state.canMonitor)
        XCTAssertEqual(state.monitor?.status, .active)
        XCTAssertEqual(state.latestAcquisition?.progress, 0.42)
    }

    func testCommandsDelegateToFocusedPort() async {
        let port = EntityAcquisitionServiceStub(state: makeState(), entityPruned: true)
        let service = EntityAcquisitionService(port: port)

        _ = await service.perform(.start(entityID))
        _ = await service.perform(.pause(monitorID))
        _ = await service.perform(.resume(monitorID))
        _ = await service.perform(.searchAgain(acquisitionID))
        let stop = await service.perform(.unmonitor(monitorID))
        let commands = await port.commands

        XCTAssertEqual(
            commands,
            [
                .start(entityID),
                .pause(monitorID),
                .resume(monitorID),
                .searchAgain(acquisitionID),
                .unmonitor(monitorID),
            ])
        XCTAssertEqual(stop, .completed(entityPruned: true))
    }

    func testFailureBecomesReadableOutcome() async {
        let port = EntityAcquisitionServiceStub(
            state: makeState(),
            error: PrismediaAPIError.httpStatus(
                403,
                APIProblem(code: "forbidden", message: "Administrator access is required.")
            )
        )
        let service = EntityAcquisitionService(port: port)

        let outcome = await service.perform(.pause(monitorID))

        guard case .failure(let message) = outcome else {
            return XCTFail("Expected a failure")
        }
        XCTAssertTrue(message.contains("Administrator access is required"))
    }

    private func makeState() -> EntityMonitorState {
        EntityMonitorState(
            entityID: entityID,
            canMonitor: true,
            canRequest: true,
            trackableProviders: ["openlibrary"],
            discoversChildren: false,
            canSearchMissingChildren: false,
            missingChildEntityKind: nil,
            monitor: EntityMonitor(
                id: monitorID,
                kind: .book,
                acquisitionID: acquisitionID,
                status: .active,
                title: "The Work",
                author: "Author",
                acquisitionStatus: AcquisitionStatus(rawValue: "downloading"),
                createdAt: .distantPast,
                updatedAt: .now,
                entityID: entityID,
                preset: "all"
            ),
            latestAcquisition: EntityAcquisitionSummary(
                id: acquisitionID,
                status: AcquisitionStatus(rawValue: "downloading"),
                title: "The Work",
                progress: 0.42,
                createdAt: .distantPast,
                updatedAt: .now,
                entityID: entityID
            )
        )
    }
}
