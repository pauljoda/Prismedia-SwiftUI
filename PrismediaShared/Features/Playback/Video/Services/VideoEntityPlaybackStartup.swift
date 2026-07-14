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
        activate(
            resolved,
            VideoInitialResumePosition.resolve(
                detailResumeSeconds: resumeSeconds(in: resolved),
                thumbnailResumeSeconds: ownerLink.thumbnailPreview?.resumeSeconds))
        return resolved
    }
    private static func resumeSeconds(in detail: EntityDetail) -> Double? {
        detail.capabilities.compactMap { capability -> Double? in
            guard case .playback(let playback) = capability else { return nil }
            return playback.resumeSeconds
        }.first
    }
}
