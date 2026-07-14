#if DEBUG
    import Foundation

    struct VideoPlaybackPreviewLoader: EntityDetailLoading {
        let detail: EntityDetail
        func loadEntity(id: UUID) async throws -> EntityDetail { detail }
    }
#endif
