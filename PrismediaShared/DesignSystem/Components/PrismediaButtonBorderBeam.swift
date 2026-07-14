import Foundation
import SwiftUI

struct PrismediaButtonBorderBeam: View {
    @Environment(\.accessibilityDifferentiateWithoutColor) private var differentiateWithoutColor
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.isEnabled) private var isEnabled
    @State private var animationProgress = 0.0

    private static let animationDuration: TimeInterval = 600
    private static let staticProgress = 0.12
    private static let baseLineWidth: CGFloat = 0.55
    private static let glowLineWidth: CGFloat = 4
    private static let glowRadius: CGFloat = 5
    private static let crispLineWidth: CGFloat = 0.85
    private static let beamMaskLineWidth: CGFloat = 10

    let shape: ButtonBorderShape
    let showsBorderBeam: Bool
    private let previewProgress: Double?

    init(
        shape: ButtonBorderShape,
        showsBorderBeam: Bool,
        previewProgress: Double? = nil
    ) {
        self.shape = shape
        self.showsBorderBeam = showsBorderBeam
        self.previewProgress = previewProgress
    }

    @ViewBuilder
    var body: some View {
        if showsBorderBeam {
            beam(progress: resolvedProgress)
                .accessibilityHidden(true)
                .allowsHitTesting(false)
                .onChange(of: pausesAnimation, initial: true) { _, pausesAnimation in
                    updateAnimation(paused: pausesAnimation)
                }
        }
    }

    private var pausesAnimation: Bool {
        reduceMotion || !isEnabled
    }

    private var resolvedProgress: Double {
        if let previewProgress {
            previewProgress
        } else if pausesAnimation {
            Self.staticProgress
        } else {
            animationProgress
        }
    }

    private func updateAnimation(paused: Bool) {
        guard previewProgress == nil else { return }

        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            animationProgress = paused ? Self.staticProgress : 0
        }

        guard !paused else { return }

        withAnimation(
            .linear(duration: Self.animationDuration)
                .repeatForever(autoreverses: false)
        ) {
            animationProgress = 1
        }
    }

    private func beam(progress: Double) -> some View {
        let detailAngle = Angle.degrees(-20 + progress * 360)
        let hazeAngle = Angle.degrees(140 + progress * 360)
        let detailGradient = AngularGradient(
            gradient: differentiateWithoutColor ? detailNeutralGradient : detailSpectrumGradient,
            center: .center,
            angle: detailAngle
        )
        let hazeGradient = AngularGradient(
            gradient: differentiateWithoutColor ? hazeNeutralGradient : hazeSpectrumGradient,
            center: .center,
            angle: hazeAngle
        )

        return ZStack {
            shape
                .stroke(PrismediaColor.borderSubtle.opacity(0.32), lineWidth: Self.baseLineWidth)

            shape
                .stroke(hazeGradient, lineWidth: Self.glowLineWidth)
                .blur(radius: Self.glowRadius)
                .opacity(0.15)

            shape
                .stroke(detailGradient, lineWidth: Self.crispLineWidth)
                .opacity(0.36)

            shape
                .stroke(hazeGradient, lineWidth: Self.baseLineWidth)
                .opacity(0.18)
        }
        .mask {
            shape.stroke(lineWidth: Self.beamMaskLineWidth)
        }
        .opacity(isEnabled ? 1 : 0.38)
    }

    private var detailSpectrumGradient: Gradient {
        Gradient(stops: [
            .init(color: PrismediaColor.spectrumCyan, location: 0),
            .init(color: PrismediaColor.spectrumBlue, location: 0.11),
            .init(color: PrismediaColor.spectrumViolet, location: 0.24),
            .init(color: PrismediaColor.spectrumMagenta, location: 0.37),
            .init(color: PrismediaColor.spectrumRed, location: 0.49),
            .init(color: PrismediaColor.spectrumOrange, location: 0.61),
            .init(color: PrismediaColor.spectrumYellow, location: 0.75),
            .init(color: PrismediaColor.spectrumGreen, location: 0.88),
            .init(color: PrismediaColor.spectrumCyan, location: 1),
        ])
    }

    private var hazeSpectrumGradient: Gradient {
        Gradient(stops: [
            .init(color: PrismediaColor.spectrumMagenta, location: 0),
            .init(color: PrismediaColor.spectrumRed, location: 0.14),
            .init(color: PrismediaColor.spectrumOrange, location: 0.29),
            .init(color: PrismediaColor.spectrumYellow, location: 0.41),
            .init(color: PrismediaColor.spectrumGreen, location: 0.54),
            .init(color: PrismediaColor.spectrumCyan, location: 0.68),
            .init(color: PrismediaColor.spectrumBlue, location: 0.82),
            .init(color: PrismediaColor.spectrumViolet, location: 0.92),
            .init(color: PrismediaColor.spectrumMagenta, location: 1),
        ])
    }

    private var detailNeutralGradient: Gradient {
        Gradient(stops: [
            .init(color: PrismediaColor.textPrimary.opacity(0.3), location: 0),
            .init(color: PrismediaColor.textPrimary.opacity(0.58), location: 0.14),
            .init(color: PrismediaColor.textPrimary.opacity(0.34), location: 0.31),
            .init(color: PrismediaColor.textPrimary.opacity(0.64), location: 0.49),
            .init(color: PrismediaColor.textPrimary.opacity(0.38), location: 0.7),
            .init(color: PrismediaColor.textPrimary.opacity(0.52), location: 0.87),
            .init(color: PrismediaColor.textPrimary.opacity(0.3), location: 1),
        ])
    }

    private var hazeNeutralGradient: Gradient {
        Gradient(stops: [
            .init(color: PrismediaColor.textPrimary.opacity(0.42), location: 0),
            .init(color: PrismediaColor.textPrimary.opacity(0.26), location: 0.18),
            .init(color: PrismediaColor.textPrimary.opacity(0.5), location: 0.39),
            .init(color: PrismediaColor.textPrimary.opacity(0.3), location: 0.62),
            .init(color: PrismediaColor.textPrimary.opacity(0.56), location: 0.81),
            .init(color: PrismediaColor.textPrimary.opacity(0.42), location: 1),
        ])
    }
}

#if DEBUG
    #Preview("Button Border Beam") {
        ZStack {
            PrismediaBackdrop()

            Button {
            } label: {
                Label("Continue", systemImage: "arrow.right")
                    .font(.headline)
                    .padding(PrismediaSpacing.large)
            }
            .buttonBorderShape(.capsule)
            .buttonStyle(.glass(.clear))
            .overlay {
                PrismediaButtonBorderBeam(
                    shape: .capsule,
                    showsBorderBeam: true,
                    previewProgress: 0.72
                )
            }
        }
        .frame(
            width: PrismediaLayout.readableContentWidth / 2,
            height: PrismediaLayout.loadingAnimationHeight
        )
        .preferredColorScheme(.dark)
    }
#endif
