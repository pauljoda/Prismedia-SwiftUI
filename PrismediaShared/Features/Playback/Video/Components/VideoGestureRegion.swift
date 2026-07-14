#if !os(tvOS)
    import AVFoundation
    import SwiftUI

    struct VideoGestureRegion: View {
        let controller: VideoPlaybackController
        let side: VideoPlayerGestureSide
        let onSingleTap: () -> Void

        @State private var longPressActive = false

        var body: some View {
            ZStack {
                Color.clear.contentShape(Rectangle())
                if controller.shuttleSide == side {
                    Label("2×", systemImage: side == .left ? "backward.fill" : "forward.fill")
                        .font(.headline.bold())
                        .foregroundStyle(PrismediaColor.onMedia)
                        .padding(.horizontal, PrismediaSpacing.large)
                        .frame(height: 38)
                        .glassEffect(.regular.tint(.black.opacity(0.28)), in: .capsule)
                        .allowsHitTesting(false)
                }
            }
            .gesture(
                TapGesture(count: 2)
                    .exclusively(before: TapGesture(count: 1))
                    .onEnded { result in
                        switch result {
                        case .first:
                            controller.skip(by: side == .left ? -10 : 10)
                        case .second:
                            onSingleTap()
                        }
                    }
            )
            .onLongPressGesture(
                minimumDuration: 0.9,
                maximumDistance: 44,
                pressing: { pressing in
                    if !pressing, longPressActive {
                        controller.endShuttle()
                        longPressActive = false
                    }
                },
                perform: {
                    longPressActive = true
                    controller.beginShuttle(on: side)
                }
            )
            .onDisappear {
                if longPressActive { controller.endShuttle() }
            }
            .accessibilityLabel(side == .left ? "Rewind gestures" : "Forward gestures")
        }
    }

    #if DEBUG
        #Preview("Video Gesture Region") {
            let controller = VideoPlaybackController(
                videoID: UUID(uuidString: "A57450E8-AC6C-4930-9C1E-B3995675D702")!,
                service: VideoPlaybackPreviewService()
            )
            VideoGestureRegion(controller: controller, side: .right, onSingleTap: {})
                .frame(width: 240, height: 180)
                .background(Color.black)
        }
    #endif
#endif
