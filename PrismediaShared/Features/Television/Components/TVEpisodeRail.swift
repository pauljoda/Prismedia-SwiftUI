import SwiftUI

#if os(tvOS)

    struct TVEpisodeRail: View {
        @Environment(\.accessibilityReduceMotion) private var reduceMotion
        @FocusState private var focusedTarget: TVEpisodeRailFocusTarget?
        @State private var pendingBoundaryDirection: TVSeasonBoundaryDirection?
        @State private var hasAppliedInitialFocus = false

        let episodes: [EntityThumbnail]
        let initialFocusEpisodeID: UUID?
        let previousSeason: EntityThumbnail?
        let nextSeason: EntityThumbnail?
        let isLoading: Bool
        let errorMessage: String?
        let onFocus: (EntityThumbnail) -> Void
        let onActivate: (EntityThumbnail) -> Void
        let onSelectSeason: (EntityThumbnail) -> Void

        var body: some View {
            content
                .onChange(of: focusedTarget) { _, target in
                    guard case .episode(let episodeID) = target,
                        let episode = episodes.first(where: { $0.id == episodeID })
                    else { return }
                    onFocus(episode)
                }
        }

        @ViewBuilder
        private var content: some View {
            if isLoading {
                ProgressView("Loading episodes…")
                    .frame(maxWidth: .infinity, minHeight: 250)
            } else if let errorMessage {
                ContentUnavailableView(errorMessage, systemImage: "exclamationmark.triangle")
                    .frame(maxWidth: .infinity, minHeight: 250)
            } else if episodes.isEmpty {
                ContentUnavailableView("No Episodes", systemImage: "rectangle.stack")
                    .frame(maxWidth: .infinity, minHeight: 250)
            } else {
                ScrollViewReader { proxy in
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(alignment: .top, spacing: PrismediaSpacing.section) {
                            if let previousSeason {
                                seasonBoundaryButton(
                                    season: previousSeason,
                                    direction: .previous,
                                    focusTarget: .previousSeason
                                )
                            }

                            ForEach(episodes) { episode in
                                Button {
                                    onActivate(episode)
                                } label: {
                                    EntityThumbnailCardView(
                                        item: episode,
                                        layout: .rail,
                                        preferredWidth: 300
                                    )
                                }
                                .buttonStyle(.card)
                                .focused($focusedTarget, equals: .episode(episode.id))
                                .id(episode.id)
                                .accessibilityHint("Updates the selected episode")
                                .accessibilityIdentifier(
                                    "tv.seasons-detail.episode.\(episode.id.uuidString)"
                                )
                            }

                            if let nextSeason {
                                seasonBoundaryButton(
                                    season: nextSeason,
                                    direction: .next,
                                    focusTarget: .nextSeason
                                )
                            }
                        }
                        .padding(.horizontal, 72)
                        .padding(.vertical, PrismediaSpacing.medium)
                    }
                    .onChange(of: episodes.map(\.id), initial: true) { _, episodeIDs in
                        restoreFocusIfNeeded(episodeIDs: episodeIDs, proxy: proxy)
                        applyInitialFocusIfNeeded(episodeIDs: episodeIDs, proxy: proxy)
                    }
                    .onChange(of: initialFocusEpisodeID, initial: true) {
                        applyInitialFocusIfNeeded(
                            episodeIDs: episodes.map(\.id),
                            proxy: proxy
                        )
                    }
                }
                .frame(height: 300)
                .frame(maxWidth: .infinity, alignment: .leading)
                .prismediaFocusSection()
            }
        }

        private func seasonBoundaryButton(
            season: EntityThumbnail,
            direction: TVSeasonBoundaryDirection,
            focusTarget: TVEpisodeRailFocusTarget
        ) -> some View {
            Button {
                pendingBoundaryDirection = direction
                onSelectSeason(season)
            } label: {
                TVSeasonBoundaryCard(season: season, direction: direction)
            }
            .buttonStyle(.card)
            .focused($focusedTarget, equals: focusTarget)
            .accessibilityHint("Loads \(season.title)")
            .accessibilityIdentifier(direction.accessibilityIdentifier)
        }

        private func restoreFocusIfNeeded(
            episodeIDs: [UUID],
            proxy: ScrollViewProxy
        ) {
            guard !episodeIDs.isEmpty, let pendingBoundaryDirection else { return }
            self.pendingBoundaryDirection = nil
            let episodeID = pendingBoundaryDirection == .previous ? episodeIDs.last : episodeIDs.first
            guard let episodeID else { return }

            scrollAndFocus(episodeID, proxy: proxy)
        }

        private func applyInitialFocusIfNeeded(
            episodeIDs: [UUID],
            proxy: ScrollViewProxy
        ) {
            guard !hasAppliedInitialFocus,
                pendingBoundaryDirection == nil,
                let initialFocusEpisodeID,
                episodeIDs.contains(initialFocusEpisodeID)
            else { return }
            hasAppliedInitialFocus = true

            scrollAndFocus(initialFocusEpisodeID, proxy: proxy)
        }

        private func scrollAndFocus(_ episodeID: UUID, proxy: ScrollViewProxy) {
            withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.25)) {
                proxy.scrollTo(episodeID, anchor: .center)
            }
            Task { @MainActor in
                await Task.yield()
                focusedTarget = .episode(episodeID)
            }
        }
    }
#endif
#if os(tvOS) && DEBUG
    #Preview("TV Episode Rail · Content · Accessibility Type") {
        PreviewShell {
            TVEpisodeRail(
                episodes: [TVSeasonsPreviewData.episodeThumbnail],
                initialFocusEpisodeID: TVSeasonsPreviewData.episodeThumbnail.id,
                previousSeason: nil,
                nextSeason: TVSeasonsPreviewData.seasonThumbnail,
                isLoading: false,
                errorMessage: nil,
                onFocus: { _ in },
                onActivate: { _ in },
                onSelectSeason: { _ in }
            )
        }
        .environment(\.dynamicTypeSize, .accessibility3)
    }

    #Preview("TV Episode Rail · Loading") {
        PreviewShell {
            TVEpisodeRail(
                episodes: [],
                initialFocusEpisodeID: nil,
                previousSeason: nil,
                nextSeason: nil,
                isLoading: true,
                errorMessage: nil,
                onFocus: { _ in },
                onActivate: { _ in },
                onSelectSeason: { _ in }
            )
        }
    }

    #Preview("TV Episode Rail · Error") {
        PreviewShell {
            TVEpisodeRail(
                episodes: [],
                initialFocusEpisodeID: nil,
                previousSeason: nil,
                nextSeason: nil,
                isLoading: false,
                errorMessage: "Couldn’t load this season.",
                onFocus: { _ in },
                onActivate: { _ in },
                onSelectSeason: { _ in }
            )
        }
    }
#endif
