public struct VideoPlaybackDisplayMetadata: Sendable, Equatable {
    public let dynamicRange: VideoPlaybackDynamicRange
    public let frameRate: Double?
    public let width: Int?
    public let height: Int?
    public let codec: String?
    public let dolbyVisionProfile: Int?
    public let bitDepth: Int?

    public init(
        dynamicRange: VideoPlaybackDynamicRange,
        frameRate: Double? = nil,
        width: Int? = nil,
        height: Int? = nil,
        codec: String? = nil,
        dolbyVisionProfile: Int? = nil,
        bitDepth: Int? = nil
    ) {
        self.dynamicRange = dynamicRange
        self.frameRate = frameRate
        self.width = width
        self.height = height
        self.codec = codec
        self.dolbyVisionProfile = dolbyVisionProfile
        self.bitDepth = bitDepth
    }
}
