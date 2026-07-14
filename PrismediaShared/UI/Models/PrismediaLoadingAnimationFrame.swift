import Foundation

struct PrismediaLoadingAnimationFrame: Equatable, Sendable {
    static let cycleDuration: TimeInterval = 2.8

    private static let lightTravelStart = 0.04
    private static let lightTravelEnd = 0.38
    private static let lightFadeStart = 0.58
    private static let lightFadeEnd = 0.76
    private static let colorArrivalStart = 0.4
    private static let colorArrivalEnd = 0.54
    private static let spectrumArrivalStart = 0.5
    private static let spectrumArrivalEnd = 0.84
    private static let spectrumFadeStart = 0.48
    private static let spectrumFadeEnd = 0.56
    private static let impactStart = 0.37
    private static let impactPeak = 0.43
    private static let impactEnd = 0.54
    private static let resetStart = 0.9
    private static let resetEnd = 1.0

    static let reducedMotion = PrismediaLoadingAnimationFrame(
        incomingLightProgress: 1,
        incomingLightOpacity: 0,
        prismColorProgress: 1,
        spectrumProgress: 1,
        spectrumOpacity: 0.72,
        impactGlowOpacity: 0
    )

    let incomingLightProgress: Double
    let incomingLightOpacity: Double
    let prismColorProgress: Double
    let spectrumProgress: Double
    let spectrumOpacity: Double
    let impactGlowOpacity: Double

    init(elapsedTime: TimeInterval) {
        let wrappedTime = elapsedTime.truncatingRemainder(dividingBy: Self.cycleDuration)
        let positiveTime = wrappedTime < 0 ? wrappedTime + Self.cycleDuration : wrappedTime
        self.init(progress: positiveTime / Self.cycleDuration)
    }

    init(progress: Double) {
        let progress = min(max(progress, 0), 1)
        let lightArrival = Self.smoothstep(
            progress,
            from: Self.lightTravelStart,
            to: Self.lightTravelEnd
        )
        let lightFade =
            1
            - Self.smoothstep(
                progress,
                from: Self.lightFadeStart,
                to: Self.lightFadeEnd
            )
        let colorArrival = Self.smoothstep(
            progress,
            from: Self.colorArrivalStart,
            to: Self.colorArrivalEnd
        )
        let colorReset =
            1
            - Self.smoothstep(
                progress,
                from: Self.resetStart,
                to: Self.resetEnd
            )
        let spectrumArrival = Self.smoothstep(
            progress,
            from: Self.spectrumArrivalStart,
            to: Self.spectrumArrivalEnd
        )
        let spectrumFadeIn = Self.smoothstep(
            progress,
            from: Self.spectrumFadeStart,
            to: Self.spectrumFadeEnd
        )
        let spectrumFadeOut =
            1
            - Self.smoothstep(
                progress,
                from: Self.resetStart,
                to: Self.resetEnd
            )
        let impactRise = Self.smoothstep(
            progress,
            from: Self.impactStart,
            to: Self.impactPeak
        )
        let impactFall =
            1
            - Self.smoothstep(
                progress,
                from: Self.impactPeak,
                to: Self.impactEnd
            )

        self.init(
            incomingLightProgress: lightArrival,
            incomingLightOpacity: lightArrival * lightFade,
            prismColorProgress: colorArrival * colorReset,
            spectrumProgress: spectrumArrival,
            spectrumOpacity: spectrumFadeIn * spectrumFadeOut,
            impactGlowOpacity: impactRise * impactFall
        )
    }

    private init(
        incomingLightProgress: Double,
        incomingLightOpacity: Double,
        prismColorProgress: Double,
        spectrumProgress: Double,
        spectrumOpacity: Double,
        impactGlowOpacity: Double
    ) {
        self.incomingLightProgress = incomingLightProgress
        self.incomingLightOpacity = incomingLightOpacity
        self.prismColorProgress = prismColorProgress
        self.spectrumProgress = spectrumProgress
        self.spectrumOpacity = spectrumOpacity
        self.impactGlowOpacity = impactGlowOpacity
    }

    private static func smoothstep(_ value: Double, from start: Double, to end: Double) -> Double {
        let progress = min(max((value - start) / (end - start), 0), 1)
        return progress * progress * (3 - (2 * progress))
    }
}
