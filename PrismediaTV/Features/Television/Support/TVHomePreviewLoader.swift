import SwiftUI

#if os(tvOS)

    #if DEBUG
        struct TVHomePreviewLoader: TVHomeLoading {
            let item = EntityThumbnail(
                id: UUID(uuidString: "77777777-7777-7777-7777-777777777777")!,
                kind: .movie,
                title: "Signal at Midnight",
                progress: 0.42,
                resumeSeconds: 1_204
            )

            func load(shelf: TVHomeShelf) async throws -> [EntityThumbnail] {
                shelf.id == "in-progress" || shelf.id == "movies" ? [item] : []
            }
        }

    #endif
#endif
