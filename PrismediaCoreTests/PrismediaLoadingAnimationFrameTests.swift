import XCTest

@testable import PrismediaCore

final class PrismediaLoadingAnimationFrameTests: XCTestCase {
    func testWhiteLightArrivesBeforeColorAndSpectrumAppear() {
        let incoming = PrismediaLoadingAnimationFrame(progress: 0.3)
        let impact = PrismediaLoadingAnimationFrame(progress: 0.44)
        let refracting = PrismediaLoadingAnimationFrame(progress: 0.62)

        XCTAssertGreaterThan(incoming.incomingLightProgress, 0.5)
        XCTAssertEqual(incoming.prismColorProgress, 0)
        XCTAssertEqual(incoming.spectrumProgress, 0)

        XCTAssertEqual(impact.incomingLightProgress, 1)
        XCTAssertGreaterThan(impact.prismColorProgress, 0)
        XCTAssertEqual(impact.spectrumProgress, 0)

        XCTAssertEqual(refracting.prismColorProgress, 1)
        XCTAssertGreaterThan(refracting.spectrumProgress, 0)
    }

    func testElapsedTimeWrapsIntoAStableLoadingCycle() {
        let firstCycle = PrismediaLoadingAnimationFrame(elapsedTime: 0.4)
        let nextCycle = PrismediaLoadingAnimationFrame(
            elapsedTime: PrismediaLoadingAnimationFrame.cycleDuration + 0.4
        )

        let firstValues = [
            firstCycle.incomingLightProgress,
            firstCycle.incomingLightOpacity,
            firstCycle.prismColorProgress,
            firstCycle.spectrumProgress,
            firstCycle.spectrumOpacity,
            firstCycle.impactGlowOpacity,
        ]
        let nextValues = [
            nextCycle.incomingLightProgress,
            nextCycle.incomingLightOpacity,
            nextCycle.prismColorProgress,
            nextCycle.spectrumProgress,
            nextCycle.spectrumOpacity,
            nextCycle.impactGlowOpacity,
        ]

        for (first, next) in zip(firstValues, nextValues) {
            XCTAssertEqual(first, next, accuracy: 0.000_000_000_001)
        }
    }

    func testReducedMotionUsesAStaticCompletedRefraction() {
        let timeline = PrismediaLoadingAnimationFrame.reducedMotion

        XCTAssertEqual(timeline.incomingLightProgress, 1)
        XCTAssertEqual(timeline.prismColorProgress, 1)
        XCTAssertEqual(timeline.spectrumProgress, 1)
        XCTAssertEqual(timeline.impactGlowOpacity, 0)
    }

    func testProgressValuesRemainNormalizedOutsideTheCycleRange() {
        let beforeStart = PrismediaLoadingAnimationFrame(progress: -1)
        let afterEnd = PrismediaLoadingAnimationFrame(progress: 2)

        let values = [
            beforeStart.incomingLightProgress,
            beforeStart.prismColorProgress,
            beforeStart.spectrumProgress,
            beforeStart.impactGlowOpacity,
            afterEnd.incomingLightProgress,
            afterEnd.prismColorProgress,
            afterEnd.spectrumProgress,
            afterEnd.impactGlowOpacity,
        ]

        for value in values {
            XCTAssertTrue((0...1).contains(value))
        }
    }
}
