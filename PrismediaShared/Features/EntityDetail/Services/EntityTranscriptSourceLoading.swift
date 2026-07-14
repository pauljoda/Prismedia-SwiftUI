import Foundation

public protocol EntityTranscriptSourceLoading: Sendable {
    func loadTranscriptSource(videoID: UUID, trackID: String) async throws -> Data
}
