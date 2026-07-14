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
                .sheet(isPresented: $nowPlayingPresented) {
                    MusicNowPlayingView(
                        engine: engine,
                        artworkPalette: artworkPaletteBinding
                    )
                    .environment(controller)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
                    .presentationContentInteraction(.scrolls)
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
