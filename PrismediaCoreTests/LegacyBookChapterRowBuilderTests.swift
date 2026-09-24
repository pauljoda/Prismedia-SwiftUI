import XCTest

@testable import PrismediaCore

/// Chapter rows built from an older server's chapter map (before 3.8); removed with the legacy folder.
final class LegacyBookChapterRowBuilderTests: XCTestCase {
    func testAppliesThePersistedChapterMapRegardlessOfOrigin() {
        let chapters = [
            chapter(id: "prologue", title: "Prologue", order: 0),
            chapter(id: "one", title: "Chapter 1: Winter", order: 1),
        ]
        let tracks = [
            track(id: 1, title: "Chapter 1: Winter", order: 0),
            track(id: 2, title: "Prologue", order: 1),
        ]

        let rows = LegacyBookChapterRowBuilder().build(
            readableChapters: chapters,
            audioTracks: tracks,
            explicitMappings: [
                BookChapterAudioMapping(
                    readableChapterKey: "prologue",
                    audioTrackID: tracks[0].id,
                    origin: .manual
                ),
                BookChapterAudioMapping(
                    readableChapterKey: "one",
                    audioTrackID: tracks[1].id,
                    origin: .auto
                ),
            ]
        )

        XCTAssertEqual(rows.map(\.audioTrack?.id), tracks.map(\.id))
        XCTAssertTrue(rows.allSatisfy { !$0.isCurrentProgress })
    }

    func testNeverMatchesByTitleOnTheClient() {
        // Matching is computed and persisted server-side; identical titles alone must not attach.
        let chapters = [chapter(id: "prologue", title: "Prologue", order: 0)]
        let tracks = [track(id: 1, title: "Prologue", order: 0)]

        let rows = LegacyBookChapterRowBuilder().build(
            readableChapters: chapters,
            audioTracks: tracks
        )

        XCTAssertNil(rows.first?.audioTrack)
        XCTAssertEqual(rows.last?.audioTrack?.id, tracks.first?.id)
    }

    func testIgnoresMappingsWhoseChapterOrTrackIsMissing() {
        let chapters = [chapter(id: "one", title: "Bran", order: 0)]
        let tracks = [track(id: 1, title: "Bran", order: 0)]

        let rows = LegacyBookChapterRowBuilder().build(
            readableChapters: chapters,
            audioTracks: tracks,
            explicitMappings: [
                BookChapterAudioMapping(readableChapterKey: "vanished", audioTrackID: tracks[0].id),
                BookChapterAudioMapping(
                    readableChapterKey: "one",
                    audioTrackID: UUID(uuidString: "99999999-9999-9999-9999-999999999999")!
                ),
            ]
        )

        XCTAssertNil(rows.first?.audioTrack)
    }

    func testKeepsUnmappedAudioVisibleAsAppendedRows() {
        let chapters = [chapter(id: "a", title: "Prologue", order: 0)]
        let tracks = [
            track(id: 1, title: "Opening A", order: 0),
            track(id: 2, title: "Opening B", order: 1),
        ]

        let rows = LegacyBookChapterRowBuilder().build(
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

        let rows = LegacyBookChapterRowBuilder().build(
            readableChapters: chapters,
            audioTracks: []
        )

        XCTAssertTrue(rows.allSatisfy { !$0.isCurrentProgress })
    }

    func testOneM4BMapsMultipleEmbeddedChaptersWithoutConsumingTheWholeFile() {
        let track = track(id: 1, title: "Complete audiobook", order: 0)
        let firstMarker = UUID(uuidString: "00000000-0000-0000-0000-000000000101")!
        let secondMarker = UUID(uuidString: "00000000-0000-0000-0000-000000000102")!
        let audioChapters = [
            BookAudioChapter(audioTrackID: track.id, audioMarkerID: firstMarker,
                title: "One", startSeconds: 0, endSeconds: 100),
            BookAudioChapter(audioTrackID: track.id, audioMarkerID: secondMarker,
                title: "Two", startSeconds: 100, endSeconds: 250),
        ]
        let readable = [
            chapter(id: "one", title: "One", order: 0),
            chapter(id: "two", title: "Two", order: 1),
        ]
        let mappings = BookChapterMappingBuilder().sequentialMappings(
            readableChapters: readable,
            audioTracks: [track],
            audioChapters: audioChapters,
            firstReadableChapterKey: "one"
        )
        let rows = LegacyBookChapterRowBuilder().build(
            readableChapters: readable,
            audioTracks: [track],
            audioChapters: audioChapters,
            explicitMappings: mappings
        )

        XCTAssertEqual(mappings.map(\.audioMarkerID), [firstMarker, secondMarker])
        XCTAssertEqual(rows.map(\.audioTrack?.id), [track.id, track.id])
        XCTAssertEqual(rows.map(\.audioStartSeconds), [0, 100])
        XCTAssertEqual(rows.map(\.audioEndSeconds), [100, 250])
    }

    func testRepeatedAudioChaptersKeepTheirFirstOccurrence() {
        let track = track(id: 1, title: "Complete audiobook", order: 0)
        let marker = UUID(uuidString: "00000000-0000-0000-0000-000000000101")!
        let audioChapters = [
            BookAudioChapter(audioTrackID: track.id, audioMarkerID: marker,
                title: "One", startSeconds: 0, endSeconds: 100),
            BookAudioChapter(audioTrackID: track.id, audioMarkerID: marker,
                title: "One (repeated)", startSeconds: 0, endSeconds: 100),
        ]
        let rows = LegacyBookChapterRowBuilder().build(
            readableChapters: [chapter(id: "one", title: "One", order: 0)],
            audioTracks: [track, track],
            audioChapters: audioChapters,
            explicitMappings: [
                BookChapterAudioMapping(readableChapterKey: "one", audioTrackID: track.id, audioMarkerID: marker)
            ]
        )

        XCTAssertEqual(rows.map(\.title), ["One"])
        XCTAssertEqual(rows.map(\.audioMarkerID), [marker])
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
