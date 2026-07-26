#if os(macOS)
    import AVFoundation
    import SwiftUI

    struct MacMusicMiniPlayerView: View {
        @Environment(\.musicMiniPlayerVisibility) private var visibility
        @Environment(MusicPlayerController.self) private var controller
        @State private var artworkPalette: ArtworkPalette?
        @State private var isExpanded = false
        @State private var volume = 1.0

        let engine: AVPlayerAudioPlaybackEngine
        let showNowPlaying: () -> Void

        var body: some View {
            if let track = controller.currentTrack {
                VStack(spacing: 0) {
                    HStack(spacing: PrismediaSpacing.medium) {
                        trackButton(track)
                        transport

                        if isExpanded {
                            timeline(track)
                            volumeControl
                        }

                        Button("Toggle Now Playing", systemImage: "list.bullet", action: showNowPlaying)
                            .labelStyle(.iconOnly)
                            .help("Show or hide Now Playing")

                        Button(
                            isExpanded ? "Use Compact Player" : "Expand Player",
                            systemImage: isExpanded ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right"
                        ) {
                            withAnimation(.snappy) { isExpanded.toggle() }
                        }
                        .labelStyle(.iconOnly)
                        .help(isExpanded ? "Use Compact Player" : "Expand Player")

                        Button("Hide Player", systemImage: "xmark") {
                            visibility?.hideByUser()
                        }
                        .labelStyle(.iconOnly)
                        .help("Hide Player")
                    }
                    .padding(.horizontal, PrismediaSpacing.medium)
                    .padding(.vertical, PrismediaSpacing.small)

                    ProgressView(value: progress, total: 1)
                        .progressViewStyle(.linear)
                        .controlSize(.mini)
                        .tint(accent)
                        .accessibilityHidden(true)
                }
                .buttonStyle(.plain)
                .controlSize(.large)
                .frame(width: isExpanded ? 760 : 470)
                .glassEffect(.regular, in: .rect(cornerRadius: PrismediaRadius.control))
                .overlay {
                    RoundedRectangle(cornerRadius: PrismediaRadius.control)
                        .stroke(accent.opacity(0.48), lineWidth: PrismediaLayout.hairline)
                }
                .shadow(color: PrismediaColor.background.opacity(0.4), radius: 22, y: 10)
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
                .onAppear {
                    volume = Double(engine.player.volume)
                }
                .onChange(of: volume) { _, nextVolume in
                    engine.player.volume = Float(nextVolume)
                }
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("music.mini-player")
                .animation(.snappy, value: isExpanded)
            }
        }

        private func trackButton(_ track: MusicTrack) -> some View {
            Button(action: showNowPlaying) {
                HStack(spacing: PrismediaSpacing.small) {
                    RemotePosterImage(
                        path: track.artworkPath,
                        fallbackSeed: track.album ?? track.title,
                        systemImage: "music.note"
                    )
                    .frame(width: 40, height: 40)
                    .clipShape(.rect(cornerRadius: PrismediaRadius.badge))

                    VStack(alignment: .leading, spacing: PrismediaSpacing.extraExtraSmall) {
                        Text(track.title)
                            .font(.callout.weight(.semibold))
                            .lineLimit(1)
                        Text(MusicPresentation.artist(track.artist))
                            .font(.caption)
                            .foregroundStyle(PrismediaColor.textSecondary)
                            .lineLimit(1)
                    }
                }
                .frame(width: isExpanded ? 190 : 170, alignment: .leading)
                .contentShape(.rect)
            }
            .accessibilityLabel("Show Now Playing for \(track.title)")
        }

        private var transport: some View {
            HStack(spacing: PrismediaSpacing.medium) {
                Button("Previous Track", systemImage: "backward.fill", action: controller.skipToPrevious)
                    .labelStyle(.iconOnly)
                    .disabled(!controller.queue.canGoPrevious)

                Button(
                    controller.isPlaying ? "Pause" : "Play",
                    systemImage: controller.isPlaying ? "pause.fill" : "play.fill",
                    action: togglePlayback
                )
                .labelStyle(.iconOnly)
                .font(.title3.weight(.semibold))
                .foregroundStyle(accent)
                .contentTransition(.identity)

                Button("Next Track", systemImage: "forward.fill", action: controller.skipToNext)
                    .labelStyle(.iconOnly)
                    .disabled(!controller.queue.canGoNext)
            }
            .foregroundStyle(PrismediaColor.textPrimary)
        }

        private func timeline(_ track: MusicTrack) -> some View {
            VStack(spacing: PrismediaSpacing.extraExtraSmall) {
                HStack {
                    Text(MusicPresentation.clockTime(engine.elapsedTime))
                    Spacer(minLength: PrismediaSpacing.small)
                    Text("−\(MusicPresentation.clockTime(remainingTime(for: track)))")
                }
                .font(.caption2.monospacedDigit())
                .foregroundStyle(PrismediaColor.textMuted)

                Slider(
                    value: Binding(
                        get: { min(engine.elapsedTime, duration(for: track)) },
                        set: { controller.seek(to: $0) }
                    ),
                    in: 0...duration(for: track)
                )
                .tint(accent)
                .controlSize(.mini)
                .accessibilityLabel("Playback Position")
            }
            .frame(width: 130)
        }

        private var volumeControl: some View {
            HStack(spacing: PrismediaSpacing.extraSmall) {
                Image(systemName: volume == 0 ? "speaker.slash.fill" : "speaker.wave.2.fill")
                    .font(.caption)
                    .foregroundStyle(PrismediaColor.textSecondary)
                Slider(value: $volume, in: 0...1)
                    .controlSize(.mini)
                    .accessibilityLabel("Volume")
            }
            .frame(width: 86)
        }

        private var accent: Color {
            artworkPalette?.primary.color ?? PrismediaColor.materialSpectrumGreen
        }

        private var progress: Double {
            guard let track = controller.currentTrack else { return 0 }
            return min(max(engine.elapsedTime / duration(for: track), 0), 1)
        }

        private func duration(for track: MusicTrack) -> Double {
            max(engine.duration, track.duration ?? 0, 1)
        }

        private func remainingTime(for track: MusicTrack) -> Double {
            max(0, duration(for: track) - engine.elapsedTime)
        }

        private func togglePlayback() {
            withoutMusicControlAnimation {
                controller.isPlaying ? controller.pause() : controller.resume()
            }
        }
    }

    #if DEBUG
        #Preview("Mac Music Floating Player") {
            @Previewable @State var controller = MusicPreviewData.controller()
            @Previewable @State var engine = AVPlayerAudioPlaybackEngine()

            PreviewShell(signedIn: true) {
                MacMusicMiniPlayerView(engine: engine, showNowPlaying: {})
                    .environment(controller)
                    .frame(width: 860, height: 120)
            }
        }
    #endif
#endif
