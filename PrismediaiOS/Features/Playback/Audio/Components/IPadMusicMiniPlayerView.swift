#if os(iOS)
    import SwiftUI

    struct IPadMusicMiniPlayerView: View {
        @Environment(\.musicMiniPlayerVisibility) private var visibility
        @Environment(MusicPlayerController.self) private var controller
        @State private var artworkPalette: ArtworkPalette?

        let showNowPlaying: () -> Void

        var body: some View {
            if let track = controller.currentTrack {
                HStack(spacing: PrismediaSpacing.small) {
                    trackButton(track)

                    transportButton(
                        "Previous Track",
                        systemImage: "backward.fill",
                        isDisabled: !controller.queue.canGoPrevious,
                        action: controller.skipToPrevious
                    )

                    playButton

                    transportButton(
                        "Next Track",
                        systemImage: "forward.fill",
                        isDisabled: !controller.queue.canGoNext,
                        action: controller.skipToNext
                    )

                    Button("Show Now Playing", systemImage: "music.note.list", action: showNowPlaying)
                        .labelStyle(.iconOnly)
                        .foregroundStyle(accent)
                        .frame(
                            width: PrismediaLayout.minimumHitTarget,
                            height: PrismediaLayout.minimumHitTarget
                        )
                        .accessibilityHint("Opens playback position, queue, and audio controls")
                }
                .buttonStyle(.plain)
                .padding(.leading, PrismediaSpacing.small)
                .padding(.trailing, PrismediaSpacing.extraSmall)
                .padding(.vertical, PrismediaSpacing.extraSmall)
                .frame(maxWidth: 720)
                .glassEffect(.regular, in: .rect(cornerRadius: PrismediaRadius.control))
                .overlay {
                    RoundedRectangle(cornerRadius: PrismediaRadius.control)
                        .stroke(accent.opacity(0.42), lineWidth: PrismediaLayout.hairline)
                }
                .shadow(color: PrismediaColor.background.opacity(0.38), radius: 18, y: 9)
                .padding(.horizontal, PrismediaSpacing.extraExtraLarge)
                .padding(.top, PrismediaSpacing.small)
                .padding(.bottom, PrismediaSpacing.medium)
                .prismediaArtworkPalette(for: track.artworkPath, palette: $artworkPalette)
                .contextMenu {
                    Button("Show Now Playing", systemImage: "music.note.list", action: showNowPlaying)
                    Divider()
                    Button("Hide Player", systemImage: "xmark") {
                        visibility?.hideByUser()
                    }
                }
                .accessibilityElement(children: .contain)
            }
        }

        private func trackButton(_ track: MusicTrack) -> some View {
            Button(action: showNowPlaying) {
                HStack(spacing: PrismediaSpacing.small) {
                    MusicNowPlayingArtwork(
                        track: track,
                        cornerRadius: PrismediaRadius.badge
                    )
                    .frame(width: 42, height: 42)

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
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(.rect)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityLabel("Now Playing, \(track.title)")
            .accessibilityIdentifier("music.mini-player")
        }

        private var playButton: some View {
            Button(
                controller.isPlaying ? "Pause" : "Play",
                systemImage: controller.isPlaying ? "pause.fill" : "play.fill",
                action: togglePlayback
            )
            .labelStyle(.iconOnly)
            .font(.body.weight(.bold))
            .foregroundStyle(accent)
            .frame(
                width: PrismediaLayout.minimumHitTarget,
                height: PrismediaLayout.minimumHitTarget
            )
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
                .foregroundStyle(PrismediaColor.textSecondary)
                .frame(
                    width: PrismediaLayout.minimumHitTarget,
                    height: PrismediaLayout.minimumHitTarget
                )
                .contentShape(.rect)
                .disabled(isDisabled)
        }

        private var accent: Color {
            artworkPalette?.primary.color ?? PrismediaColor.materialSpectrumViolet
        }

        private func togglePlayback() {
            withoutMusicControlAnimation {
                controller.isPlaying ? controller.pause() : controller.resume()
            }
        }
    }

    #if DEBUG
        #Preview("iPad Music Floating Player", traits: .fixedLayout(width: 900, height: 140)) {
            @Previewable @State var controller = MusicPreviewData.controller()

            PreviewShell(signedIn: true) {
                IPadMusicMiniPlayerView(showNowPlaying: {})
                    .environment(controller)
            }
        }
    #endif
#endif
