#if os(iOS) || os(macOS)
    import SwiftUI

    struct MusicNowPlayingArtwork: View {
        let track: MusicTrack
        let cornerRadius: CGFloat
        let aspectRatio: Double
        let fallbackSeed: String
        let systemImage: String

        init(
            track: MusicTrack,
            cornerRadius: CGFloat = PrismediaRadius.control,
            aspectRatio: Double = 1,
            fallbackSeed: String? = nil,
            systemImage: String = "music.note"
        ) {
            self.track = track
            self.cornerRadius = cornerRadius
            self.aspectRatio = aspectRatio
            self.fallbackSeed = fallbackSeed ?? track.album ?? track.title
            self.systemImage = systemImage
        }

        var body: some View {
            RemotePosterImage(
                path: track.artworkPath,
                fallbackSeed: fallbackSeed,
                systemImage: systemImage,
                contentMode: .fit,
                imageCornerRadius: cornerRadius
            )
            .aspectRatio(aspectRatio, contentMode: .fit)
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
