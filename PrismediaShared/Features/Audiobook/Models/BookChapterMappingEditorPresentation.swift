import Foundation

struct BookChapterMappingEditorPresentation: Equatable, Sendable {
    let readableChapters: [ReadableBookChapter]
    let audioTracks: [MusicTrack]
    let audioChapters: [BookAudioChapter]
    let mappings: [BookChapterAudioMapping]
    let loadErrorMessage: String?

    /// Only the user's explicit rows are editable; the server-derived automatic layer is
    /// annotation-only and refills after every save, so it must never seed a draft or a request.
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

    /// Editor reset key. Tracks only the manual rows so a background refresh of the server's
    /// automatic layer never discards an in-progress draft.
    var revision: String {
        manualMappings
            .sorted {
                ($0.audioTrackID.uuidString, $0.audioMarkerID?.uuidString ?? "", $0.readableChapterKey)
                    < ($1.audioTrackID.uuidString, $1.audioMarkerID?.uuidString ?? "", $1.readableChapterKey)
            }
            .map { "\($0.audioTrackID.uuidString):\($0.audioMarkerID?.uuidString ?? "whole"):\($0.readableChapterKey)" }
            .joined(separator: "|")
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
