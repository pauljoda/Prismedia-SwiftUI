struct VideoMediaStream: Decodable {
    let index: Int?
    let type: String
    let codec: String?
    let codecTag: String?
    let width: Int?
    let height: Int?
    let averageFrameRate: Double?
    let realFrameRate: Double?
    let channels: Int?
    let isDefault: Bool?
    let videoRangeType: String?
    let colorTransfer: String?
    let dolbyVisionProfile: Int?
    let bitDepth: Int?
    let language: String?
    let displayTitle: String?

    enum CodingKeys: String, CodingKey {
        case index = "Index"
        case type = "Type"
        case codec = "Codec"
        case codecTag = "CodecTag"
        case width = "Width"
        case height = "Height"
        case averageFrameRate = "AverageFrameRate"
        case realFrameRate = "RealFrameRate"
        case channels = "Channels"
        case isDefault = "IsDefault"
        case videoRangeType = "VideoRangeType"
        case colorTransfer = "ColorTransfer"
        case dolbyVisionProfile = "DvProfile"
        case bitDepth = "BitDepth"
        case language = "Language"
        case displayTitle = "DisplayTitle"
    }
}
