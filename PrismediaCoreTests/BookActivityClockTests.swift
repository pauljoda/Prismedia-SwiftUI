import XCTest

@testable import PrismediaCore

final class BookActivityClockTests: XCTestCase {
    func testHeartbeatsMeasureActiveWallClockTimeAndRestartTheInterval() {
        var clock = BookActivityClock()

        clock.start(at: 10)

        XCTAssertEqual(clock.take(at: 25), 15)
        XCTAssertEqual(clock.take(at: 32.5), 7.5)
    }

    func testStopFlushesThenLeavesTheClockInactive() {
        var clock = BookActivityClock()

        clock.start(at: 10)

        XCTAssertEqual(clock.stop(at: 25), 15)
        XCTAssertNil(clock.take(at: 40))
    }

    func testHeartbeatIsCappedAtSixtySeconds() {
        var clock = BookActivityClock()

        clock.start(at: 10)

        XCTAssertEqual(clock.take(at: 100), 60)
    }

    func testRepeatedStartDoesNotDiscardUnreportedActivity() {
        var clock = BookActivityClock()

        clock.start(at: 10)
        clock.start(at: 20)

        XCTAssertEqual(clock.stop(at: 25), 15)
    }
}
