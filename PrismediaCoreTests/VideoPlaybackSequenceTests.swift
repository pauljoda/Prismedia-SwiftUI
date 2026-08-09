import XCTest

@testable import PrismediaCore

final class VideoPlaybackSequenceTests: XCTestCase {
    func testNextEpisodeUsesSeasonOrderEvenWhenResponseOrderDiffers() {
        let first = episode(id: "11111111-1111-1111-1111-111111111111", order: 1)
        let second = episode(id: "22222222-2222-2222-2222-222222222222", order: 2)
        let third = episode(id: "33333333-3333-3333-3333-333333333333", order: 3)

        let next = VideoPlaybackSequence.nextEpisode(
            after: first.id,
            in: EntityGroup(
                kind: .videoEpisode,
                label: "Episodes",
                entities: [third, first, second],
                code: nil
            )
        )

        XCTAssertEqual(next?.id, second.id)
    }

    func testLastEpisodeInSeasonHasNoNextEpisode() {
        let first = episode(id: "11111111-1111-1111-1111-111111111111", order: 1)
        let second = episode(id: "22222222-2222-2222-2222-222222222222", order: 2)

        let next = VideoPlaybackSequence.nextEpisode(
            after: second.id,
            in: EntityGroup(
                kind: .videoEpisode,
                label: "Episodes",
                entities: [first, second],
                code: nil
            )
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

    func testNextEpisodeSkipsTheSecondProviderEpisodeInTheCompletedSource() {
        let firstID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let secondID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
        let shared = [
            EntitySharedSourceEpisode(id: firstID, title: "Part One", seasonNumber: 7, episodeNumber: 2),
            EntitySharedSourceEpisode(id: secondID, title: "Part Two", seasonNumber: 7, episodeNumber: 3),
        ]
        let first = episode(id: firstID.uuidString, order: 2, sharedSourceEpisodes: shared)
        let second = episode(id: secondID.uuidString, order: 3, sharedSourceEpisodes: shared)
        let nextFile = episode(id: "33333333-3333-3333-3333-333333333333", order: 4)

        let next = VideoPlaybackSequence.nextEpisode(
            after: second.id,
            in: EntityGroup(
                kind: .videoEpisode,
                label: "Episodes",
                entities: [second, nextFile, first],
                code: nil
            )
        )

        XCTAssertEqual(next?.id, nextFile.id)
    }

    private func episode(
        id: String,
        order: Int,
        sharedSourceEpisodes: [EntitySharedSourceEpisode] = []
    ) -> EntityThumbnail {
        EntityThumbnail(
            id: UUID(uuidString: id)!,
            kind: .videoEpisode,
            title: "Episode \(order)",
            sortOrder: order,
            hasSourceMedia: true,
            sharedSourceEpisodes: sharedSourceEpisodes
        )
    }
}
