import Foundation

/// Human-readable suggestions for language-code settings; saved codes remain authoritative.
enum AdministrativeLanguageCatalog {
    static func supports(key: String) -> Bool {
        key == PrismediaContractCodes.SettingKey.playbackAudioPreferredLanguages
            || key == PrismediaContractCodes.SettingKey.subtitlesAutoDownloadLanguages
    }

    static func option(for code: String, locale: Locale = .current) -> AdministrativeSettingOption {
        AdministrativeSettingOption(
            value: code,
            label: locale.localizedString(forIdentifier: code) ?? code,
            description: code
        )
    }

    static func options(locale: Locale = .current) -> [AdministrativeSettingOption] {
        Locale.LanguageCode.isoLanguageCodes
            .map { option(for: $0.identifier, locale: locale) }
            .sorted { $0.label.localizedStandardCompare($1.label) == .orderedAscending }
    }

    static func matching(
        _ query: String,
        in options: [AdministrativeSettingOption]
    ) -> [AdministrativeSettingOption] {
        let query = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return options }
        return options.filter {
            $0.label.localizedStandardContains(query) || $0.value.localizedStandardContains(query)
        }
    }
}
