struct AppleDirectPlayProfile: Encodable {
    let type: String
    let container: String
    let videoCodec: String
    let audioCodec: String

    enum CodingKeys: String, CodingKey {
        case type = "Type"
        case container = "Container"
        case videoCodec = "VideoCodec"
        case audioCodec = "AudioCodec"
    }
}
