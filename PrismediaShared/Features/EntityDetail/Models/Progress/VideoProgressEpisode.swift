import Foundation

/// Minimal episode playback state used to blend an in-episode position into a
/// series or season cursor.
struct VideoProgressEpisode: Hashable, Sendable {
    let id: UUID
    let title: String
    let resumeSeconds: Double
    let durationSeconds: Double?
    let isCompleted: Bool

    init(
        id: UUID,
        title: String,
        resumeSeconds: Double,
        durationSeconds: Double?,
        isCompleted: Bool
    ) {
        self.id = id
        self.title = title
        self.resumeSeconds = max(0, resumeSeconds.isFinite ? resumeSeconds : 0)
        self.durationSeconds = durationSeconds
        self.isCompleted = isCompleted
    }

    init(detail: EntityDetail) {
        let playback: EntityPlaybackCapability? = detail.capability()
        let technical: EntityTechnicalCapability? = detail.capability()
        self.init(
            id: detail.id,
            title: detail.title,
            resumeSeconds: playback?.resumeSeconds ?? 0,
            durationSeconds: AudiobookDurationParser.seconds(from: technical?.duration),
            isCompleted: playback?.completedAt != nil
        )
    }

    init(thumbnail: EntityThumbnail) {
        let fraction = min(1, max(0, thumbnail.progress ?? 0))
        self.init(
            id: thumbnail.id,
            title: thumbnail.title,
            resumeSeconds: fraction,
            durationSeconds: 1,
            isCompleted: fraction >= 1
        )
    }
}
