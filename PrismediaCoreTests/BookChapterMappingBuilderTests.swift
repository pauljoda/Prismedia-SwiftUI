import XCTest

@testable import PrismediaCore

final class BookChapterMappingBuilderTests: XCTestCase {
    func testMatchesByNormalizedTitleBeforeChapterNumber() {
        let chapters = [
            chapter(id: "one", title: "Chapter 1: Café Meridian", order: 0),
            chapter(id: "two", title: "Chapter 2: The Crossing", order: 1),
        ]
        let tracks = [
            track(id: 1, title: "02 - The Crossing", order: 1),
            track(id: 2, title: "Track 01 — Cafe Meridian", order: 0),
        ]

        let rows = BookChapterMappingBuilder().build(
            readableChapters: chapters,
            audioTracks: tracks
        )

        XCTAssertEqual(rows.map(\.audioTrack?.id), [tracks[1].id, tracks[0].id])
    }

    func testMatchesRemainingChaptersByExplicitNumber() {
        let chapters = [chapter(id: "seven", title: "Chapter 7", order: 0)]
        let tracks = [track(id: 1, title: "Part 07 - A Different Title", order: 0)]

        let rows = BookChapterMappingBuilder().build(
            readableChapters: chapters,
            audioTracks: tracks
        )

        XCTAssertEqual(rows.first?.audioTrack?.id, tracks.first?.id)
    }

    func testUsesPositionOnlyWhenUnmatchedCountsAgree() {
        let chapters = [
            chapter(id: "a", title: "Prologue", order: 0),
            chapter(id: "b", title: "Epilogue", order: 1),
        ]
        let tracks = [
            track(id: 1, title: "Opening", order: 0),
            track(id: 2, title: "Closing", order: 1),
        ]

        let rows = BookChapterMappingBuilder().build(
            readableChapters: chapters,
            audioTracks: tracks
        )

        XCTAssertEqual(rows.map(\.audioTrack?.id), tracks.map(\.id))
    }

    func testLeavesAmbiguousReadableRowsUnmatchedAndAppendsExtraAudio() {
        let chapters = [chapter(id: "a", title: "Prologue", order: 0)]
        let tracks = [
            track(id: 1, title: "Opening A", order: 0),
            track(id: 2, title: "Opening B", order: 1),
        ]

        let rows = BookChapterMappingBuilder().build(
            readableChapters: chapters,
            audioTracks: tracks,
            currentReadableID: "a",
            currentAudioTrackID: tracks[1].id
        )

        XCTAssertNil(rows[0].audioTrack)
        XCTAssertTrue(rows[0].isCurrentReading)
        XCTAssertEqual(rows.dropFirst().compactMap(\.audioTrack?.id), tracks.map(\.id))
        XCTAssertTrue(rows.last?.isCurrentAudio == true)
    }

    private func chapter(id: String, title: String, order: Int) -> ReadableBookChapter {
        ReadableBookChapter(
            id: id,
            title: title,
            order: order,
            depth: 0,
            target: .epub(location: "Text/\(id).xhtml")
        )
    }

    private func track(id: Int, title: String, order: Int) -> MusicTrack {
        MusicTrack(
            id: UUID(uuidString: String(format: "00000000-0000-0000-0000-%012d", id))!,
            title: title,
            sortOrder: order
        )
    }
}
