#if os(iOS)
    import SwiftUI

    struct IPadMusicMiniPlayerView: View {
        @Environment(\.musicMiniPlayerVisibility) private var visibility
        @Environment(MusicPlayerController.self) private var controller
        @Binding private var artworkPalette: ArtworkPalette?
        @State private var scrubPosition = 0.0
        @State private var isScrubbing = false

        let engine: AVPlayerAudioPlaybackEngine
        let showNowPlaying: () -> Void

        init(
            engine: AVPlayerAudioPlaybackEngine,
            artworkPalette: Binding<ArtworkPalette?>,
            showNowPlaying: @escaping () -> Void
        ) {
            self.engine = engine
            _artworkPalette = artworkPalette
            self.showNowPlaying = showNowPlaying
        }

        var body: some View {
            if let track = controller.currentTrack {
                VStack(spacing: 0) {
                    nowPlayingHeader(track)
                    compactTimeline(track)
                    controlRow
                }
                .buttonStyle(.plain)
                .containerRelativeFrame(.horizontal, alignment: .center) { length, _ in
                    min(760, max(480, length - 520))
                }
                .contentShape(.rect(cornerRadius: PrismediaRadius.control))
                .glassEffect(.regular.interactive(), in: .rect(cornerRadius: PrismediaRadius.control))
                .overlay {
                    RoundedRectangle(cornerRadius: PrismediaRadius.control)
                        .stroke(accent.opacity(0.48), lineWidth: PrismediaLayout.hairline)
                        .allowsHitTesting(false)
                }
                .shadow(color: PrismediaColor.background.opacity(0.4), radius: 22, y: 10)
                .padding(.horizontal, PrismediaSpacing.extraExtraLarge)
                .padding(.top, PrismediaSpacing.small)
                .padding(.bottom, PrismediaSpacing.medium)
                .contextMenu {
                    Button("Show Now Playing", systemImage: "music.note.list", action: showNowPlaying)
                    Divider()
                    Button("Hide Player", systemImage: "xmark") {
                        visibility?.hideByUser()
                    }
                }
                .onAppear(perform: synchronizeTimeline)
                .onChange(of: engine.elapsedTime) { _, elapsedTime in
                    guard !isScrubbing else { return }
                    scrubPosition = elapsedTime
                }
                .onChange(of: track.id) { _, _ in
                    synchronizeTimeline()
                }
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("music.mini-player")
            }
        }

        private func nowPlayingHeader(_ track: MusicTrack) -> some View {
            HStack(spacing: PrismediaSpacing.medium) {
                trackButton(track)

                Text(
                    "\(MusicPresentation.clockTime(engine.elapsedTime)) / \(MusicPresentation.clockTime(duration(for: track)))"
                )
                .font(.caption.monospacedDigit())
                .foregroundStyle(PrismediaColor.textMuted)
                .contentTransition(.numericText())

                Button("Hide Player", systemImage: "xmark") {
                    visibility?.hideByUser()
                }
                .labelStyle(.iconOnly)
                .foregroundStyle(PrismediaColor.textSecondary)
                .frame(
                    width: PrismediaLayout.minimumHitTarget,
                    height: PrismediaLayout.minimumHitTarget
                )
                .contentShape(.rect)
                .accessibilityIdentifier("music.mini-player.hide")
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
            .layoutPriority(1)
            .accessibilityLabel("Show Now Playing for \(track.title)")
            .accessibilityIdentifier("music.mini-player.track")
        }

        private func compactTimeline(_ track: MusicTrack) -> some View {
            Slider(
                value: $scrubPosition,
                in: 0 ... duration(for: track),
                onEditingChanged: scrubDidChange
            )
            .controlSize(.mini)
            .tint(accent)
            .accessibilityLabel("Playback Position")
            .accessibilityValue(
                "\(MusicPresentation.clockTime(scrubPosition)) of \(MusicPresentation.clockTime(duration(for: track)))"
            )
            .padding(.horizontal, PrismediaSpacing.large)
            .padding(.bottom, PrismediaSpacing.small)
        }

        private var controlRow: some View {
            ZStack {
                HStack {
                    MusicRoutePicker()
                        .glassEffect(.regular.interactive(), in: .circle)
                        .accessibilityLabel("Choose Audio Output")

                    Spacer(minLength: 0)

                    Button("Show Now Playing", systemImage: "music.note.list", action: showNowPlaying)
                        .labelStyle(.iconOnly)
                        .foregroundStyle(accent)
                        .frame(
                            width: PrismediaLayout.minimumHitTarget,
                            height: PrismediaLayout.minimumHitTarget
                        )
                        .contentShape(.rect)
                        .accessibilityHint("Opens playback position, queue, and audio controls")
                        .accessibilityIdentifier("music.mini-player.now-playing")
                }

                playbackControls
            }
            .padding(.horizontal, PrismediaSpacing.large)
            .padding(.top, PrismediaSpacing.extraSmall)
            .padding(.bottom, PrismediaSpacing.medium)
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
                            Circle()
                                .stroke(accent.opacity(0.46), lineWidth: PrismediaLayout.hairline)
                                .allowsHitTesting(false)
                        }
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

        private func synchronizeTimeline() {
            scrubPosition = engine.elapsedTime
        }

        private func scrubDidChange(_ editing: Bool) {
            isScrubbing = editing
            if !editing { controller.seek(to: scrubPosition) }
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
            @Previewable @State var engine = AVPlayerAudioPlaybackEngine()
            @Previewable @State var artworkPalette: ArtworkPalette?

            PreviewShell(signedIn: true) {
                IPadMusicMiniPlayerView(
                    engine: engine,
                    artworkPalette: $artworkPalette,
                    showNowPlaying: {}
                )
                    .environment(controller)
            }
        }
    #endif
#endif
