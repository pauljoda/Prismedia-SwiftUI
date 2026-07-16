#if os(iOS)
    import Foundation
    import Observation
    import SwiftUI

    struct MusicPlaybackHost<Content: View>: View {
        @Environment(\.scenePhase) private var scenePhase
        @Environment(PrismediaAppEnvironment.self) private var environment
        @Environment(MusicPlaybackComposition.self) private var playback
        @State private var miniPlayerVisibility = MusicMiniPlayerVisibility()
        @State private var nowPlayingPresented = false
        @Namespace private var nowPlayingTransitionNamespace

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
                .onChange(of: scenePhase) { _, phase in
                    guard phase != .active else { return }
                    Task { await controller.flushAudiobookProgress() }
                }
        }

        @ViewBuilder
        private var playbackContent: some View {
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
