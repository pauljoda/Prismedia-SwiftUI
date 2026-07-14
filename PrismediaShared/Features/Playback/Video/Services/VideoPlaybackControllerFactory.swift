import Foundation

@MainActor
struct VideoPlaybackControllerFactory {
    private let makeController:
        @MainActor (UUID, any VideoPlaybackServicing, [EntitySubtitle]) -> VideoPlaybackController
    init(
        _ makeController:
            @escaping @MainActor (UUID, any VideoPlaybackServicing, [EntitySubtitle]) -> VideoPlaybackController
    ) { self.makeController = makeController }
    func callAsFunction(videoID: UUID, service: any VideoPlaybackServicing, subtitles: [EntitySubtitle])
        -> VideoPlaybackController
    {
        makeController(videoID, service, subtitles)
    }
    static let live = Self { VideoPlaybackController(videoID: $0, service: $1, sidecarSubtitles: $2) }
}
