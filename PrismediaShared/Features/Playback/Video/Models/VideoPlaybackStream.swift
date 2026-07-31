struct VideoPlaybackStream: Decodable {
    let index: Int
    let type: String
    let codec: String?
    let width: Int?
    let height: Int?
    let averageFrameRate: Double?
    let channels: Int?
    let isDefault: Bool
    let videoRangeType: String?
    let colorTransfer: String?
    let dolbyVisionProfile: Int?
    let bitDepth: Int?
    let language: String?
    let displayTitle: String?
    private enum CodingKeys: String, CodingKey {
        case index, type, codec, width, height, averageFrameRate, channels, isDefault
        case videoRangeType, colorTransfer, bitDepth, language, displayTitle
        case dolbyVisionProfile = "dvProfile"
    }
}
