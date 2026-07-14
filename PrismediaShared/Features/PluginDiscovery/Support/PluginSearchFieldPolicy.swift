import Foundation

public enum PluginSearchFieldPolicy {
    public static func eligibleProviders(
        _ providers: [AdministrativePlugin],
        entityKind: String,
        hidesNsfw: Bool
    ) -> [AdministrativePlugin] {
        providers
            .filter { provider in
                provider.installed
                    && provider.enabled
                    && provider.missingAuthKeys.isEmpty
                    && (!hidesNsfw || !provider.isNsfw)
                    && support(in: provider, entityKind: entityKind) != nil
            }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    public static func support(
        in provider: AdministrativePlugin,
        entityKind: String
    ) -> AdministrativePluginSupport? {
        provider.supports.first { support in
            support.entityKind.caseInsensitiveCompare(entityKind) == .orderedSame
                && support.actions.contains("search")
                && support.actions.contains("lookup-id")
                && !(support.search?.fields.isEmpty ?? true)
        }
    }

    public static func seedValues(
        for fields: [AdministrativePluginSearchField],
        existing: [String: String],
        title: String
    ) -> [String: String] {
        let firstTextKey = fields.first { $0.type == "text" }?.key
        return Dictionary(
            uniqueKeysWithValues: fields.map { field in
                let value =
                    existing[field.key]
                    ?? (field.key == firstTextKey ? title.trimmingCharacters(in: .whitespacesAndNewlines) : "")
                return (field.key, value)
            })
    }

    public static func submittedValues(
        fields: [AdministrativePluginSearchField],
        values: [String: String]
    ) -> [String: String] {
        let allowedKeys = Set(fields.map(\.key))
        return values.reduce(into: [:]) { result, entry in
            guard allowedKeys.contains(entry.key) else { return }
            let value = entry.value.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !value.isEmpty else { return }
            result[entry.key] = value
        }
    }

    public static func hasRequiredValues(
        fields: [AdministrativePluginSearchField],
        values: [String: String]
    ) -> Bool {
        fields.allSatisfy { field in
            !field.required
                || !(values[field.key] ?? "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .isEmpty
        }
    }

    public static func compatibilityTitle(
        fields: [AdministrativePluginSearchField],
        values: [String: String],
        fallback: String
    ) -> String {
        if let title = trimmedValue(values["title"]) { return title }
        for field in fields where field.type == "text" {
            if let value = trimmedValue(values[field.key]) { return value }
        }
        return fallback.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func trimmedValue(_ value: String?) -> String? {
        guard let value else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
