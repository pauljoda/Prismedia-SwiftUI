import Foundation

public struct VideoSubtitleSettingsResponse: Decodable, Sendable {
    public let values: [String: VideoSubtitleSettingValue]
}
