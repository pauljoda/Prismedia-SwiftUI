#if os(iOS)
    import SwiftUI

    struct MusicNowPlayingQueueView: View {
        @Environment(MusicPlayerController.self) private var controller
        @State private var showsHistory = false

        let currentTrack: MusicTrack
        let artworkNamespace: Namespace.ID
        let isActive: Bool
        let onShowPlayer: () -> Void
        let onAddToCollection: () -> Void

        var body: some View {
            ZStack {
                if showsHistory, !controller.queue.history.isEmpty {
                    historyPage
                        .transition(.move(edge: .top))
                } else {
                    currentQueuePage
                        .transition(.move(edge: .bottom))
                }
            }
            .onChange(of: currentTrack.id) {
                showsHistory = false
            }
            .onChange(of: controller.queue.history.isEmpty) {
                if controller.queue.history.isEmpty { showsHistory = false }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .accessibilityIdentifier("music.queue")
        }

        private var currentQueuePage: some View {
            VStack(alignment: .leading, spacing: PrismediaSpacing.extraExtraLarge) {
                MusicNowPlayingCurrentTrackView(
                    track: currentTrack,
                    artworkNamespace: artworkNamespace,
                    showsContent: isActive,
                    onShowPlayer: onShowPlayer,
                    onAddToCollection: onAddToCollection
                )
                .contentShape(Rectangle())
                .simultaneousGesture(historyRevealGesture)
                .accessibilityAction(named: "Show History", showHistory)

                ScrollView {
                    MusicNowPlayingUpNextSection(
                        tracks: controller.queue.upNextTracks,
                        contextTitle: controller.context?.playbackOwnerTitle ?? currentTrack.album,
                        onSelect: { controller.skipToUpcomingTrack(id: $0) }
                    )
                    .opacity(isActive ? 1 : 0)
                    .padding(.bottom, PrismediaSpacing.large)
                }
                .scrollEdgeEffectStyle(.soft, for: .top)
                .layoutPriority(1)
            }
            .padding(.horizontal, PrismediaSpacing.section)
            .padding(.bottom, PrismediaSpacing.large)
        }

        private var historyPage: some View {
            ScrollView {
                MusicNowPlayingHistorySection(
                    history: controller.queue.history,
                    onClear: controller.clearHistory,
                    onShowCurrent: showCurrent
                )
                .padding(.horizontal, PrismediaSpacing.section)
                .padding(.bottom, PrismediaSpacing.large)
            }
            .scrollEdgeEffectStyle(.soft, for: .top)
            .accessibilityIdentifier("music.queue.history-page")
        }

        private var historyRevealGesture: some Gesture {
            DragGesture(minimumDistance: 24)
                .onEnded { value in
                    guard !controller.queue.history.isEmpty,
                        max(value.translation.height, value.predictedEndTranslation.height) > 72
                    else { return }
                    showHistory()
                }
        }

        private func showHistory() {
            guard !controller.queue.history.isEmpty else { return }
            withAnimation(.snappy(duration: 0.36, extraBounce: 0.02)) {
                showsHistory = true
            }
        }

        private func showCurrent() {
            withAnimation(.snappy(duration: 0.36, extraBounce: 0.02)) {
                showsHistory = false
            }
        }
    }

    #if DEBUG
        #Preview("Now Playing Queue") {
            @Previewable @Namespace var artworkNamespace
            @Previewable @State var controller = MusicPreviewData.controller()
            MusicNowPlayingQueueView(
                currentTrack: MusicPreviewData.tracks[0],
                artworkNamespace: artworkNamespace,
                isActive: true,
                onShowPlayer: {},
                onAddToCollection: {}
            )
            .environment(controller)
            .environment(PrismediaPreviewData.model(signedIn: true))
            .background(PrismediaBackdrop())
        }
    #endif
#endif
