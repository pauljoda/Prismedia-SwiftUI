#if os(iOS) || os(macOS)
    import SwiftUI

    struct MusicTrackRowView: View {
        @Environment(\.artworkPrimaryAccent) private var artworkPrimaryAccent
        @Environment(\.artworkSecondaryText) private var artworkSecondaryText
        let track: MusicTrack
        let fallbackNumber: Int
        let onPlay: () -> Void
        let onAddToCollection: (() -> Void)?

        var body: some View {
            Button(action: onPlay) {
                HStack(spacing: PrismediaSpacing.medium) {
                    Text(String(track.trackNumber ?? fallbackNumber))
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(artworkSecondaryText)
                        .frame(width: 24, alignment: .trailing)

                    VStack(alignment: .leading, spacing: PrismediaSpacing.extraSmall) {
                        Text(track.title)
                            .font(.body)
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                        trackMetadata
                    }

                    Spacer()

                    if let duration = track.duration {
                        Text(MusicPresentation.clockTime(duration))
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(artworkSecondaryText)
                    }
                }
                .padding(.vertical, PrismediaSpacing.extraSmall)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityHint("Plays this song")
            .accessibilityIdentifier("music.track.row.\(track.id.uuidString)")
            #if os(iOS)
                .swipeActions(edge: .trailing) {
                    if let onAddToCollection {
                        Button(action: onAddToCollection) {
                            Label("Add to Collection", systemImage: "folder.badge.plus")
                        }
                        .tint(artworkPrimaryAccent)
                    }
                }
            #endif
        }

        @ViewBuilder
        private var trackMetadata: some View {
            let value = [track.artist, track.album]
                .compactMap { $0 }
                .joined(separator: " — ")
            if !value.isEmpty {
                Text(value)
                    .font(.caption)
                    .foregroundStyle(artworkSecondaryText)
                    .lineLimit(1)
            }
        }
    }

    #if DEBUG
        #Preview("Music Track Row") {
            List {
                MusicTrackRowView(
                    track: MusicTrack(thumbnail: MusicCollectionPreviewLoader.track),
                    fallbackNumber: 1,
                    onPlay: {},
                    onAddToCollection: nil
                )
            }
        }
    #endif
#endif
