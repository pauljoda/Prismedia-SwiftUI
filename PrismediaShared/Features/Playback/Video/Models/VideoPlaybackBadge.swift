public struct VideoPlaybackBadge: Equatable, Sendable {
    public enum Tone: Equatable, Sendable { case direct, transcode, neutral, premium }

    public let label: String
    public let systemImage: String?
    public let tone: Tone

    public init(label: String, systemImage: String? = nil, tone: Tone) {
        self.label = label
        self.systemImage = systemImage
        self.tone = tone
    }
}
