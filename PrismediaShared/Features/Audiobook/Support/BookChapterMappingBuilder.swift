import Foundation

struct BookChapterMappingBuilder: Sendable {
    func build(
        readableChapters: [ReadableBookChapter],
        audioTracks: [MusicTrack],
        currentReadableID: String? = nil,
        currentAudioTrackID: UUID? = nil
    ) -> [BookChapterMapping] {
        let readable = readableChapters.sorted(by: readableChapterSort)
        let tracks = audioTracks.sorted(by: audioTrackSort)
        var consumedTrackIndexes = Set<Int>()
        var matches: [String: Int] = [:]

        for chapter in readable {
            let key = matchKey(chapter.title)
            guard !key.isEmpty,
                let index = firstAvailableTrackIndex(
                    in: tracks,
                    consumed: consumedTrackIndexes,
                    matching: { matchKey($0.title) == key }
                )
            else { continue }
            matches[chapter.id] = index
            consumedTrackIndexes.insert(index)
        }

        for chapter in readable where matches[chapter.id] == nil {
            guard let number = chapterNumber(chapter.title),
                let index = firstAvailableTrackIndex(
                    in: tracks,
                    consumed: consumedTrackIndexes,
                    matching: { chapterNumber($0.title) == number }
                )
            else { continue }
            matches[chapter.id] = index
            consumedTrackIndexes.insert(index)
        }

        let unmatchedChapters = readable.filter { matches[$0.id] == nil }
        let unmatchedTrackIndexes = tracks.indices.filter { !consumedTrackIndexes.contains($0) }
        if !unmatchedChapters.isEmpty, unmatchedChapters.count == unmatchedTrackIndexes.count {
            for (chapter, index) in zip(unmatchedChapters, unmatchedTrackIndexes) {
                matches[chapter.id] = index
                consumedTrackIndexes.insert(index)
            }
        }

        var rows = readable.map { chapter in
            let track = matches[chapter.id].map { tracks[$0] }
            return BookChapterMapping(
                id: "read-\(chapter.id)-\(chapter.order)",
                title: chapter.title,
                order: chapter.order,
                depth: chapter.depth,
                readTarget: chapter.target,
                audioTrack: track,
                isCurrentReading: chapter.id == currentReadableID,
                isCurrentAudio: track?.id == currentAudioTrackID
            )
        }

        for index in tracks.indices where !consumedTrackIndexes.contains(index) {
            let track = tracks[index]
            rows.append(
                BookChapterMapping(
                    id: "audio-\(track.id.uuidString.lowercased())",
                    title: track.title,
                    order: readable.count + index,
                    depth: 0,
                    readTarget: nil,
                    audioTrack: track,
                    isCurrentReading: false,
                    isCurrentAudio: track.id == currentAudioTrackID
                )
            )
        }

        return rows
    }

    func matchKey(_ value: String) -> String {
        value
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .replacingOccurrences(
                of: #"^\s*(?:chapter|ch\.?|track|part)\s*[ivxlcdm]+\s*(?:[.\-–—:_]|\s)+"#,
                with: "",
                options: [.regularExpression, .caseInsensitive]
            )
            .replacingOccurrences(
                of: #"^\s*(?:chapter|ch\.?|track|part)\s*0*\d+\s*(?:[.\-–—:_]|\s)*"#,
                with: "",
                options: [.regularExpression, .caseInsensitive]
            )
            .replacingOccurrences(
                of: #"^\s*0*\d+\s*(?:[.\-–—:_]|\s)+"#,
                with: "",
                options: .regularExpression
            )
            .replacingOccurrences(of: #"[^a-z0-9]+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func readableChapterSort(_ lhs: ReadableBookChapter, _ rhs: ReadableBookChapter) -> Bool {
        (lhs.order, lhs.title, lhs.id) < (rhs.order, rhs.title, rhs.id)
    }

    private func audioTrackSort(_ lhs: MusicTrack, _ rhs: MusicTrack) -> Bool {
        (lhs.sortOrder, lhs.title, lhs.id.uuidString)
            < (rhs.sortOrder, rhs.title, rhs.id.uuidString)
    }

    private func firstAvailableTrackIndex(
        in tracks: [MusicTrack],
        consumed: Set<Int>,
        matching predicate: (MusicTrack) -> Bool
    ) -> Int? {
        tracks.indices.first { !consumed.contains($0) && predicate(tracks[$0]) }
    }

    private func chapterNumber(_ value: String) -> Int? {
        let patterns = [
            #"\b(?:chapter|ch\.?|track|part)\s*0*(\d+)\b"#,
            #"^\s*0*(\d+)\s*(?:[.\-–—:_]|\s)"#,
        ]
        let range = NSRange(value.startIndex..<value.endIndex, in: value)
        for pattern in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
                let match = regex.firstMatch(in: value, range: range),
                let captureRange = Range(match.range(at: 1), in: value),
                let number = Int(value[captureRange]),
                number > 0
            else { continue }
            return number
        }
        return nil
    }
}
