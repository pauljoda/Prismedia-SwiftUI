struct AppleTranscodingProfile: Encodable {
    let type: String
    let container: String
    let protocolName: String
    let videoCodec: String
    let audioCodec: String
    let context: String
    let breakOnNonKeyFrames: Bool
    let maxAudioChannels: String
    let minSegments: Int
    let enableSubtitlesInManifest: Bool

    enum CodingKeys: String, CodingKey {
        case type = "Type"
        case container = "Container"
        case protocolName = "Protocol"
        case videoCodec = "VideoCodec"
        case audioCodec = "AudioCodec"
        case context = "Context"
        case breakOnNonKeyFrames = "BreakOnNonKeyFrames"
        case maxAudioChannels = "MaxAudioChannels"
        case minSegments = "MinSegments"
        case enableSubtitlesInManifest = "EnableSubtitlesInManifest"
    }
}
