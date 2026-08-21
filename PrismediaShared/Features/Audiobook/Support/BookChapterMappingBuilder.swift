import Foundation

/// Composes the reading/listening chapter rows from the server-persisted chapter map. The map
/// already merges the user's explicit picks with the scan-computed automatic title matches, so
/// this builder only applies it — no title matching runs on the client anymore.
struct BookChapterMappingBuilder: Sendable {
    func build(
        readableChapters: [ReadableBookChapter],
        audioTracks: [MusicTrack],
        explicitMappings: [BookChapterAudioMapping] = []
    ) -> [BookChapterMapping] {
        let readable = readableChapters.sorted(by: readableChapterSort)
        let tracks = audioTracks.sorted(by: audioTrackSort)
        var consumedTrackIndexes = Set<Int>()
        var matches: [String: Int] = [:]

        let readableIDs = Set(readable.map(\.id))
        let trackIndexByID = Dictionary(uniqueKeysWithValues: tracks.enumerated().map { ($1.id, $0) })
        for mapping in explicitMappings {
            guard readableIDs.contains(mapping.readableChapterKey),
                matches[mapping.readableChapterKey] == nil,
                let index = trackIndexByID[mapping.audioTrackID],
                !consumedTrackIndexes.contains(index)
            else { continue }
            matches[mapping.readableChapterKey] = index
            consumedTrackIndexes.insert(index)
        }

        var rows = readable.map { chapter in
            let track = matches[chapter.id].map { tracks[$0] }
            return BookChapterMapping(
                id: "read-\(chapter.id)-\(chapter.order)",
                title: chapter.title,
                order: chapter.order,
                depth: chapter.depth,
                readTarget: chapter.target,
                readStartFraction: chapter.startFraction,
                readEndFraction: chapter.endFraction,
                readPageCount: chapter.pageCount,
                audioTrack: track
            )
        }

        var nextOrder = readable.count
        for index in tracks.indices where !consumedTrackIndexes.contains(index) {
            let track = tracks[index]
            rows.append(
                BookChapterMapping(
                    id: "audio-\(track.id.uuidString.lowercased())",
                    title: track.title,
                    order: nextOrder,
                    depth: 0,
                    readTarget: nil,
                    readStartFraction: nil,
                    readEndFraction: nil,
                    readPageCount: nil,
                    audioTrack: track
                )
            )
            nextOrder += 1
        }

        return rows
    }

    /// Creates the explicit one-to-one map produced by the “Mark first chapter” workflow.
    func sequentialMappings(
        readableChapters: [ReadableBookChapter],
        audioTracks: [MusicTrack],
        firstReadableChapterKey: String
    ) -> [BookChapterAudioMapping] {
        let readable = readableChapters.sorted(by: readableChapterSort)
        let tracks = audioTracks.sorted(by: audioTrackSort)
        guard let firstIndex = readable.firstIndex(where: { $0.id == firstReadableChapterKey }) else {
            return []
        }

        return tracks.prefix(readable.count - firstIndex).enumerated().map { offset, track in
            BookChapterAudioMapping(
                readableChapterKey: readable[firstIndex + offset].id,
                audioTrackID: track.id
            )
        }
    }

    private func readableChapterSort(_ lhs: ReadableBookChapter, _ rhs: ReadableBookChapter) -> Bool {
        (lhs.order, lhs.title, lhs.id) < (rhs.order, rhs.title, rhs.id)
    }

    private func audioTrackSort(_ lhs: MusicTrack, _ rhs: MusicTrack) -> Bool {
        (lhs.sortOrder, lhs.title, lhs.id.uuidString)
            < (rhs.sortOrder, rhs.title, rhs.id.uuidString)
    }
}
