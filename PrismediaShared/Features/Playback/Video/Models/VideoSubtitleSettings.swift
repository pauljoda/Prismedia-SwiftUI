import Foundation

public struct VideoSubtitleSettings: Equatable, Sendable {
    public static let `default` = VideoSubtitleSettings(
        autoEnable: false,
        preferredTerms: [
            SubtitlePreferenceTerm(term: "English", weight: 100),
            SubtitlePreferenceTerm(term: "Eng", weight: 80),
        ],
        appearance: .default
    )

    public let autoEnable: Bool
    public let preferredTerms: [SubtitlePreferenceTerm]
    public let appearance: VideoSubtitleAppearance

    public init(
        autoEnable: Bool,
        preferredTerms: [SubtitlePreferenceTerm],
        appearance: VideoSubtitleAppearance
    ) {
        self.autoEnable = autoEnable
        self.preferredTerms = preferredTerms
        self.appearance = appearance
    }

    public init(values: [String: VideoSubtitleSettingValue]) {
        let defaults = Self.default
        autoEnable = values["subtitles.autoEnable"]?.boolValue ?? defaults.autoEnable
        preferredTerms =
            values["subtitles.preferredLanguages"]?.weightedTermListValue
            ?? values["subtitles.preferredLanguages"]?.legacyWeightedTerms
            ?? defaults.preferredTerms
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

    fileprivate var weightedTermListValue: [SubtitlePreferenceTerm]? {
        guard case .weightedTermList(let value) = self else { return nil }
        return value
    }

    fileprivate var legacyWeightedTerms: [SubtitlePreferenceTerm]? {
        guard case .stringList(let values) = self else { return nil }
        return values.enumerated().map { index, term in
            SubtitlePreferenceTerm(term: term, weight: max(1, 100 - index))
        }
    }
}
