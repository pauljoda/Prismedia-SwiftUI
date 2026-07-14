import XCTest

@testable import PrismediaCore

#if os(iOS) || os(macOS)
    final class IdentifyNextFlowTests: XCTestCase {
        func testNextAndPreviousWrapAcrossReviewableIDsOnly() {
            let ids = [UUID(), UUID(), UUID()]
            XCTAssertEqual(IdentifyNextFlow.next(after: ids[2], in: ids), ids[0])
            XCTAssertEqual(IdentifyNextFlow.previous(before: ids[0], in: ids), ids[2])
            XCTAssertEqual(IdentifyNextFlow.next(after: nil, in: ids), ids[0])
            XCTAssertNil(IdentifyNextFlow.next(after: nil, in: []))
        }
    }
#endif
