#if os(iOS)
    import Foundation
    import Observation
    import SwiftUI

    struct MusicPlaybackHost<Content: View>: View {
        @Environment(\.scenePhase) private var scenePhase
        @Environment(PrismediaAppEnvironment.self) private var environment
        @State private var playback = MusicPlaybackComposition()
        @State private var remoteCommands: MusicRemoteCommandCoordinator?
        @State private var miniPlayerVisibility = MusicMiniPlayerVisibility()
        @State private var nowPlayingPresented = false
        @Namespace private var nowPlayingTransitionNamespace

        private let client: PrismediaAPIClient
        private let content: Content

        @MainActor
        init(
            client: PrismediaAPIClient,
            @ViewBuilder content: () -> Content
        ) {
            self.client = client
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
                .onAppear(perform: connectPlaybackSystem)
                .task(id: controller.currentTrack?.id) {
                    let track = controller.currentTrack
                    await playback.prepareArtworkPalette(
                        for: track,
                        artworkURL: client.assetURL(for: track?.artworkPath),
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

        private func connectPlaybackSystem() {
            playback.connect(to: client)
            if remoteCommands == nil {
                remoteCommands = MusicRemoteCommandCoordinator(
                    controller: controller,
                    engine: engine,
                    client: client
                )
            }
            engine.onPlaybackEnded = { [weak controller] in
                Task { @MainActor in await controller?.handlePlaybackEnded() }
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
    }

    #if DEBUG
        #Preview("Music Playback Host") {
            PreviewShell(signedIn: true) {
                MusicPlaybackHost(
                    client: PrismediaPreviewData.model(signedIn: true).client!
                ) {
                    TabView {
                        Tab("Albums", systemImage: "square.stack") {
                            NavigationStack {
                                Text("Music Library")
                                    .navigationTitle("Albums")
                            }
                        }
                    }
                }
            }
        }
    #endif
#endif
