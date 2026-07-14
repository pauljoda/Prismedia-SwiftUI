import XCTest

@testable import PrismediaCore

final class TVHomeHeroMovePolicyTests: XCTestCase {
    func testUpRequestsTabFocusWithOneHeroItem() {
        XCTAssertEqual(
            TVHomeHeroMovePolicy.action(
                for: .up,
                isFocused: true,
                selectedIndex: 0,
                itemCount: 1
            ),
            .focusTabs
        )
    }

    func testPagingRequiresAtLeastTwoHeroItems() {
        XCTAssertEqual(
            TVHomeHeroMovePolicy.action(
                for: .left,
                isFocused: true,
                selectedIndex: 0,
                itemCount: 1
            ),
            .none
        )
        XCTAssertEqual(
            TVHomeHeroMovePolicy.action(
                for: .right,
                isFocused: true,
                selectedIndex: 0,
                itemCount: 1
            ),
            .none
        )
    }

    func testPagingWrapsWithoutProducingAnOutOfBoundsIndex() {
        XCTAssertEqual(
            TVHomeHeroMovePolicy.action(
                for: .left,
                isFocused: true,
                selectedIndex: 0,
                itemCount: 3
            ),
            .select(index: 2)
        )
        XCTAssertEqual(
            TVHomeHeroMovePolicy.action(
                for: .right,
                isFocused: true,
                selectedIndex: 2,
                itemCount: 3
            ),
            .select(index: 0)
        )
        XCTAssertEqual(
            TVHomeHeroMovePolicy.action(
                for: .right,
                isFocused: true,
                selectedIndex: 99,
                itemCount: 3
            ),
            .select(index: 0)
        )
    }

    func testMoveCommandsDoNothingWhenHeroIsNotFocused() {
        XCTAssertEqual(
            TVHomeHeroMovePolicy.action(
                for: .up,
                isFocused: false,
                selectedIndex: 0,
                itemCount: 1
            ),
            .none
        )
    }
}
