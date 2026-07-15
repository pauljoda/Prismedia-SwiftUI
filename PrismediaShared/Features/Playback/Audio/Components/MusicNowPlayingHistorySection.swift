#if os(iOS)
    import SwiftUI

    struct MusicNowPlayingHistorySection: View {
        let history: [MusicQueueHistoryEntry]

        var body: some View {
            LazyVStack(alignment: .leading, spacing: PrismediaSpacing.medium) {
                ForEach(history) { entry in
                    MusicNowPlayingQueueTrackRow(track: entry.track)
                }
            }
            .accessibilityIdentifier("music.queue.history")
        }
    }

    #if DEBUG
        #Preview("Queue History") {
            MusicNowPlayingHistorySection(
                history: [
                    MusicQueueHistoryEntry(sequence: 0, track: MusicPreviewData.tracks[0]),
                    MusicQueueHistoryEntry(sequence: 1, track: MusicPreviewData.tracks[1]),
                ]
            )
            .environment(PrismediaPreviewData.model(signedIn: true))
            .padding()
            .background(PrismediaBackdrop())
        }
    #endif
#endif
