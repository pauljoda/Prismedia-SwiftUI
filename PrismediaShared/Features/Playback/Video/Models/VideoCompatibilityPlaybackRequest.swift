import Foundation

struct VideoCompatibilityPlaybackRequest: Equatable, Sendable {
    let url: URL
    let resumeTime: Double
    let playbackRate: Float
    let audioStreams: [VideoPlaybackStreamChoice]
}
