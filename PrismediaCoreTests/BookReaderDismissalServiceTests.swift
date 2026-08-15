import XCTest

@testable import PrismediaCore

@MainActor
final class BookReaderDismissalServiceTests: XCTestCase {
    func testDismissesBeforeWaitingForProgressFlush() async {
        var events: [String] = []

        let flushTask = BookReaderDismissalService().close(
            prepare: { events.append("queued") },
            dismiss: { events.append("dismissed") },
            flush: { events.append("flushed") }
        )

        XCTAssertEqual(events, ["queued", "dismissed"])
        await flushTask.value
        XCTAssertEqual(events, ["queued", "dismissed", "flushed"])
    }
}
