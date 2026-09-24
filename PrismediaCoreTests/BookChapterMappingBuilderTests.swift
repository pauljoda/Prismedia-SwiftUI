import XCTest

@testable import PrismediaCore

final class BookChapterMappingBuilderTests: XCTestCase {
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
            origin: .manual
        )
        let auto = BookChapterAudioMapping(
            readableChapterKey: "two",
            audioTrackID: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
            origin: .auto
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
            audioChapters: [],
            mappings: [manual, auto, legacy],
            loadErrorMessage: nil,
            separateExplanation: nil
        )

        // Automatic rows must never reach a save request; origin-less rows are legacy manual.
        XCTAssertEqual(presentation.manualMappings, [manual, legacy])
        XCTAssertFalse(presentation.revision.contains(auto.readableChapterKey))
        XCTAssertEqual(presentation.automaticChapterTitle(for: BookAudioChapter(
            audioTrackID: auto.audioTrackID, audioMarkerID: nil, title: "Two", startSeconds: 0, endSeconds: nil
        )), "Two")
        XCTAssertNil(presentation.automaticChapterTitle(for: BookAudioChapter(
            audioTrackID: manual.audioTrackID, audioMarkerID: nil, title: "One", startSeconds: 0, endSeconds: nil
        )))
    }

    func testEditorFromTheServerAlignmentListsEachAudioWindowOnce() {
        let track = track(id: 1, title: "Complete audiobook", order: 0)
        let marker = UUID(uuidString: "00000000-0000-0000-0000-000000000101")!
        let window = BookAudioChapterWindow(
            trackEntityID: track.id, markerID: marker, title: "One", startSeconds: 0, endSeconds: 100
        )
        let alignment = BookAlignmentResponse(
            modalities: [.reading, .listening],
            readablePositionTotal: 10_000,
            rows: [
                BookAlignmentRow(
                    id: "r0", order: 0, matchState: .paired, provenance: .auto,
                    readable: BookReadableChapterWindow(chapterKey: "one", title: "One", location: "Text/one.xhtml"),
                    audio: window
                ),
                BookAlignmentRow(id: "a0", order: 1, matchState: .audioOnly, audio: window),
            ]
        )

        let presentation = BookChapterMappingEditorPresentation(
            alignment: alignment,
            audioTracks: [track],
            loadErrorMessage: nil
        )

        // A server list that names the same audio window twice must not trap the editor.
        XCTAssertEqual(presentation.orderedAudioChapters.map(\.audioMarkerID), [marker])
        XCTAssertEqual(presentation.orderedReadableChapters.map(\.target), [.epub(location: "Text/one.xhtml")])
        XCTAssertTrue(presentation.manualMappings.isEmpty)
        XCTAssertEqual(presentation.automaticChapterTitle(for: window.audioChapter), "One")
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
