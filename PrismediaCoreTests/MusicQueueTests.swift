import XCTest

@testable import PrismediaCore

final class MusicQueueTests: XCTestCase {
    func testNextAndPreviousFollowAlbumOrder() {
        let tracks = makeTracks(count: 3)
        var queue = MusicQueue(tracks: tracks)

        XCTAssertEqual(queue.currentTrack?.id, tracks[0].id)
        XCTAssertEqual(queue.advance(reason: .user)?.id, tracks[1].id)
        XCTAssertEqual(queue.advance(reason: .user)?.id, tracks[2].id)
        XCTAssertNil(queue.advance(reason: .user))
        XCTAssertEqual(queue.movePrevious()?.id, tracks[1].id)
    }

    func testRepeatOneReplaysOnlyWhenTheTrackEnds() {
        let tracks = makeTracks(count: 2)
        var queue = MusicQueue(tracks: tracks)
        queue.setRepeatMode(.one)

        XCTAssertEqual(queue.advance(reason: .playbackEnded)?.id, tracks[0].id)
        XCTAssertEqual(queue.advance(reason: .user)?.id, tracks[1].id)
    }

    func testRepeatAllWrapsAtBothEnds() {
        let tracks = makeTracks(count: 2)
        var queue = MusicQueue(tracks: tracks, startingAt: tracks[1].id)
        queue.setRepeatMode(.all)

        XCTAssertEqual(queue.advance(reason: .playbackEnded)?.id, tracks[0].id)
        XCTAssertEqual(queue.movePrevious()?.id, tracks[1].id)
    }

    func testShuffleKeepsTheCurrentTrackAndVisitsEveryTrackOnce() {
        let tracks = makeTracks(count: 5)
        var queue = MusicQueue(tracks: tracks, startingAt: tracks[2].id)
        var generator = SeededGenerator(seed: 42)

        queue.setShuffled(true, using: &generator)

        XCTAssertTrue(queue.isShuffled)
        XCTAssertEqual(queue.currentTrack?.id, tracks[2].id)

        var visited = [queue.currentTrack?.id].compactMap { $0 }
        while let next = queue.advance(reason: .user) {
            visited.append(next.id)
        }
        XCTAssertEqual(Set(visited), Set(tracks.map(\.id)))
        XCTAssertEqual(visited.count, tracks.count)
    }

    func testShuffleChangesTheDisplayedQueueOrderAndKeepsCurrentTrackFirst() {
        let tracks = makeTracks(count: 5)
        var queue = MusicQueue(tracks: tracks, startingAt: tracks[2].id)
        var generator = SeededGenerator(seed: 42)

        queue.setShuffled(true, using: &generator)

        XCTAssertEqual(queue.orderedTracks.first?.id, tracks[2].id)
        XCTAssertNotEqual(queue.orderedTracks.map(\.id), tracks.map(\.id))
        XCTAssertEqual(Set(queue.orderedTracks.map(\.id)), Set(tracks.map(\.id)))
    }

    func testUpNextTracksMatchTheOrderPlayedAfterShuffle() {
        let tracks = makeTracks(count: 5)
        var queue = MusicQueue(tracks: tracks, startingAt: tracks[2].id)
        var generator = SeededGenerator(seed: 42)
        queue.setShuffled(true, using: &generator)
        let displayedIDs = queue.upNextTracks.map(\.id)

        var playedIDs: [UUID] = []
        while let track = queue.advance(reason: .user) {
            playedIDs.append(track.id)
        }

        XCTAssertEqual(displayedIDs, playedIDs)
    }

    func testHistoryContainsOnlyTracksThatPlaybackActuallyLeftBehind() {
        let tracks = makeTracks(count: 4)
        var queue = MusicQueue(tracks: tracks, startingAt: tracks[1].id)

        XCTAssertTrue(queue.history.isEmpty)

        _ = queue.advance(reason: .user)
        _ = queue.advance(reason: .playbackEnded)

        XCTAssertEqual(queue.history.map(\.track.id), [tracks[1].id, tracks[2].id])
        XCTAssertEqual(queue.currentTrack?.id, tracks[3].id)
    }

    func testMovingBackThroughPlayedTracksRemovesThemFromHistory() {
        let tracks = makeTracks(count: 4)
        var queue = MusicQueue(tracks: tracks)
        _ = queue.advance(reason: .user)
        _ = queue.advance(reason: .user)

        XCTAssertEqual(queue.history.map(\.track.id), [tracks[0].id, tracks[1].id])

        _ = queue.movePrevious()

        XCTAssertEqual(queue.currentTrack?.id, tracks[1].id)
        XCTAssertEqual(queue.history.map(\.track.id), [tracks[0].id])
    }

    func testSelectingAnUpcomingTrackMakesItCurrentAndRecordsOnlyTheTrackLeftBehind() {
        let tracks = makeTracks(count: 4)
        var queue = MusicQueue(tracks: tracks)

        let selected = queue.moveToUpcomingTrack(id: tracks[2].id)

        XCTAssertEqual(selected?.id, tracks[2].id)
        XCTAssertEqual(queue.currentTrack?.id, tracks[2].id)
        XCTAssertEqual(queue.history.map(\.track.id), [tracks[0].id])
        XCTAssertEqual(queue.upNextTracks.map(\.id), [tracks[3].id])
    }

    func testUpcomingTracksCanBeReorderedWithoutChangingTheCurrentTrack() {
        let tracks = makeTracks(count: 4)
        var queue = MusicQueue(tracks: tracks)

        XCTAssertTrue(queue.moveUpcomingTrack(id: tracks[3].id, before: tracks[1].id))

        XCTAssertEqual(queue.currentTrack?.id, tracks[0].id)
        XCTAssertEqual(queue.upNextTracks.map(\.id), [tracks[3].id, tracks[1].id, tracks[2].id])
        XCTAssertTrue(queue.history.isEmpty)

        XCTAssertTrue(queue.moveUpcomingTrack(id: tracks[3].id, after: tracks[2].id))
        XCTAssertEqual(queue.upNextTracks.map(\.id), [tracks[1].id, tracks[2].id, tracks[3].id])
    }

    func testRepeatModeCyclesFromOffToAllToOneAndBackToOff() {
        var queue = MusicQueue(tracks: makeTracks(count: 2))

        queue.cycleRepeatMode()
        XCTAssertEqual(queue.repeatMode, .all)
        queue.cycleRepeatMode()
        XCTAssertEqual(queue.repeatMode, .one)
        queue.cycleRepeatMode()
        XCTAssertEqual(queue.repeatMode, .off)
    }

    func testDisablingShuffleRestoresNaturalOrderAtTheCurrentTrack() {
        let tracks = makeTracks(count: 4)
        var queue = MusicQueue(tracks: tracks, startingAt: tracks[1].id)
        var generator = SeededGenerator(seed: 7)
        queue.setShuffled(true, using: &generator)
        _ = queue.advance(reason: .user)
        let currentID = queue.currentTrack?.id

        queue.setShuffled(false)

        XCTAssertFalse(queue.isShuffled)
        XCTAssertEqual(queue.currentTrack?.id, currentID)
        XCTAssertEqual(queue.position, 0)
        let naturalIndex = tracks.firstIndex { $0.id == currentID }!
        XCTAssertEqual(
            queue.upNextTracks.map(\.id),
            tracks.dropFirst(naturalIndex + 1).map(\.id)
        )
    }

    func testShuffleModeChangesPreserveHistoryAndDoNotReplayHistoryAsUpNext() {
        let tracks = makeTracks(count: 5)
        var queue = MusicQueue(tracks: tracks)
        _ = queue.advance(reason: .user)
        let history = queue.history
        var generator = SeededGenerator(seed: 42)

        queue.setShuffled(true, using: &generator)

        XCTAssertEqual(queue.history, history)
        XCTAssertFalse(queue.upNextTracks.contains { $0.id == tracks[0].id })

        queue.setShuffled(false)

        XCTAssertEqual(queue.history, history)
        XCTAssertFalse(queue.upNextTracks.contains { $0.id == tracks[0].id })
    }

    func testEmptyAndSingleTrackQueuesHaveSafeBoundaries() {
        var empty = MusicQueue(tracks: [])
        XCTAssertNil(empty.currentTrack)
        XCTAssertNil(empty.advance(reason: .user))
        XCTAssertNil(empty.movePrevious())

        let track = makeTracks(count: 1)[0]
        var single = MusicQueue(tracks: [track])
        XCTAssertEqual(single.currentTrack, track)
        XCTAssertNil(single.advance(reason: .playbackEnded))
        XCTAssertNil(single.movePrevious())
        single.setRepeatMode(.all)
        XCTAssertEqual(single.advance(reason: .playbackEnded), track)
    }

    func testRestorationPreservesExactOrderPositionRepeatAndShuffle() {
        let tracks = makeTracks(count: 4)
        let history = [
            MusicQueueHistoryEntry(sequence: 0, track: tracks[2]),
            MusicQueueHistoryEntry(sequence: 1, track: tracks[0]),
        ]
        let restoration = MusicPlaybackRestoration(
            tracks: tracks,
            orderedTrackIDs: [tracks[2].id, tracks[0].id, tracks[3].id, tracks[1].id],
            currentTrackID: tracks[3].id,
            repeatMode: .all,
            isShuffled: true,
            elapsedTime: 42,
            history: history
        )

        let queue = MusicQueue(restoration: restoration)

        XCTAssertEqual(queue.orderedTracks.map(\.id), restoration.orderedTrackIDs)
        XCTAssertEqual(queue.currentTrack?.id, tracks[3].id)
        XCTAssertEqual(queue.repeatMode, .all)
        XCTAssertTrue(queue.isShuffled)
        XCTAssertEqual(queue.history, history)
    }

    private func makeTracks(count: Int) -> [MusicTrack] {
        (0..<count).map { index in
            MusicTrack(
                id: UUID(uuidString: String(format: "00000000-0000-0000-0000-%012d", index + 1))!,
                title: "Track \(index + 1)",
                sortOrder: index
            )
        }
    }
}

private struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        state = 6_364_136_223_846_793_005 &* state &+ 1
        return state
    }
}
