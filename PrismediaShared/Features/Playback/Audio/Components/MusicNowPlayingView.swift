#if os(iOS) || os(macOS)
    import SwiftUI

    struct MusicNowPlayingView: View {
        @Environment(\.accessibilityReduceMotion) private var reduceMotion
        @Environment(\.dismiss) private var dismiss
        @Environment(PrismediaAppEnvironment.self) private var environment
        @Environment(PrismediaAppRouter.self) private var router
        @Environment(MusicPlayerController.self) private var controller
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
                            ToolbarItem(placement: .principal) {
                                dismissHandle
                            }
                        }
                        .toolbarBackground(.hidden, for: .navigationBar)
                }
                .presentationBackground(.clear)
                .musicNowPlayingPresentationBehavior(
                    engine: engine,
                    isScrubbing: isScrubbing,
                    scrubPosition: $scrubPosition,
                    trackForCollection: $trackForCollection,
                    environment: environment
                )
            #else
                playerSurface
                    .safeAreaPadding(.top, PrismediaSpacing.extraLarge)
                    .overlay(alignment: .topTrailing) {
                        inspectorCloseButton
                    }
                .musicNowPlayingPresentationBehavior(
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

        private func playerContent(_ track: MusicTrack) -> some View {
            VStack(spacing: 0) {
                ZStack {
                    MusicNowPlayingQueueView(
                        currentTrack: track,
                        artworkNamespace: artworkNamespace,
                        artworkIsSource: artworkIsSource,
                        isActive: presentation == .queue,
                        showsHistory: $queueShowsHistory,
                        onShowPlayer: showPlayer,
                        onNavigate: navigate,
                        onAddToCollection: { trackForCollection = track }
                    )
                    .allowsHitTesting(presentation == .queue)

                    MusicNowPlayingPlayerView(
                        track: track,
                        artworkNamespace: artworkNamespace,
                        artworkIsSource: artworkIsSource,
                        isActive: presentation == .player,
                        onShowQueue: showQueue,
                        onNavigate: navigate,
                        onAddToCollection: { trackForCollection = track }
                    )
                    .allowsHitTesting(presentation == .player)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .layoutPriority(1)

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

        #if os(macOS)
            private var inspectorCloseButton: some View {
                Button("Close Now Playing", systemImage: "xmark", action: closePlayer)
                    .labelStyle(.iconOnly)
                    .buttonStyle(.glass)
                    .buttonBorderShape(.circle)
                    .help("Hide Now Playing Inspector")
                    .padding(PrismediaSpacing.medium)
                    .accessibilityIdentifier("music.close-player")
            }
        #endif

        private var selectedTint: Color {
            artworkPalette?.primary.color ?? PrismediaColor.accent
        }

        private func toggleQueue() {
            setPresentation(presentation == .queue ? .player : .queue)
        }

        private func showQueue() {
            setPresentation(.queue)
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
            engine: AVPlayerAudioPlaybackEngine,
            isScrubbing: Bool,
            scrubPosition: Binding<Double>,
            trackForCollection: Binding<MusicTrack?>,
            environment: PrismediaAppEnvironment
        ) -> some View {
            self
                .onChange(of: engine.elapsedTime) { _, value in
                    if !isScrubbing { scrubPosition.wrappedValue = value }
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
