import XCTest

@testable import PrismediaCore

final class EntityImageViewerPagingTests: XCTestCase {
    func testSelectionUsesStableEntityIDsAndMovesOnePageAtATime() {
        let first = UUID()
        let second = UUID()
        let third = UUID()
        let paging = EntityImageViewerPaging(entityIDs: [first, second, third])

        XCTAssertEqual(paging.destination(from: second, direction: .previous), first)
        XCTAssertEqual(paging.destination(from: second, direction: .next), third)
    }

    func testPagingStopsAtSequenceBoundariesAndRejectsUnknownSelection() {
        let first = UUID()
        let second = UUID()
        let paging = EntityImageViewerPaging(entityIDs: [first, second])

        XCTAssertNil(paging.destination(from: first, direction: .previous))
        XCTAssertNil(paging.destination(from: second, direction: .next))
        XCTAssertNil(paging.destination(from: UUID(), direction: .next))
    }
}
