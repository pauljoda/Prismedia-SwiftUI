import Foundation

struct EntityDetailReferenceDraft: Identifiable, Hashable, Sendable {
    let id: String
    let entityID: UUID?
    let kind: EntityKind
    let title: String
    let artworkPath: String?
    let sourceThumbnail: EntityThumbnail?

    init(thumbnail: EntityThumbnail) {
        id = thumbnail.id.uuidString.lowercased()
        entityID = thumbnail.id
        kind = thumbnail.kind
        title = thumbnail.title
        artworkPath = thumbnail.bestCoverPath
        sourceThumbnail = thumbnail
    }

    init(entityID: UUID, kind: EntityKind, title: String, artworkPath: String?) {
        id = entityID.uuidString.lowercased()
        self.entityID = entityID
        self.kind = kind
        self.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        self.artworkPath = artworkPath
        sourceThumbnail = nil
    }

    static func new(title: String, kind: EntityKind) -> Self {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        return Self(
            id: "new:\(kind.rawValue):\(trimmed.lowercased())",
            entityID: nil,
            kind: kind,
            title: trimmed,
            artworkPath: nil,
            sourceThumbnail: nil
        )
    }

    private init(
        id: String,
        entityID: UUID?,
        kind: EntityKind,
        title: String,
        artworkPath: String?,
        sourceThumbnail: EntityThumbnail?
    ) {
        self.id = id
        self.entityID = entityID
        self.kind = kind
        self.title = title
        self.artworkPath = artworkPath
        self.sourceThumbnail = sourceThumbnail
    }

    var normalizedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
            && lhs.entityID == rhs.entityID
            && lhs.kind == rhs.kind
            && lhs.title == rhs.title
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(entityID)
        hasher.combine(kind)
        hasher.combine(title)
    }
}
