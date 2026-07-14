import XCTest

@testable import PrismediaCore

final class VideoPlaybackSequenceTests: XCTestCase {
    func testNextEpisodeUsesSeasonOrderEvenWhenResponseOrderDiffers() {
        let first = episode(id: "11111111-1111-1111-1111-111111111111", order: 1)
        let second = episode(id: "22222222-2222-2222-2222-222222222222", order: 2)
        let third = episode(id: "33333333-3333-3333-3333-333333333333", order: 3)

        let next = VideoPlaybackSequence.nextEpisode(
            after: first.id,
            in: EntityGroup(kind: .video, label: "Episodes", entities: [third, first, second], code: nil)
        )

        XCTAssertEqual(next?.id, second.id)
    }

    func testLastEpisodeInSeasonHasNoNextEpisode() {
        let first = episode(id: "11111111-1111-1111-1111-111111111111", order: 1)
        let second = episode(id: "22222222-2222-2222-2222-222222222222", order: 2)

        let next = VideoPlaybackSequence.nextEpisode(
            after: second.id,
            in: EntityGroup(kind: .video, label: "Episodes", entities: [first, second], code: nil)
        )

        XCTAssertNil(next)
    }

    func testNonVideoGroupCannotProvideNextEpisode() {
        let current = episode(id: "11111111-1111-1111-1111-111111111111", order: 1)
        let other = episode(id: "22222222-2222-2222-2222-222222222222", order: 2)

        let next = VideoPlaybackSequence.nextEpisode(
            after: current.id,
            in: EntityGroup(kind: .videoSeason, label: "Seasons", entities: [current, other], code: nil)
        )

        XCTAssertNil(next)
    }

    private func episode(id: String, order: Int) -> EntityThumbnail {
        EntityThumbnail(
            id: UUID(uuidString: id)!,
            kind: .video,
            title: "Episode \(order)",
            sortOrder: order,
            hasSourceMedia: true
        )
    }
}
