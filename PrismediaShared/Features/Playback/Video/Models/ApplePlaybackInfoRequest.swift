struct ApplePlaybackInfoRequest: Encodable {
    let enableDirectPlay: Bool
    let enableDirectStream: Bool
    let enableTranscoding = true
    let supportedVideoRangeTypes: [String]
    let deviceProfile: AppleDeviceProfile
    let audioStreamIndex: Int?

    enum CodingKeys: String, CodingKey {
        case enableDirectPlay = "EnableDirectPlay"
        case enableDirectStream = "EnableDirectStream"
        case enableTranscoding = "EnableTranscoding"
        case supportedVideoRangeTypes = "SupportedVideoRangeTypes"
        case deviceProfile = "DeviceProfile"
        case audioStreamIndex = "AudioStreamIndex"
    }

    init(mode: VideoPlaybackNegotiationMode, audioStreamIndex: Int? = nil) {
        // The raw direct-play endpoint serves the whole source file and cannot
        // honor AudioStreamIndex. When AVFoundation cannot switch locally,
        // retain native video decode through server remux/direct stream while
        // asking the server to select the requested audio stream.
        enableDirectPlay = mode.allowsDirectPlay && audioStreamIndex == nil
        enableDirectStream = mode.allowsDirectStream
        deviceProfile = .current
        supportedVideoRangeTypes = AppleDeviceProfile.supportedVideoRangeTypes
        self.audioStreamIndex = audioStreamIndex
    }
}
