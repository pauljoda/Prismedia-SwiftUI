import Foundation

enum EntityDetailReferenceSelectionPolicy {
    static func contains(
        _ candidate: EntityDetailReferenceDraft,
        in selection: [EntityDetailReferenceDraft]
    ) -> Bool {
        selection.contains { selected in
            if let candidateID = candidate.entityID, let selectedID = selected.entityID {
                return candidateID == selectedID
            }
            return candidate.normalizedTitle == selected.normalizedTitle
        }
    }

    static func canCreate(
        title: String,
        results: [EntityDetailReferenceDraft],
        selection: [EntityDetailReferenceDraft]
    ) -> Bool {
        let normalized = title.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !normalized.isEmpty else { return false }
        return !(results + selection).contains { $0.normalizedTitle == normalized }
    }
}
