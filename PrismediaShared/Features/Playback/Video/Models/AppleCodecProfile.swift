struct AppleCodecProfile: Encodable {
    let type: String
    let codec: String
    let conditions: [AppleProfileCondition]

    enum CodingKeys: String, CodingKey {
        case type = "Type"
        case codec = "Codec"
        case conditions = "Conditions"
    }
}
