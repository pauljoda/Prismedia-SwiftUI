import SwiftUI

#if DEBUG
    enum CollectionMembersPreviewFixture {
        static let mixed = [
            EntityThumbnail(
                id: UUID(uuidString: "11E4AB39-6CF8-4C16-946E-651561DA3FEF")!,
                kind: .movie,
                title: "Arrival"
            ),
            EntityThumbnail(
                id: UUID(uuidString: "E611E103-F6CD-49B0-8DF4-B1B2E9780493")!,
                kind: .book,
                title: "Stories of Your Life"
            ),
            EntityThumbnail(
                id: UUID(uuidString: "79B29DAA-1C2D-49BB-88DA-D713C46253B8")!,
                kind: .audioTrack,
                title: "On the Nature of Daylight"
            ),
            EntityThumbnail(
                id: UUID(uuidString: "85203A3D-D045-4645-B8F2-9528E22E3301")!,
                kind: .gallery,
                title: "Production Gallery"
            ),
        ]
    }

#endif
