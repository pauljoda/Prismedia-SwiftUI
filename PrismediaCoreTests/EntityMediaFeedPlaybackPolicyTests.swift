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

    func testPrewarmWindowIncludesOnlyTheVisibleItemAndTwoAhead() {
        let ids = fixtureIDs

        XCTAssertEqual(
            EntityMediaFeedPlaybackPolicy.prewarmIDs(
                orderedIDs: ids,
                visibleIDs: [ids[3]],
                eligibleIDs: [ids[3], ids[4], ids[5], ids[6]]
            ),
            Set(ids[3...5])
        )
    }

    func testPrewarmWindowIsClampedAtCollectionEdges() {
        let ids = fixtureIDs

        XCTAssertEqual(
            EntityMediaFeedPlaybackPolicy.prewarmIDs(
                orderedIDs: ids,
                visibleIDs: [ids[5]],
                eligibleIDs: [ids[5], ids[6]]
            ),
            Set(ids[5...6])
        )
    }

    func testInitialPrewarmWindowLoadsOnlyTheFirstTwoEligibleVideos() {
        XCTAssertEqual(
            EntityMediaFeedPlaybackPolicy.prewarmIDs(
                orderedIDs: fixtureIDs,
                visibleIDs: [],
                eligibleIDs: [fixtureIDs[1], fixtureIDs[4], fixtureIDs[6]]
            ),
            Set([fixtureIDs[1], fixtureIDs[4]])
        )
    }

    private var fixtureIDs: [UUID] {
        (0..<7).map { index in
            UUID(uuidString: "00000000-0000-0000-0000-00000000000\(index)")!
        }
    }
}
