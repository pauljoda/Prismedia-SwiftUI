struct VideoPlaybackInfoResponse: Decodable {
    let playSessionID: String
    let mediaSources: [VideoMediaSource]

    enum CodingKeys: String, CodingKey {
        case playSessionID = "PlaySessionId"
        case mediaSources = "MediaSources"
    }
}
