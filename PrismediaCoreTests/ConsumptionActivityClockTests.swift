import XCTest

@testable import PrismediaCore

final class ConsumptionActivityClockTests: XCTestCase {
    func testTakeReturnsElapsedTimeAndContinuesFromTheTake() {
        var clock = ConsumptionActivityClock()
        clock.start(at: 10)

        XCTAssertEqual(clock.take(at: 18), 8)
        XCTAssertEqual(clock.take(at: 23), 5)
    }

    func testTakeDoesNotStartAnIdleClock() {
        var clock = ConsumptionActivityClock()

        XCTAssertNil(clock.take(at: 18))
    }

    func testStopReturnsElapsedTimeAndStopsTheClock() {
        var clock = ConsumptionActivityClock()
        clock.start(at: 10)

        XCTAssertEqual(clock.stop(at: 18), 8)
        XCTAssertNil(clock.take(at: 23))
    }

    func testHeartbeatIsClamped() {
        var clock = ConsumptionActivityClock(maximumHeartbeatSeconds: 60)
        clock.start(at: 10)

        XCTAssertEqual(clock.take(at: 100), 60)
    }
}
