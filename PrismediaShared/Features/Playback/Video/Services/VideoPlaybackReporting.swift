import Foundation

public protocol VideoPlaybackReporting: Sendable {
    func reportVideoPlayback(_ event: VideoPlaybackEvent, report: VideoPlaybackReport) async throws
}

extension PrismediaAPIClient: VideoPlaybackReporting {}

extension PrismediaEntityDetailLoader: VideoPlaybackReporting {
    public func reportVideoPlayback(_ event: VideoPlaybackEvent, report: VideoPlaybackReport) async throws {
        try await client.reportVideoPlayback(event, report: report)
    }
}
