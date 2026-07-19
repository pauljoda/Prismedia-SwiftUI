import Foundation

struct GalleryChildGroupsPresentation: Equatable, Sendable {
    let galleryID: UUID
    let subGalleries: [EntityThumbnail]
    let images: [EntityThumbnail]
    let remainingGroups: [EntityGroup]

    static func isAvailable(for parentKind: EntityKind) -> Bool {
        parentKind == .gallery
    }

    init(galleryID: UUID, groups: [EntityGroup]) {
        self.galleryID = galleryID
        subGalleries = Self.uniqueEntities(in: groups.filter { $0.kind == .gallery })
        images = Self.uniqueEntities(in: groups.filter { $0.kind == .image })
        remainingGroups = groups.filter { ![.gallery, .image].contains($0.kind) }
    }

    var imageGridConfiguration: EntityGridConfiguration {
        EntityGridConfiguration(
            title: "Images",
            query: EntityListQuery(kind: .image, sort: "added"),
            defaultDisplayMode: .wall,
            availableDisplayModes: [.wall, .grid, .feed],
            preferencesID: "gallery-\(galleryID.uuidString.lowercased())-images"
        )
    }

    var isEmpty: Bool {
        subGalleries.isEmpty && images.isEmpty && remainingGroups.isEmpty
    }

    private static func uniqueEntities(in groups: [EntityGroup]) -> [EntityThumbnail] {
        var seen = Set<UUID>()
        return groups.flatMap(\.entities).filter { seen.insert($0.id).inserted }
    }
}
