import XCTest

@testable import PrismediaCore

final class EntityMediaFeedPlaybackPolicyTests: XCTestCase {
    func testPlaybackSelectsOnlyTheFirstVisibleItemInFeedOrder() {
        let ids = fixtureIDs

        XCTAssertEqual(
            EntityMediaFeedPlaybackPolicy.playbackID(
                orderedIDs: ids,
                visibleIDs: [ids[3], ids[2]]
            ),
            ids[2]
        )
        XCTAssertNil(
            EntityMediaFeedPlaybackPolicy.playbackID(
                orderedIDs: ids,
                visibleIDs: []
            )
        )
    }

    private var fixtureIDs: [UUID] {
        (0..<7).map { index in
            UUID(uuidString: "00000000-0000-0000-0000-00000000000\(index)")!
        }
    }
}
