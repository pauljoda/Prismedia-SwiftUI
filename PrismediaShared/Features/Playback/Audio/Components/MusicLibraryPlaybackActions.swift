#if os(iOS) || os(macOS)
    import SwiftUI

    struct MusicLibraryPlaybackActions: View {
        @Environment(PrismediaAppEnvironment.self) private var environment
        @Environment(MusicPlayerController.self) private var controller
        @State private var loadingQueueMode: MusicQueueStartMode?
        @State private var playbackError: String?
        @State private var playbackRequestID: UUID?

        let context: EntityGridTopContentContext

        var body: some View {
            MusicPlaybackButtons(
                loadingMode: loadingQueueMode,
                isDisabled: context.visibleItemCount == 0
            ) { queueMode in
                Task { await playLibrary(queueMode: queueMode) }
            }
            .alert("Couldn’t Start Playback", isPresented: playbackErrorPresented) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(playbackError ?? "Please try again.")
            }
        }

        private func playLibrary(queueMode: MusicQueueStartMode) async {
            guard let client = environment.client else { return }
            guard loadingQueueMode == nil else { return }
            let requestID = UUID()
            let queueIDAtRequestStart = controller.currentQueueID
            playbackRequestID = requestID
            loadingQueueMode = queueMode
            var expandingQueueID: UUID?
            defer {
                if playbackRequestID == requestID {
                    playbackRequestID = nil
                    loadingQueueMode = nil
                }
                if let expandingQueueID {
                    controller.finishQueueExpansion(expandingQueueID)
                }
            }

            do {
                let loader = MusicLibraryQueueLoader(client: client)
                if queueMode == .shuffled {
                    for try await tracks in loader.shuffledTrackBatches(
                        matching: context.query,
                        search: context.search
                    ) {
                        try Task.checkCancellation()
                        if let expandingQueueID {
                            guard controller.appendUpcomingTracks(tracks, to: expandingQueueID)
                            else { return }
                            continue
                        }

                        guard controller.currentQueueID == queueIDAtRequestStart else { return }
                        expandingQueueID = controller.preparePlayback(
                            tracks: tracks,
                            queueMode: .shuffled
                        )
                        controller.resume()
                        if playbackRequestID == requestID {
                            loadingQueueMode = nil
                        }
                    }
                    return
                }

                let tracks = try await loader.tracks(
                    matching: context.query,
                    search: context.search
                )
                guard !tracks.isEmpty else { return }
                controller.play(tracks: tracks, queueMode: queueMode)
            } catch is CancellationError {
                return
            } catch {
                if expandingQueueID == nil, playbackRequestID == requestID {
                    playbackError = error.localizedDescription
                }
            }
        }

        private var playbackErrorPresented: Binding<Bool> {
            Binding(
                get: { playbackError != nil },
                set: { if !$0 { playbackError = nil } }
            )
        }
    }

    #if DEBUG
        #Preview("Music Library Playback Actions") {
            @Previewable @State var controller = MusicPreviewData.controller(playing: false)
            PreviewShell(signedIn: true) {
                MusicLibraryPlaybackActions(
                    context: EntityGridTopContentContext(
                        query: EntityListQuery(
                            kind: .audioLibrary,
                            sort: "added",
                            sortDescending: true
                        ),
                        search: nil,
                        visibleItemCount: 12
                    )
                )
                .padding()
                .background(PrismediaBackdrop())
            }
            .environment(controller)
        }
    #endif
#endif
