import Foundation

public protocol VideoPlaybackReporting: Sendable {
    func reportVideoPlayback(_ event: VideoPlaybackEvent, report: VideoPlaybackReport) async throws
    func markVideoPlayed(videoID: UUID) async throws
}

extension PrismediaAPIClient: VideoPlaybackReporting {}

extension PrismediaEntityDetailLoader: VideoPlaybackReporting {
    public func reportVideoPlayback(_ event: VideoPlaybackEvent, report: VideoPlaybackReport) async throws {
        try await client.reportVideoPlayback(event, report: report)
    }

    public func markVideoPlayed(videoID: UUID) async throws {
        try await client.markVideoPlayed(videoID: videoID)
    }
}
