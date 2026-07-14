import Foundation

enum EntityImageViewerPreviewData {
    static let firstID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
    static let secondID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!

    static let items = [
        EntityThumbnail(
            id: firstID,
            kind: .image,
            title: "Blue Hour",
            hasSourceMedia: true
        ),
        EntityThumbnail(
            id: secondID,
            kind: .image,
            title: "Studio Light",
            hasSourceMedia: true
        ),
    ]

    static let details = Dictionary(
        uniqueKeysWithValues: items.map { item in
            (
                item.id,
                EntityDetail(
                    id: item.id,
                    kind: .image,
                    title: item.title,
                    parentEntityID: nil,
                    sortOrder: nil,
                    hasSourceMedia: true,
                    capabilities: [
                        .files(
                            EntityItemsCapability(
                                items: [
                                    EntityFile(
                                        role: "source",
                                        path: "/preview/\(item.id.uuidString).png",
                                        mimeType: "image/png"
                                    )
                                ]
                            )
                        )
                    ],
                    childrenByKind: [],
                    relationships: []
                )
            )
        }
    )

}
