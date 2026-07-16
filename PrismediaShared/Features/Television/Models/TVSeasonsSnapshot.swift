import SwiftUI

struct TVSeasonsSnapshot: Equatable, Sendable {
    var seriesDetail: EntityDetail?
    var seasons: [EntityThumbnail] = []
    var selectedSeasonID: UUID?
    var episodes: [EntityThumbnail] = []
    var selectedEpisode: EntityThumbnail?
    var selectedEpisodeDetail: EntityDetail?
    var isLoadingSeason = false
    var seasonErrorMessage: String?

    static func initial(rootDetail: EntityDetail) -> TVSeasonsSnapshot {
        var snapshot = TVSeasonsSnapshot()
        if rootDetail.kind == .videoSeries {
            snapshot.applySeries(rootDetail, preferredSeasonID: nil)
        } else if rootDetail.kind == .videoSeason {
            snapshot.selectedSeasonID = rootDetail.id
            snapshot.episodes = TVSeasonsPresentation.episodes(in: rootDetail)
        }
        return snapshot
    }

    mutating func applySeries(_ detail: EntityDetail, preferredSeasonID: UUID?) {
        seriesDetail = detail
        seasons = TVSeasonsPresentation.seasons(in: detail)
        selectedSeasonID = TVSeasonsPresentation.selectedSeasonID(
            preferredID: preferredSeasonID ?? selectedSeasonID,
            seasons: seasons
        )
    }

    mutating func beginSelectingSeason(id: UUID) {
        selectedSeasonID = id
        selectedEpisode = nil
        selectedEpisodeDetail = nil
        seasonErrorMessage = nil
    }

    mutating func installSeason(
        _ detail: EntityDetail,
        preferredEpisodeID: UUID? = nil
    ) {
        episodes = TVSeasonsPresentation.episodes(in: detail)
        selectedEpisode = episodes.first { $0.id == preferredEpisodeID } ?? episodes.first
        selectedEpisodeDetail = nil
        seasonErrorMessage = nil
    }
}
