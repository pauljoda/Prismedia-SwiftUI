import XCTest

@testable import PrismediaCore

final class AnimatedImageDecodePolicyTests: XCTestCase {
    func testLongAnimationsStayInsideAggregateDecodedPixelBudget() {
        let maximumPixelSize = AnimatedImageDecodePolicy.maximumPixelSize(
            requestedMaximumPixelSize: 2_048,
            frameCount: 100,
            decodedByteBudget: 96 * 1_024 * 1_024
        )

        XCTAssertLessThanOrEqual(maximumPixelSize, 502)
        XCTAssertGreaterThanOrEqual(maximumPixelSize, 64)
    }

    func testShortAnimationsKeepTheRequestedMaximum() {
        XCTAssertEqual(
            AnimatedImageDecodePolicy.maximumPixelSize(
                requestedMaximumPixelSize: 2_048,
                frameCount: 2,
                decodedByteBudget: 96 * 1_024 * 1_024
            ),
            2_048
        )
    }
}
