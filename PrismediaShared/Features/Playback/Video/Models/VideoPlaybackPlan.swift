import Foundation

public struct VideoPlaybackPlan: Sendable {
    public let videoID: UUID
    public let url: URL
    public let delivery: VideoPlaybackDelivery
    public let playSessionID: String
    public let mediaSourceID: String
    public let durationSeconds: Double
    public let badges: [VideoPlaybackBadge]
    public let audioStreams: [VideoPlaybackStreamChoice]
    public let httpHeaders: [String: String]
    public let diagnostics: VideoPlaybackDiagnostics?
    public let displayMetadata: VideoPlaybackDisplayMetadata?
    public let requiresNativePlayabilityCheck: Bool
    public let renderer: VideoPlaybackRenderer

    public init(
        videoID: UUID, url: URL, delivery: VideoPlaybackDelivery, playSessionID: String, mediaSourceID: String,
        durationSeconds: Double, badges: [VideoPlaybackBadge] = [], audioStreams: [VideoPlaybackStreamChoice] = [],
        httpHeaders: [String: String] = [:], diagnostics: VideoPlaybackDiagnostics? = nil,
        displayMetadata: VideoPlaybackDisplayMetadata? = nil,
        requiresNativePlayabilityCheck: Bool = false,
        renderer: VideoPlaybackRenderer = .native
    ) {
        self.videoID = videoID
        self.url = url
        self.delivery = delivery
        self.playSessionID = playSessionID
        self.mediaSourceID = mediaSourceID
        self.durationSeconds = durationSeconds
        self.badges = badges
        self.audioStreams = audioStreams
        self.httpHeaders = httpHeaders
        self.diagnostics = diagnostics
        self.displayMetadata = displayMetadata
        self.requiresNativePlayabilityCheck = requiresNativePlayabilityCheck
        self.renderer = renderer
    }
}
