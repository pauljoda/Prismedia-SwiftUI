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
        /// Shared with the collapsed artwork, which this bar's artwork flies into.
        let artworkNamespace: Namespace.ID
        let showNowPlaying: () -> Void
        /// Collapses the bar to floating artwork in a corner.
        let minimize: () -> Void

        init(
            engine: AVPlayerAudioPlaybackEngine,
            artworkPalette: Binding<ArtworkPalette?>,
            artworkNamespace: Namespace.ID,
            showNowPlaying: @escaping () -> Void,
            minimize: @escaping () -> Void
        ) {
            self.engine = engine
            _artworkPalette = artworkPalette
            self.artworkNamespace = artworkNamespace
            self.showNowPlaying = showNowPlaying
            self.minimize = minimize
        }

        /// One bar whose track and transport groups the system arranges side by
        /// side, so on iPhone Duo each keeps to its own side of the fold.
        var body: some View {
            if let track = controller.currentTrack {
                // An arrangement has no height of its own, so a hidden copy of the
                // transport sizes the bar and the arranged groups fill it.
                transportGroup(track)
                    .hidden()
                    .overlay {
                        PrismediaArrangedPanes {
                            trackGroup(track)
                                .padding(.trailing, PrismediaSpacing.medium)
                        } secondary: {
                            transportGroup(track)
                                .padding(.leading, PrismediaSpacing.medium)
                        }
                    }
                    .padding(.horizontal, PrismediaSpacing.small)
                    .padding(.vertical, PrismediaSpacing.extraSmall)
                    .glassEffect(.regular, in: .capsule)
                    .padding(.horizontal, PrismediaSpacing.extraExtraLarge)
                    .buttonStyle(.plain)
                    .padding(.top, PrismediaSpacing.small)
                    .padding(.bottom, PrismediaSpacing.medium)
                    .onAppear(perform: synchronizeTimeline)
                    .onChange(of: engine.elapsedTime) {
                        guard !isScrubbing else { return }
                        synchronizeTimeline()
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

        private func trackGroup(_ track: MusicTrack) -> some View {
            HStack(spacing: PrismediaSpacing.extraSmall) {
                transportButton(
                    "Minimize Player",
                    systemImage: "arrow.down.right.and.arrow.up.left",
                    isDisabled: false,
                    action: minimize
                )
                .accessibilityIdentifier("music.mini-player.minimize")
                trackButton(track)
                actionsButton(track)
            }
            .frame(maxWidth: .infinity)
        }

        /// Shuffle and repeat, then the timeline, give way first when the pane is narrow.
        private func transportGroup(_ track: MusicTrack) -> some View {
            ViewThatFits(in: .horizontal) {
                transportControls(track, includesModes: true, includesTimeline: true)
                transportControls(track, includesModes: false, includesTimeline: true)
                transportControls(track, includesModes: false, includesTimeline: false)
            }
            .frame(maxWidth: .infinity)
        }

        private func transportControls(
            _ track: MusicTrack,
            includesModes: Bool,
            includesTimeline: Bool
        ) -> some View {
            HStack(spacing: PrismediaSpacing.extraSmall) {
                if includesModes { shuffleButton }
                previousButton
                playButton
                nextButton
                if includesModes { repeatButton }
                if includesTimeline {
                    playbackTimeline(track)
                        .padding(.leading, PrismediaSpacing.extraSmall)
                }
            }
        }

        /// The times sit either side of the slider, so the row centres on the
        /// transport buttons and its last element stays clear of the capsule's end.
        private func playbackTimeline(_ track: MusicTrack) -> some View {
            let duration = duration(for: track)
            return HStack(spacing: PrismediaSpacing.small) {
                Text(MusicPresentation.clockTime(scrubPosition))
                    .accessibilityHidden(true)

                Slider(
                    value: $scrubPosition,
                    in: 0...duration,
                    onEditingChanged: scrubDidChange
                )
                .controlSize(.mini)
                .tint(accent)
                .frame(minWidth: 72)
                .accessibilityLabel("Playback Position")
                .accessibilityValue(
                    "\(MusicPresentation.clockTime(scrubPosition)) of \(MusicPresentation.clockTime(duration))"
                )
                .accessibilityIdentifier("music.mini-player.timeline")

                Text(MusicPresentation.clockTime(duration))
                    .accessibilityHidden(true)
            }
            .font(.caption2.monospacedDigit())
            .foregroundStyle(PrismediaColor.textMuted)
            .padding(.trailing, PrismediaSpacing.small)
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
                    .matchedGeometryEffect(
                        id: IPadMusicMiniPlayerBubble.artworkTransitionID,
                        in: artworkNamespace
                    )

                    VStack(alignment: .leading, spacing: PrismediaSpacing.extraExtraSmall) {
                        Text(controller.entryTitle ?? track.title)
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
            .accessibilityLabel("Show Now Playing for \(controller.entryTitle ?? track.title)")
            .accessibilityIdentifier("music.mini-player.track")
        }

        private var previousButton: some View {
            transportButton(
                "Previous Track",
                systemImage: "backward.fill",
                isDisabled: !controller.canSkipToPrevious,
                action: controller.skipToPrevious
            )
        }

        private var nextButton: some View {
            transportButton(
                "Next Track",
                systemImage: "forward.fill",
                isDisabled: !controller.canSkipToNext,
                action: controller.skipToNext
            )
        }

        private var shuffleButton: some View {
            modeButton(
                controller.queue.isShuffled ? "Turn Shuffle Off" : "Turn Shuffle On",
                systemImage: "shuffle",
                isActive: controller.queue.isShuffled,
                isDisabled: controller.context?.preservesQueueOrder == true,
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

        /// Length of the entry playing: its chapter, else the whole file.
        private func duration(for track: MusicTrack) -> Double {
            max(entryPosition(for: track).duration, 1)
        }

        private func entryPosition(for track: MusicTrack) -> MusicEntryPosition {
            controller.entryPosition(
                atFileTime: engine.elapsedTime,
                fileDuration: max(engine.duration, track.duration ?? 0)
            )
        }

        private func synchronizeTimeline() {
            guard let track = controller.currentTrack else { return }
            scrubPosition = entryPosition(for: track).position
        }

        private func scrubDidChange(_ editing: Bool) {
            isScrubbing = editing
            if !editing { controller.seek(toEntryOffset: scrubPosition) }
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
            @Previewable @Namespace var artworkNamespace

            PreviewShell(signedIn: true) {
                IPadMusicMiniPlayerView(
                    engine: engine,
                    artworkPalette: $artworkPalette,
                    artworkNamespace: artworkNamespace,
                    showNowPlaying: {},
                    minimize: {}
                )
                .environment(controller)
            }
        }
    #endif
#endif
