struct VideoTranscodingInfo: Decodable {
    let isVideoDirect: Bool
    let isAudioDirect: Bool
    let videoCodec: String
    let audioCodec: String
    let container: String
}
