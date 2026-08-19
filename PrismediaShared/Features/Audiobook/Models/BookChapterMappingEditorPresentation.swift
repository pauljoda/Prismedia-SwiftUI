import Foundation

struct BookChapterMappingEditorPresentation: Equatable, Sendable {
    let readableChapters: [ReadableBookChapter]
    let audioTracks: [MusicTrack]
    let mappings: [BookChapterAudioMapping]
    let loadErrorMessage: String?

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

    var revision: String {
        mappings
            .sorted {
                ($0.audioTrackID.uuidString, $0.readableChapterKey)
                    < ($1.audioTrackID.uuidString, $1.readableChapterKey)
            }
            .map { "\($0.audioTrackID.uuidString):\($0.readableChapterKey)" }
            .joined(separator: "|")
    }

    func automaticChapterTitle(for trackID: UUID) -> String? {
        BookChapterMappingBuilder()
            .build(readableChapters: readableChapters, audioTracks: audioTracks)
            .first(where: { $0.audioTrack?.id == trackID && $0.readTarget != nil })?
            .title
    }
}
