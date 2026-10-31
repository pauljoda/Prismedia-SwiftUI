#if os(iOS)
    import Foundation
    import Observation
    import SwiftUI

    struct MusicPlaybackHost<Content: View>: View {
        @Environment(\.scenePhase) private var scenePhase
        @Environment(\.horizontalSizeClass) private var horizontalSizeClass
        @Environment(\.accessibilityReduceMotion) private var reduceMotion
        @Environment(PrismediaAppEnvironment.self) private var environment
        @Environment(MusicPlaybackComposition.self) private var playback
        @State private var miniPlayerVisibility = MusicMiniPlayerVisibility()
        @State private var nowPlayingPresented = false
        /// Regular width only: the bar collapsed to floating artwork in a corner.
        @State private var miniPlayerIsCollapsed = false
        @State private var collapsedMiniPlayerEdge = HorizontalEdge.trailing
        /// True while the bar expands out of the floating artwork: it fades in
        /// around the artwork flying back instead of sliding up from the bottom.
        @State private var miniPlayerExpandsFromArtwork = false
        @Namespace private var nowPlayingTransitionNamespace
        @Namespace private var miniPlayerArtworkNamespace

        private let content: Content

        @MainActor
        init(
            @ViewBuilder content: () -> Content
        ) {
            self.content = content()
        }

        var body: some View {
            playbackContent
                .environment(\.musicMiniPlayerVisibility, miniPlayerVisibility)
                .fullScreenCover(isPresented: $nowPlayingPresented) {
                    MusicNowPlayingView(
                        engine: engine,
                        artworkPalette: artworkPaletteBinding
                    )
                    .environment(controller)
                    .navigationTransition(
                        .zoom(
                            sourceID: nowPlayingTransitionID,
                            in: nowPlayingTransitionNamespace
                        )
                    )
                }
                .task(id: controller.currentTrack?.id) {
                    let track = controller.currentTrack
                    await MusicQueueArtworkPreloader(
                        playbackService: playback.playbackService,
                        artworkLoader: environment.artworkLoader
                    ).prewarm(queue: controller.queue)
                    await playback.prepareArtworkPalette(
                        for: track,
                        artworkURL: playback.artworkURL(for: track?.artworkPath),
                        loader: environment.artworkPaletteLoader
                    )
                }
                .task {
                    await controller.runProgressHeartbeat()
                }
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active {
                        controller.resumeMappedProgressActivity()
                    } else {
                        Task { await controller.flushMappedProgress() }
                    }
                }
                .onChange(of: controller.currentQueueID) {
                    miniPlayerVisibility.revealForPlaybackActivity()
                }
                .onChange(of: controller.isPlaying) { _, isPlaying in
                    guard isPlaying else { return }
                    miniPlayerVisibility.revealForPlaybackActivity()
                }
                #if DEBUG
                    .onAppear(perform: bootstrapUITestPlaybackIfNeeded)
                #endif
        }

        @ViewBuilder
        private var playbackContent: some View {
            if horizontalSizeClass == .regular {
                content
                    .environment(controller)
                    .safeAreaInset(edge: .bottom, spacing: 0) {
                        if showsMiniPlayer, !miniPlayerIsCollapsed {
                            iPadMiniPlayer
                                .transition(
                                    miniPlayerExpandsFromArtwork
                                        ? .opacity
                                        : .move(edge: .bottom).combined(with: .opacity)
                                )
                        }
                    }
                    // The collapsed artwork floats in a corner and reserves no space.
                    // The bar's artwork flies into it, so it appears without a
                    // transition, and it fades out only so the bar's artwork has a
                    // source to fly back from.
                    .overlay(alignment: collapsedMiniPlayerEdge == .leading ? .bottomLeading : .bottomTrailing) {
                        if showsMiniPlayer, miniPlayerIsCollapsed {
                            IPadMusicMiniPlayerBubble(
                                edge: $collapsedMiniPlayerEdge,
                                artworkNamespace: miniPlayerArtworkNamespace,
                                artworkPalette: playback.artworkPalette,
                                onExpand: { setMiniPlayerCollapsed(false) }
                            )
                            .environment(controller)
                            .transition(.asymmetric(insertion: .identity, removal: .opacity))
                        }
                    }
                    .animation(reduceMotion ? nil : .snappy, value: showsMiniPlayer)
            } else {
                if #available(iOS 26.1, *) {
                    content
                        .environment(controller)
                        .tabViewBottomAccessory(isEnabled: showsMiniPlayer) {
                            miniPlayer
                        }
                } else {
                    content
                        .environment(controller)
                        .tabViewBottomAccessory {
                            if showsMiniPlayer { miniPlayer }
                        }
                }
            }
        }

        private var miniPlayer: some View {
            MusicMiniPlayerView {
                nowPlayingPresented = true
            }
            .environment(controller)
            .matchedTransitionSource(
                id: nowPlayingTransitionID,
                in: nowPlayingTransitionNamespace
            )
        }

        private var iPadMiniPlayer: some View {
            IPadMusicMiniPlayerView(
                engine: engine,
                artworkPalette: artworkPaletteBinding,
                artworkNamespace: miniPlayerArtworkNamespace,
                showNowPlaying: { nowPlayingPresented = true },
                minimize: { setMiniPlayerCollapsed(true) }
            )
            .environment(controller)
            .matchedTransitionSource(
                id: nowPlayingTransitionID,
                in: nowPlayingTransitionNamespace
            )
        }

        /// Animated so the artwork moves between the bar and the corner as one piece.
        private func setMiniPlayerCollapsed(_ isCollapsed: Bool) {
            miniPlayerExpandsFromArtwork = !isCollapsed
            withAnimation(reduceMotion ? nil : .snappy(duration: 0.45, extraBounce: 0.04)) {
                miniPlayerIsCollapsed = isCollapsed
            } completion: {
                miniPlayerExpandsFromArtwork = false
            }
        }

        private var engine: AVPlayerAudioPlaybackEngine { playback.engine }
        private var nowPlayingTransitionID: String { "music.now-playing.presentation" }
        private var controller: MusicPlayerController { playback.controller }
        private var artworkPaletteBinding: Binding<ArtworkPalette?> {
            Binding(
                get: { playback.artworkPalette },
                set: { playback.artworkPalette = $0 }
            )
        }
        private var showsMiniPlayer: Bool {
            controller.currentTrack != nil && !miniPlayerVisibility.isSuppressed
        }

        #if DEBUG
            private func bootstrapUITestPlaybackIfNeeded() {
                guard controller.currentTrack == nil else { return }
                let tracks = PrismediaUITestBootstrap.musicTracks()
                guard !tracks.isEmpty else { return }
                controller.play(tracks: tracks, queueMode: .ordered)
                nowPlayingPresented = PrismediaUITestBootstrap.presentsNowPlaying()
                miniPlayerIsCollapsed = PrismediaUITestBootstrap.collapsesMiniPlayer()
            }
        #endif
    }

    #if DEBUG
        #Preview("Music Playback Host") {
            @Previewable @State var playback = MusicPlaybackComposition()
            PreviewShell(signedIn: true) {
                MusicPlaybackHost {
                    TabView {
                        Tab("Albums", systemImage: "square.stack") {
                            NavigationStack {
                                Text("Music Library")
                                    .navigationTitle("Albums")
                            }
                        }
                    }
                }
                .environment(playback)
            }
        }
    #endif
#endif
