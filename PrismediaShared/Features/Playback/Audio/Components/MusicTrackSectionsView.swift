#if os(iOS) || os(macOS)
    import SwiftUI

    struct MusicTrackSectionsView: View {
        @Environment(\.artworkSecondaryText) private var artworkSecondaryText
        let sections: [MusicTrackSection]
        let onPlay: (MusicTrack) -> Void
        let onAddToCollection: ((MusicTrack) -> Void)?

        var body: some View {
            ForEach(sections) { section in
                Section {
                    ForEach(Array(section.tracks.enumerated()), id: \.element.id) { index, track in
                        MusicTrackRowView(
                            track: track,
                            fallbackNumber: index + 1,
                            onPlay: { onPlay(track) },
                            onAddToCollection: onAddToCollection.map { action in
                                { action(track) }
                            }
                        )
                        .listRowBackground(Color.clear)
                    }
                } header: {
                    if let title = section.title {
                        Text(title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(artworkSecondaryText)
                    }
                }
            }
        }
    }

    #if DEBUG
        #Preview("Music Track Sections") {
            List {
                MusicTrackSectionsView(
                    sections: [
                        MusicTrackSection(
                            title: "Night Drive",
                            tracks: [MusicTrack(thumbnail: MusicCollectionPreviewLoader.track)]
                        )
                    ],
                    onPlay: { _ in },
                    onAddToCollection: nil
                )
            }
        }
    #endif
#endif
