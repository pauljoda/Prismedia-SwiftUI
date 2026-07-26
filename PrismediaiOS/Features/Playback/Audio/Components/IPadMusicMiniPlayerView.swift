#if os(iOS)
    import SwiftUI

    struct IPadMusicMiniPlayerView: View {
        @Environment(\.musicMiniPlayerVisibility) private var visibility
        @Environment(PrismediaAppEnvironment.self) private var environment
        @Environment(PrismediaAppRouter.self) private var router
        @Environment(MusicPlayerController.self) private var controller
        @Binding private var artworkPalette: ArtworkPalette?
        @State private var actionsPresented = false
        @State private var trackForCollection: MusicTrack?
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
                HStack(spacing: PrismediaSpacing.extraSmall) {
                    shuffleButton
                    previousButton
                    playButton
                    nextButton
                    repeatButton

                    Capsule()
                        .fill(PrismediaColor.textMuted.opacity(0.28))
                        .frame(width: PrismediaLayout.hairline, height: 28)
                        .padding(.horizontal, PrismediaSpacing.extraSmall)
                        .accessibilityHidden(true)

                    trackButton(track)

                    playbackTimeline(track)

                    actionsButton(track)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, PrismediaSpacing.small)
                .padding(.vertical, PrismediaSpacing.extraSmall)
                .frame(maxWidth: 900)
                .glassEffect(.regular, in: .capsule)
                .padding(.horizontal, PrismediaSpacing.extraExtraLarge)
                .padding(.top, PrismediaSpacing.small)
                .padding(.bottom, PrismediaSpacing.medium)
                .onAppear(perform: synchronizeTimeline)
                .onChange(of: engine.elapsedTime) { _, elapsedTime in
                    guard !isScrubbing else { return }
                    scrubPosition = elapsedTime
                }
                .onChange(of: track.id) { _, _ in
                    actionsPresented = false
                    synchronizeTimeline()
                }
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

        private func playbackTimeline(_ track: MusicTrack) -> some View {
            let duration = duration(for: track)
            return VStack(spacing: 0) {
                Slider(
                    value: $scrubPosition,
                    in: 0 ... duration,
                    onEditingChanged: scrubDidChange
                )
                .controlSize(.mini)
                .tint(accent)
                .accessibilityLabel("Playback Position")
                .accessibilityValue(
                    "\(MusicPresentation.clockTime(scrubPosition)) of \(MusicPresentation.clockTime(duration))"
                )
                .accessibilityIdentifier("music.mini-player.timeline")

                HStack {
                    Text(MusicPresentation.clockTime(scrubPosition))
                    Spacer(minLength: PrismediaSpacing.extraSmall)
                    Text(MusicPresentation.clockTime(duration))
                }
                .font(.caption2.monospacedDigit())
                .foregroundStyle(PrismediaColor.textMuted)
                .accessibilityHidden(true)
            }
            .frame(minWidth: 120, idealWidth: 170, maxWidth: 210)
        }

        private func actionsButton(_ track: MusicTrack) -> some View {
            Button {
                actionsPresented = true
            } label: {
                Image(systemName: "ellipsis")
                    .font(.body.weight(.semibold))
                    .symbolRenderingMode(.monochrome)
                    .foregroundStyle(PrismediaColor.textSecondary)
                    .frame(
                        width: PrismediaLayout.minimumHitTarget,
                        height: PrismediaLayout.minimumHitTarget
                    )
                    .contentShape(.rect)
            }
            .accessibilityLabel("More actions for \(track.title)")
            .accessibilityHint("Shows actions above the compact player")
            .accessibilityIdentifier("music.track-actions")
            .popover(
                isPresented: $actionsPresented,
                attachmentAnchor: .rect(.bounds),
                arrowEdge: .bottom
            ) {
                MusicTrackActionsPopoverView(
                    track: track,
                    onNavigate: router.open,
                    onAddToCollection: { trackForCollection = track },
                    onShowNowPlaying: showNowPlaying,
                    onHidePlayer: { visibility?.hideByUser() }
                )
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

        private var shuffleButton: some View {
            modeButton(
                controller.queue.isShuffled ? "Turn Shuffle Off" : "Turn Shuffle On",
                systemImage: "shuffle",
                isActive: controller.queue.isShuffled,
                isDisabled: controller.context?.isAudiobook == true,
                identifier: "music.mini-player.shuffle"
            ) {
                withoutMusicControlAnimation {
                    controller.setShuffleEnabled(!controller.queue.isShuffled)
                }
            }
        }

        private var repeatButton: some View {
            modeButton(
                repeatLabel,
                systemImage: controller.queue.repeatMode == .one ? "repeat.1" : "repeat",
                isActive: controller.queue.repeatMode != .off,
                isDisabled: false,
                identifier: "music.mini-player.repeat"
            ) {
                withoutMusicControlAnimation(controller.cycleRepeatMode)
            }
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

        private func modeButton(
            _ title: String,
            systemImage: String,
            isActive: Bool,
            isDisabled: Bool,
            identifier: String,
            action: @escaping () -> Void
        ) -> some View {
            Button(title, systemImage: systemImage, action: action)
                .labelStyle(.iconOnly)
                .font(.body.weight(.semibold))
                .foregroundStyle(isActive ? accent : PrismediaColor.textSecondary)
                .frame(
                    width: PrismediaLayout.minimumHitTarget,
                    height: PrismediaLayout.minimumHitTarget
                )
                .contentShape(.rect)
                .disabled(isDisabled)
                .accessibilityValue(isActive ? "On" : "Off")
                .accessibilityIdentifier(identifier)
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
        #Preview("iPad Music Floating Player", traits: .fixedLayout(width: 1_000, height: 100)) {
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
