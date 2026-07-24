import Foundation

enum RequestIdentifyProviderPreferencePolicy {
    static let settingKey = "identify.defaultProviders"

    static func eligibleProviders(
        _ providers: [AdministrativePlugin],
        entityKind: String,
        defaultProviderIDs: [String: String],
        hidesNsfw: Bool
    ) -> [AdministrativePlugin] {
        PluginSearchFieldPolicy.eligibleProviders(
            providers,
            entityKind: entityKind,
            hidesNsfw: hidesNsfw,
            preferredProviderID: defaultProviderID(
                for: entityKind,
                in: defaultProviderIDs
            )
        )
    }

    static func defaultProviderID(
        for entityKind: String,
        in defaultProviderIDs: [String: String]
    ) -> String? {
        let match = defaultProviderIDs.first {
            $0.key.caseInsensitiveCompare(entityKind) == .orderedSame
        }?.value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let match, !match.isEmpty else { return nil }
        return match
    }

    static func defaults(
        from response: AdministrativeSettingsValuesResponse
    ) -> [String: String] {
        response.values[settingKey]?.stringMapValue ?? [:]
    }
}
