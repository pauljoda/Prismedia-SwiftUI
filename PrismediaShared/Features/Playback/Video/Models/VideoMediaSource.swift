struct VideoMediaSource: Decodable {
    let id: String
    let container: String?
    let runTimeTicks: Int64?
    let supportsDirectPlay: Bool
    let supportsTranscoding: Bool
    let transcodingURL: String?
    let transcodingInfo: VideoTranscodingInfo?
    let mediaStreams: [VideoMediaStream]

    enum CodingKeys: String, CodingKey {
        case id = "Id"
        case container = "Container"
        case runTimeTicks = "RunTimeTicks"
        case supportsDirectPlay = "SupportsDirectPlay"
        case supportsTranscoding = "SupportsTranscoding"
        case transcodingURL = "TranscodingUrl"
        case transcodingInfo = "TranscodingInfo"
        case mediaStreams = "MediaStreams"
    }
}
