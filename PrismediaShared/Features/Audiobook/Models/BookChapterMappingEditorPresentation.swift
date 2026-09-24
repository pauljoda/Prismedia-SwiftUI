import Foundation

struct BookChapterMappingEditorPresentation: Equatable, Sendable {
    let readableChapters: [ReadableBookChapter]
    let audioTracks: [MusicTrack]
    let audioChapters: [BookAudioChapter]
    let mappings: [BookChapterAudioMapping]
    let loadErrorMessage: String?
    /// Why the Book keeps reading and listening separate, when the server says so.
    let separateExplanation: String?

    /// Only person-confirmed rows (picked by hand or filled in order) are editable; the
    /// server-derived automatic layer is annotation-only and refills after every save, so it must
    /// never seed a draft or a request.
    var manualMappings: [BookChapterAudioMapping] {
        mappings.filter { !$0.isAutomatic }
    }

    var alignedCount: Int {
        mappings.count
    }

    var automaticCount: Int {
        mappings.filter(\.isAutomatic).count
    }

    var orderedReadableChapters: [ReadableBookChapter] {
        readableChapters.sorted {
            ($0.order, $0.title, $0.id) < ($1.order, $1.title, $1.id)
        }
    }

    var orderedAudioTracks: [MusicTrack] {
        audioTracks.sorted {
            ($0.sortOrder, $0.title, $0.id.uuidString)
                < ($1.sortOrder, $1.title, $1.id.uuidString)
        }
    }

    var orderedAudioChapters: [BookAudioChapter] {
        BookAudioChapter.catalog(audioTracks: audioTracks, audioChapters: audioChapters)
    }

    /// Editor reset key. Tracks only the confirmed rows and their origins so a background refresh
    /// of the server's automatic layer never discards an in-progress draft.
    var revision: String {
        BookChapterMappingDraft.signature(manualMappings)
    }

    /// Title of the chapter the server's automatic matcher chose for this track, shown as the
    /// "no explicit mapping" annotation. Matching is computed and persisted server-side.
    func automaticChapterTitle(for candidate: BookAudioChapter) -> String? {
        guard let key = mappings.first(where: {
            $0.isAutomatic && $0.audioTrackID == candidate.audioTrackID
                && $0.audioMarkerID == candidate.audioMarkerID
        })?
            .readableChapterKey
        else { return nil }
        return readableChapters.first(where: { $0.id == key })?.title
    }
}

extension BookChapterMappingEditorPresentation {
    /// The editor for a server alignment: its readable chapters in display order, its audio
    /// windows, and its paired rows with their provenance.
    init(alignment: BookAlignmentResponse, audioTracks: [MusicTrack], loadErrorMessage: String?) {
        self.init(
            readableChapters: alignment.readableWindows.enumerated().map { order, window in
                ReadableBookChapter(window: window, order: order)
            },
            audioTracks: audioTracks,
            audioChapters: alignment.rows.compactMap { $0.audio?.audioChapter },
            mappings: alignment.chapterMappings,
            loadErrorMessage: loadErrorMessage,
            separateExplanation: alignment.separateProgress?.explanation
        )
    }
}
