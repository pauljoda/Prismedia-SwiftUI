import AVFoundation
import SwiftUI

struct VideoSubtitlePlaybackOverlay: View {
    let assContents: String?
    let content: VideoSubtitleText?
    let appearance: VideoSubtitleAppearance
    let player: AVPlayer
    var additionalBottomInset: CGFloat = 0

    var body: some View {
        Group {
            if let assContents {
                VideoAssSubtitleOverlay(
                    contents: assContents,
                    player: player,
                    additionalBottomInset: additionalBottomInset
                )
            } else if let content {
                VideoSubtitleOverlay(
                    content: content,
                    appearance: appearance,
                    additionalBottomInset: additionalBottomInset
                )
            }
        }
        #if os(tvOS)
            // AVPlayerViewController expands its bottom safe area while the
            // transport bar is visible. Subtitle percentages belong to the
            // video canvas, not that temporarily unobscured control region.
            .ignoresSafeArea()
        #endif
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
