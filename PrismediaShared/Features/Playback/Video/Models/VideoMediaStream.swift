struct VideoMediaStream: Decodable {
    let index: Int?
    let type: String
    let codec: String?
    let codecTag: String?
    let width: Int?
    let height: Int?
    let channels: Int?
    let isDefault: Bool?
    let videoRangeType: String?
    let language: String?
    let displayTitle: String?

    enum CodingKeys: String, CodingKey {
        case index = "Index"
        case type = "Type"
        case codec = "Codec"
        case codecTag = "CodecTag"
        case width = "Width"
        case height = "Height"
        case channels = "Channels"
        case isDefault = "IsDefault"
        case videoRangeType = "VideoRangeType"
        case language = "Language"
        case displayTitle = "DisplayTitle"
    }
}
