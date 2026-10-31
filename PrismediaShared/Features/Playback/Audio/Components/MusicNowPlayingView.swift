#if os(iOS) || os(macOS)
    import SwiftUI

    struct MusicNowPlayingView: View {
        @Environment(\.accessibilityReduceMotion) private var reduceMotion
        @Environment(\.dismiss) private var dismiss
        @Environment(PrismediaAppEnvironment.self) private var environment
        @Environment(PrismediaAppRouter.self) private var router
        @Environment(MusicPlayerController.self) private var controller
        #if os(iOS)
            @Environment(\.horizontalSizeClass) private var horizontalSizeClass
        #endif
        @Namespace private var localArtworkNamespace

        @State private var presentation = MusicNowPlayingPresentation.player
        @State private var queueShowsHistory = false
        @State private var scrubPosition = 0.0
        @State private var isScrubbing = false
        @State private var trackForCollection: MusicTrack?
        @Binding private var artworkPalette: ArtworkPalette?

        private let engine: AVPlayerAudioPlaybackEngine
        private let providedArtworkNamespace: Namespace.ID?
        private let onDismiss: (() -> Void)?

        init(
            engine: AVPlayerAudioPlaybackEngine,
            artworkPalette: Binding<ArtworkPalette?>,
            artworkNamespace: Namespace.ID? = nil,
            onDismiss: (() -> Void)? = nil
        ) {
            self.engine = engine
            _artworkPalette = artworkPalette
            providedArtworkNamespace = artworkNamespace
            self.onDismiss = onDismiss
        }

        @ViewBuilder
        var body: some View {
            #if os(iOS)
                NavigationStack {
                    playerSurface
                        .navigationTitle("")
                        .prismediaInlineNavigationTitle()
                        .toolbar {
                            // Regular width would centre the handle over the fold, so
                            // the handle moves into the player pane and a close button
                            // joins the side bar.
                            if horizontalSizeClass == .regular {
                                ToolbarItem(placement: .cancellationAction) {
                                    PrismediaToolbarActionButton(
                                        "Close Now Playing",
                                        systemImage: "chevron.down",
                                        action: closePlayer
                                    )
                                    .accessibilityIdentifier("music.close-player")
                                }
                            } else {
                                ToolbarItem(placement: .principal) {
                                    dismissHandle
                                }
                            }
                        }
                        .toolbarBackground(.hidden, for: .navigationBar)
                }
                .presentationBackground(.clear)
                .musicNowPlayingPresentationBehavior(
                    controller: controller,
                    engine: engine,
                    isScrubbing: isScrubbing,
                    scrubPosition: $scrubPosition,
                    trackForCollection: $trackForCollection,
                    environment: environment
                )
            #else
                playerSurface
                    .safeAreaPadding(.top, PrismediaSpacing.screen)
                    .overlay(alignment: .topTrailing) {
                        inspectorCloseButton
                    }
                .musicNowPlayingPresentationBehavior(
                    controller: controller,
                    engine: engine,
                    isScrubbing: isScrubbing,
                    scrubPosition: $scrubPosition,
                    trackForCollection: $trackForCollection,
                    environment: environment
                )
            #endif
        }

        private var playerSurface: some View {
            Group {
                if let track = controller.currentTrack {
                    ArtworkPaletteSurface(
                        artworkPath: track.artworkPath,
                        fallbackSeed: track.album ?? track.title,
                        systemImage: "music.note",
                        palette: $artworkPalette
                    ) {
                        playerContent(track)
                    }
                } else {
                    ContentUnavailableView("Nothing Playing", systemImage: "music.note")
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(PrismediaColor.background)
            .accessibilityIdentifier("music.now-playing")
        }

        /// Compact width switches between the player and the queue. Regular width
        /// shows both as panes the system arranges, on iPhone Duo one on each side
        /// of the fold: the artwork and title in one, the queue with the controls
        /// beneath it in the other. Side by side that keeps the controls toward the
        /// thumb; half closed on a table the artwork sits in the raised half and the
        /// controls on the flat half.
        @ViewBuilder
        private func playerContent(_ track: MusicTrack) -> some View {
            #if os(iOS)
                if horizontalSizeClass == .regular {
                    PrismediaArrangedPanes {
                        VStack(spacing: 0) {
                            dismissHandle
                            playerView(track, isActive: true)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                    } secondary: {
                        VStack(spacing: 0) {
                            queueView(
                                track,
                                isActive: true,
                                isBesidePlayer: true,
                                artworkNamespace: artworkNamespace
                            )
                            .frame(maxHeight: .infinity)
                            playbackControls(track, showsQueueButton: false)
                        }
                    }
                } else {
                    switchedContent(track)
                }
            #else
                switchedContent(track)
            #endif
        }

        private func switchedContent(_ track: MusicTrack) -> some View {
            VStack(spacing: 0) {
                ZStack {
                    queueView(
                        track,
                        isActive: presentation == .queue,
                        isBesidePlayer: false,
                        artworkNamespace: artworkNamespace
                    )
                    .allowsHitTesting(presentation == .queue)

                    playerView(track, isActive: presentation == .player)
                        .allowsHitTesting(presentation == .player)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .layoutPriority(1)

                playbackControls(track, showsQueueButton: true)
            }
        }

        private func queueView(
            _ track: MusicTrack,
            isActive: Bool,
            isBesidePlayer: Bool,
            artworkNamespace: Namespace.ID
        ) -> some View {
            MusicNowPlayingQueueView(
                currentTrack: track,
                artworkNamespace: artworkNamespace,
                artworkIsSource: artworkIsSource,
                isActive: isActive,
                isBesidePlayer: isBesidePlayer,
                showsHistory: $queueShowsHistory,
                onShowPlayer: showPlayer,
                onNavigate: navigate,
                onAddToCollection: { trackForCollection = track }
            )
        }

        private func playerView(_ track: MusicTrack, isActive: Bool) -> some View {
            MusicNowPlayingPlayerView(
                track: track,
                title: controller.entryTitle ?? track.title,
                artworkNamespace: artworkNamespace,
                artworkIsSource: artworkIsSource,
                artworkAspectRatio: artworkAspectRatio,
                artworkFallbackSeed: controller.context?.playbackOwnerTitle,
                artworkSystemImage: artworkSystemImage,
                isActive: isActive,
                onNavigate: navigate,
                onAddToCollection: { trackForCollection = track }
            )
        }

        private func playbackControls(_ track: MusicTrack, showsQueueButton: Bool) -> some View {
            VStack(spacing: 0) {
                MusicNowPlayingTransportView(
                    track: track,
                    engine: engine,
                    selectedTint: selectedTint,
                    scrubPosition: $scrubPosition,
                    isScrubbing: $isScrubbing
                )

                MusicNowPlayingControlBar(
                    presentation: presentation,
                    selectedTint: selectedTint,
                    showsQueueButton: showsQueueButton,
                    onToggleQueue: toggleQueue
                )
                .padding(.top, PrismediaSpacing.small)
                .padding(.horizontal, PrismediaSpacing.extraLarge)
                .padding(.bottom, PrismediaSpacing.medium)
            }
        }

        private var artworkNamespace: Namespace.ID {
            providedArtworkNamespace ?? localArtworkNamespace
        }

        private var artworkIsSource: Bool {
            providedArtworkNamespace == nil
        }

        private var artworkAspectRatio: Double {
            controller.context?.playbackOwnerEntityKind?.thumbnailAspectRatio ?? 1
        }

        private var artworkSystemImage: String {
            controller.context?.playbackOwnerEntityKind?.thumbnailFallbackSystemImage ?? "music.note"
        }

        #if os(macOS)
            private var inspectorCloseButton: some View {
                Button("Close Now Playing", systemImage: "sidebar.trailing", action: closePlayer)
                    .labelStyle(.iconOnly)
                    .buttonStyle(.glass)
                    .buttonBorderShape(.circle)
                    .help("Hide Now Playing Inspector")
                    .padding(.top, PrismediaSpacing.section)
                    .padding(.trailing, PrismediaSpacing.large)
                    .accessibilityIdentifier("music.close-player")
            }
        #endif

        private var selectedTint: Color {
            artworkPalette?.primary.color ?? PrismediaColor.accent
        }

        private func toggleQueue() {
            setPresentation(presentation == .queue ? .player : .queue)
        }

        private func showPlayer() {
            setPresentation(.player)
        }

        private func setPresentation(_ newPresentation: MusicNowPlayingPresentation) {
            guard newPresentation != presentation else { return }
            if newPresentation == .player, queueShowsHistory {
                var transaction = Transaction(animation: nil)
                transaction.disablesAnimations = true
                withTransaction(transaction) {
                    queueShowsHistory = false
                }
            }
            withAnimation(reduceMotion ? nil : .snappy(duration: 0.42, extraBounce: 0.04)) {
                presentation = newPresentation
            }
        }

        private func closePlayer() {
            if let onDismiss {
                onDismiss()
            } else {
                dismiss()
            }
        }

        private func navigate(to link: EntityLink) {
            closePlayer()
            router.open(link: link)
        }

        private var dismissHandle: some View {
            Button(action: closePlayer) {
                Capsule()
                    .fill(PrismediaColor.onMedia.opacity(0.45))
                    .frame(width: 38, height: 5)
                    .frame(width: 80, height: PrismediaLayout.minimumHitTarget)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .simultaneousGesture(dismissGesture)
            .accessibilityIdentifier("music.close-player")
            .accessibilityLabel("Dismiss Now Playing")
        }

        private var dismissGesture: some Gesture {
            DragGesture(minimumDistance: 12)
                .onEnded { value in
                    let distance = max(
                        value.translation.height,
                        value.predictedEndTranslation.height
                    )
                    guard distance > 64 else { return }
                    closePlayer()
                }
        }
    }

    private extension View {
        func musicNowPlayingPresentationBehavior(
            controller: MusicPlayerController,
            engine: AVPlayerAudioPlaybackEngine,
            isScrubbing: Bool,
            scrubPosition: Binding<Double>,
            trackForCollection: Binding<MusicTrack?>,
            environment: PrismediaAppEnvironment
        ) -> some View {
            self
                .onChange(of: engine.elapsedTime) { _, value in
                    // The timeline shows the entry playing, so its position is an offset into it.
                    guard !isScrubbing else { return }
                    let fileDuration = max(engine.duration, controller.currentTrack?.duration ?? 0)
                    let entry = controller.entryPosition(atFileTime: value, fileDuration: fileDuration)
                    scrubPosition.wrappedValue = entry.position
                }
                .sheet(item: trackForCollection) { track in
                    AddToCollectionSheet(
                        items: [CollectionEntityReference(entityType: .audioTrack, entityID: track.id)]
                    )
                    .environment(environment)
                }
        }
    }

    #if DEBUG
        #if os(iOS)
            #Preview("Mini Player · Expanded") {
                @Previewable @State var controller = MusicPreviewData.controller()
                MusicMiniPlayerView(showNowPlaying: {})
                    .environment(controller)
                    .environment(PrismediaPreviewData.model(signedIn: true))
                    .padding()
                    .background(PrismediaBackdrop())
            }
        #endif

        #Preview("Now Playing") {
            @Previewable @State var controller = MusicPreviewData.controller()
            @Previewable @State var engine = AVPlayerAudioPlaybackEngine()
            @Previewable @State var artworkPalette: ArtworkPalette?
            MusicNowPlayingView(engine: engine, artworkPalette: $artworkPalette)
                .environment(controller)
                .environment(PrismediaPreviewData.model(signedIn: true))
                .environment(PrismediaAppRouter())
        }
    #endif
#endif
