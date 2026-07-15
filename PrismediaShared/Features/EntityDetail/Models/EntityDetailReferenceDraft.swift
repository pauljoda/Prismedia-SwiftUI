import Foundation

struct EntityDetailReferenceDraft: Identifiable, Hashable, Sendable {
    let id: String
    let entityID: UUID?
    let kind: EntityKind
    let title: String
    let artworkPath: String?

    init(thumbnail: EntityThumbnail) {
        id = thumbnail.id.uuidString.lowercased()
        entityID = thumbnail.id
        kind = thumbnail.kind
        title = thumbnail.title
        artworkPath = thumbnail.bestCoverPath
    }

    init(entityID: UUID, kind: EntityKind, title: String, artworkPath: String?) {
        id = entityID.uuidString.lowercased()
        self.entityID = entityID
        self.kind = kind
        self.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        self.artworkPath = artworkPath
    }

    static func new(title: String, kind: EntityKind) -> Self {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        return Self(
            id: "new:\(kind.rawValue):\(trimmed.lowercased())",
            entityID: nil,
            kind: kind,
            title: trimmed,
            artworkPath: nil
        )
    }

    private init(
        id: String,
        entityID: UUID?,
        kind: EntityKind,
        title: String,
        artworkPath: String?
    ) {
        self.id = id
        self.entityID = entityID
        self.kind = kind
        self.title = title
        self.artworkPath = artworkPath
    }

    var normalizedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}
