import Foundation

public struct EntityGridPreferencesStore: @unchecked Sendable {
    private static let keyPrefix = "prismedia.entity-grid.preferences.v1."
    private static let presetKeyPrefix = "prismedia.entity-grid.presets.v1."

    private let defaults: UserDefaults?
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    public static var standard: Self {
        EntityGridPreferencesStore(defaults: .standard)
    }

    /// Useful for deterministic previews and surfaces that intentionally do
    /// not participate in restoration.
    public static var disabled: Self {
        EntityGridPreferencesStore(defaults: nil)
    }

    public init(defaults: UserDefaults) {
        self.defaults = defaults
        encoder = JSONEncoder()
        decoder = JSONDecoder()
    }

    private init(defaults: UserDefaults?) {
        self.defaults = defaults
        encoder = JSONEncoder()
        decoder = JSONDecoder()
    }

    public func load(for identifier: String) -> EntityGridPreferences? {
        guard
            let data = defaults?.data(forKey: key(for: identifier)),
            let preferences = try? decoder.decode(EntityGridPreferences.self, from: data)
        else { return nil }
        return preferences
    }

    public func save(_ preferences: EntityGridPreferences, for identifier: String) {
        guard let defaults, let data = try? encoder.encode(preferences) else { return }
        defaults.set(data, forKey: key(for: identifier))
    }

    public func reset(for identifier: String) {
        defaults?.removeObject(forKey: key(for: identifier))
    }

    public func loadPresets(for identifier: String) -> [EntityGridPreset] {
        guard
            let data = defaults?.data(forKey: presetKey(for: identifier)),
            let presets = try? decoder.decode([EntityGridPreset].self, from: data)
        else { return [] }
        return presets.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    public func savePreset(
        named name: String,
        preferences: EntityGridPreferences,
        for identifier: String
    ) {
        guard let defaults else { return }
        let normalizedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedName.isEmpty else { return }
        var presets = loadPresets(for: identifier)
        if let index = presets.firstIndex(where: {
            $0.name.compare(normalizedName, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame
        }) {
            presets[index] = EntityGridPreset(
                id: presets[index].id,
                name: presets[index].name,
                preferences: preferences
            )
        } else {
            presets.append(EntityGridPreset(name: normalizedName, preferences: preferences))
        }
        guard let data = try? encoder.encode(presets) else { return }
        defaults.set(data, forKey: presetKey(for: identifier))
    }

    public func deletePreset(id: UUID, for identifier: String) {
        guard let defaults else { return }
        let presets = loadPresets(for: identifier).filter { $0.id != id }
        guard let data = try? encoder.encode(presets) else { return }
        defaults.set(data, forKey: presetKey(for: identifier))
    }

    private func key(for identifier: String) -> String {
        Self.keyPrefix + identifier
    }

    private func presetKey(for identifier: String) -> String {
        Self.presetKeyPrefix + identifier
    }
}
