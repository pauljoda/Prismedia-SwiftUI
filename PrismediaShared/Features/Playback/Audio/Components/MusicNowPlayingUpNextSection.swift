#if os(iOS)
    import SwiftUI

    struct MusicNowPlayingUpNextSection: View {
        let tracks: [MusicTrack]
        let contextTitle: String?
        let onSelect: (UUID) -> Void

        var body: some View {
            VStack(alignment: .leading, spacing: PrismediaSpacing.medium) {
                VStack(alignment: .leading, spacing: PrismediaSpacing.extraExtraSmall) {
                    Text("Up Next")
                        .font(.title3.bold())
                        .accessibilityIdentifier("music.queue.up-next")
                    if let contextTitle {
                        Text("From \(contextTitle)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                if tracks.isEmpty {
                    Text("No more tracks in the queue")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, minHeight: 72, alignment: .leading)
                } else {
                    ForEach(tracks) { track in
                        Button {
                            onSelect(track.id)
                        } label: {
                            MusicNowPlayingQueueTrackRow(track: track)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .frame(maxWidth: .infinity)
                        .accessibilityIdentifier("music.queue.track.\(track.id.uuidString)")
                    }
                }
            }
        }
    }

    #if DEBUG
        #Preview("Up Next") {
            MusicNowPlayingUpNextSection(
                tracks: MusicPreviewData.tracks,
                contextTitle: "1",
                onSelect: { _ in }
            )
            .environment(PrismediaPreviewData.model(signedIn: true))
            .padding()
            .background(PrismediaBackdrop())
        }
    #endif
#endif
