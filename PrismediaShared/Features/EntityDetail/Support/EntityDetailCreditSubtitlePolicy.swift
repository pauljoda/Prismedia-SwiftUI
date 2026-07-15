import Foundation

struct EntityDetailCreditSubtitlePolicy {
    static func subtitle(for metadata: EntityCreditMetadata) -> String? {
        if let character = firstNonempty(metadata.characters) ?? nonempty(metadata.character) {
            return character
        }

        guard let role = firstNonempty(metadata.roles) ?? nonempty(metadata.role) else {
            return nil
        }
        guard role.lowercased() != "person" else { return nil }
        return
            role
            .replacingOccurrences(of: "-", with: " ")
            .replacingOccurrences(of: "_", with: " ")
            .split(separator: " ")
            .map { $0.prefix(1).uppercased() + $0.dropFirst().lowercased() }
            .joined(separator: " ")
    }

    private static func firstNonempty(_ values: [String]) -> String? {
        values.lazy.compactMap(nonempty).first
    }

    private static func nonempty(_ value: String?) -> String? {
        let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed?.isEmpty == false ? trimmed : nil
    }
}
