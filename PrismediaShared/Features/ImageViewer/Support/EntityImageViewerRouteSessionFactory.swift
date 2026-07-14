import Foundation

@MainActor
enum EntityImageViewerRouteSessionFactory {
    static func make(
        for link: EntityLink,
        sequenceLoader: (any EntityMediaSequenceLoading)?
    ) -> EntityImageViewerSession? {
        guard link.kind == .image, link.intent != .metadata else { return nil }

        let selected =
            link.mediaSequence?.items.first { $0.id == link.entityID }
            ?? link.sourceThumbnail.flatMap { $0.id == link.entityID ? $0 : nil }
            ?? EntityThumbnail(
                id: link.entityID,
                kind: .image,
                title: link.thumbnailPreview?.title ?? "Image",
                parentEntityID: link.parentEntityID,
                parentKind: link.parentKind,
                coverURL: link.thumbnailPreview?.artworkPath
            )
        return EntityImageViewerSession(
            selected: selected,
            sequence: link.mediaSequence,
            sequenceLoader: sequenceLoader
        )
    }
}
