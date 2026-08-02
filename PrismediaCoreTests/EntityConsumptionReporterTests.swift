import XCTest

@testable import PrismediaCore

@MainActor
final class EntityConsumptionReporterTests: XCTestCase {
    func testAccessIsOncePerOpenAndActivityExcludesPausedTime() async throws {
        let entityID = UUID()
        let service = EntityConsumptionServiceSpy()
        let time = MutableConsumptionTime()
        let reporter = EntityConsumptionReporter(service: service, now: { time.value })

        reporter.open(id: entityID)
        reporter.open(id: entityID)
        time.value = 15
        reporter.heartbeat()
        time.value = 25
        reporter.pause()
        time.value = 40
        reporter.resume()
        time.value = 45
        reporter.close()
        await reporter.flush()

        let accesses = await service.accesses
        let activity = await service.activity
        XCTAssertEqual(accesses.map(\.id), [entityID])
        XCTAssertFalse(try XCTUnwrap(accesses.first?.sessionID).isEmpty)
        XCTAssertEqual(activity.map(\.id), [entityID, entityID, entityID])
        XCTAssertEqual(activity.map(\.seconds), [15, 10, 5])
    }

    func testChangingImageFlushesThePriorEntityBeforeOpeningTheNext() async {
        let firstID = UUID()
        let secondID = UUID()
        let service = EntityConsumptionServiceSpy()
        let time = MutableConsumptionTime()
        let reporter = EntityConsumptionReporter(service: service, now: { time.value })

        reporter.open(id: firstID)
        time.value = 8
        reporter.open(id: secondID)
        time.value = 12
        reporter.close()
        await reporter.flush()

        let accesses = await service.accesses
        let activity = await service.activity
        XCTAssertEqual(accesses.map(\.id), [firstID, secondID])
        XCTAssertEqual(activity.map(\.id), [firstID, secondID])
        XCTAssertEqual(activity.map(\.seconds), [8, 4])
    }
}

@MainActor
private final class MutableConsumptionTime {
    var value: TimeInterval = 0
}

private actor EntityConsumptionServiceSpy: EntityConsumptionServicing {
    private(set) var accesses: [(id: UUID, sessionID: String)] = []
    private(set) var activity: [(id: UUID, seconds: Double)] = []

    func recordConsumptionAccess(id: UUID, sessionID: String) async throws {
        accesses.append((id, sessionID))
    }

    func recordConsumptionActivity(id: UUID, seconds: Double) async throws {
        activity.append((id, seconds))
    }
}
