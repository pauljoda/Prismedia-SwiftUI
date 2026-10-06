#if os(iOS) || os(macOS)
    import SwiftUI

    struct MusicNowPlayingQueueTrackRow: View {
        let track: MusicTrack
        /// Title shown for the row: a chapter's, else the file's.
        var title: String?

        var body: some View {
            HStack(spacing: PrismediaSpacing.medium) {
                MusicNowPlayingArtwork(
                    track: track,
                    cornerRadius: PrismediaRadius.badge
                )
                .frame(width: 44, height: 44)

                VStack(alignment: .leading, spacing: PrismediaSpacing.extraExtraSmall) {
                    Text(title ?? track.title)
                        .font(.body)
                        .lineLimit(1)
                    Text(MusicPresentation.artist(track.artist))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
            .accessibilityElement(children: .combine)
        }
    }

    #if DEBUG
        #Preview("Queue Track Row") {
            MusicNowPlayingQueueTrackRow(track: MusicPreviewData.tracks[0])
                .environment(PrismediaPreviewData.model(signedIn: true))
                .padding()
                .background(PrismediaBackdrop())
        }
    #endif
#endif
