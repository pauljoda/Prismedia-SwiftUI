import Foundation
import SwiftUI

public struct PrismediaLoadingMark: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var startDate = Date()

    private static let frameInterval: TimeInterval = 1 / 60

    private let fixedFrame: PrismediaLoadingAnimationFrame?
    private let launchBrandNamespace: Namespace.ID?

    public init() {
        fixedFrame = nil
        launchBrandNamespace = nil
    }

    init(launchBrandNamespace: Namespace.ID?) {
        fixedFrame = nil
        self.launchBrandNamespace = launchBrandNamespace
    }

    init(previewProgress: Double) {
        fixedFrame = PrismediaLoadingAnimationFrame(progress: previewProgress)
        launchBrandNamespace = nil
    }

    init(previewFrame: PrismediaLoadingAnimationFrame) {
        fixedFrame = previewFrame
        launchBrandNamespace = nil
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
        ZStack {
            Canvas(
                opaque: false,
                colorMode: .extendedLinear,
                rendersAsynchronously: true
            ) { context, size in
                PrismediaLoadingRenderer.draw(
                    frame: frame,
                    context: &context,
                    size: size,
                    drawsPrism: launchBrandNamespace == nil
                )
            }

            if let launchBrandNamespace {
                ZStack {
                    loadingPrismImage(named: "PrismediaPrismNeutral")

                    loadingPrismImage(named: "PrismediaPrismColor")
                        .opacity(frame.prismColorProgress)
                }
                .frame(
                    width: PrismediaLayout.loadingPrismMark,
                    height: PrismediaLayout.loadingPrismMark
                )
                .matchedGeometryEffect(
                    id: "prismedia.launch.brand",
                    in: launchBrandNamespace,
                    isSource: true
                )
                .accessibilityHidden(true)
            }
        }
    }

    private func loadingPrismImage(named name: String) -> some View {
        Image(name, bundle: .prismediaResources)
            .resizable()
            .renderingMode(.original)
            .scaledToFit()
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
