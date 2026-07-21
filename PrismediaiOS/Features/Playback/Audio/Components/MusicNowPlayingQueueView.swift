#if os(iOS)
    import SwiftUI

    struct MusicNowPlayingQueueView: View {
        @Environment(MusicPlayerController.self) private var controller
        @State private var historyPullIsArmed = false
        @State private var currentQueuePullIsArmed = false

        let currentTrack: MusicTrack
        let artworkNamespace: Namespace.ID
        let isActive: Bool
        @Binding var showsHistory: Bool
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
                    hasHistory: !controller.queue.history.isEmpty,
                    onShowPlayer: onShowPlayer,
                    onShowHistory: showHistory,
                    onAddToCollection: onAddToCollection
                )
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
                .scrollBounceBehavior(.always, axes: .vertical)
                .onScrollGeometryChange(for: Bool.self) { geometry in
                    geometry.contentOffset.y < -geometry.contentInsets.top - 52
                } action: { _, isPastThreshold in
                    if isPastThreshold { historyPullIsArmed = true }
                }
                .onScrollPhaseChange { oldPhase, newPhase in
                    guard oldPhase == .interacting || oldPhase == .tracking else { return }
                    guard newPhase != .interacting, newPhase != .tracking else { return }
                    guard historyPullIsArmed else { return }
                    historyPullIsArmed = false
                    showHistory()
                }
                .layoutPriority(1)
            }
            .padding(.horizontal, PrismediaSpacing.section)
            .padding(.bottom, PrismediaSpacing.large)
        }

        private var historyPage: some View {
            VStack(alignment: .leading, spacing: PrismediaSpacing.medium) {
                historyHeader

                ScrollView {
                    MusicNowPlayingHistorySection(history: controller.queue.history)
                        .padding(.horizontal, PrismediaSpacing.section)
                        .padding(.bottom, PrismediaSpacing.large)
                }
                .scrollEdgeEffectStyle(.soft, for: .top)
                .scrollBounceBehavior(.always, axes: .vertical)
                .onScrollGeometryChange(for: Bool.self) { geometry in
                    let topOffset = -geometry.contentInsets.top
                    let bottomOffset = max(
                        topOffset,
                        geometry.contentSize.height - geometry.containerSize.height
                            + geometry.contentInsets.bottom
                    )
                    return geometry.contentOffset.y > bottomOffset + 52
                } action: { _, isPastThreshold in
                    if isPastThreshold { currentQueuePullIsArmed = true }
                }
                .onScrollPhaseChange { oldPhase, newPhase in
                    guard oldPhase == .interacting || oldPhase == .tracking else { return }
                    guard newPhase != .interacting, newPhase != .tracking else { return }
                    guard currentQueuePullIsArmed else { return }
                    currentQueuePullIsArmed = false
                    showCurrent()
                }
                .layoutPriority(1)
            }
            .padding(.bottom, PrismediaSpacing.large)
            .accessibilityIdentifier("music.queue.history-page")
        }

        private var historyHeader: some View {
            HStack {
                Text("History")
                    .font(.title3.bold())

                Spacer()

                Button("Now Playing", action: showCurrent)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("music.queue.show-current")

                Button("Clear", action: clearHistory)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("music.queue.clear-history")
            }
            .padding(.horizontal, PrismediaSpacing.section)
        }

        private func resetPullState() {
            historyPullIsArmed = false
            currentQueuePullIsArmed = false
        }

        private func showHistory() {
            guard !controller.queue.history.isEmpty else { return }
            resetPullState()
            withAnimation(.snappy(duration: 0.36, extraBounce: 0.02)) {
                showsHistory = true
            }
        }

        private func showCurrent() {
            resetPullState()
            withAnimation(.snappy(duration: 0.36, extraBounce: 0.02)) {
                showsHistory = false
            }
        }

        private func clearHistory() {
            showCurrent()
            controller.clearHistory()
        }
    }

    #if DEBUG
        #Preview("Now Playing Queue") {
            @Previewable @Namespace var artworkNamespace
            @Previewable @State var controller = MusicPreviewData.controller()
            @Previewable @State var showsHistory = false
            MusicNowPlayingQueueView(
                currentTrack: MusicPreviewData.tracks[0],
                artworkNamespace: artworkNamespace,
                isActive: true,
                showsHistory: $showsHistory,
                onShowPlayer: {},
                onAddToCollection: {}
            )
            .environment(controller)
            .environment(PrismediaPreviewData.model(signedIn: true))
            .background(PrismediaBackdrop())
        }
    #endif
#endif
