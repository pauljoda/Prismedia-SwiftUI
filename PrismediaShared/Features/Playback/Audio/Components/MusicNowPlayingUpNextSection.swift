#if os(iOS) || os(macOS)
    import SwiftUI

    struct MusicNowPlayingUpNextSection: View {
        let entries: [MusicQueueEntry]
        let contextTitle: String?
        let onSelect: (MusicQueueEntry) -> Void

        var body: some View {
            LazyVStack(alignment: .leading, spacing: PrismediaSpacing.medium) {
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

                if entries.isEmpty {
                    Text("No more tracks in the queue")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, minHeight: 72, alignment: .leading)
                } else {
                    ForEach(entries) { entry in
                        Button {
                            onSelect(entry)
                        } label: {
                            MusicNowPlayingQueueTrackRow(track: entry.track, title: entry.title)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .frame(maxWidth: .infinity)
                        .accessibilityIdentifier(entryAccessibilityIdentifier(entry))
                    }
                }
            }
        }

        private func entryAccessibilityIdentifier(_ entry: MusicQueueEntry) -> String {
            guard let chapter = entry.chapter else { return "music.queue.track.\(entry.track.id.uuidString)" }
            return "music.queue.chapter.\(chapter.markerID.uuidString)"
        }
    }

    #if DEBUG
        #Preview("Up Next") {
            MusicNowPlayingUpNextSection(
                entries: MusicPreviewData.tracks.map { MusicQueueEntry(track: $0, chapter: nil) },
                contextTitle: "1",
                onSelect: { _ in }
            )
            .environment(PrismediaPreviewData.model(signedIn: true))
            .padding()
            .background(PrismediaBackdrop())
        }
    #endif
#endif
