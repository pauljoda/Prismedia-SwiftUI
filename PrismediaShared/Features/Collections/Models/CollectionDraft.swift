import Foundation

/// Editable fields for a new manual Collection, before it is sent to the server.
struct CollectionDraft: Hashable, Sendable {
    // MARK: - Variables

    var title: String
    var description: String
    var isNsfw: Bool
    var isShared: Bool

    /// The title without surrounding whitespace, as the server stores it.
    var trimmedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// The description without surrounding whitespace, or `nil` when it is blank.
    var trimmedDescription: String? {
        let trimmed = description.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    /// Whether the draft has the title the server requires.
    var canSubmit: Bool {
        !trimmedTitle.isEmpty
    }

    // MARK: - Initializers

    init(
        title: String = "",
        description: String = "",
        isNsfw: Bool = false,
        isShared: Bool = false
    ) {
        self.title = title
        self.description = description
        self.isNsfw = isNsfw
        self.isShared = isShared
    }
}
