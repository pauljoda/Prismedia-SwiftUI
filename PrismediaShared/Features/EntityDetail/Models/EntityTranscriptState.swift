import Foundation

struct EntityTranscriptState {
    private(set) var selectedTrackID: String?
    private(set) var phase: EntityTranscriptPhase = .idle
    var searchText = ""
    private var loadGeneration = 0

    var cues: [EntityTranscriptCue] {
        guard case .content(let cues) = phase else { return [] }
        return cues
    }

    var filteredCues: [EntityTranscriptCue] {
        let terms = normalizedSearchTerms
        guard !terms.isEmpty else { return cues }
        return cues.filter { cue in
            let candidate = Self.normalized(cue.text)
            return terms.allSatisfy(candidate.contains)
        }
    }

    mutating func beginLoad(videoID: UUID, trackID: String) -> EntityTranscriptLoadRequest {
        loadGeneration += 1
        selectedTrackID = trackID
        phase = .loading
        return EntityTranscriptLoadRequest(
            videoID: videoID,
            trackID: trackID,
            generation: loadGeneration
        )
    }

    mutating func selectTrack(_ trackID: String) {
        guard trackID != selectedTrackID else { return }
        loadGeneration += 1
        selectedTrackID = trackID
        phase = .loading
    }

    mutating func finishLoad(
        _ outcome: EntityTranscriptLoadOutcome,
        request: EntityTranscriptLoadRequest
    ) {
        guard request.generation == loadGeneration,
            request.trackID == selectedTrackID
        else { return }

        switch outcome {
        case .content(let cues):
            phase = .content(cues)
        case .failure(let message):
            phase = .failure(message)
        case .cancelled:
            break
        }
    }

    mutating func reset() {
        loadGeneration += 1
        selectedTrackID = nil
        phase = .idle
        searchText = ""
    }

    func activeCueID(at time: Double?) -> EntityTranscriptCue.ID? {
        guard let time else { return nil }
        return cues.last(where: { $0.startTime <= time && time < $0.endTime })?.id
    }

    private var normalizedSearchTerms: [String] {
        Self.normalized(searchText)
            .split(whereSeparator: \.isWhitespace)
            .map(String.init)
    }

    private static func normalized(_ value: String) -> String {
        value.folding(
            options: [.caseInsensitive, .diacriticInsensitive],
            locale: .current
        )
    }
}
