import Foundation

struct PreviewEntityTranscriptSourceLoader: EntityTranscriptSourceLoading {
    private let data: Data

    init(
        data: Data = Data(
            """
            WEBVTT

            00:00:01.000 --> 00:00:04.000
            The signal is coming from inside the station.

            00:00:05.000 --> 00:00:08.000
            Follow it before the channel closes.
            """.utf8
        )
    ) {
        self.data = data
    }

    func loadTranscriptSource(videoID: UUID, trackID: String) async throws -> Data {
        data
    }
}
