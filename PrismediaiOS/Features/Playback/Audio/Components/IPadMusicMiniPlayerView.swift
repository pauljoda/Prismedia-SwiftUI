#if os(iOS)
    import SwiftUI

    struct IPadMusicMiniPlayerView: View {
        @Environment(\.musicMiniPlayerVisibility) private var visibility
        @Environment(PrismediaAppEnvironment.self) private var environment
        @Environment(PrismediaAppRouter.self) private var router
        @Environment(MusicPlayerController.self) private var controller
        @Binding private var artworkPalette: ArtworkPalette?
        @State private var trackForCollection: MusicTrack?

        let showNowPlaying: () -> Void

        init(
            artworkPalette: Binding<ArtworkPalette?>,
            showNowPlaying: @escaping () -> Void
        ) {
            _artworkPalette = artworkPalette
            self.showNowPlaying = showNowPlaying
        }

        var body: some View {
            if let track = controller.currentTrack {
                HStack(spacing: PrismediaSpacing.extraSmall) {
                    previousButton
                    playButton
                    nextButton

                    Capsule()
                        .fill(PrismediaColor.textMuted.opacity(0.28))
                        .frame(width: PrismediaLayout.hairline, height: 28)
                        .padding(.horizontal, PrismediaSpacing.extraSmall)
                        .accessibilityHidden(true)

                    trackButton(track)

                    MusicTrackActionsMenu(
                        track: track,
                        onNavigate: router.open,
                        onAddToCollection: { trackForCollection = track },
                        onShowNowPlaying: showNowPlaying,
                        onHidePlayer: { visibility?.hideByUser() }
                    )
                }
                .buttonStyle(.plain)
                .padding(.horizontal, PrismediaSpacing.small)
                .padding(.vertical, PrismediaSpacing.extraSmall)
                .frame(maxWidth: 900)
                .glassEffect(.regular, in: .capsule)
                .padding(.horizontal, PrismediaSpacing.extraExtraLarge)
                .padding(.top, PrismediaSpacing.small)
                .padding(.bottom, PrismediaSpacing.medium)
                .sheet(item: $trackForCollection) { track in
                    AddToCollectionSheet(
                        items: [CollectionEntityReference(entityType: .audioTrack, entityID: track.id)]
                    )
                    .environment(environment)
                }
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("music.mini-player")
            }
        }

        private func trackButton(_ track: MusicTrack) -> some View {
            Button(action: showNowPlaying) {
                HStack(spacing: PrismediaSpacing.small) {
                    MusicNowPlayingArtwork(
                        track: track,
                        cornerRadius: PrismediaRadius.badge
                    )
                    .frame(width: 44, height: 44)

                    VStack(alignment: .leading, spacing: PrismediaSpacing.extraExtraSmall) {
                        Text(track.title)
                            .font(.callout.weight(.semibold))
                            .foregroundStyle(PrismediaColor.textPrimary)
                            .lineLimit(1)

                        Text(MusicPresentation.artist(track.artist))
                            .font(.caption)
                            .foregroundStyle(PrismediaColor.textSecondary)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(.rect)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .layoutPriority(1)
            .accessibilityLabel("Show Now Playing for \(track.title)")
            .accessibilityIdentifier("music.mini-player.track")
        }

        private var previousButton: some View {
            transportButton(
                "Previous Track",
                systemImage: "backward.fill",
                isDisabled: !controller.queue.canGoPrevious,
                action: controller.skipToPrevious
            )
        }

        private var nextButton: some View {
            transportButton(
                "Next Track",
                systemImage: "forward.fill",
                isDisabled: !controller.queue.canGoNext,
                action: controller.skipToNext
            )
        }

        private var playButton: some View {
            Button(action: togglePlayback) {
                Image(systemName: controller.isPlaying ? "pause.fill" : "play.fill")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(accent)
                    .frame(
                        width: PrismediaLayout.minimumHitTarget,
                        height: PrismediaLayout.minimumHitTarget
                    )
                    .contentShape(.rect)
            }
            .accessibilityLabel(controller.isPlaying ? "Pause" : "Play")
            .accessibilityIdentifier("music.mini-player.play-pause")
            .contentTransition(.identity)
            .animation(nil, value: controller.isPlaying)
        }

        private func transportButton(
            _ title: String,
            systemImage: String,
            isDisabled: Bool,
            action: @escaping () -> Void
        ) -> some View {
            Button(title, systemImage: systemImage, action: action)
                .labelStyle(.iconOnly)
                .font(.body.weight(.semibold))
                .foregroundStyle(PrismediaColor.textSecondary)
                .frame(
                    width: PrismediaLayout.minimumHitTarget,
                    height: PrismediaLayout.minimumHitTarget
                )
                .contentShape(.rect)
                .disabled(isDisabled)
        }

        private var accent: Color {
            artworkPalette?.primary.color ?? PrismediaColor.materialSpectrumGreen
        }

        private func togglePlayback() {
            withoutMusicControlAnimation {
                controller.isPlaying ? controller.pause() : controller.resume()
            }
        }
    }

    #if DEBUG
        #Preview("iPad Music Floating Player", traits: .fixedLayout(width: 1_000, height: 100)) {
            @Previewable @State var controller = MusicPreviewData.controller()
            @Previewable @State var artworkPalette: ArtworkPalette?

            PreviewShell(signedIn: true) {
                IPadMusicMiniPlayerView(
                    artworkPalette: $artworkPalette,
                    showNowPlaying: {}
                )
                .environment(controller)
            }
        }
    #endif
#endif
