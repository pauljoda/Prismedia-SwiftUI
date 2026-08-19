import Foundation

struct VideoCompatibilityPlaybackRequest: Equatable, Sendable {
    let url: URL
    let resumeTime: Double
    let playbackRate: Float
    let audioStreams: [VideoPlaybackStreamChoice]
    let dolbyVisionProfile: Int?
    let networkCachingSeconds: Int

    init(
        url: URL,
        resumeTime: Double,
        playbackRate: Float,
        audioStreams: [VideoPlaybackStreamChoice],
        dolbyVisionProfile: Int?,
        networkCachingSeconds: Int = VLCNetworkCachingSettings.defaultSeconds
    ) {
        self.url = url
        self.resumeTime = resumeTime
        self.playbackRate = playbackRate
        self.audioStreams = audioStreams
        self.dolbyVisionProfile = dolbyVisionProfile
        self.networkCachingSeconds = VLCNetworkCachingSettings.normalizedSeconds(
            networkCachingSeconds
        )
    }
}
