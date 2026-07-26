#if os(macOS)
    import AVFoundation
    import SwiftUI

    struct MacMusicMiniPlayerView: View {
        @Environment(\.musicMiniPlayerVisibility) private var visibility
        @State private var artworkPalette: ArtworkPalette?
        @State private var positionAnchor = MacMusicPlaybackPositionAnchor()

        let controller: MusicPlayerController
        let engine: AVPlayerAudioPlaybackEngine
        let waveform: MusicWaveform?
        let artworkNamespace: Namespace.ID
        let showNowPlaying: () -> Void

        var body: some View {
            if let track = controller.currentTrack {
                VStack(spacing: 0) {
                    HStack(spacing: PrismediaSpacing.medium) {
                        trackButton(track)
                        transport

                        Button("Show Now Playing", systemImage: "sidebar.right", action: showNowPlaying)
                            .labelStyle(.iconOnly)
                            .foregroundStyle(accent)
                            .help("Show Now Playing Inspector")

                        Button("Hide Player", systemImage: "xmark") {
                            visibility?.hideByUser()
                        }
                        .labelStyle(.iconOnly)
                        .help("Hide Player")
                    }
                    .padding(.horizontal, PrismediaSpacing.medium)
                    .padding(.vertical, PrismediaSpacing.small)

                    timeline(track)
                }
                .buttonStyle(.plain)
                .controlSize(.large)
                .frame(width: 520)
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
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("music.mini-player")
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
                    .matchedGeometryEffect(
                        id: "music.now-playing.artwork.\(track.id.uuidString)",
                        in: artworkNamespace,
                        properties: .frame,
                        isSource: true
                    )

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
                .frame(width: 230, alignment: .leading)
                .contentShape(.rect)
            }
            .accessibilityLabel("Show Now Playing for \(track.title)")
        }

        private var transport: some View {
            HStack(spacing: PrismediaSpacing.medium) {
                Button("Previous Track", systemImage: "backward.fill", action: controller.skipToPrevious)
                    .labelStyle(.iconOnly)
                    .foregroundStyle(secondaryAccent)
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
                    .foregroundStyle(secondaryAccent)
                    .disabled(!controller.queue.canGoNext)
            }
        }

        @ViewBuilder
        private func timeline(_ track: MusicTrack) -> some View {
            TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: !controller.isPlaying)) { timeline in
                if let waveform, controller.context?.isAudiobook != true {
                    MacMusicWaveformStrip(
                        waveform: waveform,
                        position: interpolatedPosition(at: timeline.date, track: track),
                        duration: duration(for: track),
                        accent: accent,
                        secondaryAccent: secondaryAccent,
                        onSeek: seek
                    )
                } else {
                    Slider(
                        value: Binding(
                            get: { interpolatedPosition(at: timeline.date, track: track) },
                            set: seek
                        ),
                        in: 0...duration(for: track)
                    )
                    .tint(accent)
                    .controlSize(.mini)
                    .accessibilityLabel("Playback Position")
                    .padding(.horizontal, PrismediaSpacing.medium)
                    .padding(.bottom, PrismediaSpacing.extraSmall)
                }
            }
            .onAppear(perform: synchronizePositionAnchor)
            .onChange(of: engine.elapsedTime) { _, value in
                positionAnchor.synchronize(to: value)
            }
            .onChange(of: controller.isPlaying) { _, _ in synchronizePositionAnchor() }
            .onChange(of: controller.playbackRate) { _, _ in synchronizePositionAnchor() }
            .onChange(of: track.id) { _, _ in synchronizePositionAnchor() }
        }

        private var accent: Color {
            artworkPalette?.primary.color ?? PrismediaColor.materialSpectrumGreen
        }

        private var secondaryAccent: Color {
            artworkPalette?.secondary.color ?? PrismediaColor.textSecondary
        }

        private func duration(for track: MusicTrack) -> Double {
            max(engine.duration, track.duration ?? 0, 1)
        }

        private func interpolatedPosition(at date: Date, track: MusicTrack) -> Double {
            positionAnchor.position(
                at: date,
                isPlaying: controller.isPlaying,
                playbackRate: controller.playbackRate,
                duration: duration(for: track)
            )
        }

        private func seek(to position: Double) {
            positionAnchor.synchronize(to: position)
            controller.seek(to: position)
        }

        private func synchronizePositionAnchor() {
            positionAnchor.synchronize(to: engine.elapsedTime)
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
            @Previewable @Namespace var artworkNamespace

            PreviewShell(signedIn: true) {
                MacMusicMiniPlayerView(
                    controller: controller,
                    engine: engine,
                    waveform: MusicWaveformPreviewLoader.waveform,
                    artworkNamespace: artworkNamespace,
                    showNowPlaying: {}
                )
                .environment(controller)
                .frame(width: 860, height: 180)
            }
        }
    #endif
#endif
