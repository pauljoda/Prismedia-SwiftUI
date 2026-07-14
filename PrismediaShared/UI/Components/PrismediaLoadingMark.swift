import Foundation
import SwiftUI

public struct PrismediaLoadingMark: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var startDate = Date()

    private static let frameInterval: TimeInterval = 1 / 60

    private let fixedFrame: PrismediaLoadingAnimationFrame?

    public init() {
        fixedFrame = nil
    }

    init(previewProgress: Double) {
        fixedFrame = PrismediaLoadingAnimationFrame(progress: previewProgress)
    }

    init(previewFrame: PrismediaLoadingAnimationFrame) {
        fixedFrame = previewFrame
    }

    public var body: some View {
        content
            .frame(maxWidth: .infinity)
            .frame(height: PrismediaLayout.loadingAnimationHeight)
            .accessibilityHidden(true)
    }

    @ViewBuilder
    private var content: some View {
        if let fixedFrame {
            canvas(for: fixedFrame)
        } else {
            TimelineView(
                .animation(
                    minimumInterval: Self.frameInterval,
                    paused: reduceMotion
                )
            ) { context in
                canvas(
                    for: reduceMotion
                        ? .reducedMotion
                        : PrismediaLoadingAnimationFrame(
                            elapsedTime: context.date.timeIntervalSince(startDate)
                        )
                )
            }
        }
    }

    private func canvas(for frame: PrismediaLoadingAnimationFrame) -> some View {
        Canvas(
            opaque: false,
            colorMode: .extendedLinear,
            rendersAsynchronously: true
        ) { context, size in
            PrismediaLoadingRenderer.draw(
                frame: frame,
                context: &context,
                size: size
            )
        }
    }
}

#if DEBUG
    #Preview("Loading Mark · Incoming") {
        ZStack {
            PrismediaBackdrop()
            PrismediaLoadingMark(previewProgress: 0.3)
        }
        .frame(
            width: PrismediaLayout.readableContentWidth / 2,
            height: PrismediaLayout.loadingAnimationHeight
        )
        .preferredColorScheme(.dark)
    }

    #Preview("Loading Mark · Impact") {
        ZStack {
            PrismediaBackdrop()
            PrismediaLoadingMark(previewProgress: 0.44)
        }
        .frame(
            width: PrismediaLayout.readableContentWidth,
            height: PrismediaLayout.loadingAnimationHeight
        )
        .preferredColorScheme(.dark)
    }

    #Preview("Loading Mark · Reduce Motion") {
        ZStack {
            PrismediaBackdrop()
            PrismediaLoadingMark(previewFrame: .reducedMotion)
        }
        .frame(
            width: PrismediaLayout.readableContentWidth / 2,
            height: PrismediaLayout.loadingAnimationHeight
        )
        .preferredColorScheme(.dark)
    }
#endif
