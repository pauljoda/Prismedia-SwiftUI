import Foundation

/// Orchestrates series and season progress I/O while the detail view owns the
/// transient presentation state.
@MainActor
struct VideoContainerProgressService {
    private let loader: any EntityDetailLoading
    private let mutator: (any EntityProgressMutating)?

    init(
        loader: any EntityDetailLoading,
        mutator: (any EntityProgressMutating)?
    ) {
        self.loader = loader
        self.mutator = mutator
    }

    var canMutate: Bool {
        mutator != nil
    }

    func loadProgressEpisode(for container: EntityDetail) async throws -> EntityDetail? {
        guard Self.supportsProgress(container),
            let progress: EntityProgressCapability = container.capability(),
            let episodeID = progress.currentEntityID
        else { return nil }

        let episode = try await loader.loadEntity(id: episodeID)
        return episode.kind == .video ? episode : nil
    }

    func toggleCompletion(
        container: EntityDetail,
        presentation: VideoContainerProgressPresentation
    ) async throws -> EntityDetail {
        guard let mutator else { throw VideoContainerProgressError.unavailable }
        return try await mutator.updateProgress(
            id: container.id,
            request: EntityProgressUpdateRequest(
                currentEntityID: presentation.episodeID,
                unit: .item,
                index: presentation.index,
                total: presentation.total,
                mode: nil,
                completed: presentation.status != .completed,
                reset: false
            )
        )
    }

    func startOver(container: EntityDetail) async throws -> EntityDetail {
        guard let mutator else { throw VideoContainerProgressError.unavailable }
        guard let progress: EntityProgressCapability = container.capability(),
            let firstEpisodeID = try await firstEpisodeID(in: container)
        else { throw VideoContainerProgressError.missingFirstEpisode }

        return try await mutator.updateProgress(
            id: container.id,
            request: EntityProgressUpdateRequest(
                currentEntityID: firstEpisodeID,
                unit: .item,
                index: 0,
                total: progress.total,
                mode: nil,
                completed: nil,
                reset: true
            )
        )
    }

    private func firstEpisodeID(in container: EntityDetail) async throws -> UUID? {
        if let directEpisode = Self.orderedChildren(of: .video, in: container).first {
            return directEpisode.id
        }

        guard container.kind == .videoSeries,
            let firstSeason = Self.orderedChildren(of: .videoSeason, in: container).first
        else { return nil }
        let season = try await loader.loadEntity(id: firstSeason.id)
        return Self.orderedChildren(of: .video, in: season).first?.id
    }

    private static func orderedChildren(
        of kind: EntityKind,
        in detail: EntityDetail
    ) -> [EntityThumbnail] {
        detail.childrenByKind
            .filter { $0.kind == kind }
            .flatMap(\.entities)
            .enumerated()
            .sorted { lhs, rhs in
                let lhsOrder = lhs.element.sortOrder ?? Int.max
                let rhsOrder = rhs.element.sortOrder ?? Int.max
                return lhsOrder == rhsOrder ? lhs.offset < rhs.offset : lhsOrder < rhsOrder
            }
            .map(\.element)
    }

    private static func supportsProgress(_ detail: EntityDetail) -> Bool {
        detail.kind == .videoSeries || detail.kind == .videoSeason
    }
}
