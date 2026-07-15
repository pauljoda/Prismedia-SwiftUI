#if !os(tvOS)
    import AVFoundation
    import SwiftUI

    struct VideoPlaybackTimeline: View {
        @Environment(\.artworkPrimaryAccent) private var artworkPrimaryAccent
        let controller: VideoPlaybackController
        @State private var previewTime: Double?

        var body: some View {
            GeometryReader { geometry in
                let width = geometry.size.width
                let duration = max(controller.duration, 0)
                let played = duration > 0 ? CGFloat((previewTime ?? controller.currentTime) / duration) : 0

                ZStack(alignment: .leading) {
                    Capsule().fill(.white.opacity(0.18)).frame(height: 4)
                    ForEach(Array(controller.bufferedRanges.enumerated()), id: \.offset) { _, range in
                        let start = duration > 0 ? CGFloat(range.start.seconds / duration) : 0
                        let end = duration > 0 ? CGFloat(CMTimeRangeGetEnd(range).seconds / duration) : 0
                        Capsule()
                            .fill(.white.opacity(0.34))
                            .frame(width: max(0, min(1, end) - max(0, start)) * width, height: 4)
                            .offset(x: max(0, start) * width)
                    }
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [artworkPrimaryAccent.opacity(0.72), artworkPrimaryAccent],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(0, min(1, played)) * width, height: 4)
                        .shadow(color: artworkPrimaryAccent.opacity(0.45), radius: 3)
                    Circle()
                        .fill(artworkPrimaryAccent)
                        .frame(width: 10, height: 10)
                        .offset(x: max(0, min(width - 10, played * width - 5)))
                }
                .frame(maxHeight: .infinity)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            previewTime = duration * max(0, min(1, value.location.x / width))
                        }
                        .onEnded { _ in
                            if let previewTime { controller.seek(to: previewTime) }
                            previewTime = nil
                        }
                )
            }
            .frame(height: interactionHeight)
            .accessibilityElement()
            .accessibilityLabel("Playback position")
            .accessibilityValue(
                VideoPlaybackTimelineAccessibility.value(
                    currentTime: previewTime ?? controller.currentTime,
                    duration: controller.duration
                )
            )
            .accessibilityAdjustableAction { direction in
                switch direction {
                case .increment:
                    seekAccessibilityTimeline(incrementing: true)
                case .decrement:
                    seekAccessibilityTimeline(incrementing: false)
                @unknown default:
                    break
                }
            }
        }

        private func seekAccessibilityTimeline(incrementing: Bool) {
            controller.seek(
                to: VideoPlaybackTimelineAccessibility.adjustedTime(
                    from: controller.currentTime,
                    duration: controller.duration,
                    incrementing: incrementing
                )
            )
        }

        private var interactionHeight: CGFloat {
            #if os(iOS)
                44
            #else
                28
            #endif
        }
    }

    #if DEBUG
        #Preview("Video Playback Timeline") {
            let controller = VideoPlaybackController(
                videoID: UUID(uuidString: "A57450E8-AC6C-4930-9C1E-B3995675D702")!,
                service: VideoPlaybackPreviewService()
            )
            VideoPlaybackTimeline(controller: controller)
                .padding()
                .background(Color.black)
        }
    #endif
#endif
