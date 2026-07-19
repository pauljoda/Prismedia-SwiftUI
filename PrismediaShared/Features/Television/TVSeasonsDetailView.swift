import SwiftUI

#if os(tvOS)
    struct TVSeasonsDetailView: View {
        @State private var snapshot = TVSeasonsSnapshot()
        @State private var seasonCache: [UUID: EntityDetail] = [:]
        @State private var episodeCache: [UUID: EntityDetail] = [:]
        @State private var seasonRequestID = UUID()
        @State private var episodeLoadTask: Task<Void, Never>?
        @State private var hasLoaded = false
        @State private var hasAppliedRouteEpisode = false
        @State private var initialFocusEpisodeID: UUID?

        private let useCase: TVSeasonsUseCase
        private let routeLink: EntityLink?
        private let dependencies: EntityDetailDependencies
        private let loader: any EntityDetailLoading
        private let playbackService: (any VideoPlaybackServicing)?

        init(
            rootDetail: EntityDetail,
            routeLink: EntityLink? = nil,
            dependencies: EntityDetailDependencies
        ) {
            useCase = TVSeasonsUseCase(
                rootDetail: rootDetail,
                loader: dependencies.detailLoader
            )
            self.routeLink = routeLink
            self.dependencies = dependencies
            loader = dependencies.detailLoader
            playbackService = dependencies.videoPlaybackService
        }

        var body: some View {
            VStack(alignment: .leading, spacing: PrismediaSpacing.large) {
                Spacer(minLength: 24)
                TVSeasonsHeroCopy(
                    series: displayedSeries,
                    selectedEpisode: snapshot.selectedEpisode,
                    selectedEpisodeDetail: snapshot.selectedEpisodeDetail,
                    seasons: snapshot.seasons,
                    selectedSeasonID: snapshot.selectedSeasonID
                )
                TVSeasonsPlaybackArea(
                    episode: snapshot.selectedEpisode,
                    episodeDetail: snapshot.selectedEpisodeDetail,
                    loader: loader,
                    playbackService: playbackService,
                    fullscreenRequest: snapshot.fullscreenRequest,
                    onFullscreenDismiss: handleFullscreenDismiss,
                    onPlaybackProgressCommitted: { episodeID in
                        Task { await refreshPlaybackProgress(for: episodeID) }
                    },
                    onAdvance: handleAdvancedEpisode
                )
                TVSeasonPicker(
                    seasons: snapshot.seasons,
                    selectedSeasonID: snapshot.selectedSeasonID,
                    onSelect: { season in Task { await selectSeason(id: season.id) } }
                )
                TVEpisodeRail(
                    episodes: snapshot.episodes,
                    initialFocusEpisodeID: initialFocusEpisodeID,
                    previousSeason: adjacentSeasons.previous,
                    nextSeason: adjacentSeasons.next,
                    isLoading: snapshot.isLoadingSeason,
                    errorMessage: snapshot.seasonErrorMessage,
                    onFocus: { applyEpisodeSelection($0, intent: .focus) },
                    onActivate: { applyEpisodeSelection($0, intent: .activate) },
                    onSelectSeason: { season in Task { await selectSeason(id: season.id) } }
                )
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.bottom, PrismediaSpacing.section)
            .background {
                TVSeasonsHeroBackground(
                    series: displayedSeries,
                    selectedEpisode: snapshot.selectedEpisode
                )
                .ignoresSafeArea()
            }
            .background(.black)
            .task { await loadIfNeeded() }
            .onDisappear { episodeLoadTask?.cancel() }
            .accessibilityIdentifier("tv.seasons-detail")
        }

        private var displayedSeries: EntityDetail {
            snapshot.seriesDetail ?? useCase.rootDetail
        }

        private var adjacentSeasons: (previous: EntityThumbnail?, next: EntityThumbnail?) {
            TVSeasonsPresentation.adjacentSeasons(
                selectedID: snapshot.selectedSeasonID,
                seasons: snapshot.seasons
            )
        }

        private func loadIfNeeded() async {
            guard !hasLoaded else { return }
            hasLoaded = true
            snapshot = useCase.initialSnapshot
            let progressTarget = try? await useCase.loadProgressTarget()
            initialFocusEpisodeID = routeEpisodeID ?? progressTarget?.episodeID

            if useCase.rootDetail.kind == .videoSeries {
                if let selectedSeasonID = progressTarget?.seasonID ?? snapshot.selectedSeasonID {
                    await selectSeason(id: selectedSeasonID)
                    applyRouteEpisodeIfNeeded()
                }
                return
            }

            guard useCase.rootDetail.kind == .videoSeason else { return }
            seasonCache[useCase.rootDetail.id] = useCase.rootDetail
            snapshot.installSeason(
                useCase.rootDetail,
                preferredEpisodeID: initialFocusEpisodeID
            )
            applyRouteEpisodeIfNeeded()
            do {
                guard let parent = try await useCase.loadParentSeries(), !Task.isCancelled else { return }
                snapshot.applySeries(parent, preferredSeasonID: useCase.rootDetail.id)
                snapshot.selectedSeasonID = useCase.rootDetail.id
            } catch is CancellationError {
                return
            } catch {
                // A directly opened season remains usable when its parent cannot
                // be refreshed.
            }
        }

        private func selectSeason(id: UUID) async {
            guard id != snapshot.selectedSeasonID || snapshot.episodes.isEmpty else { return }
            snapshot.beginSelectingSeason(id: id)
            episodeLoadTask?.cancel()

            if let cached = seasonCache[id] {
                snapshot.installSeason(
                    cached,
                    preferredEpisodeID: preferredEpisodeID(in: id)
                )
                return
            }

            let requestID = UUID()
            seasonRequestID = requestID
            snapshot.isLoadingSeason = true
            snapshot.episodes = []
            defer {
                if seasonRequestID == requestID { snapshot.isLoadingSeason = false }
            }

            do {
                guard let detail = try await useCase.loadSeason(id: id),
                    !Task.isCancelled,
                    seasonRequestID == requestID,
                    snapshot.selectedSeasonID == id
                else { return }
                seasonCache[id] = detail
                snapshot.installSeason(
                    detail,
                    preferredEpisodeID: preferredEpisodeID(in: id)
                )
                applyRouteEpisodeIfNeeded()
            } catch is CancellationError {
                return
            } catch {
                guard seasonRequestID == requestID else { return }
                snapshot.seasonErrorMessage = "Couldn’t load this season."
            }
        }

        private func applyEpisodeSelection(
            _ episode: EntityThumbnail,
            intent: TVEpisodeSelectionIntent
        ) {
            let decision = TVSeasonsPresentation.episodeSelection(
                episodeID: episode.id,
                intent: intent,
                isDetailCached: episodeCache[episode.id] != nil
            )
            focusEpisode(episode, shouldPrewarmDetail: decision.shouldPrewarmDetail)
            if decision.shouldPresentFullscreen {
                snapshot.presentFullscreen(
                    TVEpisodePlaybackRequest(episodeID: decision.episodeID)
                )
            }
        }

        private func applyRouteEpisodeIfNeeded() {
            guard !hasAppliedRouteEpisode, !snapshot.episodes.isEmpty else { return }
            hasAppliedRouteEpisode = true
            guard
                let episode = TVSeasonsPresentation.routeEpisode(
                    from: routeLink,
                    episodes: snapshot.episodes
                )
            else { return }
            applyEpisodeSelection(episode, intent: .activate)
        }

        private var routeEpisodeID: UUID? {
            guard routeLink?.intent == .playback,
                routeLink?.kind == .videoSeason
            else { return nil }
            return routeLink?.sourceThumbnail?.id
        }

        private func preferredEpisodeID(in seasonID: UUID) -> UUID? {
            guard let initialFocusEpisodeID else { return nil }
            if let source = routeLink?.sourceThumbnail,
                source.id == initialFocusEpisodeID
            {
                return source.parentEntityID == seasonID ? initialFocusEpisodeID : nil
            }
            return initialFocusEpisodeID
        }

        private func handleAdvancedEpisode(_ link: EntityLink) {
            guard let source = link.sourceThumbnail,
                let episode = snapshot.episodes.first(where: { $0.id == source.id })
            else { return }
            snapshot.fullscreenRequest = nil
            applyEpisodeSelection(episode, intent: .focus)
        }

        private func handleFullscreenDismiss(
            _ request: TVEpisodePlaybackRequest?,
            episodeID: UUID
        ) {
            if let request { snapshot.finishFullscreen(requestID: request.id) }
            episodeCache[episodeID] = nil
            snapshot.invalidateEpisodeDetail(id: episodeID)
        }

        private func refreshPlaybackProgress(for episodeID: UUID) async {
            do {
                guard let episodeDetail = try await useCase.loadEpisode(id: episodeID),
                    !Task.isCancelled
                else { return }
                episodeCache[episodeID] = episodeDetail
                snapshot.installEpisodeDetail(episodeDetail)

                guard let seasonID = episodeDetail.parentEntityID,
                    let seasonDetail = try await useCase.loadSeason(id: seasonID),
                    !Task.isCancelled
                else { return }
                seasonCache[seasonID] = seasonDetail
                if snapshot.selectedSeasonID == seasonID {
                    snapshot.refreshSeason(seasonDetail)
                }
            } catch is CancellationError {
                return
            } catch {
                return
            }
        }

        private func focusEpisode(
            _ episode: EntityThumbnail,
            shouldPrewarmDetail: Bool
        ) {
            episodeLoadTask?.cancel()
            snapshot.selectedEpisode = episode
            snapshot.selectedEpisodeDetail = episodeCache[episode.id]
            guard snapshot.selectedEpisodeDetail == nil, shouldPrewarmDetail else { return }

            episodeLoadTask = Task {
                try? await Task.sleep(for: .milliseconds(250))
                guard !Task.isCancelled else { return }

                do {
                    guard let detail = try await useCase.loadEpisode(id: episode.id),
                        !Task.isCancelled
                    else { return }
                    episodeCache[episode.id] = detail
                    if snapshot.selectedEpisode?.id == episode.id {
                        snapshot.selectedEpisodeDetail = detail
                    }
                } catch {
                    return
                }
            }
        }
    }

    #if DEBUG

        #Preview("TV Seasons Detail") {
            PreviewShell {
                NavigationStack {
                    TVSeasonsDetailView(
                        rootDetail: TVSeasonsPreviewData.series,
                        dependencies: TVSeasonsPreviewData.dependencies
                    )
                }
            }
        }
    #endif
#endif
