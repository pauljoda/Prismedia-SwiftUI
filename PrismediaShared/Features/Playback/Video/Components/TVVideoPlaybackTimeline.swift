#if os(tvOS)
    import SwiftUI

    struct TVVideoPlaybackTimeline: View {
        @Environment(\.artworkPrimaryAccent) private var artworkPrimaryAccent
        let controller: VideoPlaybackController

        var body: some View {
            GeometryReader { geometry in
                let width = geometry.size.width
                let progress = playbackProgress

                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(.white.opacity(0.2))
                        .frame(height: 6)

                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    artworkPrimaryAccent.opacity(0.72),
                                    artworkPrimaryAccent,
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: progress * width, height: 6)
                        .shadow(color: artworkPrimaryAccent.opacity(0.48), radius: 4)

                    Circle()
                        .fill(artworkPrimaryAccent)
                        .frame(width: 14, height: 14)
                        .offset(x: max(0, min(width - 14, progress * width - 7)))
                }
                .frame(maxHeight: .infinity)
            }
            .frame(height: 28)
            .accessibilityElement()
            .accessibilityLabel("Playback position")
            .accessibilityValue(
                VideoPlaybackTimelineAccessibility.value(
                    currentTime: controller.currentTime,
                    duration: controller.duration
                )
            )
            .accessibilityAdjustableAction { direction in
                switch direction {
                case .increment:
                    controller.skip(by: 10)
                case .decrement:
                    controller.skip(by: -10)
                @unknown default:
                    break
                }
            }
        }

        private var playbackProgress: CGFloat {
            guard controller.duration > 0 else { return 0 }
            return CGFloat(max(0, min(1, controller.currentTime / controller.duration)))
        }
    }

    #if DEBUG
        #Preview("TV Video Playback Timeline") {
            TVVideoPlaybackTimeline(
                controller: VideoPlaybackController(
                    videoID: UUID(uuidString: "A57450E8-AC6C-4930-9C1E-B3995675D702")!,
                    service: VideoPlaybackPreviewService()
                )
            )
            .padding(60)
            .background(Color.black)
        }
    #endif
#endif
