import Foundation

extension PrismediaAPIClient {
    public func videoSubtitleSettings() async throws -> VideoSubtitleSettings {
        let keys = [
            "subtitles.autoEnable",
            "subtitles.preferredLanguages",
            "subtitles.style",
            "subtitles.fontScale",
            "subtitles.positionPercent",
            "subtitles.opacity",
        ]
        let response = try await send(
            VideoSubtitleSettingsResponse.self,
            path: "/api/settings/values",
            queryItems: keys.map { URLQueryItem(name: "keys", value: $0) }
        )
        return VideoSubtitleSettings(values: response.values)
    }
}
