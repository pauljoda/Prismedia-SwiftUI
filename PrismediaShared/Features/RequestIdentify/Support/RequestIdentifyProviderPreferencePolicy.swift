import Foundation

enum RequestIdentifyProviderPreferencePolicy {
    static let settingKey = PrismediaContractCodes.SettingKey.identifyDefaultProviders

    /// Offers compatible kinds without hiding saved mappings from older or newer plugin catalogs.
    static func editableKinds(
        providers: [AdministrativePlugin], defaults: [String: String], hidesNsfw: Bool
    ) -> [EntityKind] {
        let savedKinds = Set(defaults.keys.map { EntityKind(rawValue: $0.lowercased()) })
        let candidates = Set(generatedEntityKindDefinitions.keys).union(savedKinds)
        return candidates.filter { kind in
            savedKinds.contains(kind)
                || !identifyProviders(
                    providers, entityKind: kind.rawValue,
                    defaultProviderIDs: [:], hidesNsfw: hidesNsfw
                ).isEmpty
        }.sorted { $0.displayLabel.localizedStandardCompare($1.displayLabel) == .orderedAscending }
    }

    /// Changes only one kind's override; nil restores automatic selection and preserves unrelated entries.
    static func updatingDefaults(
        _ defaults: [String: String], kind: EntityKind, providerID: String?
    ) -> [String: String] {
        var updated = defaults.filter { $0.key.caseInsensitiveCompare(kind.rawValue) != .orderedSame }
        if let providerID, !providerID.isEmpty { updated[kind.rawValue] = providerID }
        return updated
    }

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

    static func identifyProviders(
        _ providers: [AdministrativePlugin],
        entityKind: String,
        defaultProviderIDs: [String: String],
        hidesNsfw: Bool
    ) -> [AdministrativePlugin] {
        let normalizedKind = entityKind.lowercased()
        let pluginFallbackKind = EntityKind(rawValue: normalizedKind)
            .definition?.identifyPluginFallbackKind?.rawValue
        let preferredProviderID = defaultProviderID(
            for: entityKind,
            in: defaultProviderIDs
        )

        return
            providers
            .filter { provider in
                provider.installed
                    && provider.enabled
                    && provider.missingAuthKeys.isEmpty
                    && (!hidesNsfw || !provider.isNsfw)
                    && provider.supports.contains { support in
                        let supportedKind = support.entityKind.lowercased()
                        return supportedKind == normalizedKind
                            || supportedKind == pluginFallbackKind
                    }
            }
            .sorted { left, right in
                let leftIsPreferred = providerIDsEqual(left.id, preferredProviderID)
                let rightIsPreferred = providerIDsEqual(right.id, preferredProviderID)
                if leftIsPreferred != rightIsPreferred {
                    return leftIsPreferred
                }
                return left.name.localizedStandardCompare(right.name) == .orderedAscending
            }
    }

    static func resolvedProviderID(
        in providers: [AdministrativePlugin],
        restoredProviderID: String?,
        currentProviderID: String?
    ) -> String {
        if let restored = canonicalProviderID(restoredProviderID, in: providers) {
            return restored
        }
        if let current = canonicalProviderID(currentProviderID, in: providers) {
            return current
        }
        return providers.first?.id ?? ""
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

    private static func canonicalProviderID(
        _ providerID: String?,
        in providers: [AdministrativePlugin]
    ) -> String? {
        guard let providerID else { return nil }
        return providers.first {
            $0.id.caseInsensitiveCompare(providerID) == .orderedSame
        }?.id
    }

    private static func providerIDsEqual(
        _ lhs: String,
        _ rhs: String?
    ) -> Bool {
        guard let rhs else { return false }
        return lhs.caseInsensitiveCompare(rhs) == .orderedSame
    }
}
