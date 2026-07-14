import CoreGraphics
import XCTest

@testable import PrismediaCore

final class EntityImageVideoProgressLayoutTests: XCTestCase {
    func testLandscapeMediaFitsInsidePortraitContainer() throws {
        let frame = try XCTUnwrap(
            EntityImageVideoProgressLayout.fittedMediaFrame(
                containerSize: CGSize(width: 390, height: 844),
                mediaSize: CGSize(width: 1_920, height: 1_080)
            )
        )

        XCTAssertEqual(frame.minX, 0, accuracy: 0.001)
        XCTAssertEqual(frame.width, 390, accuracy: 0.001)
        XCTAssertEqual(frame.height, 219.375, accuracy: 0.001)
        XCTAssertEqual(frame.maxY, 531.6875, accuracy: 0.001)
    }

    func testPortraitMediaFitsInsideLandscapeContainer() throws {
        let frame = try XCTUnwrap(
            EntityImageVideoProgressLayout.fittedMediaFrame(
                containerSize: CGSize(width: 844, height: 390),
                mediaSize: CGSize(width: 1_080, height: 1_920)
            )
        )

        XCTAssertEqual(frame.minY, 0, accuracy: 0.001)
        XCTAssertEqual(frame.width, 219.375, accuracy: 0.001)
        XCTAssertEqual(frame.height, 390, accuracy: 0.001)
        XCTAssertEqual(frame.maxY, 390, accuracy: 0.001)
    }

    func testSquareMediaCentersInsideRectangularContainer() throws {
        let frame = try XCTUnwrap(
            EntityImageVideoProgressLayout.fittedMediaFrame(
                containerSize: CGSize(width: 800, height: 500),
                mediaSize: CGSize(width: 1_000, height: 1_000)
            )
        )

        XCTAssertEqual(frame.minX, 150, accuracy: 0.001)
        XCTAssertEqual(frame.minY, 0, accuracy: 0.001)
        XCTAssertEqual(frame.width, 500, accuracy: 0.001)
        XCTAssertEqual(frame.height, 500, accuracy: 0.001)
    }

    func testInvalidContainerAndMediaSizesDoNotProduceAFrame() {
        XCTAssertNil(
            EntityImageVideoProgressLayout.fittedMediaFrame(
                containerSize: .zero,
                mediaSize: CGSize(width: 1_920, height: 1_080)
            )
        )
        XCTAssertNil(
            EntityImageVideoProgressLayout.fittedMediaFrame(
                containerSize: CGSize(width: 390, height: 844),
                mediaSize: CGSize(width: 0, height: 1_080)
            )
        )
        XCTAssertNil(
            EntityImageVideoProgressLayout.fittedMediaFrame(
                containerSize: CGSize(width: CGFloat.infinity, height: 844),
                mediaSize: CGSize(width: 1_920, height: 1_080)
            )
        )
    }
}
