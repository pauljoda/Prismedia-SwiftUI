struct VideoTranscodingInfo: Decodable {
    let isVideoDirect: Bool
    let videoCodec: String?
    let audioCodec: String?
    let transcodeReasons: [String]?

    enum CodingKeys: String, CodingKey {
        case isVideoDirect = "IsVideoDirect"
        case videoCodec = "VideoCodec"
        case audioCodec = "AudioCodec"
        case transcodeReasons = "TranscodeReasons"
    }
}
