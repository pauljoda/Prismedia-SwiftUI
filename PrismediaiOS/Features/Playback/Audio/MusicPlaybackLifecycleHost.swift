#if os(iOS)
    import SwiftUI

    struct MusicPlaybackLifecycleHost<Content: View>: View {
        @Environment(PrismediaAppEnvironment.self) private var environment
        @State private var remoteCommands: MusicRemoteCommandCoordinator?

        let playback: MusicPlaybackComposition
        private let content: Content

        init(
            playback: MusicPlaybackComposition,
            @ViewBuilder content: () -> Content
        ) {
            self.playback = playback
            self.content = content()
        }

        var body: some View {
            content
                .environment(playback)
                .environment(playback.controller)
                .onAppear(perform: connectPlaybackSystem)
                .onChange(of: environment.session) {
                    connectPlaybackService()
                }
                .onChange(of: environment.isRestoringSession) {
                    connectPlaybackService()
                }
        }

        private func connectPlaybackSystem() {
            connectPlaybackService()
            guard remoteCommands == nil else { return }
            remoteCommands = MusicRemoteCommandCoordinator(
                controller: playback.controller,
                engine: playback.engine,
                artworkURL: playback.artworkURL(for:)
            )
            playback.engine.onPlaybackEnded = { [weak controller = playback.controller] in
                Task { @MainActor in await controller?.handlePlaybackEnded() }
            }
        }

        private func connectPlaybackService() {
            guard let client = environment.client else {
                guard !environment.isRestoringSession else { return }
                playback.clearSession()
                return
            }
            playback.connect(to: client)
        }
    }

    #if DEBUG
        #Preview("Music Playback Lifecycle") {
            @Previewable @State var playback = MusicPlaybackComposition()
            PreviewShell(signedIn: true) {
                MusicPlaybackLifecycleHost(playback: playback) {
                    ContentUnavailableView(
                        "Playback Ready",
                        systemImage: "music.note",
                        description: Text("Remote playback remains available outside the music shell.")
                    )
                }
            }
        }
    #endif
#endif
