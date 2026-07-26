#if os(macOS)
    import AVFoundation
    import SwiftUI

    struct MacMusicMiniPlayerView: View {
        @Environment(\.musicMiniPlayerVisibility) private var visibility
        @Binding var artworkPalette: ArtworkPalette?
        @State private var positionAnchor = MacMusicPlaybackPositionAnchor()
        @State private var scrubPosition = 0.0
        @State private var isScrubbing = false
        @State private var volume = 1.0

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
                VStack(spacing: 0) {
                    nowPlayingHeader(track)
                    compactSeekBar(track)

                    if let waveform, controller.context?.isAudiobook != true {
                        waveformTimeline(track, waveform: waveform)
                    }

                    controlRow
                }
                .buttonStyle(.plain)
                .frame(maxWidth: 760)
                .glassEffect(.regular, in: .rect(cornerRadius: PrismediaRadius.control))
                .overlay {
                    RoundedRectangle(cornerRadius: PrismediaRadius.control)
                        .stroke(accent.opacity(0.48), lineWidth: PrismediaLayout.hairline)
                        .allowsHitTesting(false)
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
                .onAppear(perform: synchronizePositionAnchor)
                .onChange(of: engine.elapsedTime) { _, value in
                    guard !isScrubbing else { return }
                    positionAnchor.synchronize(to: value)
                    scrubPosition = value
                }
                .onChange(of: controller.isPlaying) { _, _ in
                    synchronizePositionAnchor()
                }
                .onChange(of: engine.isPlaybackAdvancing) { _, _ in
                    synchronizePositionAnchor()
                }
                .onChange(of: controller.playbackRate) { _, _ in
                    synchronizePositionAnchor()
                }
                .onChange(of: track.id) { _, _ in
                    synchronizePositionAnchor()
                }
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("music.mini-player")
            }
        }

        private func nowPlayingHeader(_ track: MusicTrack) -> some View {
            HStack(spacing: PrismediaSpacing.medium) {
                trackButton(track)

                TimelineView(.periodic(from: .now, by: 0.5)) { timeline in
                    Text(
                        "\(MusicPresentation.clockTime(interpolatedPosition(at: timeline.date, track: track))) / \(MusicPresentation.clockTime(duration(for: track)))"
                    )
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(PrismediaColor.textMuted)
                    .contentTransition(.numericText())
                }

                Button("Hide Player", systemImage: "xmark") {
                    visibility?.hideByUser()
                }
                .labelStyle(.iconOnly)
                .foregroundStyle(PrismediaColor.textSecondary)
                .frame(width: PrismediaLayout.minimumHitTarget, height: PrismediaLayout.minimumHitTarget)
                .help("Hide Player")
            }
            .padding(.horizontal, PrismediaSpacing.large)
            .padding(.top, PrismediaSpacing.small)
            .padding(.bottom, PrismediaSpacing.extraSmall)
        }

        private func trackButton(_ track: MusicTrack) -> some View {
            Button(action: showNowPlaying) {
                HStack(spacing: PrismediaSpacing.small) {
                    MusicNowPlayingArtwork(
                        track: track,
                        cornerRadius: PrismediaRadius.badge
                    )
                    .frame(width: 40, height: 40)
                    .zIndex(1)

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
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(.rect)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityLabel("Show Now Playing for \(track.title)")
        }

        private func compactSeekBar(_ track: MusicTrack) -> some View {
            TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: !engine.isPlaybackAdvancing)) { timeline in
                MusicPlaybackTimeline(
                    position: Binding(
                        get: {
                            isScrubbing
                                ? scrubPosition
                                : interpolatedPosition(at: timeline.date, track: track)
                        },
                        set: { scrubPosition = $0 }
                    ),
                    duration: duration(for: track),
                    onEditingChanged: { scrubDidChange($0, track: track) },
                    showsTimeLabels: false
                )
                .controlSize(.mini)
                .environment(\.artworkPrimaryAccent, accent)
            }
            .padding(.horizontal, PrismediaSpacing.large)
            .padding(.bottom, PrismediaSpacing.small)
        }

        private func waveformTimeline(
            _ track: MusicTrack,
            waveform: MusicWaveform
        ) -> some View {
            TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: !engine.isPlaybackAdvancing)) { timeline in
                MacMusicWaveformStrip(
                    waveform: waveform,
                    position: isScrubbing
                        ? scrubPosition
                        : interpolatedPosition(at: timeline.date, track: track),
                    duration: duration(for: track),
                    accent: accent,
                    secondaryAccent: secondaryAccent,
                    onSeek: seek
                )
            }
        }

        private var controlRow: some View {
            ZStack {
                HStack {
                    volumeControl
                    Spacer(minLength: 0)
                    Button("Show Now Playing", systemImage: "sidebar.right", action: showNowPlaying)
                        .labelStyle(.iconOnly)
                        .foregroundStyle(PrismediaColor.textSecondary)
                        .frame(
                            width: PrismediaLayout.minimumHitTarget,
                            height: PrismediaLayout.minimumHitTarget
                        )
                        .help("Show Now Playing Inspector")
                }

                playbackControls
            }
            .padding(.horizontal, PrismediaSpacing.large)
            .padding(.top, PrismediaSpacing.extraSmall)
            .padding(.bottom, PrismediaSpacing.medium)
        }

        private var volumeControl: some View {
            HStack(spacing: PrismediaSpacing.extraSmall) {
                Image(systemName: volume == 0 ? "speaker.slash.fill" : "speaker.wave.2.fill")
                    .frame(width: 18)
                Slider(value: $volume, in: 0...1)
                    .controlSize(.mini)
                    .tint(accent)
                    .frame(width: 72)
                    .accessibilityLabel("Volume")
            }
            .font(.caption)
            .foregroundStyle(PrismediaColor.textMuted)
            .onAppear { volume = Double(engine.player.volume) }
            .onChange(of: volume) { _, value in
                engine.player.volume = Float(min(max(value, 0), 1))
            }
        }

        private var playbackControls: some View {
            HStack(spacing: PrismediaSpacing.extraExtraSmall) {
                compactControl(
                    controller.queue.isShuffled ? "Turn Shuffle Off" : "Turn Shuffle On",
                    systemImage: "shuffle",
                    isActive: controller.queue.isShuffled,
                    isDisabled: controller.context?.isAudiobook == true
                ) {
                    withoutMusicControlAnimation {
                        controller.setShuffleEnabled(!controller.queue.isShuffled)
                    }
                }

                compactControl(
                    "Previous Track",
                    systemImage: "backward.fill",
                    isDisabled: !controller.queue.canGoPrevious,
                    action: controller.skipToPrevious
                )

                Button(action: togglePlayback) {
                    Image(systemName: controller.isPlaying ? "pause.fill" : "play.fill")
                        .font(.body.weight(.bold))
                        .foregroundStyle(controller.isPlaying ? PrismediaColor.background : accent)
                        .frame(width: 36, height: 36)
                        .background(
                            controller.isPlaying ? accent.opacity(0.9) : accent.opacity(0.16),
                            in: Circle()
                        )
                        .overlay {
                            Circle().stroke(accent.opacity(0.46), lineWidth: PrismediaLayout.hairline)
                                .allowsHitTesting(false)
                        }
                        .frame(
                            width: PrismediaLayout.minimumHitTarget,
                            height: PrismediaLayout.minimumHitTarget
                        )
                        .contentShape(.rect)
                }
                .accessibilityLabel(controller.isPlaying ? "Pause" : "Play")
                .contentTransition(.identity)
                .animation(nil, value: controller.isPlaying)

                compactControl(
                    "Next Track",
                    systemImage: "forward.fill",
                    isDisabled: !controller.queue.canGoNext,
                    action: controller.skipToNext
                )

                compactControl(
                    repeatLabel,
                    systemImage: controller.queue.repeatMode == .one ? "repeat.1" : "repeat",
                    isActive: controller.queue.repeatMode != .off,
                    action: { withoutMusicControlAnimation(controller.cycleRepeatMode) }
                )
            }
        }

        private func compactControl(
            _ title: String,
            systemImage: String,
            isActive: Bool = false,
            isDisabled: Bool = false,
            action: @escaping () -> Void
        ) -> some View {
            Button(title, systemImage: systemImage, action: action)
                .labelStyle(.iconOnly)
                .font(.caption.weight(.semibold))
                .foregroundStyle(isActive ? accent : PrismediaColor.textMuted)
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

        private var secondaryAccent: Color {
            artworkPalette?.secondary.color ?? PrismediaColor.textSecondary
        }

        private var repeatLabel: String {
            switch controller.queue.repeatMode {
            case .off: "Set Repeat All"
            case .all: "Set Repeat One"
            case .one: "Turn Repeat Off"
            }
        }

        private func duration(for track: MusicTrack) -> Double {
            max(engine.duration, track.duration ?? 0, 1)
        }

        private func interpolatedPosition(at date: Date, track: MusicTrack) -> Double {
            positionAnchor.position(
                at: date,
                isPlaying: engine.isPlaybackAdvancing,
                playbackRate: controller.playbackRate,
                duration: duration(for: track)
            )
        }

        private func seek(to position: Double) {
            positionAnchor.synchronize(to: position)
            scrubPosition = position
            controller.seek(to: position)
        }

        private func synchronizePositionAnchor() {
            let currentTime = engine.player.currentTime().seconds
            let resolvedTime = currentTime.isFinite ? currentTime : engine.elapsedTime
            positionAnchor.synchronize(to: resolvedTime)
            if !isScrubbing { scrubPosition = resolvedTime }
        }

        private func scrubDidChange(_ editing: Bool, track: MusicTrack) {
            if editing {
                scrubPosition = interpolatedPosition(at: .now, track: track)
                isScrubbing = true
            } else {
                isScrubbing = false
                seek(to: scrubPosition)
            }
        }

        private func togglePlayback() {
            synchronizePositionAnchor()
            withoutMusicControlAnimation {
                controller.isPlaying ? controller.pause() : controller.resume()
            }
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
                .frame(width: 860, height: 180)
            }
        }
    #endif
#endif
