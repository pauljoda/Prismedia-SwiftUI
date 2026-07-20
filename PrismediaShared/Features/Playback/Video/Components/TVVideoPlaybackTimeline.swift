#if os(tvOS)
    import SwiftUI

    struct TVVideoPlaybackTimeline: View {
        @Environment(\.artworkPrimaryAccent) private var artworkPrimaryAccent

        let currentTime: Double
        let duration: Double
        let originTime: Double?
        let isFocused: Bool
        let isSeeking: Bool
        let previewURL: URL

        private let previewSize = CGSize(width: 360, height: 203)
        private let playheadSize: CGFloat = 22
        private let originMarkerWidth: CGFloat = 4

        private var trackHeight: CGFloat {
            if isSeeking { return 18 }
            return isFocused ? 14 : 10
        }

        var body: some View {
            GeometryReader { geometry in
                let width = geometry.size.width
                let currentProgress = playbackProgress(for: currentTime)
                let originProgress = originTime.map(playbackProgress(for:))

                ZStack(alignment: .leading) {
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(.white.opacity(isFocused ? 0.32 : 0.24))
                            .frame(width: width, height: trackHeight)

                        if let originProgress, isSeeking {
                            Capsule()
                                .fill(artworkPrimaryAccent.opacity(0.48))
                                .frame(
                                    width: pendingProgress(
                                        current: currentProgress,
                                        origin: originProgress
                                    ) * width,
                                    height: trackHeight
                                )
                        }

                        Capsule()
                            .fill(artworkPrimaryAccent)
                            .frame(
                                width: committedProgress(
                                    current: currentProgress,
                                    origin: originProgress
                                ) * width,
                                height: trackHeight
                            )
                    }
                    .frame(width: width, height: trackHeight, alignment: .leading)
                    .clipShape(.capsule)

                    if let originProgress, isSeeking,
                       abs(originProgress - currentProgress) > 0.001
                    {
                        Capsule()
                            .fill(.white.opacity(0.92))
                            .frame(width: originMarkerWidth, height: 32)
                            .offset(x: markerOffset(
                                progress: originProgress,
                                markerWidth: originMarkerWidth,
                                trackWidth: width
                            ))
                    }

                    Circle()
                        .fill(.white)
                        .frame(width: playheadSize, height: playheadSize)
                        .shadow(color: .black.opacity(0.45), radius: 5, y: 2)
                        .offset(x: markerOffset(
                            progress: currentProgress,
                            markerWidth: playheadSize,
                            trackWidth: width
                        ))
                }
                .frame(width: width, height: geometry.size.height, alignment: .leading)
                .overlay(alignment: .topLeading) {
                    if isSeeking, duration > 0 {
                        thumbnailPreview
                            .offset(
                                x: thumbnailOffset(progress: currentProgress, width: width),
                                y: -(previewSize.height + 18)
                            )
                    }
                }
                .animation(.easeOut(duration: 0.12), value: isSeeking)
            }
            .frame(height: 72)
            .accessibilityHidden(true)
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

        private func committedProgress(current: CGFloat, origin: CGFloat?) -> CGFloat {
            guard let origin, isSeeking else { return current }
            return min(current, origin)
        }

        private func pendingProgress(current: CGFloat, origin: CGFloat) -> CGFloat {
            max(current, origin)
        }

        private func markerOffset(
            progress: CGFloat,
            markerWidth: CGFloat,
            trackWidth: CGFloat
        ) -> CGFloat {
            max(0, min(trackWidth - markerWidth, progress * trackWidth - markerWidth / 2))
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
                isFocused: true,
                isSeeking: true,
                previewURL: URL(string: "https://example.com/video.mkv")!
            )
            .padding(60)
            .background(Color.black)
        }
    #endif
#endif
