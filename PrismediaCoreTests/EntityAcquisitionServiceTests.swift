import XCTest

@testable import PrismediaCore

@MainActor
final class EntityAcquisitionServiceTests: XCTestCase {
    func testTransientAcquisitionFailurePreservesFallbackDetail() async {
        let fallback = acquisitionDetail
        let service = EntityAcquisitionService(
            port: EntityAcquisitionServiceStub(
                state: monitorState,
                acquisition: nil,
                failsAcquisitionLoad: true
            )
        )

        let outcome = await service.load(
            entityID: entityID,
            fallbackAcquisition: fallback
        )

        XCTAssertEqual(
            outcome,
            .content(
                EntityAcquisitionPanelSnapshot(
                    state: monitorState,
                    latestAcquisition: fallback
                )
            )
        )
    }

    func testSuccessfulEmptyAcquisitionLoadDoesNotReuseFallbackDetail() async {
        let service = EntityAcquisitionService(
            port: EntityAcquisitionServiceStub(
                state: monitorState,
                acquisition: nil,
                failsAcquisitionLoad: false
            )
        )

        let outcome = await service.load(
            entityID: entityID,
            fallbackAcquisition: acquisitionDetail
        )

        XCTAssertEqual(
            outcome,
            .content(
                EntityAcquisitionPanelSnapshot(
                    state: monitorState,
                    latestAcquisition: nil
                )
            )
        )
    }

    private var entityID: UUID {
        UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa")!
    }

    private var monitorState: EntityMonitorState {
        EntityMonitorState(
            entityID: entityID,
            canMonitor: true,
            canRequest: true,
            trackableProviders: ["Open Library"],
            discoversChildren: false,
            canSearchMissingChildren: false,
            missingChildEntityKind: nil,
            monitor: nil,
            latestAcquisition: nil
        )
    }

    private var acquisitionDetail: RequestActivityAcquisitionDetail {
        let json = """
            {
              "summary":{
                "id":"11111111-1111-1111-1111-111111111111",
                "status":"searching",
                "title":"Dune",
                "kind":"book",
                "createdAt":"2026-07-12T17:00:00Z",
                "updatedAt":"2026-07-12T18:00:00Z",
                "entityId":"aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
              },
              "candidates":[]
            }
            """
        return try! PrismediaJSON.decoder().decode(
            RequestActivityAcquisitionDetail.self,
            from: Data(json.utf8)
        )
    }
}

private actor EntityAcquisitionServiceStub: EntityAcquisitionServicing {
    let state: EntityMonitorState
    let acquisition: RequestActivityAcquisitionDetail?
    let failsAcquisitionLoad: Bool

    init(
        state: EntityMonitorState,
        acquisition: RequestActivityAcquisitionDetail?,
        failsAcquisitionLoad: Bool
    ) {
        self.state = state
        self.acquisition = acquisition
        self.failsAcquisitionLoad = failsAcquisitionLoad
    }

    func loadState(entityID _: UUID) async throws -> EntityMonitorState { state }

    func latestAcquisition(entityID _: UUID) async throws -> RequestActivityAcquisitionDetail? {
        if failsAcquisitionLoad { throw URLError(.cannotConnectToHost) }
        return acquisition
    }

    func acquisitionBlocklist(entityID: UUID?) async throws -> [RequestActivityBlocklistEntry] { [] }
    func clearAcquisitionBlocklist(entityID: UUID?, createdAfter: Date?) async throws -> Int { 0 }

    func startMonitor(entityID _: UUID) async throws {}
    func pauseMonitor(id _: UUID) async throws {}
    func resumeMonitor(id _: UUID) async throws {}
    func searchAgain(acquisitionID _: UUID) async throws {}
    func searchForRelease(entityID _: UUID) async throws {}
    func syncContainer(entityID _: UUID) async throws {}

    func searchMissingChildren(entityID _: UUID) async throws -> EntityMissingChildrenSearchResponse {
        EntityMissingChildrenSearchResponse(covered: 0, missing: 0)
    }

    func unmonitor(id _: UUID) async throws -> Bool { false }
}
