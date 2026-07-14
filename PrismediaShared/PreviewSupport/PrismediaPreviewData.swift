import Foundation

enum PrismediaPreviewData {
    static let videos: [EntityThumbnail] = [
        EntityThumbnail(
            id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
            kind: .video,
            title: "@BrownDerbyHistoricVids Little bit of Hollywood? Okayyy.",
            coverURL: "/preview/video-1.jpg",
            meta: [
                EntityThumbnailMeta(icon: "duration", label: "29:25"),
                EntityThumbnailMeta(icon: "video", label: "720p"),
                EntityThumbnailMeta(icon: "codec", label: "H264"),
                EntityThumbnailMeta(icon: "format", label: "MATROSKA"),
            ],
            rating: 4,
            isFavorite: true,
            isOrganized: true,
            hasSourceMedia: true,
            progress: 0.37,
            playCount: 2,
            genres: ["Comedy", "Television"]
        ),
        EntityThumbnail(
            id: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
            kind: .video,
            title: "Bahld Harmon birthplace (disputed)",
            coverURL: "/preview/video-2.jpg",
            meta: [
                EntityThumbnailMeta(icon: "duration", label: "30:32"),
                EntityThumbnailMeta(icon: "video", label: "1440p"),
                EntityThumbnailMeta(icon: "codec", label: "HEVC"),
                EntityThumbnailMeta(icon: "format", label: "MATROSKA"),
            ],
            rating: 3,
            isNsfw: true,
            isWanted: true,
            wantedStatus: AcquisitionStatus(rawValue: "downloading"),
            progress: 0.08
        ),
        EntityThumbnail(
            id: UUID(uuidString: "33333333-3333-3333-3333-333333333333")!,
            kind: .video,
            title: "Happy Birthday, a friend at the patio table",
            coverURL: "/preview/video-3.jpg",
            meta: [
                EntityThumbnailMeta(icon: "duration", label: "21:04"),
                EntityThumbnailMeta(icon: "video", label: "1080p"),
                EntityThumbnailMeta(icon: "codec", label: "H264"),
            ],
            isOrganized: true
        ),
    ]

    static let series = EntityThumbnail(
        id: UUID(uuidString: "44444444-4444-4444-4444-444444444444")!,
        kind: .videoSeries,
        title: "The Chair Company",
        coverURL: "/preview/series-chair-company.jpg",
        meta: [
            EntityThumbnailMeta(icon: "count", label: "8 episodes"),
            EntityThumbnailMeta(icon: "calendar", label: "2025"),
        ],
        progress: 0.5
    )

    static let gallery = EntityThumbnail(
        id: UUID(uuidString: "55555555-5555-5555-5555-555555555555")!,
        kind: .gallery,
        title: "Gallery",
        coverURL: "/preview/gallery.jpg",
        meta: [
            EntityThumbnailMeta(icon: "image", label: "56 images"),
            EntityThumbnailMeta(icon: "calendar", label: "Scanned"),
        ],
        progress: 0.82
    )

    static let book = EntityThumbnail(
        id: UUID(uuidString: "66666666-6666-6666-6666-666666666666")!,
        kind: .book,
        title: "Midnight Console Vol. 1",
        coverURL: "/preview/book.jpg",
        meta: [
            EntityThumbnailMeta(icon: "book", label: "Comic Archive"),
            EntityThumbnailMeta(icon: "chapter", label: "12 chapters"),
        ],
        progress: 0.24
    )

    static let person = EntityThumbnail(
        id: UUID(uuidString: "77777777-7777-7777-7777-777777777777")!,
        kind: .person,
        title: "Ron Trosper",
        coverURL: "/preview/person.jpg",
        meta: [
            EntityThumbnailMeta(icon: "video", label: "14 videos"),
            EntityThumbnailMeta(icon: "gallery", label: "3 galleries"),
        ],
        rating: 5
    )

    static let allEntities: [EntityThumbnail] = videos + [series, gallery, book, person]

    static let user = UserAccount(
        id: UUID(uuidString: "eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee")!,
        username: "preview",
        displayName: "Preview User",
        role: .admin,
        allowNsfw: true,
        canCreateLibraries: true
    )

    @MainActor
    static func model(signedIn: Bool = false) -> PrismediaAppEnvironment {
        let session =
            signedIn
            ? AuthSession(
                serverURL: URL(string: "http://preview.prismedia.local")!,
                accessToken: "preview-token",
                user: user
            ) : nil

        return PrismediaAppEnvironment(
            sessionStore: makePreviewSessionStore(session: session),
            clientFactory: {
                PrismediaAPIClient(
                    serverURL: $0,
                    loader: makePreviewHTTPDataLoader(items: allEntities)
                )
            },
            artworkLoader: makePreviewArtworkLoader(),
            initialSession: session,
            restoreOnInit: false
        )
    }
}
