import SwiftUI

struct TVSeasonsSnapshot: Equatable, Sendable {
    var seriesDetail: EntityDetail?
    var seasons: [EntityThumbnail] = []
    var selectedSeasonID: UUID?
    var episodes: [EntityThumbnail] = []
    var selectedEpisode: EntityThumbnail?
    var selectedEpisodeDetail: EntityDetail?
    var fullscreenRequest: TVEpisodePlaybackRequest?
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

    mutating func refreshSeason(_ detail: EntityDetail) {
        let selectedEpisodeID = selectedEpisode?.id
        episodes = TVSeasonsPresentation.episodes(in: detail)
        selectedEpisode = episodes.first { $0.id == selectedEpisodeID } ?? episodes.first
        if selectedEpisode?.id != selectedEpisodeID {
            selectedEpisodeDetail = nil
        }
        seasonErrorMessage = nil
    }

    mutating func installEpisodeDetail(_ detail: EntityDetail) {
        guard selectedEpisode?.id == detail.id else { return }
        selectedEpisodeDetail = detail
    }

    mutating func invalidateEpisodeDetail(id: UUID) {
        guard selectedEpisode?.id == id else { return }
        selectedEpisodeDetail = nil
    }

    mutating func presentFullscreen(_ request: TVEpisodePlaybackRequest) {
        fullscreenRequest = request
    }

    mutating func finishFullscreen(requestID: UUID) {
        guard fullscreenRequest?.id == requestID else { return }
        fullscreenRequest = nil
    }
}
