struct VideoPlaybackSource: Decodable {
    let id: String
    let container: String?
    let durationSeconds: Double?
    let method: VideoPlaybackDelivery
    let url: String
    let supportsTranscoding: Bool
    let streams: [VideoPlaybackStream]
    let transcoding: VideoTranscodingInfo?
}
