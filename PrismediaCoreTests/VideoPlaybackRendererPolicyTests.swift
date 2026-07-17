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
}
