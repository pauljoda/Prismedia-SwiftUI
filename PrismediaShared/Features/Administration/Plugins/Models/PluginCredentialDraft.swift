import Foundation

/// Unsaved replacements and explicit removals. Blank fields preserve server values.
struct PluginCredentialDraft {
    var values: [String: String] = [:]
    private(set) var clearedKeys = Set<String>()

    subscript(key: String) -> String {
        get { values[key, default: ""] }
        set { values[key] = newValue }
    }

    var hasChanges: Bool {
        values.values.contains { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            || !clearedKeys.isEmpty
    }

    mutating func setCleared(_ cleared: Bool, for key: String) {
        if cleared { clearedKeys.insert(key) } else { clearedKeys.remove(key) }
    }
}
