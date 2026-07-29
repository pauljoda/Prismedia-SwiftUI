#if os(macOS)
    import SwiftUI

    struct MacMusicPlaybackHost<Content: View>: View {
        @Environment(\.scenePhase) private var scenePhase
        @State private var playback = MusicPlaybackComposition()
        @State private var miniPlayerVisibility = MusicMiniPlayerVisibility()
        @State private var nowPlayingPresented = false
        @State private var waveform: MusicWaveform?
        @State private var remoteCommands: MusicRemoteCommandCoordinator?

        private let client: PrismediaAPIClient
        private let waveformLoader: any MusicWaveformLoading
        private let content: Content

        @MainActor
        init(
            client: PrismediaAPIClient,
            waveformLoader: (any MusicWaveformLoading)? = nil,
            @ViewBuilder content: () -> Content
        ) {
            self.client = client
            self.waveformLoader = waveformLoader ?? PrismediaMusicWaveformLoader(client: client)
            self.content = content()
        }

        var body: some View {
            let presentation = MacMusicPlaybackPresentationContext(
                controller: controller,
                engine: engine,
                waveform: waveform,
                isInspectorPresented: $nowPlayingPresented
            )

            content
                .environment(controller)
                .environment(\.musicMiniPlayerVisibility, miniPlayerVisibility)
                .environment(\.macMusicPlaybackPresentation, presentation)
                .focusedSceneValue(controller)
                .onAppear(perform: connectPlaybackSystem)
                .task(id: controller.currentTrack?.id) {
                    await loadWaveform()
                }
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active {
                        controller.resumeAudiobookActivity()
                    } else {
                        Task { await controller.flushAudiobookProgress() }
                    }
                }
                .onChange(of: controller.currentQueueID) {
                    miniPlayerVisibility.revealForPlaybackActivity()
                }
                .onChange(of: controller.currentTrack?.id) { _, trackID in
                    guard trackID == nil else { return }
                    nowPlayingPresented = false
                }
                .onChange(of: controller.isPlaying) { _, isPlaying in
                    guard isPlaying else { return }
                    miniPlayerVisibility.revealForPlaybackActivity()
                }
        }

        private func connectPlaybackSystem() {
            playback.connect(to: client)
            if remoteCommands == nil {
                remoteCommands = MusicRemoteCommandCoordinator(
                    controller: controller,
                    engine: engine,
                    artworkURL: playback.artworkURL(for:)
                )
            }
            #if DEBUG
                let tracks = PrismediaUITestBootstrap.musicTracks()
                if !tracks.isEmpty {
                    controller.play(tracks: tracks, queueMode: .ordered)
                }
            #endif
            engine.onPlaybackEnded = { [weak controller] in
                Task { @MainActor in await controller?.handlePlaybackEnded() }
            }
        }

        private var engine: AVPlayerAudioPlaybackEngine { playback.engine }
        private var controller: MusicPlayerController { playback.controller }

        private func loadWaveform() async {
            waveform = nil
            guard let trackID = controller.currentTrack?.id else { return }
            do {
                let resolved = try await waveformLoader.loadWaveform(for: trackID)
                guard !Task.isCancelled, controller.currentTrack?.id == trackID else { return }
                waveform = resolved
            } catch is CancellationError {
                return
            } catch {
                waveform = nil
            }
        }
    }

    #if DEBUG
        #Preview("Mac Music Playback Host") {
            PreviewShell(signedIn: true) {
                MacMusicPlaybackHost(
                    client: PrismediaPreviewData.model(signedIn: true).client!,
                    waveformLoader: MusicWaveformPreviewLoader()
                ) {
                    MacMusicPlaybackPresentationHost {
                        NavigationStack {
                            Text("Music Library")
                                .navigationTitle("Albums")
                        }
                    }
                }
            }
            .frame(width: 900, height: 680)
        }
    #endif
#endif
