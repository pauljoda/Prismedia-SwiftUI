import XCTest

@testable import PrismediaCore

final class BookChapterMappingBuilderTests: XCTestCase {
    func testAppliesThePersistedChapterMapRegardlessOfOrigin() {
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
                BookChapterAudioMapping(
                    readableChapterKey: "prologue",
                    audioTrackID: tracks[0].id,
                    origin: BookChapterAudioMapping.Origin.manual
                ),
                BookChapterAudioMapping(
                    readableChapterKey: "one",
                    audioTrackID: tracks[1].id,
                    origin: BookChapterAudioMapping.Origin.auto
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

        let rows = BookChapterMappingBuilder().build(
            readableChapters: chapters,
            audioTracks: tracks
        )

        XCTAssertNil(rows.first?.audioTrack)
        XCTAssertEqual(rows.last?.audioTrack?.id, tracks.first?.id)
    }

    func testIgnoresMappingsWhoseChapterOrTrackIsMissing() {
        let chapters = [chapter(id: "one", title: "Bran", order: 0)]
        let tracks = [track(id: 1, title: "Bran", order: 0)]

        let rows = BookChapterMappingBuilder().build(
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

    func testEditorSurfacesEditOnlyTheManualLayer() {
        let manual = BookChapterAudioMapping(
            readableChapterKey: "one",
            audioTrackID: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            origin: BookChapterAudioMapping.Origin.manual
        )
        let auto = BookChapterAudioMapping(
            readableChapterKey: "two",
            audioTrackID: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
            origin: BookChapterAudioMapping.Origin.auto
        )
        let legacy = BookChapterAudioMapping(
            readableChapterKey: "three",
            audioTrackID: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!
        )
        let presentation = BookChapterMappingEditorPresentation(
            readableChapters: [
                chapter(id: "one", title: "One", order: 0),
                chapter(id: "two", title: "Two", order: 1),
                chapter(id: "three", title: "Three", order: 2),
            ],
            audioTracks: [],
            mappings: [manual, auto, legacy],
            loadErrorMessage: nil
        )

        // Automatic rows must never reach a save request; origin-less rows are legacy manual.
        XCTAssertEqual(presentation.manualMappings, [manual, legacy])
        XCTAssertFalse(presentation.revision.contains(auto.readableChapterKey))
        XCTAssertEqual(presentation.automaticChapterTitle(for: auto.audioTrackID), "Two")
        XCTAssertNil(presentation.automaticChapterTitle(for: manual.audioTrackID))
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
