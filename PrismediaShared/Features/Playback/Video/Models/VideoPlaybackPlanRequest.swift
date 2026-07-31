struct VideoPlaybackPlanRequest: Encodable {
    let enableDirectPlay: Bool
    let enableDirectStream: Bool
    let enableTranscoding = true
    let supportedVideoRangeTypes: [String]
    let profile: AppleVideoPlaybackProfile
    let audioStreamIndex: Int?
    let enableClientToneMapping: Bool
    let sessionID: String?

    enum CodingKeys: String, CodingKey {
        case enableDirectPlay
        case enableDirectStream
        case enableTranscoding
        case supportedVideoRangeTypes
        case profile
        case audioStreamIndex
        case enableClientToneMapping
        case sessionID = "sessionId"
    }

    init(
        mode: VideoPlaybackNegotiationMode,
        audioStreamIndex: Int? = nil,
        preferredEngine: VideoPlaybackEngine = .automatic,
        sessionID: String? = nil
    ) {
        // The raw direct-play endpoint serves the whole source file and cannot
        // honor a server-selected audio stream. When AVFoundation cannot switch locally,
        // retain native video decode through server remux/direct stream while
        // asking the server to select the requested audio stream.
        enableDirectPlay = mode.allowsDirectPlay && audioStreamIndex == nil
        enableDirectStream = mode.allowsDirectStream
        let supportsCompatibilityRenderer =
            preferredEngine != .native
            && VideoPlaybackRendererPolicy.platformSupportsCompatibilityRenderer
        profile = .make(supportsCompatibilityRenderer: supportsCompatibilityRenderer)
        supportedVideoRangeTypes = AppleVideoPlaybackProfile.supportedVideoRangeTypes
        self.audioStreamIndex = audioStreamIndex
        enableClientToneMapping = supportsCompatibilityRenderer
        self.sessionID = sessionID
    }
}
