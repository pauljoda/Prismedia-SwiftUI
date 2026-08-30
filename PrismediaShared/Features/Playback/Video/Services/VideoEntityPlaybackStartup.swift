import Foundation

@MainActor
enum VideoEntityPlaybackStartup {
    static func resolve(
        detail: EntityDetail,
        sourceThumbnail: EntityThumbnail? = nil,
        detailLoader: any EntityDetailLoading
    ) async throws -> EntityDetail {
        guard
            let videoID = PlayableVideoResolver.videoID(
                in: detail,
                sourceThumbnail: sourceThumbnail
            )
        else {
            throw VideoEntityPlaybackStartupError.noPlayableVideo
        }
        guard videoID != detail.id else { return detail }
        return try await detailLoader.loadEntity(id: videoID)
    }
    static func prepare(
        detail: EntityDetail, ownerLink: EntityLink, detailLoader: any EntityDetailLoading,
        activate: (EntityDetail, Double) -> Void
    ) async throws -> EntityDetail {
        let resolved = try await resolve(
            detail: detail,
            sourceThumbnail: ownerLink.sourceThumbnail,
            detailLoader: detailLoader
        )
        let consumption = consumption(in: resolved)
        activate(
            resolved,
            VideoInitialResumePosition.resolve(
                detailResumeSeconds: consumption?.resumeSeconds,
                detailCompletedAt: consumption?.completedAt,
                thumbnailResumeSeconds: ownerLink.thumbnailPreview?.resumeSeconds))
        return resolved
    }
    private static func consumption(in detail: EntityDetail) -> EntityConsumptionCapability? {
        detail.capabilities.compactMap { capability -> EntityConsumptionCapability? in
            guard case .consumption(let playback) = capability else { return nil }
            return playback
        }.first
    }
}
