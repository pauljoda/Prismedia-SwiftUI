struct VideoDirectPlayProfileRequest: Encodable {
    let type: String
    let container: String
    let videoCodec: String
    let audioCodec: String
}
