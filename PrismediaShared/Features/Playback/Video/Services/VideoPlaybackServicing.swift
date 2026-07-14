import Foundation

public protocol VideoPlaybackServicing: Sendable {
    func negotiateVideoPlayback(videoID: UUID, forceTranscode: Bool) async throws -> VideoPlaybackPlan
    func negotiateVideoPlayback(videoID: UUID, forceTranscode: Bool, audioStreamIndex: Int?) async throws
        -> VideoPlaybackPlan
    func mediaData(for path: String) async throws -> Data
    func authenticatedMediaURL(for path: String) -> URL?
    func videoSubtitleSettings() async throws -> VideoSubtitleSettings
}

extension VideoPlaybackServicing {
    public func negotiateVideoPlayback(videoID: UUID, forceTranscode: Bool, audioStreamIndex: Int?) async throws
        -> VideoPlaybackPlan
    {
        try await negotiateVideoPlayback(videoID: videoID, forceTranscode: forceTranscode)
    }

    public func videoSubtitleSettings() async throws -> VideoSubtitleSettings { .default }
}

extension PrismediaAPIClient: VideoPlaybackServicing {}
extension PrismediaEntityDetailLoader: VideoPlaybackServicing {
    public func negotiateVideoPlayback(videoID: UUID, forceTranscode: Bool) async throws -> VideoPlaybackPlan {
        try await client.negotiateVideoPlayback(videoID: videoID, forceTranscode: forceTranscode)
    }
    public func negotiateVideoPlayback(videoID: UUID, forceTranscode: Bool, audioStreamIndex: Int?) async throws
        -> VideoPlaybackPlan
    {
        try await client.negotiateVideoPlayback(
            videoID: videoID, forceTranscode: forceTranscode, audioStreamIndex: audioStreamIndex)
    }
    public func mediaData(for path: String) async throws -> Data { try await client.mediaData(for: path) }
    public func authenticatedMediaURL(for path: String) -> URL? { client.authenticatedMediaURL(for: path) }
    public func videoSubtitleSettings() async throws -> VideoSubtitleSettings {
        try await client.videoSubtitleSettings()
    }
}
