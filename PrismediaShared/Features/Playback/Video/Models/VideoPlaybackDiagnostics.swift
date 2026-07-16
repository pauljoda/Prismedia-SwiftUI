public struct VideoPlaybackDiagnostics: Equatable, Sendable {
    public let sourceContainer: String?
    public let sourceVideoCodec: String?
    public let sourceVideoCodecTag: String?
    public let sourceAudioCodec: String?
    public let outputVideoCodec: String?
    public let outputAudioCodec: String?
    public let transcodeReasons: [String]

    public init(
        sourceContainer: String?,
        sourceVideoCodec: String?,
        sourceVideoCodecTag: String?,
        sourceAudioCodec: String?,
        outputVideoCodec: String?,
        outputAudioCodec: String?,
        transcodeReasons: [String]
    ) {
        self.sourceContainer = sourceContainer
        self.sourceVideoCodec = sourceVideoCodec
        self.sourceVideoCodecTag = sourceVideoCodecTag
        self.sourceAudioCodec = sourceAudioCodec
        self.outputVideoCodec = outputVideoCodec
        self.outputAudioCodec = outputAudioCodec
        self.transcodeReasons = transcodeReasons
    }
}
