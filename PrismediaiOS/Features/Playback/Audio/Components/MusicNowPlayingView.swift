#if os(iOS)
    import SwiftUI

    struct MusicNowPlayingView: View {
        @Environment(\.dismiss) private var dismiss
        @Environment(PrismediaAppEnvironment.self) private var environment
        @Environment(MusicPlayerController.self) private var controller
        @Namespace private var artworkNamespace

        let engine: AVPlayerAudioPlaybackEngine

        @State private var presentation = MusicNowPlayingPresentation.player
        @State private var queueShowsHistory = false
        @State private var scrubPosition: Double = 0
        @State private var isScrubbing = false
        @State private var trackForCollection: MusicTrack?
        @Binding var artworkPalette: ArtworkPalette?

        var body: some View {
            NavigationStack {
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
            .accessibilityIdentifier("music.now-playing")
            .onChange(of: engine.elapsedTime) { _, value in
                if !isScrubbing { scrubPosition = value }
            }
            .sheet(item: $trackForCollection) { track in
                AddToCollectionSheet(
                    items: [CollectionEntityReference(entityType: .audioTrack, entityID: track.id)]
                )
                .environment(environment)
            }
        }

        private func playerContent(_ track: MusicTrack) -> some View {
            VStack(spacing: 0) {
                ZStack {
                    MusicNowPlayingQueueView(
                        currentTrack: track,
                        artworkNamespace: artworkNamespace,
                        isActive: presentation == .queue,
                        showsHistory: $queueShowsHistory,
                        onShowPlayer: showPlayer,
                        onAddToCollection: { trackForCollection = track }
                    )
                    .allowsHitTesting(presentation == .queue)

                    MusicNowPlayingPlayerView(
                        track: track,
                        artworkNamespace: artworkNamespace,
                        isActive: presentation == .player,
                        onShowQueue: showQueue,
                        onAddToCollection: { trackForCollection = track }
                    )
                    .allowsHitTesting(presentation == .player)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .layoutPriority(1)

                MusicNowPlayingTransportView(
                    track: track,
                    engine: engine,
                    scrubPosition: $scrubPosition,
                    isScrubbing: $isScrubbing
                )

                MusicNowPlayingControlBar(
                    presentation: presentation,
                    selectedTint: artworkPalette?.primary.color ?? PrismediaColor.accent,
                    onToggleQueue: toggleQueue
                )
                .padding(.top, PrismediaSpacing.small)
                .padding(.horizontal, PrismediaSpacing.extraLarge)
                .padding(.bottom, PrismediaSpacing.medium)
            }
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
            withAnimation(.snappy(duration: 0.42, extraBounce: 0.04)) {
                presentation = newPresentation
            }
        }

        private func closePlayer() {
            dismiss()
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

    #if DEBUG
        #Preview("Mini Player · Expanded") {
            @Previewable @State var controller = MusicPreviewData.controller()
            MusicMiniPlayerView(showNowPlaying: {})
                .environment(controller)
                .environment(PrismediaPreviewData.model(signedIn: true))
                .padding()
                .background(PrismediaBackdrop())
        }

        #Preview("Now Playing") {
            @Previewable @State var controller = MusicPreviewData.controller()
            @Previewable @State var engine = AVPlayerAudioPlaybackEngine()
            @Previewable @State var artworkPalette: ArtworkPalette?
            MusicNowPlayingView(engine: engine, artworkPalette: $artworkPalette)
                .environment(controller)
                .environment(PrismediaPreviewData.model(signedIn: true))
        }
    #endif
#endif
