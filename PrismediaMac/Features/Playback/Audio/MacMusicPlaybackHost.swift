#if os(macOS)
    import SwiftUI

    struct MacMusicPlaybackHost<Content: View>: View {
        @Environment(\.scenePhase) private var scenePhase
        @State private var playback = MusicPlaybackComposition()
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
            content
                .environment(controller)
                .environment(\.musicMiniPlayerVisibility, miniPlayerVisibility)
                .focusedSceneValue(controller)
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    if showsMiniPlayer {
                        MacMusicMiniPlayerView(
                            engine: engine,
                            showNowPlaying: { nowPlayingPresented.toggle() }
                        )
                        .environment(controller)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .inspector(isPresented: $nowPlayingPresented) {
                    MacMusicNowPlayingView(
                        engine: engine,
                        onClose: { nowPlayingPresented = false }
                    )
                        .environment(controller)
                        .inspectorColumnWidth(min: 300, ideal: 360, max: 480)
                }
                .animation(.snappy, value: showsMiniPlayer)
                .onAppear(perform: connectPlaybackSystem)
                .onChange(of: scenePhase) { _, phase in
                    guard phase != .active else { return }
                    Task { await controller.flushAudiobookProgress() }
                }
                .onChange(of: controller.currentQueueID) {
                    miniPlayerVisibility.revealForPlaybackActivity()
                }
                .onChange(of: controller.isPlaying) { _, isPlaying in
                    guard isPlaying else { return }
                    miniPlayerVisibility.revealForPlaybackActivity()
                }
        }

        private func connectPlaybackSystem() {
            playback.connect(to: client)
            engine.onPlaybackEnded = { [weak controller] in
                Task { @MainActor in await controller?.handlePlaybackEnded() }
            }
            engine.onNowPlayingProgressChanged = { [weak controller, weak engine] in
                guard let engine else { return }
                controller?.updateElapsedTime(engine.elapsedTime)
            }
        }

        private var engine: AVPlayerAudioPlaybackEngine { playback.engine }
        private var controller: MusicPlayerController { playback.controller }
        private var showsMiniPlayer: Bool {
            controller.currentTrack != nil && !miniPlayerVisibility.isSuppressed
        }
    }

    #if DEBUG
        #Preview("Mac Music Playback Host") {
            PreviewShell(signedIn: true) {
                MacMusicPlaybackHost(
                    client: PrismediaPreviewData.model(signedIn: true).client!
                ) {
                    NavigationStack {
                        Text("Music Library")
                            .navigationTitle("Albums")
                    }
                }
            }
            .frame(width: 900, height: 680)
        }
    #endif
#endif
