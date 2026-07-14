struct VideoMediaSource: Decodable {
    let id: String
    let runTimeTicks: Int64?
    let supportsDirectPlay: Bool
    let supportsTranscoding: Bool
    let transcodingURL: String?
    let transcodingInfo: VideoTranscodingInfo?
    let mediaStreams: [VideoMediaStream]

    enum CodingKeys: String, CodingKey {
        case id = "Id"
        case runTimeTicks = "RunTimeTicks"
        case supportsDirectPlay = "SupportsDirectPlay"
        case supportsTranscoding = "SupportsTranscoding"
        case transcodingURL = "TranscodingUrl"
        case transcodingInfo = "TranscodingInfo"
        case mediaStreams = "MediaStreams"
    }
}
