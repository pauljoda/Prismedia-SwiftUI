import Foundation

/// Resolves the next episode without mutating playback. The page-owned
/// lifecycle check prevents delayed I/O from producing an off-page activation.
@MainActor
struct VideoPlaybackAdvanceResolver {
    private let loader: any EntityDetailLoading

    init(loader: any EntityDetailLoading) {
        self.loader = loader
    }

    func resolveNext(
        after completed: EntityDetail,
        lifecycleIsCurrent: @escaping @MainActor () -> Bool
    ) async -> VideoPlaybackAdvanceResolution? {
        guard let parentID = completed.parentEntityID else { return nil }
        do {
            let parent = try await loader.loadEntity(id: parentID)
            guard !Task.isCancelled, lifecycleIsCurrent() else { return nil }
            guard let episodeGroup = parent.childrenByKind.first(where: { $0.kind == .video }),
                let nextEpisode = VideoPlaybackSequence.nextEpisode(
                    after: completed.id,
                    in: episodeGroup
                )
            else { return nil }

            let nextDetail = try await loader.loadEntity(id: nextEpisode.id)
            guard !Task.isCancelled, lifecycleIsCurrent() else { return nil }
            return VideoPlaybackAdvanceResolution(
                detail: nextDetail,
                link: EntityLink(thumbnail: nextEpisode)
            )
        } catch {
            return nil
        }
    }
}
