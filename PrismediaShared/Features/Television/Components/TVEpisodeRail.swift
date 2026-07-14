import SwiftUI

#if os(tvOS)

    struct TVEpisodeRail: View {
        @FocusState private var focusedTarget: TVEpisodeRailFocusTarget?
        @State private var pendingBoundaryDirection: TVSeasonBoundaryDirection?

        let episodes: [EntityThumbnail]
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
                .onChange(of: episodes.map(\.id)) { _, episodeIDs in
                    restoreFocusIfNeeded(episodeIDs: episodeIDs)
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
                            .accessibilityHint("Updates the selected episode")
                            .accessibilityIdentifier("tv.seasons-detail.episode.\(episode.id.uuidString)")
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

        private func restoreFocusIfNeeded(episodeIDs: [UUID]) {
            guard !episodeIDs.isEmpty, let pendingBoundaryDirection else { return }
            self.pendingBoundaryDirection = nil
            let episodeID = pendingBoundaryDirection == .previous ? episodeIDs.last : episodeIDs.first
            guard let episodeID else { return }

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
