import SwiftUI

/// Performs television hierarchy I/O while the SwiftUI screen owns its value
/// snapshot, focus, request identity, and loading presentation.
@MainActor
struct TVSeasonsUseCase: Sendable {
    let rootDetail: EntityDetail
    private let loader: any EntityDetailLoading

    init(rootDetail: EntityDetail, loader: any EntityDetailLoading) {
        self.rootDetail = rootDetail
        self.loader = loader
    }

    var initialSnapshot: TVSeasonsSnapshot {
        TVSeasonsSnapshot.initial(rootDetail: rootDetail)
    }

    func loadParentSeries() async throws -> EntityDetail? {
        guard rootDetail.kind == .videoSeason,
            let parentID = rootDetail.parentEntityID
        else { return nil }
        let detail = try await loader.loadEntity(id: parentID)
        return detail.kind == .videoSeries ? detail : nil
    }

    func loadSeason(id: UUID) async throws -> EntityDetail? {
        let detail = try await loader.loadEntity(id: id)
        return detail.kind == .videoSeason ? detail : nil
    }

    func loadEpisode(id: UUID) async throws -> EntityDetail? {
        let detail = try await loader.loadEntity(id: id)
        return detail.kind == .video ? detail : nil
    }

    func loadProgressTarget() async throws -> (episodeID: UUID, seasonID: UUID)? {
        guard let progress: EntityProgressCapability = rootDetail.capability(),
            let episodeID = progress.currentEntityID
        else { return nil }

        if rootDetail.kind == .videoSeason {
            guard TVSeasonsPresentation.episodes(in: rootDetail).contains(where: { $0.id == episodeID }) else {
                return nil
            }
            return (episodeID, rootDetail.id)
        }

        guard rootDetail.kind == .videoSeries,
            let episode = try await loadEpisode(id: episodeID),
            let seasonID = episode.parentEntityID,
            TVSeasonsPresentation.seasons(in: rootDetail).contains(where: { $0.id == seasonID })
        else { return nil }
        return (episodeID, seasonID)
    }
}
