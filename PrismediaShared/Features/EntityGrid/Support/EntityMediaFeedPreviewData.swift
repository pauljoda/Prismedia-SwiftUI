#if DEBUG
    import Foundation

    enum EntityMediaFeedPreviewData {
        static let portraitID = UUID(uuidString: "33333333-3333-3333-3333-333333333333")!
        static let landscapeID = UUID(uuidString: "44444444-4444-4444-4444-444444444444")!

        static let items = [
            EntityThumbnail(
                id: portraitID,
                kind: .image,
                title: "Portrait · 1080 × 1620",
                hasSourceMedia: true
            ),
            EntityThumbnail(
                id: landscapeID,
                kind: .image,
                title: "Landscape · 1920 × 1080",
                hasSourceMedia: true
            ),
        ]

        static let details = Dictionary(
            uniqueKeysWithValues: [
                (portraitID, makeDetail(id: portraitID, title: items[0].title, width: 1_080, height: 1_620)),
                (landscapeID, makeDetail(id: landscapeID, title: items[1].title, width: 1_920, height: 1_080)),
            ]
        )

        private static func makeDetail(
            id: UUID,
            title: String,
            width: Int,
            height: Int
        ) -> EntityDetail {
            let object: [String: Any] = [
                "id": id.uuidString,
                "kind": "image",
                "title": title,
                "hasSourceMedia": true,
                "capabilities": [
                    [
                        "kind": "files",
                        "items": [
                            [
                                "role": "source",
                                "path": "/preview/\(id.uuidString).png",
                                "mimeType": "image/png",
                            ]
                        ],
                    ],
                    [
                        "kind": "technical",
                        "width": width,
                        "height": height,
                    ],
                ],
                "childrenByKind": [],
                "relationships": [],
            ]
            let data = try! JSONSerialization.data(withJSONObject: object)
            return try! PrismediaJSON.decoder().decode(EntityDetail.self, from: data)
        }
    }
#endif
