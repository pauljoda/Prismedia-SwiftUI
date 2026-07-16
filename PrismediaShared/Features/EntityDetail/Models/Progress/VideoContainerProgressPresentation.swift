import Foundation

/// Display policy shared by series and season progress surfaces.
struct VideoContainerProgressPresentation: Hashable, Sendable {
    let episodeID: UUID
    let status: MediaProgressStatus
    let percent: Int
    let positionLabel: String
    let contextLabel: String
    let index: Int
    let total: Int
    let canContinue: Bool

    init?(progress: EntityProgressCapability?, episode: VideoProgressEpisode?) {
        guard let progress,
            let currentEntityID = progress.currentEntityID,
            progress.total > 0,
            let episode,
            episode.id == currentEntityID
        else { return nil }

        let total = progress.total
        let index = min(total - 1, max(0, progress.index))
        let isCompleted = progress.completedAt != nil
        let completedEpisodes = Double(index)
        let episodeFraction = isCompleted ? 1 : Self.playbackFraction(episode)
        let rawPercent = (completedEpisodes + episodeFraction) / Double(total) * 100

        episodeID = currentEntityID
        status = isCompleted ? .completed : .inProgress
        percent = isCompleted ? 100 : min(100, max(0, Int(rawPercent.rounded())))
        positionLabel = "Episode \(index + 1) of \(total)"
        contextLabel = episode.title
        self.index = index
        self.total = total
        canContinue = !isCompleted
    }

    private static func playbackFraction(_ episode: VideoProgressEpisode) -> Double {
        if episode.isCompleted { return 1 }
        guard let duration = episode.durationSeconds,
            duration.isFinite,
            duration > 0
        else { return 0 }
        return min(1, max(0, episode.resumeSeconds / duration))
    }
}
