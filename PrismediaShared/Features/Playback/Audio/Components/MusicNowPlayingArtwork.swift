#if os(iOS)
    import SwiftUI

    struct MusicNowPlayingArtwork: View {
        let track: MusicTrack

        var body: some View {
            RemotePosterImage(
                path: track.artworkPath,
                fallbackSeed: track.album ?? track.title,
                systemImage: "music.note"
            )
            .aspectRatio(1, contentMode: .fill)
            .clipShape(.rect(cornerRadius: PrismediaRadius.control, style: .continuous))
        }
    }

    #if DEBUG
        #Preview("Now Playing Artwork") {
            MusicNowPlayingArtwork(track: MusicPreviewData.tracks[0])
                .frame(width: 280, height: 280)
                .environment(PrismediaPreviewData.model(signedIn: true))
                .padding()
                .background(PrismediaBackdrop())
        }
    #endif
#endif
