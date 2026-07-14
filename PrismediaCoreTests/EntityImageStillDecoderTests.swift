import XCTest

@testable import PrismediaCore

final class EntityImageStillDecoderTests: XCTestCase {
    func testDecodesSourceBytesAndExposesIntrinsicDimensions() throws {
        let data = try XCTUnwrap(
            Data(
                base64Encoded:
                    "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVQIHWP4z8DwHwAFgAI/ScL+WQAAAABJRU5ErkJggg=="
            )
        )

        let image = try XCTUnwrap(
            EntityImageStillDecoder.decode(data: data, maximumPixelSize: 2_048)
        )

        XCTAssertEqual(image.width, 1)
        XCTAssertEqual(image.height, 1)
    }
}
