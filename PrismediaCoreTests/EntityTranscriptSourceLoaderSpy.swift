import Foundation

@testable import PrismediaCore

actor EntityTranscriptSourceLoaderSpy: EntityTranscriptSourceLoading {
    private let result: Result<Data, Error>
    private var calls: [(videoID: UUID, trackID: String)] = []

    init(result: Result<Data, Error>) {
        self.result = result
    }

    func loadTranscriptSource(videoID: UUID, trackID: String) async throws -> Data {
        calls.append((videoID, trackID))
        return try result.get()
    }

    func recordedCalls() -> [(videoID: UUID, trackID: String)] {
        calls
    }
}
