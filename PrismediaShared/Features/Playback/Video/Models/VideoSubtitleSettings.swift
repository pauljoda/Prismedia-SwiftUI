import Foundation

public struct VideoSubtitleSettings: Equatable, Sendable {
    public static let `default` = VideoSubtitleSettings(
        autoEnable: false,
        preferredLanguages: ["en", "eng"],
        appearance: .default
    )

    public let autoEnable: Bool
    public let preferredLanguages: [String]
    public let appearance: VideoSubtitleAppearance

    public init(
        autoEnable: Bool,
        preferredLanguages: [String],
        appearance: VideoSubtitleAppearance
    ) {
        self.autoEnable = autoEnable
        self.preferredLanguages = preferredLanguages
        self.appearance = appearance
    }

    public init(values: [String: VideoSubtitleSettingValue]) {
        let defaults = Self.default
        autoEnable = values["subtitles.autoEnable"]?.boolValue ?? defaults.autoEnable
        preferredLanguages =
            values["subtitles.preferredLanguages"]?.stringListValue
            ?? defaults.preferredLanguages
        appearance = VideoSubtitleAppearance(
            style: values["subtitles.style"]?.stringValue
                .flatMap(VideoSubtitleDisplayStyle.init(rawValue:))
                ?? defaults.appearance.style,
            fontScale: values["subtitles.fontScale"]?.numberValue
                ?? defaults.appearance.fontScale,
            positionPercent: values["subtitles.positionPercent"]?.numberValue
                ?? defaults.appearance.positionPercent,
            opacity: values["subtitles.opacity"]?.numberValue
                ?? defaults.appearance.opacity
        )
    }
}

extension VideoSubtitleSettingValue {
    fileprivate var boolValue: Bool? {
        guard case .bool(let value) = self else { return nil }
        return value
    }

    fileprivate var numberValue: Double? {
        guard case .number(let value) = self else { return nil }
        return value
    }

    fileprivate var stringValue: String? {
        guard case .string(let value) = self else { return nil }
        return value
    }

    fileprivate var stringListValue: [String]? {
        guard case .stringList(let value) = self else { return nil }
        return value
    }
}
