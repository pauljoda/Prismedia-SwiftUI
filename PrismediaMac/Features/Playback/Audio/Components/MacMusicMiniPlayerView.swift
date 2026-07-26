#if os(macOS)
    import SwiftUI

    struct MacMusicMiniPlayerView: View {
        @Environment(\.musicMiniPlayerVisibility) private var visibility
        @Binding var artworkPalette: ArtworkPalette?

        let controller: MusicPlayerController
        let engine: AVPlayerAudioPlaybackEngine
        let waveform: MusicWaveform?
        let showNowPlaying: () -> Void

        init(
            controller: MusicPlayerController,
            engine: AVPlayerAudioPlaybackEngine,
            waveform: MusicWaveform?,
            artworkPalette: Binding<ArtworkPalette?>,
            showNowPlaying: @escaping () -> Void
        ) {
            self.controller = controller
            self.engine = engine
            self.waveform = waveform
            _artworkPalette = artworkPalette
            self.showNowPlaying = showNowPlaying
        }

        var body: some View {
            if let track = controller.currentTrack {
                HStack(spacing: PrismediaSpacing.medium) {
                    MacMusicCompactTransportView(
                        controller: controller,
                        accent: accent
                    )

                    MacMusicCompactNowPlayingCenter(
                        track: track,
                        controller: controller,
                        engine: engine,
                        waveform: waveform,
                        accent: accent,
                        secondaryAccent: secondaryAccent,
                        showNowPlaying: showNowPlaying
                    )
                    .frame(maxWidth: .infinity)

                    MacMusicCompactUtilityControls(
                        track: track,
                        controller: controller,
                        engine: engine,
                        showNowPlaying: showNowPlaying,
                        hidePlayer: { visibility?.hideByUser() }
                    )
                }
                .buttonStyle(.plain)
                .padding(.horizontal, PrismediaSpacing.large)
                .padding(.vertical, PrismediaSpacing.small)
                .frame(maxWidth: 900)
                .glassEffect(.regular, in: .capsule)
                .background {
                    Capsule()
                        .fill(.clear)
                        .contentShape(.capsule)
                        .onTapGesture {}
                        .accessibilityHidden(true)
                }
                .overlay {
                    Capsule()
                        .stroke(accent.opacity(0.16), lineWidth: PrismediaLayout.hairline)
                        .allowsHitTesting(false)
                }
                .shadow(color: PrismediaColor.background.opacity(0.36), radius: 18, y: 8)
                .padding(.horizontal, PrismediaSpacing.extraExtraLarge)
                .padding(.top, PrismediaSpacing.small)
                .padding(.bottom, PrismediaSpacing.medium)
                .prismediaArtworkPalette(for: track.artworkPath, palette: $artworkPalette)
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("music.mini-player")
            }
        }

        private var accent: Color {
            artworkPalette?.primary.color ?? PrismediaColor.materialSpectrumGreen
        }

        private var secondaryAccent: Color {
            artworkPalette?.secondary.color ?? PrismediaColor.textSecondary
        }
    }

    #if DEBUG
        #Preview("Mac Music Floating Player") {
            @Previewable @State var controller = MusicPreviewData.controller()
            @Previewable @State var engine = AVPlayerAudioPlaybackEngine()
            @Previewable @State var artworkPalette: ArtworkPalette?

            PreviewShell(signedIn: true) {
                MacMusicMiniPlayerView(
                    controller: controller,
                    engine: engine,
                    waveform: MusicWaveformPreviewLoader.waveform,
                    artworkPalette: $artworkPalette,
                    showNowPlaying: {}
                )
                .environment(controller)
                .frame(width: 1_000, height: 140)
            }
        }
    #endif
#endif
