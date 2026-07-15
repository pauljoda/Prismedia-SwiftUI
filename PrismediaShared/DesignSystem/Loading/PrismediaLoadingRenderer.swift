import SwiftUI

enum PrismediaLoadingRenderer {
    private static let artworkWidth: CGFloat = 640
    private static let artworkHeight: CGFloat = 590
    private static let beamEntryX: CGFloat = 149 / artworkWidth
    private static let beamEntryY: CGFloat = 349 / artworkHeight
    private static let impactX: CGFloat = 320 / artworkWidth
    private static let impactY: CGFloat = 349 / artworkHeight
    private static let fanStartX: CGFloat = 447 / artworkWidth
    private static let fanTopY: CGFloat = 285 / artworkHeight
    private static let fanBottomY: CGFloat = 368 / artworkHeight
    private static let incomingBeamSlope: CGFloat = -60 / 263
    private static let internalLightStart = 0.82
    private static let internalLightLength = 0.18
    private static let spectrumColors = [
        PrismediaColor.spectrumRed,
        PrismediaColor.spectrumOrange,
        PrismediaColor.spectrumYellow,
        PrismediaColor.spectrumGreen,
        PrismediaColor.spectrumCyan,
        PrismediaColor.spectrumBlue,
        PrismediaColor.spectrumViolet,
    ]

    static func draw(
        frame: PrismediaLoadingAnimationFrame,
        context: inout GraphicsContext,
        size: CGSize,
        drawsPrism: Bool = true
    ) {
        guard size.width > 0, size.height > 0 else { return }

        let prismRectangle = prismRectangle(in: size)
        drawSpectrum(frame: frame, in: prismRectangle, context: &context, size: size)
        drawIncomingLight(frame: frame, in: prismRectangle, context: &context, size: size)
        if drawsPrism {
            drawPrism(frame: frame, in: prismRectangle, context: &context)
        }
        drawInternalLight(frame: frame, in: prismRectangle, context: &context)
        drawImpactGlow(frame: frame, in: prismRectangle, context: &context)
    }

    private static func prismRectangle(in size: CGSize) -> CGRect {
        let availableWidth = max(size.width - (PrismediaSpacing.medium * 2), 0)
        let width = min(PrismediaLayout.loadingPrismMark, availableWidth)
        let height = width * artworkHeight / artworkWidth
        return CGRect(
            x: (size.width - width) / 2,
            y: (size.height - height) / 2,
            width: width,
            height: height
        )
    }

    private static func drawIncomingLight(
        frame: PrismediaLoadingAnimationFrame,
        in prismRectangle: CGRect,
        context: inout GraphicsContext,
        size: CGSize
    ) {
        guard frame.incomingLightOpacity > 0 else { return }

        let entry = point(x: beamEntryX, y: beamEntryY, in: prismRectangle)
        let startX = -PrismediaSpacing.screen
        let calculatedStartY = entry.y - (incomingBeamSlope * (entry.x - startX))
        let start = CGPoint(
            x: startX,
            y: min(
                max(calculatedStartY, PrismediaSpacing.small),
                size.height - PrismediaSpacing.small
            )
        )
        let head = interpolate(from: start, to: entry, progress: frame.incomingLightProgress)
        var path = Path()
        path.move(to: start)
        path.addLine(to: head)

        let opacity = frame.incomingLightOpacity
        let gradient = Gradient(stops: [
            .init(color: PrismediaColor.onMedia.opacity(0), location: 0),
            .init(color: PrismediaColor.onMedia.opacity(opacity * 0.58), location: 0.62),
            .init(color: PrismediaColor.onMedia.opacity(opacity), location: 1),
        ])
        let shading = GraphicsContext.Shading.linearGradient(
            gradient,
            startPoint: start,
            endPoint: head
        )

        context.drawLayer { layer in
            layer.blendMode = .plusLighter
            layer.addFilter(.blur(radius: PrismediaLayout.loadingBeamGlowRadius))
            layer.stroke(
                path,
                with: shading,
                lineWidth: PrismediaLayout.loadingLightLineWidth * 2
            )
        }
        context.stroke(
            path,
            with: shading,
            lineWidth: PrismediaLayout.loadingLightLineWidth
        )

        let headRadius = PrismediaLayout.loadingLightLineWidth * 1.8
        context.fill(
            Path(
                ellipseIn: CGRect(
                    x: head.x - headRadius,
                    y: head.y - headRadius,
                    width: headRadius * 2,
                    height: headRadius * 2
                )
            ),
            with: .color(PrismediaColor.onMedia.opacity(opacity))
        )
    }

    private static func drawSpectrum(
        frame: PrismediaLoadingAnimationFrame,
        in prismRectangle: CGRect,
        context: inout GraphicsContext,
        size: CGSize
    ) {
        guard frame.spectrumProgress > 0, frame.spectrumOpacity > 0 else { return }

        let lastIndex = max(spectrumColors.count - 1, 1)
        for (index, color) in spectrumColors.enumerated() {
            let fraction = Double(index) / Double(lastIndex)
            let start = CGPoint(
                x: prismRectangle.minX + (prismRectangle.width * fanStartX),
                y: prismRectangle.minY
                    + (prismRectangle.height * interpolate(from: fanTopY, to: fanBottomY, progress: fraction))
            )
            let target = CGPoint(
                x: size.width + PrismediaSpacing.screen,
                y: interpolate(
                    from: PrismediaSpacing.small,
                    to: size.height - PrismediaSpacing.small,
                    progress: fraction
                )
            )
            let end = interpolate(from: start, to: target, progress: frame.spectrumProgress)
            let terminalWidth = interpolate(
                from: PrismediaLayout.loadingLightLineWidth,
                to: PrismediaLayout.loadingSpectrumBandWidth,
                progress: frame.spectrumProgress
            )
            let path = spectrumPath(from: start, to: end, terminalWidth: terminalWidth)
            let opacity = frame.spectrumOpacity
            let shading = GraphicsContext.Shading.linearGradient(
                Gradient(colors: [
                    color.opacity(opacity),
                    color.opacity(opacity * 0.72),
                ]),
                startPoint: start,
                endPoint: end
            )

            context.drawLayer { layer in
                layer.blendMode = .plusLighter
                layer.addFilter(.blur(radius: PrismediaLayout.loadingSpectrumGlowRadius))
                layer.fill(path, with: .color(color.opacity(opacity * 0.64)))
            }
            context.fill(path, with: shading)
        }
    }

    private static func spectrumPath(
        from start: CGPoint,
        to end: CGPoint,
        terminalWidth: CGFloat
    ) -> Path {
        let startHalfWidth = PrismediaLayout.loadingLightLineWidth / 2
        let endHalfWidth = terminalWidth / 2
        var path = Path()
        path.move(to: CGPoint(x: start.x, y: start.y - startHalfWidth))
        path.addLine(to: CGPoint(x: end.x, y: end.y - endHalfWidth))
        path.addLine(to: CGPoint(x: end.x, y: end.y + endHalfWidth))
        path.addLine(to: CGPoint(x: start.x, y: start.y + startHalfWidth))
        path.closeSubpath()
        return path
    }

    private static func drawPrism(
        frame: PrismediaLoadingAnimationFrame,
        in prismRectangle: CGRect,
        context: inout GraphicsContext
    ) {
        context.draw(
            Image("PrismediaPrismNeutral", bundle: .prismediaResources),
            in: prismRectangle
        )

        var colorContext = context
        colorContext.opacity = frame.prismColorProgress
        colorContext.draw(
            Image("PrismediaPrismColor", bundle: .prismediaResources),
            in: prismRectangle
        )
    }

    private static func drawInternalLight(
        frame: PrismediaLoadingAnimationFrame,
        in prismRectangle: CGRect,
        context: inout GraphicsContext
    ) {
        let progress = min(
            max((frame.incomingLightProgress - internalLightStart) / internalLightLength, 0),
            1
        )
        let opacity = frame.incomingLightOpacity * progress
        guard opacity > 0 else { return }

        let entry = point(x: beamEntryX, y: beamEntryY, in: prismRectangle)
        let impact = point(x: impactX, y: impactY, in: prismRectangle)
        let end = interpolate(from: entry, to: impact, progress: progress)
        var path = Path()
        path.move(to: entry)
        path.addLine(to: end)

        context.drawLayer { layer in
            layer.blendMode = .plusLighter
            layer.addFilter(.blur(radius: PrismediaLayout.loadingBeamGlowRadius / 2))
            layer.stroke(
                path,
                with: .color(PrismediaColor.onMedia.opacity(opacity)),
                lineWidth: PrismediaLayout.loadingLightLineWidth * 2
            )
        }
        context.stroke(
            path,
            with: .color(PrismediaColor.onMedia.opacity(opacity)),
            lineWidth: PrismediaLayout.loadingLightLineWidth
        )
    }

    private static func drawImpactGlow(
        frame: PrismediaLoadingAnimationFrame,
        in prismRectangle: CGRect,
        context: inout GraphicsContext
    ) {
        guard frame.impactGlowOpacity > 0 else { return }

        let impact = point(x: impactX, y: impactY, in: prismRectangle)
        let radius = PrismediaLayout.loadingImpactGlowRadius
        let glow = Path(
            ellipseIn: CGRect(
                x: impact.x - radius,
                y: impact.y - radius,
                width: radius * 2,
                height: radius * 2
            )
        )
        context.fill(
            glow,
            with: .radialGradient(
                Gradient(stops: [
                    .init(
                        color: PrismediaColor.onMedia.opacity(frame.impactGlowOpacity),
                        location: 0
                    ),
                    .init(
                        color: PrismediaColor.spectrumYellow.opacity(
                            frame.impactGlowOpacity * 0.42
                        ),
                        location: 0.34
                    ),
                    .init(color: PrismediaColor.onMedia.opacity(0), location: 1),
                ]),
                center: impact,
                startRadius: 0,
                endRadius: radius
            )
        )
    }

    private static func point(x: CGFloat, y: CGFloat, in rectangle: CGRect) -> CGPoint {
        CGPoint(
            x: rectangle.minX + (rectangle.width * x),
            y: rectangle.minY + (rectangle.height * y)
        )
    }

    private static func interpolate(
        from start: CGPoint,
        to end: CGPoint,
        progress: Double
    ) -> CGPoint {
        CGPoint(
            x: interpolate(from: start.x, to: end.x, progress: progress),
            y: interpolate(from: start.y, to: end.y, progress: progress)
        )
    }

    private static func interpolate(
        from start: CGFloat,
        to end: CGFloat,
        progress: Double
    ) -> CGFloat {
        start + ((end - start) * CGFloat(progress))
    }
}
