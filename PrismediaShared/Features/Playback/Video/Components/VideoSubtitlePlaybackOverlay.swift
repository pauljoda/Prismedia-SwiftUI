import AVFoundation
import SwiftUI

struct VideoSubtitlePlaybackOverlay: View {
    let assContents: String?
    let content: VideoSubtitleText?
    let appearance: VideoSubtitleAppearance
    let player: AVPlayer

    var body: some View {
        Group {
            if let assContents {
                VideoAssSubtitleOverlay(
                    contents: assContents,
                    player: player
                )
            } else if let content {
                VideoSubtitleOverlay(
                    content: content,
                    appearance: appearance
                )
            }
        }
        .allowsHitTesting(false)
    }
}

#if DEBUG
    #Preview("Video Subtitle Playback Overlay") {
        VideoSubtitlePlaybackOverlay(
            assContents: nil,
            content: VideoSubtitleText("This is how your subtitles will look."),
            appearance: .default,
            player: AVPlayer()
        )
        .aspectRatio(16 / 9, contentMode: .fit)
        .background(Color.black)
    }
#endif
