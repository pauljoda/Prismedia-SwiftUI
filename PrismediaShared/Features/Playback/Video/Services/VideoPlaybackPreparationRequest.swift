import Foundation

@MainActor
struct VideoPlaybackPreparationRequest {
    let detail: EntityDetail
    let ownerLink: EntityLink
    let detailLoader: any EntityDetailLoading
    let playbackService: any VideoPlaybackServicing
    let session: VideoPlaybackSession?
    let onPlaybackCompleted: @MainActor (UUID) -> Void
}
