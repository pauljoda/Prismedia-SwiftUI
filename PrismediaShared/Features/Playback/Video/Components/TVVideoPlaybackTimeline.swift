#if os(tvOS)
    import SwiftUI

    struct TVVideoPlaybackTimeline: View {
        @Environment(\.artworkPrimaryAccent) private var artworkPrimaryAccent

        let currentTime: Double
        let duration: Double
        let originTime: Double?
        let isSeeking: Bool
        let previewURL: URL

        private let previewSize = CGSize(width: 360, height: 203)

        var body: some View {
            GeometryReader { geometry in
                let width = geometry.size.width
                let progress = playbackProgress(for: currentTime)

                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(.white.opacity(0.2))
                        .frame(height: isSeeking ? 10 : 6)

                    Capsule()
                        .fill(artworkPrimaryAccent)
                        .frame(width: progress * width, height: isSeeking ? 10 : 6)

                    if let originTime, isSeeking {
                        Capsule()
                            .fill(.white.opacity(0.55))
                            .frame(width: 4, height: 24)
                            .offset(x: markerOffset(for: originTime, width: width))
                    }

                    Circle()
                        .fill(.white)
                        .frame(width: isSeeking ? 22 : 14, height: isSeeking ? 22 : 14)
                        .shadow(color: .black.opacity(0.45), radius: 5, y: 2)
                        .offset(x: markerOffset(for: currentTime, width: width))

                    if isSeeking, duration > 0 {
                        thumbnailPreview
                            .offset(
                                x: thumbnailOffset(progress: progress, width: width),
                                y: -(previewSize.height + 26)
                            )
                    }
                }
                .frame(maxHeight: .infinity)
                .animation(.easeOut(duration: 0.12), value: isSeeking)
            }
            .frame(height: 34)
            .accessibilityElement()
            .accessibilityLabel("Playback position")
            .accessibilityValue(
                VideoPlaybackTimelineAccessibility.value(
                    currentTime: currentTime,
                    duration: duration
                )
            )
        }

        private var thumbnailPreview: some View {
            ZStack(alignment: .bottom) {
                TVVLCThumbnailView(
                    url: previewURL,
                    position: duration > 0 ? currentTime / duration : 0
                )
                .frame(width: previewSize.width, height: previewSize.height)

                Text(VideoPlaybackPresentation.clockTime(currentTime))
                    .font(.caption.monospacedDigit().weight(.bold))
                    .foregroundStyle(PrismediaColor.onMedia)
                    .padding(.horizontal, PrismediaSpacing.small)
                    .padding(.vertical, PrismediaSpacing.extraSmall)
                    .glassEffect(.regular, in: .capsule)
                    .padding(PrismediaSpacing.small)
            }
            .clipShape(.rect(cornerRadius: 16))
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(.white.opacity(0.35), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.65), radius: 14, y: 7)
        }

        private func playbackProgress(for time: Double) -> CGFloat {
            guard duration > 0 else { return 0 }
            return CGFloat(max(0, min(1, time / duration)))
        }

        private func markerOffset(for time: Double, width: CGFloat) -> CGFloat {
            let markerWidth: CGFloat = isSeeking ? 22 : 14
            return max(0, min(width - markerWidth, playbackProgress(for: time) * width - markerWidth / 2))
        }

        private func thumbnailOffset(progress: CGFloat, width: CGFloat) -> CGFloat {
            max(0, min(width - previewSize.width, progress * width - previewSize.width / 2))
        }
    }

    #if DEBUG
        #Preview("TV Video Playback Timeline") {
            TVVideoPlaybackTimeline(
                currentTime: 42,
                duration: 100,
                originTime: 30,
                isSeeking: true,
                previewURL: URL(string: "https://example.com/video.mkv")!
            )
            .padding(60)
            .background(Color.black)
        }
    #endif
#endif
