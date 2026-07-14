#if os(iOS)
    import SwiftUI

    struct MusicNowPlayingHistorySection: View {
        let history: [MusicQueueHistoryEntry]
        let onClear: () -> Void
        let onShowCurrent: () -> Void

        var body: some View {
            VStack(alignment: .leading, spacing: PrismediaSpacing.medium) {
                HStack {
                    Text("History")
                        .font(.title3.bold())
                    Spacer()
                    Button("Clear", action: onClear)
                        .foregroundStyle(.secondary)
                }
                .contentShape(Rectangle())
                .simultaneousGesture(currentRevealGesture)
                .accessibilityAction(named: "Show Currently Playing", onShowCurrent)

                ForEach(history) { entry in
                    MusicNowPlayingQueueTrackRow(track: entry.track)
                }
            }
            .accessibilityIdentifier("music.queue.history")
        }

        private var currentRevealGesture: some Gesture {
            DragGesture(minimumDistance: 24)
                .onEnded { value in
                    let projectedDistance = min(
                        value.translation.height,
                        value.predictedEndTranslation.height
                    )
                    guard projectedDistance < -72 else { return }
                    onShowCurrent()
                }
        }
    }

    #if DEBUG
        #Preview("Queue History") {
            MusicNowPlayingHistorySection(
                history: [
                    MusicQueueHistoryEntry(sequence: 0, track: MusicPreviewData.tracks[0]),
                    MusicQueueHistoryEntry(sequence: 1, track: MusicPreviewData.tracks[1]),
                ],
                onClear: {},
                onShowCurrent: {}
            )
            .environment(PrismediaPreviewData.model(signedIn: true))
            .padding()
            .background(PrismediaBackdrop())
        }
    #endif
#endif
