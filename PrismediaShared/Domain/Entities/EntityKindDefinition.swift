import Foundation

/// Generated client snapshot of one canonical backend Entity-kind definition.
public struct EntityKindDefinition: Hashable, Sendable {
    public let kind: EntityKind
    public let displayName: String
    public let groupLabel: String
    public let category: String
    public let storageShape: String
    public let presentation: EntityKindPresentation
    public let supportsFileDeletion: Bool
    public let supportsRequests: Bool
    public let enumeratesIdentifyChildren: Bool

    public init(
        kind: EntityKind,
        displayName: String,
        groupLabel: String,
        category: String,
        storageShape: String,
        presentation: EntityKindPresentation,
        supportsFileDeletion: Bool,
        supportsRequests: Bool,
        enumeratesIdentifyChildren: Bool
    ) {
        self.kind = kind
        self.displayName = displayName
        self.groupLabel = groupLabel
        self.category = category
        self.storageShape = storageShape
        self.presentation = presentation
        self.supportsFileDeletion = supportsFileDeletion
        self.supportsRequests = supportsRequests
        self.enumeratesIdentifyChildren = enumeratesIdentifyChildren
    }
}

public extension EntityKind {
    /// Canonical generated definition for this kind, or nil for a newer server kind unknown to the app build.
    var definition: EntityKindDefinition? {
        generatedEntityKindDefinitions[self]
    }

    var displayLabel: String {
        definition?.displayName
            ?? rawValue.replacingOccurrences(of: "-", with: " ").capitalized
    }

    var groupLabel: String {
        definition?.groupLabel ?? displayLabel
    }

    var thumbnailAspectRatio: Double {
        guard let presentation = definition?.presentation,
              presentation.thumbnailHeight > 0
        else { return 1 }
        return Double(presentation.thumbnailWidth) / Double(presentation.thumbnailHeight)
    }

    var prefersWideThumbnail: Bool {
        thumbnailAspectRatio > 1
    }
}
