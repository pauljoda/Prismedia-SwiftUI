struct VideoPlaybackPlanResponse: Decodable {
    let sessionID: String
    let source: VideoPlaybackSource

    enum CodingKeys: String, CodingKey {
        case sessionID = "sessionId"
        case source
    }
}
