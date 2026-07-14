import Foundation

@MainActor
struct EntityTranscriptService {
    private let sourceLoader: any EntityTranscriptSourceLoading

    init(sourceLoader: any EntityTranscriptSourceLoading) {
        self.sourceLoader = sourceLoader
    }

    func load(videoID: UUID, trackID: String) async -> EntityTranscriptLoadOutcome {
        do {
            let data = try await sourceLoader.loadTranscriptSource(
                videoID: videoID,
                trackID: trackID
            )
            try Task.checkCancellation()
            guard let contents = String(data: data, encoding: .utf8) else {
                return .failure("This transcript is not valid UTF-8 text.")
            }
            let cues = try WebVTTSubtitleParser.parse(contents).enumerated().map { index, cue in
                EntityTranscriptCue(
                    id: index,
                    startTime: cue.startTime,
                    endTime: cue.endTime,
                    text: cue.text
                )
            }
            return .content(cues)
        } catch is CancellationError {
            return .cancelled
        } catch {
            guard !Task.isCancelled else { return .cancelled }
            return .failure(error.localizedDescription)
        }
    }
}
