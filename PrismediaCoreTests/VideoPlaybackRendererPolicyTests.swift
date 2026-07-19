import XCTest

@testable import PrismediaCore

final class VideoPlaybackRendererPolicyTests: XCTestCase {
    func testSubTenBitHdrDirectSourceUsesCompatibilityRendererWhenAvailable() {
        let renderer = VideoPlaybackRendererPolicy.renderer(
            delivery: .direct,
            dynamicRange: .hdr10,
            bitDepth: 8,
            supportsCompatibilityRenderer: true
        )

        XCTAssertEqual(renderer, .compatibility)
    }

    func testStandardsCompliantHdrKeepsNativeRenderer() {
        let renderer = VideoPlaybackRendererPolicy.renderer(
            delivery: .direct,
            dynamicRange: .hdr10,
            bitDepth: 10,
            supportsCompatibilityRenderer: true
        )

        XCTAssertEqual(renderer, .native)
    }

    func testSubTenBitSdrKeepsNativeRenderer() {
        let renderer = VideoPlaybackRendererPolicy.renderer(
            delivery: .direct,
            dynamicRange: .sdr,
            bitDepth: 8,
            supportsCompatibilityRenderer: true
        )

        XCTAssertEqual(renderer, .native)
    }

    func testCompatibilityRendererIsNeverSelectedForRemux() {
        let renderer = VideoPlaybackRendererPolicy.renderer(
            delivery: .remux,
            dynamicRange: .hdr10,
            bitDepth: 8,
            supportsCompatibilityRenderer: true
        )

        XCTAssertEqual(renderer, .native)
    }

    func testAutomaticEngineUsesCompatibilityRendererForDirectMatroska() {
        let renderer = VideoPlaybackRendererPolicy.renderer(
            delivery: .direct,
            sourceContainer: "mkv",
            dynamicRange: .dolbyVision,
            bitDepth: 10,
            supportsCompatibilityRenderer: true,
            preferredEngine: .automatic
        )

        XCTAssertEqual(renderer, .compatibility)
    }

    func testNativeEngineKeepsDirectMatroskaOnNativeRenderer() {
        let renderer = VideoPlaybackRendererPolicy.renderer(
            delivery: .direct,
            sourceContainer: "matroska",
            dynamicRange: .sdr,
            bitDepth: 8,
            supportsCompatibilityRenderer: true,
            preferredEngine: .native
        )

        XCTAssertEqual(renderer, .native)
    }

    func testVLCPreferenceUsesCompatibilityRendererForRemux() {
        let renderer = VideoPlaybackRendererPolicy.renderer(
            delivery: .remux,
            sourceContainer: "mp4",
            dynamicRange: .sdr,
            bitDepth: 8,
            supportsCompatibilityRenderer: true,
            preferredEngine: .vlc
        )

        XCTAssertEqual(renderer, .compatibility)
    }

    func testVLCPreferenceFallsBackToNativeWhenCompatibilityRendererIsUnavailable() {
        let renderer = VideoPlaybackRendererPolicy.renderer(
            delivery: .direct,
            sourceContainer: "mkv",
            dynamicRange: .sdr,
            bitDepth: 8,
            supportsCompatibilityRenderer: false,
            preferredEngine: .vlc
        )

        XCTAssertEqual(renderer, .native)
    }
}
