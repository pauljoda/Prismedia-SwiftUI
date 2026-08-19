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
        XCTAssertTrue(rows.allSatisfy { !$0.isCurrentProgress })
    }

    func testDoesNotMatchChaptersByExplicitNumber() {
        let chapters = [chapter(id: "seven", title: "Chapter 7", order: 0)]
        let tracks = [track(id: 1, title: "Part 07 - A Different Title", order: 0)]

        let rows = BookChapterMappingBuilder().build(
            readableChapters: chapters,
            audioTracks: tracks
        )

        XCTAssertNil(rows.first?.audioTrack)
        XCTAssertEqual(rows.last?.audioTrack?.id, tracks.first?.id)
    }

    func testDoesNotMatchDelimitedTrailingChapterNumbers() {
        let chapters = [
            chapter(id: "one", title: "Chapter 1", order: 0),
            chapter(id: "two", title: "Chapter 2", order: 1),
        ]
        let tracks = [
            track(id: 2, title: "George R. R. Martin - SFI03 Storm of Swords - 2", order: 0),
            track(id: 1, title: "George R. R. Martin - SFI03 Storm of Swords - 1", order: 1),
        ]

        let rows = BookChapterMappingBuilder().build(
            readableChapters: chapters,
            audioTracks: tracks
        )

        XCTAssertTrue(rows.prefix(2).allSatisfy { $0.audioTrack == nil })
        XCTAssertEqual(rows.dropFirst(2).compactMap(\.audioTrack?.id), tracks.map(\.id))
    }

    func testDoesNotMistakeBookNumberForChapterNumber() {
        let chapters = [chapter(id: "three", title: "Chapter 3", order: 0)]
        let tracks = [
            track(
                id: 3,
                title: "A Storm of Swords: A Song of Ice and Fire, Book 3",
                order: 0
            )
        ]

        let rows = BookChapterMappingBuilder().build(
            readableChapters: chapters,
            audioTracks: tracks
        )

        XCTAssertNil(rows.first?.audioTrack)
    }

    func testDoesNotInferChapterNumbersFromTrackOrder() {
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

        XCTAssertTrue(rows.prefix(2).allSatisfy { $0.audioTrack == nil })
        XCTAssertEqual(rows.dropFirst(2).compactMap(\.audioTrack?.id), tracks.map(\.id))
    }

    func testLeavesAmbiguousReadableRowsUnmatchedAndAppendsExtraAudio() {
        let chapters = [chapter(id: "a", title: "Prologue", order: 0)]
        let tracks = [
            track(id: 1, title: "Opening A", order: 0),
            track(id: 2, title: "Opening B", order: 1),
        ]

        let rows = BookChapterMappingBuilder().build(
            readableChapters: chapters,
            audioTracks: tracks
        )

        XCTAssertNil(rows[0].audioTrack)
        XCTAssertEqual(rows.dropFirst().compactMap(\.audioTrack?.id), tracks.map(\.id))
        XCTAssertTrue(rows.allSatisfy { !$0.isCurrentProgress })
    }

    func testLeavesTextOnlyChaptersUnmarkedUntilCanonicalProgressIsApplied() {
        let chapters = [
            chapter(id: "one", title: "Chapter 1", order: 0),
            chapter(id: "two", title: "Chapter 2", order: 1),
        ]

        let rows = BookChapterMappingBuilder().build(
            readableChapters: chapters,
            audioTracks: []
        )

        XCTAssertTrue(rows.allSatisfy { !$0.isCurrentProgress })
    }

    func testExplicitMappingsWinOverAutomaticTitleMatches() {
        let chapters = [
            chapter(id: "prologue", title: "Prologue", order: 0),
            chapter(id: "one", title: "Chapter 1: Winter", order: 1),
        ]
        let tracks = [
            track(id: 1, title: "Chapter 1: Winter", order: 0),
            track(id: 2, title: "Prologue", order: 1),
        ]

        let rows = BookChapterMappingBuilder().build(
            readableChapters: chapters,
            audioTracks: tracks,
            explicitMappings: [
                BookChapterAudioMapping(readableChapterKey: "prologue", audioTrackID: tracks[0].id),
                BookChapterAudioMapping(readableChapterKey: "one", audioTrackID: tracks[1].id),
            ]
        )

        XCTAssertEqual(rows.map(\.audioTrack?.id), tracks.map(\.id))
    }

    func testSequentialMappingsStartAtTheChapterMarkedByTheUser() {
        let chapters = [
            chapter(id: "cover", title: "Cover", order: 0),
            chapter(id: "prologue", title: "Prologue", order: 1),
            chapter(id: "one", title: "Chapter 1", order: 2),
            chapter(id: "two", title: "Chapter 2", order: 3),
        ]
        let tracks = [
            track(id: 1, title: "File 1", order: 0),
            track(id: 2, title: "File 2", order: 1),
            track(id: 3, title: "File 3", order: 2),
        ]

        let mappings = BookChapterMappingBuilder().sequentialMappings(
            readableChapters: chapters,
            audioTracks: tracks,
            firstReadableChapterKey: "prologue"
        )

        XCTAssertEqual(mappings.map(\.readableChapterKey), ["prologue", "one", "two"])
        XCTAssertEqual(mappings.map(\.audioTrackID), tracks.map(\.id))
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
